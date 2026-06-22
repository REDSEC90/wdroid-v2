#!/bin/bash
# =============================================================================
# commands/launch.sh — Abertura de apps Android
# =============================================================================

_launch_usage() {
    echo "Uso: wdroid launch [pacote|whatsapp|tiktok-lite]"
}

case "${1:-}" in
    help|--help|-h)
        _launch_usage
        return 0
        ;;
esac

[ "$#" -le 1 ] || {
    _launch_usage
    return 1
}

_load_modules app

case "${1:-}" in
    tiktok-lite|tiktok)
        source "$BASE_DIR/core/plugin.sh"
        plugin_cmd run tiktok open
        ;;
    whatsapp)
        source "$BASE_DIR/core/plugin.sh"
        plugin_cmd run whatsapp open
        ;;
    *)
        launch_app "${1:-$APP_PACKAGE}"
        ;;
esac
