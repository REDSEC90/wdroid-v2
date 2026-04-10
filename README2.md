# wdroid 🧩

wdroid nasceu como uma solução prática para um problema simples:

> usar WhatsApp no Debian via Waydroid sem dor, sem repetição e sem configuração manual.

Mas durante o desenvolvimento, ficou claro que o problema não era só o WhatsApp.

Era **o próprio processo repetitivo, frágil e limitado de gerenciar ambientes Android no Linux**.

---

## 🚀 Evolução do projeto

O que começou como automação específica evoluiu para algo maior:

> **wdroid se tornou um runtime modular para controlar e automatizar ambientes Android via CLI.**

Hoje, o foco não é mais apenas um app —  
é dar controle total do ambiente para qualquer finalidade.

---

## ⚡ O que o wdroid resolve

- Elimina comandos repetitivos no Waydroid  
- Automatiza setup e execução de apps  
- Padroniza ambientes Android no Linux  
- Permite criar fluxos reutilizáveis  

---

## 🧠 Filosofia

O core do wdroid é simples, previsível e estável.

A complexidade e o poder vêm de fora:

> 🔌 **plugins**

---

## 🔌 Sistema de Plugins

O verdadeiro poder do wdroid está na sua extensibilidade.

Você pode:

- Criar automações para qualquer app Android
- Integrar com APIs, bots ou scripts
- Construir fluxos completos de automação
- Expandir o sistema sem alterar o core

---

## 📱 Casos de uso

Embora tenha começado com WhatsApp, o wdroid pode ser usado para:

### Automação de apps
- WhatsApp (uso original)
- Outros apps Android
- Bots e workflows

### Testes
- Ambientes reproduzíveis
- QA mobile

### Scripts personalizados
- Automação de tarefas
- Integração com sistemas externos

### Laboratório
- Experimentação com Android no Linux
- Ambientes isolados

---

## 🧩 Liberdade total

wdroid não impõe como você deve usar.

Você pode:

- usar como ferramenta simples
- automatizar tudo
- criar seus próprios plugins
- adaptar para qualquer cenário

> O limite é o que você decidir construir.

---

## ⚙️ Estrutura

```bash
core/       # lógica principal
commands/   # interface CLI
modules/    # funcionalidades
plugins/    # extensões
