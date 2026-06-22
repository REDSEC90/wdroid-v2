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

_android_ns_pid() {
    local mac="${WAYDROID_CONTAINER_MAC:-00:16:3e:f9:d3:03}"
    # Cache do PID para evitar varredura repetida
    local cache="/tmp/wdroid-android-nspid"
    if [ -f "$cache" ]; then
        local cached_pid; cached_pid="$(cat "$cache")"
        sudo nsenter --net="/proc/$cached_pid/ns/net" -- ip link show 2>/dev/null | grep -q "$mac" && {
            echo "$cached_pid"; return 0
        }
        rm -f "$cache"
    fi
    local pid
    for pid in $(ls /proc/ 2>/dev/null | grep -E '^[0-9]+$'); do
        local ns="/proc/$pid/ns/net"
        [ -r "$ns" ] || continue
        sudo nsenter --net="$ns" -- ip link show 2>/dev/null | grep -q "$mac" || continue
        echo "$pid" > "$cache"
        echo "$pid"
        return 0
    done
    return 1
}

check_default_route() {
    local pid
    pid="$(_android_ns_pid)" || return 1
    sudo nsenter --net="/proc/$pid/ns/net" -- ip route 2>/dev/null | grep -q "^default"
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

    # Detecta ferramenta disponível: nft > iptables-legacy > iptables
    local nft_bin; nft_bin="$(command -v nft || echo /sbin/nft)"
    if [ -x "$nft_bin" ]; then
        sudo "$nft_bin" add table ip wdroid_nat 2>/dev/null || true
        sudo "$nft_bin" add chain ip wdroid_nat postrouting \
            '{ type nat hook postrouting priority 100; }' 2>/dev/null || true
        sudo "$nft_bin" add rule ip wdroid_nat postrouting \
            ip saddr "${WAYDROID_GATEWAY%.*}.0/24" oif "$iface" masquerade 2>/dev/null || true
    else
        local ipt
        command -v iptables-legacy &>/dev/null && ipt="iptables-legacy" || ipt="iptables"
        $ipt -t nat -C POSTROUTING -s "${WAYDROID_GATEWAY%.*}.0/24" -o "$iface" -j MASQUERADE 2>/dev/null || \
            sudo $ipt -t nat -A POSTROUTING -s "${WAYDROID_GATEWAY%.*}.0/24" -o "$iface" -j MASQUERADE 2>/dev/null || true
    fi
    sudo sysctl -w net.ipv4.ip_forward=1 &>/dev/null || true
}

_android_ns_pid() {
    local mac="${WAYDROID_CONTAINER_MAC:-00:16:3e:f9:d3:03}"
    local pid
    for pid in $(ls /proc/ 2>/dev/null | grep -E '^[0-9]+$'); do
        local ns="/proc/$pid/ns/net"
        [ -r "$ns" ] || continue
        sudo nsenter --net="$ns" -- ip link show 2>/dev/null | grep -q "$mac" && echo "$pid" && return 0
    done
    return 1
}

_fix_container_ip() {
    local container_ip="${WAYDROID_GATEWAY%.*}.2"
    local pid
    pid="$(_android_ns_pid)" || { warn "Namespace do Android não encontrado."; return 1; }

    sudo nsenter --net="/proc/$pid/ns/net" -- ip addr add "$container_ip/24" dev eth0 2>/dev/null || true
    sudo nsenter --net="/proc/$pid/ns/net" -- ip route add default via "$WAYDROID_GATEWAY" dev eth0 onlink 2>/dev/null || true
    # DNS via setprop (funciona independente do namespace de rede)
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
