#!/bin/bash
# tests/test_syntax.sh — Verifica sintaxe de todos os scripts

suite "Sintaxe dos scripts"

_scripts=(
    "$BASE_DIR/bin/wdroid"
    "$BASE_DIR/core/config.sh"
    "$BASE_DIR/core/logger.sh"
    "$BASE_DIR/core/lock.sh"
    "$BASE_DIR/core/utils.sh"
    "$BASE_DIR/core/state.sh"
    "$BASE_DIR/core/plugin.sh"
    "$BASE_DIR/modules/app.sh"
    "$BASE_DIR/modules/session.sh"
    "$BASE_DIR/modules/container.sh"
    "$BASE_DIR/modules/network.sh"
    "$BASE_DIR/modules/backup.sh"
    "$BASE_DIR/commands/start.sh"
    "$BASE_DIR/commands/stop.sh"
    "$BASE_DIR/commands/status.sh"
    "$BASE_DIR/commands/doctor.sh"
    "$BASE_DIR/commands/reset.sh"
    "$BASE_DIR/commands/logs.sh"
    "$BASE_DIR/plugins/whatsapp.sh"
    "$BASE_DIR/plugins/tiktok.sh"
)

for _s in "${_scripts[@]}"; do
    _name="${_s#$BASE_DIR/}"
    if bash -n "$_s" 2>/dev/null; then
        pass "sintaxe OK: $_name"
    else
        fail "sintaxe INVÁLIDA: $_name" "$(bash -n "$_s" 2>&1)"
    fi
done
