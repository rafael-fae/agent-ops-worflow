# Inventário do Servidor OVH Antigo — 30/05/2026

Migração: `51.77.219.105` (oesteodontologia) → `142.4.215.215` (ns509999)

## Servidor Antigo

- **Hostname:** oesteodontologia
- **OS:** Ubuntu 24.04.4 LTS
- **IP:** 51.77.219.105
- **Disco:** 108 GB (53 GB usado)
- **Uptime:** 26 dias

## Usuários

| User | UID | Shell | Grupos |
|------|-----|-------|--------|
| {{COMMANDER}} | 1001 | /usr/bin/zsh | sudo, docker |
| thaisa | 1002 | /bin/bash | docker |

## Docker Containers

| Container | Imagem | Porta | Rede |
|---|---|---|---|
| oeste-odontologia-nginx | nginx:alpine | 80:80 | bridge |
| oeste-odontologia-app | oeste-odontologia-app | 3000 | bridge |
| oeste-odontologia-db | mysql:8.0 | 3306 | bridge |
| evolution-api | evoapicloud/evolution-api:2.4.0-rc2 | 8080 | bridge |
| evolution-postgres | postgres:15 | 5432 | bridge |
| evolution-redis | redis:7-alpine | 6379 | bridge |
| dontus-app | oeste-odontologia-dontus-app | 8502 | bridge |
| roshar-agents | hermes-roshar-hermes-team:latest | host | host |

## Docker Volumes (sizes)

| Volume | Tamanho |
|--------|---------|
| oeste-odontologia_mysql_data | 200 MB |
| oeste-odontologia_evolution_postgres_data | 119 MB |
| oeste-odontologia_evolution_redis_data | 43 MB |
| oeste-odontologia_dontus_data | 278 MB |
| oeste-odontologia_evolution_data | 8 KB |

## PM2 Processes (user {{COMMANDER}})

| Nome | Script | Porta | Status |
|------|--------|-------|--------|
| pycode-blog | server.js (Express) | 8080 | online |
| webhook-whatsapp | receptor_whatsapp.py | 8001 | online |
| webhook-meta | webhook_meta.py | 8002 | online |
| fechamento-pycode | cron 22:55 | — | stopped |
| quartz-cerebro | legado | — | stopped |

## systemd Services

### User {{COMMANDER}}
- `cloudflared` — Cloudflare Tunnel
- `orto-sia` — SIA Streamlit (porta 8501)
- `hermes-gateway-lirin` — Gateway Hermes Lirin

### User thaisa
- `hermes-thaisa-jade` — Orquestradora
- `hermes-thaisa-babi` — Saúde
- `hermes-thaisa-harry` — Consultório
- `hermes-thaisa-hermione` — Acadêmica
- `hermes-thaisa-luna` — Finanças

## Projetos (tamanhos)

| Caminho | Tamanho | Descrição |
|---------|---------|-----------|
| `/var/www/oeste-odontologia/` | 65 MB | Site + Docker compose |
| `/var/www/dontus_app/` | 602 MB | Dontus Streamlit dashboard |
| `{{COMMANDER_HOME}}/sia_projeto/` | 13 GB | SIA Streamlit (maior: .venv + data) |
| `{{COMMANDER_HOME}}/sistema-orto-sia/` | 584 KB | Dados SIA legados |
| `{{COMMANDER_HOME}}/projects/pycode-blog/` | 15 MB | Blog Express |
| `{{COMMANDER_HOME}}/projects/pycode-cerebro/` | 609 MB | Scripts + dados |
| `{{COMMANDER_HOME}}/projects/meta-webhook/` | 32 MB | Meta webhook receiver |
| `{{COMMANDER_HOME}}/hermes-roshar/` | 1 GB | Docker agents OVH |
| `{{COMMANDER_HOME}}/Dev/hermes-profiles/` | 175 MB | Git monorepo agentes |
| `{{COMMANDER_HOME}}/projects/obsidian/` | — | Vault git |
| `/home/thaisa/` | 300 MB | 5 agentes Hermes |

## Cloudflare Tunnel

- **Tunnel ID:** `5f54a07f-b9ce-41bc-a776-2fe4172b6cfd`
- **Account Tag:** `7e5e83e3a2009e3ce98924cb14a34572`
- **Config:** `/etc/cloudflared/config.yml` + `/etc/cloudflared/credentials.json`
- **Service:** systemd `cloudflared.service`

## UFW Rules

```
8001/tcp ALLOW (webhook WhatsApp)
8002/tcp ALLOW from 172.18.0.0/16 (Meta webhook, interno Docker)
22/tcp  ALLOW (adicionado durante migração)
```

## Credenciais (locais)

| Arquivo | Contém |
|---------|--------|
| `/var/www/oeste-odontologia/.env` | MySQL, JWT, Evolution API key |
| `/var/www/dontus_app/config.yaml` | Dontus login, Evolution API key |
| `{{COMMANDER_HERMES_PATH}}/.env` | Tokens globais Hermes (2593 bytes) |
| `{{COMMANDER_HOME}}/ecosystem.config.js` | 6 tokens Slack (plaintext) |
| `/home/thaisa/ecosystem_thaisa.config.js` | 5 tokens Slack Thaísa |

## Cron Jobs

| Schedule | Job |
|----------|-----|
| `* * * * *` | Status ping (Cloudflare Access) |
| `0 6 * * 0` | Backup semanal |
| `30 * * * *` | Git sync profiles |
| `15,45 * * * *` | Git sync vault |
