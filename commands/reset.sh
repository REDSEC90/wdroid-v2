#!/bin/bash
# =============================================================================
# commands/reset.sh — Reset seguro com backup automático
# =============================================================================

_reset_usage() {
    echo "Uso: wdroid reset"
}

case "${1:-}" in
    "")
        ;;
    help|--help|-h)
        _reset_usage
        return 0
        ;;
    *)
        _reset_usage
        return 1
        ;;
esac

_load_modules container session backup

header "RESET DO WAYDROID"

printf "  ${_C_RED}${_C_BOLD}ATENÇÃO: Esta operação apaga todos os dados do Android.${_C_RESET}\n"
printf "  Apps, contas e configurações serão perdidos.\n\n"

# Backup opcional antes do reset
read -rp "  Criar backup antes do reset? (y/s/n): " do_backup
case "$do_backup" in
    y|Y|s|S)
        backup_safe
        ;;
esac

echo ""
confirm "Confirmar reset completo? Digite exatamente" "yes" || {
    log "Operação cancelada."
    return 0
}

log "Encerrando ambiente..."
stop_session 2>/dev/null || true
stop_container 2>/dev/null || true
sleep 2

log "Removendo dados..."
sudo rm -rf "$WAYDROID_DATA_DIR"

log "Reinicializando Waydroid..."

read -rp "  Instalar com GAPPS (Google Play)? (y/s/n): " use_gapps
case "$use_gapps" in
    y|Y|s|S)
        run sudo waydroid init -s GAPPS
        ;;
    *)
        run sudo waydroid init
        ;;
esac

log "Reset concluído. Execute: wdroid start"
