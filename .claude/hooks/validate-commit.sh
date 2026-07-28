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

# Shared payload extraction (.claude/hooks/lib/payload.sh). Guard the source:
# a hook that dies on a missing lib would block every Bash call in a partially
# copied harness.
LIB="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/lib/payload.sh"
if [ -f "$LIB" ]; then
    . "$LIB"
else
    payload_field() {
        printf '%s' "$1" \
            | grep -oE "\"${2##*.}\"[[:space:]]*:[[:space:]]*\"(\\\\.|[^\"\\\\])*\"" \
            | head -1 | sed "s/^\"[^\"]*\"[[:space:]]*:[[:space:]]*\"//; s/\"\$//; s/\\\\\"/\"/g"
    }
fi

COMMAND=$(payload_field "$INPUT" tool_input.command)

if [ -z "$COMMAND" ]; then
    exit 0
fi

if echo "$COMMAND" | grep -qE 'rm\s+-rf?\s+(/|~|\$HOME)' ; then
    echo "BLOCKED: rm -rf on root or home directory is forbidden." >&2
    exit 2
fi

# --- Rule: no READING secrets through Bash (Data Protection § 1) ---
# The Bash deny rules in settings.json are prefix-oriented, so entries like
# Bash(cat *.env*) do not reliably cover `head -c 200 .env`, `sed -n 1p .env`,
# `base64 .env`, or `python -c "print(open('.env').read())"`. Reads are blocked
# HERE, where the check is semantic rather than a pattern match. The Read tool
# stays covered by the Read(**/.env*) rules in settings.json.
#
# Shape of the check: a secret-looking path AND a command that would disclose
# its contents. Naming a secret path is not itself a violation — `ls -la .env`
# and `echo ".env" >> .gitignore` reveal nothing and must keep working.

# Strip the non-secret example variants first so `.env.example` never trips this.
SANITIZED=$(echo "$COMMAND" | sed -E 's/\.env\.(example|sample|template|dist)([^[:alnum:]]|$)/\2/g')

# NOTE: the '.' must NOT be excluded after '\.env' — doing so let
# `tail -n 5 .env.production` through, since the char right after ".env" was a
# dot. Suffixed env files (.env.production, .env.local) are the common case.
# Safe because the sanitizer above has already removed the example variants,
# so nothing benign with a dotted suffix reaches this regex.
SECRET_PATH_RE='\.env([^[:alnum:]]|$)|credentials\.json|token\.json|\.pem([^[:alnum:]]|$)|\.key([^[:alnum:]]|$)|\.p12([^[:alnum:]]|$)|\.pfx([^[:alnum:]]|$)|id_rsa|id_ed25519'

# Commands that put file contents somewhere visible (stdout, a copy, the network).
READER_RE='(^|[|;&(]|[[:space:]])(cat|tac|nl|head|tail|less|more|od|xxd|hexdump|strings|base64|cut|awk|sed|grep|egrep|fgrep|rg|ag|jq|yq|bat|dotenv|printenv|cp|mv|scp|rsync|curl|wget|tee|zip|tar)([[:space:]]|$)'
# Inline interpreter one-liners: python -c, node -e, ruby -e, perl -e, ...
INLINE_READ_RE='(python[0-9.]*|py|node|deno|bun|ruby|perl|php)([[:space:]]+-[[:alnum:]]+)*[[:space:]]+-(c|e)([[:space:]]|$)'
# Input redirection: `while read x < .env`, `$(< .env)`
REDIRECT_READ_RE='<[[:space:]]*[^[:space:]<>]*(\.env|\.pem|\.key|credentials\.json|token\.json|id_rsa)'

if echo "$SANITIZED" | grep -qE "$SECRET_PATH_RE" ; then
    if echo "$SANITIZED" | grep -qE "$READER_RE" \
    || echo "$SANITIZED" | grep -qE "$INLINE_READ_RE" \
    || echo "$SANITIZED" | grep -qE "$REDIRECT_READ_RE" ; then
        cat >&2 <<'EOF'
BLOCKED: this command would disclose the contents of a secret file
(.env / credentials.json / token.json / *.pem / *.key / id_rsa*).

Secrets never leave their home (CLAUDE.md § Data Protection 1). Reference them
by variable name only — never read, print, copy, upload, or archive the file.

If you need to know WHICH keys exist (not their values):
  grep -oE '^[A-Z_][A-Z0-9_]*=' .env    <- still blocked; ask the user instead.

If you genuinely need the value, the user provides it — you do not read it.
Naming the path is fine: `ls -la .env` and `echo ".env" >> .gitignore` are allowed.
EOF
        exit 2
    fi
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
