#!/bin/bash
# =============================================================================
# modules/backup.sh — Backup e restauração seguros
# =============================================================================

backup_safe() {
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

    sudo cp -r "$WAYDROID_DATA_DIR" "$dest/" || die "Falha no backup."
    log "Backup concluído: $dest"

    if $was_running; then
        start_container
        sleep 2
        start_session
    fi

    echo "$dest"
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

    warn "Isso substituirá o ambiente Android atual."
    confirm "Confirmar restauração?" "yes" || { log "Cancelado."; return 0; }

    stop_session 2>/dev/null || true
    stop_container 2>/dev/null || true
    sleep 1

    log "Restaurando de: $src"
    sudo rm -rf "$WAYDROID_DATA_DIR"
    sudo cp -r "$src/waydroid" "$WAYDROID_DATA_DIR"

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
    log "Mantendo os $keep backups mais recentes..."
    local count=0
    ls -t "$BACKUP_DIR" 2>/dev/null | while read -r entry; do
        ((count++))
        if ((count > keep)); then
            rm -rf "${BACKUP_DIR:?}/$entry"
            log "Removido: $entry"
        fi
    done
}
