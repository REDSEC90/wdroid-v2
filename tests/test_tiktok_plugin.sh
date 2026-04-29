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

# open requer sessão ativa — falha quando STOPPED
_run_tiktok \
    'systemctl() { return 1; }; export -f systemctl' \
    'open' &>/dev/null
assert_eq "open falha sem sessão ativa" "1" "$?"

# send sem argumento falha
_run_tiktok \
    'systemctl() { return 0; }; export -f systemctl
     waydroid() { echo "Session: RUNNING"; }; export -f waydroid' \
    'send' &>/dev/null
assert_eq "send sem texto falha" "1" "$?"

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

# WDROID_TIKTOK_APK sobrescreve caminho padrão
_out=$(bash -c "
    export HOME=/tmp
    export WDROID_TIKTOK_APK='/custom/path/tiktok.apk'
    source '$BASE_DIR/plugins/tiktok.sh' 2>/dev/null
    echo \"\$TIKTOK_APK\"
" 2>/dev/null || true)
assert_contains "WDROID_TIKTOK_APK sobrescreve padrão" "/custom/path/tiktok.apk" "$_out"

rm -f "$_TMP_APK" 2>/dev/null || true
rm -rf /tmp/wdroid-test-logs-* /tmp/wdroid-test-state-* 2>/dev/null || true
