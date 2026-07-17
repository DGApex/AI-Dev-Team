<!-- Language: English · Español → architecture.es.md -->

# Architecture

> This document explains *why* the harness is shaped the way it is. For the
> exhaustive catalog of agents, hooks, skills and settings, see
> [`reference.md`](reference.md).

The harness solves one core mismatch: **LLMs are probabilistic, but most real
work is deterministic and needs to be consistent.** A single agent doing
everything compounds error — 90% accuracy per step is only 59% success over five
steps. The whole design pushes complexity *out* of the model and *into*
deterministic structure, so the model is left with the one thing it is good at:
judgment and routing.

Everything below is layered on top of that idea.

---

## 1. The 3-Layer Model

The foundation. Every task flows through three separated layers:

| Layer | Name | What lives here | Nature |
|-------|------|-----------------|--------|
| **1** | **Directive** (*what to do*) | SOPs in `directives/`, agent definitions in `.claude/agents/` | Natural-language instructions, like a brief for a mid-level employee |
| **2** | **Orchestration** (*decision-making*) | The model itself + the delegation lattice | Reads directives, routes to tools in the right order, handles errors |
| **3** | **Execution** (*doing the work*) | Deterministic Python scripts in `execution/` | Reliable, testable, fast — API calls, data processing, file ops |

The orchestrator is the **glue between intent and execution**. It does not scrape
a website by hand — it reads `directives/scrape_website.md`, decides inputs and
outputs, and runs `execution/scrape_single_site.py`.

### Self-annealing

Errors are treated as learning opportunities, not dead ends. The loop:

1. **Fix** the thing that broke.
2. **Fix the tool** (the script / agent / hook), not the symptom in the consumer.
3. **Test** the fix against the failure case.
4. **Update the directive** with what was learned (API limits, timing, edge cases).
5. The system is now permanently stronger.

This applies recursively: if a fix reveals a structural flaw, it escalates to
`technical-director` and produces an ADR.

---

## 2. The Studio (a refinement, not a replacement)

On top of the 3-layer model runs the **Personal AI Dev Studio** — a 3-tier
organization of 22 specialized agents that mirrors a real software team. It maps
cleanly onto the layers:

- **Layer 1 (Directive)** ↔ agent definitions + SOPs
- **Layer 2 (Orchestration)** ↔ the delegation lattice
- **Layer 3 (Execution)** ↔ specialist agents + Python scripts

### The three tiers

```
        LEADERSHIP (Opus)          strategy, sign-off, arbitration
   technical-director · creative-director · producer
                    │
        DEPARTMENT LEADS (Sonnet)  own a domain, delegate down
   frontend · backend · mobile · devops · git · design ·
   skill-curator · doc-keeper
                    │
        SPECIALISTS (Sonnet/Haiku) do the hands-on work
   react · web · node · python · db · mobile-impl ·
   qa-tester · librarian · skill-author · changelog-writer
```

Plus one agent that sits **outside** the tree: `security-reviewer`, a read-only,
globally-invocable gate (Opus) that must pass before any sensitive change is
committed.

### Why tiers, and why models are calibrated to them

Each tier is assigned a model by **cognitive cost**, not by prestige:

- **Haiku** — read-only status checks, formatting, simple lookups. No judgment.
- **Sonnet** — implementation, design authoring, single-system analysis. The default.
- **Opus** — multi-document synthesis, high-stakes gate verdicts, cross-system review.

Rule of thumb: *if removing an agent wouldn't change the project's trajectory,
it's Haiku-tier; if a wrong judgment there would burn weeks, it's Opus-tier;
everything else is Sonnet.* Agent frontmatter always uses the **aliases**
(`haiku`/`sonnet`/`opus`), never pinned IDs, so tiers track the latest model
automatically.

### The delegation lattice

Delegation is **unidirectional and explicit** — there is a documented
who-delegates-to-whom matrix (see [`reference.md`](reference.md)). Leads delegate
to specialists; leadership delegates to leads. Skipping a tier for a complex
decision is an anti-pattern. Two special edges break the strict tree on purpose:

- **`qa-tester`** is owned by `devops-lead` but is **globally invocable** by any
  lead — it is the shared verification specialist.
- **`security-reviewer`** is a global gate that runs *before* `git-lead` on any
  change touching auth, PII, external input, third-party APIs, or infra/secrets.

Conflicts escalate to the nearest shared parent; security verdicts win unless the
user explicitly overrides.

---

## 3. The file is the memory

The single most important invariant: **the conversation is ephemeral; the file
system is memory.** Any state that must survive a session — current task,
decisions made, next steps — is persisted to disk, never left only in context.

This is enforced, not merely encouraged:

| File | Role | Owner |
|------|------|-------|
| `directives/session-log.md` | Chronological log; **newest entry on top**, each opening with a `<!-- cierre -->` closing-summary block | `doc-keeper` |
| `directives/project-overview.md` | Always-current description of the project (never >2 sessions stale) | `doc-keeper` |
| `production/session-state/active.md` | Machine-recoverable in-flight state | `doc-keeper` |
| `directives/backlog.md` | Deferred ideas / future work (two sections: `Abiertas` / `Cerradas`, never renumbered) | `producer` + `doc-keeper` |
| `directives/roadmap.md` | Phased plan + scope, created when the idea phase closes | `producer` + `doc-keeper` |
| `memory/` (project root) | Distilled, recallable facts — one fact per file, indexed by `memory/MEMORY.md` | `doc-keeper` |
| `**/ADR-*.md` | Architecture Decision Records (Nygard format) | `technical-director` |

**The closing-summary block is load-bearing.** The `SessionStart` hook `sed`s the
first `<!-- cierre -->…<!-- /cierre -->` block out of `session-log.md` and injects
it verbatim as the next session's first impression. Because newest-on-top is
enforced, "the first block in the file" and "the newest session's summary" are
the same thing. The sentinels are ASCII so the hooks can `grep`/`sed` them
regardless of locale.

---

## 4. Hooks: deterministic glue around a non-deterministic core

Hooks are shell scripts the harness runs automatically at fixed lifecycle points.
They are how the studio guarantees behavior the model might otherwise forget. All
ten live in `.claude/hooks/` and are wired in `.claude/settings.json`.

| Lifecycle event | Hook(s) | What it guarantees |
|-----------------|---------|--------------------|
| `SessionStart` | `session-start.sh` | Injects branch, recent commits, the newest closing summary, and the memory index into the new session |
| `UserPromptSubmit` | `route-intent.sh`, `enforce-language.sh` | Detects add/edit & design intent and reminds the orchestrator of standing authorizations; enforces "always answer the user in Spanish" |
| `PreToolUse` (Bash) | `validate-commit.sh`, `enforce-venv.sh` | Blocks `rm -rf /`, writes to `.env`, force-push to main; nudges for issue-referencing commit messages; blocks global pip installs |
| `PreCompact` / `PostCompact` | `pre-compact.sh`, `post-compact.sh` | Dumps full state before lossy compression, reloads it after |
| `SubagentStart` / `SubagentStop` | `log-agent.sh`, `log-agent-stop.sh` | Writes an audit trail of every subagent invocation |
| `Stop` | `stop-state-reminder.sh` | Hard-blocks the session end if state wasn't persisted (the "file is the memory" enforcement) and drives the Roadmap Checkpoint |

Hooks are **privileged** (they auto-execute), so editing anything under
`.claude/hooks/` or `settings*.json` is a confirmation-required action. Every
filesystem hook `cd`s to `${CLAUDE_PROJECT_DIR}` first, because a hook can inherit
whatever cwd the shell last visited (a lesson learned from a real cwd-drift false
positive).

---

## 5. Orchestrator mindset (process over model)

*Model capability is fixed; process is not.* The studio encodes a reasoning
discipline so that any session, on any model, converges on similar quality. The
eight rules, in one breath:

1. **Evidence before belief** — never claim "done/fixed" without observing it.
2. **Adversarial self-verification** — a finding must survive an attempt to refute it.
3. **Act at the decision point** — no re-litigating, no option-narration, no ending on promises.
4. **Diagnose the class, fix the root** — after a fix, sweep for siblings of the same bug class.
5. **Calibrated delegation** — fan out for breadth, never for a one-lookup answer; every prompt self-contained.
6. **Problem vs request** — assessment when the user describes, action when the user asks.
7. **Irreversibility gradient** — reversible: do it; hard-to-reverse: get a fresh explicit yes.
8. **Lead with the outcome** — the first sentence answers "what happened".

Some rules are enforced by structure (hooks, permission rules, the QA verify
phase); the rest are carried by the orchestrator. A violated rule is a
self-anneal event: you fix the artifact that should have enforced it.

---

## 6. Security is non-negotiable

A dedicated section of the contract outranks productivity and every directive:

- **Secrets never leave home** — never read/print/log `.env*`, `credentials.json`,
  `token.json`, `*.pem`, `*.key`, `id_rsa*`; reference them only by variable name.
  Permission `deny` rules in `settings.json` back this up.
- **No untrusted egress** — no sending repo/user data to a network destination the
  user didn't name this session; adding/changing a git remote is confirmation-required.
- **PII minimization** — synthetic data in tests, no real PII in logs/memory/commits.
- **Security review in the loop** — the `security-reviewer` gate is mandatory
  before committing anything touching auth, PII, external input, third-party APIs,
  or infra/secrets. A `qa-tester` PASS alone is not sufficient for those.

---

## Language policy

The conversation with the user is in **neutral Spanish**. The **portable
artifacts stay in English** for reuse across projects and environments: the
harness (`.claude/**`), `execution/**` code, the contract itself
(`CLAUDE.md`/`AGENTS.md`/`GEMINI.md`), and portable technical records (ADRs,
changelogs, directive SOPs). Only the session/state documents that the user reads
directly — `session-log.md`, `project-overview.md`, `active.md`, `backlog.md`,
`roadmap.md`, and `memory/` — are written in the conversation language.

This repository's own documentation is provided in **both English and Spanish**
(`*.md` / `*.es.md`) so it is legible to either audience.
