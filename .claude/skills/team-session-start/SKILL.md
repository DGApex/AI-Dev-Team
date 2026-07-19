---
name: team-session-start
description: "Guided onboarding for the start of a session. Loads CLAUDE.md, directives, session-log, project-overview, active.md, and lists available skills. Producer + doc-keeper synthesize a status briefing and propose next actions. Alias: /start."
argument-hint: "[--quick (skip docs-stale check)]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, Task, AskUserQuestion
---

When this skill is invoked (also as `/start`):

## 0. Bootstrap the full project scaffold (runs before everything else)

Every check below is conditional ("if missing") — this step is idempotent and
silently skips anything that already exists. Collect what was actually created
and notify the user with the exact list at the end of the step.

**0a. CLAUDE.md trio** — if `CLAUDE.md` is missing in the project root:
1. Read `.claude/templates/CLAUDE.template.md`
2. Write the template content to three files in the project root:
   - `CLAUDE.md`
   - `AGENTS.md`
   - `GEMINI.md`

**0b. Git repository** — if `git rev-parse --git-dir` fails:
1. Run `git init`
2. Write `.gitignore` with at least:
   ```
   .tmp/
   .env
   credentials.json
   token.json
   node_modules/
   ```

**0c. Directives** — if `directives/` is missing, create it with two skeletons:
- `directives/session-log.md` — header explaining it is the chronological
  session log (newest entry on top) plus one initial entry in the template's entry format
  (`## YYYY-MM-DD — Project scaffolded`, with today's date) recording that the
  scaffold was created by `/start`.
- `directives/project-overview.md` — the mandatory sections from
  CLAUDE.template.md § Project Documentation, each with a `_TBD_` placeholder:
  Project identity · Current status · Vision · Architecture & stack ·
  Key design decisions · Directory structure · Known constraints.

**0c-bis. Backlog** — if `directives/backlog.md` is missing, create it with a
header explaining it is the queue of future ideas / deferred todos (NOT the
active task → `active.md`, chronology → `session-log.md`, or current state →
`project-overview.md`; `producer` drives priorities, `doc-keeper` maintains it),
the entry format (`## B-NNN — title` + a **Status** line: `idea` / `en curso` /
`✅ hecho`), and zero entries.

**The file MUST be scaffolded with the two-section ordering rule in its header, and
with both section headings already present (empty).** A backlog that grows without
this becomes unreadable by ~20 entries — open and closed items interleave, and the
queue stops being a queue. It is far cheaper to be born ordered than to be reordered
later:

```markdown
**Cómo leer este archivo.** Dos secciones, y solo dos:

- **`## Abiertas`** — todo lo NO hecho, ordenado por número de menor a mayor. Esto es la cola.
- **`## Cerradas`** — todo lo hecho o descartado, ordenado por número. Se conservan por sus
  `[[links]]` y por el razonamiento que documentan. **No son pendientes. No reabrir sin evidencia
  nueva.** Sus títulos van marcados `## ✅ B-NNN — [CERRADO]` para que se distingan de un vistazo.

**Los números nunca se reordenan ni se reasignan**: son identidad, y hay `[[links]]` cruzados que
apuntan a ellos. Un ítem que se cierra **se mueve de sección, no cambia de número**.

Al cerrar un ítem: cambia su `**Status:**` a `✅ hecho` (o `❌ sin objeto`), marca el título como
`## ✅ B-NNN — [CERRADO] título`, y **muévelo a `## Cerradas`** conservando su número.
```

**0c-ter. Roadmap** — if `directives/roadmap.md` is missing, create it with a
header explaining it is the phased roadmap + scope of the project (the "where
this is going"), owned by `producer` and distinct from backlog (parking lot →
`backlog.md`), chronology (`session-log.md`), current state (`project-overview.md`),
and single decisions (ADRs). Skeleton content:
- an **Alcances (scope)** section with `_TBD_` in-scope / out-of-scope placeholders;
- a **Fases** section with a `_TBD_` placeholder (each future phase = pregunta it
  answers · entregables · exit criteria);
- near the top, the sentinel line `<!-- roadmap-checkpoint: pending -->`.
The Stop hook uses that sentinel: once a foundational decision (an `ADR-*.md`)
exists but the roadmap is still a skeleton, it prompts the orchestrator to propose
a programming roadmap. Flip the sentinel to `done` (roadmap filled) or `declined`
(user declined) to silence it. See the Roadmap Checkpoint pattern in
`.claude/docs/agent-coordination-map.md`.

**0d. Session state** — if `production/session-state/active.md` is missing,
create it with minimal initial state, **already carrying the closing-summary
block** (CLAUDE.md § Living documentation). Scaffold it with the sentinels in
place, exactly as the backlog is scaffolded pre-ordered: a structure that is born
correct is never retrofitted under time pressure.
```markdown
# Active Session State

<!-- cierre -->
## 🧾 Cierre — sin sesiones aún
Proyecto recién inicializado por `/start`. Nada que resumir todavía.
**Siguiente paso concreto:** elegir la primera tarea (paso 5 de `/start`).
<!-- /cierre -->

---

**Status:** freshly scaffolded — no active task yet.
**Last update:** <today's date> (by /start bootstrap)
## Current task
None. Run /start step 5 to pick one.
```
The `<!-- cierre -->` block is what the SessionStart hook injects into the next
session's context, and `stop-state-reminder.sh` blocks the Stop while it is
missing. At session close, rewrite it (in Spanish, detailed but simple) so it
recaps what the session did, decided, and left pending.

**0e. Working directories** — create if missing:
- `execution/` (with an empty `.gitkeep`)
- `.tmp/`

**0e-bis. Project memory** — if `memory/MEMORY.md` is missing (project root —
NOT inside `.claude/`, which must stay a portable, project-agnostic harness),
create it with the standard header (one line per memory; what belongs here vs
session-log/project-overview/ADRs; curated by doc-keeper) and zero entries.
Memory files are one fact per file with frontmatter (`name`, `description`,
`metadata.type: gotcha | constraint | preference | reference`), body with
**Why:** and **How to apply:**, `[[name]]` links between related memories.
Per-agent memory (`memory/agents/<agent>/MEMORY.md`) is NOT scaffolded — it's
created lazily the first time an agent records a domain learning.

**0f. Global skill dependencies** — read the "Required global skills" manifest
in `.claude/docs/global-skills-map.md` and compare it against the skills
actually available in this session (the available-skills list the harness
provides; do NOT rely on globbing directories — plugin skills don't live in a
folder you can scan):
- Any **REQUIRED** skill missing → prominent warning in the briefing:
  "⚠ Missing required global skill: `<name>` — the studio depends on it."
- Any **RECOMMENDED** skill missing → one soft line listing them.
- Skills available in the session but absent from the map → flag the drift
  for `skill-curator` (one line, no action needed).

**Then offer to install the missing ones** (do NOT just warn). For each missing
REQUIRED skill — and, if the user opts in, any missing RECOMMENDED — run the
**install flow** in `.claude/docs/global-skills-map.md` §6:
1. Look the skill up in that map's §7 credits/sources table. If its origin is
   `por verificar` (no confirmed repo), do NOT guess — say so and ask the user
   for the source instead of installing.
2. Ask **where to install** with `AskUserQuestion`, options in this order:
   - **Global (recommended)** → `~/.claude/skills/<name>/` (here:
     `C:\Users\<user>\.claude\skills\<name>\`) — shared across all projects.
   - **Portable** → `.claude/skills/<name>/` in this repo — travels with the
     harness, **but shadows/freezes** any future global copy (§5/§6); if chosen,
     note the freeze in the session log.
   - **Skip** → leave it missing (keep the warning).
3. On global/portable, install from §7's `install` command into the chosen dir,
   then verify `<target>/<name>/SKILL.md` exists and report where it landed.

Batch it: list all missing installable skills, ask the target once per skill (or
"install all missing globally?" if the user prefers), never install silently.

**Notification format:** "Scaffold check — created: [list]. Already present: [list or 'everything else']." If nothing was created, say nothing and continue.

## 1. Parse Arguments

- `--quick` → skip the doc-staleness check (doc-keeper sub-step), trust current state.

## 2. Gather Context (read all in parallel)

Read the following files. If a file is missing, note it but continue:

1. `CLAUDE.md` — 3-layer model + Studio overview
2. `directives/session-log.md` — last 3 entries (most recent on top)
3. `directives/project-overview.md` — current project state
4. `production/session-state/active.md` — machine-recoverable state
5. `.claude/docs/agent-roster.md` — who's available
6. `.claude/docs/agent-coordination-map.md` — workflow patterns
7. `.claude/docs/orchestrator-mindset.md` — reasoning discipline (the 8 rules
   the orchestrator applies all session and injects into delegated prompts)
8. `memory/MEMORY.md` — project memory index (read individual memory
   files only when their description is relevant to the session's work)
9. `directives/backlog.md` — deferred ideas / todos (skim; surface any that are
   relevant to the session's next actions)
10. `directives/roadmap.md` — phased roadmap + scope (skim; if it still holds an
    unresolved `roadmap-checkpoint: pending` sentinel and an ADR exists, plan to
    propose a programming roadmap this session)

Also run `Glob` for `Skills/*/SKILL.md` to enumerate available skills, and `git status --short` + `git log --oneline -10` for working-tree context.

## 3. Synthesize Status (parallel Tasks)

Spawn two subagents in parallel:

- `Task(producer)`: "Read the gathered context (active.md + session-log + project-overview). Synthesize: (1) where the studio left off, (2) what is open, (3) what the obvious next 1-3 actions are. Output as a markdown briefing under 300 words."
- `Task(doc-keeper)`: "Read project-overview.md and session-log.md. Verify project-overview describes a state from within the last 2 sessions. If stale, list specifically what's outdated. Output a 'Doc health' section."
  - SKIP if `--quick` was passed.

## 4. Render Briefing

Combine the two outputs into a single briefing rendered inline:

```
=== Personal AI Dev Studio — Session Briefing ===

[producer's synthesis]

=== Doc health (doc-keeper) ===
[doc-keeper's findings, or "skipped (--quick)"]

=== Available skills ===
[grouped: existing skills in Skills/, plus team-* in .claude/skills/]

=== Skill dependencies (global-skills-map.md) ===
[REQUIRED: all present ✓ / missing: list with ⚠ + "offering install (step 0f)"]
[RECOMMENDED missing: soft list, or omit if complete]
[unmapped skills detected: list for skill-curator, or omit]
[if any missing installable: "→ I can install these — global or portable? (§6)"]

=== Working tree ===
Branch: <branch>
Uncommitted: <count> files
Recent commits:
  <last 5>
```

## 5. Confirm Next Action with User

Use `AskUserQuestion` with options derived from producer's "next 1-3 actions" suggestion:

- One option per suggested action (max 3)
- Always include: "Other / let me decide"

The user's pick becomes the active task; update `production/session-state/active.md` accordingly (asking permission first per collaboration protocol).

## Patterns Used

This skill implements the **Project Onboarding** pattern (custom for Personal AI Dev Studio). It is the canonical first step of any session — never skip it on the first turn.

See `.claude/docs/agent-coordination-map.md` for the full pattern catalog.