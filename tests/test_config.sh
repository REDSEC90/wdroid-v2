#!/bin/bash
# tests/test_config.sh — Verifica variáveis de configuração

suite "Configuração (core/config.sh)"

# Carrega config em subshell para não poluir o ambiente
_config_output=$(bash -c "source '$BASE_DIR/core/config.sh'; \
    echo \"VERSION=\$WDROID_VERSION\"; \
    echo \"CONTAINER=\$WAYDROID_CONTAINER\"; \
    echo \"APP=\$APP_PACKAGE\"; \
    echo \"RETRY=\$RETRY_MAX\"; \
    echo \"CONTAINER_TIMEOUT=\$CONTAINER_TIMEOUT\"; \
    echo \"SESSION_TIMEOUT=\$SESSION_TIMEOUT\"")

assert_contains "WDROID_VERSION definida"       "VERSION=2"          "$_config_output"
assert_contains "WAYDROID_CONTAINER definido"   "CONTAINER=waydroid" "$_config_output"
assert_contains "APP_PACKAGE padrão WhatsApp"   "APP=com.whatsapp"   "$_config_output"
assert_contains "RETRY_MAX definido"            "RETRY="             "$_config_output"
assert_contains "CONTAINER_TIMEOUT definido"    "CONTAINER_TIMEOUT=" "$_config_output"
assert_contains "SESSION_TIMEOUT definido"      "SESSION_TIMEOUT="   "$_config_output"
