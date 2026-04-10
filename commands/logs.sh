#!/bin/bash
# =============================================================================
# commands/logs.sh — Visualização de logs (container e wdroid)
# =============================================================================

MODE="${1:-container}"
LINES="${2:-50}"

header "LOGS — $MODE"

case "$MODE" in
    container)
        journalctl -u "$WAYDROID_CONTAINER" --no-pager -n "$LINES"
        ;;
    wdroid)
        if [ -f "$_LOG_FILE" ]; then
            tail -n "$LINES" "$_LOG_FILE"
        else
            warn "Sem logs wdroid nesta sessão."
        fi
        ;;
    all)
        section "Container (últimas $LINES linhas)"
        journalctl -u "$WAYDROID_CONTAINER" --no-pager -n "$LINES"
        echo ""
        section "wdroid (últimas $LINES linhas)"
        [ -f "$_LOG_FILE" ] && tail -n "$LINES" "$_LOG_FILE" || notice "Sem logs."
        ;;
    follow|-f)
        log "Seguindo logs do container (Ctrl+C para sair)..."
        journalctl -u "$WAYDROID_CONTAINER" -f
        ;;
    *)
        echo "Uso: wdroid logs [container|wdroid|all|follow] [linhas]"
        ;;
esac
