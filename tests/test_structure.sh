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
    "commands/start.sh"
    "commands/stop.sh"
    "commands/status.sh"
    "commands/doctor.sh"
    "commands/reset.sh"
    "commands/logs.sh"
    "plugins/whatsapp.sh"
    "plugins/tiktok.sh"
)

for _f in "${_required_files[@]}"; do
    assert_file_exists "existe: $_f" "$BASE_DIR/$_f"
done

# Executáveis obrigatórios
_executables=(
    "bin/wdroid"
    "core/config.sh"
    "core/logger.sh"
    "core/utils.sh"
    "core/state.sh"
    "core/plugin.sh"
    "modules/app.sh"
    "modules/session.sh"
    "modules/container.sh"
    "modules/network.sh"
    "modules/backup.sh"
    "commands/start.sh"
    "commands/stop.sh"
    "commands/status.sh"
    "commands/doctor.sh"
    "commands/reset.sh"
    "commands/logs.sh"
    "plugins/whatsapp.sh"
    "plugins/tiktok.sh"
)

for _f in "${_executables[@]}"; do
    assert_executable "executável: $_f" "$BASE_DIR/$_f"
done

suite "Shebang"
for _f in "${_required_files[@]}"; do
    _first=$(head -1 "$BASE_DIR/$_f")
    if [[ "$_first" == "#!/bin/bash" ]]; then
        pass "shebang OK: $_f"
    else
        fail "shebang ausente/incorreto: $_f" "linha 1: $_first"
    fi
done
