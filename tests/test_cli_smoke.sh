#!/bin/bash
# tests/test_cli_smoke.sh — Smoke tests do bin/wdroid executável

suite "CLI smoke (bin/wdroid)"

_CLI_TMP="/tmp/wdroid-cli-smoke-$$"
_CLI_BIN="$_CLI_TMP/bin"
mkdir -p "$_CLI_BIN"

cat > "$_CLI_BIN/waydroid" <<'EOF'
#!/bin/bash
case "${1:-}" in
    app)
        case "${2:-}" in
            list) echo "Name: mock.app" ;;
            launch) echo "launch:${3:-}" ;;
            install) echo "install:${3:-}" ;;
            remove) echo "remove:${3:-}" ;;
        esac
        ;;
    status)
        echo "Container: STOPPED"
        echo "Session: STOPPED"
        ;;
    shell)
        echo "mock-shell"
        ;;
    prop)
        echo "prop:${*:2}"
        ;;
    *)
        echo "waydroid:${*}"
        ;;
esac
EOF
chmod +x "$_CLI_BIN/waydroid"

cat > "$_CLI_BIN/systemctl" <<'EOF'
#!/bin/bash
case "${1:-}" in
    is-active)
        [ "${WDROID_TEST_CONTAINER_ACTIVE:-}" = "1" ] && exit 0
        exit 1
        ;;
    show)
        [ "${WDROID_TEST_SYSTEMCTL_SHOW_FAIL:-}" = "1" ] && exit 1
        echo "ActiveEnterTimestamp=mock"
        ;;
    *)
        exit 0
        ;;
esac
EOF
chmod +x "$_CLI_BIN/systemctl"

cat > "$_CLI_BIN/iptables" <<'EOF'
#!/bin/bash
exit 0
EOF
chmod +x "$_CLI_BIN/iptables"

cat > "$_CLI_BIN/sudo" <<'EOF'
#!/bin/bash
if [ "${1:-}" = "-n" ] && [ "${2:-}" = "waydroid" ]; then
    shift 2
    waydroid "$@"
    exit $?
fi

[ -n "${WDROID_TEST_TRACE:-}" ] && printf "sudo:%s\n" "$*" >> "$WDROID_TEST_TRACE"
exit 0
EOF
chmod +x "$_CLI_BIN/sudo"

cat > "$_CLI_BIN/curl" <<'EOF'
#!/bin/bash
out=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        -o)
            shift
            out="${1:-}"
            ;;
    esac
    shift || true
done

[ -n "${WDROID_TEST_TRACE:-}" ] && printf "curl-out:%s\n" "$out" >> "$WDROID_TEST_TRACE"

if [ "${WDROID_TEST_CURL_FAIL:-}" = "1" ]; then
    exit 22
fi

[ -n "$out" ] && printf "#!/bin/bash\n" > "$out"
exit 0
EOF
chmod +x "$_CLI_BIN/curl"

cat > "$_CLI_BIN/lsmod" <<'EOF'
#!/bin/bash
echo "kvm 1 0"
EOF
chmod +x "$_CLI_BIN/lsmod"

cat > "$_CLI_BIN/journalctl" <<'EOF'
#!/bin/bash
if [ "${WDROID_TEST_JOURNAL_FAIL:-}" = "1" ]; then
    exit 1
fi

printf "journal:%s\n" "$*"
EOF
chmod +x "$_CLI_BIN/journalctl"

_run_cli() {
    PATH="$_CLI_BIN:$PATH" \
    HOME=/tmp \
    WDROID_HOME="$_CLI_TMP/home" \
    WDROID_BACKUP_DIR="$_CLI_TMP/backups" \
    WDROID_LOG_DIR="$_CLI_TMP/logs" \
    WDROID_LOCK_FILE="$_CLI_TMP/wdroid.lock" \
    WDROID_STATE_FILE="$_CLI_TMP/wdroid.state" \
    WDROID_TEST_TRACE="${WDROID_TEST_TRACE:-}" \
    WDROID_TEST_CURL_FAIL="${WDROID_TEST_CURL_FAIL:-}" \
    WDROID_TEST_JOURNAL_FAIL="${WDROID_TEST_JOURNAL_FAIL:-}" \
    WDROID_TEST_CONTAINER_ACTIVE="${WDROID_TEST_CONTAINER_ACTIVE:-}" \
    WDROID_TEST_SYSTEMCTL_SHOW_FAIL="${WDROID_TEST_SYSTEMCTL_SHOW_FAIL:-}" \
    TMPDIR="${WDROID_TEST_TMPDIR:-/tmp}" \
    "$BASE_DIR/bin/wdroid" "$@"
}

_out=$(_run_cli help)
assert_contains "help executável mostra comandos" "wdroid v" "$_out"
assert_contains "help executável mostra Play Store" "playstore status" "$_out"

_run_cli help topico-inexistente &>/dev/null
assert_eq "help rejeita tópico não implementado" "1" "$?"

_out=$(_run_cli version)
assert_contains "version executável mostra versão" "wdroid v" "$_out"

_out=$(_run_cli version --help)
assert_contains "version help executável" "wdroid version" "$_out"

_run_cli version extra &>/dev/null
assert_eq "version rejeita argumento extra" "1" "$?"

_out=$(_run_cli plugin list)
assert_contains "plugin list executável mostra whatsapp" "whatsapp" "$_out"
assert_contains "plugin list executável mostra tiktok" "tiktok" "$_out"

_out=$(_run_cli apps)
assert_contains "apps executável usa waydroid mockado" "mock.app" "$_out"

_out=$(_run_cli apps --help)
assert_contains "apps help executável" "wdroid {" "$_out"

_run_cli apps extra &>/dev/null
assert_eq "apps rejeita argumento extra" "1" "$?"

_out=$(_run_cli adb --help)
assert_contains "adb help executável" "wdroid {" "$_out"

_run_cli adb extra &>/dev/null
assert_eq "adb rejeita argumento extra" "1" "$?"

_out=$(_run_cli screenshot --help)
assert_contains "screenshot help executável" "screenshot" "$_out"

_run_cli screenshot a.png b.png &>/dev/null
assert_eq "screenshot rejeita argumento extra" "1" "$?"

_out=$(_run_cli send-text --help)
assert_contains "send-text help executável" "send-text" "$_out"

_run_cli send-text &>/dev/null
assert_eq "send-text sem mensagem retorna erro" "1" "$?"

_out=$(_run_cli install-apk --help)
assert_contains "install-apk help executável" "install-apk" "$_out"

_run_cli install-apk um.apk dois.apk &>/dev/null
assert_eq "install-apk rejeita argumento extra" "1" "$?"

_out=$(_run_cli multi-window --help)
assert_contains "multi-window help executável" "multi-window" "$_out"

_run_cli multi-window extra &>/dev/null
assert_eq "multi-window rejeita argumento extra" "1" "$?"

_out=$(_run_cli launch --help)
assert_contains "launch help executável" "wdroid launch" "$_out"

_run_cli launch com.app extra &>/dev/null
assert_eq "launch rejeita argumento extra" "1" "$?"

_out=$(_run_cli playstore help)
assert_contains "playstore help executável" "Play Store" "$_out"

_run_cli playstore help extra &>/dev/null
assert_eq "playstore help rejeita argumento extra" "1" "$?"

_out=$(_run_cli micloud help)
assert_contains "micloud help executável" "Xiaomi Cloud" "$_out"

_run_cli micloud help extra &>/dev/null
assert_eq "micloud help rejeita argumento extra" "1" "$?"

_out=$(_run_cli backup list)
assert_contains "backup list executável" "Backups disponíveis" "$_out"

_out=$(_run_cli backup help)
assert_contains "backup help executável" "wdroid backup" "$_out"

_out=$(_run_cli status --help)
assert_contains "status help executável" "wdroid status" "$_out"

_run_cli status extra &>/dev/null
assert_eq "status rejeita argumento extra" "1" "$?"

_out=$(WDROID_TEST_CONTAINER_ACTIVE=1 WDROID_TEST_SYSTEMCTL_SHOW_FAIL=1 _run_cli status)
assert_eq "status não aborta se systemctl show falha" "0" "$?"
assert_contains "status mostra tempo indisponível" "tempo indisponível" "$_out"

_out=$(_run_cli backup restore --help)
assert_contains "backup restore help executável" "wdroid backup" "$_out"

_out=$(_run_cli backup list --help)
assert_contains "backup list help executável" "wdroid backup" "$_out"

_out=$(_run_cli backup clean --help)
assert_contains "backup clean help executável" "wdroid backup" "$_out"

_run_cli backup create extra &>/dev/null
assert_eq "backup create rejeita argumento extra" "1" "$?"

_run_cli backup restore a b &>/dev/null
assert_eq "backup restore rejeita argumento extra" "1" "$?"

_run_cli backup list extra &>/dev/null
assert_eq "backup list rejeita argumento extra" "1" "$?"

_run_cli backup clean 1 2 &>/dev/null
assert_eq "backup clean rejeita argumento extra" "1" "$?"

_out=$(_run_cli reset --help)
assert_contains "reset help executável" "wdroid reset" "$_out"

_run_cli reset --opcao-invalida &>/dev/null
assert_eq "reset inválido retorna erro sem prompt" "1" "$?"

_out=$(_run_cli start --help)
assert_contains "start help executável" "wdroid start" "$_out"

_run_cli start --opcao-invalida &>/dev/null
assert_eq "start inválido retorna erro sem iniciar" "1" "$?"

_out=$(_run_cli stop --help)
assert_contains "stop help executável" "wdroid stop" "$_out"

_run_cli stop --opcao-invalida &>/dev/null
assert_eq "stop inválido retorna erro sem parar" "1" "$?"

_out=$(_run_cli restart --help)
assert_contains "restart help executável" "wdroid restart" "$_out"

_run_cli restart --opcao-invalida &>/dev/null
assert_eq "restart inválido retorna erro sem reiniciar" "1" "$?"

_out=$(_run_cli fix --help)
assert_contains "fix help executável" "wdroid fix" "$_out"

_run_cli fix --opcao-invalida &>/dev/null
assert_eq "fix inválido retorna erro sem corrigir" "1" "$?"

_run_cli autostart --opcao-invalida &>/dev/null
assert_eq "autostart rejeita argumento extra" "1" "$?"

_run_cli no-autostart --opcao-invalida &>/dev/null
assert_eq "no-autostart rejeita argumento extra" "1" "$?"

_out=$(_run_cli install --help)
assert_contains "install help executável" "wdroid install" "$_out"

_run_cli install --opcao-invalida &>/dev/null
assert_eq "install inválido retorna erro sem instalar" "1" "$?"

mkdir -p "$_CLI_TMP/tmp"
_INSTALL_TRACE="$_CLI_TMP/install.trace"
_out=$(WDROID_TEST_TRACE="$_INSTALL_TRACE" WDROID_TEST_TMPDIR="$_CLI_TMP/tmp" _run_cli install --no-init)
assert_contains "install --no-init conclui com mocks" "Instalação concluída" "$_out"
_repo_script=$(sed -n 's/^curl-out://p' "$_INSTALL_TRACE" | head -1)
assert_not_eq "install registra script temporário" "" "$_repo_script"
assert_file_absent "install remove script temporário no sucesso" "$_repo_script"

_INSTALL_FAIL_TRACE="$_CLI_TMP/install-fail.trace"
_out=$(WDROID_TEST_TRACE="$_INSTALL_FAIL_TRACE" WDROID_TEST_CURL_FAIL=1 WDROID_TEST_TMPDIR="$_CLI_TMP/tmp" _run_cli install --no-init 2>&1)
assert_not_eq "install falha se repo não baixa" "0" "$?"
_repo_script=$(sed -n 's/^curl-out://p' "$_INSTALL_FAIL_TRACE" | head -1)
assert_not_eq "install falho registra script temporário" "" "$_repo_script"
assert_file_absent "install remove script temporário após falha" "$_repo_script"

mkdir -p "$_CLI_TMP/backups/1" "$_CLI_TMP/backups/2"
_run_cli backup clean 1 &>/dev/null
assert_eq "backup clean executável não aborta sob set -e" "0" "$?"

_run_cli backup clean invalido &>/dev/null
assert_eq "backup clean rejeita retenção inválida" "1" "$?"

rm -rf "$_CLI_TMP/backups"
_run_cli backup clean 1 &>/dev/null
assert_eq "backup clean sem diretório não aborta" "0" "$?"

_out=$(_run_cli doctor)
assert_contains "doctor executável calcula health score" "Health score" "$_out"

_out=$(_run_cli doctor --help)
assert_contains "doctor help executável" "wdroid doctor" "$_out"

_run_cli doctor --opcao-invalida &>/dev/null
assert_eq "doctor inválido retorna erro" "1" "$?"

_out=$(_run_cli plugin help)
assert_contains "plugin help executável" "wdroid plugin" "$_out"

_out=$(_run_cli plugin list --help)
assert_contains "plugin list help executável" "wdroid plugin" "$_out"

_run_cli plugin list extra &>/dev/null
assert_eq "plugin list rejeita argumento extra" "1" "$?"

_run_cli plugin help extra &>/dev/null
assert_eq "plugin help rejeita argumento extra" "1" "$?"

_run_cli plugin install plugin.sh extra &>/dev/null
assert_eq "plugin install rejeita argumento extra" "1" "$?"

_run_cli plugin remove whatsapp extra &>/dev/null
assert_eq "plugin remove rejeita argumento extra" "1" "$?"

_run_cli plugin acao-invalida &>/dev/null
assert_eq "plugin inválido retorna erro" "1" "$?"

_out=$(_run_cli logs help)
assert_contains "logs help executável" "wdroid logs" "$_out"

_out=$(_run_cli logs container 3)
assert_contains "logs container usa journalctl" "journal:-u waydroid-container --no-pager -n 3" "$_out"

_out=$(WDROID_TEST_JOURNAL_FAIL=1 _run_cli logs container 3)
assert_eq "logs container não aborta se journalctl falha" "0" "$?"
assert_contains "logs container avisa falha journalctl" "Não foi possível ler logs" "$_out"

_run_cli logs modo-invalido &>/dev/null
assert_eq "logs inválido retorna erro" "1" "$?"

_run_cli logs container abc &>/dev/null
assert_eq "logs rejeita linhas inválidas" "1" "$?"

sleep 30 &
_LOCK_PID=$!
printf "%s\n" "$_LOCK_PID" > "$_CLI_TMP/wdroid.lock"

_run_cli plugin list &>/dev/null
assert_eq "plugin list usa lock leve" "0" "$?"

_run_cli backup list &>/dev/null
assert_eq "backup list usa lock leve" "0" "$?"

_run_cli playstore status &>/dev/null
assert_eq "playstore status usa lock leve" "0" "$?"

_run_cli micloud status &>/dev/null
assert_eq "micloud status usa lock leve" "0" "$?"

_run_cli apps &>/dev/null
assert_eq "apps usa lock leve" "0" "$?"

_run_cli backup clean 1 &>/dev/null
assert_eq "backup clean respeita lock exclusivo" "1" "$?"

kill "$_LOCK_PID" 2>/dev/null || true
wait "$_LOCK_PID" 2>/dev/null || true
rm -f "$_CLI_TMP/wdroid.lock"

_run_cli comando-inexistente &>/dev/null
assert_eq "comando desconhecido retorna erro" "1" "$?"

rm -rf "$_CLI_TMP" 2>/dev/null || true
