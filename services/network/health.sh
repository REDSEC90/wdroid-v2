#!/bin/bash
# =============================================================================
# services/network/health.sh — Estado consolidado de rede
# Estados: OFFLINE | CONNECTING | ONLINE | DEGRADED | RECOVERING
# =============================================================================

# Carrega serviços necessários (idempotente)
_net_load_services() {
    local svc_dir
    svc_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    for svc in connectivity dns routes events cache; do
        # shellcheck source=/dev/null
        [ "$(type -t "network_is_online")" = "function" ] || source "$svc_dir/$svc.sh"
    done
    source "$svc_dir/connectivity.sh"
    source "$svc_dir/dns.sh"
    source "$svc_dir/routes.sh"
    source "$svc_dir/events.sh"
    source "$svc_dir/cache.sh"
}
_net_load_services

# Determina o estado atual da rede
network_get_state() {
    local online dns_ok gw_ok

    gw_ok=false;  route_validate_default  && gw_ok=true
    online=false; network_is_online       && online=true
    dns_ok=false; dns_is_healthy          && dns_ok=true

    if $online && $dns_ok && $gw_ok; then
        echo "ONLINE"
    elif $gw_ok && ! $online; then
        echo "DEGRADED"
    elif ! $gw_ok && ! $online; then
        echo "OFFLINE"
    else
        echo "DEGRADED"
    fi
}

# Coleta e persiste snapshot completo de saúde
network_health_check() {
    local state internet dns latency gw

    state="$(network_get_state)"
    latency="$(network_get_latency)"
    dns="$(dns_get_status)"
    gw="$(route_get_default)"
    internet="$( [ "$state" = "ONLINE" ] && echo "online" || echo "offline" )"

    net_cache_save_state "$internet" "$dns" "$latency" "$state"

    # Emite evento se estado mudou
    local prev_state; prev_state="$(net_cache_get last_state)"
    if [ -n "$prev_state" ] && [ "$prev_state" != "$state" ]; then
        case "$state" in
            ONLINE)   network_emit "network_online"   ;;
            OFFLINE)  network_emit "network_offline"  ;;
            DEGRADED) network_emit "network_degraded" ;;
        esac
    fi

    printf '{"internet":"%s","dns":"%s","gateway":"%s","latency":"%s","state":"%s"}\n' \
        "$internet" "$dns" "${gw:-N/A}" "$latency" "$state"
}

# Saída legível para wdroid status / doctor
network_print_health() {
    local check; check="$(network_health_check)"
    local state internet dns gw latency
    state=$(echo "$check"   | grep -oP '"state":"\K[^"]+')
    internet=$(echo "$check" | grep -oP '"internet":"\K[^"]+')
    dns=$(echo "$check"     | grep -oP '"dns":"\K[^"]+')
    gw=$(echo "$check"      | grep -oP '"gateway":"\K[^"]+')
    latency=$(echo "$check" | grep -oP '"latency":"\K[^"]+')

    local _ok='\033[0;32m✓\033[0m'
    local _fail='\033[0;31m✗\033[0m'
    local _warn='\033[1;33m!\033[0m'

    printf "  %b Internet: %s\n"      "$( [ "$internet" = "online"  ] && echo "$_ok" || echo "$_fail" )" "$internet"
    printf "  %b DNS: %s\n"           "$( [ "$dns" = "DNS_HEALTHY"  ] && echo "$_ok" || echo "$_fail" )" "$dns"
    printf "  %b Gateway: %s\n"       "$( [ "$gw" != "N/A"          ] && echo "$_ok" || echo "$_warn" )" "${gw:-N/A}"
    printf "  %b Latência: %s\n"      "$_ok" "$latency"
    printf "  %b Network State: %s\n" "$( [ "$state" = "ONLINE"     ] && echo "$_ok" || echo "$_warn" )" "$state"
}
