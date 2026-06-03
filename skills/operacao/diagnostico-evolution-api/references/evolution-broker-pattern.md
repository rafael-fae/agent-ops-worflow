# Evolution → WhatsApp Broker {{GIT_OPS}}

Implementado em 30/05/2026. Substitui o receptor simples `receptor_whatsapp.py` por um broker
com routing: grupo → blog, Comandante → inbox, outros → ignorado.

## Código do Broker

Arquivo: `{{COMMANDER_HOME}}fae/projects/pycode-cerebro/scripts/broker_whatsapp.py`

```python
from fastapi import FastAPI, Request
from datetime import datetime
import os, urllib.request, json

app = FastAPI()

GRUPO_ID = "120363425868389123@g.us"
COMANDANTE_ID = "556799623440@s.whatsapp.net"  # validar JID real!
HOJE = "{{COMMANDER_HOME}}fae/projects/pycode-cerebro/data/historico/hoje.md"
INBOX = "{{COMMANDER_HOME}}fae/projects/pycode-cerebro/data/historico/inbox.md"
EVO_KEY = "57c8b82fb8c16641c181ae040563b2254aa8efbfac61d04aeddd7d08d6c11ec9"

def send_evo(number, text):
    """Envia mensagem via Evolution API"""
    payload = json.dumps({"number": number, "text": text}).encode()
    req = urllib.request.Request(
        "http://127.0.0.1:80/message/sendText/<INSTANCE>",
        data=payload,
        headers={"apikey": EVO_KEY, "Host": "evolution.oesteodontologia.com.br",
                 "Content-Type": "application/json"}
    )
    urllib.request.urlopen(req, timeout=10)

@app.post("/webhook")
async def receber(request: Request):
    dados = await request.json()
    evento = dados.get("event")

    if evento not in ("messages.upsert", "MESSAGES_UPSERT"):
        return {"status": "ignored"}

    msg_data = dados.get("data", {})
    msg_info = msg_data.get("message", {})
    remote_jid = msg_data.get("key", {}).get("remoteJid", "")

    texto = msg_info.get("conversation") or \
            msg_info.get("extendedTextMessage", {}).get("text", "")
    if not texto:
        return {"status": "no_text"}

    nome = msg_data.get("pushName", "Desconhecido")
    agora = datetime.now().strftime("%d/%m/%Y, %H:%M:%S")
    linha = f"[{agora}] {nome}: {texto}\n"

    # Grupo → blog
    if remote_jid == GRUPO_ID:
        with open(HOJE, "a", encoding="utf-8") as f:
            f.write(linha)
        return {"status": "ok", "dest": "blog"}

    # Comandante → inbox
    if remote_jid == COMANDANTE_ID:
        with open(INBOX, "a", encoding="utf-8") as f:
            f.write(linha)
        return {"status": "ok", "dest": "inbox"}

    return {"status": "ignored", "jid": remote_jid}
```

## Systemd service

```ini
[Unit]
Description=WhatsApp Broker (Evolution → Blog + Inbox)
After=network.target

[Service]
Type=simple
User={{COMMANDER}}fae
WorkingDirectory={{COMMANDER_HOME}}fae/projects/pycode-cerebro/scripts
ExecStart={{COMMANDER_HOME}}fae/projects/pycode-cerebro/scripts/.venv/bin/uvicorn broker_whatsapp:app --host 0.0.0.0 --port 8001
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
```

## Pitfalls

1. **JID ≠ número de telefone:** O `remoteJid` do webhook pode não corresponder ao número informado. Sempre validar com log antes de configurar filtros. Ex: número `67999623440` → JID `556799623440@s.whatsapp.net`.

2. **uvicorn como entry point:** O script define `app = FastAPI()` mas não chama `uvicorn.run()`. O systemd deve executar `uvicorn broker_whatsapp:app`, não `python3 broker_whatsapp.py`.

3. **urllib no lugar de httpx:** O venv do broker pode não ter `httpx`. Usar `urllib.request` (stdlib) para chamadas HTTP internas.

4. **DATABASE_SAVE_DATA_CHATS=false bloqueia grupos no Manager UI:** Grupos existem na API mas não são persistidos. Para ver no Manager, temporariamente setar `true`.
