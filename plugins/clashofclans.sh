#!/bin/bash
# DESCRIPTION: Plugin para instalação e automação do Clash of Clans via Waydroid

_load_modules app session

COC_PACKAGE="com.supercell.clashofclans"
COC_APK="${WDROID_COC_APK:-${APK_DIR:-$HOME/.wdroid/apks}/clashofclans.apk}"

_coc_usage() {
    echo ""
    echo "  Plugin Clash of Clans — ações disponíveis:"
    echo "    install [apk]    Instala APK local no Waydroid"
    echo "    open             Abre o Clash of Clans"
    echo "    screenshot [f]   Captura a tela atual"
    echo "    adb              Conecta ADB ao Waydroid"
    echo ""
    echo "  Variáveis de ambiente:"
    echo "    WDROID_COC_APK   Caminho do APK (padrão: ${APK_DIR:-$HOME/.wdroid/apks}/clashofclans.apk)"
    echo ""
    echo "  Exemplos:"
    echo "    wdroid plugin run clashofclans install ~/Downloads/clashofclans.apk"
    echo "    wdroid plugin run clashofclans open"
    echo ""
}

_coc_install_splits() {
    local dir="$1"
    local tmp_dir="/data/local/tmp/coc-install"

    # Copia splits para /data/local/tmp do Android
    sudo mkdir -p "$HOME/.local/share/waydroid/data/local/tmp/coc-install" 2>/dev/null || true
    local apk_list=()
    for apk in "$dir"/*.apk; do
        [ -f "$apk" ] || continue
        local name; name=$(basename "$apk")
        sudo cp "$apk" "$HOME/.local/share/waydroid/data/local/tmp/$name"
        apk_list+=("$name")
    done

    [ ${#apk_list[@]} -eq 0 ] && die "Nenhum APK encontrado em: $dir"

    log "Criando sessão de instalação (split APK)..."
    local session
    session=$(waydroid_shell -- pm install-create -r 2>&1 | grep -oP '\[\K[0-9]+')
    [ -z "$session" ] && die "Falha ao criar sessão pm install-create"

    for name in "${apk_list[@]}"; do
        log "  Escrevendo split: $name"
        waydroid_shell -- pm install-write "$session" "${name%.apk}" "/data/local/tmp/$name" 2>&1 || \
            { waydroid_shell -- pm install-abandon "$session" 2>/dev/null; die "Falha ao escrever split: $name"; }
    done

    log "Commitando instalação..."
    waydroid_shell -- pm install-commit "$session" 2>&1 | grep -qi "success" || \
        die "pm install-commit falhou"
    log "Clash of Clans instalado com sucesso."
}

_coc_install() {
    local input="${1:-}"

    # Se for um diretório de splits extraídos
    if [ -d "$input" ]; then
        _coc_install_splits "$input"
        return
    fi

    # APK único ou XAPK
    local apk="${input:-$COC_APK}"
    require_apk_file "$apk" "Informe o APK/XAPK: wdroid plugin run clashofclans install <arquivo>"

    case "${apk,,}" in
        *.xapk)
            log "Detectado XAPK — extraindo splits..."
            local tmpdir; tmpdir=$(mktemp -d)
            unzip -o "$apk" '*.apk' -d "$tmpdir" >/dev/null 2>&1 || die "Falha ao extrair XAPK"
            _coc_install_splits "$tmpdir"
            rm -rf "$tmpdir"
            ;;
        *.apk)
            # APK simples — tenta direto
            local name; name=$(basename "$apk")
            sudo cp "$apk" "$HOME/.local/share/waydroid/data/local/tmp/$name"
            waydroid_shell -- pm install -r "/data/local/tmp/$name" 2>&1 | grep -qi "success" || \
                die "Falha ao instalar APK"
            log "Clash of Clans instalado."
            ;;
    esac
}

plugin_main() {
    local action="${1:-help}"
    shift || true

    case "$action" in
        install)
            case "$#" in
                0|1) _coc_install "${1:-}" ;;
                *) die "Uso: wdroid plugin run clashofclans install [arquivo.apk|arquivo.xapk|dir-splits]" ;;
            esac
            ;;

        open)
            [ "$#" -eq 0 ] || die "Uso: wdroid plugin run clashofclans open"
            require_state SESSION_RUNNING
            launch_app "$COC_PACKAGE"
            ;;

        screenshot)
            [ "$#" -le 1 ] || die "Uso: wdroid plugin run clashofclans screenshot [arquivo.png]"
            require_state SESSION_RUNNING
            capture_screen "${1:-}"
            ;;

        adb)
            [ "$#" -eq 0 ] || die "Uso: wdroid plugin run clashofclans adb"
            adb_connect
            ;;

        help|--help|-h)
            _coc_usage
            ;;

        *)
            _coc_usage
            return 1
            ;;
    esac
}
