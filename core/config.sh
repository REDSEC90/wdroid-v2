#!/bin/bash
# =============================================================================
# core/config.sh — Configurações globais do wdroid v2
# =============================================================================

WDROID_VERSION="2.0.0"

# Container
WAYDROID_CONTAINER="waydroid-container"
WAYDROID_DATA_DIR="/var/lib/waydroid"

# Rede
WAYDROID_IFACE="waydroid0"
WAYDROID_GATEWAY="192.168.240.1"

# App padrão
APP_PACKAGE="com.whatsapp"

# Diretórios
BACKUP_DIR="${WDROID_BACKUP_DIR:-$HOME/.wdroid/backups}"
LOG_DIR="${WDROID_LOG_DIR:-$HOME/.wdroid/logs}"
STATE_FILE="/tmp/wdroid.state"

# Timeouts e retries
RETRY_MAX=5
RETRY_DELAY=1
CONTAINER_TIMEOUT=10
SESSION_TIMEOUT=15
