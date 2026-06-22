#!/bin/bash
# tests/test_config.sh — Verifica variáveis de configuração

suite "Configuração (core/config.sh)"

# Carrega config em subshell para não poluir o ambiente
_config_output=$(bash -c "source '$BASE_DIR/core/config.sh'; \
    echo \"VERSION=\$WDROID_VERSION\"; \
    echo \"CONTAINER=\$WAYDROID_CONTAINER\"; \
    echo \"DATA_DIR=\$WAYDROID_DATA_DIR\"; \
    echo \"APP=\$APP_PACKAGE\"; \
    echo \"WDROID_HOME=\$WDROID_HOME\"; \
    echo \"BACKUP_DIR=\$BACKUP_DIR\"; \
    echo \"LOG_DIR=\$LOG_DIR\"; \
    echo \"APK_DIR=\$APK_DIR\"; \
    echo \"USER_PLUGIN_DIR=\$USER_PLUGIN_DIR\"; \
    echo \"STATE_FILE=\$STATE_FILE\"; \
    echo \"RETRY=\$RETRY_MAX\"; \
    echo \"CONTAINER_TIMEOUT=\$CONTAINER_TIMEOUT\"; \
    echo \"SESSION_TIMEOUT=\$SESSION_TIMEOUT\"")

assert_contains "WDROID_VERSION definida"       "VERSION=2"          "$_config_output"
assert_contains "WAYDROID_CONTAINER definido"   "CONTAINER=waydroid" "$_config_output"
assert_contains "WAYDROID_DATA_DIR definido"    "DATA_DIR=/var/lib/waydroid" "$_config_output"
assert_contains "APP_PACKAGE padrão WhatsApp"   "APP=com.whatsapp"   "$_config_output"
assert_contains "WDROID_HOME definido"           "WDROID_HOME="       "$_config_output"
assert_contains "BACKUP_DIR usa wdroid"          "/.wdroid/backups"   "$_config_output"
assert_contains "LOG_DIR usa wdroid"             "/.wdroid/logs"      "$_config_output"
assert_contains "APK_DIR usa wdroid"             "/.wdroid/apks"      "$_config_output"
assert_contains "USER_PLUGIN_DIR usa wdroid"     "/.wdroid/plugins"   "$_config_output"
assert_contains "STATE_FILE definido"            "STATE_FILE="        "$_config_output"
assert_contains "RETRY_MAX definido"            "RETRY="             "$_config_output"
assert_contains "CONTAINER_TIMEOUT definido"    "CONTAINER_TIMEOUT=" "$_config_output"
assert_contains "SESSION_TIMEOUT definido"      "SESSION_TIMEOUT="   "$_config_output"

_override_output=$(bash -c "
    export WAYDROID_DATA_DIR=/tmp/wdroid-data-custom
    export WDROID_APP_PACKAGE=com.example.app
    export WDROID_RETRY_MAX=9
    source '$BASE_DIR/core/config.sh'
    echo \"DATA_DIR=\$WAYDROID_DATA_DIR\"
    echo \"APP=\$APP_PACKAGE\"
    echo \"RETRY=\$RETRY_MAX\"
")
assert_contains "WAYDROID_DATA_DIR aceita override" "DATA_DIR=/tmp/wdroid-data-custom" "$_override_output"
assert_contains "APP_PACKAGE aceita override" "APP=com.example.app" "$_override_output"
assert_contains "RETRY_MAX aceita override" "RETRY=9" "$_override_output"
