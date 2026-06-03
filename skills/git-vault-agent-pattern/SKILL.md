---
name: git-vault-agent-pattern
description: Arquitetura de agente Hermes Utility — dedicado exclusivamente a git versionamento de vault Obsidian. Memory desligado, sem criação de conteudo, apenas pull/commit/push sob autorizacao.
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Git-Vault Agent {{GIT_OPS}} (Utility Agent)

## O que e

Utility Agent — agente Hermes que executa uma unica funcao operacional: git versionamento de vault Obsidian. Nao cria conteudo, nao tem memoria longa, nao toma decisoes de dominio.

## Quando usar

- Multi-agente editando mesmo repositorio — serializar commits, evitar conflitos
- Repositorio compartilhado entre maquina local (humano) e servidor (agentes Hermes)
- Fluxo com safety gate: pushes requerem autorizacao do orquestrador

## Arquitetura

Duas instancias da mesma persona:
- CLI local (MacBook): cria/edita notas + git pull/push (autorizado pelo humano)
- Agente servidor (Hermes): SO git pull/commit/push (autorizado pelo orquestrador)
- Ambas compartilham mesma base de personalidade (arquivos SOUL.md na raiz do vault)

### Principios

1. Memory disabled — `memory_enabled: false`, `user_profile_enabled: false`. Cada comando e auto-contido.
2. Authorization gate — push requer autorizacao explicita, **exceto quando {{COMMANDER}} autoriza push automatico** (ex: {{GIT_OPS}}-mac e {{GIT_OPS}}-OVH autorizados em 28/05/2026). Nesse caso, o cron de auto-backup faz push sem intervencao.
3. Zero content creation — NUNCA edita notas, PRDs ou conteudo. So git.
4. CWD fixo — `terminal.cwd` aponta para o repositorio alvo.

## Configuracao Essencial (config.yaml)

```yaml
model:
  provider: opencode-go
  default: deepseek-v4-pro

slack:
  bot_user_name: pattern
  require_mention: true
  allow_mentions: true

terminal:
  backend: local
  cwd: {{COMMANDER_HOME}}/projects/obsidian

memory:
  memory_enabled: false
  user_profile_enabled: false

gateway:
  mode: proxy
```

### Escopos Slack (7)

`app_mentions:read`, `channels:history`, `channels:read`, `chat:write`, `groups:history`, `groups:read`, `users:read`

Eventos: `app_mention`, `message.groups`

## Fluxo de Operacao

### Commit
1. Agente: `<{{GIT_OPS_MENTION}}> commit: descricao`
2. {{GIT_OPS}}: `git pull --rebase` -> `git diff --stat` -> reporta
3. Orquestrador autoriza: commit autorizado
4. {{GIT_OPS}}: `git add -A` -> `git commit -m` -> `git push`
5. Reporta hash

### Sincronizacao
1. Humano: `<{{GIT_OPS_MENTION}}> sincroniza`
2. {{GIT_OPS}}: `git pull` -> reporta diff

### Conflito
ABORTA -> escala para orquestrador com diff do conflito

## Regras Absolutas
- NUNCA `git push --force`
- NUNCA resolver conflitos automaticamente
- SEMPRE `git pull --rebase` antes
- SEMPRE registrar em log
- **Push automatico** so quando autorizado explicitamente por {{COMMANDER}} (ex: autorizacao de 28/05/2026 para {{GIT_OPS}}s). Senao, requer autorizacao do orquestrador.

## Deploy

### 1. Criar App Slack (manual — ~10min)

Seguir `SLACK_BOT_SETUP.md`:
- api.slack.com/apps → Create App → Name: `{{GIT_OPS}}`
- **Socket Mode** ON → gera `SLACK_APP_TOKEN` (xapp-...)
- **OAuth & Permissions** → 7 escopos padrão → Install → gera `SLACK_BOT_TOKEN` (xoxb-...)
- **Event Subscriptions** → `app_mention`, `message.groups`
- `/invite @{{GIT_OPS}}` nos canais alvo

### 2. Preencher .env

```bash
nano ~/.hermes/profiles/pattern/.env
```

**⚠️ CRÍTICO: incluir o próprio {{GIT_OPS}} no SLACK_ALLOWED_USERS.**
Se o {{GIT_OPS}} não estiver na sua própria allowlist, ele rejeita menções como não autorizadas e nunca responde.

```
OPENCODE_GO_API_KEY=sk-...
SLACK_BOT_TOKEN=xoxb-...
SLACK_APP_TOKEN=xapp-...
SLACK_HOME_CHANNEL=C0B3PS16NKS
SLACK_REQUIRE_MENTION=true
SLACK_ALLOWED_USERS=U09HU87HZ0D,{{SLACK_ID_OVH_ORCHESTRATOR}},{{SLACK_ID_OVH_BACKEND}},{{SLACK_ID_OVH_FRONTEND}},{{SLACK_ID_OVH_PRODUCT}},{{SLACK_ID_OVH_DEVOPS}},<PATTERN_USER_ID>
```

### 3. Instalar systemd (user service)

```bash
hermes --profile pattern gateway install
chown -R {{COMMANDER}}:{{COMMANDER}} ~/.hermes/profiles/pattern/sessions
```

**Comando correto:** `hermes --profile pattern gateway install` (NÃO `gateway service install` — esse subcomando não existe).

O systemd unit fica em:
```
~/.config/systemd/user/hermes-gateway-pattern.service
```

Com `Linger` ativado automaticamente (sobrevive a logout SSH).

### 4. Iniciar

```bash
systemctl --user start hermes-gateway-pattern
systemctl --user status hermes-gateway-pattern
```

### ⚠️ REGRA ABSOLUTA — NUNCA PREEMPTAR O PATTERN

**{{ORCHESTRATOR}} e outros agentes NUNCA devem executar operações no vault Obsidian manualmente.**

Mesmo que o {{GIT_OPS}} demore a responder ou pareça offline:
- **NÃO** crie, mova, copie ou remova arquivos no vault por conta própria
- **NÃO** use terminal para manipular o vault
- **NÃO** reverta operações para "corrigir" o estado — pode causar perda de dados não versionados

**Faça isto:** Escale para {{COMMANDER}} ("{{GIT_OPS}} está lento, Comandante. Aguardo instruções.")

**Razão:** O vault tem arquivos untracked (não versionados no git) que são perdidos permanentemente se removidos. {{ORCHESTRATOR}} uma vez perdeu dois diretórios ao tentar reverter uma operação manual — só foram recuperados via git porque parte do conteúdo estava versionada.

### Diagnóstico — {{GIT_OPS}} não responde?

Se o systemd mostra `active (running)` mas o {{GIT_OPS}} não responde no Slack:

| Causa | Verificar | Correção |
|---|---|---|
| `SLACK_ALLOWED_USERS` sem o {{GIT_OPS}} | `grep ALLOWED_USERS .env` | Adicionar `<@{{SLACK_ID_GITOPS}}>` à lista |
| Token inválido | Logs: `journalctl --user -u hermes-gateway-pattern` | Recriar app Slack |
| Bot não está no canal | `/invite @{{GIT_OPS}}` não foi executado | `/invite @{{GIT_OPS}}` no canal |
| Duas linhas ALLOWED_USERS | `grep -c ALLOWED_USERS .env` | Deixar só uma linha com todos os IDs |

**Se o diagnóstico não resolver rápido — NÃO tente fazer o trabalho do {{GIT_OPS}} manualmente.** Reporte ao {{COMMANDER}} e aguarde.

**⚠️ Sinal vermelho: NÃO peça ao usuário para verificar tokens se ele já afirmou que estão corretos.** O terminal mascara tokens como `***` por segurança. Confie na palavra do Comandante.

## Terminal Pitfalls

### Exit Code 130 (SIGINT) — Terminal Instável

Sintoma: comandos no terminal retornam `exit_code: 130` repetidamente, mesmo comandos simples como `echo "test"`.

Causa: processos background zumbis (com `&` no comando) ou estado corrompido da sessão shell do Hermes.

Workaround: usar `execute_code` (Python) com `subprocess.run()` em vez de chamadas diretas ao terminal:

```python
from hermes_tools import terminal
import subprocess, time

# Se terminal() retorna 130, use subprocess diretamente
result = subprocess.run(
    ["systemctl", "--user", "status", "hermes-gateway-pattern"],
    capture_output=True, text=True, timeout=10
)
print(result.stdout)
```

Prevenção: NÃO usar `&` (background) em comandos do terminal. Se precisar matar processos, usar PIDs específicos em vez de `pgrep -f` que pode auto-matching.

{{GIT_OPS}} CLI (MacBook): Carregado por arquivos de personalidade na raiz do vault. Cria/edita notas E git. Push autorizado pelo humano.
{{GIT_OPS}} Hermes (Servidor): So git. Push autorizado por {{ORCHESTRATOR}} ou humano.

A regra de commit difere por instancia — no servidor a autorizacao pode vir do orquestrador.
