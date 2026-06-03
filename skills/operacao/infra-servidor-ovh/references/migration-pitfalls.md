# Pitfalls de Migração de Servidor OVH

Registrado em 30/05/2026 durante migração 51.77.219.105 → 142.4.215.215.

## 1. VIRTUAL_ENV com paths hardcoded do servidor antigo

**Sintoma:** `ModuleNotFoundError: No module named 'fastapi'` mesmo com o módulo instalado no .venv.

**Causa:** O diretório `.venv` foi copiado via rsync. O script `activate` tem o path do VIRTUAL_ENV hardcoded.

**Solução:** RECRIAR o venv, não apenas copiar:
```bash
rm -rf .venv && uv venv --python 3.12 && source .venv/bin/activate && uv sync
```

## 2. SSH config com diretivas órfãs após sed

**Causa:** `sed 's/Host ssh.../###/'` remove o cabeçalho Host mas deixa as diretivas filhas como globais.

**Solução:** Comentar linha por linha ou usar `sed -i '2,6s/^/###/' ~/.ssh/config`

## 3. Docker volumes: rsync com container rodando

**Mitigação:** `docker compose stop` antes do rsync dos volumes. `docker compose start` depois.

## 4. PM2 vs systemd: preferir systemd para serviços Python

PM2 com venv apresenta problemas de VIRTUAL_ENV não propagado. Systemd é mais confiável.

## 5. Webhook receiver: script sem uvicorn.run()

O `receptor_whatsapp.py` define `app = FastAPI()` mas não chama `uvicorn.run()`. Usar: `uvicorn receptor_whatsapp:app --host 0.0.0.0 --port 8001`

## 6. Cloudflare Tunnel: YAML com chave duplicada quebra

`service:` aparecendo duas vezes no ingress causa erro de parse. Remover duplicata.

## 7. OVH-to-OVH transfer: chave SSH sem passphrase

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_migrate -N '' -C 'migration-key'
```

## 8. Arquivos excluídos do rsync que precisam ser recriados

| Excluído | Como recriar |
|----------|-------------|
| `.venv/` | `uv venv --python 3.12 && uv sync` |
| `node_modules/` | `npm install` |
