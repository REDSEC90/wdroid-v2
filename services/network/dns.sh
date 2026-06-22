#!/bin/bash
# =============================================================================
# services/network/dns.sh — Verificação e status de DNS
# =============================================================================

_DNS_HOSTS=("google.com" "github.com" "cloudflare.com")

dns_resolve_check() {
    local host
    for host in "${_DNS_HOSTS[@]}"; do
        getent hosts "$host" &>/dev/null && return 0
    done
    return 1
}

dns_is_healthy() {
    dns_resolve_check
}

dns_get_status() {
    dns_is_healthy && echo "DNS_HEALTHY" || echo "DNS_FAILURE"
}
