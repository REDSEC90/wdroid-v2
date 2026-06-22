#!/bin/bash
# =============================================================================
# services/network/cache.sh — Persistência de estado de rede
# =============================================================================

_NET_CACHE_DIR="${HOME}/.local/share/wdroid/network"

_net_cache_init() {
    mkdir -p "$_NET_CACHE_DIR"
}

net_cache_set() {
    local key="$1" value="$2"
    _net_cache_init
    echo "$value" > "$_NET_CACHE_DIR/$key"
}

net_cache_get() {
    local key="$1"
    cat "$_NET_CACHE_DIR/$key" 2>/dev/null
}

net_cache_save_state() {
    local internet="$1" dns="$2" latency="$3" state="$4"
    net_cache_set "last_state"      "$state"
    net_cache_set "last_dns_status" "$dns"
    net_cache_set "last_latency"    "$latency"
    net_cache_set "last_check"      "$(date '+%Y-%m-%d %H:%M:%S')"
}
