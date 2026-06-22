#!/bin/bash
# =============================================================================
# core/lock.sh — Lockfile para evitar execuções concorrentes
# =============================================================================

LOCK_FILE="${WDROID_LOCK_FILE:-/tmp/wdroid.lock}"

_lock_pid_active() {
    local pid="${1:-}"
    [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null
}

_lock_write_current_pid() {
    mkdir -p "$(dirname "$LOCK_FILE")" || die "Não foi possível criar diretório do lock: $(dirname "$LOCK_FILE")"
    ( set -o noclobber; printf "%s\n" "$$" > "$LOCK_FILE" ) 2>/dev/null
}

acquire_lock() {
    if _lock_write_current_pid; then
        trap "_release_lock" EXIT INT TERM
        return 0
    fi

    local pid
    pid=$(cat "$LOCK_FILE" 2>/dev/null || true)
    if _lock_pid_active "$pid"; then
        die "Outra instância do wdroid já está em execução (PID: $pid). Use: wdroid status"
    fi

    warn "Lockfile órfão detectado (PID: ${pid:-desconhecido}). Removendo..."
    rm -f "$LOCK_FILE"

    if _lock_write_current_pid; then
        trap "_release_lock" EXIT INT TERM
        return 0
    fi

    pid=$(cat "$LOCK_FILE" 2>/dev/null || true)
    die "Não foi possível adquirir lock${pid:+ (PID atual: $pid)}."
}

_release_lock() {
    local pid
    pid=$(cat "$LOCK_FILE" 2>/dev/null || true)
    if [ "$pid" = "$$" ]; then
        rm -f "$LOCK_FILE"
    fi
}

# Permite operações de leitura sem lock (status, logs, doctor)
acquire_lock_soft() {
    if [ -f "$LOCK_FILE" ]; then
        local pid
        pid=$(cat "$LOCK_FILE" 2>/dev/null || true)
        if _lock_pid_active "$pid"; then
            warn "wdroid em execução em background (PID: $pid)"
        fi
    fi
}
