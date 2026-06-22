#!/bin/bash
# =============================================================================
# commands/app.sh — Comandos de apps, ADB e sessão gráfica
# =============================================================================

APP_COMMAND="${1:-}"
shift || true

_app_usage() {
    echo "Uso: wdroid {install-apk <arquivo.apk>|apps|adb|screenshot [arquivo.png]|send-text <mensagem>|multi-window}"
}

_app_help_arg() {
    case "${1:-}" in
        help|--help|-h) return 0 ;;
        *) return 1 ;;
    esac
}

case "$APP_COMMAND" in
    install-apk)
        if [ "$#" -eq 1 ] && _app_help_arg "${1:-}"; then
            _app_usage
            return 0
        fi
        [ "$#" -eq 1 ] || {
            _app_usage
            return 1
        }
        _load_modules app
        install_apk "$1"
        ;;
    apps)
        if [ "$#" -eq 1 ] && _app_help_arg "${1:-}"; then
            _app_usage
            return 0
        fi
        [ "$#" -eq 0 ] || {
            _app_usage
            return 1
        }
        _load_modules app
        list_apps
        ;;
    adb)
        if [ "$#" -eq 1 ] && _app_help_arg "${1:-}"; then
            _app_usage
            return 0
        fi
        [ "$#" -eq 0 ] || {
            _app_usage
            return 1
        }
        _load_modules app
        adb_connect
        ;;
    screenshot)
        if [ "$#" -eq 1 ] && _app_help_arg "${1:-}"; then
            _app_usage
            return 0
        fi
        [ "$#" -le 1 ] || {
            _app_usage
            return 1
        }
        _load_modules app
        capture_screen "${1:-}"
        ;;
    send-text)
        if [ "$#" -eq 1 ] && _app_help_arg "${1:-}"; then
            _app_usage
            return 0
        fi
        [ "$#" -gt 0 ] || {
            _app_usage
            return 1
        }
        _load_modules app
        send_text "$*"
        ;;
    multi-window)
        if [ "$#" -eq 1 ] && _app_help_arg "${1:-}"; then
            _app_usage
            return 0
        fi
        [ "$#" -eq 0 ] || {
            _app_usage
            return 1
        }
        _load_modules session
        enable_multi_window
        ;;
    help|--help|-h)
        _app_usage
        ;;
    *)
        _app_usage
        return 1
        ;;
esac
