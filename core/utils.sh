#!/bin/bash
# =============================================================================
# core/utils.sh — Utilitários: run seguro, retry, timeout, validações
# =============================================================================

# Executa comando e aborta se falhar
run() {
    "$@" || die "Falha ao executar: $*"
}

# Executa silenciosamente — aborta se falhar
run_silent() {
    "$@" &>/dev/null || die "Falha ao executar: $*"
}

# Retry com backoff
retry() {
    local n=0
    local cmd=("$@")
    until "${cmd[@]}"; do
        ((n++))
        if ((n >= RETRY_MAX)); then
            die "Falhou após $n tentativas: ${cmd[*]}"
        fi
        warn "Tentativa $n/$RETRY_MAX falhou. Aguardando ${RETRY_DELAY}s..."
        sleep "$RETRY_DELAY"
    done
}

# Aguarda condição ser verdadeira com timeout
wait_for() {
    local condition="$1"
    local timeout="${2:-$SESSION_TIMEOUT}"
    local label="${3:-condição}"
    local elapsed=0

    while ! eval "$condition" &>/dev/null; do
        if ((elapsed >= timeout)); then
            die "Timeout ($timeout s) aguardando: $label"
        fi
        printf "\r  ${_C_YELLOW}aguardando %s... (%ds)${_C_RESET}" "$label" "$elapsed"
        sleep 1
        ((elapsed++))
    done
    printf "\r  ${_C_GREEN}%s pronto.${_C_RESET}           \n" "$label"
}

# Requer root — ou eleva automaticamente
require_root() {
    if [ "$EUID" -ne 0 ]; then
        warn "Privilégios de root necessários. Elevando..."
        exec sudo -E "$0" "$@"
    fi
}

# Confirmação interativa
confirm() {
    local msg="${1:-Continuar?}"
    local expected="${2:-y}"
    read -rp "  $msg ($expected/n): " answer
    [ "$answer" = "$expected" ]
}

# Verifica se comando existe
require_cmd() {
    command -v "$1" &>/dev/null || die "Comando não encontrado: $1. Instale antes de continuar."
}

# Verifica Wayland
check_wayland() {
    [ "$XDG_SESSION_TYPE" = "wayland" ] || [ -n "$WAYLAND_DISPLAY" ]
}

# Verifica KVM
check_kvm() {
    lsmod | grep -q kvm
}
