#!/bin/bash
# =============================================================================
# modules/session.sh — Controle da sessão Android
# =============================================================================

start_session() {
    log "Iniciando sessão Android..."
    waydroid session start &
    wait_for is_session_running "$SESSION_TIMEOUT" "sessão Android"
}

stop_session() {
    log "Encerrando sessão Android..."
    waydroid session stop 2>/dev/null || true
}

is_session_running() {
    waydroid status 2>/dev/null | grep -q "Session:.*RUNNING"
}

show_ui() {
    log "Abrindo interface Android completa..."
    waydroid show-full-ui &
}

enable_multi_window() {
    run waydroid prop set persist.waydroid.multi_windows true
    log "Modo multi-janela ativado."
}

disable_multi_window() {
    run waydroid prop set persist.waydroid.multi_windows false
    log "Modo multi-janela desativado."
}
