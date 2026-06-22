#!/bin/bash
# tests/test_lock.sh — Verifica lock exclusivo e lock leve

suite "Lock (core/lock.sh)"

_LOCK_TMP="/tmp/wdroid-lock-test-$$"
_LOCK_FILE="$_LOCK_TMP/nested/wdroid.lock"

_run_lock() {
    local script="$1"
    bash -c "
        export HOME=/tmp
        BASE_DIR='$BASE_DIR'
        WDROID_LOG_DIR='$_LOCK_TMP/logs'
        WDROID_LOCK_FILE='$_LOCK_FILE'
        source '$BASE_DIR/core/config.sh'
        source '$BASE_DIR/core/logger.sh'
        _init_logger
        source '$BASE_DIR/core/lock.sh'
        $script
    "
}

rm -rf "$_LOCK_TMP"
_run_lock 'acquire_lock; [ -f "$LOCK_FILE" ] && echo locked; _release_lock; [ ! -e "$LOCK_FILE" ] && echo released' >"$_LOCK_TMP.out" 2>/dev/null
_out=$(cat "$_LOCK_TMP.out" 2>/dev/null || true)
assert_contains "lock cria arquivo em diretório novo" "locked" "$_out"
assert_contains "release remove lock do próprio processo" "released" "$_out"

mkdir -p "$(dirname "$_LOCK_FILE")"
printf "999999\n" > "$_LOCK_FILE"
_run_lock 'acquire_lock; echo "$(<"$LOCK_FILE")"; _release_lock' >"$_LOCK_TMP.out" 2>/dev/null
_out=$(cat "$_LOCK_TMP.out" 2>/dev/null || true)
_orphan_replacement_pid=$(printf "%s\n" "$_out" | tail -n 1)
assert_eq "lock órfão é substituído" "0" "$?"
assert_not_eq "lock órfão não mantém PID antigo" "999999" "$_orphan_replacement_pid"
if [[ "$_orphan_replacement_pid" =~ ^[0-9]+$ ]]; then
    pass "lock órfão recebe PID numérico"
else
    fail "lock órfão recebe PID numérico" "$_orphan_replacement_pid"
fi

sleep 30 &
_LOCK_PID=$!
mkdir -p "$(dirname "$_LOCK_FILE")"
printf "%s\n" "$_LOCK_PID" > "$_LOCK_FILE"
_run_lock 'acquire_lock' &>/dev/null
assert_eq "lock ativo bloqueia lock exclusivo" "1" "$?"

_run_lock 'acquire_lock_soft' &>/dev/null
assert_eq "lock leve não bloqueia com processo ativo" "0" "$?"

kill "$_LOCK_PID" 2>/dev/null || true
wait "$_LOCK_PID" 2>/dev/null || true
rm -rf "$_LOCK_TMP" "$_LOCK_TMP.out" 2>/dev/null || true
