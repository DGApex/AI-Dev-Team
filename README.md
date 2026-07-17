<!-- Language: English · Español → README.es.md -->

# Personal AI Dev Studio — Harness

**A portable, opinionated harness that turns a single AI coding assistant into a
disciplined 22-agent software studio.** Drop the `.claude/` directory into any
project and you get a tiered agent org, deterministic lifecycle hooks, a
security-first permission policy, and a "the file is the memory" state model —
all designed so sessions converge on frontier-quality outcomes regardless of the
underlying model.

> 🇬🇧 English · 🇪🇸 [Léelo en español](README.es.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Built for Claude Code](https://img.shields.io/badge/built%20for-Claude%20Code-8A2BE2)
![Docs: EN + ES](https://img.shields.io/badge/docs-EN%20%2B%20ES-blue)

---

## Why this exists

LLMs are probabilistic, but most real work is deterministic and must be
consistent. One agent doing everything compounds error — 90% accuracy per step is
only **59% success over five steps**. This harness fixes the mismatch by pushing
complexity *out* of the model and *into* deterministic structure: SOPs, scripts,
a delegation lattice, and hooks. The model is left with the one thing it's good
at — judgment and routing.

## What you get

- 🧱 **3-layer architecture** — Directive (*what to do*) → Orchestration
  (*decide*) → Execution (*deterministic scripts*), with a self-annealing error
  loop that makes the system stronger every time something breaks.
- 🏢 **A 22-agent studio** in three tiers (Leadership · Leads · Specialists) plus
  a read-only `security-reviewer` gate, wired by an explicit delegation lattice.
- 🪝 **10 lifecycle hooks** that guarantee behavior the model might forget: context
  injection at session start, intent routing, language enforcement, commit/venv
  validation, compaction state dump/restore, a subagent audit trail, and a stop
  guard that refuses to end a session with unsaved state.
- 🧠 **"The file is the memory"** — every recoverable decision is persisted to
  disk; the next session's first impression is injected verbatim from the newest
  closing summary.
- 🔐 **Security-first by default** — permission rules wall off secrets and
  dangerous operations; a mandatory security gate runs before any sensitive
  commit.
- 🧩 **6 team skills + a deterministic plan/build workflow** with adversarial QA.
- 🌍 **Bilingual docs** — everything user-facing is in English and Spanish.

## Quick start

```bash
# 1. Get the harness
git clone https://github.com/DGApex/ai-dev-studio-harness.git
cp -r ai-dev-studio-harness/.claude /path/to/your-project/.claude

# 2. Open Claude Code and bootstrap the studio
#    (idempotent — safe to run at the start of every session;
#     generates the CLAUDE.md/AGENTS.md/GEMINI.md contract for you)
/start
```

Full steps, prerequisites, and customization: **[docs/installation.md](docs/installation.md)**.

## The studio at a glance

```
        LEADERSHIP (Opus)          strategy · sign-off · arbitration
   technical-director · creative-director · producer
                    │
        DEPARTMENT LEADS (Sonnet)  own a domain · delegate down
   frontend · backend · mobile · devops · git · design ·
   skill-curator · doc-keeper
                    │
        SPECIALISTS (Sonnet/Haiku) hands-on work
   react · web · node · python · db · mobile-impl ·
   qa-tester · librarian · skill-author · changelog-writer

   security-reviewer ── read-only gate, outside the tree,
                        runs before any sensitive commit
```

Models are assigned by **cognitive cost** using aliases (`haiku`/`sonnet`/`opus`)
that always track the latest model in each tier.

## Repository layout

```
ai-dev-studio-harness/
├── .claude/                 the harness itself
│   ├── agents/              22 agent definitions
│   ├── docs/                8 studio docs (roster, lattice, rules, principles…)
│   ├── hooks/               10 lifecycle shell scripts
│   ├── skills/              6 project skills (team-* + humanizer)
│   ├── templates/           CLAUDE.template.md — the portable contract
│   ├── workflows/           team-new-feature.js — plan/build workflow
│   ├── settings.json        permissions + hook wiring (committed)
│   └── settings.local.json  machine-local overrides (git-ignored)
├── docs/                    architecture · reference · installation (EN + ES)
├── README.md / README.es.md
├── CONTRIBUTING.md          bilingual
├── CHANGELOG.md
├── LICENSE                  MIT
└── .gitignore
```

## Documentation

| Topic | English | Español |
|-------|---------|---------|
| Architecture (the *why*) | [architecture.md](docs/architecture.md) | [architecture.es.md](docs/architecture.es.md) |
| Reference (the full catalog) | [reference.md](docs/reference.md) | [reference.es.md](docs/reference.es.md) |
| Installation & usage | [installation.md](docs/installation.md) | [installation.es.md](docs/installation.es.md) |

## Requirements

- [Claude Code](https://claude.com/claude-code) (CLI, desktop, web, or IDE extension)
- Git, and Bash (Git Bash on Windows) for the hooks
- *(Optional)* Python 3 + [`uv`](https://docs.astral.sh/uv/) for Layer-3 scripts

## A note on language

The harness converses in **neutral Spanish** by default, while all portable
artifacts (`.claude/**`, code, the contract, ADRs) stay in **English** for reuse.
Both are configurable — see [installation.md](docs/installation.md#customization).

## License

[MIT](LICENSE) © 2026 Alexander Frings.
