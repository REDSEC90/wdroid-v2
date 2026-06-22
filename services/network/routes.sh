#!/bin/bash
# =============================================================================
# services/network/routes.sh — Rotas e interfaces do host
# =============================================================================

route_get_default() {
    ip route show default 2>/dev/null | awk '/^default/ {print $3; exit}'
}

route_validate_default() {
    local gw
    gw="$(route_get_default)"
    [ -z "$gw" ] && return 1
    ping -c1 -W2 -q "$gw" &>/dev/null
}

route_get_interfaces() {
    ip -o link show up 2>/dev/null | awk -F': ' '{print $2}' | grep -v "^lo$"
}
