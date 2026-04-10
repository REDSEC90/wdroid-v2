#!/bin/bash
# =============================================================================
# modules/app.sh — Gerenciamento de apps e ADB
# =============================================================================

launch_app() {
    local package="${1:-$APP_PACKAGE}"
    log "Abrindo: $package"
    run waydroid app launch "$package"
}

install_apk() {
    local apk="$1"
    [ -z "$apk" ]    && die "Informe o APK: wdroid install-apk <arquivo.apk>"
    [ -f "$apk" ]    || die "Arquivo não encontrado: $apk"
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

send_text() {
    local text="$1"
    [ -z "$text" ] && die "Informe o texto: wdroid send-text <mensagem>"
    log "Enviando texto via ADB..."
    run waydroid shell input text "$text"
}

capture_screen() {
    local dest="${1:-$HOME/wdroid-screenshot-$(date +%s).png}"
    log "Capturando tela..."
    waydroid shell screencap -p /sdcard/ss.png
    adb pull /sdcard/ss.png "$dest" &>/dev/null
    log "Screenshot salva em: $dest"
}
