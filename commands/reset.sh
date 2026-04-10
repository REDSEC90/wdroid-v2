#!/bin/bash
# =============================================================================
# commands/reset.sh — Reset seguro com backup automático
# =============================================================================

_load_modules container session backup

header "RESET DO WAYDROID"

printf "  ${_C_RED}${_C_BOLD}ATENÇÃO: Esta operação apaga todos os dados do Android.${_C_RESET}\n"
printf "  Apps, contas e configurações serão perdidos.\n\n"

# Backup automático obrigatório antes do reset
read -rp "  Criar backup antes do reset? (y/n): " do_backup
if [ "$do_backup" = "y" ]; then
    backup_safe
fi

echo ""
confirm "Confirmar reset completo? Digite exatamente" "yes" || {
    log "Operação cancelada."
    exit 0
}

log "Encerrando ambiente..."
stop_session 2>/dev/null || true
stop_container 2>/dev/null || true
sleep 2

log "Removendo dados..."
sudo rm -rf "$WAYDROID_DATA_DIR"

log "Reinicializando Waydroid..."

read -rp "  Instalar com GAPPS (Google Play)? (y/n): " use_gapps
if [ "$use_gapps" = "y" ]; then
    run sudo waydroid init -s GAPPS
else
    run sudo waydroid init
fi

log "Reset concluído. Execute: wdroid start"
