#!/bin/bash
# Claude Code PreToolUse hook (Bash matcher) — Personal AI Dev Studio
# Validates Bash commands before execution.
#
# Outcomes:
#   - exit 0, no output          = allow
#   - exit 2 + stderr            = hard block
#   - exit 0 + JSON on stdout    = soft warning (permissionDecision: "ask" surfaces
#     a confirmation prompt to the user — stderr with exit 0 is invisible in
#     PreToolUse hooks, so warnings MUST go through this JSON channel)

INPUT=$(cat 2>/dev/null)

# JSON extraction with graceful degradation: python -> python3 -> py -3 -> grep.
# On Windows Git Bash, "python" is not always on PATH.
extract_command() {
    local PY
    for PY in "python" "python3" "py -3"; do
        if command -v ${PY%% *} >/dev/null 2>&1; then
            local out
            out=$(echo "$INPUT" | $PY -c "import sys, json; d=json.load(sys.stdin); print(d.get('tool_input', {}).get('command', ''))" 2>/dev/null)
            if [ -n "$out" ]; then
                echo "$out"
                return
            fi
        fi
    done
    # Fallback: pull the raw "command" string field (handles escaped quotes).
    echo "$INPUT" | grep -oE '"command"[[:space:]]*:[[:space:]]*"(\\.|[^"\\])*"' | head -1 \
        | sed 's/^"command"[[:space:]]*:[[:space:]]*"//; s/"$//; s/\\"/"/g'
}

COMMAND=$(extract_command)

if [ -z "$COMMAND" ]; then
    exit 0
fi

if echo "$COMMAND" | grep -qE 'rm\s+-rf?\s+(/|~|\$HOME)' ; then
    echo "BLOCKED: rm -rf on root or home directory is forbidden." >&2
    exit 2
fi

if echo "$COMMAND" | grep -qE '>\s*[^\s]*\.env' ; then
    # .env.example / .env.sample / .env.template hold no secrets — allow those.
    if ! echo "$COMMAND" | grep -qE '\.env\.(example|sample|template)\b' ; then
        echo "BLOCKED: writing to .env files is forbidden." >&2
        exit 2
    fi
fi

if echo "$COMMAND" | grep -qE 'git\s+push\s+(--force|-f).*\b(main|master)\b' ; then
    echo "BLOCKED: force-push to main/master is forbidden." >&2
    exit 2
fi

if echo "$COMMAND" | grep -qE '^git\s+commit' ; then
    if ! echo "$COMMAND" | grep -qE '#[0-9]+|[A-Z]+-[0-9]+|design/|docs/|directives/' ; then
        cat <<'EOF'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask", "permissionDecisionReason": "Commit message does not reference an issue (#N), ADR, or design doc. Studio convention asks for one — proceed anyway?"}}
EOF
        exit 0
    fi
fi

exit 0
