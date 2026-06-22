#!/bin/bash
# =============================================================================
# services/network/retry.sh — Reconexão com backoff exponencial + jitter ±10%
# =============================================================================

_NET_RETRY_DELAYS=(1 2 4 8 16 32 60)
_NET_RETRY_MAX=7

# Aplica jitter ±10% a um valor inteiro
_net_jitter() {
    local base="$1"
    local jitter=$(( base / 10 ))
    local rand=$(( RANDOM % (jitter * 2 + 1) - jitter ))
    echo $(( base + rand ))
}

# Tenta reconectar chamando $1 até ter sucesso ou esgotar tentativas
# Uso: network_retry_until <função_de_verificação> [<função_de_correção>]
network_retry_until() {
    local check_fn="$1"
    local fix_fn="${2:-}"
    local attempt delay

    for attempt in $(seq 0 $(( _NET_RETRY_MAX - 1 ))); do
        "$check_fn" && return 0

        delay="${_NET_RETRY_DELAYS[$attempt]:-60}"
        delay="$(_net_jitter "$delay")"

        warn "Rede indisponível. Tentativa $((attempt+1))/$_NET_RETRY_MAX. Aguardando ${delay}s..."
        [ -n "$fix_fn" ] && "$fix_fn" 2>/dev/null || true
        sleep "$delay"
    done

    return 1
}
