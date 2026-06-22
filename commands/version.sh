#!/bin/bash
# =============================================================================
# commands/version.sh — Versao da CLI
# =============================================================================

case "${1:-}" in
    "")
        ;;
    help|--help|-h)
        echo "Uso: wdroid version"
        return 0
        ;;
    *)
        echo "Uso: wdroid version"
        return 1
        ;;
esac

echo "wdroid v${WDROID_VERSION}"
