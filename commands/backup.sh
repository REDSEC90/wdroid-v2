#!/bin/bash
# =============================================================================
# commands/backup.sh — Roteamento de backup e restauracao
# =============================================================================

SUB="${1:-create}"
shift || true

_backup_usage() {
    echo "Uso: wdroid backup {create|restore|list|clean [N]|help}"
}

_backup_help_arg() {
    case "${1:-}" in
        help|--help|-h) return 0 ;;
        *) return 1 ;;
    esac
}

case "$SUB" in
    create)
        [ "$#" -eq 0 ] || {
            _backup_usage
            return 1
        }
        _load_modules container session backup
        backup_safe
        ;;
    restore)
        if [ "$#" -eq 1 ] && _backup_help_arg "${1:-}"; then
            _backup_usage
            return 0
        fi
        [ "$#" -le 1 ] || {
            _backup_usage
            return 1
        }
        _load_modules container session backup
        restore_backup "${1:-}"
        ;;
    list)
        if [ "$#" -eq 1 ] && _backup_help_arg "${1:-}"; then
            _backup_usage
            return 0
        fi
        [ "$#" -eq 0 ] || {
            _backup_usage
            return 1
        }
        _load_modules container session backup
        list_backups
        ;;
    clean)
        if [ "$#" -eq 1 ] && _backup_help_arg "${1:-}"; then
            _backup_usage
            return 0
        fi
        [ "$#" -le 1 ] || {
            _backup_usage
            return 1
        }
        _load_modules container session backup
        clean_backups "${1:-3}"
        ;;
    help|--help|-h)
        _backup_usage
        ;;
    *)
        _backup_usage
        return 1
        ;;
esac
