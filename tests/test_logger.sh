#!/bin/bash
# tests/test_logger.sh — Verifica funções de logging

suite "Logger (core/logger.sh)"

_run_logger() {
    bash -c "
        export HOME=/tmp
        WDROID_LOG_DIR=/tmp/wdroid-test-logs-$$
        source '$BASE_DIR/core/config.sh'
        source '$BASE_DIR/core/logger.sh'
        _init_logger
        $1
    "
}

# log() imprime INFO
_out=$(_run_logger 'log "mensagem teste"')
assert_contains "log() imprime [INFO]"    "[INFO]"          "$_out"
assert_contains "log() imprime mensagem"  "mensagem teste"  "$_out"

# warn() imprime WARN
_out=$(_run_logger 'warn "aviso teste"')
assert_contains "warn() imprime [WARN]"   "[WARN]"          "$_out"
assert_contains "warn() imprime mensagem" "aviso teste"     "$_out"

# error() imprime ERROR no stderr
_out=$(_run_logger 'error "erro teste"' 2>&1)
assert_contains "error() imprime [ERROR]" "[ERROR]"         "$_out"
assert_contains "error() imprime mensagem" "erro teste"     "$_out"

# die() sai com código 1
_run_logger 'die "fatal"' &>/dev/null
assert_eq "die() sai com código 1" "1" "$?"

# die() aceita código customizado
_run_logger 'die "fatal" 42' &>/dev/null
assert_eq "die() aceita código customizado" "42" "$?"

# header() imprime o título
_out=$(_run_logger 'header "TÍTULO TESTE"')
assert_contains "header() imprime título" "TÍTULO TESTE" "$_out"

# logger funciona mesmo sem _init_logger explícito
_out=$(bash -c "
    export HOME=/tmp
    WDROID_LOG_DIR=/tmp/wdroid-test-logs-noinit-$$
    source '$BASE_DIR/core/config.sh'
    source '$BASE_DIR/core/logger.sh'
    log 'sem init'
")
assert_contains "logger inicializa sob demanda" "sem init" "$_out"

# logger não aborta quando LOG_DIR não pode ser criado
_out=$(bash -c "
    export HOME=/tmp
    WDROID_LOG_DIR=/dev/null
    source '$BASE_DIR/core/config.sh'
    source '$BASE_DIR/core/logger.sh'
    _init_logger
    log 'sem arquivo'
")
assert_contains "logger segue sem arquivo de log" "sem arquivo" "$_out"

# ok/fail/notice não lançam erro
assert_exit_ok "ok() não lança erro"     bash -c "source '$BASE_DIR/core/config.sh'; source '$BASE_DIR/core/logger.sh'; _init_logger; ok 'tudo bem'"
assert_exit_ok "fail() não lança erro"   bash -c "source '$BASE_DIR/core/config.sh'; source '$BASE_DIR/core/logger.sh'; _init_logger; fail 'algo errado'"
assert_exit_ok "notice() não lança erro" bash -c "source '$BASE_DIR/core/config.sh'; source '$BASE_DIR/core/logger.sh'; _init_logger; notice 'atenção'"

# Limpa logs de teste
rm -rf /tmp/wdroid-test-logs-* /tmp/wdroid-test-logs-noinit-* 2>/dev/null || true
