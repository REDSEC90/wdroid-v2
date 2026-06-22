#!/bin/bash
# =============================================================================
# modules/container.sh — Controle do container Android
# =============================================================================

start_container() {
    log "Iniciando container Android..."
    retry sudo systemctl start "$WAYDROID_CONTAINER"
    wait_for is_container_running "$CONTAINER_TIMEOUT" "container"
}

stop_container() {
    log "Parando container Android..."
    run sudo systemctl stop "$WAYDROID_CONTAINER"
}

restart_container() {
    log "Reiniciando container..."
    run sudo systemctl restart "$WAYDROID_CONTAINER"
    wait_for is_container_running "$CONTAINER_TIMEOUT" "container"
}

enable_autostart() {
    run sudo systemctl enable "$WAYDROID_CONTAINER"
    log "Autostart ativado."
}

disable_autostart() {
    run sudo systemctl disable "$WAYDROID_CONTAINER"
    log "Autostart desativado."
}

is_container_running() {
    systemctl is-active --quiet "$WAYDROID_CONTAINER" 2>/dev/null
}
