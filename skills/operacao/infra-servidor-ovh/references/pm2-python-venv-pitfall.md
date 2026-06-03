# PM2 + Python venv — Pitfalls e Por que Evitar

## O Problema

PM2 gerencia processos Node.js nativamente. Para Python, ele spawna um subprocesso
e **não propaga o ambiente do virtualenv** de forma confiável.

### Sintomas observados (30/05/2026)

1. **`ModuleNotFoundError` persistente:** `pm2 start script.py --interpreter .venv/bin/python3`
   falha com `No module named 'fastapi'` mesmo com o pacote instalado no venv.
   Executar o mesmo comando manualmente funciona.

2. **`VIRTUAL_ENV` não propagado:** Mesmo com `--interpreter .venv/bin/python3`,
   o PM2 pode não setar `VIRTUAL_ENV` nem ajustar o `PATH`, fazendo o Python
   procurar pacotes no sistema em vez do venv.

3. **Restart loop infinito:** Scripts FastAPI sem `uvicorn.run()` (apenas definem
   `app = FastAPI()`) saem com código 0. PM2 interpreta como crash e reinicia
   até atingir o limite de 15 restarts.

4. **`exec cwd` incorreto após restart:** PM2 pode herdar o cwd de outro processo,
   fazendo scripts que usam paths relativos encontrarem arquivos errados.

## Solução: systemd

Para serviços Python com venv, **preferir systemd** sobre PM2:

```ini
[Service]
User={{COMMANDER}}fae
WorkingDirectory=/path/to/project
ExecStart=/path/to/.venv/bin/uvicorn app:app --host 0.0.0.0 --port 8001
Environment="HOME={{COMMANDER_HOME}}fae"
Restart=always
RestartSec=5
```

Vantagens do systemd sobre PM2 para Python:
- Ambiente limpo e explícito via `Environment=`
- Path absoluto para o binário do venv — zero ambiguidade
- Logs via journald (`journalctl -u service-name`)
- Auto-start no boot com `systemctl enable`
- Zero dependência de Node.js/npm para gerenciar processos Python

## Quando Usar PM2

PM2 ainda é adequado para:
- Aplicações Node.js (pycode-blog, Express)
- Scripts que já funcionam sem venv
- Ambientes onde systemd não está disponível (containers minimalistas)

## Workaround (se PM2 for inevitável)

Usar um **wrapper script** em bash que ativa o venv:

```bash
#!/bin/bash
source /path/to/.venv/bin/activate
exec uvicorn app:app --host 0.0.0.0 --port 8001
```

E iniciar com PM2 usando `--interpreter /bin/bash`.

**Nota:** O workaround funcionou para o webhook-meta mas falhou intermitentemente
para o webhook-whatsapp. A migração para systemd resolveu definitivamente.
