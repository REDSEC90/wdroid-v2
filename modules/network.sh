#!/bin/bash
# =============================================================================
# modules/network.sh — Diagnóstico e correção de rede
# =============================================================================

check_network() {
    ip addr show "$WAYDROID_IFACE" &>/dev/null
}

check_ip_forward() {
    [ "$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null)" = "1" ]
}

check_default_route() {
    waydroid shell ip route 2>/dev/null | grep -q "default"
}

fix_network() {
    warn "Aplicando correções de rede..."

    if ! check_network; then
        warn "Interface $WAYDROID_IFACE ausente. Reiniciando container..."
        restart_container
        sleep 2
    fi

    if ! check_ip_forward; then
        log "Ativando IP forwarding..."
        sudo sysctl -w net.ipv4.ip_forward=1 &>/dev/null
    fi

    log "Corrigindo rota padrão no container..."
    sudo waydroid shell ip route add default via "$WAYDROID_GATEWAY" dev eth0 2>/dev/null || true

    log "Ajustando iptables..."
    sudo iptables -P FORWARD ACCEPT 2>/dev/null || true

    log "Rede corrigida."
}

network_health() {
    # Retorna score numérico de saúde da rede (0-3)
    local score=0
    check_network     && ((score++)) || true
    check_ip_forward  && ((score++)) || true
    check_default_route && ((score++)) || true
    echo "$score"
}

print_network_status() {
    section "Rede"
    if check_network; then
        ok "Interface $WAYDROID_IFACE presente"
        ip addr show "$WAYDROID_IFACE" | grep "inet " | awk '{printf "    addr: %s\n", $2}'
    else
        fail "Interface $WAYDROID_IFACE ausente"
    fi

    if check_ip_forward; then
        ok "IP forwarding ativo"
    else
        fail "IP forwarding desativado"
    fi

    if check_default_route; then
        ok "Rota padrão configurada no container"
    else
        notice "Rota padrão ausente no container"
    fi
}
