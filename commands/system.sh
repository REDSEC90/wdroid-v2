#!/bin/bash
# =============================================================================
# commands/system.sh — Integracoes de sistema
# =============================================================================

SYSTEM_COMMAND="${1:-}"
shift || true

_system_usage() {
    echo "Uso: wdroid {autostart|no-autostart}"
}

_load_modules container

case "$SYSTEM_COMMAND" in
    autostart)
        [ "$#" -eq 0 ] || {
            _system_usage
            return 1
        }
        enable_autostart
        ;;
    no-autostart)
        [ "$#" -eq 0 ] || {
            _system_usage
            return 1
        }
        disable_autostart
        ;;
    help|--help|-h)
        _system_usage
        ;;
    *)
        _system_usage
        return 1
        ;;
esac
