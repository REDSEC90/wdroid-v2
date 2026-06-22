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
    waydroid_shell ip route 2>/dev/null | grep -q "default"
}

check_container_ip() {
    waydroid_shell ip addr show eth0 2>/dev/null | grep -q "inet "
}

# Detecta a interface de saída real do host (ex: wlp3s0, eth0, enp3s0)
_host_wan_iface() {
    ip route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<NF;i++) if($i=="dev") {print $(i+1); exit}}'
}

_fix_masquerade() {
    local iface
    iface="$(_host_wan_iface)"
    [ -z "$iface" ] && { warn "Interface WAN não detectada, pulando MASQUERADE."; return; }

    # Tenta iptables-legacy primeiro (Debian com nftables), depois iptables
    local ipt="iptables"
    iptables-legacy -L &>/dev/null 2>&1 && ipt="iptables-legacy"

    # Remove regra genérica antiga se existir e adiciona específica para WAN
    $ipt -t nat -C POSTROUTING -s "${WAYDROID_GATEWAY%.*}.0/24" -o "$iface" -j MASQUERADE 2>/dev/null || \
        sudo $ipt -t nat -A POSTROUTING -s "${WAYDROID_GATEWAY%.*}.0/24" -o "$iface" -j MASQUERADE 2>/dev/null || true
    sudo $ipt -P FORWARD ACCEPT 2>/dev/null || true
}

_fix_container_ip() {
    local container_ip="${WAYDROID_GATEWAY%.*}.2"
    waydroid_shell ip addr add "$container_ip/24" dev eth0 2>/dev/null || true
    waydroid_shell ip route add default via "$WAYDROID_GATEWAY" dev eth0 2>/dev/null || true
    # DNS via setprop
    waydroid_shell setprop net.dns1 8.8.8.8 2>/dev/null || true
    waydroid_shell setprop net.dns2 1.1.1.1 2>/dev/null || true
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
        sudo sysctl -w net.ipv4.ip_forward=1 &>/dev/null || \
            warn "Não foi possível ativar IP forwarding."
    fi

    log "Configurando MASQUERADE na interface WAN..."
    _fix_masquerade

    if ! check_container_ip; then
        log "Atribuindo IP estático ao container Android..."
        _fix_container_ip
    elif ! check_default_route; then
        log "Corrigindo rota padrão no container..."
        waydroid_shell ip route add default via "$WAYDROID_GATEWAY" dev eth0 2>/dev/null || true
        waydroid_shell setprop net.dns1 8.8.8.8 2>/dev/null || true
    fi

    log "Rede corrigida."
}

network_health() {
    local score=0
    check_network && score=$((score + 1))
    check_ip_forward && score=$((score + 1))
    check_container_ip && score=$((score + 1))
    check_default_route && score=$((score + 1))
    echo "$score"
}

print_network_status() {
    section "Rede"
    if check_network; then
        ok "Interface $WAYDROID_IFACE presente"
        ip addr show "$WAYDROID_IFACE" | awk '/inet / {printf "    addr: %s\n", $2}' || true
    else
        fail "Interface $WAYDROID_IFACE ausente"
    fi

    if check_ip_forward; then
        ok "IP forwarding ativo"
    else
        fail "IP forwarding desativado"
    fi

    if check_container_ip; then
        ok "IP do container configurado"
        waydroid_shell ip addr show eth0 2>/dev/null | awk '/inet / {printf "    addr: %s\n", $2}' || true
    else
        notice "Container sem IP (DHCP não respondeu)"
    fi

    if check_default_route; then
        ok "Rota padrão configurada no container"
    else
        notice "Rota padrão ausente no container"
    fi
}
