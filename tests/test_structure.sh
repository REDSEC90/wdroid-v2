#!/bin/bash
# tests/test_structure.sh — Verifica estrutura de arquivos e permissões

suite "Estrutura do projeto"

# Arquivos obrigatórios
_required_files=(
    "bin/wdroid"
    "core/config.sh"
    "core/logger.sh"
    "core/lock.sh"
    "core/utils.sh"
    "core/state.sh"
    "core/plugin.sh"
    "modules/app.sh"
    "modules/session.sh"
    "modules/container.sh"
    "modules/network.sh"
    "modules/backup.sh"
    "modules/services.sh"
    "commands/app.sh"
    "commands/backup.sh"
    "commands/fix.sh"
    "commands/help.sh"
    "commands/launch.sh"
    "commands/plugin.sh"
    "commands/restart.sh"
    "commands/services.sh"
    "commands/start.sh"
    "commands/stop.sh"
    "commands/status.sh"
    "commands/system.sh"
    "commands/doctor.sh"
    "commands/reset.sh"
    "commands/logs.sh"
    "commands/install.sh"
    "commands/version.sh"
    "plugins/whatsapp.sh"
    "plugins/tiktok.sh"
)

_required_docs=(
    "README.md"
    "CHANGELOG.md"
    "CONTRIBUTING.md"
    "docs/architecture.md"
    "docs/overview.md"
    "docs/security.md"
    "docs/troubleshooting.md"
    "docs/usage.md"
)

for _f in "${_required_files[@]}"; do
    assert_file_exists "existe: $_f" "$BASE_DIR/$_f"
done

for _f in "${_required_docs[@]}"; do
    assert_file_exists "existe doc: $_f" "$BASE_DIR/$_f"
done

# Executáveis obrigatórios
_executables=(
    "bin/wdroid"
    "core/config.sh"
    "core/logger.sh"
    "core/lock.sh"
    "core/utils.sh"
    "core/state.sh"
    "core/plugin.sh"
    "modules/app.sh"
    "modules/session.sh"
    "modules/container.sh"
    "modules/network.sh"
    "modules/backup.sh"
    "modules/services.sh"
    "commands/app.sh"
    "commands/backup.sh"
    "commands/fix.sh"
    "commands/help.sh"
    "commands/launch.sh"
    "commands/plugin.sh"
    "commands/restart.sh"
    "commands/services.sh"
    "commands/start.sh"
    "commands/stop.sh"
    "commands/status.sh"
    "commands/system.sh"
    "commands/doctor.sh"
    "commands/reset.sh"
    "commands/logs.sh"
    "commands/install.sh"
    "commands/version.sh"
    "plugins/whatsapp.sh"
    "plugins/tiktok.sh"
)

for _f in "${_executables[@]}"; do
    assert_executable "executável: $_f" "$BASE_DIR/$_f"
done

suite "Higiene estrutural"
_forbidden_paths=(
    "wdroid"
    "wdroid.pub"
    "tiktok.sh"
    "README2.md"
    "{bin,core,modules,commands,plugins}"
)

for _f in "${_forbidden_paths[@]}"; do
    assert_file_absent "ausente da raiz: $_f" "$BASE_DIR/$_f"
done

_root_android_artifacts=$(find "$BASE_DIR" -maxdepth 1 -type f \
    \( -iname "*.apk" -o -iname "*.apks" -o -iname "*.xapk" -o -iname "*.idsig" \) -print)
if [ -z "$_root_android_artifacts" ]; then
    pass "sem APKs/artefatos Android na raiz"
else
    fail "sem APKs/artefatos Android na raiz" "$_root_android_artifacts"
fi

_docs_generated_artifacts=$(find "$BASE_DIR/docs" -maxdepth 1 -type f \
    \( -iname "*.pdf" -o -iname "*.tar.gz" -o -iname "*.zip" \) -print)
if [ -z "$_docs_generated_artifacts" ]; then
    pass "sem artefatos gerados em docs/"
else
    fail "sem artefatos gerados em docs/" "$_docs_generated_artifacts"
fi

if [ ! -e "$BASE_DIR/LICENSE" ]; then
    pass "LICENSE ausente sem arquivo vazio"
elif [ -s "$BASE_DIR/LICENSE" ]; then
    pass "LICENSE presente e não vazio"
else
    fail "LICENSE não deve estar vazio" "$BASE_DIR/LICENSE"
fi

_secret_hits=$(find "$BASE_DIR" -path "$BASE_DIR/.git" -prune -o -type f -print0 \
    | xargs -0 grep -IlE 'BEGIN (OPENSSH|RSA|DSA|EC)? ?PRIVATE KEY' 2>/dev/null || true)
if [ -z "$_secret_hits" ]; then
    pass "sem chaves privadas no projeto"
else
    fail "sem chaves privadas no projeto" "$_secret_hits"
fi

_command_exit_hits=$(grep -RInE '(^|[[:space:]])exit([[:space:]]|$)' "$BASE_DIR/commands" 2>/dev/null || true)
if [ -z "$_command_exit_hits" ]; then
    pass "comandos sourceados não usam exit direto"
else
    fail "comandos sourceados não usam exit direto" "$_command_exit_hits"
fi

_command_eval_hits=$(grep -RInE '(^|[[:space:]])eval([[:space:]]|$)' "$BASE_DIR/commands" 2>/dev/null || true)
if [ -z "$_command_eval_hits" ]; then
    pass "comandos sourceados não usam eval"
else
    fail "comandos sourceados não usam eval" "$_command_eval_hits"
fi

_runtime_eval_hits=$(find "$BASE_DIR/bin" "$BASE_DIR/core" "$BASE_DIR/modules" "$BASE_DIR/commands" "$BASE_DIR/plugins" \
    -type f -print0 \
    | xargs -0 grep -HnE '(^|[[:space:]])eval([[:space:]]|$)' 2>/dev/null || true)
if [ -z "$_runtime_eval_hits" ]; then
    pass "código de runtime não usa eval"
else
    fail "código de runtime não usa eval" "$_runtime_eval_hits"
fi

_direct_waydroid_shell_hits=$(find "$BASE_DIR/bin" "$BASE_DIR/core" "$BASE_DIR/modules" "$BASE_DIR/commands" "$BASE_DIR/plugins" \
    -type f ! -path "$BASE_DIR/core/utils.sh" -print0 \
    | xargs -0 grep -HnE '(^|[[:space:]])waydroid[[:space:]]+shell([[:space:]]|$)' 2>/dev/null || true)
if [ -z "$_direct_waydroid_shell_hits" ]; then
    pass "waydroid shell centralizado em core/utils.sh"
else
    fail "waydroid shell centralizado em core/utils.sh" "$_direct_waydroid_shell_hits"
fi

suite "Shebang"
for _f in "${_required_files[@]}"; do
    _first=$(head -1 "$BASE_DIR/$_f")
    if [[ "$_first" == "#!/bin/bash" ]]; then
        pass "shebang OK: $_f"
    else
        fail "shebang ausente/incorreto: $_f" "linha 1: $_first"
    fi
done
