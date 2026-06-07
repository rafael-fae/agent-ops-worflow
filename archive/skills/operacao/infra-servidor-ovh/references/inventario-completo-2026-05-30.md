# Inventário Completo — Servidor OVH (30/05/2026)

Servidor: `oesteodontologia` | IP: `51.77.219.105` | Ubuntu 24.04.4 LTS | 26 dias up
SSH: `ssh.oesteodontologia.com.br` (Cloudflare Access) | User: `{{COMMANDER}}` (uid 1001, zsh, sudo)
2º user: `thaisa` (uid 1002, bash)

## Containers Docker

### docker-compose principal (`/var/www/oeste-odontologia/docker-compose.yml`)

| Container | Imagem | Porta Interna | Status |
|-----------|--------|--------------|--------|
| oeste-odontologia-db | mysql:8.0 | 3306 | Up 3 weeks (healthy) |
| oeste-odontologia-app | oeste-odontologia-app (1.11 GB) | 3000 | Up 3 weeks |
| oeste-odontologia-nginx | nginx:alpine | 80 (bind host) | Up 9 days |
| evolution-postgres | postgres:15 | 5432 | Up 10 days (healthy) |
| evolution-redis | redis:7-alpine | 6379 | Up 10 days |
| evolution-api | evoapicloud/evolution-api:2.4.0-rc2 | 8080 | Up 9 days |
| dontus-app | oeste-odontologia-dontus-app (862 MB) | 8502 | Up 9 days |

### docker-compose {{TEAM_NAME}} (`{{COMMANDER_HOME}}/hermes-roshar/docker-compose.yml`)

| Container | Imagem | Rede | Status |
|-----------|--------|------|--------|
| roshar-agents | hermes-roshar-hermes-team (8.75 GB) | host | Up 3 weeks |

### Volumes Docker
- `oeste-odontologia_mysql_data`
- `oeste-odontologia_evolution_data`
- `oeste-odontologia_evolution_postgres_data`
- `oeste-odontologia_evolution_redis_data`
- `oeste-odontologia_dontus_data`
- `vps-config_evolution_data` (legado)
- `vps-config_evolution_postgres_data` (legado)
- `vps-config_evolution_redis_data` (legado)

### Redes Docker
- `oeste-odontologia_oeste-network`: bridge 172.18.0.0/16 (ativa)
- `oeste-odontologia_default`: bridge 172.19.0.0/16 (DOWN)
- `vps-config_oeste-network`: bridge 172.20.0.0/16 (DOWN)

## Serviços Host (PM2)

| ID | Nome | Porta | Stack | Status | Mem |
|----|------|-------|-------|--------|-----|
| 17 | pycode-blog | 8080 | Express + EJS | online | 109 MB |
| 8 | webhook-whatsapp | 8001 | FastAPI (uvicorn) | online | 44 MB |
| 11 | webhook-meta | 8002 | FastAPI (uvicorn) | online | 44 MB |
| 7 | fechamento-pycode | — | bash script | stopped (cron 22:55) | — |
| 16 | quartz-cerebro | — | Node/Quartz | stopped | — |

## Serviços systemd

### User {{COMMANDER}}
| Serviço | Comando | Porta |
|---------|---------|-------|
| orto-sia | `uv run streamlit run code/annotator_interface.py --server.port 8501` | 8501 |
| hermes-gateway-lirin | Hermes CLI gateway | — |

### User thaisa (5 agentes)
| Serviço | Agente | Hermes Profile |
|---------|--------|---------------|
| hermes-thaisa-jade | Jade (Orquestradora) | jade |
| hermes-thaisa-babi | Babi (Saúde) | babi |
| hermes-thaisa-harry | Harry (Consultório) | harry |
| hermes-thaisa-hermione | Hermione (Acadêmica) | hermione |
| hermes-thaisa-luna | Luna (Finanças) | luna |

### Infra
| Serviço | Função |
|---------|--------|
| cloudflared | Cloudflare Tunnel (tunnel ID: 5f54a07f-b9ce-41bc-a776-2fe4172b6cfd) |
| docker | Docker Engine |
| cron | Cron daemon |

## Subdomínios Cloudflare (via túnel + nginx)

| Subdomínio | Roteamento |
|-----------|-----------|
| oesteodontologia.com.br, www | nginx → app:3000 (site Node.js) |
| dashboard.oesteodontologia.com.br | nginx → dontus-app:8502 |
| evolution.oesteodontologia.com.br | nginx → evolution-api:8080 |
| webhook.oesteodontologia.com.br | nginx → evolution-api:8080 + :8002 (/webhook/meta) |
| ssh.oesteodontologia.com.br | SSH localhost:22 (Cloudflare Access) |
| {{BLOG_URL}} | localhost:8080 (direto, sem nginx) |

## UFW

```
Status: active | Default: deny (incoming)
8001/tcp ALLOW IN Anywhere
8002/tcp ALLOW IN 172.18.0.0/16
Loopback ALLOW
```

## Cron Jobs

```
* * * * *     curl status ping (health check status.{{COMMANDER}}fae.com.br)
0 6 * * 0     sync-weekly-backup.sh
30 * * * *    git sync hermes-profiles (pull rebase + commit + push)
15,45 * * * * git sync obsidian vault (pull rebase + commit + push)
```

## Diretórios de Projetos

| Caminho | Projeto | Git | Tamanho |
|---------|---------|-----|---------|
| /var/www/oeste-odontologia/ | Site Oeste + docker-compose | — | — |
| /var/www/dontus_app/ | Dashboard Dontus Streamlit | — | — |
| {{COMMANDER_HOME}}/sia_projeto/ | SIA Streamlit | — | — |
| {{COMMANDER_HOME}}/sistema-orto-sia/ | Dados SIA | — | — |
| {{COMMANDER_HOME}}/projects/pycode-blog/ | Blog Express | — | — |
| {{COMMANDER_HOME}}/projects/pycode-cerebro/ | Scripts + dados cérebro | — | — |
| {{COMMANDER_HOME}}/projects/obsidian/ | Vault Obsidian | ✅ | — |
| {{COMMANDER_HOME}}/hermes-roshar/ | Docker agents OVH | — | — |
| {{COMMANDER_HOME}}/Dev/hermes-profiles/ | Perfis agentes (git) | ✅ | — |
| {{COMMANDER_HOME}}/hermes-roshar/projetos/{{PROJECT_SLUG}}/ | Docs {{PROJECT_NAME}} | ✅ | — |

## Versões de Software

- Python: 3.12.3
- Node: v22.22.2
- Docker: (presente)
- PM2: (presente)
- cloudflared: (systemd)
- Gemini CLI: 0.43.0 (`/usr/bin/gemini`)
- OpenCode CLI: 1.15.11 (`{{COMMANDER_HOME}}/.opencode/bin/opencode`)
- Hermes Agent: 0.10.0 (`{{COMMANDER_HOME}}/hermes_env/`)

## Credenciais (mapa de dispersão)

⚠️ NUNCA usar `cat`/`grep` — tokens são mascarados como `***`. Usar `xxd` ou `docker exec ... sh -c 'echo ${#VAR}'`.

| Arquivo | Conteúdo sensível |
|---------|------------------|
| `/var/www/oeste-odontologia/.env` | MYSQL_ROOT_PASSWORD, MYSQL_PASSWORD, EVOLUTION_API_KEY, EVOLUTION_POSTGRES_PASSWORD, DATABASE_URL, JWT_SECRET |
| `/var/www/dontus_app/config.yaml` | dontus.senha, evolution_apikey |
| `{{COMMANDER_HOME}}/ecosystem.config.js` | 6x SLACK_BOT_TOKEN, 6x SLACK_APP_TOKEN (Radiantes + Lirin) |
| `{{COMMANDER_HERMES_PATH}}/.env` | Vários tokens prefixados (2593 bytes) |
| `{{COMMANDER_HOME}}/hermes-roshar/docker-compose.yml` | OPENROUTER_API_KEY |
| `{{COMMANDER_HOME}}/sia_projeto/.env` | OPENROUTER_API_KEY |
| `{{COMMANDER_HOME}}/Dev/hermes-profiles/*/auth.json` | OpenCode API keys |
| Container evolution-api | AUTHENTICATION_API_KEY, WA_BUSINESS_TOKEN_WEBHOOK |
