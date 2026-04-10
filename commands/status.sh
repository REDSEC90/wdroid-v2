#!/bin/bash
# =============================================================================
# commands/status.sh — Status completo do sistema
# =============================================================================

_load_modules container session network

header "STATUS DO WAYDROID v${WDROID_VERSION}"

section "Estado geral"
printf "  Estado: %s\n" "$(print_state)"

section "Container"
if is_container_running; then
    ok "Ativo ($(systemctl show waydroid-container --property=ActiveEnterTimestamp \
        | sed 's/ActiveEnterTimestamp=//' | sed 's/  / /g'))"
else
    fail "Inativo"
fi

section "Sessão Android"
if is_session_running; then
    ok "Ativa"
    waydroid status 2>/dev/null | grep -v "^$" | sed 's/^/  /'
else
    fail "Inativa"
fi

print_network_status

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
