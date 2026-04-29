#!/bin/bash
# tests/test_utils.sh — Verifica utilitários

suite "Utils (core/utils.sh)"

_run_utils() {
    bash -c "
        export HOME=/tmp
        WDROID_LOG_DIR=/tmp/wdroid-test-logs-$$
        RETRY_MAX=3; RETRY_DELAY=0; SESSION_TIMEOUT=5
        source '$BASE_DIR/core/config.sh'
        source '$BASE_DIR/core/logger.sh'
        _init_logger
        source '$BASE_DIR/core/utils.sh'
        $1
    "
}

# run() propaga sucesso
_run_utils 'run true' &>/dev/null
assert_eq "run() propaga sucesso" "0" "$?"

# run() aborta em falha
_run_utils 'run false' &>/dev/null
assert_eq "run() aborta em falha (exit 1)" "1" "$?"

# run_silent() funciona silenciosamente
_out=$(_run_utils 'run_silent echo "nao deve aparecer"')
assert_eq "run_silent() não produz output" "" "$_out"

# require_cmd() passa para comando existente
_run_utils 'require_cmd bash' &>/dev/null
assert_eq "require_cmd() passa para bash" "0" "$?"

# require_cmd() falha para comando inexistente
_run_utils 'require_cmd comando_que_nao_existe_xyz' &>/dev/null
assert_eq "require_cmd() falha para inexistente" "1" "$?"

# check_wayland() retorna algo sem lançar erro
_run_utils 'check_wayland; true' &>/dev/null
assert_eq "check_wayland() não lança erro" "0" "$?"

# check_kvm() retorna algo sem lançar erro
_run_utils 'check_kvm; true' &>/dev/null
assert_eq "check_kvm() não lança erro" "0" "$?"

# wait_for() com condição imediatamente verdadeira
_run_utils 'wait_for "true" 5 "teste"' &>/dev/null
assert_eq "wait_for() passa com condição verdadeira" "0" "$?"

# wait_for() com timeout
_run_utils 'SESSION_TIMEOUT=1; wait_for "false" 1 "teste"' &>/dev/null
assert_eq "wait_for() falha com timeout" "1" "$?"

# retry() passa quando comando tem sucesso
_run_utils 'retry true' &>/dev/null
assert_eq "retry() passa com sucesso" "0" "$?"

# retry() falha após RETRY_MAX tentativas
_run_utils 'RETRY_MAX=2; RETRY_DELAY=0; retry false' &>/dev/null
assert_eq "retry() falha após RETRY_MAX" "1" "$?"

rm -rf /tmp/wdroid-test-logs-* 2>/dev/null || true
