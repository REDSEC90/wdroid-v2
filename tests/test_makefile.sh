#!/bin/bash
# tests/test_makefile.sh — Verifica instalacao e empacotamento

suite "Makefile"

_makefile_content=$(sed -n '1,220p' "$BASE_DIR/Makefile")

assert_contains "install usa diretório XDG para código" \
    ".local/share/wdroid" "$_makefile_content"

assert_contains "dados ficam em ~/.wdroid" \
    "WDROID_HOME" "$_makefile_content"

assert_contains "uninstall preserva dados do usuário" \
    "Dados preservados" "$_makefile_content"

assert_contains "make test executa suíte completa" \
    "bash tests/run_tests.sh" "$_makefile_content"
