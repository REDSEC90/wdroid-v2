#!/bin/bash
# tests/test_command_composition.sh — Verifica composicao de commands/*.sh

suite "Composição de comandos"

_run_sourced_command() {
    local command="$1"
    bash -c "
        export HOME=/tmp
        WDROID_LOG_DIR=/tmp/wdroid-test-logs-$$
        STATE_FILE=/tmp/wdroid-test-state-$$
        BASE_DIR='$BASE_DIR'
        source '$BASE_DIR/core/config.sh'
        source '$BASE_DIR/core/logger.sh'
        source '$BASE_DIR/core/utils.sh'
        source '$BASE_DIR/core/state.sh'
        _init_logger
        _load_modules() {
            for mod in \"\$@\"; do
                source \"\$BASE_DIR/modules/\$mod.sh\"
            done
        }
        waydroid() {
            if [ \"\$1\" = \"status\" ]; then
                echo 'Container: STOPPED'
                echo 'Session: STOPPED'
                return 0
            fi
            return 1
        }
        systemctl() { return 1; }
        sudo() { return 0; }
        sleep() { return 0; }
        export -f waydroid systemctl sudo sleep
        $command
    "
}

_out=$(_run_sourced_command "source '$BASE_DIR/commands/stop.sh'; echo after-stop")
assert_contains "stop retorna sem encerrar shell chamador" "after-stop" "$_out"

_out=$(printf 'n\nno\n' | _run_sourced_command "source '$BASE_DIR/commands/reset.sh'; echo after-reset")
assert_contains "reset cancelado retorna sem encerrar shell chamador" "after-reset" "$_out"

_out=$(printf 's\nyes\ns\n' | _run_sourced_command "
    _load_modules() { true; }
    backup_safe() { echo backup-safe; }
    stop_session() { echo stop-session; }
    stop_container() { echo stop-container; }
    sudo() { echo \"sudo:\$*\"; return 0; }
    source '$BASE_DIR/commands/reset.sh'
")
assert_contains "reset aceita s para backup" "backup-safe" "$_out"
assert_contains "reset aceita s para GAPPS" "sudo:waydroid init -s GAPPS" "$_out"

_out=$(bash -c "
    BASE_DIR='$BASE_DIR'
    _run_command() { echo \"\$1\"; }
    source '$BASE_DIR/commands/restart.sh'
")
assert_contains "restart chama stop" "stop" "$_out"
assert_contains "restart chama start" "start" "$_out"

_out=$(_run_sourced_command "
    _load_modules() { true; }
    send_text() { echo \"send:\$*\"; }
    source '$BASE_DIR/commands/app.sh' send-text ola mundo
")
assert_contains "send-text junta argumentos em mensagem" "send:ola mundo" "$_out"

rm -rf /tmp/wdroid-test-logs-* /tmp/wdroid-test-state-* 2>/dev/null || true
