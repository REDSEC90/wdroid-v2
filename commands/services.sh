#!/bin/bash
# =============================================================================
# commands/services.sh — Roteamento de Play Store e Xiaomi Cloud
# =============================================================================

SERVICE_COMMAND="${1:-}"
shift || true

_load_modules app session services

case "$SERVICE_COMMAND" in
    playstore)
        playstore_cmd "$@"
        ;;
    micloud|mi-cloud)
        micloud_cmd "$@"
        ;;
    *)
        die "Uso: wdroid {playstore|micloud} ..."
        ;;
esac
