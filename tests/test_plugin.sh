#!/bin/bash
# tests/test_plugin.sh — Verifica sistema de plugins

suite "Sistema de plugins (core/plugin.sh)"

_PLUGIN_TEST_DIR="/tmp/wdroid-test-plugins-$$"
mkdir -p "$_PLUGIN_TEST_DIR"

# Cria plugin de teste
cat > "$_PLUGIN_TEST_DIR/hello.sh" << 'EOF'
#!/bin/bash
# DESCRIPTION: Plugin de teste
plugin_main() {
    case "${1:-help}" in
        greet) echo "hello world" ;;
        help|*) echo "Plugin hello: greet" ;;
    esac
}
EOF
chmod +x "$_PLUGIN_TEST_DIR/hello.sh"

_run_plugin() {
    bash -c "
        export HOME=/tmp
        WDROID_LOG_DIR=/tmp/wdroid-test-logs-$$
        BASE_DIR='$BASE_DIR'
        source '$BASE_DIR/core/config.sh'
        source '$BASE_DIR/core/logger.sh'
        _init_logger
        _load_modules() { source \"\$BASE_DIR/modules/\$1.sh\" 2>/dev/null || true; }
        source '$BASE_DIR/core/plugin.sh'
        PLUGIN_DIR='$_PLUGIN_TEST_DIR'
        $1
    "
}

# plugin list inclui plugins oficiais mesmo com diretório de usuário separado
_out=$(_run_plugin "PLUGIN_DIR='/tmp/wdroid-test-user-plugins-$$'; plugin_cmd list")
assert_contains "plugin list inclui plugin oficial whatsapp" "whatsapp" "$_out"
assert_contains "plugin list inclui plugin oficial tiktok" "tiktok" "$_out"

# plugin list mostra plugins disponíveis
_out=$(_run_plugin 'plugin_cmd list')
assert_contains "plugin list mostra hello" "hello" "$_out"
assert_contains "plugin list mostra descrição" "Plugin de teste" "$_out"

_out=$(_run_plugin 'plugin_cmd list --help')
assert_contains "plugin list help mostra uso" "wdroid plugin" "$_out"

_run_plugin 'plugin_cmd list extra' &>/dev/null
assert_eq "plugin list rejeita argumento extra" "1" "$?"

_run_plugin 'plugin_cmd help extra' &>/dev/null
assert_eq "plugin help rejeita argumento extra" "1" "$?"

# plugin run executa ação do plugin
_out=$(_run_plugin 'plugin_cmd run hello greet')
assert_contains "plugin run hello greet retorna output" "hello world" "$_out"

# plugin run sem nome falha
_run_plugin 'plugin_cmd run' &>/dev/null
assert_eq "plugin run sem nome falha" "1" "$?"

# plugin run com nome inexistente falha
_run_plugin 'plugin_cmd run nao_existe' &>/dev/null
assert_eq "plugin run inexistente falha" "1" "$?"

# plugin run rejeita path traversal
_run_plugin 'plugin_cmd run ../hello' &>/dev/null
assert_eq "plugin run rejeita nome com path traversal" "1" "$?"

# plugin install copia arquivo para PLUGIN_DIR
_TMP_PLUGIN="/tmp/myplugin-$$.sh"
echo '#!/bin/bash
# DESCRIPTION: Instalado
plugin_main() { echo "instalado"; }' > "$_TMP_PLUGIN"
_run_plugin "PLUGIN_DIR='$_PLUGIN_TEST_DIR'; plugin_cmd install '$_TMP_PLUGIN' extra" &>/dev/null
assert_eq "plugin install rejeita argumento extra" "1" "$?"

_run_plugin "PLUGIN_DIR='$_PLUGIN_TEST_DIR'; plugin_cmd install '$_TMP_PLUGIN'" &>/dev/null
assert_file_exists "plugin install copia arquivo" "$_PLUGIN_TEST_DIR/myplugin-$$.sh"

_TMP_NO_ENTRYPOINT="/tmp/noentry-$$.sh"
echo '#!/bin/bash
echo sem entrypoint' > "$_TMP_NO_ENTRYPOINT"
_run_plugin "PLUGIN_DIR='$_PLUGIN_TEST_DIR'; plugin_cmd install '$_TMP_NO_ENTRYPOINT'" &>/dev/null
assert_eq "plugin install rejeita arquivo sem plugin_main" "1" "$?"

_TMP_BAD_EXT="/tmp/badext-$$.txt"
echo '#!/bin/bash
plugin_main() { true; }' > "$_TMP_BAD_EXT"
_run_plugin "PLUGIN_DIR='$_PLUGIN_TEST_DIR'; plugin_cmd install '$_TMP_BAD_EXT'" &>/dev/null
assert_eq "plugin install rejeita extensão inválida" "1" "$?"

_TMP_BAD_NAME="/tmp/bad name-$$.sh"
echo '#!/bin/bash
plugin_main() { true; }' > "$_TMP_BAD_NAME"
_run_plugin "PLUGIN_DIR='$_PLUGIN_TEST_DIR'; plugin_cmd install '$_TMP_BAD_NAME'" &>/dev/null
assert_eq "plugin install rejeita nome inválido" "1" "$?"

# plugin remove apaga o arquivo
_run_plugin "PLUGIN_DIR='$_PLUGIN_TEST_DIR'; plugin_cmd remove 'myplugin-$$' extra" &>/dev/null
assert_eq "plugin remove rejeita argumento extra" "1" "$?"

_run_plugin "PLUGIN_DIR='$_PLUGIN_TEST_DIR'; plugin_cmd remove 'myplugin-$$'" &>/dev/null
if [ ! -f "$_PLUGIN_TEST_DIR/myplugin-$$.sh" ]; then
    pass "plugin remove apaga arquivo"
else
    fail "plugin remove não apagou arquivo"
fi

_run_plugin "PLUGIN_DIR='$_PLUGIN_TEST_DIR'; plugin_cmd remove 'whatsapp'" &>/dev/null
assert_eq "plugin remove não remove plugin oficial" "1" "$?"

_OUTSIDE_PLUGIN="/tmp/wdroid-outside-plugin-$$.sh"
echo "fora" > "$_OUTSIDE_PLUGIN"
_run_plugin "PLUGIN_DIR='$_PLUGIN_TEST_DIR'; plugin_cmd remove '../wdroid-outside-plugin-$$'" &>/dev/null
assert_eq "plugin remove rejeita path traversal" "1" "$?"
assert_file_exists "plugin remove inválido preserva arquivo externo" "$_OUTSIDE_PLUGIN"

# Limpa
rm -rf "$_PLUGIN_TEST_DIR" "$_TMP_PLUGIN" "$_TMP_NO_ENTRYPOINT" "$_TMP_BAD_EXT" "$_TMP_BAD_NAME" "$_OUTSIDE_PLUGIN" /tmp/wdroid-test-logs-* 2>/dev/null || true
