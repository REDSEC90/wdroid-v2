#!/bin/bash
# DESCRIPTION: Plugin para automações específicas do WhatsApp via ADB

_load_modules app session

plugin_main() {
    local action="${1:-help}"
    shift || true

    case "$action" in
        open)
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
            require_state SESSION_RUNNING
            capture_screen
            ;;
        adb)
            adb_connect
            ;;
        help|*)
            echo ""
            echo "  Plugin WhatsApp — ações disponíveis:"
            echo "    open          Abre o WhatsApp"
            echo "    send <texto>  Envia texto via ADB (app deve estar aberto)"
            echo "    screenshot    Captura a tela atual"
            echo "    adb           Conecta ADB ao Waydroid"
            echo ""
            ;;
    esac
}
