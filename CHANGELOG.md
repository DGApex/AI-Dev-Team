# Changelog

All notable changes to this harness are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
