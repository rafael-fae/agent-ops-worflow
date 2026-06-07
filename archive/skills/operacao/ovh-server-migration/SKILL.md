---
name: ovh-server-migration
description: Procedimento completo para migrar toda a infraestrutura entre servidores OVH — preparação, transferência de dados via OVH-to-OVH, Docker, PM2, systemd, Cloudflare Tunnel switch, e verificação pós-migração.
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Migração de Servidor OVH — Procedimento Completo

## Gatilho
- {{COMMANDER}} adquire um novo servidor OVH e quer migrar toda a infraestrutura
- Substituição de servidor antigo por novo (hardware, upgrade de recursos)
- O novo servidor está limpo (Ubuntu Server recém-instalado)

## Estratégia Geral

A migração usa **Cloudflare Tunnel como ponto de switch**. Ambos os servidores compartilham o mesmo Tunnel ID e credenciais. O switch consiste em parar o cloudflared no antigo e iniciar no novo — tráfego migra em ~30 segundos sem alteração de DNS.

### Ordem das Fases
1. **Fase 0** — Preparar novo servidor (usuários, pacotes, ferramentas)
2. **Fase 1** — Transferir dados (rsync OVH→OVH)
3. **Fase 2** — Migrar Docker (compose, volumes, imagens)
4. **Fase 3** — Configurar serviços host (PM2, systemd, cron)
5. **Fase 4** — Switch do Cloudflare Tunnel + testes
6. **Fase 5** — Equipes secundárias (Thaísa, etc.)

---

## Fase 0 — Preparação do Novo Servidor

### 0.1 Conectar e criar usuário principal

```bash
# Conectar como ubuntu (usuário padrão OVH)
ssh ubuntu@<NOVO_IP>

# Criar usuário com sudo (NUNCA usar '{{COMMANDER}}' — usar '{{COMMANDER}}fae' para distinguir)
sudo useradd -m -s /bin/bash -G sudo {{COMMANDER}}fae
echo '{{COMMANDER}}fae:TempPass2026!Migrate' | sudo chpasswd
sudo mkdir -p {{COMMANDER_HOME}}fae/.ssh
sudo chmod 700 {{COMMANDER_HOME}}fae/.ssh
```

### 0.2 Copiar chaves SSH

```bash
# Do servidor antigo:
cat {{COMMANDER_HOME}}/.ssh/authorized_keys | ssh ubuntu@<NOVO_IP> \
  "sudo tee -a {{COMMANDER_HOME}}fae/.ssh/authorized_keys"
sudo chmod 600 {{COMMANDER_HOME}}fae/.ssh/authorized_keys
sudo chown -R {{COMMANDER}}fae:{{COMMANDER}}fae {{COMMANDER_HOME}}fae/.ssh
```

### 0.3 Instalar pacotes base

```bash
sudo apt update && sudo apt install -y zsh tree htop jq tmux neofetch \
  ncdu btop mosh fd-find ripgrep bat fzf unzip build-essential \
  zsh-autosuggestions zsh-syntax-highlighting eza

# Node.js 22
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs

# PM2
sudo npm install -g pm2@7.0.1

# Docker
sudo apt install -y docker.io docker-compose-v2
sudo systemctl enable --now docker
sudo usermod -aG docker {{COMMANDER}}fae

# cloudflared
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
  -o /tmp/cloudflared
sudo mv /tmp/cloudflared /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared

# uv (Python)
curl -LsSf https://astral.sh/uv/install.sh | sudo -E sh
```

### 0.4 Instalar ferramentas CLI

```bash
# Gemini CLI
sudo npm install -g @google/gemini-cli@0.43.0

# ZSH + oh-my-zsh para o usuário {{COMMANDER}}fae
sudo -u {{COMMANDER}}fae sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
sudo chsh -s /usr/bin/zsh {{COMMANDER}}fae

# Powerlevel10k
sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /usr/share/powerlevel10k
```

### 0.5 Configurar UFW

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 8001/tcp
sudo ufw allow from 172.18.0.0/16 to any port 8002 proto tcp
sudo ufw allow 22/tcp
sudo ufw --force enable
```

### 0.6 Configurar timezone

```bash
sudo timedatectl set-timezone America/Cuiaba
```

---

## Fase 1 — Transferência de Dados

### :red_circle: PITFALL: Transferência do Mac é lenta

Transferir arquivos da máquina local do {{COMMANDER}} para o servidor OVH via SCP pode levar vários minutos para arquivos grandes (ex: binário OpenCode de 138 MB levou +120s). **SEMPRE usar transferência OVH→OVH direta** — a rede interna da OVH atinge 30 MB/s.

### 1.1 Criar chave SSH de migração (sem passphrase)

A chave SSH padrão do servidor antigo pode ter passphrase, bloqueando automação. Criar uma chave dedicada sem passphrase:

```bash
# NO SERVIDOR ANTIGO:
ssh-keygen -t ed25519 -f {{COMMANDER_HOME}}/.ssh/id_ed25519_migrate -N '' -C 'migration-key'
cat {{COMMANDER_HOME}}/.ssh/id_ed25519_migrate.pub
# Copiar a chave pública para o autorized_keys do NOVO SERVIDOR

# Adicionar ao ~/.ssh/config no SERVIDOR ANTIGO:
# Host new-ovh
#   HostName <NOVO_IP>
#   User {{COMMANDER}}fae
#   IdentityFile ~/.ssh/id_ed25519_migrate
#   IdentitiesOnly yes
#   StrictHostKeyChecking accept-new
```

### 1.2 Rsync com exclusões adequadas

**:warning: NUNCA transferir .venv, node_modules ou __pycache__.** Recriar ambientes virtualizados no destino.

```bash
# Do servidor antigo:
rsync -avz \
  --exclude='.venv' \
  --exclude='__pycache__' \
  --exclude='*.pyc' \
  --exclude='node_modules' \
  {{COMMANDER_HOME}}/<projeto>/ new-ovh:{{COMMANDER_HOME}}fae/<projeto>/
```

### 1.3 Ordem de transferência (menor → maior)

1. Diretórios pequenos primeiro: `/var/www/`, `pycode-blog`, `pycode-cerebro`
2. Diretórios médios: `dontus_app`, `hermes-roshar`, `hermes-profiles`
3. Diretórios grandes por último: SIA (13 GB), dados de mídia

### 1.4 OpenCode CLI — Instalação correta

O OpenCode CLI é um binário Go standalone (~145 MB), NÃO um pacote npm. O pacote npm `@opencode-ai/plugin` contém apenas a SDK Node.js, não o binário CLI.

```bash
# CORRETO: transferir o binário do servidor antigo
rsync -avz {{COMMANDER_HOME}}/.opencode/bin/opencode new-ovh:{{COMMANDER_HOME}}fae/.opencode/bin/opencode
chmod +x {{COMMANDER_HOME}}fae/.opencode/bin/opencode
```

**:x: NUNCA:** tentar instalar via `npm install @opencode-ai/plugin` esperando obter o CLI.

---

## Fase 2 — Migrar Docker

### 2.1 Estratégia para volumes com containers rodando

Copiar volumes Docker com containers em execução corrompe dados. Opções:

| Abordagem | Risco | Quando usar |
|-----------|-------|-------------|
| `docker compose stop` → rsync volumes → `docker compose up` | Downtime de ~2 min | Migração planejada |
| `docker exec ... pg_dump` / `mysqldump` → restore no novo | Zero downtime no antigo | Migração com serviço ativo |
| `docker commit` → `docker save` → `docker load` | Imagens grandes | Quando não é possível rebuild |

### 2.2 Procedimento com stop

```bash
# NO SERVIDOR ANTIGO:
cd /var/www/oeste-odontologia
docker compose stop
rsync -avz /var/lib/docker/volumes/oeste-odontologia_* new-ovh:/var/lib/docker/volumes/
docker compose up -d  # voltar a rodar imediatamente
```

### 2.3 Docker Compose no novo servidor

```bash
# NO NOVO SERVIDOR:
cd /var/www/oeste-odontologia
docker compose pull
docker compose up -d evolution-postgres evolution-redis  # primeiro DBs
sleep 10
docker compose up -d  # depois o resto
```

---

## Fase 3 — Serviços Host

### 3.1 PM2

```bash
# IMPORTANTE: SEMPRE especificar --cwd para evitar que o PM2 herde o cwd errado
# O cwd padrão do PM2 é o diretório onde 'pm2 start' foi executado

# Configurar pycode-blog na porta 8080
cd {{COMMANDER_HOME}}fae/projects/pycode-blog
npm install
PORT=8080 NODE_ENV=production pm2 start server.js --name pycode-blog --cwd {{COMMANDER_HOME}}fae/projects/pycode-blog

# Webhooks (Python FastAPI — precisam de venv com fastapi/uvicorn)
cd {{COMMANDER_HOME}}fae/projects/pycode-cerebro/scripts
source .venv/bin/activate
uv pip install fastapi uvicorn
PORT=8001 pm2 start receptor_whatsapp.py --name webhook-whatsapp \
  --interpreter {{COMMANDER_HOME}}fae/projects/pycode-cerebro/scripts/.venv/bin/python3 \
  --cwd {{COMMANDER_HOME}}fae/projects/pycode-cerebro/scripts

# Meta webhook (precisa também de python-dotenv)
cd {{COMMANDER_HOME}}fae/projects/meta-webhook
uv venv && source .venv/bin/activate
uv pip install fastapi uvicorn python-dotenv
PORT=8002 pm2 start webhook_meta.py --name webhook-meta \
  --interpreter {{COMMANDER_HOME}}fae/projects/meta-webhook/.venv/bin/python3 \
  --cwd {{COMMANDER_HOME}}fae/projects/meta-webhook

# Salvar e configurar autostart
pm2 save
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u {{COMMANDER}}fae --hp {{COMMANDER_HOME}}fae

# :warning: Verificar cwd após start:
pm2 show webhook-whatsapp | grep 'exec cwd'
# Deve mostrar o diretório correto do script, nunca outro projeto
```

### 3.2 Systemd (SIA)

```bash
sudo tee /etc/systemd/system/orto-sia.service << 'EOF'
[Unit]
Description=Streamlit App - Sistema Orto SIA
After=network.target

[Service]
User={{COMMANDER}}fae
WorkingDirectory={{COMMANDER_HOME}}fae/sia_projeto
ExecStart={{COMMANDER_HOME}}fae/.local/bin/uv run streamlit run code/annotator_interface.py --server.port 8501 --server.headless true
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
# NÃO iniciar ainda — aguardar switch do túnel
```

### 3.3 Cron

Copiar os mesmos cron jobs do servidor antigo:
- Status ping (1 min)
- Backup semanal (Domingo 6h)
- Git sync profiles (1h)
- Git sync vault (30 min)

---

## Fase 4 — Switch do Cloudflare Tunnel

### :red_circle: MOMENTO CRÍTICO

O switch causa downtime de ~30 segundos em todos os subdomínios. Fazer em horário de baixo tráfego.

### 4.1 Configurar cloudflared no novo servidor

Copiar `/etc/cloudflared/credentials.json` e `/etc/cloudflared/config.yml` do servidor antigo.
**NÃO iniciar o serviço ainda.**

### 4.2 Procedimento de switch

```bash
# 1. NO SERVIDOR ANTIGO:
sudo systemctl stop cloudflared
# Verificar que parou: sudo systemctl status cloudflared

# 2. NO NOVO SERVIDOR (imediatamente após):
sudo systemctl enable --now cloudflared
# Verificar que subiu: sudo journalctl -u cloudflared -f

# 3. Testar subdomínios:
curl -sI https://oesteodontologia.com.br/ | head -3
curl -sI https://evolution.oesteodontologia.com.br/ | head -3
curl -sI https://dashboard.oesteodontologia.com.br/ | head -3
curl -sI https://{{BLOG_URL}}/ | head -3

# 4. Se algo falhar, rollback imediato:
# NO NOVO: sudo systemctl stop cloudflared
# NO ANTIGO: sudo systemctl start cloudflared
```

### 4.3 Rollback

O rollback é instantâneo — basta inverter o procedimento acima. Sem alteração de DNS, sem propagação.

---

## Fase 5 — Equipes Secundárias (Thaísa)

### 5.1 Criar usuário e copiar ambiente

```bash
sudo useradd -m -s /bin/bash -G docker thaisa
sudo mkdir -p /home/thaisa/.ssh && sudo chmod 700 /home/thaisa/.ssh

# Copiar todo o /home/thaisa/ do servidor antigo
rsync -avz --exclude='.venv' --exclude='__pycache__' \
  /home/thaisa/ new-thaisa:/home/thaisa/

# Recriar venv do Hermes
sudo -u thaisa uv venv /home/thaisa/hermes_env --python 3.12
sudo -u thaisa uv pip install hermes-agent==0.14.0
```

### 5.2 Copiar serviços systemd

Copiar os 5 serviços `hermes-thaisa-*.service` do servidor antigo, ajustando paths de `{{COMMANDER}}` → `{{COMMANDER}}fae` onde necessário.

---

## Verificação Pós-Migração

```bash
# Docker
docker ps --format "table {{.Names}}\t{{.Status}}"

# PM2
pm2 status

# Systemd
systemctl is-active cloudflared orto-sia

# Portas
ss -tlnp | grep -E '80|3000|8001|8002|8080|8501|8502'

# Cloudflare
curl -sI https://oesteodontologia.com.br/ | grep -E 'HTTP|cf-cache'
```

### :red_circle: Auditoria Pós-Migração (OBRIGATÓRIA)

Após a migração, executar auditoria COMPLETA comparando servidor antigo vs novo. Itens que frequentemente são esquecidos:

1. **PM2**: Comparar `pm2 list` nos dois servidores. Verificar se TODOS os processos foram migrados.
2. **Systemd**: `systemctl list-units --all | grep hermes` — comparar timers ativos.
3. **Cron**: `crontab -l` nos dois servidores. Verificar cada job.
4. **Docker**: `docker ps` + `docker images` — comparar containers e imagens.
5. **Diretórios**: Conferir `~/projects/`, `~/Dev/`, `/var/www/` entre os servidores.
6. **Scripts**: `~/scripts/` — especialmente scripts de backup e fechamento diário.
7. **Dados históricos**: Verificar se `data/historico/` (pycode-cerebro) foi copiado com todos os `grupo_*.md`.
8. **PM2 startup**: Executar `pm2 save` e `pm2 startup systemd` no novo servidor.

### :red_circle: Hermes Agents — NUNCA em Docker Container

Os agentes Hermes da Sociedade do Anel (Aragorn, Celebrimbor, Galadriel, Elrond, Éomer, Gandalf, Lirin) rodam NATIVOS no host:
- **PM2**: Aragorn, Celebrimbor, Galadriel, Elrond, Éomer
- **Systemd**: Gandalf, Lirin

**O container `roshar-agents` foi um erro de migração.** Se existir, deve ser removido:
```bash
docker compose down  # em ~/hermes-roshar/
docker stop roshar-agents
docker rm roshar-agents
```

Os profiles devem usar symlinks: `~/.hermes/profiles/<agent>` → `~/Dev/hermes-profiles/<agent>`

---

## Path Migration — `{{COMMANDER_HOME}}/` → `{{COMMANDER_HOME}}fae/`

Ao migrar com nome de usuário diferente, **TODOS** os arquivos que contêm paths hardcoded precisam ser corrigidos. Falhar nisso causa erros silenciosos (arquivos escritos em paths errados, PermissionError, dados perdidos).

### Arquivos que tipicamente precisam de substituição

| Arquivo | Path hardcoded | Sintoma se não corrigir |
|---------|---------------|------------------------|
| `.env.meta` | `LOG_DIR={{COMMANDER_HOME}}/...` | PermissionError ao tentar criar log |
| `receptor_whatsapp.py` | `ARQUIVO_HOJE = "{{COMMANDER_HOME}}/..."` | Mensagens salvas no path errado |
| `webhook_meta.py` | Paths de data directory | Webhook não registra eventos |
| `ecosystem.config.js` | Paths nos `script:` e `env:` | PM2 não encontra binários |
| systemd services | `WorkingDirectory=`, `ExecStart=` | Serviços não iniciam |
| `.env` (Docker) | Volume paths, connection strings | Containers não conectam |

### Procedimento de substituição

```bash
# No novo servidor, corrigir paths em todos os arquivos relevantes
sudo -u {{COMMANDER}}fae find {{COMMANDER_HOME}}fae -type f \( -name '*.py' -o -name '*.env' -o -name '*.js' -o -name '*.yaml' -o -name '*.yml' -o -name '*.sh' -o -name '*.service' -o -name '*.json' \) -exec grep -l '{{COMMANDER_HOME}}/' {} \; 2>/dev/null | while read f; do
    sudo -u {{COMMANDER}}fae sed -i 's|{{COMMANDER_HOME}}/|{{COMMANDER_HOME}}fae/|g' "$f"
done

# Verificar se restou algum:
sudo -u {{COMMANDER}}fae grep -r '{{COMMANDER_HOME}}/' {{COMMANDER_HOME}}fae/projects/ /var/www/ 2>/dev/null | grep -v '.git/' | grep -v 'node_modules'
```

### :red_circle: CUIDADO
- NUNCA aplicar sed em arquivos binários ou .git/
- NUNCA substituir em paths que referenciam outrem (ex: `/home/thaisa/` não deve ser alterado)
- Revisar manualmente arquivos de config que contêm placeholders

### Subdomínios do Cloudflare Tunnel — Roteamento via Nginx

O Cloudflare Tunnel roteia tráfego para `localhost:80` (nginx). O nginx então faz proxy para os serviços internos baseado no `Host` header. Subdomínios que NÃO passam pelo nginx (ex: `{{BLOG_URL}}` na porta 8080) precisam de rota explícita no Cloudflare Zero Trust dashboard — a config local (`/etc/cloudflared/config.yml`) é apenas referência, as rotas reais são definidas remotamente.

Subdomínios configurados:
| Subdomínio | Tunnel → | Nginx → |
|---|---|---|
| `oesteodontologia.com.br` / `www` | `localhost:80` | `app:3000` |
| `dashboard.oesteodontologia.com.br` | `localhost:80` | `dontus-app:8502` |
| `evolution.oesteodontologia.com.br` | `localhost:80` | `evolution-api:8080` |
| `webhook.oesteodontologia.com.br` | `localhost:80` | `/webhook/meta` → `host:8002` |
| `ssh.oesteodontologia.com.br` | `ssh://localhost:22` | (não passa pelo nginx) |
| `{{BLOG_URL}}` | `localhost:8080` | (direto, sem nginx) |

### Evolution API — License Re-activation Pós-Migração

Após migrar o banco PostgreSQL para novo hardware, o `instance_id` da Evolution API muda. A API retorna `LICENSE_REQUIRED` em todos os endpoints (exceto `/manager/login`). A licença anterior é invalidada.

A re-ativação requer acesso browser ao `https://evolution.oesteodontologia.com.br/manager/login` com conta Google. Isso **só funciona após o switch do Cloudflare Tunnel**, quando o domínio aponta para o novo servidor.

O endpoint `/manager/login` permanece acessível (HTTP 200) mesmo com `LICENSE_REQUIRED` ativo — a página de login carrega normalmente para permitir a ativação.

### Dontus Dashboard — Startup Lento

O container `dontus-app` (Streamlit) compila dependências Python no primeiro boot (~30 segundos). Durante esse período, `curl localhost:8502` pode retornar HTTP 000 (conexão recusada). Aguardar 30-40 segundos após `docker compose up -d` antes de testar.

---

## Pitfalls

1. **Chave SSH com passphrase bloqueia rsync automatizado.** Criar chave dedicada sem passphrase (`ssh-keygen -N ''`).

2. **SCP do Mac para OVH é lento (~1 MB/s).** Sempre usar OVH→OVH (~30 MB/s).

3. **Binário interrompido corrompe.** Verificar `file <binario>` após transferência. Se mostrar "missing section headers", o arquivo está truncado. Re-transferir.

4. **npm install não produz o binário OpenCode CLI.** O pacote `@opencode-ai/plugin` é SDK Node.js, não o CLI standalone (Bun/Go binary de 145 MB).

5. **PM2 executado como usuário errado.** Sempre usar `sudo -u {{COMMANDER}}fae pm2 ...` ou conectar como o próprio usuário. `pm2 status` como ubuntu mostra lista vazia.

6. **PM2 + venv: `--interpreter` NÃO ativa o venv.** Especificar `--interpreter .venv/bin/python3` no PM2 NÃO seta `VIRTUAL_ENV`. O Python pode até encontrar o executável correto, mas o venv não é ativado e `site-packages` não entra no path. **Solução definitiva:** wrapper script que dá `source activate` antes do `exec python3`:

```bash
#!/bin/bash
. {{COMMANDER_HOME}}fae/projects/.../.venv/bin/activate
exec python3 {{COMMANDER_HOME}}fae/projects/.../script.py
```

```bash
pm2 start wrapper.sh --name webhook --interpreter /bin/bash
```

Este padrão é mais confiável que `--interpreter .venv/bin/python3` sozinho ou `--env VIRTUAL_ENV=...` (que pode ser sobrescrito pelo ambiente do PM2). Ver `references/venv-pitfall.md` para o diagnóstico completo.

6b. **Webhooks Python precisam de fastapi/uvicorn no venv.** Após rsync com `--exclude .venv`, recriar venv e instalar dependências. O webhook-meta também precisa de `python-dotenv` (`from dotenv import load_dotenv`).

7. **Túnel Cloudflare só funciona em UM servidor por vez.** Iniciar cloudflared no novo antes de parar o antigo causa conflito. Ordem correta: parar antigo → iniciar novo.

8. **rsync sem `--exclude .venv` transfere GB desnecessários.** O .venv do SIA continha nvidia/cuda headers (~5 GB). Sempre excluir `.venv`, `__pycache__`, `node_modules`.

9. **Permissão de diretórios pós-rsync.** Arquivos transferidos mantêm UID numérico. Se o UID do `{{COMMANDER}}` no antigo for diferente do `{{COMMANDER}}fae` no novo, `chown -R {{COMMANDER}}fae:{{COMMANDER}}fae` é necessário.

10. **Docker volumes não podem ser copiados a quente.** `rsync` de volumes com PostgreSQL/MySQL rodando produz arquivos inconsistentes. Parar containers antes de copiar volumes.

11. **Hardcoded `{{COMMANDER_HOME}}/` paths quebram silenciosamente.** A migração com username diferente (`{{COMMANDER}}` → `{{COMMANDER}}fae`) faz com que scripts que referenciam `{{COMMANDER_HOME}}/...` tentem escrever em diretórios inexistentes ou sem permissão. O erro mais comum é `PermissionError: [Errno 13]` em paths alheios. Ver seção "Path Migration" acima.

12. **PM2 herda cwd de onde foi iniciado.** Se `pm2 start` é executado de um diretório diferente do script, o `exec cwd` do PM2 fica errado, quebrando `import` relativos ou abertura de arquivos. Sempre usar `--cwd <diretório_do_script>` ao iniciar processos PM2. Verificar com `pm2 show <nome> | grep 'exec cwd'`.

13. **Auditar `/home/<user>/` exige `sudo`.** Diretórios home de outros usuários têm permissão `700` (drwx------). `ls /home/thaisa/` como `{{COMMANDER}}` retorna "Permission denied" mesmo com arquivos presentes. SEMPRE usar `sudo ls`, `sudo du`, `sudo find` ao auditar ambientes de outros usuários. Reportar "vazio" sem sudo é falso-positivo.

14. **Webhook-meta depende de `python-dotenv`.** Além de fastapi/uvicorn, o script `webhook_meta.py` importa `from dotenv import load_dotenv`. Instalar com `uv pip install python-dotenv` no venv.

15. **Shell escaping em comandos aninhados causa falhas misteriosas.** Evitar ssh host 'sudo -u user bash -c "comandos"' com aspas aninhadas. Preferir escrever scripts em arquivos (tee /tmp/script.sh), copiar para o servidor, e executar. Ou usar ssh host 'bash -s' << 'EOF' ... EOF (heredoc com delimitador quotado).

16. **SSH config: Host removido mas diretivas órfãs viram GLOBAIS.** Ao editar `~/.ssh/config` com sed ou manualmente, remover a linha `Host ...` mas deixar as diretivas indentadas (User, ProxyCommand, ServerAliveInterval, etc.) faz com que elas sejam aplicadas a TODAS as conexões SSH, não apenas ao host original.

**Sintoma:** `ssh -v` mostra `Authenticating to ... as '{{COMMANDER}}'` mesmo com `User {{COMMANDER}}fae` em outro bloco Host.

**Exemplo do que NÃO fazer:**
```
###    ← linha Host foi comentada
  ProxyCommand cloudflared access ssh ...
  User {{COMMANDER}}          ← AGORA É GLOBAL!
  ServerAliveInterval 15
```

**Correção:** Comentar TODAS as linhas do bloco órfão ou removê-las completamente. Verificar com `grep -n "User\|Host " ~/.ssh/config`.

17. **SSH host alias falha com DNS intermitente.** O resolver do servidor OVH pode falhar para hostnames definidos apenas no ~/.ssh/config. Preferir IP explícito via `-e 'ssh -i key user@IP'` no rsync.

18. :red_circle: **Garantir acesso SSH por IP direto a AMBOS os servidores antes do switch.** Sem porta 22 aberta para IP direto, perde-se acesso total ao servidor antigo quando o cloudflared é desligado. Abrir `sudo ufw allow 22/tcp` e testar ANTES de qualquer ação no túnel.

19. **Evolution: DATABASE_SAVE_DATA_CHATS=false esconde grupos no Manager UI.** Grupos EXISTEM na API (`/group/fetchAllGroups`) mas não aparecem na aba "Chats" porque não são persistidos na tabela `Chat`. Alterar para `true`, reiniciar container, e aguardar a primeira mensagem no grupo. Após os grupos aparecerem, pode voltar para `false`.

20. **Evolution: licença invalidada em novo servidor.** O `instance_id` é derivado de fingerprint da máquina. Servidor novo → novo `instance_id` → licença rejeitada. Re-ativar em `/manager/login` com Google OAuth. Instâncias WhatsApp também são perdidas e precisam ser recriadas.

21. **`sistema-orto-sia/` é facilmente esquecido.** É um diretório pequeno (~600 KB em `~/sistema-orto-sia/`) que contém dados de mapeamento do SIA. Não está dentro de `sia_projeto/` nem de `projects/`. Verificar explicitamente no inventário.

22. **Webhook-whatsapp: o script Python NÃO contém `uvicorn.run()`.** O `receptor_whatsapp.py` apenas define `app = FastAPI()`. A execução correta é via uvicorn como entry point: `.venv/bin/uvicorn receptor_whatsapp:app --host 0.0.0.0 --port 8001`. Executar o script diretamente faz o processo sair com exit 0 sem abrir porta. Sintoma no systemd: `code=exited, status=0/SUCCESS` repetidamente.

23. :red_circle: **PM2 cron NÃO dispara quando processo está `stopped`.** O `cron restart` do PM2 só funciona se o processo estiver `online`. Para jobs que terminam (ex: scripts batch como fechamento diário), usar **crontab do sistema** (`crontab -e`), nunca PM2 cron.

24. :red_circle: **`ln -sf` com diretório existente cria symlink DENTRO, não substitui.** Se `~/.hermes/profiles/aragorn` já é um diretório real, `ln -sf source target/` coloca o symlink dentro de `target/`. Para substituir: `rm -rf target && ln -sf source target`.

25. **Permissões herdadas de container Docker (root).** Arquivos criados dentro do container pertencem ao `root`. Após remover o container, `sudo chown -R user:user` nos diretórios afetados. Sintoma: `PermissionError` em logs, state.db, channel_directory.json.

26. **Fechamento diário (pycode-cerebro) — migração completa:**
    - Copiar `fechamento_diario.sh` e `sintetizador.py` do servidor antigo
    - Corrigir paths: `{{COMMANDER_HOME}}/` → `{{COMMANDER_HOME}}fae/`
    - No `sintetizador.py`: corrigir `load_dotenv()`, `MODELO`, paths de dados
    - Instalar dependências: `python3-dotenv`, `python3-requests`
    - Agendar no crontab do sistema: `55 22 * * * /path/fechamento_diario.sh`
    - NUNCA usar PM2 cron (pitfall 23)
