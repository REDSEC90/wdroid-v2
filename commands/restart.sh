#!/bin/bash
# =============================================================================
# commands/restart.sh — Reinicia ambiente Waydroid
# =============================================================================

_restart_usage() {
    echo "Uso: wdroid restart"
}

case "${1:-}" in
    "")
        ;;
    help|--help|-h)
        _restart_usage
        return 0
        ;;
    *)
        _restart_usage
        return 1
        ;;
esac

_run_command stop
sleep 1
_run_command start
