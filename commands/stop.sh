#!/bin/bash
# =============================================================================
# commands/stop.sh — Encerramento limpo com state machine
# =============================================================================

_stop_usage() {
    echo "Uso: wdroid stop"
}

case "${1:-}" in
    "")
        ;;
    help|--help|-h)
        _stop_usage
        return 0
        ;;
    *)
        _stop_usage
        return 1
        ;;
esac

_load_modules session container

header "PARANDO WAYDROID"

STATE=$(get_state)
log "Estado atual: $(print_state)"

case "$STATE" in
    STOPPED)
        log "Ambiente já está parado."
        return 0
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
