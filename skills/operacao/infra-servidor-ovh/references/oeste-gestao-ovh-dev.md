# {{PROJECT_NAME}} — Ambiente de Desenvolvimento OVH

## Stack

Serviços Docker na OVH para desenvolvimento/testes:
- **web**: Django 6.0 + Gunicorn (porta 8000)
- **db**: PostgreSQL 16 (porta 5432)
- **pgbouncer**: Pool de conexões (porta 6432)
- **redis**: Cache + broker Celery (porta 6379)

## Acesso

```bash
{{OVH_SSH_COMMAND}}
cd {{PROJECT_PATH}}
```

## Comandos úteis

```bash
# Status
docker compose ps

# Logs
docker compose logs web

# Rebuild após git pull
git pull origin develop
docker compose down
docker compose build --no-cache --build-arg FIELD_ENCRYPTION_KEY=$(python3 -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())') web
docker compose up -d

# Verificar saúde
docker compose ps
curl -s -o /dev/null -w '%{http_code}' http://localhost:8000/
```

## Cloudflare Tunnel

Subdomínio de testes: `gestao.oesteodontologia.com.br` → `localhost:8000`

Adicionar no Cloudflare Zero Trust dashboard (Networks → Tunnels → Edit → Public Hostnames):
- Subdomain: gestao
- Domain: oesteodontologia.com.br
- Type: HTTP
- URL: localhost:8000

## Fluxo de Deploy

1. Desenvolvimento no Mac (`{{PROJECT_PATH}}`)
2. Commit + push para GitHub (`develop`)
3. Pull na OVH (`{{OVH_SSH_COMMAND}} "cd {{PROJECT_PATH}} && git pull"`)
4. Rebuild + restart Docker
5. Validar com `curl localhost:8000`

## Sync de arquivos (emergência)

```bash
# Mac → OVH
rsync -avz {{PROJECT_PATH}}/Dockerfile ovh-new:{{PROJECT_PATH}}/
rsync -avz {{PROJECT_PATH}}/docker-compose.yml ovh-new:{{PROJECT_PATH}}/
rsync -avz {{PROJECT_PATH}}/config/settings.py ovh-new:{{PROJECT_PATH}}/config/

# OVH → Mac (recuperar correções feitas no servidor)
rsync -avz ovh-new:{{PROJECT_PATH}}/Dockerfile {{PROJECT_PATH}}/
```
