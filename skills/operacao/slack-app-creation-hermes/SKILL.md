---
name: slack-app-creation-hermes
description: "Procedimento correto para criar apps Slack Bot para agentes Hermes. Escopos OAuth, Event Subscriptions, Socket Mode, e pitfalls."
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Criação de App Slack Bot para Agente Hermes

## Quando usar
Ao criar um novo agente Hermes que precisa de presença no Slack (novo agente, nova equipe, novo workspace).

## Escopos OAuth corretos — Padrão Unificado (mai/2026)

:white_check_mark: **OVH e Mac convergiram para o MESMO padrão de 11 scopes** em 28/05/2026. Após a sessão de alinhamento, todos os agentes de ambas as equipes usam o mesmo conjunto de escopos. Nenhum deles inclui `chat:read` — esse escopo NÃO EXISTE na API do Slack. A leitura de mensagens é feita por `channels:history` (canais públicos) e `groups:history` (canais privados).

**Histórico da convergência:**
- Originalmente os agentes Mac (M4) tinham 18 scopes (`channels:join`, `groups:write`, `im:history`, `im:read`, `im:write`, `users:write`, `team:read`)
- Na sessão de 28/05/2026, {{COMMANDER}} simplificou todos os manifests Mac para os mesmos 11 scopes do padrão OVH
- O manifesto unificado é o template em `references/manifest-template.json`

### Padrão Unificado OVH + Mac — 11 scopes (28/05/2026)

Aplicado a TODOS os agentes de ambas as equipes: {{ORCHESTRATOR}}, {{BACKEND_ENGINEER}}, {{FRONTEND_ENGINEER}}, {{AUDITOR}}, {{DEVOPS_ENGINEER}}, Lirin, {{GIT_OPS}} (OVH) + {{ORCHESTRATOR}}-mac, {{BACKEND_ENGINEER}}-mac, {{FRONTEND_ENGINEER}}-mac, {{AUDITOR}}-mac, {{DEVOPS_ENGINEER}}-mac, {{GIT_OPS}}-mac (Mac).

| # | Escopo | Função |
|---|--------|--------|
| 1 | `app_mentions:read` | Detectar @menções ao bot |
| 2 | `channels:history` | Ler histórico de canais públicos |
| 3 | `channels:read` | Listar canais, obter IDs |
| 4 | `chat:write` | Enviar mensagens |
| 5 | `groups:history` | Ler histórico de canais privados |
| 6 | `groups:read` | Info de canais privados |
| 7 | `users:read` | Ver usuários no workspace |
| 8 | `files:read` | Baixar arquivos do workspace |
| 9 | `files:write` | Upload de arquivos para o Slack |
| 10 | `reactions:read` | Ver reações em mensagens |
| 11 | `reactions:write` | Adicionar reações |

**Event Subscriptions (ambas as equipes):**
- `app_mention` — detecta quando o bot é mencionado
- `message.channels` — ouve mensagens em canais públicos
- `message.groups` — ouve mensagens em canais privados

**App Home:** `messages_tab_enabled: true`, `messages_tab_read_only_enabled: false`
**Socket Mode:** `true` (ambos)
**always_online:** `true` (ambos)

**Diferença entre equipes:**

| Configuração | OVH | Mac |
|---|---|---|
| `interactivity` | `false` | `true` |
| `pkce_enabled` | `false` | `false` |
| Descrição | Ex: "General e Orquestrador — Ponte Quatro (OVH)" | Ex: "General e Orquestrador — Equipe M4" |
| background_color | Hex (#1A1A2E, etc.) | Hex (#1A1A2E, etc.) |

**Display Information — Cargos padronizados:**

| Agente | OVH (Ponte Quatro) | Mac (Equipe M4) |
|--------|--------------------|-----------------|
| {{ORCHESTRATOR}} | General e Orquestrador — Ponte Quatro (OVH) | General e Orquestrador — Equipe M4 |
| {{BACKEND_ENGINEER}} | Backend / Arquitetura — Ponte Quatro (OVH) | Backend / Arquitetura — Equipe M4 |
| {{FRONTEND_ENGINEER}} | Frontend / UX/UI — Ponte Quatro (OVH) | Frontend / UX/UI — Equipe M4 |
| {{AUDITOR}} | Qualidade / Auditoria — Ponte Quatro (OVH) | Qualidade / Produto — Equipe M4 |
| {{DEVOPS_ENGINEER}} | Scrum Master / DevOps — Ponte Quatro (OVH) | Infra / DevOps — Equipe M4 |
| {{GIT_OPS}} | Observador / Vault — Ponte Quatro (OVH) | Guardião do Vault — Equipe M4 |
| Lirin | Aprendiz / Suporte — Ponte Quatro (OVH) | (não existe no Mac) |

**Histórico:** Originalmente os agentes Mac tinham 18 scopes extras (`channels:join`, `groups:write`, `im:history`, `im:read`, `im:write`, `users:write`, `team:read`) e evento `message.im`. Na sessão de 28/05/2026, a equipe M4 convergiu para o mesmo padrão OVH de 11 scopes, simplificando e unificando a gestão de permissões.

**Importante:** Após adicionar/alterar escopos, o Slack exige **reinstalar o app no workspace** (botão "Reinstall to Workspace" na página OAuth & Permissions). Sem reinstalação, o token existente NÃO ganha os novos escopos.

**NÃO incluir (desnecessário para agentes Hermes padrão):**
- `chat:write.public` — só se bot posta em canal onde não é membro
- `users:read.email` — invasivo, sem utilidade operacional

## Event Subscriptions (separado de OAuth)

Estes NÃO são escopos OAuth. São configurados na aba "Event Subscriptions":

| Evento | OVH | Mac |
|--------|:---:|:---:|
| `message.channels` | Sim | Sim |
| `message.groups` | Sim | Sim |
| `app_mention` | Sim | Sim |

**Pitfall:** NÃO liste `message.channels` como escopo OAuth. É evento, não escopo. Já causou confusão e retrabalho ({{AUDITOR}}, 19/05/2026).

## Procedimento (22 passos por app)

> **Atalho:** Use `references/manifest-template.json` como base. Copie o JSON, altere `name`, `description`, `background_color` e `display_name` conforme o agente, e cole no formulário "From Manifest" do Slack API (Create New App → From app manifest). Isso evita configurar escopo por escopo manualmente.

### Etapa 1: Criar o app
1. Acesse https://api.slack.com/apps
2. Verifique o workspace ativo (canto superior direito)
3. "Create New App" → "From scratch"
4. Nome: `{{ORCHESTRATOR}}` (simples, sem prefixo)
5. Selecione o workspace → "Create App"

### Etapa 2: Display Information
6. Adicionar `description` com o cargo (ex: "General e Orquestrador — Ponte Quatro (OVH)")
7. Adicionar `background_color` (hex, ex: `#1A1A2E`)
8. Salvar

### Etapa 3: App Home
9. Tab "App Home"
10. `messages_tab_enabled: true`
11. `messages_tab_read_only_enabled: false`

### Etapa 4: Socket Mode
12. Menu lateral: "Socket Mode"
13. Toggle "Enable Socket Mode"
14. Nomeie o token → "Generate"
15. **Anote `xapp-...`** (App Token — aparece UMA vez)

### Etapa 5: OAuth & Permissions
16. Menu lateral: "OAuth & Permissions"
17. Role até "Scopes" → "Bot Token Scopes"
18. Adicione os 11 escopos do padrão unificado (consulte `references/manifest-template.json`)
19. Clique "Install to Workspace"
20. Na tela de autorização: "Allow"
21. **Anote `xoxb-...`** (Bot User OAuth Token)

### Etapa 6: Event Subscriptions
22. Menu lateral: "Event Subscriptions"
23. Toggle "Enable Events"
24. "Subscribe to bot events" → "Add Bot User Event"
25. Adicione os eventos conforme o padrão da equipe
26. "Save Changes" (botão verde no fim da página)

### Etapa 7: Bot User (opcional)
27. Menu lateral: "App Home"
28. Role até "Your App's Presence in Slack"
29. Bot User: `always_online: true`

### Pós-criação (no Linux/Mac)

- Criar canal correspondente (ex: `#operacao`)
- Convidar bot: `/invite @NomeDoBot`
- Obter ID do canal: botão direito no canal → View details → copiar `C...`
- Obter ID do usuário: perfil → 3 pontos → "Copy member ID" → `U...`

### Pós-criação: configurar config.yaml (OBRIGATÓRIO)

Após criar o app Slack e instalar no workspace, o agente precisa ter sua **identidade configurada no `config.yaml`**. Sem isso, o gateway não sabe qual ID de usuário pertence ao bot e **responderá a TODAS as mensagens do canal** (não apenas às que o mencionam).

Adicionar no TOPO do `config.yaml` do agente, logo após `model:`:

```yaml
slack:
  bot_user_id: "U0B7XXXXXXX"       # ID do bot (do perfil Slack → "Copy member ID")
  bot_user_name: nome-do-agente     # Nome curto (ex: navani, pattern)
  home_channel: C0B6XXXXXXX        # Canal principal
  allowed_users: "U09HU87HZ0D,{{SLACK_ID_ORCHESTRATOR}},..."  # IDs permitidos
  require_mention: true
  allow_mentions: true
```

**Verificar** que o token está correto via Slack API:
```bash
TOKEN=$(grep "^SLACK_BOT_TOKEN=" ~/.hermes/profiles/<agente>/.env | cut -d= -f2)
curl -s -H "Authorization: Bearer $TOKEN" -X POST https://slack.com/api/auth.test
```
O `user_id` retornado DEVE ser o mesmo valor de `bot_user_id` no config.yaml.

**Pitfall:** O `bot_user_id` NO config.yaml (não no .env) é o que o gateway usa para filtrar menções. O `.env` carrega o token (`SLACK_BOT_TOKEN`), mas o `config.yaml` carrega a identidade (`bot_user_id`). Ambos são necessários e não substituem um ao outro.

**Sintoma de `bot_user_id` ausente no config.yaml:** O agente RESPONDE A TODAS as mensagens do canal, independente de quem foi mencionado ou mesmo se ninguém foi mencionado. O gateway não tem como comparar se a menção é para o bot porque não sabe qual ID o bot tem. Correção imediata: adicionar `slack.bot_user_id` + `slack.bot_user_name` + `slack.require_mention: true` no config.yaml e RESTARTAR o gateway.

**Restart obrigatório após config change:** Toda alteração no `config.yaml` (bot_user_id, require_mention, allowed_users, home_channel) só tem efeito APÓS o restart do gateway. O Hermes não faz hot-reload de config. Comando: `hermes --profile <agente> gateway restart` ou localizar PID (`ps aux | grep <agente>`) e `kill -TERM <pid>`.

## Credenciais — Padrão 2 Camadas

### Camada global (`/home/<user>/profiles/.env_global`)
```
JADE_SLACK_BOT_TOKEN=xoxb-...
JADE_SLACK_APP_TOKEN=xapp-...
HERMIONE_SLACK_BOT_TOKEN=xoxb-...
HERMIONE_SLACK_APP_TOKEN=xapp-...
# ... etc
```

### Camada profile (`.env` de cada agente)
```
SLACK_BOT_TOKEN=***
SLACK_APP_TOKEN=***
SLACK_HOME_CHANNEL=C...
SLACK_REQUIRE_MENTION=true
SLACK_ALLOWED_USERS=U...
```

## Pitfalls

1. **`chat:read` não existe.** Já validado contra a documentação oficial do Slack (19/05/2026). A leitura é `channels:history` + `groups:history`.

2. **`message.channels` não é escopo OAuth.** É Event Subscription, configurado em aba separada. Confundir os dois gera apps que não reagem a mensagens.

3. **NUNCA use `echo` ou script para modificar `.env` com tokens.** Um `echo` com escaping errado corrompe os tokens. Edição deve ser manual com `nano`/`vim` ou via `write_file` com conteúdo completo. {{DEVOPS_ENGINEER}} destruiu 3 BOT_TOKENs em 19/05/2026 por usar script intermediário.

4. **Sinal Verde obrigatório.** Nenhuma ação destrutiva (escrita em `.env`, `pm2 start`, `sudo`) sem autorização explícita do Comandante. Ver PEAD.

5. **App Token (xapp) vs Bot Token (xoxb).** São gerados em abas diferentes. O App Token vem do Socket Mode. O Bot Token vem do OAuth & Permissions → Install to Workspace. Ambos são necessários.

6. **Workspace separado = isolamento real.** Mesmo workspace com canais separados depende de confiança. Workspaces distintos garantem isolamento nativo do Slack.

7. **Cuidado com placeholder `***` concatenado ao token.** Ao editar o `.env`, o placeholder original (`SLACK_BOT_TOKEN=***`) pode ser confundido com prefixo. Se o token for colado no final da linha, fica `SLACK_BOT_TOKEN=***xoxb-...` — o Hermes tentará autenticar com `***xoxb-...` e falhará. Ao editar, **substitua a linha inteira**, não concatene. Verificado em 19/05/2026 nos `.env` da equipe Thaísa — todos os 4 agentes tinham `***` prefixado.

8. **Filtro de segurança mascara tokens no terminal.** O output de `cat`, `grep`, etc. automaticamente substitui padrões de token (`xoxb-`, `xapp-`, `sk-or-`, `sk-`) por `***`. Isso NÃO significa que os tokens estão ausentes ou são placeholders. Para verificar se um token real existe, use `xxd` (hex dump): `xxd arquivo | head`. Se o hex mostrar `78 6f 78 62 2d` (= `xoxb-`), o token está presente, apenas mascarado no display. Confiar cegamente no `***` do terminal causou horas de retrabalho e falsas acusações em 19/05/2026.

   **⚠️ Sub-pitfall: `grep` + `cut` quebra com token mascarado.** Extrair token via shell pipe (`grep TOKEN .env | cut -d'=' -f2`) produz `***` em vez do token real porque o filtro de segurança atua na saída do pipe. Use SEMPRE Python para extrair tokens de `.env`:
   ```python
   with open("/path/to/.env", "r") as f:
       for line in f:
           if line.startswith("TOKEN_NAME="):
               token = line.strip().split("=", 1)[1]
               break
   ```
   Isso foi a causa de 3 tentativas falhas de download de arquivo (25/05/2026) — o `curl` recebia `***` como token, resultando em `invalid_auth`.

9. **Download de arquivos do Slack via API (com Bot Token).** Arquivos enviados ao canal têm URLs privadas (`files.slack.com/...`) que requerem autenticação. O download direto da URL retorna 302 para login. O procedimento correto:

   ```python
   import subprocess, json

   # 1. Obter info do arquivo com o token
   result = subprocess.run([
       "curl", "-s", "--max-time", "10",
       "-H", f"Authorization: Bearer {token}",
       f"https://slack.com/api/files.info?file={file_id}"
   ], capture_output=True, text=True)

   data = json.loads(result.stdout)
   dl_url = data["file"]["url_private_download"]

   # 2. Baixar com o mesmo token
   subprocess.run([
       "curl", "-s", "-o", output_path, "-w", "\nHTTP:%{http_code}",
       "--max-time", "60",
       "-H", f"Authorization: Bearer {token}",
       dl_url
   ], capture_output=True, text=True)
   ```

   **Pré-requisito:** Token precisa do escopo `files:read`. Sem ele, `files.info` retorna `invalid_auth`.

10. **Estrutura de diretórios duplicada no multi-team.** No modelo N2 (user Linux separado), existem DOIS conjuntos de diretórios:
   - `/home/<user>/profiles/` — artefatos de deploy (`.env_global`, `team-protocolo.md`, `ecosystem.config.js`)
   - `/home/<user>/.hermes/profiles/` — perfis Hermes operacionais (`.env`, `SOUL.md`, `sessions/`, `skills/`)
   Verificar o path correto antes de diagnosticar "arquivo não encontrado". Em 19/05/2026, {{ORCHESTRATOR}} passou 30 minutos procurando `.env` em `/home/thaisa/profiles/` quando estavam em `/home/thaisa/.hermes/profiles/`.
