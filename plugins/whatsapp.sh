#!/bin/bash
# DESCRIPTION: Plugin para automações específicas do WhatsApp via ADB

_load_modules app session

_whatsapp_usage() {
    echo ""
    echo "  Plugin WhatsApp — ações disponíveis:"
    echo "    open          Abre o WhatsApp"
    echo "    send <texto>  Envia texto via ADB (app deve estar aberto)"
    echo "    screenshot    Captura a tela atual"
    echo "    adb           Conecta ADB ao Waydroid"
    echo ""
}

_whatsapp_no_extra_args() {
    local usage="$1"
    shift || true
    [ "$#" -eq 0 ] || die "Uso: $usage"
}

plugin_main() {
    local action="${1:-help}"
    shift || true

    case "$action" in
        open)
            _whatsapp_no_extra_args "wdroid plugin run whatsapp open" "$@"
            require_state SESSION_RUNNING
            launch_app "com.whatsapp"
            ;;
        send)
            # Envio básico de texto via ADB (requer app aberto)
            local text="$*"
            [ -z "$text" ] && die "Informe o texto: wdroid plugin run whatsapp send <mensagem>"
            require_state SESSION_RUNNING
            send_text "$text"
            ;;
        screenshot)
            [ "$#" -le 1 ] || die "Uso: wdroid plugin run whatsapp screenshot [arquivo.png]"
            require_state SESSION_RUNNING
            capture_screen "${1:-}"
            ;;
        adb)
            _whatsapp_no_extra_args "wdroid plugin run whatsapp adb" "$@"
            adb_connect
            ;;
        help|--help|-h)
            _whatsapp_no_extra_args "wdroid plugin run whatsapp help" "$@"
            _whatsapp_usage
            ;;
        *)
            _whatsapp_usage
            return 1
            ;;
    esac
}
