# Uso

## Start

```bash
wdroid start
```

## Stop

```bash
wdroid stop
```

## Doctor

```bash
wdroid doctor --fix
```

## Instalação

```bash
wdroid install
wdroid install --gapps
wdroid install --vanilla
wdroid install --no-init
```

Use `--gapps` quando quiser Play Store/GMS desde a inicialização do Waydroid.
Use `--no-init` quando quiser apenas instalar dependências e inicializar depois.

## Play Store

```bash
wdroid playstore init
wdroid start
wdroid playstore status
wdroid playstore certify --open
```

Se o Waydroid já foi inicializado como VANILLA/FOSS, crie backup antes e use:

```bash
wdroid backup create
wdroid playstore init --force
```

## Xiaomi Cloud

```bash
wdroid micloud status
wdroid micloud install XiaomiAccount.apk XiaomiCloud.apk
wdroid micloud open
```

Para componentes Xiaomi que precisam funcionar como app de sistema:

```bash
wdroid micloud install-system XiaomiCloud.apk MiCloudBackup.apk
```

Sem APKs Xiaomi locais, use o acesso web:

```bash
wdroid micloud web
```

## Plugins

```bash
wdroid plugin list
wdroid plugin install meu-plugin.sh
wdroid plugin run meu-plugin help
```

Plugins oficiais ficam no diretório de instalação do wdroid. Plugins instalados
pelo usuário ficam em `~/.wdroid/plugins`.

Plugins oficiais:

```bash
wdroid plugin run whatsapp open
wdroid plugin run whatsapp send "mensagem"
wdroid plugin run tiktok install ~/Downloads/tiktok-lite.apk
wdroid plugin run tiktok download "https://exemplo.local/tiktok-lite.apk"
```

O plugin do TikTok Lite não baixa APK de uma fonte fixa embutida. Ele procura
um APK local ou baixa somente uma URL informada explicitamente.

## Variáveis Úteis

```bash
WDROID_HOME="$HOME/.wdroid"
WDROID_BACKUP_DIR="$WDROID_HOME/backups"
WDROID_LOG_DIR="$WDROID_HOME/logs"
WDROID_APK_DIR="$WDROID_HOME/apks"
WDROID_PLUGIN_DIR="$WDROID_HOME/plugins"
WAYDROID_DATA_DIR="/var/lib/waydroid"
WDROID_APP_PACKAGE="com.whatsapp"
WDROID_RETRY_MAX="5"
WDROID_RETRY_DELAY="1"
WDROID_CONTAINER_TIMEOUT="10"
WDROID_SESSION_TIMEOUT="15"
WDROID_LOCK_FILE="/tmp/wdroid.lock"
WDROID_STATE_FILE="/tmp/wdroid.state"
```

Backups criados pelo `wdroid backup create` contêm `waydroid/` no nível raiz.
`wdroid backup restore` rejeita diretórios que não tenham essa estrutura antes
de substituir os dados atuais.

## Concorrência

Operações que alteram o ambiente usam lock exclusivo. Consultas como `status`,
`logs`, `doctor`, `apps`, `plugin list`, `backup list`, `playstore status` e
`micloud status` podem rodar durante outra execução e mostram aviso quando há
uma instância ativa.
