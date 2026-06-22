#!/bin/bash
# =============================================================================
# core/config.sh — Configurações globais do wdroid v2
# =============================================================================

WDROID_VERSION="2.0.0"

# Container
WAYDROID_CONTAINER="${WAYDROID_CONTAINER:-waydroid-container}"
WAYDROID_DATA_DIR="${WAYDROID_DATA_DIR:-${WDROID_DATA_DIR:-/var/lib/waydroid}}"

# Rede
WAYDROID_IFACE="${WAYDROID_IFACE:-waydroid0}"
WAYDROID_GATEWAY="${WAYDROID_GATEWAY:-192.168.240.1}"
WAYDROID_CONTAINER_MAC="${WAYDROID_CONTAINER_MAC:-00:16:3e:f9:d3:03}"

# App padrão
APP_PACKAGE="${APP_PACKAGE:-${WDROID_APP_PACKAGE:-com.whatsapp}}"

# Diretórios
WDROID_HOME="${WDROID_HOME:-$HOME/.wdroid}"
BACKUP_DIR="${WDROID_BACKUP_DIR:-$WDROID_HOME/backups}"
LOG_DIR="${WDROID_LOG_DIR:-$WDROID_HOME/logs}"
APK_DIR="${WDROID_APK_DIR:-$WDROID_HOME/apks}"
USER_PLUGIN_DIR="${WDROID_PLUGIN_DIR:-$WDROID_HOME/plugins}"
STATE_FILE="${WDROID_STATE_FILE:-/tmp/wdroid.state}"

# Timeouts e retries
RETRY_MAX="${WDROID_RETRY_MAX:-5}"
RETRY_DELAY="${WDROID_RETRY_DELAY:-1}"
CONTAINER_TIMEOUT="${WDROID_CONTAINER_TIMEOUT:-10}"
SESSION_TIMEOUT="${WDROID_SESSION_TIMEOUT:-15}"
