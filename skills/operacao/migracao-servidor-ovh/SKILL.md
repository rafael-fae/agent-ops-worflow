---
name: migracao-servidor-ovh
description: Procedimento completo de migração de infraestrutura entre servidores OVH — inventário, transferência OVH→OVH, Docker, PM2, Cloudflare Tunnel switch, systemd, caminhos hardcoded.
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Migração de Servidor OVH

## Gatilho
- Novo servidor OVH provisionado, migrar toda a infraestrutura do servidor atual
- Substituição de hardware, upgrade de recursos, ou troca de datacenter
- Clonagem de ambiente para disaster recovery

## Pré-requisitos
- Ambos os servidores com Ubuntu 24.04 LTS
- Acesso SSH ao servidor antigo (direto por IP ou túnel)
- Acesso SSH ao servidor novo (usuário padrão `ubuntu` com chave)
- Servidor novo com disco >= uso do servidor antigo

---

## FASE 0 — Preparação do Servidor Novo

### 0.1 Criar usuário principal
```bash
# Conectar como ubuntu no novo servidor
ssh ubuntu@<NEW_IP>

# Criar usuário com sudo (NUNCA usar '{{COMMANDER}}' como username — usar '{{COMMANDER}}fae')
sudo useradd -m -s /bin/bash -G sudo {{COMMANDER}}fae
sudo passwd {{COMMANDER}}fae  # senha temporária

# Copiar chaves SSH autorizadas do servidor antigo
sudo mkdir -p {{COMMANDER_HOME}}fae/.ssh
sudo chmod 700 {{COMMANDER_HOME}}fae/.ssh
# Copiar authorized_keys do servidor antigo
sudo tee {{COMMANDER_HOME}}fae/.ssh/authorized_keys << 'EOF'
<chaves públicas do antigo>
EOF
sudo chmod 600 {{COMMANDER_HOME}}fae/.ssh/authorized_keys
sudo chown -R {{COMMANDER}}fae:{{COMMANDER}}fae {{COMMANDER_HOME}}fae/.ssh
```

### 0.2 Hardening SSH e sudo
```bash
# Remover senhas (SSH key only)
sudo passwd -d {{COMMANDER}}fae
sudo passwd -d ubuntu  # se existir

# sudo sem senha
echo "{{COMMANDER}}fae ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/{{COMMANDER}}fae
sudo chmod 440 /etc/sudoers.d/{{COMMANDER}}fae

# Desabilitar autenticação por senha no SSH
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh
```

### 0.3 Instalar pacotes base
```bash
# Essenciais
sudo apt update
sudo apt install -y zsh tree htop jq tmux neofetch ncdu btop mosh fd-find ripgrep bat fzf unzip build-essential eza zsh-autosuggestions zsh-syntax-highlighting

# Node.js 22
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs

# PM2
sudo npm install -g pm2@7.0.1

# Docker
sudo apt install -y docker.io docker-compose-v2
sudo systemctl enable --now docker
sudo usermod -aG docker {{COMMANDER}}fae

# UV (Python)
curl -LsSf https://astral.sh/uv/install.sh | sh
# Fonte: $HOME/.local/bin/env

# ZSH + oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
sudo chsh -s /usr/bin/zsh {{COMMANDER}}fae
```

### 0.4 Ferramentas CLI
```bash
# Gemini CLI
sudo npm install -g @google/gemini-cli@0.43.0

# OpenCode CLI — NÃO instalar via npm. O binário standalone (138 MB) precisa ser copiado
# do servidor antigo. O pacote npm @opencode-ai/plugin gera um wrapper JS que não
# funciona standalone. Ver FASE 1 para transferência.

# Cloudflared
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /tmp/cloudflared
sudo mv /tmp/cloudflared /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared
```

### 0.5 UFW
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp        # SSH direto (contingência)
sudo ufw allow 8001/tcp       # Webhook WhatsApp
sudo ufw allow from 172.18.0.0/16 to any port 8002 proto tcp  # Webhook Meta (Docker interno)
sudo ufw --force enable
```

### 0.6 Timezone
```bash
sudo timedatectl set-timezone America/Cuiaba
```

---

## FASE 1 — Transferência de Dados

### 1.1 Estabelecer conexão OVH→OVH sem passphrase
O servidor antigo normalmente tem chave SSH com passphrase, o que impede rsync automatizado.
**Solução:** criar chave dedicada sem passphrase.

```bash
# NO SERVIDOR ANTIGO
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_migrate -N '' -C 'migration-key'
cat ~/.ssh/id_ed25519_migrate.pub
# Adicionar a chave pública ao authorized_keys do servidor novo

# Configurar alias SSH no servidor antigo para o novo
cat >> ~/.ssh/config << EOF
Host new-ovh
  HostName <NEW_IP>
  User {{COMMANDER}}fae
  IdentityFile ~/.ssh/id_ed25519_migrate
  IdentitiesOnly yes
  StrictHostKeyChecking accept-new
EOF

# Testar
ssh new-ovh 'echo OK && hostname'
```

### 1.2 Inventário antes da transferência
```bash
# Mapear tudo no servidor antigo
du -sh /var/www/ /home/*/projects/ /home/*/sia_projeto/ /home/*/hermes-roshar/ /home/*/Dev/hermes-profiles/
docker system df -v
crontab -l
systemctl list-units --type=service --state=running | grep -E 'hermes|cloudflared|orto-sia|pm2'
```

### 1.3 Transferir diretórios (OVH→OVH, ~30 MB/s)
```bash
# NO SERVIDOR ANTIGO — usar o alias new-ovh

# Projetos pequenos primeiro
rsync -avz --exclude='.venv' --exclude='__pycache__' --exclude='node_modules' \
  /var/www/ new-ovh:/tmp/migrate-varwww/

rsync -avz {{COMMANDER_HOME}}/projects/pycode-blog/ new-ovh:{{COMMANDER_HOME}}fae/projects/pycode-blog/
rsync -avz {{COMMANDER_HOME}}/projects/pycode-cerebro/ new-ovh:{{COMMANDER_HOME}}fae/projects/pycode-cerebro/
rsync -avz {{COMMANDER_HOME}}/projects/meta-webhook/ new-ovh:{{COMMANDER_HOME}}fae/projects/meta-webhook/

# Projetos grandes com exclusões
rsync -avz --exclude='.venv' --exclude='__pycache__' --exclude='node_modules' \
  {{COMMANDER_HOME}}/sia_projeto/ new-ovh:{{COMMANDER_HOME}}fae/sia_projeto/  # 13 GB

rsync -avz --exclude='node_modules' --exclude='.venv' \
  {{COMMANDER_HOME}}/hermes-roshar/ new-ovh:{{COMMANDER_HOME}}fae/hermes-roshar/

rsync -avz {{COMMANDER_HOME}}/Dev/hermes-profiles/ new-ovh:{{COMMANDER_HOME}}fae/Dev/hermes-profiles/

# Dotfiles
rsync -avz {{COMMANDER_HOME}}/.p10k.zsh new-ovh:{{COMMANDER_HOME}}fae/.p10k.zsh
```

### 1.4 OpenCode CLI — transferência especial
O OpenCode CLI é um binário ELF de 138 MB. **Não** instalar via npm (`@opencode-ai/plugin` gera apenas wrapper JS).
```bash
# Transferir o binário standalone do servidor antigo
rsync -avz {{COMMANDER_HOME}}/.opencode/bin/opencode new-ovh:/tmp/opencode

# NO SERVIDOR NOVO
sudo cp /tmp/opencode {{COMMANDER_HOME}}fae/.opencode/bin/opencode
sudo chown {{COMMANDER}}fae:{{COMMANDER}}fae {{COMMANDER_HOME}}fae/.opencode/bin/opencode
sudo chmod +x {{COMMANDER_HOME}}fae/.opencode/bin/opencode
```

---

## FASE 2 — Docker

### 2.1 Parada e cópia de volumes
```bash
# NO SERVIDOR ANTIGO
cd /var/www/oeste-odontologia
docker compose stop

# Copiar volumes para o novo
for vol in mysql_data evolution_postgres_data evolution_redis_data dontus_data evolution_data; do
  sudo rsync -avz \
    /var/lib/docker/volumes/oeste-odontologia_$vol/ \
    new-ovh:/tmp/docker-volumes/$vol/
done
```

### 2.2 Subir no servidor novo
```bash
# NO SERVIDOR NOVO
# Mover volumes para o local correto
for vol in mysql_data evolution_postgres_data evolution_redis_data dontus_data evolution_data; do
  target="/var/lib/docker/volumes/oeste-odontologia_${vol}/_data"
  sudo mkdir -p "$target"
  sudo cp -r /tmp/docker-volumes/$vol/_data/* "$target/"
done

# Verificar .env (deve ter sido copiado via rsync do /var/www/)
ls -la /var/www/oeste-odontologia/.env

# Build e start
cd /var/www/oeste-odontologia
sudo docker compose pull
sudo docker compose up -d
```

:warning: **Evolution API LICENSE_REQUIRED:** O `instance_id` muda com o novo servidor. A licença precisará ser re-ativada via `https://evolution.oesteodontologia.com.br/manager/login` (Google OAuth) **após** o switch do Cloudflare Tunnel.

---

## FASE 3 — Serviços Host (PM2)

### 3.1 pycode-blog (porta 8080)
```bash
cd {{COMMANDER_HOME}}fae/projects/pycode-blog
npm install
# Criar symlink de conteúdo
ln -sfn {{COMMANDER_HOME}}fae/projects/pycode-cerebro/public/content content
# Iniciar na porta 8080 (herdada do Quartz, compatível com túnel Cloudflare)
PORT=8080 NODE_ENV=production pm2 start server.js --name pycode-blog
```

### 3.2 Webhooks (FastAPI + PM2)
```bash
# :warning: Pitfall: PM2 deve usar o python do .venv, NÃO o python3 do sistema
# :warning: Pitfall: Especificar --cwd para o diretório correto do script
# :warning: PADRÃO CONFIRMADO (30/05/2026): PM2 com --interpreter .venv/bin/python3 
#   NÃO ativa o venv corretamente. O VIRTUAL_ENV não é setado e os módulos não são 
#   encontrados. Solução: wrapper script bash + --interpreter /bin/bash

# Padrão wrapper (confiável):
cat > /tmp/run_webhook.sh << 'WREOF'
#!/bin/bash
. {{COMMANDER_HOME}}fae/projects/<projeto>/.venv/bin/activate
exec python3 {{COMMANDER_HOME}}fae/projects/<projeto>/webhook.py
WREOF
chmod +x /tmp/run_webhook.sh
pm2 start /tmp/run_webhook.sh --name webhook-xxx --interpreter /bin/bash
```

**Gravidade do pitfall:** O `--interpreter .venv/bin/python3` do PM2 invoca o binário
correto, mas NÃO seta `VIRTUAL_ENV` no ambiente do processo. Sem essa variável, o Python
não encontra os `site-packages` do venv. O wrapper bash com `. /path/activate` resolve
porque o script de ativação seta `VIRTUAL_ENV` e ajusta o `PATH`.

### 3.3 Autostart PM2
```bash
pm2 save
pm2 startup systemd -u {{COMMANDER}}fae --hp {{COMMANDER_HOME}}fae
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u {{COMMANDER}}fae --hp {{COMMANDER_HOME}}fae
```

---

## FASE 4 — Caminhos Hardcoded

Scripts e configs frequentemente contêm `{{COMMANDER_HOME}}/` hardcoded. Precisam ser atualizados para o novo username.

**Locais comuns:**
- `pycode-cerebro/scripts/receptor_whatsapp.py` → `ARQUIVO_HOJE`
- `meta-webhook/.env.meta` → `LOG_DIR`
- `ecosystem.config.js` → paths de script e interpreter
- `crontab` → paths de `cd`

```bash
# Correção em massa (com cautela)
sudo -u {{COMMANDER}}fae sed -i 's|{{COMMANDER_HOME}}/|{{COMMANDER_HOME}}fae/|g' \
  {{COMMANDER_HOME}}fae/projects/pycode-cerebro/scripts/receptor_whatsapp.py \
  {{COMMANDER_HOME}}fae/projects/meta-webhook/.env.meta
```

---

## FASE 5 — Usuários Adicionais (Thaísa)

### 5.1 Criar e transferir
```bash
# NO SERVIDOR NOVO
sudo useradd -m -s /bin/bash -G docker thaisa
sudo passwd -d thaisa  # SSH key only

# NO SERVIDOR ANTIGO — transferir home completo
sudo rsync -avz --exclude='.cache' --exclude='.pm2/logs' --exclude='.pm2/pids' \
  /home/thaisa/ new-ovh:/home/thaisa/

# NO SERVIDOR NOVO — corrigir ownership
sudo chown -R thaisa:thaisa /home/thaisa
sudo chmod 750 /home/thaisa
```

### 5.2 Systemd para agentes Thaísa
Cada agente precisa de um serviço systemd:
```ini
[Unit]
Description=Hermes Agent - Nome — Equipe Thaisa
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=thaisa
WorkingDirectory=/home/thaisa/.hermes/profiles/<perfil>
EnvironmentFile=/home/thaisa/.hermes/profiles/<perfil>/.env
ExecStart=/home/thaisa/hermes_env/bin/hermes --profile <perfil> gateway run --replace
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

---

## FASE 6 — Cloudflare Tunnel Switch

### 6.1 Configurar cloudflared no novo (sem iniciar)
```bash
# Credenciais (MESMO tunnel ID e secret do servidor antigo)
sudo mkdir -p /etc/cloudflared
sudo tee /etc/cloudflared/credentials.json << 'EOF'
{"AccountTag":"...","TunnelSecret":"...","TunnelID":"..."}
EOF
sudo chmod 600 /etc/cloudflared/credentials.json

# Config (mesmo config.yml do antigo)
sudo tee /etc/cloudflared/config.yml << 'EOF'
tunnel: <TUNNEL_ID>
credentials-file: /etc/cloudflared/credentials.json
ingress:
  - hostname: ...
    service: ...
  - service: http_status:404
EOF

# Systemd (NÃO habilitar ainda)
sudo tee /etc/systemd/system/cloudflared.service << 'EOF'
[Unit]
Description=cloudflared
After=network-online.target
Wants=network-online.target

[Service]
TimeoutStartSec=15
Type=notify
ExecStart=/usr/local/bin/cloudflared --no-autoupdate --config /etc/cloudflared/config.yml tunnel run
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
```

### 6.2 Garantir acesso de contingência (IP direto)
Antes do switch, garantir que AMBOS os servidores aceitam SSH por IP direto:
```bash
# Nos dois servidores
sudo ufw allow 22/tcp

# Testar do Mac
ssh {{COMMANDER}}@<OLD_IP> 'echo OK'   # servidor antigo
ssh {{COMMANDER}}fae@<NEW_IP> 'echo OK' # servidor novo
```

### 6.3 Executar o switch
```bash
# 1. Parar cloudflared no antigo
ssh <OLD> "sudo systemctl stop cloudflared"

# 2. Iniciar cloudflared no novo
ssh <NEW> "sudo systemctl start cloudflared && sudo systemctl enable cloudflared"

# 3. Aguardar ~10s e testar todos os subdomínios
sleep 10
curl -s -o /dev/null -w '%{http_code}' https://oesteodontologia.com.br/
curl -s -o /dev/null -w '%{http_code}' https://evolution.oesteodontologia.com.br/
curl -s -o /dev/null -w '%{http_code}' https://dashboard.oesteodontologia.com.br/
curl -s -o /dev/null -w '%{http_code}' https://{{BLOG_URL}}/
```

:warning: Evolution API retornará `LICENSE_REQUIRED` após o switch. Ativar em `/manager/login`.

---

## FASE 3b — Serviços systemd Adicionais (Lirin, Thaísa)

### 3b.1 Lirin (gateway)
```bash
# Criar symlink do profile para ~/.hermes/profiles/
mkdir -p {{COMMANDER_HOME}}fae/.hermes/profiles
ln -sfn {{COMMANDER_HOME}}fae/Dev/hermes-profiles/lirin {{COMMANDER_HOME}}fae/.hermes/profiles/lirin

# Serviço systemd — SEM HERMES_HOME (causa erro "Profile does not exist"):
sudo tee /etc/systemd/system/hermes-gateway-lirin.service << 'EOF'
[Unit]
Description=Hermes Agent Gateway - Lirin
After=network-online.target

[Service]
Type=simple
User={{COMMANDER}}fae
ExecStart={{COMMANDER_HOME}}fae/hermes_env/bin/hermes --profile lirin gateway run --replace
WorkingDirectory={{COMMANDER_HOME}}fae
Environment="HOME={{COMMANDER_HOME}}fae"
Environment="PATH={{COMMANDER_HOME}}fae/hermes_env/bin:{{COMMANDER_HOME}}fae/.local/bin:/usr/bin:/bin"
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now hermes-gateway-lirin
```

### 3b.2 {{TEAM_NAME}}-Agents (Sociedade do Anel — Docker separado)

O container `roshar-agents` usa Docker Compose próprio em `/home/<user>/hermes-roshar/docker-compose.yml`,
NÃO faz parte do compose principal em `/var/www/oeste-odontologia/`.

```bash
# Symlink dos profiles (mesmo padrão do servidor antigo)
cd {{COMMANDER_HOME}}fae/hermes-roshar
rm -rf profiles
ln -sfn {{COMMANDER_HOME}}fae/Dev/hermes-profiles profiles

# Criar diretório mount obrigatório
sudo mkdir -p /root/projects/cerebro_grupo

# Build e start (imagem ~8.75 GB — usar background)
cd {{COMMANDER_HOME}}fae/hermes-roshar
sudo docker compose up -d --build
```

:warning: O build do `roshar-agents` é pesado (~10 min). Rodar com `terminal(background=true, timeout=1800)`.

---

## :warning: Pitfalls

### P1 — SSH config: linhas órfãs viram globais
Ao editar `~/.ssh/config` com sed, substituir apenas a linha `Host` transforma as diretivas indentadas seguintes em configurações GLOBAIS. Ex: `User {{COMMANDER}}` dentro de um bloco `Host` que foi removido passa a valer para TODAS as conexões.

**Sintoma:** `ssh -v` mostra `Authenticating as '{{COMMANDER}}'` mesmo com `User {{COMMANDER}}fae` no Host block correto.
**Correção:** Comentar ou remover TODAS as linhas do bloco órfão, não apenas o `Host`.

### P2 — PM2 + venv: --interpreter NÃO ativa o venv

O PM2 com `--interpreter .venv/bin/python3` invoca o binário correto mas NÃO seta `VIRTUAL_ENV`
no ambiente do processo. Sem essa variável, o Python não encontra os `site-packages`.

**Sintoma:** `ModuleNotFoundError: No module named 'fastapi'` repetido nos logs, mesmo com
o pacote instalado no venv e o `python3 -c "import fastapi"` funcionando manualmente.

**Padrão wrapper (confiável, validado 30/05/2026):**
```bash
cat > /tmp/run_webhook.sh << 'WREOF'
#!/bin/bash
. {{COMMANDER_HOME}}fae/projects/<projeto>/.venv/bin/activate
exec python3 {{COMMANDER_HOME}}fae/projects/<projeto>/script.py
WREOF
chmod +x /tmp/run_webhook.sh
pm2 start /tmp/run_webhook.sh --name webhook-xxx --interpreter /bin/bash
```

**Alternativa (menos confiável):** `pm2 start script.py --interpreter .venv/bin/python3` pode funcionar
se o venv for recriado NO MESMO path absoluto do servidor original. Se o username/home mudar,
`VIRTUAL_ENV` no script de ativação aponta para o path antigo → falha silenciosa.

### P4 — OpenCode CLI: npm ≠ binário real
O pacote npm `@opencode-ai/plugin` instala um wrapper JS que não funciona standalone (depende de node_modules completos). O binário real (138 MB ELF) precisa ser copiado via rsync do servidor antigo. Ver `cli-tools-agent-setup` para detalhes.

### P5 — Evolution API: license atrelada ao instance_id
O `instance_id` é gerado a partir de características da máquina. Migrar o PostgreSQL preserva os dados mas o ID muda. A licença precisa ser re-ativada pós-switch. **Após re-ativar**, as instâncias WhatsApp somem (`fetchInstances` retorna `[]`) — precisam ser recriadas via Manager UI e o webhook reconfigurado para `http://172.18.0.1:8001/webhook`.

### P6 — Docker volumes: path exato importa
Volumes Docker declarados em docker-compose como `mysql_data` são armazenados em `/var/lib/docker/volumes/<projeto>_mysql_data/_data/`. O nome do projeto (`oeste-odontologia`) é prefixado automaticamente. Copiar os dados para o path exato, com `_data/` como subdiretório.

### P7 — rsync sem `--exclude` enche o disco
Sempre excluir `.venv`, `__pycache__`, `node_modules` do rsync. O .venv pode ter centenas de MB (ex: SIA com 13 GB, mas ~12 GB só de .venv com CUDA). Recriar o .venv com `uv sync` é mais rápido e seguro.

### P8 — Chave SSH com passphrase bloqueia automação
O servidor antigo geralmente tem chave com passphrase. Criar uma chave dedicada sem passphrase (`id_ed25519_migrate`) especificamente para a transferência OVH→OVH. Remover após a migração.

### P9 — Cloudflare: rotas são gerenciadas remotamente

As rotas reais (hostname → service) são definidas no Cloudflare Zero Trust dashboard, NÃO no
`/etc/cloudflared/config.yml` local. O arquivo local é IGNORADO para hostnames.
**Nunca adicionar** rotas no config.yml que já existem remotamente — causa erro de YAML
(`mapping key "service" already defined at line 32`) e o cloudflared não inicia.

Para ver as rotas ativas: `sudo journalctl -u cloudflared | grep "Updated to new configuration"`.
Subdomínios como `sia.oesteodontologia.com.br → localhost:8501` podem existir remotamente sem
aparecer no config local. O config local serve apenas como fallback/documentação.

### P11 — HERMES_HOME quebrado em systemd

Se a env var `HERMES_HOME` apontar para um diretório que não contém a estrutura esperada
pelo hermes, o comando `hermes --profile X` falha com `Error: Profile 'X' does not exist`.

**Solução:** Remover `HERMES_HOME` do serviço systemd e usar symlink em `~/.hermes/profiles/`:
```bash
mkdir -p /home/<user>/.hermes/profiles
ln -sfn /home/<user>/Dev/hermes-profiles/<perfil> /home/<user>/.hermes/profiles/<perfil>
```
O `--profile` flag encontra o perfil via `~/.hermes/profiles/<nome>/` automaticamente.

### P10 — .venv copiado por rsync quebra em username diferente
O venv armazena o caminho absoluto em `bin/activate` (`VIRTUAL_ENV='{{COMMANDER_HOME}}/...'`) e em `pyvenv.cfg`. Ao migrar para um servidor com username diferente (`{{COMMANDER}}fae`), o Python não encontra os `site-packages`. **Sintoma:** `ModuleNotFoundError` para todos os módulos, mesmo com o interpreter correto. **Solução única:** excluir o `.venv` e recriar com `uv venv --python 3.12 && uv sync`. A correção com `sed` nos scripts de ativação NÃO é confiável — o venv tem dezenas de referências ao path antigo.
