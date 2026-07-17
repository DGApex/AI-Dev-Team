<!-- Language: English · Español → installation.es.md -->

# Installation & Usage

The harness is the `.claude/` directory plus a project contract. Installing it
means dropping `.claude/` into a project and generating the `CLAUDE.md` contract
from the template.

## Prerequisites

- **[Claude Code](https://claude.com/claude-code)** (CLI, desktop, web, or an IDE extension).
- **Git** — the studio's git workflow and several hooks assume a repo.
- **Bash** — the hooks are POSIX shell scripts. On Windows they run under **Git
  Bash**, which ships with Git for Windows. The hooks degrade gracefully when
  `python`/`jq` are missing.
- *(Optional)* **Python 3** with **[`uv`](https://docs.astral.sh/uv/)** — only if
  you write Layer-3 `execution/` scripts. The venv rule is enforced by
  `enforce-venv.sh`.

## Install into a new or existing project

1. **Copy the harness** into your project root:

   ```bash
   # from the project you want to equip
   cp -r /path/to/this-repo/.claude ./.claude
   ```

   Or clone this repo and copy the folder, or start your project *as* a clone of
   this repo.

2. **Generate the contract.** Copy the template to the three mirror files so the
   same instructions load in any AI environment:

   ```bash
   cp .claude/templates/CLAUDE.template.md ./CLAUDE.md
   cp ./CLAUDE.md ./AGENTS.md
   cp ./CLAUDE.md ./GEMINI.md
   ```

   > Tip: the `/start` skill does this (and the rest of the scaffold) for you
   > idempotently — see step 4.

3. **Add a `.gitignore`.** Use this repo's `.gitignore` as a base — it already
   excludes secrets, `settings.local.json`, runtime state, and build artifacts.

4. **Run `/start`.** Open Claude Code in the project and run:

   ```
   /start
   ```

   This bootstraps the full scaffold (contract, `directives/`, `backlog.md`,
   `roadmap.md`, session-state, `memory/`), checks skill dependencies, loads
   context, and produces a status briefing. It is idempotent — safe to run every
   session, and the canonical first step of any session.

## First session

- The **`SessionStart` hook** runs automatically and prints branch, recent
  commits, the newest closing summary (once you have one), and the memory index.
- Describe a feature and the orchestrator may **auto-invoke `/team-new-feature`**;
  say `directo` / `direct` to bypass the pipeline for a trivial edit.
- At the end of a session, the **`Stop` hook** will not let you finish until
  session state is persisted (`active.md` + the `session-log.md` closing summary).

## Customization

- **Trim the roster.** Solo or small projects don't need all 22 agents — delete
  the agent files you won't use and prune the corresponding rows in
  `.claude/docs/agent-roster.md` and `agent-coordination-map.md`.
- **Adjust permissions.** Edit the `allow` / `ask` / `deny` lists in
  `.claude/settings.json` to fit your risk tolerance. (Editing this file is itself
  a confirmation-required action.)
- **Language.** The default conversation language is neutral Spanish, enforced by
  `enforce-language.sh` and the contract's *Conversation language* section. To
  switch, edit both the hook and that section of `CLAUDE.md`.
- **Global skills.** The studio references the user's globally-installed skills
  (design suite, firecrawl, obsidian, GSAP, …) in
  `.claude/docs/global-skills-map.md`. Update that map to match what you actually
  have installed.

## What NOT to commit

The included `.gitignore` already handles this, but as a reminder — never commit:
`.env*`, `credentials.json`, `token.json`, `*.pem`, `*.key`, `id_rsa*`,
`.claude/settings.local.json`, `production/session-logs/`, or any `memory/` file
holding sensitive context.
