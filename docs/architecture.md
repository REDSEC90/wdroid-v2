# Arquitetura

O wdroid segue uma arquitetura modular:

- `bin/wdroid`: entrypoint, roteamento de comandos e carregamento on-demand.
- `core/`: configuração, logs, lock, helpers, state machine e plugins.
- `modules/`: operações reutilizáveis sobre Waydroid, Android, rede, apps, backup e serviços.
- `commands/`: comandos de alto nível da CLI.
- `plugins/`: extensões oficiais acionadas por `wdroid plugin run <nome>`.

## Regras de Estrutura

- Comandos novos devem entrar em `commands/*.sh` quando forem ações de topo da CLI.
- `bin/wdroid` deve permanecer como bootstrap, lock e roteador.
- Funcionalidades reutilizáveis devem entrar em `modules/*.sh`.
- Chamadas a `waydroid shell` devem usar `waydroid_shell` de `core/utils.sh`.
- APKs, chaves, backups e artefatos baixados ficam fora do repositório.
- Plugins oficiais ficam em `plugins/`; scripts soltos na raiz devem ser evitados.
- Plugins instalados pelo usuário ficam em `~/.wdroid/plugins`.
- Nomes de plugins devem ser simples (`A-Z`, `a-z`, `0-9`, `_`, `-`, `.`) e
  não podem conter caminhos.

## Instalação Local

`make install` separa código e dados:

- código: `~/.local/share/wdroid`
- dados do usuário: `~/.wdroid`
- plugins do usuário: `~/.wdroid/plugins`

`make uninstall` remove o código instalado e preserva dados do usuário.

Lock e estado usam `/tmp/wdroid.lock` e `/tmp/wdroid.state` por padrão, mas
podem ser isolados com `WDROID_LOCK_FILE` e `WDROID_STATE_FILE`.

O diretório de dados do Waydroid também pode ser isolado com
`WAYDROID_DATA_DIR`, útil para testes e ambientes não padrão.

## Backup

`modules/backup.sh` cria backups contendo o diretório `waydroid/` e valida esse
payload antes de restaurar. A restauração prepara uma cópia temporária antes de
trocar os dados atuais, reduzindo o risco de apagar uma instalação válida por
causa de um backup incompleto.

## Lock

Comandos que alteram o ambiente usam lock exclusivo. Comandos de leitura, como
`status`, `logs`, `doctor`, `apps`, `plugin list`, `backup list` e status/help
dos serviços Android usam lock leve: eles avisam se outra instância estiver em
execução, mas não bloqueiam a consulta.

O lock exclusivo cria o arquivo com escrita atômica e remove o lock apenas se o
PID armazenado ainda for o processo atual.

## State Machine

STOPPED → CONTAINER_ONLY → SESSION_RUNNING → APP_RUNNING

## Serviços Android

`modules/services.sh` concentra Play Store/GMS e Xiaomi Cloud:

- `wdroid playstore init|status|certify|open`
- `wdroid micloud status|install|install-system|open|web`

APKs proprietários são fornecidos pelo usuário. O projeto só instala arquivos locais
ou abre o acesso web quando o app Android não estiver disponível.
