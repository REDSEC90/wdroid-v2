# Visao Geral

O wdroid nasceu como uma automacao para usar WhatsApp no Debian via Waydroid e
evoluiu para uma CLI modular para controlar ambientes Android no Linux.

## Objetivo

- reduzir comandos repetitivos do Waydroid;
- padronizar inicializacao, diagnostico e correcao;
- instalar e abrir apps Android;
- permitir automacoes por plugins;
- manter backups, logs e artefatos fora do codigo-fonte.

## Modelo

O core deve ser pequeno e previsivel. Funcionalidades reutilizaveis ficam em
`modules/`, comandos de topo ficam em `commands/` e extensoes ficam em
`plugins/` ou em `~/.wdroid/plugins`.

## Casos de Uso

- automacao de apps Android;
- laboratorio Android no Linux;
- QA mobile simples;
- fluxos personalizados via shell.
