# Arquitetura

O wdroid segue uma arquitetura modular:

- core: lógica base
- modules: funcionalidades isoladas
- commands: interface CLI
- plugins: extensões

## State Machine

STOPPED → CONTAINER_ONLY → SESSION_RUNNING → APP_RUNNING
