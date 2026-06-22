#!/bin/bash
# tests/test_backup.sh — Verifica backup e restauração

suite "Backup e restauração"

_BACKUP_TMP="/tmp/wdroid-backup-test-$$"
_BACKUP_DATA="$_BACKUP_TMP/waydroid"
_BACKUP_DIR="$_BACKUP_TMP/backups"
mkdir -p "$_BACKUP_TMP"

_run_backup() {
    local script="$1"
    bash -c "
        export HOME=/tmp
        BASE_DIR='$BASE_DIR'
        WDROID_LOG_DIR='$_BACKUP_TMP/logs'
        WAYDROID_DATA_DIR='$_BACKUP_DATA'
        WDROID_BACKUP_DIR='$_BACKUP_DIR'
        source '$BASE_DIR/core/config.sh'
        source '$BASE_DIR/core/logger.sh'
        source '$BASE_DIR/core/utils.sh'
        _init_logger
        is_container_running() { return 1; }
        stop_session() { echo stop-session; }
        stop_container() { echo stop-container; }
        start_container() { echo start-container; }
        start_session() { echo start-session; }
        sleep() { return 0; }
        sudo() { \"\$@\"; }
        confirm() { return 0; }
        export -f sleep sudo
        source '$BASE_DIR/modules/backup.sh'
        $script
    "
}

rm -rf "$_BACKUP_DATA" "$_BACKUP_DIR"
_run_backup 'backup_safe' &>/dev/null
assert_eq "backup falha sem diretório Waydroid" "1" "$?"
if [ ! -d "$_BACKUP_DIR" ]; then
    pass "backup inválido não cria diretório de backup"
else
    fail "backup inválido não cria diretório de backup" "$_BACKUP_DIR"
fi

mkdir -p "$_BACKUP_DATA"
printf "ok\n" > "$_BACKUP_DATA/system.img"
_run_backup 'backup_safe' &>/dev/null
assert_eq "backup cria cópia válida" "0" "$?"
_backup_file=$(find "$_BACKUP_DIR" -path "*/waydroid/system.img" -type f | head -1)
if [ -n "$_backup_file" ]; then
    pass "backup contém diretório waydroid"
else
    fail "backup contém diretório waydroid"
fi

rm -rf "$_BACKUP_DATA" "$_BACKUP_DIR"
mkdir -p "$_BACKUP_DATA" "$_BACKUP_DIR/bad"
printf "keep\n" > "$_BACKUP_DATA/current.txt"
_run_backup "restore_backup '$_BACKUP_DIR/bad'" &>/dev/null
assert_eq "restore rejeita backup inválido" "1" "$?"
if [ -f "$_BACKUP_DATA/current.txt" ]; then
    pass "restore inválido preserva dados atuais"
else
    fail "restore inválido preserva dados atuais"
fi

rm -rf "$_BACKUP_DATA" "$_BACKUP_DIR"
mkdir -p "$_BACKUP_DATA" "$_BACKUP_DIR/good/waydroid"
printf "old\n" > "$_BACKUP_DATA/current.txt"
printf "new\n" > "$_BACKUP_DIR/good/waydroid/restored.txt"
_run_backup "restore_backup '$_BACKUP_DIR/good'" &>/dev/null
assert_eq "restore válido conclui" "0" "$?"
if [ -f "$_BACKUP_DATA/restored.txt" ] && [ ! -f "$_BACKUP_DATA/current.txt" ]; then
    pass "restore troca dados pelo backup"
else
    fail "restore troca dados pelo backup"
fi

rm -rf "$_BACKUP_TMP" 2>/dev/null || true
