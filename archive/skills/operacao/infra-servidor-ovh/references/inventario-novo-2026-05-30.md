# Inventário — Servidor OVH Novo (30/05/2026)

Servidor: `ns509999` | IP: `142.4.215.215` | Ubuntu 24.04.4 LTS | 31 GB RAM | 437 GB SSD
SSH: `ssh.oesteodontologia.com.br` (Cloudflare Access após switch) | User: `{{COMMANDER}}fae` (uid 1001, zsh, sudo NOPASSWD)
2º user: `thaisa` (uid 1002, bash)

## Containers Docker (8/8)

### docker-compose principal (`/var/www/oeste-odontologia/docker-compose.yml`)

| Container | Imagem | Porta Interna | Status |
|-----------|--------|--------------|--------|
| oeste-odontologia-db | mysql:8.0 | 3306 | healthy |
| oeste-odontologia-app | oeste-odontologia-app | 3000 | up |
| oeste-odontologia-nginx | nginx:alpine | 80 (bind host) | up |
| evolution-postgres | postgres:15 | 5432 | healthy |
| evolution-redis | redis:7-alpine | 6379 | up |
| evolution-api | evoapicloud/evolution-api:2.4.0-rc2 | 8080 | up |
| dontus-app | oeste-odontologia-dontus-app | 8502 | up |

### docker-compose {{TEAM_NAME}} (`{{COMMANDER_HOME}}fae/hermes-roshar/docker-compose.yml`)

| Container | Imagem | Rede | Status |
|-----------|--------|------|--------|
| roshar-agents | hermes-roshar-hermes-team | host | up |

## Serviços Host (PM2)

| ID | Nome | Porta | Stack | Status |
|----|------|-------|-------|--------|
| 0 | pycode-blog | 8080 | Express + EJS | online |
| 12 | webhook-meta | 8002 | FastAPI (uvicorn) | online |

## Serviços systemd

### User {{COMMANDER}}fae
| Serviço | Comando | Porta |
|---------|---------|-------|
| orto-sia | `uv run streamlit run code/annotator_interface.py --server.port 8501` | 8501 |
| hermes-gateway-lirin | Hermes CLI gateway | — |
| webhook-whatsapp | `.venv/bin/uvicorn receptor_whatsapp:app --host 0.0.0.0 --port 8001` | 8001 |

### User thaisa (5 agentes)
| Serviço | Agente | Profile |
|---------|--------|---------|
| hermes-thaisa-jade | Jade (Orquestradora) | jade |
| hermes-thaisa-babi | Babi (Saúde) | babi |
| hermes-thaisa-harry | Harry (Consultório) | harry |
| hermes-thaisa-hermione | Hermione (Acadêmica) | hermione |
| hermes-thaisa-luna | Luna (Finanças) | luna |

## Subdomínios Cloudflare (via túnel)

| Subdomínio | Roteamento |
|-----------|-----------|
| oesteodontologia.com.br, www | nginx → app:3000 |
| dashboard.oesteodontologia.com.br | nginx → dontus-app:8502 |
| evolution.oesteodontologia.com.br | nginx → evolution-api:8080 |
| sia.oesteodontologia.com.br | localhost:8501 (direto) |
| webhook.oesteodontologia.com.br | nginx → evolution-api:8080 + :8002 |
| {{BLOG_URL}} | localhost:8080 (direto) |
| ssh.oesteodontologia.com.br | SSH localhost:22 |

## UFW

```
Status: active | Default: deny (incoming)
22/tcp ALLOW IN Anywhere
8001/tcp ALLOW IN Anywhere
8002/tcp ALLOW IN 172.18.0.0/16
Loopback ALLOW
```

## Diretórios de Projetos

| Caminho | Projeto |
|---------|---------|
| /var/www/oeste-odontologia/ | Site Oeste + docker-compose |
| /var/www/dontus_app/ | Dashboard Dontus Streamlit |
| {{COMMANDER_HOME}}fae/sia_projeto/ | SIA Streamlit |
| {{COMMANDER_HOME}}fae/projects/pycode-blog/ | Blog Express |
| {{COMMANDER_HOME}}fae/projects/pycode-cerebro/ | Scripts + dados cérebro |
| {{COMMANDER_HOME}}fae/projects/meta-webhook/ | Meta webhook receiver |
| {{COMMANDER_HOME}}fae/hermes-roshar/ | Docker agents OVH |
| {{COMMANDER_HOME}}fae/Dev/hermes-profiles/ | Perfis agentes (git) |
| /home/thaisa/ | Ambiente Thaísa (277 MB, 5 agentes) |

## Agentes Hermes

| Time | Agentes | Onde |
|------|---------|------|
| Radiantes | {{ORCHESTRATOR}}, {{BACKEND_ENGINEER}}, {{AUDITOR}}, {{FRONTEND_ENGINEER}}, {{DEVOPS_ENGINEER}} | Mac M4 |
| Sociedade do Anel | Aragorn, Celebrimbor, Galadriel, Elrond, Éomer, Gandalf | Docker roshar-agents |
| Lirin | Gateway | systemd |
| Thaísa | Jade, Babi, Harry, Hermione, Luna | systemd ×5 |

## Servidor Antigo (legado)

IP: `51.77.219.105` | Todos os serviços parados/desabilitados.
Acessível por `ssh ovh-old` apenas para consulta.
Cloudflared parado — túnel migrado para o novo servidor.
