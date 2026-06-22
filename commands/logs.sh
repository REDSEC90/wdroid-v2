#!/bin/bash
# =============================================================================
# commands/logs.sh — Visualização de logs (container e wdroid)
# =============================================================================

MODE="${1:-container}"
LINES="${2:-50}"

_logs_usage() {
    echo "Uso: wdroid logs [container|wdroid|all|follow] [linhas]"
}

_logs_journalctl() {
    if ! command -v journalctl &>/dev/null; then
        warn "journalctl não encontrado; logs do container indisponíveis."
        return 0
    fi

    journalctl "$@" || {
        warn "Não foi possível ler logs do container: $WAYDROID_CONTAINER"
        return 0
    }
}

if [ "$MODE" != "follow" ] && [ "$MODE" != "-f" ] && ! [[ "$LINES" =~ ^[0-9]+$ ]]; then
    die "Número de linhas inválido: $LINES"
fi

header "LOGS — $MODE"

case "$MODE" in
    container)
        _logs_journalctl -u "$WAYDROID_CONTAINER" --no-pager -n "$LINES"
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
        _logs_journalctl -u "$WAYDROID_CONTAINER" --no-pager -n "$LINES"
        echo ""
        section "wdroid (últimas $LINES linhas)"
        [ -f "$_LOG_FILE" ] && tail -n "$LINES" "$_LOG_FILE" || notice "Sem logs."
        ;;
    follow|-f)
        log "Seguindo logs do container (Ctrl+C para sair)..."
        _logs_journalctl -u "$WAYDROID_CONTAINER" -f
        ;;
    help|--help|-h)
        _logs_usage
        ;;
    *)
        _logs_usage
        return 1
        ;;
esac
