#!/bin/bash
# tests/test_network.sh - Verifica diagnostico e correcao de rede

suite "Rede (modules/network.sh)"

_run_network() {
    local script="$1"
    bash -c "
        set -euo pipefail
        export HOME=/tmp
        WDROID_LOG_DIR=/tmp/wdroid-test-logs-$$
        BASE_DIR='$BASE_DIR'
        source \"\$BASE_DIR/core/config.sh\"
        source \"\$BASE_DIR/core/logger.sh\"
        _init_logger
        source \"\$BASE_DIR/core/utils.sh\"
        source \"\$BASE_DIR/modules/container.sh\"
        source \"\$BASE_DIR/modules/network.sh\"
        $script
    "
}

_out=$(_run_network '
    ip() {
        if [ "$1" = "addr" ] && [ "$2" = "show" ]; then
            echo "2: waydroid0: <BROADCAST,UP>"
            return 0
        fi
        return 1
    }
    waydroid_shell() { return 1; }
    print_network_status
')
assert_contains "status de rede não aborta sem IPv4" "Interface waydroid0 presente" "$_out"
assert_contains "status de rede mostra rota ausente" "Rota padrão ausente" "$_out"

_out=$(_run_network '
    check_network() { return 0; }
    check_ip_forward() { return 1; }
    waydroid_shell() { return 1; }
    sudo() {
        case "$1" in
            sysctl) return 1 ;;
            iptables) return 0 ;;
        esac
    }
    fix_network
')
assert_contains "fix_network avisa falha de sysctl" "Não foi possível ativar IP forwarding" "$_out"
assert_contains "fix_network conclui mesmo com sysctl falhando" "Rede corrigida" "$_out"

rm -rf /tmp/wdroid-test-logs-* 2>/dev/null || true
