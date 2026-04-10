#!/bin/bash
# =============================================================================
# commands/start.sh — Inicialização com state machine
# =============================================================================

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

if ! check_network; then
    warn "Rede com problema — aplicando correção automática..."
    fix_network
fi

launch_app "$APP_PACKAGE"

log "Estado final: $(print_state)"
