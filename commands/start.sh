#!/bin/bash
# =============================================================================
# commands/start.sh — Inicialização com state machine
# =============================================================================

_start_usage() {
    echo "Uso: wdroid start"
}

case "${1:-}" in
    "")
        ;;
    help|--help|-h)
        _start_usage
        return 0
        ;;
    *)
        _start_usage
        return 1
        ;;
esac

_load_modules container session network app

header "INICIANDO WAYDROID v${WDROID_VERSION}"

require_cmd waydroid

if ! check_wayland; then
    warn "Wayland não detectado — Waydroid pode não funcionar."
fi

STATE=$(get_state)
log "Estado atual: $(print_state)"

case "$STATE" in
    STOPPED)
        start_container
        start_session
        ;;
    CONTAINER_ONLY)
        log "Container já ativo."
        start_session
        ;;
    SESSION_RUNNING|APP_RUNNING)
        log "Sessão já ativa."
        ;;
esac

log "Verificando rede do container..."
fix_network

launch_app "$APP_PACKAGE"

log "Estado final: $(print_state)"
