#!/bin/bash
# tests/test_tiktok_plugin.sh — Verifica plugin TikTok Lite

suite "Plugin TikTok (plugins/tiktok.sh)"

_run_tiktok() {
    bash -c "
        export HOME=/tmp
        WDROID_LOG_DIR=/tmp/wdroid-test-logs-$$
        STATE_FILE=/tmp/wdroid-test-state-$$
        BASE_DIR='$BASE_DIR'
        source '$BASE_DIR/core/config.sh'
        source '$BASE_DIR/core/logger.sh'
        _init_logger
        source '$BASE_DIR/core/utils.sh'
        _load_modules() {
            for m in \"\$@\"; do source \"\$BASE_DIR/modules/\$m.sh\" 2>/dev/null || true; done
        }
        # Mocks
        $1
        source '$BASE_DIR/core/state.sh'
        source '$BASE_DIR/plugins/tiktok.sh'
        plugin_main $2
    "
}

# Variável TIKTOK_PACKAGE está definida
_out=$(bash -c "source '$BASE_DIR/plugins/tiktok.sh' 2>/dev/null; echo \"\$TIKTOK_PACKAGE\"" 2>/dev/null || true)
# Verifica diretamente no arquivo
assert_contains "TIKTOK_PACKAGE definido no plugin" \
    "com.zhiliaoapp.musically.go" \
    "$(grep TIKTOK_PACKAGE "$BASE_DIR/plugins/tiktok.sh")"

# Caminho padrão usa APK_DIR
_out=$(bash -c "
    export HOME=/tmp
    BASE_DIR='$BASE_DIR'
    source '$BASE_DIR/core/config.sh'
    _load_modules() { true; }
    source '$BASE_DIR/plugins/tiktok.sh'
    echo \"\$TIKTOK_APK\"
" 2>/dev/null || true)
assert_contains "TIKTOK_APK padrão usa APK_DIR" "/.wdroid/apks/tiktok-lite.apk" "$_out"

# help não lança erro
_run_tiktok '' 'help' &>/dev/null
assert_eq "plugin_main help não lança erro" "0" "$?"

# help mostra ações disponíveis
_out=$(_run_tiktok '' 'help')
assert_contains "help mostra 'setup'"      "setup"      "$_out"
assert_contains "help mostra 'download'"   "download"   "$_out"
assert_contains "help mostra 'install'"    "install"    "$_out"
assert_contains "help mostra 'open'"       "open"       "$_out"
assert_contains "help mostra 'screenshot'" "screenshot" "$_out"
assert_contains "help mostra 'adb'"        "adb"        "$_out"

_run_tiktok '' 'help extra' &>/dev/null
assert_eq "help rejeita argumento extra" "1" "$?"

_run_tiktok '' 'acao-invalida' &>/dev/null
assert_eq "ação inválida retorna erro" "1" "$?"

# open requer sessão ativa — falha quando STOPPED
_run_tiktok \
    'waydroid() { echo "Container: STOPPED"; echo "Session: STOPPED"; }; export -f waydroid' \
    'open' &>/dev/null
assert_eq "open falha sem sessão ativa" "1" "$?"

# send sem argumento falha
_run_tiktok \
    'waydroid() { echo "Container: RUNNING"; echo "Session: RUNNING"; }; export -f waydroid' \
    'send' &>/dev/null
assert_eq "send sem texto falha" "1" "$?"

_run_tiktok '' 'screenshot a.png b.png' &>/dev/null
assert_eq "screenshot rejeita argumento extra" "1" "$?"

_run_tiktok 'find() { return 0; }; export -f find' 'download' &>/dev/null
assert_eq "download sem APK local ou URL falha" "1" "$?"

_run_tiktok 'find() { return 0; }; export -f find' 'download ftp://invalido/app.apk' &>/dev/null
assert_eq "download rejeita URL não HTTP" "1" "$?"

if grep -Eqi 'apkpure|d\.apkpure|versionCode=latest|wget' "$BASE_DIR/plugins/tiktok.sh"; then
    fail "plugin TikTok não usa fonte fixa de APK de terceiro"
else
    pass "plugin TikTok não usa fonte fixa de APK de terceiro"
fi

# download encontra APK existente em $HOME
_TMP_APK="/tmp/tiktok-lite-test-$$.apk"
touch "$_TMP_APK"
_out=$(bash -c "
    export HOME=/tmp
    WDROID_LOG_DIR=/tmp/wdroid-test-logs-$$
    BASE_DIR='$BASE_DIR'
    source '$BASE_DIR/core/config.sh'
    source '$BASE_DIR/core/logger.sh'
    _init_logger
    _load_modules() { true; }
    source '$BASE_DIR/plugins/tiktok.sh'
    TIKTOK_APK='$_TMP_APK'
    # Simula find encontrando o APK
    find() { echo '$_TMP_APK'; }; export -f find
    _tiktok_download
" 2>&1)
assert_contains "download detecta APK existente" "Pronto" "$_out"

# download cria diretório do APK quando copia arquivo existente
_SRC_APK="/tmp/tiktok-lite-source-$$.apk"
_TARGET_DIR="/tmp/wdroid-tiktok-target-$$"
_TARGET_APK="$_TARGET_DIR/tiktok-lite.apk"
touch "$_SRC_APK"
_out=$(bash -c "
    export HOME=/tmp
    WDROID_LOG_DIR=/tmp/wdroid-test-logs-$$
    BASE_DIR='$BASE_DIR'
    source '$BASE_DIR/core/config.sh'
    source '$BASE_DIR/core/logger.sh'
    _init_logger
    _load_modules() { true; }
    source '$BASE_DIR/plugins/tiktok.sh'
    TIKTOK_APK='$_TARGET_APK'
    find() { echo '$_SRC_APK'; }; export -f find
    _tiktok_download
    [ -f '$_TARGET_APK' ] && echo copied
" 2>&1)
assert_contains "download cria diretório do APK" "copied" "$_out"

_URL_DIR="/tmp/wdroid-tiktok-url-$$"
_URL_APK="$_URL_DIR/tiktok-lite.apk"
_out=$(bash -c "
    export HOME=/tmp
    WDROID_LOG_DIR=/tmp/wdroid-test-logs-$$
    BASE_DIR='$BASE_DIR'
    source '$BASE_DIR/core/config.sh'
    source '$BASE_DIR/core/logger.sh'
    _init_logger
    source '$BASE_DIR/core/utils.sh'
    _load_modules() { for m in \"\$@\"; do source \"\$BASE_DIR/modules/\$m.sh\" 2>/dev/null || true; done; }
    source '$BASE_DIR/plugins/tiktok.sh'
    TIKTOK_APK='$_URL_APK'
    find() { return 0; }
    curl() {
        local out=''
        while [ \"\$#\" -gt 0 ]; do
            if [ \"\$1\" = '-o' ]; then
                shift
                out=\"\$1\"
            fi
            shift || true
        done
        mkdir -p \"\$(dirname \"\$out\")\"
        printf 'apk' > \"\$out\"
    }
    export -f find curl
    _tiktok_download 'https://example.test/tiktok-lite.apk'
    [ -s '$_URL_APK' ] && echo downloaded
" 2>&1)
assert_contains "download aceita URL explícita" "downloaded" "$_out"

_EXPLICIT_APK="/tmp/tiktok-explicit-$$.APK"
touch "$_EXPLICIT_APK"
_out=$(bash -c "
    export HOME=/tmp
    WDROID_LOG_DIR=/tmp/wdroid-test-logs-$$
    BASE_DIR='$BASE_DIR'
    source '$BASE_DIR/core/config.sh'
    source '$BASE_DIR/core/logger.sh'
    _init_logger
    source '$BASE_DIR/core/utils.sh'
    _load_modules() { for m in \"\$@\"; do source \"\$BASE_DIR/modules/\$m.sh\" 2>/dev/null || true; done; }
    find() { return 0; }
    waydroid() { printf 'waydroid:%s\n' \"\$*\"; }
    export -f find waydroid
    source '$BASE_DIR/plugins/tiktok.sh'
    plugin_main install '$_EXPLICIT_APK'
" 2>&1)
assert_contains "install aceita APK explícito" "waydroid:app install $_EXPLICIT_APK" "$_out"

# WDROID_TIKTOK_APK sobrescreve caminho padrão
_out=$(bash -c "
    export HOME=/tmp
    export WDROID_TIKTOK_APK='/custom/path/tiktok.apk'
    source '$BASE_DIR/plugins/tiktok.sh' 2>/dev/null
    echo \"\$TIKTOK_APK\"
" 2>/dev/null || true)
assert_contains "WDROID_TIKTOK_APK sobrescreve padrão" "/custom/path/tiktok.apk" "$_out"

rm -f "$_TMP_APK" "$_SRC_APK" "$_EXPLICIT_APK" 2>/dev/null || true
rm -rf "$_TARGET_DIR" "$_URL_DIR" 2>/dev/null || true
rm -rf /tmp/wdroid-test-logs-* /tmp/wdroid-test-state-* 2>/dev/null || true
