#!/bin/bash
# tests/test_whatsapp_plugin.sh — Verifica plugin WhatsApp

suite "Plugin WhatsApp (plugins/whatsapp.sh)"

_run_whatsapp() {
    bash -c "
        export HOME=/tmp
        WDROID_LOG_DIR=/tmp/wdroid-test-logs-$$
        STATE_FILE=/tmp/wdroid-test-state-$$
        BASE_DIR='$BASE_DIR'
        source '$BASE_DIR/core/config.sh'
        source '$BASE_DIR/core/logger.sh'
        _init_logger
        _load_modules() {
            for m in \"\$@\"; do source \"\$BASE_DIR/modules/\$m.sh\" 2>/dev/null || true; done
        }
        $1
        source '$BASE_DIR/core/state.sh'
        source '$BASE_DIR/plugins/whatsapp.sh'
        plugin_main $2
    "
}

# help não lança erro
_run_whatsapp '' 'help' &>/dev/null
assert_eq "plugin_main help não lança erro" "0" "$?"

# help mostra ações
_out=$(_run_whatsapp '' 'help')
assert_contains "help mostra 'open'"       "open"       "$_out"
assert_contains "help mostra 'send'"       "send"       "$_out"
assert_contains "help mostra 'screenshot'" "screenshot" "$_out"
assert_contains "help mostra 'adb'"        "adb"        "$_out"

# open requer sessão — falha quando STOPPED
_run_whatsapp \
    'systemctl() { return 1; }; export -f systemctl' \
    'open' &>/dev/null
assert_eq "open falha sem sessão ativa" "1" "$?"

# send sem argumento falha
_run_whatsapp \
    'systemctl() { return 0; }; export -f systemctl
     waydroid() { echo "Session: RUNNING"; }; export -f waydroid' \
    'send' &>/dev/null
assert_eq "send sem texto falha" "1" "$?"

rm -rf /tmp/wdroid-test-logs-* /tmp/wdroid-test-state-* 2>/dev/null || true
