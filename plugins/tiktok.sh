#!/bin/bash
# DESCRIPTION: Plugin para gerenciamento e automações do TikTok Lite via Waydroid

_load_modules app session

# Pacote do TikTok Lite
TIKTOK_PACKAGE="com.zhiliaoapp.musically.go"

# Caminho padrão do APK (pode ser sobrescrito por variável de ambiente)
TIKTOK_APK="${WDROID_TIKTOK_APK:-$HOME/tiktok-lite.apk}"

# ── Download do APK ───────────────────────────────────────────────────────────
_tiktok_download() {
    # Procura APK já existente em locais comuns
    local found
    found=$(find "$HOME" "$HOME/Downloads" /tmp -maxdepth 2 \
            \( -name "*tiktok*lite*.apk" -o -name "*musically.go*.apk" \) \
            2>/dev/null | head -1)

    if [ -n "$found" ]; then
        log "APK encontrado em: $found"
        [ "$found" != "$TIKTOK_APK" ] && cp "$found" "$TIKTOK_APK"
        log "Pronto: $TIKTOK_APK"
        return 0
    fi

    log "Baixando TikTok Lite..."
    wget -q --show-progress \
         --user-agent="Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36" \
         -O "$TIKTOK_APK" \
         "https://d.apkpure.net/b/APK/com.zhiliaoapp.musically.go?versionCode=latest" \
    && {
        log "Download concluído: $TIKTOK_APK ($(du -sh "$TIKTOK_APK" | cut -f1))"
        return 0
    }

    # Fallback: instrução manual
    rm -f "$TIKTOK_APK"
    echo ""
    echo "  Download automático indisponível."
    echo "  Baixe manualmente em:"
    echo "    https://apkpure.com/tiktok-lite/com.zhiliaoapp.musically.go"
    echo ""
    echo "  Depois salve em: $TIKTOK_APK"
    echo "  E rode: wdroid plugin run tiktok install"
    echo ""
    return 1
}

# ─── Entrypoint ───────────────────────────────────────────────────────────────
plugin_main() {
    local action="${1:-help}"
    shift || true

    case "$action" in
        download)
            _tiktok_download
            ;;

install)
            [ -f "$TIKTOK_APK" ] || _tiktok_download || return 1
            # Copia para o sdcard do Waydroid e instala via pm (contorna bug do waydroid app install)
            local _sdcard
            _sdcard=$(find "$HOME/.local/share/waydroid" -path "*/media/0/Download" -type d 2>/dev/null | head -1)
            if [ -n "$_sdcard" ]; then
                sudo cp "$TIKTOK_APK" "$_sdcard/tiktok.apk"
                sudo waydroid shell pm install /sdcard/Download/tiktok.apk
            else
                install_apk "$TIKTOK_APK"
            fi
            ;;

        open)
            require_state SESSION_RUNNING
            local url="${1:-}"
            if [ -n "$url" ]; then
                sudo waydroid shell "am start -a android.intent.action.VIEW -d '$url'"
            else
                launch_app "$TIKTOK_PACKAGE"
            fi
            ;;

        send)
            local text="$*"
            [ -z "$text" ] && die "Informe o texto: wdroid plugin run tiktok send <mensagem>"
            require_state SESSION_RUNNING
            send_text "$text"
            ;;

        screenshot)
            require_state SESSION_RUNNING
            capture_screen "${1:-}"
            ;;

        adb)
            adb_connect
            ;;

        setup)
            # Fluxo completo: download → instala → abre
            _tiktok_download || return 1
            plugin_main install
            require_state SESSION_RUNNING
            launch_app "$TIKTOK_PACKAGE"
            ;;

        help|*)
            echo ""
            echo "  Plugin TikTok Lite — ações disponíveis:"
            echo "    setup              Download + instala + abre (início rápido)"
            echo "    download           Baixa o APK do TikTok Lite"
            echo "    install            Instala o APK no Waydroid"
            echo "    open [url]         Abre o TikTok Lite (ou abre uma URL diretamente)"
            echo "    send <texto>       Envia texto via ADB (app deve estar aberto)"
            echo "    screenshot [f]     Captura a tela atual"
            echo "    adb                Conecta ADB ao Waydroid"
            echo ""
            echo "  Variáveis de ambiente:"
            echo "    WDROID_TIKTOK_APK  Caminho do APK (padrão: ~/tiktok-lite.apk)"
            echo ""
            echo "  Exemplos:"
            echo "    wdroid plugin run tiktok open"
            echo "    wdroid plugin run tiktok open 'https://vm.tiktok.com/XXXXXXX/'"
            echo "    wdroid plugin run tiktok open 'https://www.tiktok.com/@usuario'"
            echo "    wdroid plugin run tiktok screenshot ~/tela.png"
            echo ""
            ;;
    esac
}
