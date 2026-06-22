#!/bin/bash
# =============================================================================
# services/network/connectivity.sh — Verificação de conectividade de internet
# =============================================================================

# Probes usados para checar internet (sem curl obrigatório)
_NET_PROBES=("8.8.8.8" "1.1.1.1" "9.9.9.9")
_NET_PROBE_TIMEOUT=2

network_get_interface() {
    ip route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<NF;i++) if($i=="dev"){print $(i+1); exit}}'
}

network_get_gateway() {
    ip route show default 2>/dev/null | awk '/^default/ {print $3; exit}'
}

network_ping_check() {
    local probe
    for probe in "${_NET_PROBES[@]}"; do
        ping -c1 -W"$_NET_PROBE_TIMEOUT" -q "$probe" &>/dev/null && return 0
    done
    return 1
}

network_is_online() {
    local iface gateway
    iface="$(network_get_interface)"
    gateway="$(network_get_gateway)"

    [ -z "$iface" ] && return 1
    [ -z "$gateway" ] && return 1
    network_ping_check
}

network_get_latency() {
    # Retorna latência em ms para o primeiro probe que responder
    local probe result
    for probe in "${_NET_PROBES[@]}"; do
        result=$(ping -c2 -W"$_NET_PROBE_TIMEOUT" -q "$probe" 2>/dev/null \
            | awk -F'/' '/rtt/ {printf "%.0f", $5}')
        if [ -n "$result" ]; then
            echo "${result}ms"
            return 0
        fi
    done
    echo "N/A"
}
