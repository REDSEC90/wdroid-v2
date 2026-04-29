#!/bin/bash
# =============================================================================
# tests/run_tests.sh — Framework de testes mínimo para wdroid
# =============================================================================

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# ── Contadores ────────────────────────────────────────────────────────────────
_PASS=0
_FAIL=0
_SKIP=0

# ── Cores ─────────────────────────────────────────────────────────────────────
_G='\033[0;32m'; _R='\033[0;31m'; _Y='\033[1;33m'; _B='\033[1m'; _X='\033[0m'

suite() { printf "\n${_B}▶ %s${_X}\n" "$1"; }

pass()   { ((_PASS++)); printf "  ${_G}✓${_X} %s\n" "$1"; }
fail()   { ((_FAIL++)); printf "  ${_R}✗${_X} %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${_R}→ %s${_X}\n" "$2"; }
skip()   { ((_SKIP++)); printf "  ${_Y}○${_X} %s (skipped)\n" "$1"; }

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then pass "$desc"
    else fail "$desc" "esperado='$expected' obtido='$actual'"; fi
}

assert_contains() {
    local desc="$1" needle="$2" haystack="$3"
    if echo "$haystack" | grep -qF "$needle"; then pass "$desc"
    else fail "$desc" "'$needle' não encontrado"; fi
}

assert_exit_ok() {
    local desc="$1"; shift
    if "$@" &>/dev/null; then pass "$desc"
    else fail "$desc" "comando falhou: $*"; fi
}

assert_exit_fail() {
    local desc="$1"; shift
    if ! "$@" &>/dev/null; then pass "$desc"
    else fail "$desc" "esperava falha mas teve sucesso: $*"; fi
}

assert_file_exists() {
    local desc="$1" file="$2"
    if [ -f "$file" ]; then pass "$desc"
    else fail "$desc" "arquivo não encontrado: $file"; fi
}

assert_executable() {
    local desc="$1" file="$2"
    if [ -x "$file" ]; then pass "$desc"
    else fail "$desc" "não é executável: $file"; fi
}

# ── Carrega todos os arquivos de teste (sem set -e para não abortar) ──────────
for _test_file in "$BASE_DIR/tests"/test_*.sh; do
    [ -f "$_test_file" ] || continue
    # shellcheck source=/dev/null
    source "$_test_file" || true
done

# ── Relatório final ───────────────────────────────────────────────────────────
_total=$((_PASS + _FAIL + _SKIP))
printf "\n${_B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_X}\n"
printf "  Total: %d  ${_G}✓ %d${_X}  ${_R}✗ %d${_X}  ${_Y}○ %d${_X}\n" \
    "$_total" "$_PASS" "$_FAIL" "$_SKIP"
printf "${_B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_X}\n\n"

[ "$_FAIL" -eq 0 ]
