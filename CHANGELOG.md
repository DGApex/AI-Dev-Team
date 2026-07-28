# Changelog

All notable changes to this harness are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **`team-session-close` skill** (`/close`) — the mirror of `/start`. Reconstructs
  the session from evidence (git diff/log, file mtimes, `active.md`) rather than
  from memory, writes the session-log entry with its `<!-- cierre -->` block,
  rewrites `active.md` last so the Stop hook's freshness invariant holds, syncs
  project-overview / backlog / roadmap / memory, offers a git checkpoint, and ends
  with a `.tmp` purge + secrets/PII pass. Flags: `--quick`, `--no-git`.
  Documented as coordination pattern §9 (Session Close).
- **`.claude/hooks/lib/payload.sh`** — single implementation of hook-payload field
  extraction (`python`→`python3`→`py -3`→`grep`), previously copy-pasted across
  hooks. Callers guard the `source` and carry an inline fallback, so a partially
  copied harness never blocks every tool call.
- **`validate-commit.sh` now blocks secret *reads*** — the `settings.json` deny
  rules are prefix-oriented and missed `head -c 200 .env`, `sed -n 1p .env`,
  `base64 .env`, `python -c "open('.env').read()"`, and `< .env` redirects. The
  check is semantic: a secret-looking path **and** a disclosing command. Naming a
  path stays legal (`ls -la .env`, `echo ".env" >> .gitignore`), and
  `.env.example`/`.sample`/`.template`/`.dist` are sanitized out first.

### Fixed

- **`route-intent.sh` matched the whole payload instead of the prompt.** `cwd` and
  `transcript_path` carry the project's directory name, so a project living in a
  folder called `landing`, `design-system`, or `frontend` fired the design router
  on *every* prompt of every session — permanent, invisible prompt bloat. It now
  matches the `prompt` field only, and routes nothing when no prompt is extracted.
- **`stop-state-reminder.sh` walked `node_modules` in full.** `-not -path` still
  descends into a directory and tests every file inside it; the hook has a 10s
  timeout and a `find` that times out fails *silently*, so the "file is the memory"
  invariant quietly stopped existing on exactly the large projects where it matters
  most. Now uses `-prune` to skip the subtree whole, over a wider ignore list
  (`.venv`, `.mypy_cache`, `.ruff_cache`, `.nuxt`, `.turbo`, `.cache`, `target`, …).

## [1.0.0] — 2026-07-17

First public release: the Personal AI Dev Studio harness, packaged with
bilingual (English / Spanish) documentation and ready to drop into any project.

### Added

- **3-layer architecture** (Directive / Orchestration / Execution) with a
  self-annealing error loop, defined in `.claude/templates/CLAUDE.template.md`.
- **22-agent studio** across three tiers (Leadership / Leads / Specialists) plus a
  read-only `security-reviewer` gate, with a documented delegation lattice and
  escalation paths.
- **10 lifecycle hooks** in `.claude/hooks/` — session context injection, intent
  routing, language enforcement, commit/venv validation, compaction state
  dump/restore, subagent audit trail, and the "file is the memory" stop guard.
- **6 project skills** in `.claude/skills/` — `team-session-start`,
  `team-new-feature`, `team-git-checkpoint`, `team-library-recommendation`,
  `team-skill-regeneration`, and `humanizer`.
- **Deterministic plan/build workflow** (`team-new-feature.js`) with adversarial
  QA verification.
- **8 studio docs** covering the roster, coordination map, rules, design
  principles, orchestrator mindset, technical preferences, global-skills map, and
  backlog-triage standard.
- **Security-first permission policy** in `.claude/settings.json` (allow / ask /
  deny) that walls off secrets and dangerous operations.
- **Repository documentation** in English and Spanish: `README`, architecture,
  reference, and installation guides, plus `CONTRIBUTING`, `LICENSE`, and this
  changelog.
