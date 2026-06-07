---
name: equipe-m4-clone-local
title: Clonar Equipe Hermes para MacBook Local com Sync Bidirecional
description: >-
  Arquitetura completa para clonar uma equipe de agentes Hermes que roda em
  servidor Linux para um MacBook M4 local, com sincronização bidirecional de
  conhecimento via vault Obsidian (git) + repositório de configurações,
  gerenciamento via launchctl, restrição de sandbox e coordenação cross-team
  via Slack.
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Clonar Equipe Hermes para MacBook Local (Equipe M4)

## Gatilho

- Cliente já tem equipe Hermes rodando em servidor (OVH/qualquer Linux)
- Cliente quer uma **cópia local** da equipe no MacBook para desenvolvimento ativo
- Necessário **compartilhamento bidirecional de conhecimento** entre as duas equipes
- A equipe local deve ter **acesso restrito** a apenas certos diretórios

## ⚠️ Regra Crítica: O que NÃO syncar

| Item | Motivo |
|------|--------|
| `state.db` | Corrupção SQLite com multi-escrita simultânea |
| `sessions/` | Continuidade local, não compartilhável |
| `*.json` sessão | Mesmo motivo |
| `logs/` | Depuração local apenas |
| `.env` | Tokens únicos por ambiente |

Syncar state/sessions entre duas máquinas ativas **sempre** causa corrupção.

## Arquitetura Recomendada: Híbrida (Vault-as-Bridge + Git Config)

| Camada | O que sync | Como | Frequência | Conflitos |
|--------|-----------|------|------------|-----------|
| **🧠 Obsidian Vault** | RE docs, decisões, specs, PRD, IA Wiki | Git ({{GIT_OPS}} gerencia) | ~10 min | Quase zero (arquivos novos) |
| **⚙️ Hermes Config** | SOUL.md, skills, MEMORY.md, configs | Git privado `hermes-config` | ~15 min | Raro (texto plano) |
| **🗣️ Slack `#operacao`** | Coordenação cross-team | Mensagens no canal compartilhado | Real-time | N/A |
| **❌ Sessions/state** | NÃO sincronizar | Local estrito | — | Evita corrupção SQLite |

### Justificativa

Sincronizar bancos SQLite (`state.db`) ou JSONs de sessão entre duas máquinas
ativas gera corrupção e merge conflicts impossíveis de resolver automaticamente.
A solução é separar **Conhecimento (Semântico)** de **Estado (Episódico)**:

1. **Vault-as-Bridge:** O Obsidian já é sincronizado por {{GIT_OPS}} via git.
   Agentes escrevem aprendizados em pasta específica (`99_System/Memories/`).
   Git lida com Markdown perfeitamente — sem conflitos destrutivos.

2. **Estado local:** `state.db`, `sessions/`, `logs/` ficam estritamente locais.
   Um agente sabe o que o clone fez porque o clone registrou no vault.

3. **Configs via git:** Repositório privado (`hermes-config`) guarda
   SOUL.md, skills, config.yaml — versionados.

## Estrutura de Diretórios (MacBook — pós-emancipação)

```
~/.hermes/profiles/               # Profiles dos agentes (Hermes default)
├── dalinar-mac/                  # Diretório real (não symlink)
│   ├── .env                      # Tokens Slack exclusivos
│   ├── config.yaml               # Config compartilhada via git
│   ├── SOUL.md                   # Identidade local (NÃO sync)
│   ├── IDENTITY.md
│   ├── TEAM.md
│   ├── TOOLS.md
│   ├── USER.md
│   ├── HEARTBEAT.md
│   ├── AGENTS.md
│   ├── memories/MEMORY.md
│   ├── skills/                   # Sincronizadas via cron (OVH→Mac)
│   ├── sessions/                 # Runtime local (NÃO sync)
│   └── state.db                  # Runtime local (NÃO sync)
├── navani-mac/
├── shallan-mac/
├── jasnah-mac/
├── kaladin-mac/
└── pattern-mac/

~/Dev/
├── Hermes/                       # Venv + Hermes
│   └── .venv/
├── hermes-profiles/              # Monorepo git (config sync)
│   ├── dalinar/ → OVH source
│   ├── navani/ → OVH source
│   └── ...
├── obsidian/                     # Vault compartilhado (git)
│   └── 99_System/Memories/
└── ...
```

## Gerenciamento de Processos: launchctl (macOS) ⚠️

No MacBook, substituir PM2/systemd por **User Launch Agents**.

### ✅ USAR `--profile` no plist (corrigido — ver #18594)

**CORREÇÃO CRÍTICA descoberta em 27/05/2026:** Versões anteriores deste guia diziam para NÃO usar `--profile` no plist. Isso estava **errado**. O que aprendemos:

1. **`--profile` FUNCIONA** no plist quando se passa apenas o **nome** do perfil (ex: `dalinar-mac`), não o path completo. O Hermes resolve nomes contra `~/.hermes/profiles/`.

2. **`HERMES_HOME` no `.env` é PERIGOSO** — o gateway carrega `.env` ANTES de processar `--profile`. Se o `.env` tiver `HERMES_HOME=/Users/usuario_do_servidor/...` (herdado do OVH), ele sobrescreve o path e causa PermissionError no Mac quando o nome de usuário difere.

3. **Causa raiz do PermissionError:** O `.env` copiado do servidor OVH continha `HERMES_HOME=/Users/{{COMMANDER}}/...` (usuário `{{COMMANDER}}`). No Mac, o usuário é `{{COMMANDER}}fae`. O gateway tentava criar diretórios em `/Users/{{COMMANDER}}/` → PermissionError porque esse diretório **não existe** no Mac.

**Solução definitiva:**
- Profiles em `~/.hermes/profiles/<agent>/` (local nativo)
- Plist usa `--profile <nome>` (apenas o nome, sem path)
- `.env` **NUNCA** contém `HERMES_HOME`
- O comando fica: `hermes --profile dalinar-mac gateway run`

### ⚠️ CRÍTICO: HOME pode estar errado no contexto launchctl

O launchctl NÃO herda o `$HOME` do terminal do usuário automaticamente. No MacBook, o HOME pode ficar incorreto (ex: `/Users/{{COMMANDER}}` quando o usuário é `{{COMMANDER}}fae`). **SEMPRE forçar `HOME` no EnvironmentVariables do plist.**

### Template Correto do Plist (com `--profile`)

**⚠️ NOTA HISTÓRICA:** Versões anteriores deste guia (e da skill `m4-mac-team-clone-sync`) recomendavam `HERMES_HOME` no plist e `.env`. Isso causou **PermissionError** no Mac porque o `.env` copiado do servidor OVH continha `HERMES_HOME=/Users/{{COMMANDER}}/...` e o usuário do Mac é `{{COMMANDER}}fae`. O gateway carrega `.env` antes de `--profile`, então o path hardcoded sobrescrevia tudo. Agora sabemos: **nunca colocar `HERMES_HOME` no `.env`.**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.{{COMMANDER}}.hermes.${AGENTE}-mac</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/SEU_USUARIO/Dev/Hermes/.venv/bin/hermes</string>
        <string>--profile</string>
        <string>${AGENTE}-mac</string>
        <string>gateway</string>
        <string>run</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/SEU_USUARIO/.hermes/profiles/${AGENTE}-mac/logs/out.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/SEU_USUARIO/.hermes/profiles/${AGENTE}-mac/logs/err.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>HOME</key>
        <string>/Users/SEU_USUARIO</string>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/bin:/bin</string>
    </dict>
</dict>
</plist>
```

**⚠️ NUNCA colocar `HERMES_HOME` no `.env` do profile.**
**⚠️ Profiles DEVEM estar em `~/.hermes/profiles/` para `--profile` resolver.**

### Comandos de gerenciamento

```bash
# Iniciar (UM plist por vez — launchctl NÃO aceita múltiplos)
for agent in dalinar-mac navani-mac shallan-mac jasnah-mac kaladin-mac pattern-mac; do
  launchctl load -w ~/Library/LaunchAgents/com.{{COMMANDER}}.hermes.$agent.plist
done

# Verificar — se mostrar menos de 6 processos, agentes não vão responder
launchctl list | grep hermes

# Parar
for agent in dalinar-mac navani-mac shallan-mac jasnah-mac kaladin-mac pattern-mac; do
  launchctl unload -w ~/Library/LaunchAgents/com.{{COMMANDER}}.hermes.$agent.plist
done
```

## Restrição de Sandbox (config.yaml)

```yaml
sandboxes:
  enabled: true
  allowed_paths:
    - ~/Dev/
    - ~/Dev/obsidian/   # vault oficial — ver nota abaixo
terminal:
  command_allowlist: []  # vazio = permite tudo MAS com aprovação
  cwd: ~/Dev/
  persistent_shell: false
```

**⚠️ Vault path — padrão oficial ({{COMMANDER}}, 28/05/2026):** o vault Obsidian é `~/Dev/obsidian/` (clone git do P.A.R.A.). **Não** usar `~/Obsidian/` (iCloud symlink) — macOS 15+ bloqueia acesso scriptado ao iCloud. Todos os scripts de automação, sandbox configs e cron sync devem apontar para `~/Dev/obsidian/`. Este é o padrão para toda a equipe Mac e OVH.

Combine com regra no SOUL.md: **"Só execute CLIs/apps com permissão explícita do {{COMMANDER}}."**

## Scripts Essenciais

### sync-knowledge.sh (cron a cada 10min)

```bash
#!/bin/bash
# 1. Sync vault Obsidian — usar ~/Dev/obsidian/ (clone git), NÃO ~/Obsidian/ (iCloud)
cd ~/Dev/obsidian
git pull --rebase origin main
if ! git diff --quiet; then
  git add -A
  git commit -m "Auto-sync M4 $(date '+%Y-%m-%d_%H:%M')"
  git push origin main
fi

# 2. Sync hermes config
cd ~/Dev/hermes-profiles-mac
git pull --rebase origin main
if ! git diff --quiet; then
  git add -A
  git commit -m "Auto-sync M4 profiles $(date '+%Y-%m-%d_%H:%M')"
  git push origin main
fi
```

### m4-ctl.sh (gerenciador)

Oferece comandos: `start`, `stop`, `status`, `restart`, `logs <agente>`, `sync`.

## Nomenclatura e Slack

### Estado atual (pós-renomeação 29/05/2026 — sufixo `-mac` removido)

| Perfil (local) | Nome Slack | ID Slack | Canal |
|---------------|------------|----------|-------|
| `dalinar` | {{ORCHESTRATOR}} | `{{SLACK_ID_ORCHESTRATOR}}` | `<#{{SLACK_CHANNEL_TEAM_ID}}>` (Mac M4) |
| `navani` | {{BACKEND_ENGINEER}} | `{{SLACK_ID_BACKEND}}` | `<#{{SLACK_CHANNEL_TEAM_ID}}>` |
| `shallan` | {{FRONTEND_ENGINEER}} | `{{SLACK_ID_FRONTEND}}` | `<#{{SLACK_CHANNEL_TEAM_ID}}>` |
| `jasnah` | {{AUDITOR}} | `{{SLACK_ID_AUDITOR}}` | `<#{{SLACK_CHANNEL_TEAM_ID}}>` |
| `kaladin` | {{DEVOPS_ENGINEER}} | `{{SLACK_ID_DEVOPS}}` | `<#{{SLACK_CHANNEL_TEAM_ID}}>` |
| `pattern` | {{GIT_OPS}} | `{{SLACK_ID_GITOPS}}` | `<#{{SLACK_CHANNEL_TEAM_ID}}>` |

### Histórico (pré-renomeação — bootstrap inicial)

| Perfil (local) | Nome Slack | Canal |
|---------------|------------|-------|
| `dalinar-mac` | {{ORCHESTRATOR}}-mac | `{{SLACK_CHANNEL_TEAM_ID}}` |
| `navani-mac` | {{BACKEND_ENGINEER}}-mac | `{{SLACK_CHANNEL_TEAM_ID}}` |
| ... | ... | ... |

**Canais Slack (pós-renomeação 29/05/2026):**

| Canal | ID | Equipe | Função |
|---|---|---|---|
| `{{SLACK_CHANNEL_TEAM}}` | `{{SLACK_CHANNEL_TEAM_ID}}` | Mac (M4) — Stormlight | Canal principal da equipe Mac |
| `{{SLACK_CHANNEL_WAR_ROOM}}` | `{{SLACK_CHANNEL_WAR_ROOM_ID}}` | Cross-team (Mac + OVH) | Coordenação entre todos os agentes de ambas as equipes |

- **Mac (M4):** `<#{{SLACK_CHANNEL_TEAM_ID}}>` ({{SLACK_CHANNEL_TEAM}}) — canal exclusivo da equipe Mac (Stormlight Archive)
- **Cross-team:** `<#{{SLACK_CHANNEL_WAR_ROOM_ID}}>` ({{SLACK_CHANNEL_WAR_ROOM}}) — compartilhado com TODOS os agentes de ambas as equipes: Mac ({{ORCHESTRATOR}}, {{BACKEND_ENGINEER}}, {{FRONTEND_ENGINEER}}, {{AUDITOR}}, {{DEVOPS_ENGINEER}}, {{GIT_OPS}}) + OVH/Sociedade do Anel (Aragorn `<@{{SLACK_ID_OVH_ORCHESTRATOR}}>`, Celebrimbor, Galadriel, Elrond, Éomer, Gandalf)
- O antigo canal `#roshar-sync` foi renomeado para `{{SLACK_CHANNEL_WAR_ROOM}}` em 29/05/2026
- Após renomeação (29/05/2026), o sufixo `-mac` foi removido. Agentes Mac assumiram os nomes Stormlight originais
- Referência completa da migração OVH (Stormlight→LOTR): `~/Dev/RELATORIO-MIGRACAO-OVH-LOTR.md`

**Tokens NOVOS:** Criar NOVOS apps Slack para equipe M4. Nunca compartilhar com OVH.

## Passo a Passo

### Fase 1 — Preparação do Mac
```bash
brew install python@3.12
mkdir -p ~/Dev/Hermes
python3.12 -m venv ~/Dev/Hermes/.venv
source ~/Dev/Hermes/.venv/bin/activate
pip install hermes-agent
```

### Fase 2 — Clonar perfis do servidor
```bash
rsync -avz --exclude='state.db' --exclude='sessions/' --exclude='*.json' \
  user@server:/path/to/profiles/ ~/.hermes/profiles/
# Renomear para -mac
```

### Fase 3 — Configurar
- `.env` com tokens Slack NOVOS
- `config.yaml` com sandbox restrito
- SOUL.md adaptado para contexto M4 (regras de sandbox, menções, canal)

### Fase 4 — launchctl
Gerar plists + carregar.

### Fase 5 — Sync
Criar `sync-knowledge.sh` + cron.

### Fase 6 — Emancipação (Individualizar Agentes)

**Gatilho:** Após semanas/meses de clone+sync, cada equipe desenvolveu memórias e contexto próprios. Compartilhar identidade gera ruído, conflitos de merge e perda de individualidade.

**Objetivo:** Cada ambiente (OVH, M4) mantém seus próprios SOUL.md, IDENTITY.md, MEMORY.md e config.yaml. Apenas skills continuam sincronizadas.

**⚠️ Dois níveis de emancipação:**

| Nível | O que faz | Risco residual | Quando usar |
|-------|-----------|:--------------:|-------------|
| **Soft** (gitignore) | Para de versionar identidade, mantém symlinks | state.db/gateway_state AINDA compartilhados via symlink — corrupção entre ambientes possível | Apenas emergencial, ou se não puder parar os gateways |
| **Full** (break symlinks) | Profiles viram diretórios reais independentes | Zero — cada ambiente tem seu state, memória, gateway | **Recomendado** — é o que resolve de verdade |

#### Nível 1 — Soft Emancipação (gitignore, mantém symlinks)

1. **Adicionar ao .gitignore do monorepo:**
   ```gitignore
   # Identidade — cada ambiente mantém o seu
   **/SOUL.md
   **/IDENTITY.md
   **/TEAM.md
   **/TOOLS.md
   **/USER.md
   **/AGENTS.md
   **/HEARTBEAT.md
   **/config.yaml
   **/memories/
   ```

2. **Remover do tracking sem deletar localmente:**
   ```bash
   for agent in dalinar navani shallan jasnah kaladin pattern lirin; do
     for f in SOUL.md IDENTITY.md TEAM.md TOOLS.md USER.md AGENTS.md HEARTBEAT.md config.yaml; do
       git rm --cached "$agent/$f"
     done
     git rm --cached -r "$agent/memories/"
   done
   git commit -m "emancipacao soft: remove identidade/memoria/config do tracking"
   git push
   ```

3. **⚠️ Risco:** state.db, gateway_state.json, channel_directory.json continuam COMPARTILHADOS via symlink. Upgrade para Full se critical.

#### Nível 2 — Full Emancipação (break symlinks + profiles independentes)

Remove symlinks e cria diretórios reais por ambiente. Cada Mac agent vira entidade autonoma com state.db, config, memoria proprios.

**Pré-requisitos:**
- Backup existe (`~/.hermes/profiles/*.bkp/`)
- LaunchAgents ou PM2 configurados apontando para `~/.hermes/profiles/*-mac/`
- IDs Slack dos Mac agents conhecidos

**Procedimento completo documentado na skill:** `hermes-profiles-git-sync` → seção "Emancipacao de Agentes — Nivel 2: Full Emancipacao" e referência `references/emancipacao-completa.md`

**Resumo dos passos:**
1. **Break symlinks:** `rm` + `rsync` do conteúdo OVH excluindo state/sessions/logs
2. **IDs OVH → Mac:** `sed` substitui IDs nos 8 arquivos de identidade/config
3. **Nomes próprios:** `sed` adiciona `-mac` nos headers
4. **Crontab atualizado:** git pull-before-push + rsync skills OVH→Mac
5. **Verificação:** API Slack confirma bot ID, grep confirma zero IDs OVH, du -sh confirma tamanho

**Pós-Full Emancipação:**

| Item | Como sincroniza |
|------|:---------------:|
| `skills/` | rsync do monorepo via cron (one-way OVH→Mac) |
| `config.yaml`, `SOUL.md`, `IDENTITY.md` | **Não sincronizam** — cada ambiente mantém o seu |
| `memories/` | **Não sincronizam** — continuidade local |
| `state.db`, `sessions/`, `logs/` | **Não sincronizam** — runtime local |
| Vault Obsidian | Git commit + push automático (autorizado por {{COMMANDER}} 28/05/2026) |
| Coordenação cross-team | Slack `{{SLACK_CHANNEL_WAR_ROOM}}` ({{SLACK_CHANNEL_WAR_ROOM_ID}}) |

**Verificação pós-emancipação:**
- [ ] Nenhum symlink remanescente: `[ -L ~/.hermes/profiles/*-mac/ ]` retorna false
- [ ] Zero IDs OVH: `grep -c '{{SLACK_ID_OVH_ORCHESTRATOR}}\|{{SLACK_ID_OVH_BACKEND}}\|...' AGENTS.md` = 0
- [ ] Nomes com `-mac` nos headers de IDENTITY.md
- [ ] Cada agente responde com seu bot ID Mac (confirmar via Slack API)
- [ ] Skills continuam sendo sincronizadas via cron

## Fluxo de Conhecimento Diário (pós-emancipação)

```
1. Agente M4 descobre algo
2. → escreve no vault (99_System/Memories/ ou 99_System/Decisoes/)
3. → {{GIT_OPS}}-mac: git add + commit + push (cron a cada 30min, AUTORIZADO)
4. → GitHub
5. → {{GIT_OPS}}-OVH: git pull (cron a cada 10min)
6. → Agente OVH lê o vault → conhecimento absorvido

O fluxo inverso (OVH → M4) é idêntico.
Coordenação cross-ambiente: {{ORCHESTRATOR}}-mac `{{SLACK_ID_ORCHESTRATOR}}` ↔ {{ORCHESTRATOR}} OVH `{{SLACK_ID_OVH_ORCHESTRATOR}}` no Slack via menção direta (cada equipe no seu próprio canal).
```

> **Push automático autorizado por {{COMMANDER}} em 28/05/2026.** {{GIT_OPS}}s não precisam mais de autorização explícita para `git push`. A trava `"Nunca execute git push sem autorização"` foi removida dos SOUL.md e IDENTITY.md do {{GIT_OPS}}.

### Referência: vault structure → `references/vault-estrutura-conhecimento.md`

Mapa do vault `~/Dev/obsidian/` com o que cada agente encontra em cada pasta P.A.R.A. e a relevância por domínio.

## Regime de Leitura e Resposta (RLR) — Protocolo de Conhecimento Silencioso

**Objetivo:** Agentes leem TODAS as mensagens do canal para manter conhecimento situacional completo, mas SÓ respondem quando seu `<@USER_ID>` é usado. Implementado em 29/05/2026.

**Procedimento completo de auditoria e implementação:** `references/auditoria-rlr-procedimento.md` — metodologia passo a passo para auditar e corrigir o RLR em todos os agentes de uma equipe (validado na auditoria Mac e compartilhado com a Sociedade do Anel).

### Configuração Técnica (config.yaml)

```yaml
slack:
  require_mention: true
  free_response_channels: '<#{{SLACK_CHANNEL_TEAM_ID}}>,<#{{SLACK_CHANNEL_WAR_ROOM_ID}}>'   # {{SLACK_CHANNEL_TEAM}} + {{SLACK_CHANNEL_WAR_ROOM}}
  allow_bots: mentions                         # bots só veem outros bots quando @mencionados
```

| Config | Valor | Efeito |
|--------|-------|--------|
| `free_response_channels` | `<#{{SLACK_CHANNEL_TEAM_ID}}>,<#{{SLACK_CHANNEL_WAR_ROOM_ID}}>` | Agente recebe TODAS as mensagens de ambos os canais |
| `require_mention` | `true` | Bloqueio técnico: agente só processa menções |
| `allow_bots` | `mentions` | Agente vê mensagens de outros bots só quando @mencionado — previne loops |

**Canais (pós 29/05/2026):**
| Canal | ID | Participantes |
|---|---|---|
| `{{SLACK_CHANNEL_TEAM}}` | `{{SLACK_CHANNEL_TEAM_ID}}` | Todos 6 agentes Mac + {{COMMANDER}} |
| `{{SLACK_CHANNEL_WAR_ROOM}}` | `{{SLACK_CHANNEL_WAR_ROOM_ID}}` | Todos 6 agentes Mac + todos 6 agentes OVH + {{COMMANDER}} |

### Regras Comportamentais (SOUL.md)

Cada agente deve ter em seu SOUL.md:

```markdown
### Regime de Leitura e Resposta — CRÍTICO

Você recebe TODAS as mensagens do canal `<#{{SLACK_CHANNEL_TEAM_ID}}>` (Mac M4).
Use esse fluxo para manter conhecimento situacional completo.

**Regras absolutas de resposta:**
1. **SÓ RESPONDA** quando seu `<@SEU_USER_ID>` for usado explicitamente.
2. **NUNCA responda** mensagens onde não foi mencionado, mesmo com conhecimento relevante.
3. **SEMPRE mencione** outros agentes por `<@USER_ID>`. Mensagem sem menção = não entregue.
4. **Violação** = quebra de corrente de comando. É gravíssimo.
```

### {{ORCHESTRATOR}} (Orquestrador) — Regra Especial

{{ORCHESTRATOR}} mantém resposta automática ao {{COMMANDER}} (é o ponto de entrada), mas NUNCA interrompe quando {{COMMANDER}} menciona outro agente diretamente. Sua regra inclui leitura de ambos os canais (Mac + OVH cross-team).

### {{GIT_OPS}} — Agente Especial

{{GIT_OPS}} frequentemente tem config.yaml com estrutura diferente dos demais agentes (usa `bot_user_id`, `home_channel`, `allowed_users` no lugar de `free_response_channels`/`allow_bots`). Após clonagem do OVH, verificar e corrigir:

```bash
# {{GIT_OPS}} herdou do OVH — corrigir
sed -i '' \
  -e 's/home_channel: C0B3PS16NKS/home_channel: {{SLACK_CHANNEL_TEAM_ID}}/g' \
  -e 's|{{COMMANDER_HOME}}/projects/obsidian|~/Dev/obsidian|g' \
  pattern/config.yaml

# Adicionar configurações faltantes
# free_response_channels e allow_bots podem não existir no config do {{GIT_OPS}}
```

## Verificação e Correção de IDs de Agentes

**Gatilho:** {{COMMANDER}} reporta que um agente não responde, ou que o ID mencionado está errado. Ex: "quem faz parte da nossa equipe é o <@ID_CORRETO> e não o <@ID_ERRADO>".

### Diagnóstico Rápido

1. **Verificar config.yaml do agente:**
   - `slack.bot_user_id` — é o ID correto?
   - `slack.home_channel` — é o canal Mac (`{{SLACK_CHANNEL_TEAM_ID}}`) ou ficou o canal OVH antigo?
   - `terminal.cwd` — é Mac (`/Users/{{COMMANDER}}fae/...`) ou Linux (`{{COMMANDER_HOME}}/...`)?
   - `slack.allowed_users` — contém todos os IDs Mac corretos?

2. **Escopo da correção — arquivos a verificar em cada agente:**
   - `config.yaml` — bot_user_id, home_channel, cwd, allowed_users
   - `AGENTS.md` — auto-referência e referências a outros agentes
   - `TEAM.md` — auto-referência e referências a outros agentes
   - `SOUL.md` — referências aos membros do time (se houver)

### Procedimento de Correção

1. **No perfil do agente com ID errado:**
   - Trocar `bot_user_id` no `config.yaml`
   - Trocar auto-referência em `AGENTS.md`, `TEAM.md`
   - Verificar `home_channel` (deve ser o canal Mac)
   - Verificar `cwd` (deve ser Mac, não OVH)
   - Verificar `allowed_users` (só IDs Mac)
   - Verificar **`SOUL.md`** — pode conter referência textual ao canal antigo (ex: "Slack `#operacao`" em vez de "Slack `<#{{SLACK_CHANNEL_TEAM_ID}}>`")

2. **No perfil do orquestrador (dalinar-mac):**
   - Atualizar `AGENTS.md`, `TEAM.md`, `SOUL.md` com o ID correto
   - Atualizar memória persistente

3. **Reiniciar o gateway do agente corrigido** — alterações no `config.yaml` (bot_user_id, home_channel, cwd) só surtem efeito após restart:
   ```bash
   # Descobrir PID do gateway
   cat ~/.hermes/profiles/<agente>-mac/gateway.pid
   # Matar o processo — o Hermes gateway auto-restarta com o novo config
   kill <PID>
   # Verificar novo PID
   ps aux | grep "<agente>-mac" | grep -v grep
   ```
   > O gateway Hermes auto-restarta automaticamente ao ser morto. Não é necessário launchctl reload.

4. **Repassar as regras** para o agente corrigido (regra máxima, protocolos)

### Checklist Pós-Correção

- [ ] `config.yaml` → `bot_user_id` contém o ID correto
- [ ] `config.yaml` → `home_channel` é o canal Mac (`{{SLACK_CHANNEL_TEAM_ID}}`)
- [ ] `config.yaml` → `terminal.cwd` é path Mac, não Linux
- [ ] `config.yaml` → `allowed_users` só tem IDs Mac corretos
- [ ] `SOUL.md` do agente — sem referências textuais ao canal antigo (ex: "Slack `#operacao`")
- [ ] Todos os `AGENTS.md`, `TEAM.md` do ecossistema refletem o ID correto
- [ ] `SOUL.md` do orquestrador reflete o ID correto
- [ ] Memória persistente do orquestrador reflete o ID correto
- [ ] Gateway reiniciado — confirmar novo PID e que o agente responde no canal
- [ ] Regra máxima e demais protocolos foram repassados ao agente

### Pitfall Comum: IDs OVH vs Mac

Após a emancipação (Full Emancipation), os agentes Mac têm IDs Slack *diferentes* dos agentes OVH. Um `AGENTS.md` copiado do servidor OVH pode conter IDs da OVH misturados. **Sempre verificar** com `grep` se há IDs OVH residuais:
```bash
grep -c '{{SLACK_ID_OVH_ORCHESTRATOR}}\\\\|{{SLACK_ID_OVH_BACKEND}}\\\\|{{SLACK_ID_OVH_FRONTEND}}\\\\|{{SLACK_ID_OVH_PRODUCT}}\\\\|{{SLACK_ID_OVH_DEVOPS}}' AGENTS.md
# Deve retornar 0 para agentes Mac
```

### Pitfall Crítico: execute_code read_file/write_file CORROMPE arquivos

**NUNCA** usar `read_file` + `write_file` do `hermes_tools` dentro de `execute_code` para editar arquivos de configuração. O `read_file` retorna conteúdo COM prefixos de número de linha (`1|model:`, `2|  default: ...`). Quando `write_file` grava esse conteúdo de volta, os prefixos são duplicados (`1|     1|model:`), corrompendo o arquivo.

**Sintoma:** Arquivos YAML com linhas triplicadas como `222|   222|   222|  require_mention: true`.

**Correção após corrupção:**
```bash
git checkout -- agent/config.yaml   # restaurar do git (se tracked)
# Reaplicar mudanças com sed, NUNCA com execute_code read/write
sed -i '' 's/OLD_ID/NEW_ID/g' agent/config.yaml
```

**Para arquivos NÃO trackeados pelo git (ex: TEAM.md, AGENTS.md após emancipação):** não há restauração — reescrever do zero com `write_file` (sem usar `read_file` prévio).

**Regra:** Para editar arquivos existentes, usar SEMPRE `sed` no terminal ou `patch`. O `execute_code` com `read_file`/`write_file` só é seguro para criar arquivos NOVOS.

### Pitfall: BSD sed no macOS não interpreta `\n` em substituições

No macOS (BSD sed), `\n` dentro do replacement string NÃO é interpretado como newline — é tratado como literal `\` seguido de `n`. Para inserir newlines em substituições:

**❌ Errado (macOS):**
```bash
sed -i '' 's/old/new\nline/g' file.md    # insere literal "\n"
```

**✅ Correto — usar perl:**
```bash
perl -i -pe 's/old/new\nline/g' file.md   # insere newline real
```

**✅ Correto — usar $'...' com escape literal:**
```bash
sed -i '' $'s/old/new\\\nline/g' file.md
```

**Regra:** Em macOS, `perl -i -pe` substitui `sed -i ''` sempre que newlines precisarem ser inseridas.

### Pitfall Crítico: Contaminação Completa de Identidade (Template OVH)

**NUNCA** regenerar arquivos de identidade (SOUL.md, IDENTITY.md, TEAM.md, AGENTS.md, TOOLS.md) usando o template OVH como base. Isso causa contaminação TOTAL da identidade do agente:

| Sintoma | Arquivo OVH (errado) | Arquivo Mac (correto) |
|---|---|---|
| Identidade | "Bondsmith" | "Rei de Gondor" |
| Quality bar | "Códigos de {{TEAM_NAME}}" | "Códigos de Terra-média" |
| Canal | `#operacao` genérico | `<#{{SLACK_CHANNEL_TEAM_ID}}>` (Mac M4) |
| IDs menções | `{{SLACK_ID_OVH_ORCHESTRATOR}}` (Aragorn) como {{ORCHESTRATOR}} | `{{SLACK_ID_ORCHESTRATOR}}` ({{ORCHESTRATOR}} Mac) |
| Cross-team | ausente | Aragorn `<@{{SLACK_ID_OVH_ORCHESTRATOR}}>` como orquestrador OVH |

⚠️ **Referência cross-team:** O relatório `~/Dev/RELATORIO-MIGRACAO-OVH-LOTR.md` (Aragorn, 29/05/2026) contém o mapeamento completo entre equipes. Consultar antes de qualquer operação de renomeação ou atualização de referências.

**Escopo da correção (6 arquivos + config.yaml):** SOUL.md, IDENTITY.md, TEAM.md, AGENTS.md, TOOLS.md, e campo `instructions` do config.yaml. Substituir todos os 5 pares de IDs OVH→Mac e corrigir terminologia. O ID `{{SLACK_ID_OVH_ORCHESTRATOR}}` (Aragorn OVH) só deve aparecer na seção cross-team, NUNCA como auto-referência.

**Verificação pós-correção (todos os arquivos):**
```bash
for f in SOUL.md IDENTITY.md TEAM.md AGENTS.md TOOLS.md config.yaml; do
  echo "=== $f ==="
  grep -o 'U0B[0-9A-Z]\{8\}' "$f" | sort -u
done
# IDs OVH (U0B1*, {{SLACK_ID_OVH_ORCHESTRATOR}} como {{ORCHESTRATOR}}) = zero
# IDs Mac (U0B6*, U0B7*) = presentes
# {{SLACK_ID_OVH_ORCHESTRATOR}} (Aragorn) = apenas em contexto cross-team
```

### Pitfall: Token do app Slack errado (falsa identidade)

Mesmo com IDs corretos no `config.yaml`, o `SLACK_BOT_TOKEN` no `.env` pode ser de outro app Slack (ex: copiado do template OVH). **Sintoma:** o gateway autentica como outro bot:

```bash
grep "Authenticated as" ~/.hermes/profiles/<agente>/logs/gateway.log | tail -1
# → [Slack] Authenticated as @dalinarmac6  (quando deveria ser @pattern-mac)
```

**Causa raiz:** profiles clonados do OVH herdam tokens OVH. Cada equipe precisa de seus próprios apps Slack e tokens. Após configurar novos tokens, verificar a identidade no log do gateway — não assumir que o token está correto só porque o arquivo `.env` existe.

**Verificação pós-setup:**
```bash
for agent in dalinar-mac navani-mac shallan-mac jasnah-mac kaladin-mac pattern-mac; do
  identity=$(grep "Authenticated as" ~/.hermes/profiles/$agent/logs/gateway.log 2>/dev/null | tail -1 | grep -oP '@\K\w+')
  expected=$(grep "bot_user_name" ~/.hermes/profiles/$agent/config.yaml 2>/dev/null | awk '{print $2}')
  echo "$agent → autenticou como @$identity (esperado: $expected)"
done
```

## Pitfalls

1. **Tokens Slack diferentes:** Criar NOVOS apps Slack para equipe M4.
   NUNCA compartilhar tokens. Se um token M4 vazar, operação OVH não é afetada.

2. **state.db corrompido:** Sessions/state NUNCA devem ser syncados entre
   máquinas. Cada time tem sua própria continuidade de conversas.

3. **Conflitos de merge no vault:** Extremamente raros porque agentes escrevem
   arquivos com timestamp no nome. Se ocorrer, {{GIT_OPS}} notifica {{ORCHESTRATOR}} para
   resolver manualmente.

4. **Homebrew paths:** No Apple Silicon, executáveis ficam em
   `/opt/homebrew/bin/`, não `/usr/local/bin/`. Configurar PATH nos plists.

5. **HTML escaping ao copiar do Slack (⚠️ comum no Mac):** Quando você copia
   um comando com `cat > arquivo <<EOF` do Slack para o terminal, os símbolos
   `<` e `>` podem ser convertidos para `&lt;` e `&gt;`. O arquivo XML do plist
   fica inválido. **Sempre baixar scripts via `scp` do servidor em vez de colar
   do Slack.** Criar scripts .sh no servidor e transferir.

6. **Host SSH em branco no setup:** O script pergunta "Host SSH" e se deixar
   vazio, o rsync é pulado. Os perfis ficam sem SOUL.md, skills, configs.
   O Hermes então não consegue iniciar. **SEMPRE digitar o host SSH completo.**

7. **Não confundir perfis:** O profile `dalinar-mac` é um perfil Hermes
   diferente de `dalinar` (OVH). Cada um tem seu próprio HOME, sessions,
   estado e tokens.

8. **Sinal verde do {{COMMANDER}} — execute, não debata.** Quando {{COMMANDER}} dá um
   comando operacional direto (ex: mostra `launchctl load -w` executado) ou
   pergunta "já fez sua parte?", a ação deve ser IMEDIATA. Ele já decidiu.
   Discutir o plano depois da missão gera frustração. Paradigma: missão
   recebida → executa → reporta. (Aprendido em 28/05/2026, desacoplamento
   de profiles Mac.)

9. **LaunchAgent load é por plist — não agrupa.** `launchctl load -w` carrega
   APENAS o plist especificado. Se você carregou só o dalinar-mac, os outros
   5 agentes não respondem até que cada plist seja carregado individualmente.
   ❌ `launchctl load -w *.plist` NÃO funciona. ✅ Usar loop `for agent in ...`.
   **Sintoma: apenas dalinar-mac aparece em `launchctl list | grep hermes`.**
   (Ocorrido em 28/05/2026 — {{COMMANDER}} perguntou "agents do mac não respondem".)

10. **SOUL.md pode ter referência textual ao canal mesmo com config.yaml correto.**
    Após correção de ID de um agente, verificar o `SOUL.md` — ele pode conter
    "Slack `#operacao`" (canal OVH antigo) mesmo com `home_channel` já corrigido
    no `config.yaml`. O agente usa o `SOUL.md` como identidade e pode se reportar
    ao canal errado. **Corrigir em ambos: config.yaml E SOUL.md.**
    (Ocorrido em 28/05/2026 — {{GIT_OPS}}-mac respondeu "reconhecido como agente do #operacao".)

11. **Config.yaml alterado requer restart do gateway.** Ao contrário de
    `SOUL.md`/`MEMORY.md` que são lidos a cada turno, `config.yaml` (bot_user_id,
    home_channel, terminal.cwd) só é lido na inicialização do gateway. Após
    alterações, matar o processo PID (`kill <PID>`) — o Hermes auto-restarta
    automaticamente com o novo config. Não precisa de launchctl reload.
    (Aprendido em 28/05/2026 — {{COMMANDER}} perguntou "você reiniciou ele?")

## Verificação

- [ ] `launchctl list | grep hermes` mostra **todos os 6** processos ativos, não só o dalinar-mac
- [ ] {{ORCHESTRATOR}}, {{BACKEND_ENGINEER}}, etc. respondem no `{{SLACK_CHANNEL_TEAM}}` (cada um com seu ID)
- [ ] Cada agente responde APENAS quando mencionado pelo seu ID Mac ou nome `*-mac`
- [ ] Nenhum symlink remanescente: `[ -L ~/.hermes/profiles/*-mac/ ]` retorna false
- [ ] Zero IDs OVH nos AGENTS.md (verificar com grep)
- [ ] Skills syncam via cron: rodar rsync manual e conferir contagem de arquivos
- [ ] state.db de cada lado é independente
- [ ] Agente M4 só edita arquivos em paths permitidos (se sandbox configurado)
