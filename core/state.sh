#!/bin/bash
# =============================================================================
# core/state.sh — State machine do ambiente Waydroid
#
# Estados possíveis:
#   STOPPED          container inativo
#   CONTAINER_ONLY   container ativo, sem sessão Android
#   SESSION_RUNNING  sessão Android ativa, sem app
#   APP_RUNNING      app ativo (verificado via ADB/ps)
# =============================================================================

get_state() {
    local _status
    _status="$(waydroid status 2>/dev/null || true)"

    if ! echo "$_status" | grep -q "Container:.*RUNNING"; then
        echo "STOPPED"
        return
    fi

    if ! echo "$_status" | grep -q "Session:.*RUNNING"; then
        echo "CONTAINER_ONLY"
        return
    fi

    if declare -F waydroid_shell &>/dev/null && waydroid_shell pidof "$APP_PACKAGE" &>/dev/null; then
        echo "APP_RUNNING"
        return
    fi

    echo "SESSION_RUNNING"
}

save_state() {
    echo "$1" > "$STATE_FILE"
}

load_state() {
    cat "$STATE_FILE" 2>/dev/null || echo "UNKNOWN"
}

# Exibe estado com cor
print_state() {
    local state
    state=$(get_state)
    case "$state" in
        STOPPED)          printf "${_C_RED}STOPPED${_C_RESET}" ;;
        CONTAINER_ONLY)   printf "${_C_YELLOW}CONTAINER_ONLY${_C_RESET}" ;;
        SESSION_RUNNING)  printf "${_C_CYAN}SESSION_RUNNING${_C_RESET}" ;;
        APP_RUNNING)      printf "${_C_GREEN}APP_RUNNING${_C_RESET}" ;;
        *)                printf "${_C_YELLOW}UNKNOWN${_C_RESET}" ;;
    esac
}

# Garante estado mínimo ou aborta
require_state() {
    local required="$1"
    local current
    current=$(get_state)

    case "$required" in
        CONTAINER_ONLY)
            if [ "$current" = "STOPPED" ]; then
                die "Container não está ativo. Execute: wdroid start"
            fi
            ;;
        SESSION_RUNNING|APP_RUNNING)
            if [ "$current" = "STOPPED" ] || [ "$current" = "CONTAINER_ONLY" ]; then
                die "Sessão Android não está ativa. Execute: wdroid start"
            fi
            ;;
    esac
}
