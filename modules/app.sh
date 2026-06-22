#!/bin/bash
# =============================================================================
# modules/app.sh — Gerenciamento de apps e ADB
# =============================================================================

launch_app() {
    local package="${1:-$APP_PACKAGE}"
    log "Abrindo: $package"
    run waydroid app launch "$package"
}

require_apk_file() {
    local apk="$1"
    local usage="${2:-Informe o APK: wdroid install-apk <arquivo.apk>}"

    [ -n "$apk" ] || die "$usage"
    [ -f "$apk" ] || die "Arquivo não encontrado: $apk"
    case "${apk,,}" in
        *.apk) ;;
        *) die "Arquivo precisa ter extensão .apk: $apk" ;;
    esac
}

install_apk() {
    local apk="$1"
    require_apk_file "$apk" "Informe o APK: wdroid install-apk <arquivo.apk>"
    log "Instalando APK: $apk"
    run waydroid app install "$apk"
}

list_apps() {
    section "Apps instalados"
    waydroid app list
}

remove_app() {
    local package="$1"
    [ -z "$package" ] && die "Informe o pacote: wdroid app-remove <pacote>"
    log "Removendo: $package"
    run waydroid app remove "$package"
}

adb_connect() {
    require_cmd adb
    log "Conectando ADB ao Waydroid..."
    run adb connect localhost:5555
}

adb_shell() {
    require_cmd adb
    adb_connect
    adb -s localhost:5555 shell "$@"
}

_android_input_text_arg() {
    local text="$1"
    printf "%s" "${text// /%s}"
}

send_text() {
    local text="$1" input_arg
    [ -z "$text" ] && die "Informe o texto: wdroid send-text <mensagem>"
    input_arg="$(_android_input_text_arg "$text")"
    log "Enviando texto via Waydroid shell..."
    run waydroid_shell input text "$input_arg"
}

capture_screen() {
    local dest="${1:-$HOME/wdroid-screenshot-$(date +%s).png}"
    local dest_dir
    require_cmd adb
    dest_dir="$(dirname "$dest")"
    run mkdir -p "$dest_dir"
    log "Capturando tela..."
    run waydroid_shell screencap -p /sdcard/ss.png
    adb_connect
    run_silent adb -s localhost:5555 pull /sdcard/ss.png "$dest"
    log "Screenshot salva em: $dest"
}
