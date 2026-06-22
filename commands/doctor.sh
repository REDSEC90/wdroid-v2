#!/bin/bash
# =============================================================================
# commands/doctor.sh — Diagnóstico com health score e auto-fix opcional
# =============================================================================

_load_modules container session network

_doctor_usage() {
    echo "Uso: wdroid doctor [--fix|--help]"
}

AUTO_FIX=false
case "${1:-}" in
    "")
        ;;
    --fix)
        AUTO_FIX=true
        ;;
    help|--help|-h)
        _doctor_usage
        return 0
        ;;
    *)
        _doctor_usage
        return 1
        ;;
esac

header "DIAGNÓSTICO DO SISTEMA"

SCORE=0
TOTAL=0
ISSUES=()

_check() {
    local label="$1"
    local check_fn="$2"
    local fix_fn="${3:-}"
    ((TOTAL += 1))

    if "$check_fn" &>/dev/null; then
        ok "$label"
        ((SCORE += 1))
    else
        fail "$label"
        ISSUES+=("$label")
        if $AUTO_FIX && [ -n "$fix_fn" ]; then
            warn "Auto-fix: $label"
            "$fix_fn" || true
        fi
    fi
}

_cmd_waydroid()  { command -v waydroid; }
_cmd_systemctl() { command -v systemctl; }
_cmd_iptables()  {
    command -v iptables || command -v iptables-legacy || \
    command -v nft || [ -x /sbin/nft ] || [ -x /usr/sbin/nft ]
}
_fix_start_container() { sudo systemctl start "$WAYDROID_CONTAINER"; }
_fix_ip_forward() { sudo sysctl -w net.ipv4.ip_forward=1; }
_check_waydroid_data_dir() { [ -d "$WAYDROID_DATA_DIR" ]; }
_check_backup_dir() { [ -d "$BACKUP_DIR" ] || mkdir -p "$BACKUP_DIR"; }

section "Dependências"
_check "Waydroid instalado"          _cmd_waydroid
_check "systemctl disponível"        _cmd_systemctl
_check "iptables disponível"         _cmd_iptables

section "Hardware & sessão"
_check "KVM ativo"                   check_kvm
_check "Wayland habilitado"          check_wayland

section "Serviços"
_check "Container rodando"           is_container_running _fix_start_container
_check "Sessão Android ativa"        is_session_running

section "Rede"
_check "Interface $WAYDROID_IFACE"        check_network          fix_network
_check "IP forwarding"                    check_ip_forward       _fix_ip_forward
_check "IP do container configurado"      check_container_ip     fix_network
_check "Rota padrão no container"         check_default_route    fix_network
_check "Gateway acessível"               route_validate_default  fix_network
_check "Internet acessível"              network_is_online       fix_network
_check "DNS funcional"                   dns_is_healthy          fix_network

section "Armazenamento"
_check "Diretório Waydroid"          _check_waydroid_data_dir
_check "Diretório de backup"         _check_backup_dir

# Health score
echo ""
local_pct=$(( SCORE * 100 / TOTAL ))
printf "  ${_C_BOLD}Health score: %d/%d (%d%%)${_C_RESET}\n" "$SCORE" "$TOTAL" "$local_pct"

if [ ${#ISSUES[@]} -eq 0 ]; then
    printf "\n  ${_C_GREEN}✓ Sistema saudável.${_C_RESET}\n\n"
else
    printf "\n  ${_C_YELLOW}%d problema(s) encontrado(s):${_C_RESET}\n" "${#ISSUES[@]}"
    for issue in "${ISSUES[@]}"; do
        printf "    - %s\n" "$issue"
    done
    if ! $AUTO_FIX; then
        printf "\n  Dica: execute ${_C_BOLD}wdroid doctor --fix${_C_RESET} para corrigir automaticamente.\n\n"
    fi
fi
