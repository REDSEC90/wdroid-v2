#!/bin/bash
# DESCRIPTION: Plugin para gerenciamento e automações do TikTok Lite via Waydroid

_load_modules app session

# Pacote do TikTok Lite
TIKTOK_PACKAGE="com.zhiliaoapp.musically.go"

# Caminho padrão do APK (pode ser sobrescrito por variável de ambiente)
TIKTOK_APK="${WDROID_TIKTOK_APK:-${APK_DIR:-$HOME/.wdroid/apks}/tiktok-lite.apk}"

_tiktok_usage() {
    echo ""
    echo "  Plugin TikTok Lite — ações disponíveis:"
    echo "    setup [url]        Prepara APK + instala + abre"
    echo "    download [url]     Usa APK local ou baixa da URL informada"
    echo "    install [apk]      Instala APK no Waydroid"
    echo "    open [url]         Abre o TikTok Lite (ou abre uma URL diretamente)"
    echo "    clear-cache        Limpa cache e dados temporários (mantém o app)"
    echo "    send <texto>       Envia texto via ADB (app deve estar aberto)"
    echo "    screenshot [f]     Captura a tela atual"
    echo "    adb                Conecta ADB ao Waydroid"
    echo ""
    echo "  Variáveis de ambiente:"
    echo "    WDROID_TIKTOK_APK  Caminho do APK (padrão: ${APK_DIR:-$HOME/.wdroid/apks}/tiktok-lite.apk)"
    echo ""
    echo "  Exemplos:"
    echo "    wdroid plugin run tiktok download 'https://exemplo.local/tiktok-lite.apk'"
    echo "    wdroid plugin run tiktok install ~/Downloads/tiktok-lite.apk"
    echo "    wdroid plugin run tiktok open"
    echo "    wdroid plugin run tiktok open 'https://vm.tiktok.com/XXXXXXX/'"
    echo "    wdroid plugin run tiktok open 'https://www.tiktok.com/@usuario'"
    echo "    wdroid plugin run tiktok screenshot ~/tela.png"
    echo ""
}

_tiktok_no_extra_args() {
    local usage="$1"
    shift || true
    [ "$#" -eq 0 ] || die "Uso: $usage"
}

_tiktok_find_local_apk() {
    find "$HOME" "$HOME/Downloads" /tmp -maxdepth 2 \
        \( -iname "*tiktok*lite*.apk" -o -iname "*musically.go*.apk" \) \
        2>/dev/null | head -1
}

_tiktok_download_from_url() {
    local url="$1"

    case "$url" in
        http://*|https://*) ;;
        *) die "URL inválida para download: $url" ;;
    esac

    require_cmd curl
    log "Baixando TikTok Lite da URL informada..."
    if curl -fL --retry 2 --connect-timeout 20 \
        --user-agent "Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36" \
        -o "$TIKTOK_APK" "$url"; then
        [ -s "$TIKTOK_APK" ] || {
            rm -f "$TIKTOK_APK"
            die "Download vazio: $url"
        }
        log "Download concluído: $TIKTOK_APK ($(du -sh "$TIKTOK_APK" | cut -f1))"
        return 0
    fi

    rm -f "$TIKTOK_APK"
    return 1
}

_tiktok_manual_download_message() {
    echo ""
    echo "  APK do TikTok Lite não encontrado localmente."
    echo "  Baixe o APK por uma fonte que você confia e execute:"
    echo "    wdroid plugin run tiktok install /caminho/tiktok-lite.apk"
    echo ""
    echo "  Ou informe uma URL explicitamente:"
    echo "    wdroid plugin run tiktok download 'https://exemplo.local/tiktok-lite.apk'"
    echo ""
}

# ── Download do APK ───────────────────────────────────────────────────────────
_tiktok_download() {
    local url="${1:-}"
    # Procura APK já existente em locais comuns
    local found
    mkdir -p "$(dirname "$TIKTOK_APK")"

    found="$(_tiktok_find_local_apk)"
    if [ -n "$found" ]; then
        log "APK encontrado em: $found"
        [ "$found" != "$TIKTOK_APK" ] && cp "$found" "$TIKTOK_APK"
        log "Pronto: $TIKTOK_APK"
        return 0
    fi

    if [ -n "$url" ]; then
        _tiktok_download_from_url "$url"
        return $?
    fi

    _tiktok_manual_download_message
    return 1
}

_tiktok_install() {
    local apk="${1:-$TIKTOK_APK}"

    if [ -n "${1:-}" ]; then
        require_apk_file "$apk" "Informe o APK: wdroid plugin run tiktok install <arquivo.apk>"
    else
        [ -f "$apk" ] || _tiktok_download || return 1
    fi

    # Copia para o sdcard do Waydroid e instala via pm (contorna bug do waydroid app install)
    local _sdcard
    _sdcard=$(find "$HOME/.local/share/waydroid" -path "*/media/0/Download" -type d 2>/dev/null | head -1)
    if [ -n "$_sdcard" ]; then
        sudo cp "$apk" "$_sdcard/tiktok.apk"
        waydroid_shell pm install /sdcard/Download/tiktok.apk
    else
        install_apk "$apk"
    fi
}

# ─── Entrypoint ───────────────────────────────────────────────────────────────
plugin_main() {
    local action="${1:-help}"
    shift || true

    case "$action" in
        download)
            case "$#" in
                0|1) _tiktok_download "${1:-}" ;;
                *) die "Uso: wdroid plugin run tiktok download [url]" ;;
            esac
            ;;

        install)
            case "$#" in
                0|1) _tiktok_install "${1:-}" ;;
                *) die "Uso: wdroid plugin run tiktok install [arquivo.apk]" ;;
            esac
            ;;

        open)
            require_state SESSION_RUNNING
            local url="${1:-}"
            if [ -n "$url" ]; then
                waydroid_shell -- am start -a android.intent.action.VIEW -d "$url"
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
            [ "$#" -le 1 ] || die "Uso: wdroid plugin run tiktok screenshot [arquivo.png]"
            require_state SESSION_RUNNING
            capture_screen "${1:-}"
            ;;

        clear-cache)
            _tiktok_no_extra_args "wdroid plugin run tiktok clear-cache" "$@"
            require_state SESSION_RUNNING
            log "Limpando cache do TikTok Lite..."
            waydroid_shell -- pm clear "$TIKTOK_PACKAGE" --cache-only 2>/dev/null || \
            waydroid_shell -- pm clear "$TIKTOK_PACKAGE"
            log "Cache limpo."
            ;;

        adb)
            _tiktok_no_extra_args "wdroid plugin run tiktok adb" "$@"
            adb_connect
            ;;

        setup)
            case "$#" in
                0|1) ;;
                *) die "Uso: wdroid plugin run tiktok setup [url]" ;;
            esac
            # Fluxo completo: prepara APK, instala e abre
            _tiktok_download "${1:-}" || return 1
            plugin_main install
            require_state SESSION_RUNNING
            launch_app "$TIKTOK_PACKAGE"
            ;;

        help|--help|-h)
            _tiktok_no_extra_args "wdroid plugin run tiktok help" "$@"
            _tiktok_usage
            ;;

        *)
            _tiktok_usage
            return 1
            ;;
    esac
}
