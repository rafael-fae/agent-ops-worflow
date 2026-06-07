---
name: hermes-whatsapp-native
description: Setup da ponte WhatsApp nativa do Hermes Agent (Baileys) — bridge Node.js, endpoint /qr, systemd service, configuração do perfil e troubleshooting.
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Hermes WhatsApp Nativo (Baileys Bridge)

## Gatilho

- Configurar WhatsApp nativo em um agente Hermes (sem Evolution API)
- O Comandante quer conversar diretamente com agentes via WhatsApp
- O agente precisa de comunicação bidirecional (enviar e receber mensagens)
- Migrar de Evolution API para bridge Hermes nativa

## Modos de Operação

| Modo | Descrição | Quando usar |
|------|-----------|-------------|
| `self-chat` | Agente só responde mensagens enviadas para o próprio número (WhatsApp "Message Yourself") | Testes locais, sem risco de ban |
| `bot` | Agente responde DMs de qualquer número (filtrado por allowlist) | Produção, comunicação com o Comandante |

⚠️ **Trocar de modo:** alterar `WHATSAPP_MODE` no systemd service + `--mode` no ExecStart. Ex: `bot` para produção, `self-chat` para testes.
- Trocar entre modo `self-chat` (mensagens para si mesmo) e `bot` (DMs de outros números)

## Arquitetura

```
WhatsApp Mobile → Baileys (bridge.js) → HTTP localhost:3000 → Hermes Python Adapter → Agente
                    ↑ Node.js Express               ↑ gateway/platforms/whatsapp.py
```

A bridge é um processo Node.js standalone que:
1. Conecta ao WhatsApp via Baileys (protocolo WebSocket)
2. Exibe QR code para pareamento
3. Expõe endpoints HTTP para o adapter Python do Hermes
4. Faz long-poll de mensagens recebidas e envia respostas

## Onde está a bridge

A bridge **NÃO** é instalada automaticamente com `uv pip install hermes-agent`. Ela existe apenas dentro do container Docker `roshar-agents` ou precisa ser copiada manualmente.

### Copiar do container Docker

```bash
# Copiar do container para o host
sudo docker cp roshar-agents:/usr/local/lib/hermes-agent/scripts/whatsapp-bridge /tmp/whatsapp-bridge

# Mover para o local correto
sudo mkdir -p {{COMMANDER_HOME}}fae/hermes_env/lib/python3.12/site-packages/scripts
sudo cp -r /tmp/whatsapp-bridge {{COMMANDER_HOME}}fae/hermes_env/lib/python3.12/site-packages/scripts/
sudo chown -R {{COMMANDER}}fae:{{COMMANDER}}fae {{COMMANDER_HOME}}fae/hermes_env/lib/python3.12/site-packages/scripts/whatsapp-bridge

# Instalar dependências Node.js
cd {{COMMANDER_HOME}}fae/hermes_env/lib/python3.12/site-packages/scripts/whatsapp-bridge
npm install
```

### Dependências (package.json)

```json
{
  "dependencies": {
    "@whiskeysockets/baileys": "WhiskeySockets/Baileys#01047debd81beb20da7b7779b08edcb06aa03770",
    "express": "^4.21.0",
    "qrcode-terminal": "^0.12.0",
    "pino": "^9.0.0"
  }
}
```

## Patch da bridge: adicionar endpoint /qr

A bridge original imprime o QR code no terminal (ASCII art). Para servir o QR como string JSON (útil para gerar PNG ou servir via web), adicionar:

```bash
cd /path/to/whatsapp-bridge
cp bridge.js bridge.js.bak

# Adicionar variável global para armazenar QR
sed -i 's|let connectionState =|let currentQR = null; let connectionState =|' bridge.js

# Armazenar QR quando disponível
sed -i 's|if (qr) {|if (qr) { currentQR = qr;|' bridge.js

# Adicionar endpoint /qr antes do /health
sed -i '/app.get.*health.*/i\
app.get("/qr", (req, res) => {\
  if (currentQR) {\
    res.json({ qr: currentQR });\
  } else {\
    res.json({ error: "no qr yet" });\
  }\
});\
' bridge.js
```

## Modos de Operação

A bridge tem **dois modos**, controlados por `WHATSAPP_MODE`:

| Modo | Comportamento | Quando usar |
|------|--------------|-------------|
| `self-chat` (default) | SÓ processa mensagens que você envia para si mesmo (WhatsApp "Message Yourself"). **Rejeita TODAS as DMs externas e mensagens de grupo.** | Testes locais, agente que só responde a self-messages |
| `bot` | Processa DMs de remetentes na allowlist (`WHATSAPP_ALLOWED_USERS`). Mensagens `fromMe` (eco das próprias respostas) são ignoradas. | **Produção: Comandante conversa com o agente via DM** |

**:red_circle: Para DMs externas ({{COMMANDER}} → Aragorn), usar SEMPRE `bot`.** `self-chat` rejeita silenciosamente qualquer mensagem que não seja do próprio número para si mesmo.

Ver `references/bridge-modes.md` para a lógica completa de filtro de cada modo.

## Systemd service para a bridge

### Modo `bot` (produção — DMs externas)

```ini
# /etc/systemd/system/hermes-whatsapp-bridge.service
[Unit]
Description=Hermes WhatsApp Bridge (Baileys)
After=network.target

[Service]
Type=simple
User={{COMMANDER}}fae
WorkingDirectory={{COMMANDER_HOME}}fae/hermes_env/lib/python3.12/site-packages/scripts/whatsapp-bridge
Environment="HOME={{COMMANDER_HOME}}fae"
Environment="WHATSAPP_SESSION_PATH={{COMMANDER_HOME}}fae/.hermes/profiles/aragorn/platforms/whatsapp/session"
Environment="WHATSAPP_BRIDGE_PORT=3000"
Environment="WHATSAPP_MODE=bot"
Environment="WHATSAPP_ALLOWED_USERS=556799623440"
Environment="WHATSAPP_WEBHOOK_URL=http://127.0.0.1:8001/webhook"
ExecStart=/usr/bin/node bridge.js --port 3000 --mode bot --session {{COMMANDER_HOME}}fae/.hermes/profiles/aragorn/platforms/whatsapp/session
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Env vars críticas para `bot`:**
- `WHATSAPP_ALLOWED_USERS` — números (só dígitos) separados por vírgula. Ex: `556799623440,556799123456`
- `WHATSAPP_WEBHOOK_URL` — (opcional) URL para onde cada mensagem recebida é re-POSTada. Permite que um broker externo (ex: grupo→hoje.md) consuma mensagens sem competir com o gateway pela fila `/messages`.

### Modo `self-chat` (testes)

```ini
Environment="WHATSAPP_MODE=self-chat"
ExecStart=/usr/bin/node bridge.js --port 3000 --mode self-chat --session {{COMMANDER_HOME}}fae/.hermes/profiles/aragorn/platforms/whatsapp/session
```

Prefixo configurável via `WHATSAPP_REPLY_PREFIX` (só aplicado em `self-chat`).

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now hermes-whatsapp-bridge
```

## Gerar QR code como PNG

```bash
# Instalar qrcode (Node.js) no diretório da bridge
cd /path/to/whatsapp-bridge
npm install qrcode

# Script para gerar PNG (gen_qr.js)
node -e "
import qrcode from 'qrcode';
import { writeFileSync, mkdirSync } from 'fs';

const resp = await fetch('http://127.0.0.1:3000/qr');
const data = await resp.json();

if (data.qr) {
    const png = await qrcode.toDataURL(data.qr, { width: 400, margin: 2 });
    const buf = Buffer.from(png.split(',')[1], 'base64');
    mkdirSync('/path/to/output', { recursive: true });
    writeFileSync('/path/to/output/qr.png', buf);
    console.log('READY');
}
"
```

O QR code expira em ~30 segundos. Se falhar, reiniciar a bridge (`systemctl restart hermes-whatsapp-bridge`) para gerar novo QR.

## Configuração do perfil Hermes

Adicionar ao `config.yaml` do agente:

```yaml
whatsapp:
  dm_policy: "allowlist"
  allow_from:
    - "556799623440@s.whatsapp.net"   # JID do Comandante
  group_policy: "open"
  group_allow_from:
    - "120363425868389123@g.us"        # Grupo IA Master Elite
  bridge_port: 3000
  session_path: "{{COMMANDER_HOME}}fae/.hermes/profiles/aragorn/platforms/whatsapp/session"
```

### Políticas de mensagem

| Campo | Valores | Descrição |
|-------|---------|-----------|
| `dm_policy` | `open`, `allowlist`, `disabled` | Quem pode enviar DM |
| `group_policy` | `open`, `allowlist`, `disabled` | Quais grupos o agente processa |
| `allow_from` | Lista de JIDs | Remetentes permitidos (DM) |
| `group_allow_from` | Lista de JIDs | Grupos permitidos |

### Descobrir o JID real de um contato

**O número de telefone pode não corresponder ao JID do WhatsApp.** Exemplo: número `67999623440` → JID `556799623440@s.whatsapp.net` (faltava um `9`).

Para descobrir o JID real:
1. Deixar a bridge rodando e pedir para a pessoa enviar uma mensagem
2. Verificar logs: `sudo journalctl -u hermes-whatsapp-bridge --no-pager -n 20`
3. Ou usar o endpoint `/messages` da bridge após o pareamento

## Testar envio de mensagem

```bash
curl -s -X POST http://127.0.0.1:3000/send \
  -H 'Content-Type: application/json' \
  -d '{"chatId":"556799623440@s.whatsapp.net","message":"Teste"}'
```

Resposta: `{"success":true,"messageId":"3EB0..."}`

## Padrão Webhook — Multi-Consumidor

**Problema:** O endpoint `GET /messages` da bridge **NÃO é long-poll** — é uma fila única consumida com `Array.splice()`. Quem chamar primeiro leva as mensagens; o segundo recebe array vazio. Gateway Hermes e broker externo (grupo→hoje.md) NÃO podem coexistir consumindo `/messages`.

**Solução:** Adicionar webhook à bridge. Cada mensagem é POSTada para `WHATSAPP_WEBHOOK_URL` **além** de ser enfileirada para o gateway. O broker recebe via webhook; o gateway consome via `/messages`. Ambos recebem todas as mensagens sem competição.

### Patch na bridge (bridge.js)

Após `messageQueue.push(event)`:

```javascript
// Webhook forward: POST to broker for side effects
if (WHATSAPP_WEBHOOK_URL) {
  const webhookPayload = JSON.stringify(event);
  fetch(WHATSAPP_WEBHOOK_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: webhookPayload,
  }).catch(function() {}); // fire-and-forget
}
```

E declarar a env var:

```javascript
const WHATSAPP_WEBHOOK_URL = process.env.WHATSAPP_WEBHOOK_URL || null;
```

### Broker (FastAPI) que consome o webhook

```python
@app.post("/webhook")
async def receber(request: Request):
    evento = await request.json()
    chat_id = evento.get("chatId", "")
    is_group = evento.get("isGroup", False)
    sender_name = evento.get("senderName", "Desconhecido")
    body = (evento.get("body") or "").strip()

    if is_group and chat_id == GRUPO_ID:
        # → hoje.md
        ...
    if not is_group and normalize_jid(evento.get("senderId","")) == COMANDANTE:
        # → inbox.md
        ...
```

Ver `references/bridge-event-format.md` para o schema completo do evento.

## API HTTP do Bridge

| Método | Endpoint | Descrição |
|---|---|---|
| `GET` | `/health` | Status: `{"status":"connected","queueLength":0}` |
| `GET` | `/qr` | QR code string (após patch) |
| `GET` | `/messages` | **Fila única** — retorna e limpa `messageQueue`. Não é long-poll. |
| `POST` | `/send` | Enviar: `{"chatId":"...@s.whatsapp.net","message":"texto"}` |
| `GET` | `/chat/:id` | Info do chat |

## Verificar status

```bash
# Bridge conectada?
curl -s http://127.0.0.1:3000/health
# {"status":"connected","queueLength":0,"uptime":190}

# QR disponível?
curl -s http://127.0.0.1:3000/qr
# {"qr":"2@yQwJ..."}  ou  {"error":"no qr yet"}

# Logs
sudo journalctl -u hermes-whatsapp-bridge --no-pager -n 20
```

## Gateway — Onde Rodar

**:red_circle: O gateway Hermes (`hermes gateway run`) deve rodar no HOST, NÃO dentro do container Docker.**

Quando o gateway roda dentro do container, ele tenta iniciar sua **própria** bridge (subprocesso `node bridge.js`), que conflita com a bridge já rodando no host:
- Porta 3000 já em uso → timeout após 30s: `whatsapp connect timed out after 30s`
- Mesmo número WhatsApp não pode ter duas sessões Web simultâneas

**Setup correto (tudo no host, sem Docker):**
```
HOST: bridge (systemd, :3000) + gateway PM2 (aragorn) + broker (systemd, :8001)
```

O gateway Hermes (`hermes --profile aragorn gateway run`) roda no host via PM2 (ou systemd). Conecta na bridge do host via `localhost:3000` (HTTP simples). **Nenhum container Docker é necessário ou recomendado** — a tentativa de rodar agentes em container (`roshar-agents`) causa conflitos de porta, sessão WhatsApp duplicada, e problemas de permissão (arquivos criados como root).

### Requisitos para gateway no host

1. **`WHATSAPP_ENABLED=true` no `.env` do perfil** — sem isso, o gateway pula WhatsApp silenciosamente. O log mostra `Gateway running with 1 platform(s)` em vez de 2.

2. **`session_path` no `config.yaml` deve ser path absoluto do HOST:**
   ```yaml
   session_path: {{COMMANDER_HOME}}fae/.hermes/profiles/aragorn/platforms/whatsapp/session
   ```
   Se apontar para path do container (`/root/...`), o gateway no host não encontra `creds.json` e reporta: `WhatsApp is enabled but not paired`.

3. **`creds.json` deve existir no `session_path`.** Se a bridge já está pareada, copiar do diretório de sessão real:
   ```bash
   cp {{COMMANDER_HOME}}fae/.hermes/profiles/aragorn/platforms/whatsapp/session/creds.json \
      /caminho/do/session_path/configurado/
   ```

4. **Bridge serve HTTP, não HTTPS.** Se o log mostrar `Cannot connect to host 127.0.0.1:3000 ssl:default`, o gateway está tentando TLS. Verificar se `bridge_port: 3000` está correto no config.yaml (sem `https://`).

### Systemd para gateway no host

```bash
# Instalar como user service (NÃO system service)
hermes --profile aragorn gateway install

# Iniciar
systemctl --user start hermes-gateway-aragorn

# Status
systemctl --user status hermes-gateway-aragorn
```

Se o systemd service falhar, rodar com `nohup` para debug:
```bash
nohup hermes --profile aragorn gateway run > /tmp/gateway.log 2>&1 &
```

### Verificar que WhatsApp conectou

```bash
grep "platform(s)" {{COMMANDER_HOME}}fae/.hermes/profiles/aragorn/logs/gateway.log
# Deve mostrar: Gateway running with 2 platform(s)
# Se mostrar 1, só Slack conectou — WhatsApp falhou silenciosamente
```

## Modos da Bridge: `self-chat` vs `bot`

A bridge tem dois modos definidos por `WHATSAPP_MODE`:

| Modo | Comportamento | Quando usar |
|------|--------------|-------------|
| `self-chat` | Só processa mensagens enviadas para si mesmo (WhatsApp "Message Yourself"). Rejeita TODAS as DMs externas com `self_chat_mode_rejects_non_self`. | Testes locais, sem risco de responder estranhos |
| `bot` | Aceita DMs de remetentes na `WHATSAPP_ALLOWED_USERS`. Mensagens `fromMe` são ignoradas (eco das próprias respostas). | DM do Comandante → agente |

**⚠️ O modo padrão é `self-chat`.** Para receber DMs, é obrigatório:
1. `WHATSAPP_MODE=bot`
2. `WHATSAPP_ALLOWED_USERS=<numero sem @>` (ex: `556799623440`)

### Webhook para Consumidores Múltiplos

O endpoint `/messages` da bridge é uma **fila única**: `splice()` remove as mensagens, então só um consumidor as recebe. Para ter dois consumidores (ex: gateway Hermes + broker do blog), adicionar webhook na bridge:

```javascript
// Após messageQueue.push(event):
if (WHATSAPP_WEBHOOK_URL) {
  const webhookPayload = JSON.stringify(event);
  fetch(WHATSAPP_WEBHOOK_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: webhookPayload,
  }).catch(function() {});
}
```

Configurar no systemd: `Environment="WHATSAPP_WEBHOOK_URL=http://127.0.0.1:8001/webhook"`

### Gateway Hermes no Host vs Container

Se a bridge está no host (systemd) e o agente está em Docker:
- Container com `network_mode: host` acessa `localhost:3000`
- Mas o gateway tenta INICIAR sua própria bridge dentro do container → conflito de porta
- **Solução:** rodar o gateway no HOST, não no container. O gateway conecta na bridge via HTTP (localhost:3000).

```bash
# No host:
{{COMMANDER_HOME}}fae/hermes_env/bin/hermes --profile aragorn gateway run --replace
```

1. ****⚠️ Bridge NÃO incluída no `uv pip install`:** O pacote Python do Hermes não inclui o `scripts/whatsapp-bridge/`. Copiar do container Docker ou de outra instalação.

2. **QR expira rápido:** ~30 segundos.

3. **Número ≠ JID:** O JID do WhatsApp (`XXXXXXXX@s.whatsapp.net`) pode diferir do número de telefone.

4. **Sessão vinculada ao diretório:** O `session_path` contém as credenciais.

5. **Conflito com Evolution:** NÃO usar o mesmo número no Evolution e na bridge simultaneamente.

6. **Modo `self-chat` vs `bot`:** `self-chat` = responde no mesmo chat. `bot` = responde DMs externas com allowlist.

7. **Docker host network:** Se Docker usa `network_mode: host`, bridge no host acessível via `localhost:3000`.

8. **Gateway tenta iniciar bridge própria** se `WHATSAPP_ENABLED=true`. Rodar bridge como systemd NO HOST.

9. **`creds.json` precisa estar no session_path** acessível ao gateway (volume mount se Docker).

10. **`/messages` é fila única:** Apenas UM consumidor. Para múltiplos, adicionar webhook (`WHATSAPP_WEBHOOK_URL`).

11. **Webhook na bridge:** Patch no bridge.js para POST fire-and-forget. Permite gateway + broker coexistirem.** O pacote Python do Hermes não inclui o `scripts/whatsapp-bridge/`. Copiar do container Docker ou de outra instalação.

2. **QR expira rápido:** ~30 segundos. Se falhar o scan, reiniciar a bridge.

3. **Número ≠ JID:** O JID do WhatsApp (`XXXXXXXX@s.whatsapp.net`) pode diferir do número de telefone. Validar via webhook/logs.

4. **Sessão vinculada ao diretório:** O `session_path` contém as credenciais. Se mudar de diretório, precisa re-escanear QR.

5. **Conflito com Evolution:** NÃO usar o mesmo número no Evolution e na bridge simultaneamente. Apenas uma sessão WhatsApp Web por número.

6. **Modo `self-chat` vs `bot`:** Em `self-chat`, o agente responde no mesmo chat com prefixo. Em `bot`, responde como mensagem normal. **Para DMs do Comandante, usar modo `bot`** com `WHATSAPP_ALLOWED_USERS`. O modo `self-chat` rejeita TODAS as mensagens de terceiros (`self_chat_mode_rejects_non_self`).

7. **Docker host network:** Se o agente roda em Docker com `network_mode: host`, a bridge no host é acessível via `localhost:3000`.

8. :red_circle: **Gateway Hermes deve rodar no HOST, não no container.** O gateway tenta iniciar sua própria bridge interna, que conflita com a bridge já rodando no host (porta 3000). Resultado: timeout de 30s. Rodar `hermes --profile aragorn gateway run` no host.

9. **`WHATSAPP_ENABLED=true` é obrigatório no `.env`** do agente. Sem isso, o gateway não ativa a plataforma WhatsApp.

10. **Webhook na bridge para coexistência com broker:** A bridge usa fila única (`/messages`). Para ter gateway + broker consumindo simultaneamente, adicionar webhook POST na bridge (`WHATSAPP_WEBHOOK_URL`). O broker recebe via webhook, o gateway via polling.

11. **`creds.json` deve estar acessível ao gateway.** Se o gateway roda no host e o session_path está em `/home/user/.hermes/...`, o arquivo precisa existir nesse path. O container monta volumes em `/root/.hermes/...` — paths diferentes.ns de terceiros (`self_chat_mode_rejects_non_self`).

7. **Docker host network:** Se o agente roda em Docker com `network_mode: host`, a bridge no host é acessível via `localhost:3000`.

8. :red_circle: **Gateway Hermes deve rodar no HOST, não no container.** O gateway tenta iniciar sua própria bridge interna, que conflita com a bridge já rodando no host (porta 3000). Resultado: timeout de 30s. Rodar `hermes --profile aragorn gateway run` no host.

9. **`WHATSAPP_ENABLED=true` é obrigatório no `.env`** do agente. Sem isso, o gateway não ativa a plataforma WhatsApp.

10. **Webhook na bridge para coexistência com broker:** A bridge usa fila única (`/messages`). Para ter gateway + broker consumindo simultaneamente, adicionar webhook POST na bridge (`WHATSAPP_WEBHOOK_URL`). O broker recebe via webhook, o gateway via polling.

11. **`creds.json` deve estar acessível ao gateway.** Se o gateway roda no host e o session_path está em `/home/user/.hermes/...`, o arquivo precisa existir nesse path. O container monta volumes em `/root/.hermes/...` — paths diferentes.

12. **Gateway é user service:** `hermes gateway install` cria serviço em `~/.config/systemd/user/`. Usar `systemctl --user`, não `sudo systemctl`.

13. **LID vs JID no allowlist:** O WhatsApp pode entregar mensagens com remetente em formato LID (`134604409290999@lid`) em vez de JID (`556799623440@s.whatsapp.net`). A bridge usa `lid-mapping-*.json` no `session_path` para resolver. Se o allowlist não funcionar, verificar se os mappings foram gerados (deixar a bridge rodando e receber uma mensagem do contato).

14. **Bridge é HTTP, não HTTPS:** A bridge serve HTTP simples na porta 3000. Se o gateway tentar TLS (`ssl:default` no erro), verificar que `bridge_port: 3000` está configurado sem prefixo `https://`.

## Comparação: Evolution API vs Hermes Nativo

| | Evolution API | Hermes Nativo |
|---|---|---|
| Setup | Docker container, Manager UI | Bridge Node.js + config YAML |
| QR code | Manager UI (browser) | Precisa gerar PNG do endpoint /qr |
| Envio de msg | `POST /message/sendText/{instance}` | `POST http://localhost:3000/send` |
| Recebimento | Webhook configurável | Long-poll via Hermes adapter |
| Grupo → blog | Webhook → FastAPI → hoje.md | Precisa implementar no agente |
| Complexidade | Média | Média-alta |
| Dependências | Docker | Node.js + npm |
