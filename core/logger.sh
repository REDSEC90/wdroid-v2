#!/bin/bash
# =============================================================================
# core/logger.sh — Sistema de logging estruturado
# =============================================================================

# Cores
_C_RESET='\033[0m'
_C_GREEN='\033[0;32m'
_C_YELLOW='\033[1;33m'
_C_RED='\033[0;31m'
_C_CYAN='\033[0;36m'
_C_BLUE='\033[0;34m'
_C_BOLD='\033[1m'

_LOG_FILE=""

_init_logger() {
    mkdir -p "$LOG_DIR" 2>/dev/null || {
        _LOG_FILE=""
        return 0
    }
    _LOG_FILE="$LOG_DIR/wdroid-$(date +%Y%m%d).log"
}

_write() {
    local level="$1"
    local msg="$2"
    [ -n "$_LOG_FILE" ] || _init_logger
    [ -n "$_LOG_FILE" ] || return 0
    printf "[%s] [%-5s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$msg" >> "$_LOG_FILE" 2>/dev/null || true
}

log() {
    _write "INFO" "$1"
    printf "${_C_GREEN}[%s] [INFO]${_C_RESET}  %s\n" "$(date +%H:%M:%S)" "$1"
}

warn() {
    _write "WARN" "$1"
    printf "${_C_YELLOW}[%s] [WARN]${_C_RESET}  %s\n" "$(date +%H:%M:%S)" "$1"
}

error() {
    _write "ERROR" "$1"
    printf "${_C_RED}[%s] [ERROR]${_C_RESET} %s\n" "$(date +%H:%M:%S)" "$1" >&2
}

die() {
    error "$1"
    exit "${2:-1}"
}

header() {
    local line="════════════════════════════════════════════"
    printf "\n${_C_BOLD}${_C_BLUE}%s\n  %s\n%s${_C_RESET}\n\n" "$line" "$1" "$line"
    _write "INFO" "=== $1 ==="
}

section() {
    printf "\n${_C_BOLD}[ %s ]${_C_RESET}\n" "$1"
}

ok() {
    printf "  ${_C_GREEN}✓${_C_RESET} %s\n" "$1"
}

fail() {
    printf "  ${_C_RED}✗${_C_RESET} %s\n" "$1"
}

notice() {
    printf "  ${_C_YELLOW}!${_C_RESET} %s\n" "$1"
}
