#!/bin/bash
# =============================================================================
# modules/network.sh — Diagnóstico e correção de rede (modo agressivo)
# =============================================================================

check_network() {
    ip addr show "$WAYDROID_IFACE" &>/dev/null
}

check_ip_forward() {
    [ "$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null)" = "1" ]
}

# Detecta PID do processo no network namespace do container Android via eth0+MAC.
# Cache em /tmp para evitar varredura cara repetida.
_android_ns_pid() {
    local mac="${WAYDROID_CONTAINER_MAC:-00:16:3e:f9:d3:03}"
    local cache="/tmp/wdroid-android-nspid"

    if [ -f "$cache" ]; then
        local cpid; cpid="$(cat "$cache")"
        if [ -d "/proc/$cpid" ] && sudo nsenter --net="/proc/$cpid/ns/net" -- \
                ip link show eth0 2>/dev/null | grep -q "$mac"; then
            echo "$cpid"; return 0
        fi
        rm -f "$cache"
    fi

    local pid
    for pid in $(ls /proc/ 2>/dev/null | grep -E '^[0-9]+$'); do
        [ -r "/proc/$pid/ns/net" ] || continue
        # Busca especificamente eth0 com o MAC correto (evita pegar o host)
        sudo nsenter --net="/proc/$pid/ns/net" -- \
            ip link show eth0 2>/dev/null | grep -q "$mac" || continue
        echo "$pid" > "$cache"
        echo "$pid"; return 0
    done
    return 1
}

check_default_route() {
    local pid; pid="$(_android_ns_pid)" || return 1
    sudo nsenter --net="/proc/$pid/ns/net" -- ip route 2>/dev/null | grep -q "^default"
}

check_container_ip() {
    local pid; pid="$(_android_ns_pid)" || return 1
    sudo nsenter --net="/proc/$pid/ns/net" -- ip addr show eth0 2>/dev/null | grep -q "inet "
}

_host_wan_iface() {
    ip route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<NF;i++) if($i=="dev"){print $(i+1);exit}}'
}

# Ativa forwarding IPv4 + IPv6 e desbloqueia rp_filter no host
_enable_forwarding() {
    sudo sysctl -w net.ipv4.ip_forward=1                     &>/dev/null || true
    sudo sysctl -w net.ipv6.conf.all.forwarding=1             &>/dev/null || true
    sudo sysctl -w net.ipv4.conf.all.rp_filter=0              &>/dev/null || true
    sudo sysctl -w "net.ipv4.conf.${WAYDROID_IFACE}.rp_filter=0" &>/dev/null || true
}

# Abre INPUT e FORWARD para waydroid0 no firewall nftables do sistema (se existir)
_fix_nft_forward() {
    command -v nft &>/dev/null || return 0

    # Abre INPUT (necessário para dnsmasq receber DHCP requests do container)
    if sudo nft list table inet filter 2>/dev/null | grep -A5 "chain input" | grep -q "policy drop"; then
        sudo nft add rule inet filter input iifname "$WAYDROID_IFACE" accept 2>/dev/null || true
    fi

    # Abre FORWARD
    if sudo nft list table inet filter 2>/dev/null | grep -A5 "chain forward" | grep -q "policy drop"; then
        sudo nft add rule inet filter forward iifname "$WAYDROID_IFACE" accept 2>/dev/null || true
        sudo nft add rule inet filter forward oifname "$WAYDROID_IFACE" accept 2>/dev/null || true
    fi
}

# Garante que o dnsmasq do waydroid está servindo DNS/gateway via DHCP
_fix_dnsmasq() {
    local pid
    pid=$(pgrep -f "dnsmasq.*${WAYDROID_IFACE}" 2>/dev/null | head -1)

    # Verifica se o dnsmasq atual já envia as opções DNS e gateway
    if [ -n "$pid" ] && grep -qw "dhcp-option=6" /proc/$pid/cmdline 2>/dev/null; then
        return 0
    fi

    # Mata instância sem as opções e relança com DNS + gateway
    [ -n "$pid" ] && sudo kill "$pid" 2>/dev/null && sleep 0.5

    local lease_file="/var/lib/misc/dnsmasq.${WAYDROID_IFACE}.leases"
    local pid_file="/run/waydroid-lxc/dnsmasq.pid"

    sudo dnsmasq \
        --conf-file=/dev/null \
        --strict-order --bind-interfaces \
        --pid-file="$pid_file" \
        --listen-address "$WAYDROID_GATEWAY" \
        --dhcp-range "${WAYDROID_GATEWAY%.*}.2,${WAYDROID_GATEWAY%.*}.254" \
        --dhcp-lease-max=253 --dhcp-no-override \
        --except-interface=lo --interface="$WAYDROID_IFACE" \
        --dhcp-leasefile="$lease_file" \
        --dhcp-authoritative \
        --dhcp-option=3,"$WAYDROID_GATEWAY" \
        --dhcp-option=6,8.8.8.8,1.1.1.1 \
        --server=8.8.8.8 --server=1.1.1.1 2>/dev/null || true
}

# Configura MASQUERADE + regras FORWARD para o container ter acesso irrestrito
_fix_masquerade() {
    local net="${WAYDROID_GATEWAY%.*}.0/24"

    if command -v nft &>/dev/null; then
        # nftables: cria tabela/chain idempotentemente
        sudo nft add table ip wdroid_nat 2>/dev/null || true
        sudo nft add chain ip wdroid_nat postrouting \
            '{ type nat hook postrouting priority 100; policy accept; }' 2>/dev/null || true
        sudo nft add rule ip wdroid_nat postrouting \
            ip saddr "$net" masquerade 2>/dev/null || true

        sudo nft add table ip wdroid_filter 2>/dev/null || true
        sudo nft add chain ip wdroid_filter forward \
            '{ type filter hook forward priority 0; policy accept; }' 2>/dev/null || true
        sudo nft add rule ip wdroid_filter forward \
            ip saddr "$net" accept 2>/dev/null || true
        sudo nft add rule ip wdroid_filter forward \
            ip daddr "$net" ct state related,established accept 2>/dev/null || true
    else
        local ipt; command -v iptables-legacy &>/dev/null && ipt=iptables-legacy || ipt=iptables

        # NAT / MASQUERADE
        if [ -n "$iface" ]; then
            sudo $ipt -t nat -C POSTROUTING -s "$net" -o "$iface" -j MASQUERADE 2>/dev/null || \
                sudo $ipt -t nat -A POSTROUTING -s "$net" -o "$iface" -j MASQUERADE 2>/dev/null || true
        fi
        # MASQUERADE sem filtro de saída (fallback)
        sudo $ipt -t nat -C POSTROUTING -s "$net" -j MASQUERADE 2>/dev/null || \
            sudo $ipt -t nat -A POSTROUTING -s "$net" -j MASQUERADE 2>/dev/null || true

        # FORWARD bidirecional
        sudo $ipt -C FORWARD -s "$net" -j ACCEPT 2>/dev/null || \
            sudo $ipt -A FORWARD -s "$net" -j ACCEPT 2>/dev/null || true
        sudo $ipt -C FORWARD -d "$net" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || \
            sudo $ipt -A FORWARD -d "$net" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true

        # Aceita tráfego na waydroid0
        sudo $ipt -C FORWARD -i "$WAYDROID_IFACE" -j ACCEPT 2>/dev/null || \
            sudo $ipt -A FORWARD -i "$WAYDROID_IFACE" -j ACCEPT 2>/dev/null || true
        sudo $ipt -C FORWARD -o "$WAYDROID_IFACE" -j ACCEPT 2>/dev/null || \
            sudo $ipt -A FORWARD -o "$WAYDROID_IFACE" -j ACCEPT 2>/dev/null || true
    fi
}

# Configura IP, rota e DNS diretamente no namespace de rede do container
_fix_container_ip() {
    local pid; pid="$(_android_ns_pid)" || { warn "Namespace Android não encontrado."; return 1; }
    local container_ip="${WAYDROID_GATEWAY%.*}.2"
    local ns="--net=/proc/$pid/ns/net"

    # Garante interface up
    sudo nsenter $ns -- ip link set eth0 up 2>/dev/null || true

    # IP
    sudo nsenter $ns -- ip addr add "$container_ip/24" dev eth0 2>/dev/null || true

    # Rota padrão na tabela main
    sudo nsenter $ns -- ip route del default 2>/dev/null || true
    sudo nsenter $ns -- ip route add default via "$WAYDROID_GATEWAY" dev eth0 2>/dev/null || true

    # Rotas nas tabelas de policy routing do Android (netd usa tabelas 97/98/99)
    for t in 97 98 99 1002; do
        sudo nsenter $ns -- ip route add default via "$WAYDROID_GATEWAY" dev eth0 table $t 2>/dev/null || true
    done

    # DNS via resolv.conf dentro do namespace
    sudo nsenter $ns -- sh -c \
        'printf "nameserver 8.8.8.8\nnameserver 1.1.1.1\n" > /etc/resolv.conf' \
        2>/dev/null || true

    # DNS via setprop Android (camada extra de garantia)
    waydroid_shell setprop net.dns1 8.8.8.8  2>/dev/null || true
    waydroid_shell setprop net.dns2 1.1.1.1  2>/dev/null || true
    waydroid_shell setprop net.dns3 8.8.4.4  2>/dev/null || true

    # Sinaliza Android para reconectar rede
    waydroid_shell am broadcast -a android.net.conn.CONNECTIVITY_CHANGE 2>/dev/null || true
}

# Fallback: conecta WiFi no Android usando credenciais do host ou SSID/senha configurados.
# Usado quando NAT falha e o container precisa de acesso independente.
_fix_wifi_fallback() {
    local ssid="${WDROID_WIFI_SSID:-Weldes_5g}"
    local pass="${WDROID_WIFI_PASS:-75469408}"

    log "Tentando fallback via WiFi Android ($ssid)..."

    # Ativa WiFi no Android
    sudo waydroid shell svc wifi enable 2>/dev/null || true
    sleep 2

    # Adiciona e conecta a rede via cmd wifi (Android 10+)
    local net_id
    net_id=$(sudo waydroid shell cmd wifi add-network "$ssid" WPA "$pass" 2>/dev/null | grep -oE '[0-9]+' | head -1)

    if [ -n "$net_id" ]; then
        sudo waydroid shell cmd wifi connect-network "$net_id" 2>/dev/null || true
        sleep 3
        sudo waydroid shell cmd wifi status 2>/dev/null | grep -q "CONNECTED" && \
            log "WiFi conectado ($ssid)." || warn "WiFi não conectou."
    else
        # Fallback via wpa_supplicant direto no namespace
        local pid; pid="$(_android_ns_pid)" || return 1
        local conf=$(sudo nsenter --net="/proc/$pid/ns/net" -- \
            find /data /system -name wpa_supplicant.conf 2>/dev/null | head -1)
        [ -z "$conf" ] && conf="/data/misc/wifi/wpa_supplicant.conf"
        sudo nsenter --net="/proc/$pid/ns/net" -- sh -c "
cat >> '$conf' <<'EOF'
network={
    ssid=\"$ssid\"
    psk=\"$pass\"
    key_mgmt=WPA-PSK
    priority=100
}
EOF" 2>/dev/null || true
        sudo waydroid shell wpa_cli reconfigure 2>/dev/null || true
        sudo waydroid shell wpa_cli reconnect 2>/dev/null || true
    fi
}

fix_network() {
    warn "Aplicando correções de rede (modo agressivo)..."

    if ! check_network; then
        warn "Interface $WAYDROID_IFACE ausente. Reiniciando container..."
        restart_container
        sleep 3
    fi

    _enable_forwarding
    _fix_nft_forward
    _fix_dnsmasq

    log "Configurando NAT + FORWARD..."
    _fix_masquerade

    # Se container sem IP, força reconexão DHCP via link bounce
    if ! check_container_ip; then
        log "Forçando DHCP no container Android..."
        local pid; pid="$(_android_ns_pid)" && {
            sudo nsenter --net="/proc/$pid/ns/net" -- ip link set eth0 down 2>/dev/null || true
            sleep 0.3
            sudo nsenter --net="/proc/$pid/ns/net" -- ip link set eth0 up 2>/dev/null || true
            sleep 5
        } || true
    fi

    # Se NAT ainda não funcionar depois de tudo, tenta WiFi
    if ! network_is_online 2>/dev/null; then
        warn "NAT não funcional — tentando fallback WiFi..."
        _fix_wifi_fallback
    fi

    log "Rede configurada."
}
network_is_online() {
    local pid; pid="$(_android_ns_pid)" || return 1
    sudo nsenter --net="/proc/$pid/ns/net" -- \
        ping -c1 -W2 8.8.8.8 &>/dev/null
}

# Testa resolução DNS dentro do container
dns_is_healthy() {
    local pid; pid="$(_android_ns_pid)" || return 1
    sudo nsenter --net="/proc/$pid/ns/net" -- \
        sh -c 'getent hosts google.com || nslookup google.com 8.8.8.8' &>/dev/null
}

# Valida que o gateway responde (rota padrão acessível)
route_validate_default() {
    local pid; pid="$(_android_ns_pid)" || return 1
    sudo nsenter --net="/proc/$pid/ns/net" -- \
        ping -c1 -W2 "$WAYDROID_GATEWAY" &>/dev/null
}

network_health() {
    local score=0
    check_network          && score=$((score + 1))
    check_ip_forward       && score=$((score + 1))
    check_container_ip     && score=$((score + 1))
    check_default_route    && score=$((score + 1))
    route_validate_default && score=$((score + 1))
    network_is_online      && score=$((score + 1))
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
        local pid; pid="$(_android_ns_pid)" && \
            sudo nsenter --net="/proc/$pid/ns/net" -- ip addr show eth0 2>/dev/null \
            | awk '/inet / {printf "    addr: %s\n", $2}' || true
    else
        notice "Container sem IP"
    fi

    if check_default_route; then
        ok "Rota padrão configurada no container"
    else
        notice "Rota padrão ausente no container"
    fi

    if route_validate_default; then
        ok "Gateway $WAYDROID_GATEWAY acessível"
    else
        notice "Gateway não responde"
    fi

    if network_is_online; then
        ok "Internet acessível (8.8.8.8)"
    else
        notice "Sem acesso à internet"
    fi

    if dns_is_healthy; then
        ok "DNS funcional"
    else
        notice "DNS não resolve"
    fi
}
