---
name: meta-webhook-receiver-setup
description: Setup de webhook receiver FastAPI para Meta Cloud API substituindo integracao bugada da Evolution API.
category: devops
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Meta Cloud API — Webhook Receiver Setup

## Quando usar

A integracao nativa da Evolution API v2.4.0 com Meta Cloud API eh instavel. Usar um receiver FastAPI proprio.

## Arquitetura resumida

WhatsApp → Meta Cloud API → Cloudflare Tunnel (subdominio SEM Access) → Nginx location /webhook/meta → proxy para host porta 8002 → FastAPI PM2.

## Passos

1. Criar `{{COMMANDER_HOME}}/projects/meta-webhook/webhook_meta.py` com FastAPI (endpoints GET/POST `/webhook/meta`)
2. Criar `.env.meta` com `META_VERIFY_TOKEN` e `META_ACCESS_TOKEN`
3. Criar venv: `python3 -m venv .venv && .venv/bin/pip install fastapi uvicorn python-dotenv`
4. PM2: `pm2 start webhook_meta.py --name webhook-meta --interpreter .venv/bin/python` na porta 8002
5. Nginx: adicionar no server block do evolution/webhook um `location /webhook/meta` com `proxy_pass http://172.18.0.1:8002;` (172.18.0.1 = gateway da bridge Docker para o host)
6. UFW: liberar porta 8002 para sub-rede Docker: `sudo ufw allow from 172.18.0.0/16 to any port 8002 proto tcp`
7. Cloudflare Tunnel: adicionar subdomínio `webhook.oesteodontologia.com.br` → `localhost:80` **no painel Zero Trust** (gerenciamento remoto, não editar `/etc/cloudflared/config.yml`)
8. Meta Developer: configurar callback URL e verify token
9. **Remover instância Meta do Evolution:** após o receiver próprio funcionando, a instância `WHATSAPP-BUSINESS` no Evolution é inútil — deletar via manager ou API.

## Pitfalls

- **Cloudflare Access bloqueia Meta**: subdominio do webhook NAO pode ter 2FA. Usar subdominio separado (ex: webhook.oesteodontologia.com.br) sem protecao Access.
- **UFW bloqueia trafego Docker→host**: liberar porta do receiver explicitamente: `sudo ufw allow from 172.18.0.0/16 to any port 8002 proto tcp`
- **Tunnel gerenciado remotamente ignora config local**: verificar com `sudo journalctl -u cloudflared | grep "config="`. Se aparecerem hostnames que nao estao no `/etc/cloudflared/config.yml`, o tunnel eh gerenciado via Cloudflare Zero Trust dashboard (Networks → Tunnels). Editar la, nao no arquivo local.
- **Nginx faz cache DNS de containers**: apos recriar containers Docker, restartar nginx: `docker restart oeste-odontologia-nginx`
- **.env.meta vem com META_ACCESS_TOKEN vazio**: a {{BACKEND_ENGINEER}} deixa placeholder. Preencher manualmente com o token permanente da Meta.
- **Evolution v2.3.7 nao tem Meta Cloud API; v2.4.0-rc2 eh a mais estavel**: `homolog` (19/05/2026) tem bug de FK constraint `Setting_instanceId_fkey`. `rc2` (17/05/2026) funciona para criar instancias mas processa mensagens com TypeError. Usar webhook proprio em vez de depender da Evolution para Meta.
- **Evolution v2.4.0 exige licenciamento**: necessario ativar conta no manager (/manager/login) com conta Google. Se resetar o banco (apagar volumes), a licenca se perde e precisa re-ativar.
- **Reset do banco Evolution**: `docker compose stop evolution-api evolution-postgres evolution-redis && docker rm evolution-api evolution-postgres evolution-redis && docker volume rm oeste-odontologia_evolution_postgres_data oeste-odontologia_evolution_data oeste-odontologia_evolution_redis_data && docker compose up -d evolution-postgres evolution-redis evolution-api`

## Troubleshooting

| Sintoma | Causa provavel | Acao |
|---------|---------------|------|
| 502 Bad Gateway via Cloudflare | Tunnel nao tem hostname configurado | Adicionar no Zero Trust dashboard |
| 502 so no subdominio webhook (outros OK) | Cloudflared com service errado (ex: `nginx:80` em vez de `localhost:80`) | Tunnel gerenciado remotamente: corrigir no painel |
| Meta "Nao foi possivel validar" | Cloudflare Access ativo no subdominio | Remover Access do subdominio webhook |
| POST nao chega no receiver | Meta nao re-verificou webhook apos mudanca | Clicar "Verify and Save" no Developer Dashboard |
| Docker exec timeout constante | Daemon Docker sobrecarregado ou container pesado | Reiniciar container afetado |
| `integrationSession.update()` FK constraint | v2.4.0-homolog com migration quebrada | Usar rc2 ou resetar banco |
| `Cannot read properties of undefined` | Bug na v2.4.0 ao processar mensagens Meta | Abandonar Evolution para Meta; usar receiver proprio |
