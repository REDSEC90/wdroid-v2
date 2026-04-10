# =============================================================================
# Makefile — wdroid v2
# =============================================================================

INSTALL_BIN   := /usr/local/bin/wdroid
INSTALL_DIR   := $(HOME)/.wdroid
PLUGIN_DIR    := $(HOME)/.wdroid/plugins
DESKTOP_DIR   := $(HOME)/.local/share/applications
AUTOSTART_DIR := $(HOME)/.config/autostart

.DEFAULT_GOAL := help

.PHONY: help install uninstall permissions desktop autostart no-autostart \
        test lint clean

# ── Ajuda ─────────────────────────────────────────────────────────────────────

help:
	@printf "\n\033[1mwdroid v2 — Makefile\033[0m\n\n"
	@printf "  \033[36mmake install\033[0m        Instala wdroid no sistema\n"
	@printf "  \033[36mmake uninstall\033[0m      Remove wdroid do sistema\n"
	@printf "  \033[36mmake permissions\033[0m    Ajusta permissões dos scripts\n"
	@printf "  \033[36mmake desktop\033[0m        Cria atalho .desktop\n"
	@printf "  \033[36mmake autostart\033[0m      Configura início automático\n"
	@printf "  \033[36mmake no-autostart\033[0m   Remove início automático\n"
	@printf "  \033[36mmake lint\033[0m           Verifica scripts com shellcheck\n"
	@printf "  \033[36mmake test\033[0m           Executa testes básicos\n"
	@printf "  \033[36mmake clean\033[0m          Remove arquivos temporários\n\n"

# ── Permissões ────────────────────────────────────────────────────────────────

permissions:
	@echo "[+] Ajustando permissões..."
	@chmod +x bin/wdroid
	@chmod +x commands/*.sh
	@chmod +x modules/*.sh
	@chmod +x core/*.sh
	@chmod +x plugins/*.sh 2>/dev/null || true
	@echo "[✓] OK."

# ── Instalação ────────────────────────────────────────────────────────────────

install: permissions
	@echo "[+] Criando diretório: $(INSTALL_DIR)"
	@mkdir -p $(INSTALL_DIR) $(PLUGIN_DIR)
	@echo "[+] Copiando arquivos..."
	@cp -r bin core modules commands plugins Makefile README.md $(INSTALL_DIR)/
	@chmod +x $(INSTALL_DIR)/bin/wdroid
	@echo "[+] Criando link simbólico: $(INSTALL_BIN)"
	@sudo ln -sf $(INSTALL_DIR)/bin/wdroid $(INSTALL_BIN)
	@echo ""
	@echo "[✓] Instalação concluída."
	@echo "    Use: wdroid help"
	@echo ""

uninstall:
	@echo "[+] Removendo wdroid..."
	@sudo rm -f $(INSTALL_BIN)
	@rm -rf $(INSTALL_DIR)
	@rm -f $(DESKTOP_DIR)/whatsapp-waydroid.desktop
	@rm -f $(AUTOSTART_DIR)/wdroid.desktop
	@echo "[✓] wdroid removido."

# ── Integrações ───────────────────────────────────────────────────────────────

desktop: install
	@echo "[+] Criando atalho .desktop..."
	@mkdir -p $(DESKTOP_DIR)
	@printf '[Desktop Entry]\n\
Name=WhatsApp (Waydroid)\n\
Comment=Abrir WhatsApp via Waydroid\n\
Exec=$(INSTALL_BIN) start\n\
Icon=whatsapp\n\
Type=Application\n\
Terminal=false\n\
Categories=Network;Chat;\n\
StartupNotify=true\n' > $(DESKTOP_DIR)/whatsapp-waydroid.desktop
	@chmod +x $(DESKTOP_DIR)/whatsapp-waydroid.desktop
	@echo "[✓] Atalho criado: $(DESKTOP_DIR)/whatsapp-waydroid.desktop"

autostart: install
	@echo "[+] Configurando autostart..."
	@mkdir -p $(AUTOSTART_DIR)
	@printf '[Desktop Entry]\n\
Name=wdroid autostart\n\
Exec=$(INSTALL_BIN) start\n\
Type=Application\n\
Hidden=false\n\
NoDisplay=false\n\
X-GNOME-Autostart-enabled=true\n' > $(AUTOSTART_DIR)/wdroid.desktop
	@echo "[✓] Autostart configurado: $(AUTOSTART_DIR)/wdroid.desktop"

no-autostart:
	@rm -f $(AUTOSTART_DIR)/wdroid.desktop
	@echo "[✓] Autostart removido."

# ── Qualidade ─────────────────────────────────────────────────────────────────

lint:
	@echo "[+] Verificando scripts com shellcheck..."
	@command -v shellcheck >/dev/null 2>&1 || { echo "[!] shellcheck não encontrado. Instale: sudo apt install shellcheck"; exit 1; }
	@shellcheck bin/wdroid core/*.sh modules/*.sh commands/*.sh plugins/*.sh
	@echo "[✓] Nenhum problema encontrado."

test:
	@echo "[+] Executando testes básicos..."
	@bash -n bin/wdroid           && echo "  [✓] bin/wdroid: sintaxe OK"
	@for f in core/*.sh;     do bash -n "$$f" && echo "  [✓] $$f: OK"; done
	@for f in modules/*.sh;  do bash -n "$$f" && echo "  [✓] $$f: OK"; done
	@for f in commands/*.sh; do bash -n "$$f" && echo "  [✓] $$f: OK"; done
	@for f in plugins/*.sh;  do bash -n "$$f" && echo "  [✓] $$f: OK"; done
	@echo "[✓] Todos os testes passaram."

# ── Limpeza ───────────────────────────────────────────────────────────────────

clean:
	@rm -f /tmp/wdroid.lock /tmp/wdroid.state
	@echo "[✓] Temporários removidos."
