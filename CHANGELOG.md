# Changelog

## [2.0.0] - 2026-06-18

### Added

- State machine para `STOPPED`, `CONTAINER_ONLY`, `SESSION_RUNNING` e `APP_RUNNING`.
- Sistema de plugins.
- Backup e restauração.
- Diagnóstico com health score.
- Comandos para Play Store/GMS e Xiaomi Cloud.
- Opções não interativas para `wdroid install`.

### Fixed

- Resolução de symlink do entrypoint.
- Compatibilidade com saída tabulada de `waydroid status`.
- Fallback não interativo para `waydroid shell` quando root é exigido.
- Validação de backup antes de restaurar dados do Waydroid.
- Diagnóstico sem execução dinâmica via `eval`.
- Remoção de `eval` do helper de espera (`wait_for`).
- Validação de nomes, extensão e entrypoint na instalação/execução de plugins.

### Changed

- Separação entre código instalado e dados do usuário.
- CLI principal reduzida a bootstrap, lock e roteamento.
- Artefatos Android e chaves removidos da raiz do projeto.
- Plugin TikTok exige APK local ou URL explícita, sem fonte fixa embutida.
- Restauração de backup passa por diretório temporário antes da troca final.
- `wdroid install` aceita `--gapps`, `--vanilla` e `--no-init`.
- Lock exclusivo agora usa criação atômica e diretórios configuráveis.
