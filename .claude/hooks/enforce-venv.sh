#!/bin/bash
# Claude Code PreToolUse hook (Bash matcher) — Personal AI Dev Studio
# Enforces the Python venv rule (CLAUDE.md § Python Environment Discipline):
# third-party installs must target a project virtual environment, never the
# global/system Python. The block message teaches the correct path, so the
# agent self-corrects in the same turn.
#
# Outcomes:
#   - exit 0, no output = allow
#   - exit 2 + stderr   = hard block

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

# --- Rule 1: 'uv pip install --system' bypasses the venv on purpose — block. ---
if echo "$COMMAND" | grep -qE '\buv\s+pip\s+install\b.*--system'; then
    echo "BLOCKED: 'uv pip install --system' bypasses the project venv. Use 'uv add <pkg>' or plain 'uv pip install' (targets .venv). See CLAUDE.md § Python Environment Discipline." >&2
    exit 2
fi

# --- Rule 2: pip installs must be routed through a venv. ---
# Strip uv-managed forms first so 'uv pip install' doesn't trip the check
# (uv targets the project .venv by itself and errors if none exists).
STRIPPED=$(echo "$COMMAND" | sed -E 's/\buv[[:space:]]+pip[[:space:]]+install//g')

if echo "$STRIPPED" | grep -qE '(^|[;&|[:space:]])pip3?(\.exe)?[[:space:]]+install\b|-m[[:space:]]+pip[[:space:]]+install\b'; then
    # Allowed when the command visibly targets a virtual environment:
    # a .venv/venv path in the interpreter, an activate step, or VIRTUAL_ENV.
    if ! echo "$COMMAND" | grep -qiE '\.venv|[/\\]venv[/\\]|activate|VIRTUAL_ENV|pipx'; then
        cat >&2 <<'EOF'
BLOCKED: installing into the global/system Python is forbidden — third-party
deps live in a project venv (CLAUDE.md § Python Environment Discipline).

Fix:
  1. Create the venv if missing:  python -m venv .venv    (or: uv venv)
  2. Install into it:
       Windows:  .venv/Scripts/python.exe -m pip install <pkg>
       POSIX:    .venv/bin/pip install <pkg>
  3. Record the dependency in pyproject.toml / requirements.txt.

Preferred: uv add <pkg> + uv run script.py (auto-creates and syncs .venv).
One-off CLI tools: uvx <tool> (or pipx install <tool>).
EOF
        exit 2
    fi
fi

exit 0