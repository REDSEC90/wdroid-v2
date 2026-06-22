#!/bin/bash
# =============================================================================
# commands/fix.sh — Correcao automatica de problemas comuns
# =============================================================================

_fix_usage() {
    echo "Uso: wdroid fix"
}

case "${1:-}" in
    "")
        ;;
    help|--help|-h)
        _fix_usage
        return 0
        ;;
    *)
        _fix_usage
        return 1
        ;;
esac

_load_modules container session network

header "CORREÇÃO AUTOMÁTICA"

fix_network

if ! is_container_running; then
    start_container
else
    restart_container
fi

sleep 2

if ! is_session_running; then
    start_session
fi

log "Executando diagnóstico pós-correção..."
_run_command doctor
