# wdroid v2

CLI profissional para gerenciar WhatsApp via Waydroid no Debian.
Arquitetura modular com state machine, retry, logging estruturado e sistema de plugins.

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
│   └── backup.sh           # backup e restauração seguros
├── commands/
│   ├── start.sh            # inicialização com state machine
│   ├── stop.sh             # encerramento limpo com state machine
│   ├── status.sh           # status completo do sistema
│   ├── doctor.sh           # diagnóstico com health score e --fix
│   ├── reset.sh            # reset seguro com backup automático
│   └── logs.sh             # logs: container, wdroid, all, follow
├── plugins/
│   └── whatsapp.sh         # plugin de automação do WhatsApp
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
git clone https://github.com/seu-usuario/wdroid
cd wdroid
make install
```

Para instalar também o Waydroid:

```bash
wdroid install
```

---

## Uso rápido

```bash
wdroid start              # inicia tudo e abre WhatsApp
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
| `wdroid start` | Inicia container + sessão + WhatsApp |
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

### Backup
| Comando | Descrição |
|---|---|
| `wdroid backup create` | Cria backup completo |
| `wdroid backup restore` | Restaura backup (interativo) |
| `wdroid backup list` | Lista backups disponíveis |
| `wdroid backup clean [N]` | Mantém N backups (padrão: 3) |

### Plugins
| Comando | Descrição |
|---|---|
| `wdroid plugin list` | Lista plugins instalados |
| `wdroid plugin run <nome>` | Executa plugin |
| `wdroid plugin install <f>` | Instala plugin externo |
| `wdroid plugin remove <nome>` | Remove plugin |

---

## State machine

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
make test         # validação de sintaxe
make clean        # remove temporários
```

---

## Changelog

### v2.0.0
- State machine real (STOPPED → APP_RUNNING)
- Retry com backoff em todas as operações críticas
- Logging estruturado com arquivo de log diário
- Lockfile com detecção de processo órfão
- `doctor --fix` com health score
- Backup seguro com parada automática do container
- Reset com backup obrigatório antes de apagar
- Sistema de plugins dinâmico
- `make lint` e `make test`
- Módulos carregados on-demand
