---
name: m4-mac-team-clone-sync
description: Arquitetura e plano de implementação para clonar equipe Hermes do servidor OVH para MacBook local (M4/M1/M2/M3), com sincronização bidirecional de conhecimento via git.
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# M4 Mac Team Clone + Sync Bidirecional

## Gatilho

- {{COMMANDER}} quer uma equipe Hermes local no MacBook ({{ORCHESTRATOR}}-Mac, {{BACKEND_ENGINEER}}-Mac, etc.)
- Necessário compartilhar conhecimento entre time OVH (servidor) e time local (Mac)
- Restrição: Hermes no Mac só acessa ~/Dev e ~/Obsidian para edição, mas CLIs (Gemini, Claude, OpenCode) são liberados
- Execução de apps/CLIs sempre requer permissão explícita do {{COMMANDER}}

## Pré-requisitos

- Python 3.12+ via Homebrew (`brew install python@3.12`)
- 6 apps Slack NOVOS criados com manifest JSON (socket mode, escopos específicos)
- Canal `<#{{SLACK_CHANNEL_TEAM_ID}}>` ({{SLACK_CHANNEL_TEAM}}) — canal exclusivo da equipe Mac
- Canal `<#{{SLACK_CHANNEL_WAR_ROOM_ID}}>` ({{SLACK_CHANNEL_WAR_ROOM}}) para coordenação cross-team entre M4 e OVH (todos os 12 agentes)
- Acesso SSH ao servidor OVH para rsync inicial

## Arquitetura

### Estratégia de Sync: Híbrida (Vault-as-Bridge + Git Config)

| Camada | O que sync | Como | Frequência |
|--------|-----------|------|------------|
| **🧠 Conhecimento** | RE docs, decisões, specs, PRD | Obsidian vault git ({{GIT_OPS}} gerencia) | ~10 min |
| **⚙️ Hermes Config** | SOUL.md, skills, MEMORY.md | Git privado `hermes-config` | ~15 min |
| **🗣️ Coordenação** | Alertas urgentes | Slack {{SLACK_CHANNEL_WAR_ROOM}} | Real-time |
| **❌ Sessions/state** | NÃO sincronizar | Local estrito | — |

### Estrutura de Diretórios no Mac

```
~/Dev/
├── Hermes/                    # pip install hermes-agent (venv)
│   └── .venv/
├── {{PROJECT_SLUG}}/              # Codigo (git)
├── setup-m4-team/scripts/     # Scripts de setup e sync
├── hermes-config/             # Git backup semanal
```

**IMPORTANTE:** Profiles DEVEM ficar em `~/.hermes/profiles/`, nao em `~/Dev/hermes-profiles-mac/`. O comando `hermes --profile <nome>` espera profiles em `~/.hermes/profiles/`. Se profiles estiverem em `~/Dev/`, o `--profile` nao encontra e Hermes usa fallback que gera PermissionError. Ver secao Launchctl Plist para a configuracao correta.

## Sincronizacao entre M4 e OVH

**Primario:** rsync bidirecional via cron 10min (6 pares de agentes). **Backup:** git semanal para GitHub. Detalhes no script `sync-m4-ovh-complete.sh`.

### Passo a Passo Rápido

1. **Instalar Hermes no Mac:**
   ```bash
   brew install python@3.12
   mkdir -p ~/Dev/Hermes ~/Dev/hermes-profiles-mac
   python3.12 -m venv ~/Dev/Hermes/.venv
   source ~/Dev/Hermes/.venv/bin/activate
   pip install hermes-agent
   ```

2. **Clonar perfis do OVH (sem sessions/state.db):**  
   ⚠️ **NUNCA rsync sem exclusões — o diretório `home/.npm/_cacache` tem milhares de arquivos de cache e quebra a conexão SSH.**
   ```bash
   rsync -avz \
     --exclude='state.db' --exclude='sessions/' --exclude='*.json' \
     --exclude='logs/' --exclude='__pycache__/' \
     --exclude='.npm/' --exclude='.cache/' --exclude='.local/' \
     --exclude='.config/' --exclude='home/' \
     --exclude='node_modules/' --exclude='*.db' --exclude='*.db-*' \
     {{COMMANDER}}@ssh.oesteodontologia.com.br:{{COMMANDER_HOME}}/hermes-roshar/profiles/ \
     ~/Dev/hermes-profiles-mac/
   cd ~/Dev/hermes-profiles-mac
   for agent in dalinar navani shallan jasnah kaladin pattern; do mv $agent ${agent}-mac; done
   ```

3. **Configurar .env com tokens Slack NOVOS** (nunca reusar tokens OVH)

4. **Configurar config.yaml com sandbox:**
   ```yaml
   sandboxes:
     allowed_paths: [~/Dev/, ~/Dev/obsidian/]
     restricted: true
   persistent_shell: false
   ```
   
   **⚠️ Vault path (padrão oficial — {{COMMANDER}}, 28/05/2026):** `~/Dev/obsidian/`. Nunca usar `~/Obsidian/` (iCloud symlink bloqueado pelo macOS 15+).

5. **Criar launchctl plists** para cada agente (ver template no plano)

6. **Criar script sync-knowledge.sh** + cron a cada 10min:
   - `git pull --rebase` do vault Obsidian
   - `git pull --rebase` do hermes-config
   - `git add + commit + push` se houver mudanças locais

7. **Criar canal Slack {{SLACK_CHANNEL_WAR_ROOM}}** para coordenação entre times

### Regras de Ouro

- Sessions/state.db NUNCA sincronizados (corrupção SQLite)
- Tokens Slack totalmente separados entre M4 e OVH
- Git merge de texto plano resolve conflitos naturalmente
- {{GIT_OPS}} de cada lado gerencia sync do vault
- Conhecimento viaja: agente descobre → escreve vault → {{GIT_OPS}} push → GitHub → {{GIT_OPS}} pull → outro time lê

## Slack Bot Manifest JSON

Para cada bot M4, criar no **Create App → From Manifest** com este JSON (só mudar `name`, `description` e `background_color`). Veja `references/slack-manifest-comparison-mac-vs-ovh.md` para diferenças entre manifests Mac e OVH — o Mac tem mais scopes e eventos habilitados.

```json
{
    "display_information": {
        "name": "dalinar-mac",
        "description": "General e Orquestrador — Equipe M4",
        "background_color": "#1a1a2e"
    },
    "features": {
        "app_home": {
            "home_tab_enabled": false,
            "messages_tab_enabled": true,
            "messages_tab_read_only_enabled": false
        },
        "bot_user": { "display_name": "dalinar-mac", "always_online": true }
    },
    "oauth_config": {
        "scopes": {
            "bot": [
                "app_mentions:read", "channels:history", "channels:join",
                "channels:read", "chat:write", "files:read", "files:write",
                "groups:history", "groups:read", "groups:write",
                "im:history", "im:read", "im:write",
                "reactions:read", "reactions:write",
                "users:read", "users:write", "team:read"
            ]
        }
    },
    "settings": {
        "event_subscriptions": {
            "bot_events": [
                "app_mention", "message.channels",
                "message.groups", "message.im"
            ]
        },
        "interactivity": {"is_enabled": false},
        "org_deploy_enabled": false,
        "socket_mode_enabled": true,
        "token_rotation_enabled": false
    }
}
```

Após criar: Settings → Socket Mode (copiar xapp-...) → OAuth & Permissions → Install (copiar xoxb-...).

## Launchctl Plist Template (macOS) — VERSAO DEFINITIVA apos 2h de debugging

### Root cause PermissionError (CRITICAL — 1h de debugging)

O `.env` do profile copiado do servidor OVH continha `HERMES_HOME=/Users/{{COMMANDER}}/...` (username do servidor). O gateway carrega `.env` ANTES de processar `--profile`, entao `HERMES_HOME` do `.env` sobrescreve o path. No Mac o usuario e `{{COMMANDER}}fae`, nao `{{COMMANDER}}` — path inexistente causa PermissionError.

**Regras (apos debugging exaustivo):**
1. Profiles em `~/.hermes/profiles/` (layout nativo, nao `~/Dev/hermes-profiles-mac/`)
2. USAR `--profile <nome>` no plist e no terminal
3. NUNCA colocar HERMES_HOME no .env do profile
4. NUNCA colocar HERMES_HOME nas EnvironmentVariables do plist
5. GATEWAY_ALLOW_ALL_USERS=true no .env de CADA profile (global nao funciona)

### Path vault iCloud com espacos

Nao usar barras invertidas dentro de aspas duplas. Correto:
```
M4_VAULT="/Users/user/Library/Mobile Documents/iCloud~md~obsidian/Documents/{{COMMANDER}}"
```
Referenciar com `"$M4_VAULT"` — aspas duplas preservam espacos.

**⚠️ iCloud path NÃO é acessível via scripts:** macOS 15+ (Sequoia) bloqueia acesso de processos não-UI a diretórios iCloud. Rsync e shell scripts falham com `Operation not permitted`. Use `~/Dev/obsidian/` (clone git) para automação. Scripts do Obsidian vault devem SEMPRE apontar para o git path, não para o iCloud.

O `.env` do profile copiado do servidor OVH continha `HERMES_HOME=/Users/{{COMMANDER}}/...` (username do servidor). O gateway carrega `.env` ANTES de processar `--profile`, entao `HERMES_HOME` do `.env` sobrescreve o path. No Mac o usuario e `{{COMMANDER}}fae`, nao `{{COMMANDER}}` — path inexistente causa PermissionError.

**Fix:** `sed -i '' '/HERMES_HOME/d' ~/.hermes/profiles/*/.env`

### Regras obrigatorias

1. USAR `--profile <nome>` no plist
2. Profiles em `~/.hermes/profiles/` (layout nativo)
3. NUNCA colocar HERMES_HOME no .env do profile
4. NUNCA colocar HERMES_HOME nas EnvironmentVariables do plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.{{COMMANDER}}.hermes.dalinar-mac</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/SEU_USUARIO/Dev/Hermes/.venv/bin/hermes</string>
        <string>--profile</string>
        <string>dalinar-mac</string>
        <string>gateway</string>
        <string>run</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/SEU_USUARIO/.hermes/profiles/dalinar-mac/logs/out.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/SEU_USUARIO/.hermes/profiles/dalinar-mac/logs/err.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
    <key>WorkingDirectory</key>
    <string>/Users/SEU_USUARIO/.hermes/profiles/dalinar-mac</string>
</dict>
</plist>
```

Gerenciamento via `~/Library/LaunchAgents/`:
```bash
launchctl load -w ~/Library/LaunchAgents/com.{{COMMANDER}}.hermes.dalinar-mac.plist
launchctl list | grep hermes
launchctl unload -w ~/Library/LaunchAgents/com.{{COMMANDER}}.hermes.dalinar-mac.plist
```

## Estratégia de Versionamento (Git)

**3 repositórios:**
| Repo | Conteúdo | Sync |
|------|----------|------|
| `{{PROJECT_SLUG}}` | Código Django | M4 push → OVH pull |
| `obsidian-vault` | Docs, RE, decisões | Bidirecional ({{GIT_OPS}}) |
| `hermes-config` | SOUL.md, skills, MEMORY.md | Bidirecional (cron) |

**Branch strategy:**
- `main` protegida — só via PR com approval
- Branches: `feature/quem/descricao`, `hotfix/descricao`, `sync/ovh-ajuste`
- OVH só escreve em emergência (branch prefixo `sync/`)
- Tags semânticas: `v0.1.0`, `v1.0.0`, etc.

## OpenCode API Key Fallback para M4

Mesmo mecanismo do OVH: script em cada profile que testa chave ativa, se 429 faz swap para `OPENCODE_GO_API_KEY_2` no .env. Cron a cada 15min.

```bash
# Instalar (1 por profile) — adaptar ENV_FILE e STATUS_FILE para Mac
# script em: ~/Dev/hermes-profiles-mac/<agent>-mac/scripts/opencode_fallback.py

# Testar
python3 ~/Dev/hermes-profiles-mac/dalinar-mac/scripts/opencode_fallback.py check

# Cron
*/15 * * * * cd ~/Dev && for a in dalinar navani shallan jasnah kaladin pattern; do python3 hermes-profiles-mac/${a}-mac/scripts/opencode_fallback.py check; done
```

## Troubleshooting: Agentes Caindo Imediatamente

### Sintoma: PermissionError: /Users/{{COMMANDER}}
**Causa RAIZ (mais comum):** O `.env` do profile contém `HERMES_HOME=/Users/{{COMMANDER}}/...` (herdado do OVH). O gateway carrega `.env` ANTES de `--profile`, sobrescrevendo o path para um diretório que não existe.
**Solução:** `sed -i '' '/HERMES_HOME/d' ~/.hermes/profiles/*/.env`

### Sintoma: launchctl mostra PID por 1s depois morre, err.log com erro de comando
**Causa:** `--profile` posicionado ERRADO no plist (antes do subcomando `gateway` sem o profile name). Ordem correta: `hermes --profile <nome> gateway run`.
**Solução:** Verificar o plist — o array deve ser `["/path/hermes", "--profile", "dalinar-mac", "gateway", "run"]`.

### Sintoma: FileNotFoundError, diretório não existe
**Causa:** Profiles em `~/Dev/hermes-profiles-mac/` mas o plist aponta para `~/.hermes/profiles/` (ou vice-versa).
**Solução:** Todos os perfis DEVEM estar em `~/.hermes/profiles/` — é o layout nativo que o Hermes espera.

| 1. **Rsync sem exclusões de .npm/cache**: O perfil `home/.npm/_cacache` tem milhares de arquivos. Rsync sem `--exclude='.npm/' --exclude='.cache/' --exclude='home/'` estoura conexão SSH com broken pipe. **SEMPRE excluir no rsync.** Comando correto:
   ```bash
   rsync -avz \
     --exclude='state.db' --exclude='sessions/' --exclude='*.json' \
     --exclude='logs/' --exclude='__pycache__/' \
     --exclude='.npm/' --exclude='.cache/' --exclude='.local/' \
     --exclude='.config/' --exclude='home/' \
     --exclude='node_modules/' --exclude='*.db' --exclude='*.db-*' \
     ...
   ```
2. **Tokens compartilhados**: Se M4 usar tokens OVH, mensagens erradas e exposição de dados. SEMPRE tokens novos.
3. **state.db sync**: Corrompe os dois lados. Adicionar ao .gitignore.
4. **Permissões Apple Silicon**: Usar `/opt/homebrew/bin/python3` para Homebrew, não `/usr/bin/python3`.
5. **launchctl logs**: Direcionar para `~/.hermes/profiles/<agente>/logs/` — nunca para `~/Library/Logs/`.
6. **Conflitos git no MEMORY.md**: Aceitar rebase automático — texto plano mergeia bem.
7. **Script setup perguntou host SSH mas usuário deixou em branco**: Na segunda execução, sem host o rsync é pulado e os perfis ficam vazios. SEMPRE digitar o host SSH.

### Sintoma: `exec: cloudflared: not found` (SSH via Cloudflare Tunnel)

**Causa:** O SSH é chamado pelo rsync (subprocesso) e não herda o PATH completo. O `cloudflared` está em `/usr/local/bin/` mas o SSH não encontra.

**Solução:** Criar `~/.ssh/config` com caminho absoluto do cloudflared:
```bash
cat > ~/.ssh/config << 'EOF'
Host ssh.oesteodontologia.com.br
  ProxyCommand /usr/local/bin/cloudflared access ssh --hostname %h
  User {{COMMANDER}}
EOF
```

### Sintoma: `unexpected end of file` durante rsync

**Causa:** Conexão SSH caindo durante transferências pelo Cloudflare Tunnel.

**Soluções:**
1. Adicionar `-o ServerAliveInterval=15 -o ServerAliveCountMax=3` nos args SSH
2. Adicionar `--timeout=30` (ou `--timeout=15` para chunks pequenos) no rsync
3. **Vault em chunks:** Dividir em subdiretórios individuais com timeout menor:
   ```bash
   SSH_OPTS="ssh -i ~/.ssh/id_rsync -o ServerAliveInterval=15 -o ServerAliveCountMax=3"
   for chunk in 00_Inbox 10_Projects 20_Areas 30_Resources 90_Archives 99_System; do
     rsync -rlptz --delete --timeout=15 -e "$SSH_OPTS" \
       "$VAULT_LOCAL/$chunk/" \
       "user@host:$VAULT_REMOTE/$chunk/" || true
   done
   ```

### Profiles OVH: TODOS os 8 arquivos de identidade obrigatorios

Rsync de configs produz warnings se um profile nao tiver AGENTS.md ou HEARTBEAT.md. Verificar previamente:
```bash
for profile in dalinar pattern navani shallan jasnah kaladin lirin; do
  for f in config.yaml SOUL.md IDENTITY.md TEAM.md TOOLS.md USER.md AGENTS.md HEARTBEAT.md; do
    [ ! -f "$HOME/.hermes/profiles/$profile/$f" ] && echo "FALTA: $profile/$f"
  done
done
```
Faltas comuns: AGENTS.md (navani, shallan, jasnah, kaladin), HEARTBEAT.md (pattern, lirin).
