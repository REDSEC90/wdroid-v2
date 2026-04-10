#!/bin/bash
# =============================================================================
# core/plugin.sh — Sistema de plugins dinâmico
# =============================================================================

PLUGIN_DIR="$BASE_DIR/plugins"

plugin_cmd() {
    local action="${1:-list}"
    shift || true

    case "$action" in
        list)
            section "Plugins disponíveis"
            if [ -d "$PLUGIN_DIR" ] && ls "$PLUGIN_DIR"/*.sh &>/dev/null; then
                for p in "$PLUGIN_DIR"/*.sh; do
                    local name
                    name=$(basename "$p" .sh)
                    local desc
                    desc=$(grep -m1 "^# DESCRIPTION:" "$p" | sed 's/# DESCRIPTION: //' || echo "sem descrição")
                    printf "  ${_C_CYAN}%-20s${_C_RESET} %s\n" "$name" "$desc"
                done
            else
                warn "Nenhum plugin instalado."
            fi
            ;;
        run)
            local plugin_name="${1:-}"
            [ -z "$plugin_name" ] && die "Informe o nome do plugin: wdroid plugin run <nome>"
            local plugin_file="$PLUGIN_DIR/$plugin_name.sh"
            [ -f "$plugin_file" ] || die "Plugin não encontrado: $plugin_name"
            log "Executando plugin: $plugin_name"
            # shellcheck source=/dev/null
            source "$plugin_file"
            plugin_main "${@:2}"
            ;;
        install)
            local src="${1:-}"
            [ -z "$src" ] && die "Informe o caminho do plugin: wdroid plugin install <arquivo.sh>"
            [ -f "$src" ] || die "Arquivo não encontrado: $src"
            mkdir -p "$PLUGIN_DIR"
            cp "$src" "$PLUGIN_DIR/"
            chmod +x "$PLUGIN_DIR/$(basename "$src")"
            log "Plugin instalado: $(basename "$src")"
            ;;
        remove)
            local plugin_name="${1:-}"
            [ -z "$plugin_name" ] && die "Informe o nome do plugin: wdroid plugin remove <nome>"
            rm -f "$PLUGIN_DIR/$plugin_name.sh"
            log "Plugin removido: $plugin_name"
            ;;
        *)
            echo "Uso: wdroid plugin {list|run <nome>|install <arquivo>|remove <nome>}"
            ;;
    esac
}
