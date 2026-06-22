#!/bin/bash
# tests/test_services.sh — Verifica comandos Play Store e Xiaomi Cloud

suite "Serviços Android (modules/services.sh)"

_run_services() {
    bash -c "
        export HOME=/tmp
        WDROID_LOG_DIR=/tmp/wdroid-test-logs-$$
        BASE_DIR='$BASE_DIR'
        source '$BASE_DIR/core/config.sh'
        source '$BASE_DIR/core/logger.sh'
        source '$BASE_DIR/core/utils.sh'
        _init_logger
        is_session_running() { return 0; }
        require_state() { return 0; }
        waydroid() {
            if [ \"\$1\" = \"shell\" ] && [ \"\$2\" = \"--\" ] && [ \"\$3\" = \"pm\" ] && [ \"\$4\" = \"path\" ]; then
                case \"\$5\" in
                    com.android.vending|com.miui.cloudservice)
                        echo \"package:/system/priv-app/\$5/base.apk\"
                        return 0
                        ;;
                    *)
                        return 1
                        ;;
                esac
            fi
            if [ \"\$1\" = \"shell\" ] && [ \"\$2\" = \"--\" ] && [ \"\$3\" = \"content\" ]; then
                [ -n \"\${WDROID_TEST_GSF_CONTENT_ID:-}\" ] && echo \"Row: 0 value=\$WDROID_TEST_GSF_CONTENT_ID\"
                return 0
            fi
            if [ \"\$1\" = \"shell\" ] && [ \"\$2\" = \"--\" ] && [ \"\$3\" = \"sh\" ]; then
                echo \"1234567890123456789\"
                return 0
            fi
            return 0
        }
        sudo() {
            if [ \"\$1\" = \"-n\" ] && [ \"\$2\" = \"waydroid\" ]; then
                shift 2
                waydroid \"\$@\"
                return \$?
            fi
            if [ \"\$1\" = \"install\" ] || [ \"\$1\" = \"systemctl\" ]; then
                echo \"sudo:\$*\"
                return 0
            fi
            return 1
        }
        source '$BASE_DIR/modules/app.sh'
        source '$BASE_DIR/modules/services.sh'
        $1
    "
}

_run_services 'android_package_installed com.android.vending' &>/dev/null
assert_eq "detecta pacote instalado" "0" "$?"

_run_services 'android_package_installed com.xiaomi.account' &>/dev/null
assert_eq "detecta pacote ausente" "1" "$?"

_out=$(_run_services 'google_android_id')
assert_contains "extrai Android ID" "1234567890123456789" "$_out"

_out=$(_run_services 'WDROID_TEST_GSF_CONTENT_ID=987654321 google_android_id')
assert_contains "extrai Android ID via content provider" "987654321" "$_out"

_out=$(_run_services 'playstore_cmd help')
assert_contains "help Play Store menciona certify" "certify" "$_out"
assert_contains "help Play Store menciona GAPPS" "GAPPS" "$_out"

_run_services 'playstore_cmd help extra' &>/dev/null
assert_eq "playstore help rejeita argumento extra" "1" "$?"

_run_services 'playstore_cmd init --opcao-invalida' &>/dev/null
assert_eq "playstore init rejeita opção inválida" "1" "$?"

_run_services 'playstore_cmd init --force extra' &>/dev/null
assert_eq "playstore init rejeita argumento extra" "1" "$?"

_run_services 'playstore_cmd certify --opcao-invalida' &>/dev/null
assert_eq "playstore certify rejeita opção inválida" "1" "$?"

_run_services 'playstore_cmd status extra' &>/dev/null
assert_eq "playstore status rejeita argumento extra" "1" "$?"

_out=$(_run_services 'micloud_cmd help')
assert_contains "help Xiaomi Cloud menciona install-system" "install-system" "$_out"
assert_contains "help Xiaomi Cloud menciona i.mi.com" "i.mi.com" "$_out"

_run_services 'micloud_cmd help extra' &>/dev/null
assert_eq "micloud help rejeita argumento extra" "1" "$?"

_run_services 'micloud_cmd status extra' &>/dev/null
assert_eq "micloud status rejeita argumento extra" "1" "$?"

_run_services 'micloud_cmd open extra' &>/dev/null
assert_eq "micloud open rejeita argumento extra" "1" "$?"

_run_services 'micloud_cmd web extra' &>/dev/null
assert_eq "micloud web rejeita argumento extra" "1" "$?"

_MI_APK="/tmp/MiCloudTest-$$.APK"
_MI_TXT="/tmp/MiCloudTest-$$.txt"
printf "" > "$_MI_APK"
printf "" > "$_MI_TXT"

_run_services "micloud_cmd install-system '$_MI_TXT'" &>/dev/null
assert_eq "micloud install-system rejeita extensão inválida" "1" "$?"

_out=$(_run_services "micloud_cmd install-system '$_MI_APK'")
assert_contains "micloud install-system aceita .APK" "sudo:install -vpD $_MI_APK" "$_out"
assert_contains "micloud install-system normaliza nome do app" "MiCloudTest-$$/MiCloudTest-$$.apk" "$_out"

_help=$(bash "$BASE_DIR/bin/wdroid" help 2>/dev/null || true)
assert_contains "help principal menciona playstore" "playstore status" "$_help"
assert_contains "help principal menciona micloud" "micloud status" "$_help"

rm -rf /tmp/wdroid-test-logs-* "$_MI_APK" "$_MI_TXT" 2>/dev/null || true
