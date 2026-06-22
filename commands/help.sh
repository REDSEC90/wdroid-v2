#!/bin/bash
# =============================================================================
# commands/help.sh — Ajuda principal da CLI
# =============================================================================

case "${1:-}" in
    ""|help|--help|-h)
        ;;
    *)
        echo "Uso: wdroid help"
        return 1
        ;;
esac

printf "\n${_C_BOLD}${_C_BLUE}wdroid v%s${_C_RESET} — Gerenciador Waydroid + WhatsApp para Debian\n\n" "$WDROID_VERSION"

printf "${_C_BOLD}Ciclo de vida:${_C_RESET}\n"
printf "  %-28s %s\n" "start"           "Inicia container + sessão + WhatsApp"
printf "  %-28s %s\n" "stop"            "Encerra sessão e container"
printf "  %-28s %s\n" "restart"         "Para e inicia novamente"

printf "\n${_C_BOLD}Observabilidade:${_C_RESET}\n"
printf "  %-28s %s\n" "status"          "Status completo do sistema"
printf "  %-28s %s\n" "doctor [--fix]"  "Diagnóstico (--fix para corrigir)"
printf "  %-28s %s\n" "logs [modo] [N]" "Logs: container|wdroid|all|follow"

printf "\n${_C_BOLD}Manutenção:${_C_RESET}\n"
printf "  %-28s %s\n" "fix"             "Correção automática de problemas"
printf "  %-28s %s\n" "reset"           "Reset completo (com backup automático)"

printf "\n${_C_BOLD}Apps:${_C_RESET}\n"
printf "  %-28s %s\n" "launch [pacote]"    "Abre app (padrão: WhatsApp)"
printf "  %-28s %s\n" "launch whatsapp"    "Abre o WhatsApp"
printf "  %-28s %s\n" "launch tiktok-lite" "Abre o TikTok Lite"
printf "  %-28s %s\n" "install-apk <f>"    "Instala APK"
printf "  %-28s %s\n" "apps"               "Lista apps instalados"
printf "  %-28s %s\n" "adb"                "Conecta ADB"
printf "  %-28s %s\n" "send-text <msg>"    "Envia texto via ADB"
printf "  %-28s %s\n" "screenshot [f]"     "Captura tela"
printf "  %-28s %s\n" "multi-window"       "Ativa modo multi-janela"

printf "\n${_C_BOLD}Serviços Android:${_C_RESET}\n"
printf "  %-28s %s\n" "playstore status"   "Verifica Play Store/GMS"
printf "  %-28s %s\n" "playstore init"     "Inicializa Waydroid com GAPPS"
printf "  %-28s %s\n" "playstore certify"  "Mostra Android ID para certificação"
printf "  %-28s %s\n" "micloud status"     "Verifica Xiaomi Cloud"
printf "  %-28s %s\n" "micloud install <apk...>" "Instala APKs Xiaomi locais"
printf "  %-28s %s\n" "micloud web"        "Abre i.mi.com no Android"

printf "\n${_C_BOLD}Backup:${_C_RESET}\n"
printf "  %-28s %s\n" "backup create"   "Cria backup"
printf "  %-28s %s\n" "backup restore"  "Restaura backup"
printf "  %-28s %s\n" "backup list"     "Lista backups"
printf "  %-28s %s\n" "backup clean [N]" "Mantém N backups (padrão: 3)"

printf "\n${_C_BOLD}Plugins:${_C_RESET}\n"
printf "  %-28s %s\n" "plugin list"              "Lista plugins"
printf "  %-28s %s\n" "plugin run <nome> [args]" "Executa plugin"
printf "  %-28s %s\n" "plugin install <arquivo>" "Instala plugin"

printf "\n${_C_BOLD}Sistema:${_C_RESET}\n"
printf "  %-28s %s\n" "install [opts]"  "Instala Waydroid (--gapps|--vanilla|--no-init)"
printf "  %-28s %s\n" "autostart"       "Ativa início automático no boot"
printf "  %-28s %s\n" "no-autostart"    "Desativa início automático"
printf "  %-28s %s\n" "version"         "Exibe versão"

printf "\n  ${_C_CYAN}Exemplos: wdroid start | wdroid doctor --fix | wdroid logs follow${_C_RESET}\n\n"
