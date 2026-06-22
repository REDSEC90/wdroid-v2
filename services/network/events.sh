#!/bin/bash
# =============================================================================
# services/network/events.sh — Sistema de eventos de rede
# =============================================================================

# Eventos emitidos: network_online, network_offline, network_degraded,
#                   network_recovered, dns_failure, dns_recovered

_NET_EVENT_LOG="${LOG_DIR:-$HOME/.wdroid/logs}/network-events.log"

network_emit() {
    local event="$1"
    local ts; ts="$(date '+%Y-%m-%d %H:%M:%S')"
    mkdir -p "$(dirname "$_NET_EVENT_LOG")"
    echo "[$ts] $event" >> "$_NET_EVENT_LOG"
    # Hook: se existir handler externo, executa
    declare -F "on_${event}" &>/dev/null && "on_${event}"
}

network_last_event() {
    tail -1 "$_NET_EVENT_LOG" 2>/dev/null | awk '{print $NF}'
}
