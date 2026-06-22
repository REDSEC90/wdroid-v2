#!/bin/bash
# tests/test_app.sh - Verifica helpers de apps e ADB

suite "Apps (modules/app.sh)"

_run_app() {
    local script="$1"
    bash -c "
        export HOME=/tmp
        WDROID_LOG_DIR=/tmp/wdroid-test-logs-$$
        BASE_DIR='$BASE_DIR'
        source \"\$BASE_DIR/core/config.sh\"
        source \"\$BASE_DIR/core/logger.sh\"
        _init_logger
        source \"\$BASE_DIR/core/utils.sh\"
        source \"\$BASE_DIR/modules/app.sh\"
        $script
    "
}

_out=$(_run_app '_android_input_text_arg "ola mundo"')
assert_eq "send-text escapa espaco para input text" "ola%smundo" "$_out"

_out=$(_run_app '_android_input_text_arg "a  b"')
assert_eq "send-text preserva espacos consecutivos" "a%s%sb" "$_out"

_out=$(_run_app 'waydroid_shell() { printf "%s\n" "$*"; }; send_text "ola mundo"')
assert_contains "send_text usa texto escapado" "input text ola%smundo" "$_out"
assert_contains "send_text descreve Waydroid shell" "Waydroid shell" "$_out"

_run_app 'send_text ""' &>/dev/null
assert_eq "send_text rejeita mensagem vazia" "1" "$?"

_APP_TMP="/tmp/wdroid-app-$$"
_APP_TRACE="$_APP_TMP/trace"
mkdir -p "$_APP_TMP"
printf "" > "$_APP_TMP/app.apk"
printf "" > "$_APP_TMP/App.APK"
printf "" > "$_APP_TMP/app.txt"

_run_app "require_apk_file '$_APP_TMP/app.apk'" &>/dev/null
assert_eq "require_apk_file aceita .apk" "0" "$?"

_run_app "require_apk_file '$_APP_TMP/App.APK'" &>/dev/null
assert_eq "require_apk_file aceita .APK" "0" "$?"

_run_app "require_apk_file '$_APP_TMP/app.txt'" &>/dev/null
assert_eq "require_apk_file rejeita extensão inválida" "1" "$?"

_out=$(_run_app "waydroid() { printf 'waydroid:%s\n' \"\$*\"; }; install_apk '$_APP_TMP/app.apk'")
assert_contains "install_apk instala APK validado" "waydroid:app install $_APP_TMP/app.apk" "$_out"

_out=$(_run_app "
    TRACE='$_APP_TRACE'
    adb() { printf 'adb:%s\n' \"\$*\" >> \"\$TRACE\"; }
    waydroid_shell() { printf 'shell:%s\n' \"\$*\" >> \"\$TRACE\"; }
    capture_screen '$_APP_TMP/screens/shot.png'
    cat \"\$TRACE\"
")

assert_contains "screenshot usa screencap no Android" "shell:screencap -p /sdcard/ss.png" "$_out"
assert_contains "screenshot conecta ADB antes do pull" "adb:connect localhost:5555" "$_out"
assert_contains "screenshot usa serial localhost" "adb:-s localhost:5555 pull /sdcard/ss.png $_APP_TMP/screens/shot.png" "$_out"

if [ -d "$_APP_TMP/screens" ]; then
    pass "screenshot cria diretorio de destino"
else
    fail "screenshot cria diretorio de destino" "$_APP_TMP/screens"
fi

rm -rf "$_APP_TMP" /tmp/wdroid-test-logs-* 2>/dev/null || true
