# Hermes WhatsApp Bridge — Setup no Host OVH

## Contexto

O Hermes Agent v0.14.0 suporta WhatsApp nativamente via um bridge Node.js (Baileys) em
`gateway/platforms/whatsapp.py`. O bridge NÃO é instalado pelo `uv pip install hermes-agent`
— ele só existe dentro do container Docker `roshar-agents`. Para usar WhatsApp nativo no
Hermes rodando no host, é preciso extrair o bridge do container.

## Procedimento de Extração e Instalação

### 1. Extrair o bridge do container Docker

```bash
# Copiar do container para o host
sudo docker cp roshar-agents:/usr/local/lib/hermes-agent/scripts/whatsapp-bridge /tmp/whatsapp-bridge

# Mover para o site-packages do hermes_env (onde o Python adapter espera)
sudo mkdir -p {{COMMANDER_HOME}}fae/hermes_env/lib/python3.12/site-packages/scripts
sudo cp -r /tmp/whatsapp-bridge {{COMMANDER_HOME}}fae/hermes_env/lib/python3.12/site-packages/scripts/
sudo chown -R {{COMMANDER}}fae:{{COMMANDER}}fae {{COMMANDER_HOME}}fae/hermes_env/lib/python3.12/site-packages/scripts
```

### 2. Instalar dependências Node.js

```bash
cd {{COMMANDER_HOME}}fae/hermes_env/lib/python3.12/site-packages/scripts/whatsapp-bridge
npm install
```

O bridge usa:
- `@whiskeysockets/baileys` — cliente WhatsApp Web
- `express` — servidor HTTP (Python ↔ bridge)
- `qrcode-terminal` — QR code no terminal
- `pino` — logging

### 3. Criar serviço systemd para o bridge

#### Modo `bot` (produção — DMs externas, recomendado)

```ini
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

**:red_circle: `WHATSAPP_MODE=bot` é obrigatório para receber DMs externas.** `self-chat` rejeita qualquer mensagem que não seja do próprio número para si mesmo.

**`WHATSAPP_WEBHOOK_URL`** — URL para onde cada mensagem é re-POSTada (fire-and-forget). Permite que um broker externo (ex: grupo→hoje.md) consuma mensagens sem competir com o gateway Hermes pela fila `/messages`. Se não precisar de consumidor adicional, remover a env var.

#### Modo `self-chat` (apenas testes)

```ini
Environment="WHATSAPP_MODE=self-chat"
ExecStart=/usr/bin/node bridge.js --port 3000 --mode self-chat --session {{COMMANDER_HOME}}fae/.hermes/profiles/aragorn/platforms/whatsapp/session
```

**⚠️ O session_path deve ser o mesmo configurado no `config.yaml` do agente Hermes.**

### 4. Adicionar endpoint `/qr` ao bridge

O bridge original não expõe o QR code via API HTTP (apenas terminal).
Para gerar QR codes via API, adicionar ao `bridge.js`:

```javascript
// 1. Variável global
let currentQR = null; let connectionState = 'disconnected';

// 2. Armazenar QR quando gerado (dentro do handler connection.update)
if (qr) { currentQR = qr; /* código existente */ }

// 3. Endpoint /qr (antes do /health)
app.get("/qr", (req, res) => {
  if (currentQR) {
    res.json({ qr: currentQR });
  } else {
    res.json({ error: "no qr yet" });
  }
});
```

### 5. Gerar imagem PNG do QR code

```bash
cd /tmp
npm install qrcode  # no diretório do bridge

node -e "
import qrcode from 'qrcode';
const resp = await fetch('http://127.0.0.1:3000/qr');
const data = await resp.json();
const png = await qrcode.toDataURL(data.qr, { width: 400, margin: 2 });
const buf = Buffer.from(png.split(',')[1], 'base64');
writeFileSync('{{COMMANDER_HOME}}fae/projects/pycode-blog/public/qr/qr.png', buf);
"
```

## Configuração no Hermes Agent

### config.yaml do agente

O `whatsapp:` deve ficar no **nível raiz** do YAML, NÃO aninhado em `platforms:`:

```yaml
whatsapp:
  enabled: true
  bridge_port: 3000
  dm_policy: allowlist
  allow_from:
    - 556799623440@s.whatsapp.net     # JID do Comandante
  group_policy: open
  group_allow_from:
    - 120363425868389123@g.us          # JID do grupo IA Master Elite
  session_path: {{COMMANDER_HOME}}fae/.hermes/profiles/aragorn/platforms/whatsapp/session
```

### .env do agente

```
WHATSAPP_ENABLED=true
GATEWAY_ALLOW_ALL_USERS=true
```

### Ativar o gateway

```bash
# Instalar como user service (NÃO system service)
hermes --profile aragorn gateway install

# Iniciar
hermes --profile aragorn gateway start

# Verificar
hermes --profile aragorn gateway status
```

## API HTTP do Bridge

| Método | Endpoint | Descrição |
|---|---|---|
| `GET` | `/health` | Status: `{"status":"connected","queueLength":0}` |
| `GET` | `/qr` | QR code string (após patch) |
| `GET` | `/messages` | **Fila única (splice)** — retorna e limpa. Segundo consumidor recebe array vazio. |
| `POST` | `/send` | Enviar: `{"chatId":"...@s.whatsapp.net","message":"texto"}` |
| `GET` | `/chat/:id` | Info do chat |

**:red_circle: `/messages` não é long-poll.** É `messageQueue.splice(0, length)` — drena a fila inteira. Apenas UM consumidor por bridge. Para consumidores adicionais (ex: broker grupo→hoje.md), usar o padrão webhook (`WHATSAPP_WEBHOOK_URL`).

## Verificação

```bash
# Bridge rodando?
systemctl is-active hermes-whatsapp-bridge
ss -tlnp | grep 3000
curl -s http://127.0.0.1:3000/health

# Gateway conectado ao bridge?
sudo journalctl --user -u hermes-gateway-aragorn | grep -i whatsapp
```

## Pitfalls

1. **Bridge não incluído no pip install**: O `uv pip install hermes-agent` instala só o Python. O bridge Node.js (Baileys) só existe no container Docker. Extrair com `docker cp`.

2. **WhatsApp no nível raiz do YAML**: O código em `gateway/config.py:1057` lê `yaml_cfg.get("whatsapp", {})` — nível raiz, não `platforms.whatsapp`. Colocar em `platforms:` faz o gateway ignorar.

3. **User service vs system service**: `hermes gateway install` cria um **user** systemd service (`~/.config/systemd/user/`). O comando `hermes gateway start` usa `systemctl --user`. Não adianta criar um system service manualmente — o gateway não se comunica corretamente com system services.

4. **Sessão por número**: Um mesmo número WhatsApp NÃO pode ter duas sessões Web ativas simultâneas. Se o Evolution estiver usando o número, o bridge Hermes não conecta.

5. **QR code expira**: O QR code do Baileys expira em ~30 segundos. Se falhar, o bridge gera um novo automaticamente. O endpoint `/qr` retorna o QR atual.

6. **`dm_policy: allowlist` requer `allow_from`**: Sem isso, TODAS as mensagens diretas são ignoradas (silenciosamente).

7. **:red_circle: `self-chat` rejeita DMs externas**: No modo `self-chat`, a bridge rejeita silenciosamente qualquer DM de outra pessoa. Log: `"reason":"self_chat_mode_rejects_non_self"`. Usar `bot` para produção.

8. **:red_circle: `/messages` é fila única**: O endpoint usa `Array.splice()` — só um consumidor. Gateway e broker NÃO podem compartilhar. Solução: webhook (`WHATSAPP_WEBHOOK_URL`) para consumidores adicionais.
