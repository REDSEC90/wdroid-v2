#!/bin/bash
# =============================================================================
# modules/services.sh — Google Play Store e Xiaomi Cloud
# =============================================================================

GOOGLE_PLAY_PACKAGE="com.android.vending"
GOOGLE_PLAY_SERVICES_PACKAGE="com.google.android.gms"
GOOGLE_CERT_URL="https://www.google.com/android/uncertified"

XIAOMI_ACCOUNT_PACKAGE="com.xiaomi.account"
XIAOMI_CLOUD_PACKAGE="com.miui.cloudservice"
XIAOMI_CLOUD_BACKUP_PACKAGE="com.miui.cloudbackup"
XIAOMI_CLOUD_URL="https://i.mi.com/"
WAYDROID_PRIV_APP_OVERLAY="$WAYDROID_DATA_DIR/overlay/system/priv-app"

_service_no_extra_args() {
    local usage="$1"
    shift || true
    [ "$#" -eq 0 ] || die "Uso: $usage"
}

android_package_installed() {
    local package="${1:-}"
    local output
    [ -n "$package" ] || return 1

    output="$(waydroid_shell -- pm path "$package" 2>&1)" && {
        echo "$output" | grep -q "^package:" && return 0
    }

    echo "$output" | grep -Eqi "needs root access|password|senha|terminal is required" && return 2

    return 1
}

_package_status() {
    local label="$1"
    local package="$2"
    local status=0

    android_package_installed "$package" || status=$?
    case "$status" in
        0) ok "$label ($package)" ;;
        2) notice "$label não verificado: Waydroid shell exige sudo interativo ($package)" ;;
        *) fail "$label ausente ($package)" ;;
    esac
}

_open_android_url() {
    local url="$1"
    require_state SESSION_RUNNING
    if waydroid_shell -- am start -a android.intent.action.VIEW -d "$url"; then
        return 0
    fi

    if command -v xdg-open &>/dev/null; then
        warn "Não foi possível abrir a URL dentro do Android; abrindo no navegador do host."
        xdg-open "$url" &>/dev/null &
        return 0
    fi

    die "Não foi possível abrir URL no Android. Acesse manualmente: $url"
}

_launch_android_package() {
    local package="$1"
    require_state SESSION_RUNNING

    if waydroid app launch "$package" &>/dev/null; then
        log "App aberto: $package"
        return 0
    fi

    if waydroid_shell -- monkey -p "$package" -c android.intent.category.LAUNCHER 1 &>/dev/null; then
        log "App aberto via launcher: $package"
        return 0
    fi

    return 1
}

_google_android_id_from_content() {
    waydroid_shell -- content query \
        --uri content://com.google.android.gsf.gservices \
        --projection value \
        --where "name='android_id'" 2>/dev/null \
        | tr -d '\r' \
        | sed -n 's/.*value=\([0-9][0-9]*\).*/\1/p' \
        | tail -1
}

_google_android_id_from_sqlite() {
    waydroid_shell -- sh -c \
        "sqlite3 /data/data/*/*/gservices.db 'select value from main where name = \"android_id\";' 2>/dev/null" \
        | tr -d '\r' \
        | grep -E '^[0-9]+$' \
        | tail -1
}

google_android_id() {
    local android_id

    android_id="$(_google_android_id_from_content || true)"
    if [ -n "$android_id" ]; then
        printf "%s\n" "$android_id"
        return 0
    fi

    android_id="$(_google_android_id_from_sqlite || true)"
    if [ -n "$android_id" ]; then
        printf "%s\n" "$android_id"
        return 0
    fi

    return 1
}

playstore_status() {
    header "PLAY STORE"

    if ! is_session_running; then
        notice "Sessão Android parada. Execute: wdroid start"
        return 0
    fi

    section "Pacotes"
    _package_status "Google Play Store" "$GOOGLE_PLAY_PACKAGE"
    _package_status "Google Play Services" "$GOOGLE_PLAY_SERVICES_PACKAGE"

    section "Certificação"
    local android_id
    android_id="$(google_android_id || true)"
    if [ -n "$android_id" ]; then
        ok "Android ID: $android_id"
        printf "  Registre em: %s\n" "$GOOGLE_CERT_URL"
    else
        notice "Android ID não disponível. Abra a Play Store uma vez e tente novamente."
    fi
}

playstore_init() {
    local force=false
    case "$#" in
        0) ;;
        1)
            case "${1:-}" in
                --force|-f) force=true ;;
                *) die "Uso: wdroid playstore init [--force]" ;;
            esac
            ;;
        *) die "Uso: wdroid playstore init [--force]" ;;
    esac

    require_cmd waydroid

    if [ -d "$WAYDROID_DATA_DIR" ] && ! $force; then
        die "Waydroid já inicializado. Use: wdroid playstore init --force (faça backup antes)."
    fi

    if $force; then
        warn "Isso reinicializa as imagens do Waydroid com GAPPS."
        confirm "Continuar? Digite exatamente" "yes" || {
            log "Operação cancelada."
            return 0
        }
        run sudo waydroid init -f -s GAPPS
    else
        run sudo waydroid init -s GAPPS
    fi

    log "Imagem GAPPS pronta. Execute: wdroid start"
}

playstore_certify() {
    case "$#" in
        0) ;;
        1) [ "${1:-}" = "--open" ] || die "Uso: wdroid playstore certify [--open]" ;;
        *) die "Uso: wdroid playstore certify [--open]" ;;
    esac

    require_state SESSION_RUNNING

    local android_id
    android_id="$(google_android_id || true)"
    [ -n "$android_id" ] || die "Android ID não encontrado. Abra a Play Store uma vez e tente novamente."

    section "Certificação Google Play"
    printf "  Android ID: %s\n" "$android_id"
    printf "  Registre em: %s\n" "$GOOGLE_CERT_URL"
    printf "  Depois aguarde alguns minutos e reinicie a sessão: wdroid restart\n"

    if [ "${1:-}" = "--open" ] && command -v xdg-open &>/dev/null; then
        xdg-open "$GOOGLE_CERT_URL" &>/dev/null &
    fi
}

playstore_cmd() {
    local action="${1:-status}"
    shift || true

    case "$action" in
        init)
            playstore_init "$@"
            ;;
        status)
            _service_no_extra_args "wdroid playstore status" "$@"
            playstore_status
            ;;
        certify)
            playstore_certify "$@"
            ;;
        open)
            _service_no_extra_args "wdroid playstore open" "$@"
            _launch_android_package "$GOOGLE_PLAY_PACKAGE" || die "Não foi possível abrir a Play Store."
            ;;
        help|--help|-h)
            _service_no_extra_args "wdroid playstore help" "$@"
            echo ""
            echo "  Play Store — ações disponíveis:"
            echo "    init [--force]      Inicializa/reinicializa Waydroid com imagem GAPPS"
            echo "    status              Verifica Play Store, Play Services e Android ID"
            echo "    certify [--open]    Mostra Android ID e link oficial de certificação"
            echo "    open                Abre a Play Store"
            echo ""
            ;;
        *)
            die "Uso: wdroid playstore {init|status|certify|open|help}"
            ;;
    esac
}

micloud_status() {
    header "XIAOMI CLOUD"

    if ! is_session_running; then
        notice "Sessão Android parada. Execute: wdroid start"
        return 0
    fi

    section "Pacotes"
    _package_status "Xiaomi Account" "$XIAOMI_ACCOUNT_PACKAGE"
    _package_status "Xiaomi Cloud" "$XIAOMI_CLOUD_PACKAGE"
    _package_status "Mi Cloud Backup" "$XIAOMI_CLOUD_BACKUP_PACKAGE"

    section "Acesso web"
    printf "  %s\n" "$XIAOMI_CLOUD_URL"
}

micloud_install() {
    require_state SESSION_RUNNING
    [ "$#" -gt 0 ] || die "Informe APK(s): wdroid micloud install <arquivo.apk> [outro.apk]"

    local apk
    for apk in "$@"; do
        install_apk "$apk"
    done
}

micloud_install_system() {
    [ "$#" -gt 0 ] || die "Informe APK(s): wdroid micloud install-system <arquivo.apk> [outro.apk]"

    warn "Instalação como system-app usa overlayfs do Waydroid e APKs fornecidos por você."
    local apk base_name app_name
    for apk in "$@"; do
        require_apk_file "$apk" "Informe APK(s): wdroid micloud install-system <arquivo.apk> [outro.apk]"
        base_name="$(basename "$apk")"
        base_name="${base_name%.[aA][pP][kK]}"
        app_name="$(printf "%s" "$base_name" | tr -cd '[:alnum:]_.-')"
        [ -n "$app_name" ] || app_name="MiCloud"
        run sudo install -vpD "$apk" "$WAYDROID_PRIV_APP_OVERLAY/$app_name/$app_name.apk"
    done

    run sudo systemctl restart "$WAYDROID_CONTAINER"
    log "System-app instalado. Execute: wdroid start"
}

micloud_open() {
    if android_package_installed "$XIAOMI_CLOUD_PACKAGE" && _launch_android_package "$XIAOMI_CLOUD_PACKAGE"; then
        return 0
    fi

    if android_package_installed "$XIAOMI_CLOUD_BACKUP_PACKAGE" && _launch_android_package "$XIAOMI_CLOUD_BACKUP_PACKAGE"; then
        return 0
    fi

    warn "App Xiaomi Cloud não encontrado; abrindo versão web."
    _open_android_url "$XIAOMI_CLOUD_URL"
}

micloud_cmd() {
    local action="${1:-status}"
    shift || true

    case "$action" in
        status)
            _service_no_extra_args "wdroid micloud status" "$@"
            micloud_status
            ;;
        install)
            micloud_install "$@"
            ;;
        install-system)
            micloud_install_system "$@"
            ;;
        open)
            _service_no_extra_args "wdroid micloud open" "$@"
            micloud_open
            ;;
        web)
            _service_no_extra_args "wdroid micloud web" "$@"
            _open_android_url "$XIAOMI_CLOUD_URL"
            ;;
        help|--help|-h)
            _service_no_extra_args "wdroid micloud help" "$@"
            echo ""
            echo "  Xiaomi Cloud — ações disponíveis:"
            echo "    status                    Verifica Xiaomi Account/Cloud instalados"
            echo "    install <apk...>          Instala APKs locais como apps comuns"
            echo "    install-system <apk...>   Instala APKs locais como system-app via overlayfs"
            echo "    open                      Abre Xiaomi Cloud app ou web"
            echo "    web                       Abre https://i.mi.com/ no Android"
            echo ""
            ;;
        *)
            die "Uso: wdroid micloud {status|install|install-system|open|web|help}"
            ;;
    esac
}
