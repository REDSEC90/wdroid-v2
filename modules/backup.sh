#!/bin/bash
# =============================================================================
# modules/backup.sh — Backup e restauração seguros
# =============================================================================

backup_safe() {
    [ -d "$WAYDROID_DATA_DIR" ] || die "Diretório Waydroid não encontrado: $WAYDROID_DATA_DIR"

    local ts
    ts=$(date +%Y%m%d_%H%M%S)
    local dest="$BACKUP_DIR/$ts"

    mkdir -p "$dest"
    log "Criando backup em: $dest"

    local was_running=false
    if is_container_running; then
        was_running=true
        warn "Container ativo — parando para garantir consistência..."
        stop_session 2>/dev/null || true
        stop_container
        sleep 1
    fi

    sudo cp -a "$WAYDROID_DATA_DIR" "$dest/" || {
        rm -rf "$dest"
        die "Falha no backup."
    }
    log "Backup concluído: $dest"

    if $was_running; then
        start_container
        sleep 2
        start_session
    fi

    echo "$dest"
}

_backup_payload_dir() {
    local src="$1"
    [ -d "$src/waydroid" ] || return 1
    printf "%s\n" "$src/waydroid"
}

restore_backup() {
    local src="${1:-}"

    if [ -z "$src" ]; then
        list_backups
        echo ""
        read -rp "  Nome do backup para restaurar: " bname
        src="$BACKUP_DIR/$bname"
    fi

    [ -d "$src" ] || die "Backup não encontrado: $src"

    local payload
    payload="$(_backup_payload_dir "$src")" || die "Backup inválido: diretório waydroid ausente em $src"

    warn "Isso substituirá o ambiente Android atual."
    confirm "Confirmar restauração?" "yes" || { log "Cancelado."; return 0; }

    stop_session 2>/dev/null || true
    stop_container 2>/dev/null || true
    sleep 1

    log "Restaurando de: $src"
    local restore_tmp previous
    restore_tmp="${WAYDROID_DATA_DIR}.wdroid-restore-$$"
    previous="${WAYDROID_DATA_DIR}.wdroid-previous-$$"

    sudo rm -rf "$restore_tmp" "$previous"
    sudo cp -a "$payload" "$restore_tmp" || {
        sudo rm -rf "$restore_tmp"
        die "Falha ao preparar restauração."
    }

    if [ -d "$WAYDROID_DATA_DIR" ]; then
        sudo mv "$WAYDROID_DATA_DIR" "$previous" || {
            sudo rm -rf "$restore_tmp"
            die "Falha ao mover instalação atual."
        }
    fi

    if sudo mv "$restore_tmp" "$WAYDROID_DATA_DIR"; then
        sudo rm -rf "$previous"
    else
        if [ -d "$previous" ]; then
            sudo mv "$previous" "$WAYDROID_DATA_DIR" 2>/dev/null || true
        fi
        sudo rm -rf "$restore_tmp"
        die "Falha ao ativar backup restaurado."
    fi

    log "Restauração concluída. Execute: wdroid start"
}

list_backups() {
    section "Backups disponíveis ($BACKUP_DIR)"
    if [ -d "$BACKUP_DIR" ] && ls "$BACKUP_DIR" &>/dev/null; then
        ls -lht "$BACKUP_DIR" | tail -n +2 | awk '{printf "  %-30s %s\n", $NF, $5}'
    else
        notice "Nenhum backup encontrado."
    fi
}

clean_backups() {
    local keep="${1:-3}"
    [[ "$keep" =~ ^[0-9]+$ ]] || die "Quantidade inválida de backups para manter: $keep"

    if [ ! -d "$BACKUP_DIR" ]; then
        notice "Nenhum backup encontrado."
        return 0
    fi

    log "Mantendo os $keep backups mais recentes..."
    local count=0
    ls -t "$BACKUP_DIR" | while read -r entry; do
        ((count += 1))
        if ((count > keep)); then
            rm -rf "${BACKUP_DIR:?}/$entry"
            log "Removido: $entry"
        fi
    done
}
