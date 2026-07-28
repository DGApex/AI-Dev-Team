<!-- Language: English · Español → reference.es.md -->

# Reference

Exhaustive catalog of everything the harness ships. For the *why*, read
[`architecture.md`](architecture.md).

Everything lives under `.claude/`:

```
.claude/
├── agents/         22 agent definitions (persona + tools + model)
├── docs/           8 studio docs (roster, lattice, rules, principles, ...)
├── hooks/          10 lifecycle shell scripts
├── skills/         6 project skills (team-* pipelines + humanizer)
├── templates/      CLAUDE.template.md (the portable contract)
├── workflows/      team-new-feature.js (deterministic plan/build workflow)
├── worktrees/      runtime isolation dir for parallel agents (git-ignored)
├── settings.json         permissions + hook wiring (committed)
└── settings.local.json   machine-local overrides (git-ignored, never committed)
```

---

## Agents (22)

Each agent is a Markdown file in `.claude/agents/` with YAML frontmatter
(`name`, `description`, `tools`, `model`) followed by a persona line, a
**Collaboration Protocol** section (Question → Options → Decision → Draft →
Approval), and **Key Responsibilities**.

### Tier 1 — Leadership (Opus)

| Agent | Domain | When to use |
|-------|--------|-------------|
| `technical-director` | Architecture, technical sign-off, lattice arbitration | Cross-domain technical decisions, ADR sign-off, stack changes |
| `creative-director` | UX/UI vision, brand, voice, design strategy | Design direction, brand consistency, UX trade-off arbitration |
| `producer` | Planning, scope, prioritization, doc supervision | Sprint kick-off, scope arbitration, status synthesis |

### Tier 2 — Department Leads (Sonnet)

| Agent | Domain | When to use |
|-------|--------|-------------|
| `frontend-lead` | Web frontend architecture | Framework choice, component structure |
| `backend-lead` | API, server, auth, business logic | API design, auth strategy |
| `mobile-lead` | iOS / Android / cross-platform | RN vs Flutter vs Expo, mobile architecture |
| `devops-lead` | Infra, CI/CD, deploys, secrets | Pipeline setup, deploy strategy |
| `git-lead` | Version-control strategy | Commits, branches, PRs, tags, release timing |
| `design-lead` | Design system, components, assets | DS authoring, component library |
| `skill-curator` | Owns `Skills/` | Skill gaps, regen proposals, multi-skill flows |
| `doc-keeper` | Owns `directives/` + living docs | Doc maintenance, ADR tracking, session-log discipline |

### Cross-tier gate (Opus)

| Agent | Domain | When to use |
|-------|--------|-------------|
| `security-reviewer` | Security & data-protection gate (read-only) | Before `git-lead` commits any change touching auth, PII, external input, third-party APIs, or infra/secrets. Verdict: PASS / CONCERNS / BLOCK |

### Tier 3 — Specialists (Sonnet / Haiku)

| Agent | Domain | Model |
|-------|--------|-------|
| `react-specialist` | React + ecosystem (hooks, state, SSR) | Sonnet |
| `web-implementer` | Vanilla web (HTML/CSS/JS, GSAP animations) | Sonnet |
| `node-specialist` | Node / Express / Fastify | Sonnet |
| `python-specialist` | Deterministic Python scripts (Layer 3) | Sonnet |
| `db-specialist` | Schemas, queries, migrations | Sonnet |
| `mobile-implementer` | RN / Expo / Flutter implementation | Sonnet |
| `qa-tester` | Tests + verification (globally invocable) | Sonnet |
| `librarian` | Library research + ranking | Haiku |
| `skill-author` | Writes/edits skills | Sonnet |
| `changelog-writer` | Changelogs, status reports, release notes | Haiku |

---

## Hooks (10)

Shell scripts wired in `.claude/settings.json`, run at fixed lifecycle points.

| Hook | Event | Purpose |
|------|-------|---------|
| `session-start.sh` | SessionStart | Injects branch, recent commits, newest closing summary + memory index into the session |
| `route-intent.sh` | UserPromptSubmit | Detects add/edit & design intent **in the user's prompt only**; reminds orchestrator of standing pipeline & design-suite authorizations |
| `enforce-language.sh` | UserPromptSubmit | Injects the "always address the user in neutral Spanish" reminder |
| `validate-commit.sh` | PreToolUse (Bash) | Hard-blocks `rm -rf /`, writes to `.env`, force-push to main, and **any command that would disclose a secret file's contents** (`cat`/`head`/`base64`/`cp`/`curl`, `python -c`, `< .env` redirects…); soft-asks on commit messages with no issue/ADR reference |
| `enforce-venv.sh` | PreToolUse (Bash) | Blocks global/system pip installs; teaches the correct venv path so the agent self-corrects |
| `pre-compact.sh` | PreCompact | Dumps full session state + git status + recently modified files before compression |
| `post-compact.sh` | PostCompact | Reloads session state after compression |
| `log-agent.sh` | SubagentStart | Opens an audit-trail entry per subagent |
| `log-agent-stop.sh` | SubagentStop | Closes the audit-trail entry |
| `stop-state-reminder.sh` | Stop | Hard-blocks session end if project files are newer than `active.md` or the closing summary is missing; drives the Roadmap Checkpoint |
| `lib/payload.sh` | *(library, not a hook)* | Shared `payload_field` helper: pulls one field out of the event JSON on stdin. Sourced by the hooks that need it |

**Portability notes:** every hook `cd`s to `${CLAUDE_PROJECT_DIR}` first and
degrades gracefully — JSON is parsed via `python`→`python3`→`py -3`→`grep`, so the
hooks work on Windows Git Bash where `python` may be absent from PATH. That
extraction now lives once in `.claude/hooks/lib/payload.sh`; callers **guard the
source** (`[ -f "$LIB" ] && . "$LIB"`) and carry an inline fallback, so a partially
copied harness never blocks every tool call. Hooks that inspect the prompt match
the `prompt` field only — never the raw payload, whose `cwd` and `transcript_path`
carry the project's own directory name and would fire on every prompt in a project
folder called `landing` or `frontend`. Hooks exit silently in a project that has no
state files yet (e.g. this harness repo).

---

## Skills (7)

Project skills in `.claude/skills/`. Invoked with `/name` or by the orchestrator.

| Skill | What it does |
|-------|--------------|
| `team-session-start` (`/start`) | Idempotent bootstrap of the whole project scaffold + context load; `producer` + `doc-keeper` synthesize a status briefing. The canonical first step of any session |
| `team-session-close` (`/close`) | The mirror of `/start`: reconstructs the session from evidence (git diff/log + file mtimes + `active.md`, never memory), writes the session-log entry with its `<!-- cierre -->` block, rewrites `active.md` last, syncs project-overview / backlog / roadmap / memory, offers a git checkpoint, then runs a `.tmp` purge + secrets/PII pass. Flags `--quick`, `--no-git` |
| `team-new-feature` | End-to-end feature pipeline: gather context → deterministic plan workflow (producer → technical-director → lead) behind an approval gate → build workflow (specialists → adversarial QA) → git checkpoint → doc log. Enforces the mandatory design suite on UI work |
| `team-git-checkpoint` | `git-lead` analyzes the working tree, proposes a branch + commit plan; after approval commits, optionally pushes / opens a PR. Conditional devops + security gates, release/tag flow, doc-keeper logging |
| `team-library-recommendation` | `librarian` researches a 2–4 option shortlist with tradeoffs; the domain lead picks; `doc-keeper` writes a Nygard ADR and updates the allow-list |
| `team-skill-regeneration` | Regenerate/fix a skill: `skill-curator` gap analysis → `skill-author` edit → `qa-tester` dry-run → `doc-keeper` log. Supports `--dry-run` |
| `humanizer` | Removes AI-writing tells from text (33 patterns): draft → "still-AI?" audit → final rewrite loop, hard-banning em/en dashes; optional voice matching |

---

## Workflow

`.claude/workflows/team-new-feature.js` — a deterministic, two-mode JS workflow
(run via the Workflow tool) that backs the `team-new-feature` skill.

- **Plan mode** — sequential `producer` (frame) → `technical-director`
  (sign-off / ADR) → domain lead (design into specialist tasks), each returning a
  validated JSON schema.
- **Build mode** — writer specialists run in parallel (git-worktree isolation only
  when more than one mutating writer), then read-only tasks, then per-criterion
  `qa-tester` verification with an adversarial second opinion on each failure.
  Returns `{ files_modified, implementations, blocked, used_worktrees, qa: { verdict, criteria } }`.

---

## Studio docs (8)

Reference material in `.claude/docs/`, loaded on demand.

| Doc | Contents |
|-----|----------|
| `agent-roster.md` | The 22 agents by tier + model-tier assignment reference |
| `agent-coordination-map.md` | The delegation lattice, escalation paths, and 8 workflow patterns |
| `coordination-rules.md` | The 6 coordination rules, subagents-vs-teams, parallel + self-anneal protocols |
| `agent-architecture-design-principles.md` | The 8 design insights, anti-pattern catalog (A1–A9), model-routing heuristic |
| `orchestrator-mindset.md` | The 8 reasoning rules + the enforcement map |
| `technical-preferences.md` | Stack defaults, naming, performance budgets, testing, forbidden patterns, allowed libraries, ADR + skill routing |
| `global-skills-map.md` | Registers the user's globally-installed skills as studio tools + routing |
| `backlog-triage-standard.md` | The milestone-driven triage buckets (P0/P1/P2, gate, deferred, closed) and survey flow |

---

## Settings & permissions

`.claude/settings.json` (committed) declares the hook wiring and a permission
policy:

- **`allow`** — safe read-only git/ls commands run without a prompt.
- **`ask`** — edits to `.claude/hooks/**` and `settings*.json` always confirm
  (privileged, auto-executing files).
- **`deny`** — a hard wall around secrets and dangerous ops: reading/writing
  `.env*`, `credentials.json`, `token.json`, `*.pem`, `*.key`, `id_rsa*`,
  `settings.local.json`; `rm -rf`, force-push, `git reset --hard`, `git clean -f`,
  `sudo`, `chmod 777`; network egress with a body/upload (`curl --data`, `scp`,
  `nc`); and adding/changing a git remote.

`.claude/settings.local.json` holds machine-local overrides. It is **git-ignored
and must never be committed** (it is also in the `deny` read list).

---

## The contract (`CLAUDE.template.md`)

`.claude/templates/CLAUDE.template.md` is the portable contract that becomes
`CLAUDE.md` (mirrored to `AGENTS.md` / `GEMINI.md`) when the harness is installed
into a project. It is the single source of truth the orchestrator loads at every
session, covering: the 3-layer model, operating principles, the studio,
living-documentation rules, the orchestrator mindset, the language policy, and the
full Data Protection & Security section.
