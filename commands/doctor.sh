#!/bin/bash
# =============================================================================
# commands/doctor.sh — Diagnóstico com health score e auto-fix opcional
# =============================================================================

_load_modules container session network

AUTO_FIX=false
[ "${1:-}" = "--fix" ] && AUTO_FIX=true

header "DIAGNÓSTICO DO SISTEMA"

SCORE=0
TOTAL=0
ISSUES=()

_check() {
    local label="$1"
    local condition="$2"
    local fix_cmd="${3:-}"
    ((TOTAL++))

    if eval "$condition" &>/dev/null; then
        ok "$label"
        ((SCORE++))
    else
        fail "$label"
        ISSUES+=("$label")
        if $AUTO_FIX && [ -n "$fix_cmd" ]; then
            warn "Auto-fix: $fix_cmd"
            eval "$fix_cmd" || true
        fi
    fi
}

section "Dependências"
_check "Waydroid instalado"          "command -v waydroid"
_check "systemctl disponível"        "command -v systemctl"
_check "iptables disponível"         "command -v iptables"

section "Hardware & sessão"
_check "KVM ativo"                   "check_kvm"
_check "Wayland habilitado"          "check_wayland"

section "Serviços"
_check "Container rodando"           "is_container_running" \
    "sudo systemctl start $WAYDROID_CONTAINER"
_check "Sessão Android ativa"        "is_session_running"

section "Rede"
_check "Interface $WAYDROID_IFACE"   "check_network"           "fix_network"
_check "IP forwarding"               "check_ip_forward"        "sudo sysctl -w net.ipv4.ip_forward=1"
_check "Rota padrão no container"    "check_default_route"

section "Armazenamento"
_check "Diretório Waydroid"          "[ -d '$WAYDROID_DATA_DIR' ]"
_check "Diretório de backup"         "[ -d '$BACKUP_DIR' ] || mkdir -p '$BACKUP_DIR'"

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
