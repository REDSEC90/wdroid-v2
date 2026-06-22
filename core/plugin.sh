#!/bin/bash
# =============================================================================
# core/plugin.sh — Sistema de plugins dinâmico
# =============================================================================

BUNDLED_PLUGIN_DIR="$BASE_DIR/plugins"
PLUGIN_DIR="${PLUGIN_DIR:-$USER_PLUGIN_DIR}"

_plugin_name_valid() {
    local plugin_name="${1:-}"
    [[ "$plugin_name" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]]
}

_plugin_require_valid_name() {
    local plugin_name="${1:-}"
    _plugin_name_valid "$plugin_name" || die "Nome de plugin inválido: $plugin_name"
}

_plugin_has_entrypoint() {
    local plugin_file="$1"
    grep -Eq '^[[:space:]]*(function[[:space:]]+)?plugin_main[[:space:]]*(\(\))?[[:space:]]*\{' "$plugin_file"
}

_plugin_usage() {
    echo "Uso: wdroid plugin {list|run <nome> [args]|install <arquivo>|remove <nome>|help}"
}

_plugin_help_arg() {
    case "${1:-}" in
        help|--help|-h) return 0 ;;
        *) return 1 ;;
    esac
}

_plugin_dirs() {
    [ -d "$PLUGIN_DIR" ] && printf "%s\n" "$PLUGIN_DIR"
    if [ "$BUNDLED_PLUGIN_DIR" != "$PLUGIN_DIR" ] && [ -d "$BUNDLED_PLUGIN_DIR" ]; then
        printf "%s\n" "$BUNDLED_PLUGIN_DIR"
    fi
}

_plugin_resolve() {
    local plugin_name="$1"
    local dir
    _plugin_require_valid_name "$plugin_name"

    while IFS= read -r dir; do
        [ -f "$dir/$plugin_name.sh" ] && {
            printf "%s\n" "$dir/$plugin_name.sh"
            return 0
        }
    done < <(_plugin_dirs)

    return 1
}

plugin_cmd() {
    local action="${1:-list}"
    shift || true

    case "$action" in
        list)
            if [ "$#" -eq 1 ] && _plugin_help_arg "${1:-}"; then
                _plugin_usage
                return 0
            fi
            [ "$#" -eq 0 ] || {
                _plugin_usage
                return 1
            }
            section "Plugins disponíveis"
            local seen=" "
            local dir p name desc found=false
            while IFS= read -r dir; do
                for p in "$dir"/*.sh; do
                    [ -e "$p" ] || continue
                    found=true
                    local name
                    name=$(basename "$p" .sh)
                    case "$seen" in
                        *" $name "*) continue ;;
                    esac
                    seen="$seen$name "
                    local desc
                    desc=$(grep -m1 "^# DESCRIPTION:" "$p" | sed 's/# DESCRIPTION: //' || echo "sem descrição")
                    printf "  ${_C_CYAN}%-20s${_C_RESET} %s\n" "$name" "$desc"
                done
            done < <(_plugin_dirs)

            if ! $found; then
                warn "Nenhum plugin instalado."
            fi
            ;;
        run)
            local plugin_name="${1:-}"
            [ -z "$plugin_name" ] && die "Informe o nome do plugin: wdroid plugin run <nome>"
            _plugin_require_valid_name "$plugin_name"
            local plugin_file
            plugin_file="$(_plugin_resolve "$plugin_name")" || die "Plugin não encontrado: $plugin_name"
            log "Executando plugin: $plugin_name"
            # shellcheck source=/dev/null
            source "$plugin_file"
            plugin_main "${@:2}"
            ;;
        install)
            local src="${1:-}"
            [ -z "$src" ] && die "Informe o caminho do plugin: wdroid plugin install <arquivo.sh>"
            [ "$#" -eq 1 ] || {
                _plugin_usage
                return 1
            }
            [ -f "$src" ] || die "Arquivo não encontrado: $src"
            local plugin_base plugin_name
            plugin_base="$(basename "$src")"
            [[ "$plugin_base" == *.sh ]] || die "Plugin deve ser um arquivo .sh: $plugin_base"
            plugin_name="${plugin_base%.sh}"
            _plugin_require_valid_name "$plugin_name"
            _plugin_has_entrypoint "$src" || die "Plugin sem função plugin_main: $plugin_base"
            mkdir -p "$PLUGIN_DIR"
            cp "$src" "$PLUGIN_DIR/$plugin_base"
            chmod +x "$PLUGIN_DIR/$plugin_base"
            log "Plugin instalado: $plugin_base"
            ;;
        remove)
            local plugin_name="${1:-}"
            [ -z "$plugin_name" ] && die "Informe o nome do plugin: wdroid plugin remove <nome>"
            [ "$#" -eq 1 ] || {
                _plugin_usage
                return 1
            }
            _plugin_require_valid_name "$plugin_name"
            [ -f "$PLUGIN_DIR/$plugin_name.sh" ] || die "Plugin instalado pelo usuário não encontrado: $plugin_name"
            rm -f "$PLUGIN_DIR/$plugin_name.sh"
            log "Plugin removido: $plugin_name"
            ;;
        help|--help|-h)
            [ "$#" -eq 0 ] || {
                _plugin_usage
                return 1
            }
            _plugin_usage
            ;;
        *)
            _plugin_usage
            return 1
            ;;
    esac
}
