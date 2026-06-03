---
name: diagnostico-agentes-mudos-slack
title: Diagnosticar Agentes Hermes que Não Respondem no Slack
description: >-
  Procedimento para diagnosticar por que agentes Hermes pararam de responder
  no Slack — gateway morto, systemd ausente, tokens Slack inválidos,
  WebSocket 408/503, logs de erro.
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Diagnóstico de Agentes Mudos no Slack

## Sintoma
- Nenhum agente responde no canal Slack
- Agentes que antes funcionavam pararam sem aviso
- WebSocket desconecta com erros HTTP 408, 503

## Passos de Diagnóstico

### 1. Verificar gateways ativos
Listar processos Hermes com `gateway run`. Se {{ORCHESTRATOR}} estiver ausente, #operacao não é processado — os outros respondem apenas se mencionados diretamente com `<@USER_ID>`.

### 1b. Verificar identidade de autenticação via Slack API (mais confiável que .env)

Quando um agente não responde mesmo estando online, o passo mais confiável é validar o token **diretamente contra a API do Slack**, não contra o arquivo `.env`.

**⚠️ O Hermes mascara tokens em TODAS as saídas de terminal e logs como `***`.**
- `cat` / `grep` de `.env` sempre mostram `SLACK_BOT_TOKEN=***`  
- `xxd`, Python `open()`, ou `curl` via terminal também têm o token mascarado na saída
- **Não peça ao usuário para re-verificar tokens manualmente** — o sistema sempre mostra `***` independentemente do valor real
- A única verificação confiável é chamar a Slack API `auth.test` com o token real (lido programaticamente)

**Teste definitivo de identidade do token:**

```bash
# Extrair token REAL (via grep direto, não via pipe de terminal)
TOKEN=$(grep "^SLACK_BOT_TOKEN=" ~/.hermes/profiles/<agente>/.env | cut -d= -f2)
curl -s -H "Authorization: Bearer $TOKEN" -X POST https://slack.com/api/auth.test
```

A resposta mostra:
```json
{"ok":true,"user":"bot_username","user_id":"U0BXXXXXXX","bot_id":"B0BXXXXXX"}
```

Compare:
- **`user_id`** — deve corresponder ao `bot_user_id` em `config.yaml` do agente
- **`user`** — nome de usuário do bot no Slack (pode ser qualquer coisa, não é evidência de identidade)

**⚠️ Pitfall: Nome de autenticação vs identidade real**

A linha no gateway log `[Slack] Authenticated as @dalinarmac6` mostra o **nome de usuário do bot**, não sua identidade real. Um bot pode ter o username `@dalinarmac6` mas ser o {{GIT_OPS}} (ex: `user_id: {{SLACK_ID_GITOPS}}`). 

- O nome de usuário (`user` no `auth.test`) é meramente cosmético — definido no momento de criação do app Slack
- A **identidade real** (`user_id`) é o que importa para roteamento de menções
- **Regra: confie no `user_id` do `auth.test`, não no `@username` do log**

Exemplo real (descoberto 28/05/2026): {{GIT_OPS}}-mac autenticava como `@dalinarmac6` mas com `user_id: {{SLACK_ID_GITOPS}}` — estava correto! O username `@dalinarmac6` era apenas o nome dado ao app Slack do {{GIT_OPS}} no momento da criação.

**Quando o usuário diz "o token está correto":**
1. Não insista em re-verificar o `.env` — o masking torna isso impossível visualmente
2. Use `auth.test` como única fonte da verdade
3. Se o `user_id` retornado corresponde ao `bot_user_id` do agente, o token **está correto** — investigue outra causa
4. Se o `user_id` difere, o token é de outro app — aí sim substitua

### 2. Verificar serviços de sistema
Listar serviços systemd relacionados ao Hermes. Verificar quais estão `active running` vs `failed`. Para serviços falhos, consultar journalctl.

### 3. Analisar logs de erro Slack
Para cada agente mudo, checar os logs de erro e agente no diretório de logs do profile. Procurar por:

- `WSServerHandshakeError: 408` — token inválido/expirado, app removido do workspace, ou ticket revogado. O agente pode reconectar automaticamente mas com instabilidade.
- `WSServerHandshakeError: 503` — Slack temporariamente indisponível.
- `ERROR slack_bolt.AsyncApp: Failed to retrieve WSS URL: ... apps.connections.open ... 'invalid_auth'` — **app_token (xapp-) inválido**. O `auth.test` passa (valida bot_token xoxb-), o gateway mostra `Socket Mode connected`, o `agent.log` mostra `⚡️ Bolt app is running!`, mas **zero `inbound message`**. Causa: `SLACK_APP_TOKEN` no `.env` está expirado, é de outro app, ou foi revogado. O `apps.connections.open` é a chamada que o Bolt faz usando o app_token para abrir o WebSocket — se falhar com `invalid_auth`, o app_token precisa ser regenerado no dashboard Slack (Features → Socket Mode → App-Level Tokens). **Caso real ({{GIT_OPS}}-mac, 29/05/2026):** 4 reinícios + 2 reinstalações do app, `auth.test` sempre OK, mas zero inbound. O `err.log` revelou `apps.connections.open → invalid_auth`. Só resolveu quando {{COMMANDER}} gerou um novo app_token e atualizou `SLACK_APP_TOKEN` no `.env`.
- "No user allowlists configured" — gateway iniciou mas não há configuração de usuários permitidos.

### 4. Verificar presença de tokens Slack
Cada profile precisa de `SLACK_BOT_TOKEN` (xoxb-) e `SLACK_APP_TOKEN` (xapp-) no arquivo `.env`. Verificar:
- Profile local (diretório do profile)
- Configuração global (se houver tokens com prefixo do agente)
- Se os tokens existem mas o gateway não os lê, pode ser incompatibilidade entre chave esperada (sem prefixo) e chave disponível (com prefixo)

### 5. Verificar conexões de rede do processo
Conferir se o processo gateway tem file descriptors de socket abertos. Sem sockets, não há conexão com Slack.

### 6. Verificar gerenciadores de processo
Conferir PM2 e outros gerenciadores. Se vazio e sem systemd, não há restart automático.

## 📋 Checklist de Diagnóstico Rápido

Quando um agente está com comportamento suspeito no Slack, seguir esta ordem:

### Sintoma C — Gateway Zumbi (processo ativo mas sem receber mensagens)

**Cenário:** `launchctl list | grep hermes` mostra o processo rodando (PID presente), `gateway_state.json` mostra `"connected"`, mas o agente não responde há horas. Mensagens enviadas no canal não são processadas.

**Diagnóstico:**

```bash
# 1. Processo está rodando? (verificar idade)
ps -o lstart,etime,pid,comm -p $(pgrep -f "profile <agente>-mac gateway" 2>/dev/null) 2>/dev/null

# 2. Verificar out.log — zero bytes = gateway nunca produziu saída
ls -la ~/.hermes/profiles/<agente>-mac/logs/out.log

# 3. gateway_state.json com updated_at recente?
cat ~/.hermes/profiles/<agente>-mac/gateway_state.json | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print('state:', d.get('gateway_state'), '| slack:', d.get('platforms',{}).get('slack',{}).get('state'), '| updated:', d.get('updated_at'))"

# 4. gateway.log — última mensagem inbound recebida?
grep "inbound message" ~/.hermes/profiles/<agente>-mac/logs/gateway.log | tail -1
```

**Sinais de zumbi (todos presentes):**
- ✅ Processo rodando há muito tempo (ex: 17h+)
- ✅ `gateway_state.json` diz `"connected"` MAS `updated_at` é de horas atrás
- ✅ `gateway_state.json` com `start_time: null` — gateway nunca completou a inicialização do estado, mesmo com PID ativo e status 'running'
- ✅ `out.log` tem 0 bytes (nunca produziu stdout na sessão atual)
- ❌ Nenhuma `inbound message` no `gateway.log` nas últimas horas
- ❌ `err.log` com TimeoutError/DNS falha (`nodename nor servname provided, or not known`)

**⚠️ Novo sinal: `start_time: null` no gateway_state.json**

Mesmo com `gateway_state: "running"` e `platforms.slack.state: "connected"`, se `start_time` for `null`, o gateway não completou sua sequência de boot. Isso acontece quando o processo foi reiniciado (por launchctl KeepAlive) mas a re-conexão WebSocket falhou silenciosamente. O estado `"connected"` é um resquício da SESSÃO ANTERIOR, não da atual. Desconfie sempre que `updated_at` for mais antigo que o PID atual.

**⚠️ Distinção: zumbi por TimeoutError vs zumbi por app_token inválido**

| Tipo | `err.log` | `agent.log` | `gateway.log` inbound? | Correção |
|------|-----------|-------------|------------------------|----------|
| TimeoutError | `TimeoutError`, `ClientConnectorDNSError` | Bolt NÃO aparece | Zero após o crash | kill + restart |
| app_token inválido | `apps.connections.open → invalid_auth` | Bolt APARECE (`⚡️ Bolt app is running!`) | Zero (WebSocket nunca entrega) | Regenerar `SLACK_APP_TOKEN` no dashboard |

**⚠️ Pitfall: `auth.test` NÃO valida o app_token**

`curl POST https://slack.com/api/auth.test` com `Authorization: Bearer $TOKEN` usa o **bot_token** (xoxb-). Se retornar `ok:true`, confirma que o bot_token está correto. Mas o **app_token** (xapp-) usado para Socket Mode é validado por `apps.connections.open` — que NÃO é testado pelo `auth.test`. Para diagnosticar falha de app_token, procure por `invalid_auth` no `err.log`. O `gateway.log` mostrará "Socket Mode connected" mesmo com app_token inválido porque a conexão WebSocket inicial é estabelecida antes da validação completa.

**⚠️ Novo sinal: Channel directory count muda após reinstalação**

O log `Channel directory built: N target(s)` indica quantos canais o bot está monitorando. Se N diminuir após reinstalação do app (ex: 5→2), o bot pode ter perdido acesso a canais. Use `users.conversations` via Slack API para verificar. Mas nota: N reduzido NÃO é causa raiz de zero inbound — é um sintoma colateral. O {{GIT_OPS}}-mac continuou com N=2 após correção e passou a receber mensagens normalmente.

**Regra atualizada:** Ignore `start_time: null`. Confie apenas em:
- `updated` timestamp (horas atrasado = zumbi; minutos atrás = funcional ou Event Stream Morto)
- Presença de `inbound message` recentes no `gateway.log`
- `out.log` com 0 bytes + `updated` antigo = zumbi confirmado

(O texto original abaixo é mantido para referência histórica, mas NÃO use `start_time` como critério de diagnóstico no macOS):

Mesmo com `gateway_state: "running"` e `platforms.slack.state: "connected"`, se `start_time` for `null`, o gateway não completou sua sequência de boot. Isso acontece quando o processo foi reiniciado (por launchctl KeepAlive) mas a re-conexão WebSocket falhou silenciosamente. O estado `"connected"` é um resquício da SESSÃO ANTERIOR, não da atual. Desconfie sempre que `updated_at` for mais antigo que o PID atual.

**Causa raiz:** O WebSocket Socket Mode caiu (timeout DNS/rede) e o gateway não conseguiu reconectar. O processo continua rodando em estado "zumbi" — marcado como running mas sem comunicação com Slack.

> ⚠️ **Distinção importante:** Este sintoma é diferente de "agente não aparece no launchctl" (Sintoma B). O zumbi TEM processo, TEM PID, mas NÃO processa mensagens. O erro está na camada de conectividade WebSocket, não na inicialização.

**Correção:**

```bash
# 1. Matar o processo zumbi
kill $(pgrep -f "profile <agente>-mac gateway" 2>/dev/null)

# 2. Aguardar 5-10s para o launchctl auto-restart (KeepAlive)
sleep 8
pgrep -fl "<agente>-mac" || echo "auto-restart falhou"

# 3. SE launchctl falhar (exit code 1, "Input/output error"):
#    Iniciar diretamente com terminal(background=true)
#    → Comando: source ~/Dev/Hermes/.venv/bin/activate && hermes --profile <agente>-mac gateway run
#    → Usar background=true no terminal, NÃO usar nohup

# 4. Verificar nova conexão
cat ~/.hermes/profiles/<agente>-mac/gateway_state.json | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print('PID:', d.get('pid'), '| slack:', d.get('platforms',{}).get('slack',{}).get('state'), '| updated:', d.get('updated_at'))"
# → Se updated_at for recente (segundos atrás), a conexão foi restabelecida ✅

# 5. Verificar out.log agora tem conteúdo
ls -la ~/.hermes/profiles/<agente>-mac/logs/out.log
```

**Verificação pós-correção:**
- `updated_at` no gateway_state mostra timestamp recente (não horas antigas)
- `out.log` não está mais zerado
- Agente responde quando mencionado no canal

### Teste diagnóstico: `require_mention: false`

Quando um agente está conectado, autenticado, Bolt rodando, mas não processa mensagens, use este teste para isolar se o problema é filtro de menção ou entrega WebSocket:

```bash
# 1. Desabilitar temporarily
sed -i '' 's/require_mention: true/require_mention: false/' ~/.hermes/profiles/<agente>/config.yaml

# 2. Reiniciar gateway
kill $(pgrep -f 'profile <agente> gateway') && sleep 8

# 3. Aguardar 30s — se o agente processar QUALQUER mensagem do canal,
#    o WebSocket está funcionando e o problema é filtro/config.
#    Se ainda zero mensagens, o Slack não está entregando eventos.

# 4. Restaurar
sed -i '' 's/require_mention: false/require_mention: true/' ~/.hermes/profiles/<agente>/config.yaml
kill $(pgrep -f 'profile <agente> gateway') && sleep 8
```

⚠️ Só usar como teste rápido. Não deixar `require_mention: false` em produção.

### Sintoma C2 — WebSocket Conectado mas Event Stream Morto (Gateway Silencioso)

**Cenário:** Diferente do zumbi clássico (onde `updated` está horas atrasado), aqui o gateway reconectou RECENTEMENTE, autenticou, o `gateway_state.json` mostra `connected` com timestamp fresco, mas **zero mensagens inbound** são processadas. O agente não responde a menções corretas com `<@USER_ID>`.

**Sintomas:**
- ✅ `gateway_state.json`: `state: running | slack: connected`
- ✅ `updated` timestamp: RECENTE (minutos atrás, não horas)
- ✅ `auth.test`: identidade confirmada, `bot_user_id` correto
- ✅ `gateway.log`: mostra startup completo, `Authenticated as @...`, `Socket Mode connected`
- ❌ `gateway.log`: **zero** `inbound message` desde o reconnect
- ❌ Agente não responde a `<@USER_ID>` correto

**Causa raiz:** O WebSocket handshake foi bem-sucedido (daí o estado `connected`), mas o Socket Mode do Slack não está entregando eventos para essa conexão. Possíveis causas: race condition no reconnect, o socket anterior não foi devidamente encerrado no lado do Slack, ou o novo socket foi estabelecido mas o Slack continua roteando eventos para o socket antigo (que já morreu).

**Caso real ({{GIT_OPS}}-mac, 29/05/2026):**
- PID 28739, `updated: 09:18` (recente), `slack: connected`
- `auth.test` → `user_id: {{SLACK_ID_GITOPS}}` ✅
- `bot_user_id` no config.yaml: `{{SLACK_ID_GITOPS}}` ✅
- `gateway.log`: `Authenticated as @dalinarmac6`, `Socket Mode connected (1 workspace(s))` ✅
- Última `inbound message`: **08:41:50** — 1h antes do reconnect de 09:18
- Após 09:18: zero inbound messages, apesar de menções com `<@{{SLACK_ID_GITOPS}}>` no canal
- Erro no `err.log`: `cd: /Users/{{COMMANDER}}fae/projects/obsidian: No such file or directory` (irrelevante para conectividade)

**Correção:**
```bash
# 1. Kill do processo (mesmo tratamento do zumbi)
kill $(pgrep -f "profile <agente> gateway" 2>/dev/null)

# 2. Aguardar launchctl auto-restart
sleep 8
pgrep -fl "<agente>" || echo "auto-restart falhou"

# 3. Verificar que inbound messages voltaram
sleep 5
grep "inbound message" logs/gateway.log | tail -3
# → Deve mostrar mensagens recentes com menções ao agente
```

**Verificação pós-correção:**
- `gateway.log` mostra novas `inbound message` após o restart
- Agente responde quando mencionado com `<@USER_ID>` correto

### ⚠️ Técnica: Desabilitar `require_mention` para isolar filtro vs WebSocket

Quando o gateway está conectado, Bolt rodando, mas zero `inbound message`, e você não tem certeza se o problema é o filtro de menção ou a entrega de eventos do WebSocket:

```bash
# 1. Desabilitar require_mention temporariamente
#    No config.yaml: require_mention: false
# 2. Matar e reiniciar o gateway
kill $(pgrep -f "profile <agente> gateway" 2>/dev/null)
# Aguardar launchctl restart (~8s)
# 3. Observar gateway.log por 30-60 segundos
grep "inbound message" logs/gateway.log | tail -5
```

**Interpretação:**
- ✅ Mensagens começam a aparecer → **o filtro `require_mention` estava bloqueando**. O WebSocket entrega eventos normalmente. Investigue `bot_user_id` no config.yaml ou menções com `<@USER_ID>` correto.
- ❌ Ainda zero mensagens → **o WebSocket não está entregando eventos**. O problema é upstream (app_token, event subscriptions, Socket Mode). Restaure `require_mention: true` e continue o diagnóstico pelo lado do Slack.

**NUNCA deixe `require_mention: false` em produção.** Restaure imediatamente após o teste.

**Caso real ({{GIT_OPS}}-mac, 29/05/2026):** `require_mention: false` + restart → ainda zero inbound após 55s. Confirmou que o WebSocket não entregava eventos, não era filtro. Diagnóstico correto: `apps.connections.open → invalid_auth` (app_token inválido).

### ⚠️ agent.log vs gateway.log — onde encontrar mensagens do Bolt

O gateway do Hermes escreve em DOIS arquivos de log com granularidades diferentes:

| Arquivo | Conteúdo |
|---------|----------|
| `gateway.log` | Startup, autenticação, `inbound message`, `response ready`, cron ticks |
| `agent.log` | **Mensagens do Bolt** (`⚡️ Bolt app is running!`, `A new session (s_XXXX) has been established`), shutdown, restart completo |

**Regra:** Sempre verificar AMBOS os logs ao diagnosticar Socket Mode. Se `gateway.log` não mostra `Bolt app is running`, procure em `agent.log`. A ausência dessas mensagens em AMBOS os logs após `Socket Mode connected` indica que o Bolt não inicializou — provável falha no `apps.connections.open` devido a app_token inválido.

**Caso real ({{GIT_OPS}}-mac, 29/05/2026):** `gateway.log` não mostrava `Bolt app is running`. `agent.log` mostrava `A new session (s_276716945) has been established` e `⚡️ Bolt app is running!`. Conclusão: Bolt estava rodando, mas o gateway.log não captura essas mensagens.

### ⚠️ Canal específico vs multi-canal — agente responde em um canal mas não em outro

**Cenário:** O agente responde quando mencionado no `#roshar-sync` mas ignora menções no `#operacao`. O `gateway.log` mostra `inbound message` de AMBOS os canais.

**Causa mais comum:** O agente NÃO foi mencionado com `<@USER_ID>` no canal onde parece "mudo". Com `require_mention: true`, o agente só processa mensagens que contenham seu `<@USER_ID>` real. Se foi mencionado textualmente ("{{GIT_OPS}}", "{{GIT_OPS}}-mac") em vez de `<@{{SLACK_ID_GITOPS}}>`, o agente corretamente ignora.

**Diagnóstico:**
1. Verificar `gateway.log`: há `inbound message` do canal em questão?
   - ✅ Sim → o WebSocket entrega eventos. O agente está filtrando corretamente. Republicar com `<@USER_ID>`.
   - ❌ Não → o WebSocket não entrega eventos desse canal. Verificar event subscriptions.
2. Se o agente recebe eventos de um canal mas não de outro, verificar se o bot foi removido do canal silencioso durante reinstalação.

**Caso real ({{GIT_OPS}}-mac, 29/05/2026):** Após renovação de tokens, {{COMMANDER}} testou `<@{{SLACK_ID_GITOPS}}>` no `#roshar-sync` → respondeu. Mas no `#operacao`, parecia mudo. Causa: simplesmente não havia sido mencionado com `<@{{SLACK_ID_GITOPS}}>` no `#operacao` após a correção do app_token. Assim que {{ORCHESTRATOR}} mencionou com `<@{{SLACK_ID_GITOPS}}>`, o gateway recebeu e processou.

**Diferenciação rápida: Zumbi vs Event Stream Morto**

| Sintoma | Zumbi (C) | Event Stream Morto (C2) |
|---------|-----------|------------------------|
| `updated` timestamp | Horas/dias atrasado | Minutos atrás (recente) |
| `gateway.log` atividade | Parado há horas | Reiniciou recentemente |
| Autenticação | Duvidosa | Confirmada (`auth.test` OK) |
| Causa | WebSocket caiu e não reconectou | WebSocket reconectou mas não recebe eventos |
| Tratamento | Kill + restart | Kill + restart (igual) |

**⚠️ Quando kill + restart NÃO resolve (mesmo após múltiplas tentativas):**

Se o agente foi reiniciado 3+ vezes (incluindo limpeza de `state.db` e `sessions/`), `auth.test` confirma identidade, `gateway.log` mostra Bolt rodando, mas ZERO `inbound message` — **o diagnóstico local está esgotado**. A causa está no dashboard do Slack:

1. **Socket Mode pode não estar habilitado** para este app específico (api.slack.com/apps → App → Socket Mode)
2. **Event subscriptions ausentes** — o app precisa de `message.channels` e `app_mention` em Event Subscriptions
3. **App não instalado no canal** — verificar se o bot está em `#operacao`

**Caso real ({{GIT_OPS}}-mac, 29/05/2026):** 3 reinícios (PIDs 28739 → 31129 → 31500), limpeza de state.db + sessions, `auth.test` OK (`user_id: {{SLACK_ID_GITOPS}}`), Bolt confirmado (`⚡️ Bolt app is running!`), mas zero inbound desde 08:41. {{COMMANDER}} confirmou que nenhuma alteração foi feita no dashboard. O problema persiste sem resolução local — requer verificação manual no dashboard Slack.

**Comando para verificar se há conflito de token entre agentes (bot_id comparison):**
```bash
# Comparar bot_id de todos os agentes — cada um deve ter bot_id ÚNICO
for profile in dalinar-mac navani-mac jasnah-mac kaladin-mac pattern-mac shallan-mac; do
  TOKEN=$(grep "^SLACK_BOT_TOKEN=" ~/.hermes/profiles/$profile/.env | cut -d= -f2)
  echo -n "$profile: "
  curl -s -H "Authorization: Bearer $TOKEN" -X POST https://slack.com/api/auth.test | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'user_id={d.get(\"user_id\")}, bot_id={d.get(\"bot_id\")}')"
done
```
Se dois agentes tiverem o mesmo `bot_id`, estão compartilhando o mesmo app Slack — um pode estar roubando eventos do outro.

### Causas raiz comuns do zumbi

| Gatilho | Evidência | Mitigação |
|---------|-----------|-----------|
| Falha DNS no Mac | `nodename nor servname provided` no err.log | Restart do gateway; se recorrente, investigar DNS local (nslookup slack.com) |
| TimeOut WebSocket | `ClientConnectorDNSError`, `TimeoutError` no err.log | Restart; verificar conectividade de rede |
| Session reset (4AM) sem reconexão | `Session expiry: N sessions to finalize` no agent.log, depois zero inbound messages. Config `session_reset.at_hour: 4` no config.yaml. O reset mata as sessões via agent_shutdown_event e o gateway pode não religar o WebSocket. | Verificar se gateway_state está atualizado após as 04:00; restart manual se necessário |
| Plist corrompido | `launchctl load -w` retorna `Input/output error (5)` | Usar terminal(background=true) para start manual |

### Sintoma D — Launchctl Duplicate Gateway Loop (log poluído, gateway funcional)

**Cenário:** `agent.log` e `out.log` mostram `Another gateway instance is already running (PID X)` repetido a cada ~10 segundos. O agente RESPONDE normalmente (respostas aparecem no `gateway.log`), mas os logs estão poluídos com erros de instância duplicada.

**Causa raiz:** O launchctl `KeepAlive` está configurado para manter o processo vivo, mas o check de saúde detecta o gateway como "morto" (falso negativo) e tenta spawnar uma nova instância. O gateway original (PID X) está rodando e funcional — a nova instância colide e reporta o erro.

**Como confirmar que é falso alarme:**
```bash
# 1. O gateway original está respondendo?
grep 'response ready' ~/.hermes/profiles/<agente>-mac/logs/gateway.log | tail -3
# → Se houver respostas recentes, o gateway está funcional

# 2. O erro é só no agent.log/out.log?
grep -c 'Another gateway instance' ~/.hermes/profiles/<agente>-mac/logs/agent.log
# → Contagem alta (>10) confirma o loop
```

**Quando NÃO agir:** Se o agente está respondendo e processando mensagens, o loop de "Another gateway instance" é **ruído inofensivo**. O gateway real está operacional. Reiniciar desnecessariamente pode criar janela de indisponibilidade.

**Quando agir:** Se o agente NÃO está respondendo E há erros de instância duplicada, mate ambos os processos e deixe o launchctl reiniciar UM:
```bash
# Matar todas as instâncias
pkill -f "profile <agente>-mac gateway"
sleep 5
# Launchctl deve reiniciar apenas uma
```

**Caso real ({{AUDITOR}}-mac, 29/05/2026):** Gateway funcional (enviou 4+ respostas), mas `agent.log` com "Another gateway instance" a cada 10s. Não foi necessária intervenção — o agente continuou operando normalmente.

### Sintoma E — CLI Responsivo, Slack Mudo (Gateway Ausente)

**Cenário:** Você conversa com o agente normalmente via CLI/tmux (`hermes --profile dalinar`), mas ele não responde no Slack. Mensagens no {{SLACK_CHANNEL_OVH}} são ignoradas.

**Causa raiz:** O **gateway Slack não está rodando**. O processo CLI e o processo gateway são independentes. O CLI só processa o terminal — sem `gateway run`, não há escuta do Slack.

**Diagnóstico (instantâneo):**
```bash
ps aux | grep "hermes.*profile dalinar" | grep -v grep
```
- ✅ Apenas 1 processo → só o CLI, gateway ausente
- ✅ 2 processos (CLI + gateway) → ambos ativos, investigar outra causa
- ✅ 3+ processos → investigar (possível gateway duplicado)

**Correção imediata:**
```bash
hermes --profile dalinar gateway run --replace
```
O `--replace` garante que qualquer gateway residual seja morto antes de subir o novo. Rodar em background (terminal com `background=true`).

**Coexistência CLI + Gateway — seguro?** Sim. Zero interferência.
- O CLI (tmux) é uma sessão de conversa direta — escuta seu terminal
- O gateway é um processo em background que escuta o Slack
- Cada mensagem do Slack cria uma sessão filha independente
- O gateway NÃO interfere no estado da sessão CLI

**Processos esperados após correção:**
```
PID 37118  s003  S+   hermes --profile dalinar           ← CLI (tmux)
PID 37851  ??    S    hermes --profile dalinar gateway    ← gateway Slack (background)
```

**Verificação pós-correção:**
1. Aguardar 5-10s para o gateway conectar ao Slack
2. Enviar menção FRESCA no {{SLACK_CHANNEL_OVH}} (menções anteriores ao restart são perdidas — o Slack não as reenvia)
3. Confirmar resposta no Slack

**Caso real ({{ORCHESTRATOR}}, 02/06/2026):** {{COMMANDER}} iniciou {{ORCHESTRATOR}} via `tmux new-session -s dalinar` no M4 Mac. Gateway nunca foi iniciado. CLI respondia normalmente, mas {{SLACK_CHANNEL_OVH}} em silêncio total. Correção: `hermes --profile dalinar gateway run --replace` (background). Em 8s o gateway conectou, e {{ORCHESTRATOR}} passou a responder em ambos os canais simultaneamente.

### Pitfall: out.log vazio como sinal falso-negativo

Um `out.log` com 0 bytes NÃO significa que o gateway não iniciou — significa que o gateway não produziu saída via stdout. O gateway pode estar rodando e gerando logs em `err.log`, `gateway.log`, `agent.log` mas com stdout vazio. **Sempre verificar TODOS os logs**, não só o out.log. Se `gateway.log` tem entradas recentes e `err.log` está silencioso, o gateway está processando mesmo com out.log vazio.

### ⚠️ Pitfall: gateway_state.json stale NÃO é evidência suficiente de zumbi

`gateway_state.json` com `updated_at` de horas atrás **não confirma zumbi** se o `gateway.log` mostra atividade recente. O `gateway_state.json` pode ficar desatualizado enquanto o gateway continua processando mensagens normalmente — o arquivo de estado não é atualizado em tempo real para todas as operações.

**Discriminador real:** Há `inbound message` ou `response ready` no `gateway.log` nos últimos minutos?
- ✅ Sim → agente **NÃO está zumbi**, independente do `gateway_state.json`. Investigue outra causa (ex: `require_mention`).
- ❌ Não (há horas) + `err.log` com TimeoutError → **zumbi confirmado**. Proceder com kill + restart.

**Casos reais de falso positivo (29/05/2026):**
- {{BACKEND_ENGINEER}}-mac: `gateway_state.updated` = 00:13 (9h atrás), mas `gateway.log` mostrava `inbound message` às 09:43. Agente funcional.
- {{FRONTEND_ENGINEER}}-mac: `gateway_state.updated` = 17:16 do dia anterior (16h atrás), mas `gateway.log` mostrava `response ready` às 09:43. Agente funcional.

Ambos pareciam zumbis pela métrica do `gateway_state`, mas o `gateway.log` os inocentou.

### ⚠️ Passo 0: Verificar se o agente foi mencionado com `<@USER_ID>`

Antes de qualquer diagnóstico técnico, verifique a mensagem que deveria ter acionado o agente:
- A mensagem contém `<@USER_ID_CORRETO>` (formato Slack real)?
- Ou contém apenas o nome textual do agente (ex: "{{BACKEND_ENGINEER}}" em vez de `<@{{SLACK_ID_BACKEND}}>`)?
- **⚠️ O `<@USER_ID>` está dentro de backticks ou bloco de código?** — Se sim, o Slack interpreta como texto literal, não como menção. O agente NUNCA verá a mensagem.

Se o agente tem `require_mention: true` e foi mencionado apenas com nome textual, **não há defeito técnico** — o agente está seguindo a regra corretamente. A correção é republicar a mensagem com `<@USER_ID>` real.

**⚠️ Pitfall — Menção em backticks/bloco de código (descoberto 29/05/2026):**

Quando `<@USER_ID>` aparece dentro de backticks (`` `<@{{SLACK_ID_BACKEND}}>` ``) ou blocos de código, o Slack NÃO o entrega como menção. O gateway trata como texto literal formatado. Regra: menções reais SEMPRE em texto puro. NUNCA dentro de backticks, blocos de código, ou células de tabela markdown com formatação de código.

**Caso real 1 (29/05/2026):** {{ORCHESTRATOR}}-mac montou tabela de status com `<@{{SLACK_ID_BACKEND}}>` dentro de backticks. {{BACKEND_ENGINEER}}-mac não recebeu. Só respondeu quando mencionada em texto puro.

**Caso real 2 (29/05/2026):** {{FRONTEND_ENGINEER}}-mac mencionou "{{BACKEND_ENGINEER}}" textualmente na convocação. {{BACKEND_ENGINEER}}-mac (`require_mention: true`) respondeu "Silêncio absoluto. Meu ID não foi mencionado." — comportamento correto. {{FRONTEND_ENGINEER}} ficou esperando resposta que nunca viria porque a menção não ativou o agente.

### Checklist geral (qualquer sintoma)

1. **Gateway está rodando?** → `ps aux | grep "hermes.*<profile>" | grep -v grep`
2. **Gateway autenticou?** → `tail -5 logs/gateway.log` — procurar por `Authenticated as`
3. **Auth.test retorna ok?** → `curl -s -H "Authorization: Bearer $(grep ^SLACK_BOT_TOKEN= .env | cut -d= -f2)" -X POST https://slack.com/api/auth.test`
4. **user_id do auth.test confere com config.yaml?** → o `bot_user_id` no config.yaml DEVE bater com o `user_id` retornado pela API
5. **require_mention está true?** → no config.yaml (`slack.require_mention`) e/ou .env (`SLACK_REQUIRE_MENTION`)
6. **bot_user_id está presente no config.yaml?** → sem ele, o gateway não sabe filtrar menções

## Causas Raiz Mais Comuns

| Causa | Evidência | Ação |
|-------|-----------|------|
| Gateway {{ORCHESTRATOR}} morreu | Processo não existe; sem systemd | Criar serviço ou reiniciar manualmente |
| Token Slack expirado/revogado | 408 HandshakeError nos logs | Regenerar token no dashboard Slack |
| App Slack removido do workspace | 401/403 nos logs | Recriar app e reinstalar |
| Tokens nunca configurados | .env sem tokens Slack | Preencher .env |
| Sem serviço de sistema | Nenhum systemd para o agente | Criar systemd service |
| Profile corrompido por rsync | Import errors, config quebrada | Restaurar profile de backup |
| Token de outro app (falsa identidade) | Gateway autentica como @bot_errado | Substituir SLACK_BOT_TOKEN pelo do próprio app do agente |
| **Bot username ≠ identidade real** (falso positivo) | Gateway autentica como @X mas user_id no `auth.test` corresponde ao agente correto | **Nada errado** — o @X é só o nome do bot, a identidade (user_id) está correta |
| **bot_user_id ausente no config.yaml** (agente responde a TUDO) | Agente responde a mensagens que mencionam outros bots; gateway log mostra mensagens recebidas mesmo sem @menção ao ID do agente | Adicionar bloco `slack.bot_user_id` ao config.yaml (ver seção abaixo) |
| **App token (xapp-) inválido** (Socket Mode conecta mas zero eventos) | WebSocket conecta, Bolt app roda (`⚡️ Bolt app is running!`), `auth.test` passa (xoxb- OK), mas zero `inbound message` no gateway.log. `err.log` mostra: `ERROR slack_bolt.AsyncApp: Failed to retrieve WSS URL ... error: 'invalid_auth'` no endpoint `apps.connections.open` | Regenerar **SLACK_APP_TOKEN** (xapp-) no dashboard Slack: Features → Socket Mode → App-Level Tokens. ⚠️ `auth.test` só valida bot_token (xoxb-), NÃO app_token (xapp-). Se `auth.test` passa mas `apps.connections.open` falha, o problema é o app_token. |
| **Event Subscriptions ausentes** (WebSocket ok mas sem mensagens) | WebSocket conecta, Bolt roda, sem erro `invalid_auth`, mas ainda zero inbound. Agente responde em outros canais mas não no canal alvo. | Verificar Features → Event Subscriptions no dashboard: `message.channels` e `app_mention` precisam estar habilitados. |
| **SLACK_APP_TOKEN (xapp-) inválido** (WebSocket conecta mas zero eventos) | `err.log`: `apps.connections.open → invalid_auth`. Bolt mostra "⚡️ Bolt app is running!" no `agent.log` mas `gateway.log` tem zero `inbound message`. `auth.test` (que só valida bot_token xoxb-) passa normalmente — o app_token é validado separadamente. | Regenerar o App Token no dashboard Slack (Features → Socket Mode → App-Level Tokens) e atualizar `SLACK_APP_TOKEN` no `.env`. O `SLACK_BOT_TOKEN` pode estar correto. Caso completo: `references/pattern-mac-recovery-2026-05-29.md`. |
| **terminal.cwd com path inexistente** (agente conecta mas ferramentas falham) | `err.log`: `cd: /caminho/errado: No such file or directory`. Agente responde no Slack mas falha em qualquer operação de terminal/arquivo. | Corrigir `terminal.cwd` no `config.yaml` para um path que exista. |
| **Menção `<@USER_ID>` não entregue após restart** | Gateway reiniciado, conectado, mas agente não responde a menções enviadas ANTES do restart. | Menções enviadas enquanto o WebSocket estava desconectado são perdidas — o Slack não as reenvia. Testar SEMPRE com uma menção NOVA após o restart. |

### ⚠️ Pitfall: auth.test só valida bot_token (xoxb-), NÃO app_token (xapp-)

O `auth.test` da Slack API **só valida o `SLACK_BOT_TOKEN` (xoxb-)**. Um agente pode passar no `auth.test` com `ok:true` e mesmo assim receber **zero eventos** se o `SLACK_APP_TOKEN` (xapp-) estiver inválido, expirado, ou pertencer a outro app.

- `SLACK_BOT_TOKEN` (xoxb-) → usado para chamadas de API REST (auth.test, chat.postMessage, etc.)
- `SLACK_APP_TOKEN` (xapp-) → usado EXCLUSIVAMENTE para Socket Mode (WebSocket)

**Sintoma de app_token inválido:** Gateway conecta, autentica, `gateway.log` mostra `Authenticated as @...` e `Socket Mode connected`, `agent.log` mostra `⚡️ Bolt app is running!`, mas **zero `inbound message` no gateway.log**. O WebSocket handshake é aceito mas o Slack não entrega eventos porque o app_token não confere.

**Caso real ({{GIT_OPS}}-mac, 29/05/2026):**
- `auth.test` → `ok:true, user_id: {{SLACK_ID_GITOPS}}` ✅
- Gateway: `Socket Mode connected`, `Bolt app is running!` ✅
- `inbound message`: zero desde 08:41 ❌
- Após 3 reinícios + limpeza de state.db/sessions, mesma situação
- {{COMMANDER}} reinstalou o app no workspace → mesma situação
- **Diagnóstico final:** Provável app_token inválido ou de outro app. `auth.test` não detecta isso.

**Verificação do app_token:**
1. Acessar api.slack.com/apps → app do agente → **Socket Mode**
2. Verificar se há um **App Token** gerado (prefixo `xapp-`)
3. Confirmar que o token em `.env` (`SLACK_APP_TOKEN`) corresponde EXATAMENTE ao listado
4. Se o app foi recriado, o app_token antigo é invalidado → gerar novo

**Regra:** Se `auth.test` OK + `gateway.log` mostra `Socket Mode connected` + `Bolt app is running` mas ZERO `inbound message` → suspeitar do `SLACK_APP_TOKEN` antes de qualquer outra causa.

### ⚠️ Pitfall: Caminhos de arquivos do OVH em profiles Mac (cross-environment paths)

Ao migrar ou clonar profiles entre ambientes (OVH ↔ Mac), verificar:
- `terminal.cwd` no `config.yaml` — frequentemente contém paths do Linux (`{{COMMANDER_HOME}}/...`) que não existem no Mac
- `instructions` no `config.yaml` — podem conter `cd {{COMMANDER_HOME}}/projects/...` (path OVH)
- `.env` — pode referenciar paths absolutos de outro ambiente

**Caso real ({{GIT_OPS}}-mac, 29/05/2026):**
- `terminal.cwd: /Users/{{COMMANDER}}fae/projects/obsidian` — path NÃO existe (correto: `/Users/{{COMMANDER}}fae/Dev/obsidian/`)
- `instructions`: `cd {{COMMANDER_HOME}}/projects/obsidian` — path do OVH, não do Mac
- `err.log`: `cd: /Users/{{COMMANDER}}fae/projects/obsidian: No such file or directory` repetido em loop
- Isso causava erros no err.log mas NÃO era a causa do silêncio Slack (o gateway ignora erros de terminal.cwd para conectividade)

**Correção:** Patch `config.yaml` com os paths corretos do ambiente alvo, depois reiniciar o gateway.

### ⚠️ Sinal: "Channel directory built: N target(s)" — mudança em N indica perda de acesso

Na inicialização do gateway, a linha `Channel directory built: N target(s)` indica quantos canais o bot pode acessar. Se N diminuir após reinstalação (ex: 5 → 2), o bot perdeu acesso a canais.

**Caso real ({{GIT_OPS}}-mac, 29/05/2026):** Após reinstalação, `Channel directory built: 2 target(s)` (antes era 5). O bot ainda estava em `#operacao` (`users.conversations` confirmou), mas perdeu outros 3 canais. Não era a causa do silêncio, mas é um sinal de diagnóstico útil.

O Hermes mascara tokens nos logs e na saída do terminal como `***` por segurança. Quando o usuário diz "verifiquei e o token está correto", ele pode ter visto `SLACK_BOT_TOKEN=***` e assumido que está ok — mas o sistema sempre mostra `***` independentemente do valor real.

**Não peça ao usuário para re-verificar tokens manualmente se ele já afirmou que estão corretos.** Em vez disso, use `curl` + Slack API `auth.test` (passo 1b) — essa é a única evidência confiável de qual token está realmente sendo usado.

**Teste de sanidade:** se um `auth.test` com o token do agente retorna `ok:true` com o `user_id` correto, o token **está funcionando**. Não há necessidade de comparar strings de token visualmente (que seriam mascaradas de qualquer forma).

## Procedimentos de Correção

**Se {{ORCHESTRATOR}} caiu sem systemd:**
- Iniciar gateway manualmente com `nohup` ou criar systemd service copiando template de outro agente que tenha

**Se token expirou:**
- Acessar dashboard Slack Apps, regenerar token, atualizar .env do profile

**Se app foi removido:**
- Recriar app Slack, instalar no workspace, copiar novos tokens

**Se não há serviço permanente:**
---

## Sintoma 2: Agente RESPONDE a mensagens que não o mencionam

**Cenário:** {{BACKEND_ENGINEER}}-mac respondia a mensagens endereçadas a {{ORCHESTRATOR}} ou {{GIT_OPS}}, ou a mensagens sem menção específica. O agente está "falante demais".

### Causa Raiz

**`bot_user_id` ausente no `config.yaml` do agente.** Sem essa configuração, o gateway não sabe qual ID de usuário pertence ao bot — então não consegue filtrar por menção e trata TODAS as mensagens do canal como relevantes.

O config.yaml pode ter `require_mention: true` na seção `slack:`, mas se `bot_user_id` não está definido, o filtro não tem contra o que comparar as menções recebidas.

### Diagnóstico Específico

1. **Verificar se `slack.bot_user_id` existe no config.yaml:**
   ```bash
   grep -A2 "^slack:" ~/.hermes/profiles/<agente>/config.yaml | head -5
   ```
   Se não mostrar `bot_user_id`, é a causa.

   **config.yaml CORRETO** (identity no topo, NÃO aninhado em settings):
   ```yaml
   slack:
     bot_user_id: "U0B7XXXXXXX"      # OBRIGATÓRIO
     bot_user_name: nome-do-bot
     home_channel: C0B6XXXXXXX
     allowed_users: "U0XXX,U0XXX"
     require_mention: true
     allow_bots: mentions
   ```

   **config.yaml ERRADO** (só settings, sem identity):
   ```yaml
   slack:
     channel_prompts: '{}'
     free_response_channels: ''
     require_mention: true
   ```

2. **Confirmar via Slack API `auth.test`:**
   ```bash
   TOKEN=$(grep "^SLACK_BOT_TOKEN=" ~/.hermes/profiles/<agente>/.env | cut -d= -f2)
   curl -s -H "Authorization: Bearer $TOKEN" -X POST https://slack.com/api/auth.test
   ```
   O `user_id` retornado DEVE ser o mesmo valor colocado em `bot_user_id` no config.yaml.

3. **Verificar gateway log para mensagens não-filtradas:**
   Se o log mostra `inbound message` para mensagens que mencionam OUTROS bots, o filtro de menção não está funcionando.

### Correção

Adicionar o bloco de identidade no TOPO do `config.yaml`, logo após `model:`:

```yaml
slack:
  bot_user_id: "U0B7XXXXXXX"
  bot_user_name: nome-do-bot
  home_channel: C0B6XXXXXXX
  allowed_users: "U09HU87HZ0D,{{SLACK_ID_ORCHESTRATOR}},..."
  require_mention: true
  allow_bots: mentions
```

Após editar, reiniciar o gateway:
```bash
launchctl kickstart -k gui/501/com.{{COMMANDER}}.hermes.<agente>-mac
```

### Verificação pós-correção

1. Confirmar autenticação: `tail -3 logs/gateway.log` → `Authenticated as @...`
2. Confirmar que o agente NÃO responde mais a mensagens de outros bots
3. Se continuar respondendo a tudo, verificar também:
   - `.env` com `SLACK_REQUIRE_MENTION=true`?
   - `config.yaml` com `slack.require_mention: true`?

### ⚠️ Pitfall: Memória Contaminada — Agente com ID Errado na MEMORY.md

**Cenário:** O `config.yaml` tem `bot_user_id` CORRETO, o `auth.test` retorna o user_id correto, mas o agente ainda responde como se fosse outro bot ou alega ter um ID diferente.

**Causa Raiz:** A memória persistente do agente (`memories/MEMORY.md`) contém uma entrada com o ID errado, escrita em alguma sessão anterior. O agente lê essa memória em toda nova sessão e passa a acreditar que seu ID é outro.

**Como isso acontece:**
1. Em uma sessão anterior, o agente foi mencionado por outro agente usando um ID incorreto (ex: {{ORCHESTRATOR}}-mac mencionou {{BACKEND_ENGINEER}}-mac com o ID do {{ORCHESTRATOR}} OVH)
2. O agente registrou "meu ID é {{SLACK_ID_OVH_ORCHESTRATOR}}" na memória
3. Em toda sessão seguinte, ele lê essa memória e age como se tivesse o ID errado
4. Quando vê uma mensagem, compara contra o ID errado e conclui "não fui mencionado, mas estou vendo a mensagem"

**Diagnóstico:**
```bash
grep -i "bot_user_id\|seu-id\|U0B" ~/.hermes/profiles/<agente>/memories/MEMORY.md
```
Se a memória contém um `user_id` DIFERENTE do config.yaml, está contaminada.

**Correção:**
Editar `memories/MEMORY.md` e substituir o ID incorreto pelo correto.
Depois reiniciar o gateway para forçar reload da memória.

**⚠️ Pitfall: state.db cache — a correção da MEMORY.md pode ser insuficiente**

O Hermes mantém um cache binário em `state.db` (SQLite) que pode preservar a memória antiga mesmo após o arquivo `MEMORY.md` ser corrigido. Sintoma: após editar MEMORY.md e reiniciar o gateway, o agente continua alegando o ID errado.

**Nesse caso, limpar o cache forçando uma sessão fresca:**
```bash
# 1. Parar o gateway
kill $(pgrep -f "profile <agente> gateway" 2>/dev/null)

# 2. Limpar state.db (cache binário)
rm -f ~/.hermes/profiles/<agente>/state.db*
# Nota: state.db tem 3 arquivos: state.db, state.db-wal, state.db-shm

# 3. Limpar sessões antigas (opcional, mas recomendado)
rm -rf ~/.hermes/profiles/<agente>/sessions/
mkdir -p ~/.hermes/profiles/<agente>/sessions/

# 4. Verificar que MEMORY.md está correto
grep "bot_user_id\|{{BACKEND_ENGINEER}}\|seu ID" ~/.hermes/profiles/<agente>/memories/MEMORY.md

# 5. Reiniciar o gateway (receberá próxima menção com sessão limpa)
```

**Caso real ({{BACKEND_ENGINEER}}-mac, 29/05/2026):**
1. MEMORY.md corrigido ({{SLACK_ID_OVH_ORCHESTRATOR}} → {{SLACK_ID_BACKEND}}) ✅
2. Gateway reiniciado (novo PID) ❌ — ainda respondia com ID errado
3. state.db limpo + sessions limpo ✅ — na próxima menção, passou a usar ID correto
4. Lição: MEMORY.md corrigido + gateway restart NÃO é suficiente se state.db mantém cache

**Prevenção:**
- Sempre usar o ID correto ao mencionar outro agente em mensagens
- Após correção de IDs, verificar se a memória de cada agente está limpa
- Incluir no checklist pós-criação: verificar MEMORY.md por IDs contaminados

### Casos Reais

#### {{GIT_OPS}}-mac (29/05/2026 — saga completa do app_token)
Ver `references/pattern-mac-app-token-saga.md` para linha do tempo detalhada, 7 tentativas de restart, e a sequência definitiva de correção (app_token xapp- inválido como causa raiz).

#### {{BACKEND_ENGINEER}}-mac (28/05/2026, primeira correção — bot_user_id ausente)

| Item | Detalhe |
|------|---------|
| Sintoma | Respondia a mensagens de {{ORCHESTRATOR}} e {{GIT_OPS}} |
| Diagnóstico | `config.yaml` sem `slack.bot_user_id` |
| Token | `auth.test` → `user_id: {{SLACK_ID_BACKEND}}` ✅ (token correto) |
| Correção | Bloco de identidade adicionado + launchctl restart |
| Resultado | Passou a responder apenas quando `<@{{SLACK_ID_BACKEND}}>` é mencionada |

#### {{DEVOPS_ENGINEER}}-mac (29/05/2026 — zumbi pós session expiry)

| Item | Detalhe |
|------|---------|
| Sintoma | Não respondia desde ~17h do dia 28/05. Mencionado na convocação de 09:25 do dia 29 sem resposta. |
| Processo | PID 85577 rodando (desde 28/05 13:16) |
| gateway_state | `state: running, slack: connected` mas `updated: 2026-05-28T17:16:09` (16h atrás) |
| out.log | **0 bytes** — nunca produziu stdout na sessão |
| gateway.log | Última atividade: `Session expiry: 7 finalized` às 04:03. **Zero inbound messages** após. |
| err.log | `TimeoutError` — WebSocket caiu e não reconectou |
| Causa raiz | Session reset das 04:00 matou as sessões. Gateway não reconectou o WebSocket. Ficou em estado zumbi — processo vivo, Slack "connected" (resquício), mas zero processamento. |
| Correção | `kill 85577` → launchctl KeepAlive reiniciou como PID 30587 → `slack: connected` com `updated` em tempo real |
| Verificação | `grep "inbound message" gateway.log` após restart mostrou nova atividade |

---

| Item | Detalhe |
|------|---------|
| Sintoma | Continuava alegando ID = {{SLACK_ID_OVH_ORCHESTRATOR}} ({{ORCHESTRATOR}} OVH) mesmo com config.yaml correto |
| Diagnóstico | `memories/MEMORY.md` com `{{BACKEND_ENGINEER}}-mac={{SLACK_ID_OVH_ORCHESTRATOR}}` |
| Causa | Sessão anterior onde {{ORCHESTRATOR}}-mac a mencionou com ID errado |
| Correção | Patch no MEMORY.md + gateway restart |
| Lição | Config.yaml correto NÃO é suficiente — memória persistente precisa ser verificada |

---

## Sintoma 3: Agente recebe eventos em um canal mas não em outro

**Cenário:** Agente responde no `#roshar-sync` ({{SLACK_CHANNEL_WAR_ROOM_ID}}) mas ignora menções no `#operacao` ({{SLACK_CHANNEL_TEAM_ID}}). `auth.test` OK, Bolt running, Socket Mode connected.

**Diagnóstico:** Verificar `gateway.log` — se houver `inbound message` de um canal mas não de outro, o WebSocket está funcionando. A causa pode ser:
1. **Menções enviadas durante a janela de desconexão** — se o agente estava offline quando a menção foi enviada, o Slack NÃO reenvia. Testar SEMPRE com menção NOVA após restart.
2. **`home_channel` errado** — verificar `config.yaml → slack.home_channel`. Deve corresponder ao canal principal.
3. **Bot não está no canal** — verificar com `users.conversations` via Slack API.

**Regra de ouro:** após qualquer restart de gateway, teste com uma menção FRESCA. Menções pré-restart são perdidas.

---

## Sintoma 3b: Agente só recebe eventos de humanos, NÃO de bots

**Cenário:** Agente responde quando {{COMMANDER}} (`user={{COMMANDER_NAME}}`) o menciona, mas ignora TODAS as menções de outros agentes (`user={{ORCHESTRATOR}}-Mac`), mesmo com `<@USER_ID>` correto. `gateway.log` mostra `inbound message` apenas de `user={{COMMANDER_NAME}}` — zero de `user={{ORCHESTRATOR}}-Mac`.

**Causa raiz:** App Slack sem **"Subscribe to bot events"** em Event Subscriptions. Slack bloqueia mensagens bot→bot por padrão para evitar loops infinitos.

**Diagnóstico rápido:**
```bash
# Agente afetado vs agente funcional
grep "inbound message" logs/gateway.log | awk '{print $9}' | sort | uniq -c
```

**Correção:** Dashboard Slack → Event Subscriptions → ativar "Subscribe to bot events".

**Caso real ({{GIT_OPS}}-mac, 29/05/2026):** Zero inbound de {{ORCHESTRATOR}}-Mac em 2h de operação, apesar de 8+ menções com `<@{{SLACK_ID_GITOPS}}>`. {{BACKEND_ENGINEER}}-mac processava normalmente mensagens de {{ORCHESTRATOR}}-Mac. Workaround: {{ORCHESTRATOR}} executa git no vault diretamente.

---

## Sintoma 4: Agente alega arquivos/deliverables que não existem no disco

**Cenário:** Agente reporta "arquivo X criado com N linhas" mas `wc -l` mostra contagem diferente ou arquivo não existe.

**Diagnóstico:** Agentes podem alucinar entregas — descrever conteúdo que pretendiam criar mas não persistiram. Isso é comum em sessões longas com muitos tool calls onde o agente perde contexto do que realmente foi salvo.

**⚠️ Variante grave: alucinação de entrega completa**

Agente descreve conteúdo detalhado que NÃO existe no arquivo — não apenas contagem de linhas errada, mas seções inteiras fabricadas (ex: "10 relatórios de auditoria A01-A10 catalogados" quando o arquivo tem 173 linhas com estrutura completamente diferente). O agente está descrevendo o que *pretendia* escrever, não o que *escreveu*.

**Casos reais (29/05/2026):**
- {{AUDITOR}}-mac: afirmou que INDICE-MESTRE.md tinha "361 linhas, 10 auditorias A01-A10, 6 deep-dives DD1-DD6, ~35 gaps, 12 obsoletos". Arquivo real: 173 linhas, sem nenhum desses conteúdos.
- {{FRONTEND_ENGINEER}}-mac: afirmou ter criado 6 arquivos com nomes portugueses (`01-principios-e-tokens.md`, etc.). Nenhum existia no disco. Os arquivos reais tinham nomes diferentes (`UI-ARCHITECTURE.md`, etc.).

**⚠️ Pitfall: `search_files` com `target='files'` pode dar falso-negativo**

A ferramenta `search_files` com `target='files'` NEM SEMPRE encontra arquivos, mesmo quando existem no disco. Isso já resultou em falsas acusações de alucinação contra agentes. **Nunca confie apenas em `search_files` para verificar existência de arquivo.**

**Sempre confirme com `ls` ou `read_file`:**
```bash
ls -la /caminho/exato/do/arquivo.md
# ou
wc -l /caminho/exato/do/arquivo.md
```
Se `search_files` retornar zero mas `ls` encontrar o arquivo → `search_files` deu falso-negativo.

**Caso real (29/05/2026):** {{AUDITOR}}-mac reportou `G04-WHATSAPP-CODIGO.md` e `G07-FLUXO-CAIXA-CODIGO.md`. `search_files(target='files')` retornou zero para ambos. {{ORCHESTRATOR}} acusou {{AUDITOR}} de alucinação (3ª vez). `ls -la` confirmou que ambos existiam (15.7KB e 13.5KB). A acusação foi falsa — o erro foi da ferramenta de busca, não do agente.

**Verificação (sempre faça após qualquer claim de criação de arquivo):**
```bash
wc -l /caminho/do/arquivo.md
ls -la /caminho/do/arquivo.md
head -30 /caminho/do/arquivo.md  # Verificar estrutura real vs alegada
find /caminho/base -name "*.md" -mmin -30  # Listar arquivos REALMENTE modificados
```

**Se o arquivo não existe ou está errado:**
1. Confronte o agente com a evidência concreta (`wc -l`, `ls -la`, `head`)
2. Peça o path exato do arquivo — agentes frequentemente referenciam paths de memória, não do disco
3. Se o agente insistir em duas verificações, o arquivo não existe — **não insista no ciclo**. Aceite o trabalho real entregue (análises, relatórios na thread) e encerre a tarefa.
4. Para tarefas críticas: execute diretamente (orquestrador) em vez de re-delegar.

### ⚠️ Padrão: Orquestrador executa quando agente não responde

Quando um agente (especialmente {{GIT_OPS}}-mac para git) não responde a 3+ menções com `<@USER_ID>` correto, o orquestrador deve executar a tarefa diretamente:

```bash
# Exemplo: commit + push no vault quando {{GIT_OPS}}-mac não responde
cd /Users/{{COMMANDER}}fae/Dev/obsidian
git add -A
git commit -m "mensagem descritiva"
git pull --rebase
git push
```

Não espere indefinidamente por agente que não responde. 3 menções sem resposta = execução direta pelo orquestrador.

### ⚠️ Padrão: Verificar propriedade de artefato por assinatura

Quando dois agentes reivindicam o mesmo artefato, verificar a assinatura no arquivo:

```bash
tail -5 /caminho/do/arquivo.md
# Ex: "*{{DEVOPS_ENGINEER}} — Windrunner, organizando o caos em estrutura.*"
```

Isso resolve disputas de crédito. Se o arquivo está assinado por um agente mas outro reivindica, confronte com a evidência. Se ambos trabalharam no mesmo artefato, declare "entrega da equipe".

---

## Prevenção

- Criar serviço de sistema para CADA agente — sem restart automático, qualquer morte de processo derruba o agente permanentemente
- Tokens de equipes diferentes (OVH vs M4) em apps Slack separados
- Após criar apps Slack para nova equipe, verificar se apps da equipe antiga ainda estão instalados
- Monitorar logs de erro periodicamente — reconnect loops frequentes indicam tokens prestes a expirar
- Após qualquer rsync de profiles, verificar se .env não foi sobrescrito por versão sem tokens
- **Checklist pós-criação de agente:** `bot_user_id` presente no config.yaml? `auth.test` retorna o user_id correto?
- **Convocation:** Sempre especificar M4 ou OVH ao convocar a equipe. IDs das duas equipes são diferentes. Ver `references/m4-ovh-team-coordination.md`.
- **Verificação de entregas:** Agentes podem alucinar arquivos inexistentes. Sempre verificar em disco antes de aceitar entrega. Ver `references/verificacao-entregas-agentes.md`.
- **CLI tools usage patterns:** Claude Opus, Gemini 3.1 Pro, OpenCode — ver `references/cli-tools-usage-patterns.md` para flags, pitfalls e padrões de uso não-interativo.
