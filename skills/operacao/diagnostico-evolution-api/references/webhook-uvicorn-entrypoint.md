# Pitfall: Script FastAPI sem uvicorn.run()

## Sintoma

Serviço systemd/P2M inicia e morre imediatamente com `exit code 0`.
`journalctl` mostra `Deactivated successfully` sem erros. A porta NÃO está ouvindo.

## Causa

O script `receptor_whatsapp.py` define `app = FastAPI()` mas **não contém**
`uvicorn.run()` ou `if __name__ == "__main__"`. O script apenas cria a instância
da aplicação e sai.

Executar o script diretamente com `python3 script.py` faz o Python carregar as
definições e sair com código 0 — sem iniciar o servidor HTTP.

## Solução Correta

Usar **uvicorn** como entry point, não o script Python:

```bash
# CORRETO
.venv/bin/uvicorn receptor_whatsapp:app --host 0.0.0.0 --port 8001

# ERRADO — define a classe e sai, sem escutar porta
.venv/bin/python3 receptor_whatsapp.py
```

## systemd

```ini
[Service]
ExecStart={{COMMANDER_HOME}}fae/projects/pycode-cerebro/scripts/.venv/bin/uvicorn broker_whatsapp:app --host 0.0.0.0 --port 8001
WorkingDirectory={{COMMANDER_HOME}}fae/projects/pycode-cerebro/scripts
```

## PM2 (histórico — servidor antigo)

```javascript
{
  name: "webhook-whatsapp",
  script: ".venv/bin/uvicorn",            // ← uvicorn, NÃO o .py
  args: "receptor_whatsapp:app --host 0.0.0.0 --port 8001",
  interpreter: ".venv/bin/python"
}
```

## Verificação

```bash
# Confirmar que o processo está ouvindo
ss -tlnp | grep 8001

# Testar endpoint
curl -s -X POST http://127.0.0.1:8001/webhook \
  -H 'Content-Type: application/json' \
  -d '{"event":"MESSAGES_UPSERT","data":{"key":{"remoteJid":"test"},"pushName":"Test","message":{"conversation":"test"}}}'
```

## Contexto

Documentado em 30/05/2026 durante migração de servidor OVH.
O serviço webhook-whatsapp falhou 45+ vezes (entre PM2 e systemd)
até descobrir que o script estava sendo executado diretamente em vez de via uvicorn.
