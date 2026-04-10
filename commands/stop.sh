#!/bin/bash
# =============================================================================
# commands/stop.sh — Encerramento limpo com state machine
# =============================================================================

_load_modules session container

header "PARANDO WAYDROID"

STATE=$(get_state)
log "Estado atual: $(print_state)"

case "$STATE" in
    STOPPED)
        log "Ambiente já está parado."
        exit 0
        ;;
    CONTAINER_ONLY)
        stop_container
        ;;
    SESSION_RUNNING|APP_RUNNING)
        stop_session
        stop_container
        ;;
esac

log "Estado final: $(print_state)"
