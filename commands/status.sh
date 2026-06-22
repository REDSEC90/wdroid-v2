#!/bin/bash
# =============================================================================
# commands/status.sh — Status completo do sistema
# =============================================================================

_status_usage() {
    echo "Uso: wdroid status"
}

case "${1:-}" in
    "")
        ;;
    help|--help|-h)
        _status_usage
        return 0
        ;;
    *)
        _status_usage
        return 1
        ;;
esac

_load_modules container session network

_status_container_since() {
    local since
    since="$(systemctl show "$WAYDROID_CONTAINER" --property=ActiveEnterTimestamp 2>/dev/null \
        | sed 's/ActiveEnterTimestamp=//' \
        | sed 's/  / /g' || true)"
    printf "%s" "${since:-tempo indisponível}"
}

header "STATUS DO WAYDROID v${WDROID_VERSION}"

section "Estado geral"
printf "  Estado: %s\n" "$(print_state)"

section "Container"
if is_container_running; then
    ok "Ativo ($(_status_container_since))"
else
    fail "Inativo"
fi

section "Sessão Android"
if is_session_running; then
    ok "Ativa"
    waydroid status 2>/dev/null | sed '/^$/d; s/^/  /' || true
else
    fail "Inativa"
fi

print_network_status
# Health do subsistema de rede (v0.3+)
if declare -F network_print_health &>/dev/null; then
    network_print_health
fi

section "Sistema"
if check_kvm; then
    ok "KVM ativo (aceleração de hardware)"
else
    notice "KVM não detectado (performance reduzida)"
fi

if check_wayland; then
    ok "Sessão Wayland"
else
    fail "Wayland não detectado"
fi

section "Logs recentes"
if [ -f "$_LOG_FILE" ]; then
    tail -n 5 "$_LOG_FILE" | sed 's/^/  /'
else
    notice "Sem logs nesta sessão."
fi
