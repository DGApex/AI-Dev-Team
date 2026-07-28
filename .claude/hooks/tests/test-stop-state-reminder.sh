#!/bin/bash
# Suite for stop-state-reminder.sh — the Stop hook that enforces the
# "file is the memory" invariants.
#
# WHY THIS SUITE EXISTS: this hook had NO tests at all, and it is the hook that
# has been changed most often — 1-bis, 1-ter and 1-quater were each added in
# reaction to a distinct failure that reached git (a missing closing summary, a
# contradictory one, and an active.md that grew into an archive until it exceeded
# the read limit). Three guards written after the fact, none of them covered. A
# guard nobody tests is a guard that gets reverted silently, which is what
# happened to enforce-venv.sh.
#
# CONTRACT NOTE — why this suite does not use lib.sh's run(): that helper treats
# exit code 2 as "block", which is the PreToolUse contract. A Stop hook blocks by
# printing {"decision": "block", ...} on stdout and exiting 0. Asserting on the
# exit code here would make every case pass regardless of behaviour.
#
# Usage:  bash .claude/hooks/tests/test-stop-state-reminder.sh [path/to/hook]

HOOK_ARG="${1:-.claude/hooks/stop-state-reminder.sh}"
HOOK_DIR=$(cd "$(dirname "$HOOK_ARG")" && pwd) || exit 1
HOOK="$HOOK_DIR/$(basename "$HOOK_ARG")"

# shellcheck source=lib.sh
. "$(cd "$(dirname "$0")" && pwd)/lib.sh"

TMPROOT=$(mktemp -d 2>/dev/null) || { echo "cannot mktemp"; exit 1; }
trap 'rm -rf "$TMPROOT"' EXIT

# Deterministic mtimes instead of sleeps: the freshness invariant compares
# modification times, and a temp tree created inside one second has ties. -newer
# is STRICTLY newer, so ties read as "not newer" and every case would pass by
# accident. active.md is stamped in the future; a file meant to look edited later
# is stamped further still.
STATE_STAMP=203001010000
NEWER_STAMP=203101010000

PROJ=""

# scaffold a minimal project whose state file is the newest thing in it
setup_project() {
    PROJ="$TMPROOT/p$RANDOM$RANDOM"
    mkdir -p "$PROJ/production/session-state" "$PROJ/directives"
    cat > "$PROJ/directives/session-log.md" <<'LOG'
# Bitácora

## 2026-07-28 — sesión de prueba

<!-- cierre -->
## Cierre — Sesión 1
En una frase: esto es un fixture.
<!-- /cierre -->

Detalle de la sesión.
LOG
    cat > "$PROJ/production/session-state/active.md" <<'STATE'
# Active Session State

**Status:** fixture
## Current task
Nada.
STATE
    touch -t "$STATE_STAMP" "$PROJ/production/session-state/active.md"
}

# check <allow|block> <substring-expected-in-reason|-> <description>
check() {
    local expect="$1" needle="$2" desc="$3"
    local out got
    out=$(printf '%s' "${STDIN_JSON:-\{\}}" | CLAUDE_PROJECT_DIR="$PROJ" bash "$HOOK" 2>&1)
    case "$out" in
        *'"decision": "block"'*) got=block ;;
        *)                       got=allow ;;
    esac
    if [ "$got" != "$expect" ]; then
        FAIL=$((FAIL+1)); printf '  FAIL  [got %-5s want %-5s] %s\n' "$got" "$expect" "$desc"
        return
    fi
    if [ "$needle" != "-" ] && [ "${out#*"$needle"}" = "$out" ]; then
        FAIL=$((FAIL+1))
        printf '  FAIL  [%-5s, wrong reason] %s\n' "$got" "$desc"
        printf '        expected to mention: %s\n' "$needle"
        return
    fi
    PASS=$((PASS+1)); printf '  PASS  [%-5s] %s\n' "$got" "$desc"
}

# repeat a line N times into the state file, keeping it the newest file
state_with_lines() {
    local n=$1 i
    : > "$PROJ/production/session-state/active.md"
    i=0
    while [ "$i" -lt "$n" ]; do
        echo "linea de estado $i" >> "$PROJ/production/session-state/active.md"
        i=$((i+1))
    done
    touch -t "$STATE_STAMP" "$PROJ/production/session-state/active.md"
}

echo "=== stop-state-reminder.sh ==="
echo

# --- baseline -------------------------------------------------------------
setup_project
check allow - "clean state: nothing newer, sentinels balanced, file short"

# --- invariant 1: freshness ----------------------------------------------
setup_project
echo "cambio" >> "$PROJ/directives/session-log.md"
touch -t "$NEWER_STAMP" "$PROJ/directives/session-log.md"
check block "Project files changed" "a project file newer than active.md blocks"

# --- invariant 1-bis: a closing-summary block must exist ------------------
setup_project
cat > "$PROJ/directives/session-log.md" <<'LOG'
# Bitácora
## 2026-07-28 — sin bloque de cierre
Texto suelto.
LOG
touch -t "$STATE_STAMP" "$PROJ/production/session-state/active.md"
check block "no closing-summary block" "session-log with no cierre block blocks"

# --- invariant 1-ter: sentinels balanced and alternating ------------------
setup_project
printf '\n<!-- /cierre -->\n' >> "$PROJ/directives/session-log.md"
touch -t "$STATE_STAMP" "$PROJ/production/session-state/active.md"
check block "malformed cierre sentinels" "orphan closing sentinel blocks"

setup_project
printf '\n<!-- cierre -->\n<!-- cierre -->\ntexto\n<!-- /cierre -->\n<!-- /cierre -->\n' \
    >> "$PROJ/directives/session-log.md"
touch -t "$STATE_STAMP" "$PROJ/production/session-state/active.md"
check block "malformed cierre sentinels" "nested sentinels (O,O,C,C) block"

setup_project
printf '\n## 2026-07-27 — entrada anterior\n\n<!-- cierre -->\nresumen\n<!-- /cierre -->\n' \
    >> "$PROJ/directives/session-log.md"
touch -t "$STATE_STAMP" "$PROJ/production/session-state/active.md"
check allow - "MUTATION CONTROL: two well-formed entries (O,C,O,C) are allowed"

# --- invariant 1-quater: active.md is state, not a chronology --------------
setup_project
printf '\n## 📕 Sesión anterior (10ª) — cerrada\n\ntexto archivado\n' \
    >> "$PROJ/production/session-state/active.md"
touch -t "$STATE_STAMP" "$PROJ/production/session-state/active.md"
check block "archive headings" "the accreted archive heading blocks"

setup_project
printf '\n## Sesion anterior (9a)\n' >> "$PROJ/production/session-state/active.md"
touch -t "$STATE_STAMP" "$PROJ/production/session-state/active.md"
check block "archive headings" "unaccented 'Sesion anterior' heading blocks too"

setup_project
printf '\n#### sesión anterior\n' >> "$PROJ/production/session-state/active.md"
touch -t "$STATE_STAMP" "$PROJ/production/session-state/active.md"
check block "archive headings" "lowercase h4 archive heading blocks"

setup_project
printf '\nEn la sesión anterior se decidió portar la captura del banco.\n' \
    >> "$PROJ/production/session-state/active.md"
touch -t "$STATE_STAMP" "$PROJ/production/session-state/active.md"
check allow - "MUTATION CONTROL: the same words in PROSE are allowed (heading-anchored, not word-matched)"

setup_project
state_with_lines 400
check allow - "boundary: exactly 400 lines is allowed"

setup_project
state_with_lines 401
check block "over the 400-line ceiling" "401 lines blocks"

setup_project
state_with_lines 500
printf '\n## 📕 Sesión anterior (8ª)\n' >> "$PROJ/production/session-state/active.md"
touch -t "$STATE_STAMP" "$PROJ/production/session-state/active.md"
check block "archive headings" "too long AND accreted: reports the CAUSE, not the symptom"

# --- safety properties -----------------------------------------------------
setup_project
rm -f "$PROJ/production/session-state/active.md"
check allow - "no state file at all (harness repo): silent, never blocks"

setup_project
printf '\n<!-- /cierre -->\n' >> "$PROJ/directives/session-log.md"
printf '\n## 📕 Sesión anterior (7ª)\n' >> "$PROJ/production/session-state/active.md"
touch -t "$STATE_STAMP" "$PROJ/production/session-state/active.md"
STDIN_JSON='{"stop_hook_active": true}'
check allow - "stop_hook_active:true never blocks, however broken the files are"
unset STDIN_JSON

result