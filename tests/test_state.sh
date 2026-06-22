#!/bin/bash
# tests/test_state.sh — Verifica state machine (com waydroid mockado)

suite "State machine (core/state.sh)"

# Ambiente de teste: mocka waydroid
_run_state() {
    bash -c "
        export HOME=/tmp
        WDROID_LOG_DIR=/tmp/wdroid-test-logs-$$
        STATE_FILE=/tmp/wdroid-test-state-$$
        source '$BASE_DIR/core/config.sh'
        source '$BASE_DIR/core/logger.sh'
        _init_logger
        source '$BASE_DIR/core/utils.sh'

        # Mocks injetados via argumento
        $1

        source '$BASE_DIR/core/state.sh'
        $2
    "
    local _rc=$?
    rm -f /tmp/wdroid-test-state-$$ 2>/dev/null
    return $_rc
}

# get_state() → STOPPED quando container inativo
_out=$(_run_state \
    'waydroid() { echo "Container: STOPPED"; echo "Session: STOPPED"; }; export -f waydroid' \
    'get_state')
assert_eq "get_state() → STOPPED sem container" "STOPPED" "$_out"

_out=$(_run_state \
    'set -euo pipefail; waydroid() { return 1; }; export -f waydroid' \
    'get_state')
assert_eq "get_state() → STOPPED se waydroid status falha" "STOPPED" "$_out"

# get_state() → CONTAINER_ONLY quando container ativo mas sem sessão
_out=$(_run_state \
    'waydroid() { echo "Container: RUNNING"; echo "Session: STOPPED"; }; export -f waydroid' \
    'get_state')
assert_eq "get_state() → CONTAINER_ONLY sem sessão" "CONTAINER_ONLY" "$_out"

# get_state() → SESSION_RUNNING quando sessão ativa mas sem app
_out=$(_run_state \
    'waydroid() {
       if [ "$1" = "status" ]; then echo "Container: RUNNING"; echo "Session: RUNNING"
       elif [ "$1" = "shell" ]; then return 1
       fi
     }; export -f waydroid' \
    'get_state')
assert_eq "get_state() → SESSION_RUNNING com sessão" "SESSION_RUNNING" "$_out"

# get_state() → APP_RUNNING quando o pacote está ativo no Android
_out=$(_run_state \
    'waydroid() {
       if [ "$1" = "status" ]; then echo "Container: RUNNING"; echo "Session: RUNNING"
       elif [ "$1" = "shell" ] && [ "$2" = "pidof" ]; then return 0
       fi
       return 1
     }; export -f waydroid' \
    'get_state')
assert_eq "get_state() → APP_RUNNING com app ativo" "APP_RUNNING" "$_out"

# save_state / load_state
_run_state '' \
    'save_state "SESSION_RUNNING"; result=$(load_state); echo "$result"' &>/dev/null
_out=$(_run_state '' \
    'save_state "CONTAINER_ONLY"; load_state')
assert_eq "save_state/load_state funcionam" "CONTAINER_ONLY" "$_out"

# load_state() retorna UNKNOWN quando arquivo não existe
_out=$(_run_state '' \
    'rm -f "$STATE_FILE"; load_state')
assert_eq "load_state() → UNKNOWN sem arquivo" "UNKNOWN" "$_out"

# require_state() passa quando estado é suficiente
_run_state \
    'waydroid() {
       if [ "$1" = "status" ]; then echo "Container: RUNNING"; echo "Session: RUNNING"
       elif [ "$1" = "shell" ]; then return 1
       fi
     }; export -f waydroid' \
    'require_state SESSION_RUNNING' &>/dev/null
assert_eq "require_state() passa com SESSION_RUNNING" "0" "$?"

# require_state() falha quando estado é STOPPED
_run_state \
    'waydroid() { echo "Container: STOPPED"; echo "Session: STOPPED"; }; export -f waydroid' \
    'require_state SESSION_RUNNING' &>/dev/null
assert_eq "require_state() falha com STOPPED" "1" "$?"

# require_state() falha quando estado é CONTAINER_ONLY e requer SESSION
_run_state \
    'waydroid() { echo "Container: RUNNING"; echo "Session: STOPPED"; }; export -f waydroid' \
    'require_state SESSION_RUNNING' &>/dev/null
assert_eq "require_state() falha com CONTAINER_ONLY para SESSION" "1" "$?"

# require_state() passa CONTAINER_ONLY quando container está ativo
_run_state \
    'waydroid() { echo "Container: RUNNING"; echo "Session: STOPPED"; }; export -f waydroid' \
    'require_state CONTAINER_ONLY' &>/dev/null
assert_eq "require_state() passa CONTAINER_ONLY com container ativo" "0" "$?"

rm -rf /tmp/wdroid-test-logs-* /tmp/wdroid-test-state-* 2>/dev/null || true
