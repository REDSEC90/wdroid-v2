#!/bin/bash
# =============================================================================
# core/lock.sh — Lockfile para evitar execuções concorrentes
# =============================================================================

LOCK_FILE="/tmp/wdroid.lock"

acquire_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local pid
        pid=$(cat "$LOCK_FILE" 2>/dev/null)
        # Verifica se o processo ainda existe
        if kill -0 "$pid" 2>/dev/null; then
            die "Outra instância do wdroid já está em execução (PID: $pid). Use: wdroid status"
        else
            warn "Lockfile órfão detectado (PID: $pid). Removendo..."
            rm -f "$LOCK_FILE"
        fi
    fi

    echo $$ > "$LOCK_FILE"
    trap "_release_lock" EXIT INT TERM
}

_release_lock() {
    rm -f "$LOCK_FILE"
}

# Permite operações de leitura sem lock (status, logs, doctor)
acquire_lock_soft() {
    if [ -f "$LOCK_FILE" ]; then
        local pid
        pid=$(cat "$LOCK_FILE" 2>/dev/null)
        if kill -0 "$pid" 2>/dev/null; then
            warn "wdroid em execução em background (PID: $pid)"
        fi
    fi
}
