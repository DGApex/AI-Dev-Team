#!/bin/bash
# Claude Code Stop hook — Personal AI Dev Studio
# Enforces the "file is the memory" invariant (design principles § insight 3):
# if project files changed after production/session-state/active.md was last
# updated, block the stop once and ask Claude to persist session state first.
#
# Safe by construction:
#   - stop_hook_active guard prevents infinite block loops
#   - exits silently in projects that have no state file (e.g. the harness repo)

INPUT=$(cat 2>/dev/null)

# Anchor to the project root — hooks can inherit whatever cwd the session's
# shell last visited (e.g. a worktree), which produces false positives.
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0

# Never loop: if this stop is already a continuation caused by a stop hook, allow it.
if echo "$INPUT" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
    exit 0
fi

STATE_FILE="production/session-state/active.md"
LOG_FILE="directives/session-log.md"

# --- Invariant 1: session state freshness ('file is the memory') ---
if [ -f "$STATE_FILE" ]; then
    # Only nudge when meaningful project files are newer than the state file.
    # Exclude VCS internals, caches, build artifacts, worktrees, and audit logs.
    NEWER=$(find . -type f -newer "$STATE_FILE" \
        -not -path "./.git/*" \
        -not -path "./node_modules/*" \
        -not -path "./.tmp/*" \
        -not -path "./production/session-logs/*" \
        -not -path "./.claude/worktrees/*" \
        -not -path "*/.pytest_cache/*" \
        -not -path "*/__pycache__/*" \
        -not -path "*/.venv/*" \
        -not -path "*/dist/*" \
        -not -path "*/build/*" \
        -not -path "*/.next/*" \
        -not -path "*/coverage/*" \
        2>/dev/null | head -5 | tr -d '"' | tr '\n' ' ')
    if [ -n "$NEWER" ]; then
        cat <<EOF
{"decision": "block", "reason": "Project files changed after production/session-state/active.md was last updated. Per the 'file is the memory' invariant, persist session state before finishing: (1) refresh the '<!-- cierre -->' closing-summary block at the TOP of the newest entry in directives/session-log.md so it tells the next session, in plain Spanish, what this session actually did/decided/left pending — the SessionStart hook injects that block as the next session's first context; (2) update the detailed state in active.md below (current task, key decisions, next steps). Changed files include: $NEWER"}
EOF
        exit 0
    fi

    # --- Invariant 1-bis: session-log.md carries a closing-summary block ---
    # The closing summary now lives at the TOP of each session-log.md entry, and
    # the SessionStart hook injects the newest one verbatim as the next session's
    # first impression. Without any cierre block the preview falls back to a raw
    # head of active.md. ASCII sentinels keep the check locale-proof; the heading
    # inside them is free-form Spanish.
    if ! grep -q '<!-- /cierre -->' "$LOG_FILE" 2>/dev/null; then
        cat <<EOF
{"decision": "block", "reason": "directives/session-log.md has no closing-summary block, and the SessionStart hook injects the newest one as the next session's first context. Add it at the TOP of the newest entry (directly under its '## YYYY-MM-DD — título' heading), fenced by the sentinels '<!-- cierre -->' and '<!-- /cierre -->': a Spanish heading with session number + date, a one-sentence 'En una frase:', 3-6 plain-language bullets of what was done, the decisions taken and WHY, the state at close (branch, tree, tests, what is half-done), and the concrete next step. Detailed but simple — no internal jargon or code identifiers the reader has to look up. See CLAUDE.md § Living documentation."}
EOF
        exit 0
    fi
fi

# --- Invariant 2: roadmap checkpoint ---
# Once the idea+investigation phase closes — a foundational decision (an ADR)
# exists but the programming roadmap is still a skeleton — nudge the orchestrator
# to PROPOSE a roadmap to the user. The scaffolded directives/roadmap.md carries a
# 'roadmap-checkpoint: pending' sentinel; flipping it to 'done' (user accepts and
# the roadmap is filled) or 'declined' silences this. Fires until resolved.
ROADMAP="directives/roadmap.md"
if [ -f "$ROADMAP" ] && grep -q "roadmap-checkpoint: pending" "$ROADMAP" 2>/dev/null; then
    ADR=$(find . -name "ADR-*.md" \
        -not -path "./.git/*" \
        -not -path "./node_modules/*" \
        -not -path "./.claude/*" \
        -not -path "./.tmp/*" \
        2>/dev/null | head -1 | tr -d '"')
    if [ -n "$ADR" ]; then
        cat <<EOF
{"decision": "block", "reason": "A foundational decision exists ($ADR) but directives/roadmap.md is still a skeleton — the idea+investigation phase looks closed. Propose a programming roadmap to the user now (AskUserQuestion covering fases + alcances/scope). When the user accepts (you fill roadmap.md) or declines, flip the 'roadmap-checkpoint: pending' sentinel in roadmap.md to 'done'/'declined' so this stops firing."}
EOF
        exit 0
    fi
fi

exit 0
