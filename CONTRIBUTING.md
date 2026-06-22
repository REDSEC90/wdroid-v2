# Contribuindo

## Setup

```bash
make install
make test
```

## Fluxo de Trabalho

1. Mantenha mudanças pequenas e focadas.
2. Rode `make test` antes de enviar alterações.
3. Não adicione APKs, chaves, backups, logs ou artefatos gerados ao repositório.
4. Coloque comandos de topo em `commands/` e lógica reutilizável em `modules/`.
5. Use `waydroid_shell` para comandos dentro do Android.

## Testes

```bash
bash tests/run_tests.sh
```

`make lint` usa `shellcheck` quando disponível no sistema.
