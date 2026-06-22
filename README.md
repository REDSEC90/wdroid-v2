# wdroid v2

CLI modular para controlar e automatizar ambientes Android/Waydroid no Linux.

O projeto combina controle de ciclo de vida, máquina de estados, retentativas, logs estruturados, diagnósticos, backups e sistema de plugins. Também inclui automações específicas, como integração com WhatsApp, mas a base do projeto é um runtime reutilizável para ambientes Android no Linux.

---

## Arquitetura

```
wdroid/
├── bin/
│   └── wdroid              # entrypoint principal
├── core/
│   ├── config.sh           # configurações e variáveis globais
│   ├── logger.sh           # logging estruturado com cores e arquivo
│   ├── lock.sh             # lockfile anti-concorrência
│   ├── utils.sh            # run seguro, retry, wait_for, validações
│   ├── state.sh            # state machine (STOPPED → APP_RUNNING)
│   └── plugin.sh           # sistema de plugins dinâmico
├── modules/
│   ├── container.sh        # controle do container Android
│   ├── session.sh          # controle da sessão Android
│   ├── network.sh          # diagnóstico e correção de rede
│   ├── app.sh              # apps, ADB, screenshot, send-text
│   ├── backup.sh           # backup e restauração seguros
│   └── services.sh         # Play Store/GMS e Xiaomi Cloud
├── commands/
│   ├── start.sh            # ciclo de vida
│   ├── status.sh           # status e diagnóstico
│   ├── app.sh              # apps, ADB e sessão gráfica
│   ├── services.sh         # Play Store e Xiaomi Cloud
│   ├── backup.sh           # roteamento de backup
│   └── help.sh             # ajuda principal
├── plugins/
│   ├── whatsapp.sh         # plugin de automação do WhatsApp
│   └── tiktok.sh           # plugin de automação do TikTok Lite
└── Makefile
```

---

## Requisitos

- Debian 11+ (Bullseye ou Bookworm)
- Sessão **Wayland** ativa
- KVM habilitado (recomendado)
- `curl`, `iptables`, `adb` (opcional para automação)

---

## Instalação

```bash
git clone https://github.com/REDSEC90/wdroid-v2.git
cd wdroid-v2
make install
```

O código instalado fica em `~/.local/share/wdroid`; dados do usuário ficam em
`~/.wdroid` (`apks`, `backups`, `logs` e plugins instalados).

Para instalar também o Waydroid:

```bash
wdroid install
wdroid install --gapps
wdroid install --vanilla
wdroid install --no-init
```

---

## Uso rápido

```bash
wdroid start              # inicia o ambiente e abre o app padrão
wdroid stop               # encerra sessão e container
wdroid restart            # para e reinicia
wdroid status             # status completo
wdroid doctor             # diagnóstico do sistema
wdroid doctor --fix       # diagnóstico + correção automática
wdroid fix                # corrige problemas comuns
```

---

## Referência de comandos

### Ciclo de vida
| Comando | Descrição |
|---|---|
| `wdroid start` | Inicia container, sessão e app padrão |
| `wdroid stop` | Encerra sessão e container |
| `wdroid restart` | Para e inicia novamente |

### Observabilidade
| Comando | Descrição |
|---|---|
| `wdroid status` | Status completo do sistema |
| `wdroid doctor` | Diagnóstico com health score |
| `wdroid doctor --fix` | Diagnóstico + auto-correção |
| `wdroid logs` | Logs do container (50 linhas) |
| `wdroid logs wdroid` | Logs internos do wdroid |
| `wdroid logs all` | Container + wdroid juntos |
| `wdroid logs follow` | Segue logs em tempo real |

### Apps e ADB
| Comando | Descrição |
|---|---|
| `wdroid launch [pacote]` | Abre app (padrão: WhatsApp) |
| `wdroid install-apk <f>` | Instala APK |
| `wdroid apps` | Lista apps instalados |
| `wdroid adb` | Conecta ADB ao Waydroid |
| `wdroid send-text <msg>` | Envia texto via ADB |
| `wdroid screenshot [f]` | Captura tela do Android |
| `wdroid multi-window` | Ativa modo multi-janela |

### Serviços Android
| Comando | Descrição |
|---|---|
| `wdroid playstore init` | Inicializa Waydroid com imagem GAPPS |
| `wdroid playstore init --force` | Reinicializa imagens com GAPPS (faça backup antes) |
| `wdroid playstore status` | Verifica Play Store, Play Services e Android ID |
| `wdroid playstore certify [--open]` | Mostra o Android ID e o link oficial de certificação Google |
| `wdroid playstore open` | Abre a Play Store |
| `wdroid micloud status` | Verifica Xiaomi Account/Xiaomi Cloud/Mi Cloud Backup |
| `wdroid micloud install <apk...>` | Instala APKs Xiaomi locais como apps comuns |
| `wdroid micloud install-system <apk...>` | Instala APKs Xiaomi locais como system-app via overlayfs |
| `wdroid micloud open` | Abre Xiaomi Cloud app ou i.mi.com |
| `wdroid micloud web` | Abre i.mi.com no Android |

> Play Store depende da imagem GAPPS do Waydroid. Xiaomi Cloud depende de APKs proprietários fornecidos pelo usuário ou do acesso web em `https://i.mi.com/`; o projeto não redistribui binários Google/Xiaomi.

Guarde APKs locais fora do repositório, por exemplo em `~/.wdroid/apks/`.

`wdroid install` aceita `--gapps`, `--vanilla` e `--no-init` para instalação
não interativa.

### Backup
| Comando | Descrição |
|---|---|
| `wdroid backup create` | Cria backup completo |
| `wdroid backup restore` | Restaura backup (interativo) |
| `wdroid backup list` | Lista backups disponíveis |
| `wdroid backup clean [N]` | Mantém N backups (padrão: 3) |

Backups válidos contêm um diretório `waydroid/` no nível raiz do backup.
A restauração valida essa estrutura antes de parar/remover a instalação atual.

### Plugins
| Comando | Descrição |
|---|---|
| `wdroid plugin list` | Lista plugins instalados |
| `wdroid plugin run <nome>` | Executa plugin |
| `wdroid plugin install <f>` | Instala plugin externo |
| `wdroid plugin remove <nome>` | Remove plugin |

Plugins oficiais incluídos:

```bash
wdroid plugin run whatsapp open
wdroid plugin run whatsapp send "mensagem"
wdroid plugin run tiktok install ~/Downloads/tiktok-lite.apk
wdroid plugin run tiktok download "https://exemplo.local/tiktok-lite.apk"
```

O plugin do TikTok não usa URL fixa de APK. Ele procura um APK local ou baixa
apenas de uma URL informada explicitamente pelo usuário.

---

## Máquina de estados

O wdroid rastreia o estado do ambiente em 4 níveis:

```
STOPPED → CONTAINER_ONLY → SESSION_RUNNING → APP_RUNNING
```

O comando `start` avança pelo estado atual sem reiniciar o que já está ativo.
O comando `stop` encerra na ordem inversa.

---

## Configuração

Variáveis de ambiente opcionais:

```bash
export WDROID_BACKUP_DIR="$HOME/meus-backups"
export WDROID_LOG_DIR="$HOME/.logs/wdroid"
export WDROID_APK_DIR="$HOME/.wdroid/apks"
export WDROID_PLUGIN_DIR="$HOME/.wdroid/plugins"
export WAYDROID_DATA_DIR="/var/lib/waydroid"
export WDROID_APP_PACKAGE="com.whatsapp"
export WDROID_RETRY_MAX="5"
export WDROID_CONTAINER_TIMEOUT="10"
export WDROID_SESSION_TIMEOUT="15"
export WDROID_LOCK_FILE="/tmp/wdroid.lock"
export WDROID_STATE_FILE="/tmp/wdroid.state"
```

Ou edite diretamente `core/config.sh`.

---

## Plugins

Para criar um plugin, crie um arquivo em `plugins/` com a função `plugin_main`:

```bash
#!/bin/bash
# DESCRIPTION: Descrição do meu plugin

plugin_main() {
    case "${1:-help}" in
        minha-acao) echo "fazendo algo..." ;;
        *) echo "Uso: wdroid plugin run meu-plugin minha-acao" ;;
    esac
}
```

Instale com:

```bash
wdroid plugin install meu-plugin.sh
```

Plugins instalados pelo usuário são salvos em `~/.wdroid/plugins`; plugins
oficiais continuam em `plugins/` dentro da instalação do wdroid.

---

## Problemas comuns

| Sintoma | Solução |
|---|---|
| WhatsApp não abre | `wdroid fix` ou `wdroid doctor --fix` |
| Sem internet no container | `wdroid fix` |
| Container travado | `wdroid restart` |
| Tela corrompida (GPU dupla) | Defina GPU explícita no driver |
| KVM inativo | `modprobe kvm_intel` (ou `kvm_amd`) |
| Conflito de instâncias | Verifique `/tmp/wdroid.lock` |

---

## Integrações desktop

```bash
make desktop      # cria atalho .desktop no menu do sistema
make autostart    # configura início automático ao logar
make no-autostart # remove início automático
```

---

## Desenvolvimento

```bash
make lint         # shellcheck em todos os scripts
make test         # suíte completa em tests/run_tests.sh
make clean        # remove temporários
```

---

## Changelog

### v2.0.0
- Máquina de estados real (STOPPED → APP_RUNNING)
- Retry com backoff em todas as operações críticas
- Logging estruturado com arquivo de log diário
- Lockfile com detecção de processo órfão
- `doctor --fix` com health score
- Backup seguro com parada automática do container
- Reset com backup obrigatório antes de apagar
- Sistema de plugins dinâmico
- `make lint` e `make test`
- Módulos carregados on-demand
