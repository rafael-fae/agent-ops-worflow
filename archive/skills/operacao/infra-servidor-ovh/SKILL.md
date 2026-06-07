---
name: infra-servidor-ovh
description: Arquitetura do servidor OVH de produção ({{COMMANDER_NAME}}) — segurança, rede, containers, ambientes. Fatos verificados e perenes para auditoria e troubleshooting.
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Infraestrutura — Servidor OVH de Produção

**Atualizado:** 30/05/2026 — Migração para novo servidor OVH

## Servidor Atual (Produção)

| Atributo | Valor |
|---|---|
| **IP** | `142.4.215.215` |
| **Hostname** | `oesteodontologia.com.br` |
| **OS** | Ubuntu 24.04.4 LTS |
| **RAM** | 31 GB |
| **Disco** | 437 GB SSD |
| **User** | `{{COMMANDER}}fae` (sudo NOPASSWD, SSH key only) |

## Servidor Antigo (Desligado)

| Atributo | Valor |
|---|---|
| **IP** | `51.77.219.105` |
| **Hostname** | `oesteodontologia` |
| **Status** | Cloudflared parado, serviços desabilitados. Acessível via `ssh ovh-old` para consulta. |

## Perfil do Servidor
- **Tipo**: Headless (sem GUI, sem X11, sem Wayland)
- **Claude Code**: NÃO instalado
- **VS Code Server**: NÃO instalado
- **Acesso SSH**: `{{OVH_SSH_COMMAND}}` (IP direto) ou `ssh ssh.oesteodontologia.com.br` (Cloudflare Tunnel)
- **:red_circle: Chave SSH correta (Mac → OVH):** A chave padrão `id_ed25519` (`~/.ssh/id_ed25519`) é RECUSADA pelo OVH novo (02/06/2026). A chave que funciona é `{{OVH_SSH_KEY}}` (`~/.ssh/{{OVH_SSH_KEY}}`, criada 27/05/2026). Usar `ssh -i ~/.ssh/{{OVH_SSH_KEY}} ovh-new` ou adicionar `IdentityFile ~/.ssh/{{OVH_SSH_KEY}}` ao bloco `Host ovh-new` no `~/.ssh/config`. Sintoma: `Permission denied (publickey)` com a chave default. Diagnóstico: `ssh -v ovh-new` mostra `Offering public key: /Users/{{COMMANDER}}fae/.ssh/id_ed25519` → recusada; testar com `-i ~/.ssh/{{OVH_SSH_KEY}}` resolve.

## Procedimentos de Migração

Ver skill **`ovh-server-migration`** para o procedimento completo de migração entre servidores OVH, incluindo:
- Transferência OVH→OVH com chave SSH dedicada (30 MB/s)
- Switch de Cloudflare Tunnel (~30s downtime)
- Migração de Docker, PM2, systemd, cron
- Checklist de verificação pós-migração
- Inventário completo do servidor antigo em `ovh-server-migration/references/inventario-2026-05-30.md`

## Rede e Acesso
- **Cloudflare**: Proxy reverso + túnel cloudflared (systemd). O túnel é gerenciado **remotamente** via Cloudflare Zero Trust dashboard (Networks → Tunnels). O arquivo `/etc/cloudflared/config.yml` é IGNORADO para hostnames — as rotas são definidas no painel. Verificar com `sudo journalctl -u cloudflared | grep "config="`.
- **Subdomínios ativos**: oesteodontologia.com.br, www, dashboard, evolution, ssh, webhook (Meta Cloud API, sem Access), sia, {{BLOG_URL}}
- **⚠️ Estratégia de porta para serviços atrás do Túnel**: Quando o Cloudflare Dashboard estiver inacessível (2FA, sem credenciais), reusar a mesma porta do serviço anterior evita qualquer necessidade de reconfiguração remota. Exemplo: pycode-blog substituiu Quartz na porta 8080 — bastou `pm2 stop` do antigo e `pm2 start` do novo. Zero mudanças no túnel. Rollback instantâneo (reverter PM2).
- **⚠️ Rotas remotas vs locais**: As rotas são definidas no Cloudflare Zero Trust dashboard (`one.dash.cloudflare.com` → Networks → Tunnels). O `/etc/cloudflared/config.yml` local é IGNORADO para hostnames. **Nunca adicionar** rotas no config.yml que já existem remotamente — o merge de configs causa erro de YAML (`mapping key "service" already defined`) e o cloudflared não inicia. Subdomínios como `sia.oesteodontologia.com.br` podem existir remotamente sem aparecer no config local. Verificar com `sudo journalctl -u cloudflared | grep "config="`. Para migração: o novo servidor herda automaticamente as rotas remotas ao usar o mesmo TunnelID.
- **SSH**: Bloqueado para acesso externo direto
- **Migração**: Procedimento completo em `migracao-servidor-ovh` — cobre transferência OVH→OVH, Docker, PM2, Cloudflare Tunnel switch, systemd, e pitfalls de venv/caminhos.
- **Autenticação SSH**: Chave SSH + 2FA
- **Evolution API**: Roda em container Docker, webhook é estritamente interno (rede bridge). Sem port binding para o host.
- **Versão Evolution**: `evoapicloud/evolution-api:2.4.0-rc2` (17/05/2026) com licenciamento ativado. A versão `homolog` (19/05/2026) tem bug de FK constraint — evitar.
- **Persistência de mensagens**: DESLIGADA (20/05/2026) — `DATABASE_SAVE_DATA_{NEW_MESSAGE,MESSAGE_UPDATE,CONTACTS,CHATS}=false`. Apenas `DATABASE_SAVE_DATA_INSTANCE=true` permanece.
- **Instância WhatsApp**: Perdida durante upgrade 2.3.7 → 2.4.0 (banco migrado, instância não). Necessário recriar via Manager UI. Ver `diagnostico-evolution-api` para procedimento.
- **Meta Cloud API**: NÃO usa Evolution para processamento. Webhook receiver próprio (FastAPI, PM2 porta 8002) em `{{COMMANDER_HOME}}/projects/pycode-cerebro/scripts/webhook_meta.py`. Config em `.env.meta`.
- **Licenciamento**: A partir da v2.4.0, licenciamento é obrigatório. Ativar em `/manager/login`. Reset de banco invalida licença (novo `instance_id`).

## Firewall (UFW) — Atualizado 01/06/2026

- **Status**: ACTIVE | Default: deny (incoming)
- **Regras ativas**:
  - 80/tcp ALLOW (Cloudflare Tunnel)
  - 443/tcp ALLOW (HTTPS)
  - 22/tcp ALLOW (SSH admin)
  - 2222/tcp ALLOW (SSH backup — redirect iptables → 22)
  - Loopback ALLOW (127.0.0.1)
- **Docker**: TODOS os serviços com port binding em `127.0.0.1` (5432, 6379, 6432, 8000). Nenhum exposto em `0.0.0.0`.
- **fail2ban**: Ativo com jail sshd (5 tentativas = 1h ban)
- **unattended-upgrades**: Ativo com security updates automáticos
- **SSH Password auth**: Desabilitado (apenas chave)
- **Usuário ubuntu**: Removido

Procedimento completo: `references/ovh-security-hardening.md`.

## Ambientes Python
- **Hermes Agent**: `{{COMMANDER_HOME}}/hermes_env/` (virtualenv)
  - Versão instalada no servidor (verificada 18/05/2026): `0.10.0`
  - Última versão disponível no PyPI (verificada 19/05/2026): `0.14.0`
  - Comando de instalação para novos ambientes: `uv pip install hermes-agent==0.14.0` (pin explícito recomendado)
  - 54 dependências declaradas no METADATA (`Requires-Dist`)
  - METADATA: `{{COMMANDER_HOME}}/hermes_env/lib/python3.12/site-packages/hermes_agent-0.10.0.dist-info/METADATA`
  - Comandos CLI disponíveis e validados: `hermes setup --non-interactive`, `hermes config set`
- **Projetos secundários**: SIA e Dontus com `pyproject.toml` próprios — não relacionados ao Hermes em produção

## Node.js
- Node e npm presentes no sistema
- Sem `package.json` ou `node_modules` no projeto Hermes
- Apenas cache residual de `npx` (tsc, @jackyzha0/quartz) — irrelevante para investigação

## CLIs Instalados (27/05/2026)

### Gemini CLI
| Item | Valor |
|------|-------|
| Path | `/usr/bin/gemini` |
| Versão | 0.43.0 |
| Auth | OAuth (conta Google) — `{{COMMANDER_HOME}}/.gemini/` |
| Modo headless | `gemini -p "prompt"` |
| Instalação | `npm install -g @google/generative-ai-cli` |

### OpenCode CLI
| Item | Valor |
|------|-------|
| Path | `{{COMMANDER_HOME}}/.opencode/bin/opencode` |
| Versão | 1.15.11 |
| Auth | API key z.ai — `{{COMMANDER_HOME}}/.local/share/opencode/auth.json` |
| Provider `zai-coding-plan` | Modelos: `glm-4.5-air`, `glm-4.7`, `glm-5-turbo`, `glm-5.1`, `glm-5v-turbo` |
| Modo headless | `opencode run -m <provider/modelo> "prompt"` (saída TUI) |
| Instalação | Download standalone em `~/.opencode/bin/` |

### ⚠️ $HOME Isolation {{GIT_OPS}}
Agentes Hermes rodam com `$HOME={{COMMANDER_HERMES_PATH}}/profiles/<agent>/home/`.
CLIs que armazenam config/credenciais em `~/.<nome>/` **não encontram** as credenciais do {{COMMANDER}}.
**Solução:** `HOME={{COMMANDER_HOME}} <comando>` para testar, ou symlinks nos profiles.
Ver skill `cli-tools-agent-setup` para procedimento completo.

## Arquitetura de Processos (Verificada 30/05/2026)

### Arquitetura de Processos (Verificada 31/05/2026)

**Sociedade do Anel (OVH):** 5 agentes via PM2 + 2 via systemd.

| Agente | Gerenciador | Comando |
|--------|------------|---------|
| Aragorn | PM2 | `hermes --profile aragorn gateway run --replace` |
| Celebrimbor | PM2 | idem |
| Galadriel | PM2 | idem |
| Elrond | PM2 | idem |
| Eomer | PM2 | idem |
| Gandalf | systemd | `hermes-gandalf.service` |
| Lirin | systemd | `hermes-gateway-lirin.service` |

**Container Docker `roshar-agents`:** REMOVIDO (31/05/2026). Era um erro de migração — os agentes nunca rodaram em Docker. PM2 + systemd é a arquitetura correta.

**:red_circle: Pitfall de Migração:** O `ecosystem.config.js` original foi perdido na migração de servidor. Recriado em `{{COMMANDER_HOME}}fae/ecosystem.config.js` com interpreter Python direto (`{{COMMANDER_HOME}}fae/hermes_env/bin/python -m hermes_cli.main`) porque o PM2 tentava executar o script `hermes` (bash) como Node.js.

**PM2 Startup:** Configurado com `pm2 startup systemd -u {{COMMANDER}}fae`. O dump é salvo em `{{COMMANDER_HOME}}fae/.pm2/dump.pm2`. Após reboot, `pm2 resurrect` restaura os processos.

O servidor OVH hospeda a **Sociedade do Anel** (7 agentes) rodando **NATIVAMENTE no host** (PM2 + systemd), sem Docker:

| Agente | Gerenciador | Modo |
|--------|------------|------|
| Aragorn | PM2 | Orquestrador OVH + WhatsApp |
| Celebrimbor | PM2 | Desenvolvimento |
| Galadriel | PM2 | Pesquisa |
| Elrond | PM2 | Infraestrutura |
| Éomer | PM2 | Operações |
| Gandalf | systemd | Estratégia |
| Lirin | systemd | Gateway dedicado |

**:red_circle: NÃO USAR DOCKER para estes agentes.** A tentativa de container `roshar-agents` (docker-compose em `{{COMMANDER_HOME}}fae/hermes-roshar/`) foi um erro de migração — o gateway dentro do container tenta iniciar bridge própria, conflitando com a bridge do host (porta + sessão WhatsApp). O container foi removido em 30/05/2026.

### Profiles (git monorepo)
- **Base:** `{{COMMANDER_HOME}}fae/Dev/hermes-profiles/<agente>/` (git monorepo)
- **Symlink:** `{{COMMANDER_HOME}}fae/.hermes/profiles/<agente>` → `{{COMMANDER_HOME}}fae/Dev/hermes-profiles/<agente>`
- **Sync:** Git push/pull automático via cron (a cada 1h)
- **Hermes CLI:** `{{COMMANDER_HOME}}fae/hermes_env/bin/hermes` (v0.14.0)

### PM2 — 5 agentes (aragorn, celebrimbor, galadriel, elrond, eomer)

**ecosystem.config.js:** `{{COMMANDER_HOME}}fae/ecosystem.config.js` — template completo em `templates/ecosystem.config.js` neste skill.

**:red_circle: PM2 tenta executar scripts com Node.js por padrão.** Usar Python diretamente com `interpreter: 'none'`:

```javascript
{
  name: 'aragorn',
  script: '{{COMMANDER_HOME}}fae/hermes_env/bin/python',
  args: '-m hermes_cli.main --profile aragorn gateway run --replace',
  interpreter: 'none',  // CRÍTICO: sem isto, PM2 executa o bash script como Node.js → SyntaxError
  env: {
    HOME: '{{COMMANDER_HOME}}fae',
    PATH: '{{COMMANDER_HOME}}fae/hermes_env/bin:{{COMMANDER_HOME}}fae/.local/bin:/usr/bin:/bin',
  },
  restart_delay: 10000,
  max_restarts: 20,
  max_memory_restart: '2G',
}
```

**ecosystem.config.js:** `{{COMMANDER_HOME}}fae/ecosystem.config.js` — template completo em `templates/ecosystem.config.js` neste skill.

**:red_circle: PM2 cron NÃO dispara com processo stopped.** Se o processo estiver em `stopped`, o cron restart não inicia. Usar crontab do sistema para tarefas agendadas é mais confiável:

```bash
# Remover do PM2
pm2 delete fechamento-pycode
# Adicionar no crontab
(crontab -l; echo '55 22 * * * /path/to/script.sh >> /path/to/log 2>&1') | crontab -
```

### Processos PM2 ativos

| Nome | Função | Memória típica |
|------|--------|---------------|
| aragorn | Orquestrador + WhatsApp | ~76 MB |
| celebrimbor | Desenvolvimento | ~77 MB |
| galadriel | Pesquisa | ~76 MB |
| elrond | Infraestrutura | ~77 MB |
| eomer | Operações | ~76 MB |
| pycode-blog | Blog Express+EJS | ~100 MB |

### Serviços systemd (user {{COMMANDER}}fae)

| Serviço | Função | Porta | Stack |
|---------|--------|-------|-------|
| `hermes-gandalf` | Agente Gandalf (gateway run) | — | Python/Hermes |
| `hermes-gateway-lirin` | Gateway Hermes do Lirin | — | Hermes CLI |
| `hermes-whatsapp-bridge` | Bridge Baileys — conexão WhatsApp Web | 3000 | Node.js |
| `webhook-whatsapp` | Broker FastAPI — grupo→hoje.md, DM→inbox.md | 8001 | Python |
| `orto-sia` | SIA — Anotação Clínica Streamlit | 8501 | `uv run streamlit` |

**Nota sobre gateways:** Cada agente Hermes inicia seu próprio gateway via `hermes --profile X gateway run --replace` (embutido no ExecStart do PM2/systemd). O gateway conecta nas plataformas configuradas (Slack, WhatsApp) e gerencia a fila de mensagens do agente.

### Serviços systemd (user thaisa) — Equipe Thaísa

| Serviço | Agente | Função |
|---------|--------|--------|
| `hermes-thaisa-jade` | Jade | Orquestradora |
| `hermes-thaisa-babi` | Babi | Saúde |
| `hermes-thaisa-harry` | Harry | Consultório |
| `hermes-thaisa-hermione` | Hermione | Acadêmica |
| `hermes-thaisa-luna` | Luna | Finanças |

**pycode-blog** (25/05/2026): App Express + EJS que substituiu o Quartz como frontend do segundo cérebro. Roda na porta 8080 (herdada do Quartz). Código em `{{COMMANDER_HOME}}/projects/pycode-blog/`. Conteúdo via symlink → `pycode-cerebro/public/content/`. Pipeline WhatsApp → .md preservado. Express com markdown-it + wikilinks plugin + callouts + Prism.js.

**webhook-whatsapp (30/05/2026):** Substituído por systemd + broker FastAPI. O broker (`broker_whatsapp.py`) consome eventos da bridge Hermes Baileys (não mais Evolution) via webhook (`WHATSAPP_WEBHOOK_URL=http://127.0.0.1:8001/webhook`). Roteia mensagens do grupo IA Master Elite (`120363425868389123@g.us`) para `hoje.md` (blog) e mensagens diretas do Comandante (`556799623440`) para `inbox.md`. Roda em `{{COMMANDER_HOME}}fae/projects/pycode-cerebro/scripts/` na porta 8001. Ver `hermes-whatsapp-native` para o formato do evento da bridge.

**webhook-meta:** REMOVIDO (30/05/2026). O número WhatsApp Business da Meta foi migrado para Evolution via Baileys. O webhook FastAPI na porta 8002 foi desligado.

O webhook-whatsapp NÃO é Hermes — é um uvicorn/FastAPI separado (agora systemd, não PM2) em `{{COMMANDER_HOME}}fae/projects/pycode-cerebro/scripts/broker_whatsapp.py` escutando na porta 8001 (única porta exposta via UFW). Roteia mensagens do grupo para `hoje.md` e mensagens diretas do Comandante para `inbox.md`.

O webhook-meta foi REMOVIDO (30/05/2026) — o número Meta Cloud API migrou para Evolution Baileys.

### SIA — Sistema de Análise de Imagens (Streamlit)
- **Código:** `{{COMMANDER_HOME}}/sia_projeto/code/annotator_interface.py`
- **Dados:** `{{COMMANDER_HOME}}/sia_projeto/data/` e `{{COMMANDER_HOME}}/sistema-orto-sia/data/`
- **Serviço:** systemd `orto-sia.service`, user `{{COMMANDER}}`, porta **8501**
- **Autenticação:** senha via `SIA_PASSWORD` env var
- **Pages:** `pages/dashboard.py` + scripts auxiliares (batch_transcribe, extract_frames, generate_embeddings, etc.)

### Dontus Dashboard (Streamlit em Docker)
- **Container:** `dontus-app` (imagem: `oeste-odontologia-dontus-app`, 862 MB)
- **Código:** `/var/www/dontus_app/app.py`
- **Porta interna:** 8502, exposta via nginx em `dashboard.oesteodontologia.com.br`
- **Dependências:** `dontus/client.py` (DontusClient), `dontus/db.py` (SQLite), `dontus/excel.py`
- **Config:** `/var/www/dontus_app/config.yaml` (credenciais Dontus + Evolution API key)

### Estrutura de Diretórios por Profile (Sociedade do Anel)
- **Base:** `{{COMMANDER_HOME}}fae/Dev/hermes-profiles/<agente>/` (git monorepo)
- **Symlink:** `{{COMMANDER_HOME}}fae/.hermes/profiles/<agente>` → `{{COMMANDER_HOME}}fae/Dev/hermes-profiles/<agente>`
- **Sync:** Git push/pull automático via cron (a cada 1h)
- **Hermes CLI:** `{{COMMANDER_HOME}}fae/hermes_env/bin/hermes` (v0.14.0)
- **Legado Docker:** `{{COMMANDER_HOME}}fae/hermes-roshar/` — FOI REMOVIDO em 30/05/2026. O diretório continha docker-compose.yml e Dockerfile do experimento com container. NÃO usar Docker para agentes Hermes no OVH.

**:red_circle: Pitfall de symlink — diretório pré-existente:** Se `{{COMMANDER_HOME}}fae/.hermes/profiles/<agente>` já for um **diretório real** (não symlink), o comando `ln -sf source existing_dir/` cria o symlink **dentro** do diretório, não o substitui. Resultado: dois diretórios divergentes.

**Sintoma:** Edições no arquivo git (`Dev/hermes-profiles/<agente>/.env`) não surtem efeito no agente. `readlink -f` mostra paths diferentes. `.env` tem conteúdo diferente em cada cópia.

**Correção:**
```bash
# Remover o diretório real primeiro
rm -rf {{COMMANDER_HOME}}fae/.hermes/profiles/<agente>
# Depois criar o symlink
ln -sf {{COMMANDER_HOME}}fae/Dev/hermes-profiles/<agente> {{COMMANDER_HOME}}fae/.hermes/profiles/<agente>
```

**Verificar se está correto:**
```bash
readlink -f {{COMMANDER_HOME}}fae/.hermes/profiles/<agente>/.env
readlink -f {{COMMANDER_HOME}}fae/Dev/hermes-profiles/<agente>/.env
# Devem retornar o MESMO path real
```

### ⚠️ Isolamento entre Profiles — Lacuna Crítica (18/05/2026)

**Problema fundamental:** Todos os processos Hermes rodam como UID `{{COMMANDER}}`. O DAC do Linux baseia-se em UID — um processo como `{{COMMANDER}}` pode ler QUALQUER arquivo cujo owner seja `{{COMMANDER}}`, independentemente do `chmod` (600 ou 700 não protegem contra o mesmo UID).

**Permissões verificadas:**
| Arquivo | Permissão | Owner | Legível por outro agente? |
|---------|-----------|-------|--------------------------|
| `.env` | 600 | {{COMMANDER}} | ✅ SIM — mesmo UID |
| `auth.json` | 600 | {{COMMANDER}} | ✅ SIM — mesmo UID |
| `sessions/*.jsonl` | **664** | {{COMMANDER}} | ✅ SIM — world/group readable! |
| `sessions/*.json` | 664 | {{COMMANDER}} | ✅ SIM |
| `memories/MEMORY.md` | 644 | {{COMMANDER}} | ✅ SIM |
| `config.yaml` | 600 | {{COMMANDER}} | ✅ SIM |
| `state.db` | 644 | {{COMMANDER}} | ✅ SIM |
| Global `.env` | 600 | {{COMMANDER}} | ✅ SIM — contém TODOS os tokens |

**Correção imediata (zero esforço):**
```bash
chmod 600 {{COMMANDER_HOME}}/hermes-roshar/profiles/*/sessions/*.jsonl
chmod 600 {{COMMANDER_HOME}}/hermes-roshar/profiles/*/sessions/*.json
```

**Solução real:** Usuário Linux separado por equipe (`noiva-agent`), com home próprio e PM2 rodando como esse user.

### Credenciais
- **Camada 1 — Global:** `{{COMMANDER_HERMES_PATH}}/.env` — variáveis prefixadas para todos os agentes
- **Camada 2 — Profile:** `{{COMMANDER_HOME}}/Dev/hermes-profiles/<agente>/.env` — variáveis sem prefixo
- **ecosystem.config.js:** `{{COMMANDER_HOME}}fae/ecosystem.config.js` — configuração PM2 para os 5 agentes (aragorn, celebrimbor, galadriel, elrond, eomer). Usa Python diretamente com `interpreter: 'none'` (PM2 não sabe executar bash scripts). Ver seção PM2 acima para template.

**OpenCode API Key — Centralização por Grupo:**

O provider `opencode-go` lê `OPENCODE_GO_API_KEY` do `.env` por padrão. **:red_circle: `api_key_env` no config.yaml NÃO funciona com opencode-go (verificado 31/05/2026).** Tentativas com `api_key_env: OPENCODE_GO_DK_KEY` resultam em HTTP 401.

**Método que funciona — `.env` individual por agente com keys agrupadas:**

| Grupo | Agentes | Variável no .env |
|-------|---------|-----------------|
| DK | {{ORCHESTRATOR}} + {{DEVOPS_ENGINEER}} | Ambos têm o mesmo valor em `OPENCODE_GO_API_KEY` |
| SJ | {{FRONTEND_ENGINEER}} + {{AUDITOR}} | Ambos têm o mesmo valor em `OPENCODE_GO_API_KEY` |
| NP | {{BACKEND_ENGINEER}} + {{GIT_OPS}} | Ambos têm o mesmo valor em `OPENCODE_GO_API_KEY` |

**Para rotacionar:** editar o valor nos 2 `.env` do grupo. O `~/.hermes/.env` global mantém as variáveis como referência/backup, mas NÃO são usadas diretamente pelo provider.

**Método que NÃO funciona (não tentar):**
```yaml
model:
  api_key_env: OPENCODE_GO_DK_KEY  # IGNORADO pelo opencode-go
```
```bash
# .env do agente
source ~/.hermes/.env  # NÃO suportado — Hermes não interpreta bash
```

**Evolution API Key:** Persiste em 3 pontos no HOST:
1. `/var/www/oeste-odontologia/.env` → `EVOLUTION_API_KEY`
2. `/var/www/dontus_app/config.yaml` → `evolution_apikey`
3. Container `evolution-api` → `AUTHENTICATION_API_KEY` (injetada via docker-compose env)

**⚠️ Máscara de tokens:** `cat`/`grep` mascaram tokens como `***`. Para verificar o valor real, use `xxd` (hex dump) ou `docker exec evolution-api sh -c 'echo ${#VAR} ${VAR:0:8}...${VAR: -4}'`.

**Versão atual (30/05/2026):** `evoapicloud/evolution-api:2.4.0-rc2`. A tag `homolog` (19/05) tem bug de FK constraint (`Setting_instanceId_fkey`) — NUNCA usar. A `v2.3.7` é mantida apenas para rollback de emergência (imagem ainda em cache). Para atualizar: alterar tag no `docker-compose.yml` → `docker compose pull evolution-api && docker compose up -d evolution-api`.

**Docker compose ativo:** `/var/www/oeste-odontologia/docker-compose.yml`

**WhatsApp:** O Hermes v0.14.0 SUPORTA WhatsApp nativamente via `gateway/platforms/whatsapp.py` e `gateway/whatsapp_identity.py`. **Ativo desde 30/05/2026** — bridge Baileys no host (systemd), gateway do Aragorn no host (PM2), broker FastAPI na porta 8001 (systemd). Fluxo completo:

```\nWhatsApp → Bridge Baileys (host, systemd, :3000, modo bot)\n              ├─→ GET /messages → Gateway Hermes (host, PM2) → Aragorn\n              └─→ POST webhook → Broker FastAPI (:8001) → hoje.md / inbox.md\n```

A bridge NÃO divide número com Evolution — o número foi removido do Evolution antes da migração. Sessão em `{{COMMANDER_HOME}}fae/.hermes/profiles/aragorn/platforms/whatsapp/session/`.

**⚠️ Gateway SEMPRE no HOST, nunca dentro do container:** O gateway Hermes, ao rodar dentro do container `roshar-agents`, tenta iniciar sua própria bridge (conflito de porta + sessão WhatsApp duplicada → timeout 30s). O gateway correto roda no host conectando na bridge do host via `localhost:3000`.

## Cron Jobs (verificados 30/05/2026)

| Schedule | Job | Função |
|----------|-----|--------|
| `* * * * *` | curl status ping (Cloudflare Access) | Health check `status.{{COMMANDER}}fae.com.br` |
| `0 6 * * 0` | `sync-weekly-backup.sh` | Backup semanal hermes-config + vault |
| `30 * * * *` | git pull/push `hermes-profiles` | Sync profiles a cada 1h |
| `15,45 * * * *` | git pull/push `obsidian` | Sync vault a cada 30min |
| `55 22 * * *` | `fechamento_diario.sh` (crontab, NÃO PM2) | Sintetiza resumo + rotaciona `hoje.md` + restart blog |

## Rede Docker (30/05/2026)
- **Rede principal:** `oeste-odontologia_oeste-network` (bridge `172.18.0.0/16`)
- **Gateway (host view):** `172.18.0.1`
- **Redes legadas:** `vps-config_oeste-network` (172.20.0.0/16, DOWN), `oeste-odontologia_default` (172.19.0.0/16, DOWN)
- **Container IPs:** evolution-api: `172.18.0.4:8080`, dontus-app: porta 8502, oeste-odontologia-app: porta 3000
- **Nginx:** Único container com port binding (`0.0.0.0:80→80`)

## Superfície de Ataque (atualizada 30/05/2026)
| Vetor | Status |
|-------|--------|
| SSH (força bruta) | Descartado — Cloudflare Access + chave |
| IDEs (hooks Claude/VS Code) | Descartado — servidor headless, diretórios `~/.claude/` e `~/.vscode/` INEXISTENTES |
| Webhook Evolution | ✅ Interno confirmado (Docker bridge, sem port binding) |
| Máquina local do {{COMMANDER}} | :red_circle: **VETOR CONFIRMADO** — extensões VS Code (`github.copilot-chat`, `ms-vscode-remote.remote-ssh`) |
| Cloudflare bypass | Descartado |
| Dependências Python (supply chain) | Pendente — 54 dependências não verificadas |
| Código-fonte Hermes | Pendente — varredura não concluída |
| **roshar-agents host network** | :white_check_mark: **MITIGADO 30/05** — container Docker removido. Agentes rodam nativos (PM2+systemd). |
| **Cross-profile data leak (sessions 664)** | :warning: Mitigado — correção `chmod 600` aplicada em 18/05 |
| **Cross-profile credential leak (mesmo UID)** | :warning: Todos os agentes Hermes rodam como UID `{{COMMANDER}}fae`. Arquivos com permissão 600 são legíveis entre agentes do mesmo UID (DAC do Linux). |
| **ecosystem.config.js plaintext tokens** | :yellow_circle: **LEGADO** — Radiantes não rodam mais no OVH, mas arquivo persiste com 6 tokens Slack em plaintext |
| **Global .env multi-token** | :red_circle: **CONFIRMADO** — `{{COMMANDER_HERMES_PATH}}/.env` (2593 bytes) contém múltiplos tokens |
| **PM2 gerenciamento cross-team** | :warning: Um agente pode `pm2 stop/restart` processos de outros profiles |
| **Terminal toolset irrestrito** | :warning: `persistent_shell: true` + sem `command_allowlist` → acesso total ao filesystem |

## Playbook de Migração OVH → OVH

### Pitfall Crítico: `.venv` corrompido após rsync

Ao copiar projetos Python entre servidores com `rsync`, os diretórios `.venv/` contêm paths
hardcoded no script `bin/activate` (variável `VIRTUAL_ENV`). Se o nome do usuário mudar
(ex: `{{COMMANDER}}` → `{{COMMANDER}}fae`), o venv fica quebrado silenciosamente — imports falham mesmo
com `pip`/`uv` reportando pacotes instalados.

**Sintoma:** `ModuleNotFoundError: No module named 'fastapi'` mesmo com o pacote instalado.

**Diagnóstico:**
```bash
source .venv/bin/activate
echo $VIRTUAL_ENV   # Se apontar pro path antigo, está quebrado
```

**Solução:** Excluir `.venv` do rsync (`--exclude='.venv'`) e recriar no destino:
```bash
uv venv --python 3.12
uv sync
```

### Checklist de Migração — Itens Facilmente Esquecidos

Histórico de itens que foram esquecidos na migração 30/05/2026 e tiveram que ser resgatados:

| # | Item | Tamanho | Resgate |
|---|------|---------|---------|
| 1 | `pycode-cerebro/data/historico/` (20+ arquivos `grupo_*.md`) | 808 KB | `tar` + pipe SSH |
| 2 | `sync-weekly-backup.sh` | 2.5 KB | Copiado + paths atualizados |
| 3 | `projects/obsidian/` (vault P.A.R.A.) | 2.1 MB | `tar` + pipe SSH |
| 4 | PM2 startup (`pm2 startup systemd`) | — | Reconfigurado |
| 5 | `hermes_files/` (workspace dos Radiantes) | 168 KB | `tar` + pipe SSH |
| 6 | Powerlevel10k (tema oh-my-zsh) | — | `git clone` + `.p10k.zsh` copiado |

### Outros Pitfalls de Migração

1. **PM2 cron não dispara com processo `stopped`:** O `fechamento-pycode` com `cron restart: 55 22 * * *` NUNCA disparou porque o processo PM2 estava `stopped`. PM2 cron só funciona com processo `online`. Migrar scripts agendados para crontab do sistema (`crontab -e`).

2. **Container `roshar-agents` criado por engano:** A migração Docker criou o container `roshar-agents` que NUNCA existiu no servidor antigo. Os agentes da Sociedade do Anel rodavam nativos (PM2 + systemd). Removido e substituído pela configuração correta.

3. **Hostname veio como `ns509999`:** Alterado para `oesteodontologia.com.br` via `hostnamectl set-hostname` + atualização do `/etc/hosts`.

4. **Symlinks vs diretórios reais em `~/.hermes/profiles/`:** Se o diretório já existir, `ln -sf source target/` cria o symlink DENTRO do diretório, não substitui. Remover o diretório primeiro, depois criar symlink.

### Pitfall: SSH config com blocos órfãos

Ao editar o `~/.ssh/config`, linhas de um bloco `Host` que ficam sem o cabeçalho viram
configurações GLOBAIS. Ex: `User {{COMMANDER}}` sem estar dentro de um bloco `Host` aplica-se
a TODAS as conexões SSH, sobrescrevendo `User` de outros blocos.

**Sintoma:** `ssh -v` mostra `Authenticating as '{{COMMANDER}}'` mesmo com `User {{COMMANDER}}fae` no bloco.

**Correção:** Comentar ou remover linhas órfãs. Verificar com `grep -n "User " ~/.ssh/config`.

### Cloudflare Tunnel — Rotas gerenciadas remotamente

O arquivo `/etc/cloudflared/config.yml` local é IGNORADO para hostnames após o primeiro
registro do túnel. As rotas reais vêm do **Cloudflare Zero Trust dashboard**
(Networks → Tunnels → Edit → Public Hostnames).

**Verificar rotas reais:**
```bash
sudo journalctl -u cloudflared | grep "config=" | tail -1
```

**Adicionar rota:** SEMPRE pelo dashboard. O `config.yml` local serve apenas como
documentação de referência. Rotas adicionadas apenas no arquivo local são
sobrescritas na próxima atualização remota.

### Sistema de arquivos — Atualizado 30/05/2026

O terminal do Hermes aplica filtro de segurança que mascara padrões de token no output. `cat` mostra `***` para strings como `xoxb-`, `xapp-`, `sk-or-`. Isto NÃO significa placeholder — o token está lá, mas o filtro esconde.

### Como verificar token real vs placeholder

| Método | Confiabilidade |
|--------|---------------|
| Hex dump (`xxd`) | Definitivo — bytes hex não mentem |
| Tamanho do arquivo (`stat -c '%s'`) | Placeholder ~3 bytes; token real 50+ |
| `cat` simples | Inútil — sempre mostra `***` |

### Regras
- NUNCA editar credenciais via script/echo — risco de corrupção. Usar nano/vim ou write_file com conteúdo completo.
- Antes de reportar "token ausente", verificar com hex dump. Economizou horas em 19/05/2026 (equipe Thaísa).

## Auditoria de Migração — Checklist Pós-Migração

Após migrar entre servidores OVH, verificar CADA um destes itens. A omissão de qualquer um causa perda de funcionalidade:

| # | Item | Comando verificação | Falha comum |
|---|------|---------------------|-------------|
| 1 | PM2 processos | `pm2 list` | Agentes parados, ecosystem desatualizado |
| 2 | PM2 startup | `systemctl is-enabled pm2-<user>` | Não sobrevive a reboot |
| 3 | PM2 cron jobs | `pm2 show <nome>` | Cron não dispara se status=stopped |
| 4 | systemd services | `systemctl list-units \| grep hermes` | Serviços masked ou missing |
| 5 | Crontab | `crontab -l` | Jobs apontando para paths antigos |
| 6 | Docker containers | `docker ps` | Container roshar-agents indevido |
| 7 | Symlinks profiles | `ls -la ~/.hermes/profiles/` | Diretório real em vez de symlink |
| 8 | Dados históricos | `ls ~/projects/pycode-cerebro/data/historico/` | `grupo_*.md` não copiados |
| 9 | Scripts de síntese | `ls ~/projects/pycode-cerebro/scripts/` | `sintetizador.py`, `fechamento_diario.sh` |
| 10 | Obsidian vault | `ls ~/projects/obsidian/` | Vault não migrado |
| 11 | Scripts custom | `ls ~/scripts/` | `sync-weekly-backup.sh` não copiado |
| 12 | UFW | `sudo ufw status` | Regras faltando |
| 13 | Hostname | `hostnamectl` | Ainda com nome padrão OVH |

### Pitfall: PM2 cron não dispara com status=stopped

O PM2 cron restart (`--cron '55 22 * * *'`) só executa se o processo estiver `online`. Se estiver `stopped`, o cron NÃO dispara. Para scripts pontuais (fechamento diário), usar **crontab do sistema**:

```bash
# Remover do PM2
pm2 delete fechamento-pycode

# Adicionar no crontab
(crontab -l 2>/dev/null; echo '55 22 * * * /path/script.sh >> /path/log 2>&1') | crontab -
```

### Pitfall: Symlink vs diretório real em ~/.hermes/profiles/

Se o diretório já existe, `ln -sf` cria o symlink DENTRO dele, não o substitui. Para corrigir:

```bash
rm -rf ~/.hermes/profiles/<agent>
ln -sf ~/Dev/hermes-profiles/<agent> ~/.hermes/profiles/<agent>
```

Depois corrigir ownership: `sudo chown -R <user>:<user> ~/Dev/hermes-profiles/<agent>` (arquivos criados por root em Docker precisam disso).

## {{PROJECT_NAME}} — Dev Environment (01/06/2026)

Ver `references/{{PROJECT_SLUG}}-ovh-dev.md` para setup completo do ambiente Django + Docker na OVH.

### :red_circle: Auditoria Mac→OVH — Pitfall de Sync (02/06/2026)

Agentes Mac ({{BACKEND_ENGINEER}}, {{GIT_OPS}}, {{DEVOPS_ENGINEER}}, {{FRONTEND_ENGINEER}}, {{AUDITOR}}) fazem push para o GitHub. O OVH **não recebe automaticamente** — precisa de `git pull` explícito. Ao auditar trabalho feito por agentes Mac:

1. **SEMPRE executar `git pull origin develop` no OVH antes de verificar artefatos**
2. Verificar com `git log --oneline -5` se o commit está presente
3. Só então validar arquivos com `ls`/`wc -c`/`grep`

**Sintoma de falso negativo:** Commit reportado pelo agente não aparece no `git log` do OVH, arquivos esperados não existem. Causa: OVH está N commits atrás do GitHub. **Nunca declarar task como não concluída antes de fazer `git pull`.**

**Caso real (02/06/2026):** {{BACKEND_ENGINEER}} reportou commit `6962a8e`. {{ORCHESTRATOR}} auditou OVH, commit não encontrado, declarou task não concluída. {{BACKEND_ENGINEER}} corrigiu: commit estava no GitHub, OVH estava 8 commits atrás (`023aa19` vs `d68c64d`). Bastou `git pull` para resolver. O push original do Mac M4 estava correto.

### :red_circle: Git Identity no OVH — Não Configurada Globalmente

O OVH não tem `user.name` e `user.email` configurados no git global. Comandos como `git commit` e `git rebase --continue` falham com `Author identity unknown` / `empty ident name`.

**Workaround:** Configurar no repositório ou inline:
```bash
git config user.name '{{ORCHESTRATOR}} Kholin'
git config user.email 'dalinar@oesteodontologia.com.br'
# ou inline:
git -c user.name='Nome' -c user.email='email' commit -m '...'
```

**Solução permanente (requer root/ {{COMMANDER}}):**
```bash
git config --global user.name '{{COMMANDER_NAME}}'
git config --global user.email '{{COMMANDER}}@oesteodontologia.com.br'
```

## Docker + Django + uv — Pitfalls

Ver `references/docker-django-uv-pitfalls.md` para armadilhas de build (command: override, uv sync, FIELD_ENCRYPTION_KEY).

## WhatsApp Bridge (Evolution → Blog + Inbox)

Em 30/05/2026, o webhook-whatsapp foi migrado do PM2 para systemd e atualizado para um **broker** que roteia mensagens por origem:

| Origem | JID | Destino |
|---|---|---|
| Grupo IA Master Elite | `120363425868389123@g.us` | `hoje.md` (blog) |
| Comandante (direta) | `556799623440@s.whatsapp.net` | `inbox.md` + API `/send` |

**Código:** `{{COMMANDER_HOME}}fae/projects/pycode-cerebro/scripts/broker_whatsapp.py`
**Serviço:** `webhook-whatsapp.service` (systemd, porta 8001)
**API agentes:** `GET /send?number=X&text=Y` — envia WhatsApp | `GET /inbox` — lê mensagens

Ver `diagnostico-evolution-api` → `references/evolution-broker-pattern.md`.

### ⚠️ Pitfall de Migração: .venv com paths hardcoded

### :red_circle: CRÍTICO: `read_file` output NUNCA deve ser usado como conteúdo para `write_file`/`patch`

O `read_file` do Hermes formata a saída com números de linha (ex: `     1|model:`). Se este output for usado como `content` para `write_file` ou `old_string` para `patch`, os números de linha viram texto LITERAL no arquivo, corrompendo-o.

**Sintoma:** Arquivo YAML/Python/JS com linhas como `     1|model:` e `    10|     9|  bot_user_name` (numeração aninhada).

**Solução:** Usar `terminal` com `cat` para obter conteúdo limpo, ou `read_file` apenas para inspeção visual. NUNCA pipe de `read_file` → `write_file`.

**Recuperação:** Se o arquivo foi corrompido e não há git, reescrever a partir de um template limpo ou de um backup. O `git checkout -- <file>` reverte se o repo tem git.

### ⚠️ `approvals.mode: auto` — Configuração Global

Para eliminar pedidos de aprovação em comandos de leitura/escrita, configurar em TODOS os agentes:

```yaml
approvals:
  mode: auto
  timeout: 60
```

Isso evita que cada `cat`, `grep`, `ls` peça confirmação. A safety net é o protocolo de lockdown (o {{COMMANDER}} pode parar tudo a qualquer momento).

Ao fazer rsync de `.venv` entre servidores com home directories diferentes (`{{COMMANDER_HOME}}/` → `{{COMMANDER_HOME}}fae/`), o `VIRTUAL_ENV` no script `activate` fica com o path antigo. O venv parece funcionar (Python inicia) mas `pip install` e imports falham silenciosamente.

**Solução:** SEMPRE recriar o `.venv` com `uv venv --python 3.12 && uv sync` após migração. NUNCA confiar em venv rsyncado.

### ⚠️ Pitfall: read_file corrompe arquivos se usado como fonte para edição

O `read_file` adiciona números de linha (`     1|...`). Se este output for usado como `old_string` no `patch` ou `content` no `write_file`, os números viram texto literal, corrompendo o arquivo. **Sempre use `terminal("cat ...")` para ler conteúdo bruto** antes de editar. Ver `references/pitfall-read_file-corruption.md` para recuperação.

### Pitfall de Migração: Arquivos com owner root do Docker

Se o projeto usava container Docker com bind mounts (ex: `roshar-agents`), arquivos criados **dentro** do container pertencem a `root` no host (UID 0). Após remover o container e rodar o agente nativo (PM2/systemd como `{{COMMANDER}}fae`), esses arquivos causam `PermissionError`.

**Sintoma:** `PermissionError: [Errno 13] Permission denied: '{{COMMANDER_HOME}}fae/.hermes/profiles/aragorn/logs/gateway.log'`

**Diagnóstico:**
```bash
find {{COMMANDER_HOME}}fae/Dev/hermes-profiles/<agente> -user root -type f | head -10
```

**Correção:**
```bash
sudo chown -R {{COMMANDER}}fae:{{COMMANDER}}fae {{COMMANDER_HOME}}fae/Dev/hermes-profiles/<agente>
```

Afeta especialmente `logs/`, `checkpoints/`, `skills/`, `.clean_shutdown`, e `channel_directory.json` — todos potencialmente criados pelo gateway dentro do container.

### Pitfall de Migração: `pycode-cerebro/data/historico/` não migrado

O diretório `{{COMMANDER_HOME}}/projects/pycode-cerebro/data/historico/` contém:
- `hoje.md` — mensagens do dia atual (grupo IA Master Elite)
- `grupo_<data>.md` — backups diários (ex: `grupo_29-05-2026.md`)
- `inbox.md` — mensagens diretas do Comandante

**Este diretório NÃO está dentro do git nem do Docker — é puro runtime de dados.** Na migração OVH→OVH, ele precisa ser copiado explicitamente. Sem ele, o blog perde TODO o histórico de conversas e não gera resumos de dias anteriores.

**Verificar:**
```bash
ls {{COMMANDER_HOME}}fae/projects/pycode-cerebro/data/historico/
# Deve conter grupo_*.md para cada dia desde a criação do blog
du -sh {{COMMANDER_HOME}}fae/projects/pycode-cerebro/data/historico/
# ~808 KB com histórico completo
```

**Transferir do servidor antigo:**
```bash
rsync -avz {{COMMANDER}}fae@51.77.219.105:{{COMMANDER_HOME}}/projects/pycode-cerebro/data/historico/ \
      {{COMMANDER_HOME}}fae/projects/pycode-cerebro/data/historico/
```
