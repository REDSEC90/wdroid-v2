#!/bin/bash
# =============================================================================
# commands/install.sh — Instala dependências e inicializa Waydroid
# =============================================================================

_install_usage() {
    echo "Uso: wdroid install [--gapps|--vanilla|--no-init|--help]"
}

INSTALL_FLAVOR="ask"
INSTALL_INIT=true

while [ "$#" -gt 0 ]; do
    case "$1" in
        --gapps)
            INSTALL_FLAVOR="gapps"
            ;;
        --vanilla|--foss)
            INSTALL_FLAVOR="vanilla"
            ;;
        --no-init)
            INSTALL_INIT=false
            ;;
        help|--help|-h)
            _install_usage
            return 0
            ;;
        *)
            _install_usage
            return 1
            ;;
    esac
    shift
done

_install_waydroid_repo() {
    local repo_script status
    repo_script="$(mktemp)" || die "Falha ao criar arquivo temporário."

    curl -fsSL https://repo.waydro.id -o "$repo_script" || {
        status=$?
        rm -f "$repo_script"
        die "Falha ao baixar instalador do repositório Waydroid." "$status"
    }

    sudo bash "$repo_script" || {
        status=$?
        rm -f "$repo_script"
        die "Falha ao executar instalador do repositório Waydroid." "$status"
    }

    rm -f "$repo_script"
}

header "INSTALAÇÃO DO WAYDROID"

require_cmd sudo

log "Atualizando pacotes..."
run sudo apt update
run sudo apt install -y curl ca-certificates iptables adb

log "Adicionando repositório Waydroid..."
_install_waydroid_repo

log "Instalando Waydroid..."
run sudo apt install -y waydroid

if $INSTALL_INIT; then
    case "$INSTALL_FLAVOR" in
        ask)
            read -rp "  Instalar com GAPPS (Google Play)? (y/s/n): " gapps
            case "$gapps" in
                y|Y|s|S) run sudo waydroid init -s GAPPS ;;
                *)       run sudo waydroid init ;;
            esac
            ;;
        gapps)
            run sudo waydroid init -s GAPPS
            ;;
        vanilla)
            run sudo waydroid init
            ;;
    esac
else
    log "Inicialização do Waydroid pulada (--no-init)."
fi

target_user="${SUDO_USER:-${USER:-}}"
if [ -n "$target_user" ] && [ "$target_user" != "root" ]; then
    run sudo usermod -aG waydroid "$target_user"
    log "Usuário adicionado ao grupo waydroid: $target_user"
else
    warn "Usuário alvo não detectado; ajuste o grupo waydroid manualmente se necessário."
fi

log "Instalação concluída. Reinicie a sessão para aplicar grupos."
