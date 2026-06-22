# Segurança e Artefatos

Este repositório deve conter somente código, testes e documentação.

Não comite:

- chaves privadas ou públicas de acesso;
- APKs, XAPKs, APKS ou arquivos `.idsig`;
- backups, dumps, bancos locais ou logs;
- arquivos `.env` com credenciais.

Use diretórios locais fora do git, como:

```bash
~/.wdroid/apks/
~/.wdroid/backups/
~/.wdroid/logs/
~/.wdroid/plugins/
```

Plugins são código shell e rodam no mesmo contexto do usuário. Instale somente
plugins confiáveis. O `wdroid plugin install` aceita apenas arquivos `.sh` com
função `plugin_main` e nome simples, sem caminhos.

APKs proprietários, como componentes Xiaomi, Google ou apps de terceiros, devem
ser fornecidos pelo usuário e ficar fora do repositório. Comandos de download
aceitam apenas fontes informadas explicitamente pelo usuário.

Se uma chave privada já foi versionada, considere-a comprometida: remova do
repositório, rotacione a chave e, se o projeto for publicado, limpe o histórico
antes de enviar novamente.
