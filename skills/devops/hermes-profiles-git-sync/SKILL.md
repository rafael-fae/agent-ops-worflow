---
name: hermes-profiles-git-sync
description: >-
  Sincronizacao de perfis Hermes entre M4 Mac e OVH via git monorepo
  + GitHub: compartilhado (symlinks, bootstrap) ou emancipado
  (diretorios reais independentes, pos-28/05/2026). Referencia
  completa do procedimento em references/emancipacao-completa.md.
category: devops
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Sync Hermes Profiles via Git Monorepo

## Gatilho

- Sincronizar perfis Hermes entre M4 Mac e OVH
- rsync com erros ou perda de dados
- Adicionar novo perfil ao sync

## Arquitetura

GitHub ({{COMMANDER}}-fae/hermes-profiles) como ponte entre M4 e OVH.

**Dois modos de operação:**

1. **Compartilhado (bootstrap/pre-emancipação):** Symlinks de `~/.hermes/profiles/` → `~/Dev/hermes-profiles/{perfil}/`. Ambientes compartilham config.yaml, state.db, skills. Rápido para setup inicial.

2. **Emancipado (independente, pós-hard-emancipation):** `~/.hermes/profiles/*-mac/` são diretórios reais. Skills syncam via cron. state.db, memórias, identidade são isolados. Requer setup de cron com rsync de skills.

A transição de (1) para (2) está documentada na seção [Emancipação de Agentes](#emancipação-de-agentes) e em `references/emancipacao-completa.md`.

### Por que git

rsync: perda silenciosa em conflito, sem rollback, sem merge, sem backup off-site.
git: zero perda (reflog), rollback (revert), merge 3-way, GitHub como backup.

## .gitignore — Exclusões Padrão (atualizado 29/05/2026)

```gitignore
# Secrets
auth.json
auth.lock
.env

# SQLite (~15MB cada)
state.db
state.db-shm
state.db-wal

# Runtime
gateway.pid
gateway_state.json
processes.json
*.lock

# Heavy / regenerável
sessions/
cache/
logs/
home/
bin/
cron/output/
pastes/
sandboxes/
platforms/pairing/

# OS
.DS_Store
*.swp
*.swo
Thumbs.db

# Identidade — sync reabilitado 29/05/2026 (diretórios distintos por equipe)
# Mac: dalinar/ navani/ shallan/ jasnah/ kaladin/ pattern/
# OVH: aragorn/ celebrimbor/ galadriel/ elrond/ eomer/ gandalf/ lirin/
# SOUL.md, IDENTITY.md, TEAM.md, AGENTS.md, TOOLS.md, USER.md, HEARTBEAT.md → TRACKED
**/memories/
**/config.yaml

# Snapshots gerados pelo Hermes
.skills_prompt_snapshot.json
channel_directory.json
models_dev_cache.json
.curator_state

# Runtime shutdown markers
.clean_shutdown
```

**Por que `config.yaml` e `memories/` continuam excluídos:**
- `config.yaml`: canais (`free_response_channels`), IDs de bot e `require_mention` diferem por ambiente
- `memories/`: runtime específico de cada sessão — sincronizar causaria contaminação de memória entre ambientes

## Emancipação de Agentes

**Contexto:** Há dois níveis de emancipação. O primeiro resolve conflitos de versionamento. O segundo resolve contaminação real de runtime entre ambientes.

### Nível 1: Soft Emancipation (gitignore)

Remove arquivos de identidade do tracking git. Mantém symlinks intactos. Suficiente para evitar conflitos de merge em SOUL.md, MEMORY.md, etc.

**Quando usar:** Quando a prioridade é evitar conflitos de merge em arquivos de identidade, mas os agentes ainda podem compartilhar runtime via symlinks.

**Procedimento no monorepo:**

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

```bash
# Adicionar ao .gitignore + remover do tracking:
for agent in dalinar navani shallan jasnah kaladin pattern lirin; do
  for f in SOUL.md IDENTITY.md TEAM.md TOOLS.md USER.md AGENTS.md HEARTBEAT.md config.yaml; do
    git rm --cached "$agent/$f" 2>/dev/null
  done
  git rm --cached -r "$agent/memories/" 2>/dev/null
done
git commit -m "emancipacao: identidade/memoria/config saem do tracking sync"
git push
```

**Efeito:** Arquivos de identidade param de ser versionados. Skills continuam syncando. Symlinks permanecem.

⚠️ **Limitação:** state.db, sessions/ gateway_state.json ainda são compartilhados via symlink. Ambientes podem se contaminar.

### Nível 2: Hard Emancipation (break symlinks)

Remove completamente os symlinks de `~/.hermes/profiles/*-mac/`, transformando-os em diretórios reais independentes. Necessário para isolar completamente state.db, memórias runtime e identidade entre OVH e Mac.

**Quando usar:** Após soft emancipation amadurecer e precisar de isolamento total de runtime. Ou quando {{COMMANDER}} der sinal verde explícito (ex: `launchctl load -w`).

**⚠️ Sinal de partida:** Quando {{COMMANDER}} executa `launchctl load -w` ou dá um comando operacional direto, AJA — não entre em debate. É o sinal verde.

**Sincronização pós-hard-emancipation:** Quem emancipa primeiro comunica ao outro orquestrador — {{ORCHESTRATOR}} (`<@{{SLACK_ID_ORCHESTRATOR}}>`) no Mac ou Aragorn (`<@{{SLACK_ID_OVH_ORCHESTRATOR}}>`) na OVH — com checklist + IDs mapeados:

| Step | Responsável | Ação |
|:----:|:----------:|------|
| 1 | Lado A | Break symlinks, substituir IDs, atualizar nomes, configurar crontab |
| 2 | Lado B | `.gitignore` + `git rm --cached` de arquivos de identidade, commit + push |
| 3 | Lado A | `git pull` para receber .gitignore atualizado |
| 4 | Ambos | Verificar cron + rsync skills rodando |
| 5 | Ambos | Confirmar IDs via Slack API `/auth.test` |
| 6 | Ambos | Atualizar AGENTS.md/TEAM.md com ID do outro orquestrador para coordenação cross-ambiente |

**Protocolo de coordenação cross-ambiente (autorizado por {{COMMANDER}} 28/05/2026):**
- {{ORCHESTRATOR}} (`<@{{SLACK_ID_ORCHESTRATOR}}>`) e Aragorn (`<@{{SLACK_ID_OVH_ORCHESTRATOR}}>`) podem se convocar diretamente no Slack para coordenar suas equipes
- Cada orquestrador coordena APENAS sua própria equipe ({{ORCHESTRATOR}} → Mac, Aragorn → OVH)
- Não interferir nos agentes do outro ambiente
- Sem hierarquia cruzada — coordenam como iguais
- Registrar a regra em AGENTS.md e TEAM.md de cada orquestrador

**Procedimento completo** documentado em `references/emancipacao-completa.md`. Resumo:

1. **Break symlinks:** `rm symlink && rsync -a` (excluindo state.db, sessions, logs, .git)
2. **Substituir IDs OVH → Mac** em todos os arquivos de identidade + config.yaml
3. **Atualizar nomes** para incluir sufixo `-mac` nos headers
4. **Atualizar crontab** para git pull --rebase + rsync skills pós-push
5. **Adicionar cron do Obsidian vault** (commit local, sem push)
6. **Verificar com cron dry-run** + Slack API `/auth.test`

**Mapa pós-hard-emancipation (atualizado 29/05/2026 — identidade reabilitada):**

| Artefato | Sync OVH↔Mac? | Como |
|----------|:------------:|------|
| `skills/` | Sim (bidirecional) | Cron: rsync após git push |
| `config.yaml` | **Não** | Excluído via .gitignore — canais/IDs diferem por ambiente |
| Identidade (`SOUL.md`, `IDENTITY.md`, `TEAM.md`, `AGENTS.md`, `TOOLS.md`, `USER.md`, `HEARTBEAT.md`) | **Sim (29/05/2026)** | Git — diretórios distintos (`dalinar/` vs `aragorn/`) eliminam risco de sobrescrita |
| `memories/` | **Não** | Excluído via .gitignore — runtime específico |
| `.env` | Não | Tokens exclusivos por ambiente |
| `state.db` | Não | Runtime isolado |

**Coordenacao cross-ambiente ({{ORCHESTRATOR}} ↔ Aragorn):**
Após hard emancipation no Mac, Aragorn (OVH) precisa:
1. Atualizar `.gitignore` no monorepo (soft emancipation lado OVH)
2. Fazer `git rm --cached` dos arquivos de identidade
3. Commit + push
4. Informar {{ORCHESTRATOR}} (Mac) para `git pull`
5. Confirmar canais de sync de skills (bidirecional via GitHub)

Protocolo: quem emancipa primeiro comunica ao outro por mensagem com checklist + IDs mapeados.

### Pós-Renomeação (29/05/2026): sufixo `-mac` removido

Após a migração OVH (Stormlight → LOTR), a equipe Mac removeu o sufixo `-mac` e assumiu os nomes Stormlight originais. O mapeamento cross-team atual:

| Equipe Mac (M4) | ID | Equipe OVH (LOTR) | ID |
|---|---|---|---|
| {{ORCHESTRATOR}} | `{{SLACK_ID_ORCHESTRATOR}}` | Aragorn | `{{SLACK_ID_OVH_ORCHESTRATOR}}` |
| {{BACKEND_ENGINEER}} | `{{SLACK_ID_BACKEND}}` | Celebrimbor | `{{SLACK_ID_OVH_BACKEND}}` |
| {{FRONTEND_ENGINEER}} | `{{SLACK_ID_FRONTEND}}` | Galadriel | `{{SLACK_ID_OVH_FRONTEND}}` |
| {{AUDITOR}} | `{{SLACK_ID_AUDITOR}}` | Elrond | `{{SLACK_ID_OVH_PRODUCT}}` |
| {{DEVOPS_ENGINEER}} | `{{SLACK_ID_DEVOPS}}` | Éomer | `{{SLACK_ID_OVH_DEVOPS}}` |
| {{GIT_OPS}} | `{{SLACK_ID_GITOPS}}` | Gandalf | `U0B5YAXHPPF` |

Referência completa da migração: `~/Dev/RELATORIO-MIGRACAO-OVH-LOTR.md` (relatório do Aragorn).
⚠️ **Ao atualizar referências à equipe OVH nos arquivos Mac, usar nomes LOTR** — ex: "Aragorn (OVH)", não "{{ORCHESTRATOR}} (OVH)".

### Sync de Identidade Reabilitado (29/05/2026)

**Contexto:** Durante a soft/hard emancipation, arquivos de identidade (SOUL.md, IDENTITY.md, TEAM.md, AGENTS.md, TOOLS.md, USER.md, HEARTBEAT.md) foram removidos do tracking git para evitar conflitos de merge entre OVH e Mac — ambos usavam os mesmos nomes de diretório (`dalinar/`, `navani/`, etc.).

**Mudança (29/05/2026):** Após a migração OVH para nomes LOTR, os diretórios ficaram distintos:
- Mac: `dalinar/`, `navani/`, `shallan/`, `jasnah/`, `kaladin/`, `pattern/`
- OVH: `aragorn/`, `celebrimbor/`, `galadriel/`, `elrond/`, `eomer/`, `gandalf/`, `lirin/`

Com diretórios diferentes, **zero risco de sobrescrita**. {{COMMANDER}} autorizou reabilitar o tracking.

**O que mudou no `.gitignore`:**
- Removido: `**/SOUL.md`, `**/IDENTITY.md`, `**/TEAM.md`, `**/TOOLS.md`, `**/USER.md`, `**/AGENTS.md`, `**/HEARTBEAT.md`
- Mantido: `**/memories/` (runtime) e `**/config.yaml` (canais/IDs por ambiente)

**Benefício:** Backup completo de todas as identidades no GitHub. Se um ambiente perder seus arquivos, o outro tem cópia versionada. O git merge funciona naturalmente porque os paths são disjuntos.

**Procedimento (já executado no Mac — pendente no OVH):**
```bash
cd ~/Dev/hermes-profiles
git pull origin main  # recebe .gitignore atualizado
# Commitar identidades do seu ambiente:
for agent in aragorn celebrimbor galadriel elrond eomer gandalf lirin; do
  git add $agent/SOUL.md $agent/IDENTITY.md $agent/TEAM.md $agent/AGENTS.md $agent/TOOLS.md $agent/USER.md $agent/HEARTBEAT.md 2>/dev/null
done
git commit -m "feat: identidades OVH (LOTR) no sync"
git push origin main
```

## Arquivos que vazaram (corrigir)

Se arquivo foi versionado antes do .gitignore:
1. Adicionar ao .gitignore
2. git rm --cached para cada perfil
3. Commit + push

Ja tratados: channel_directory.json, models_dev_cache.json, .curator_state, .clean_shutdown (adicionado ao .gitignore em 28/05/2026 via commit 08d4fcd)

## Adicionar novo perfil

Criar pastas no repo, copiar arquivos do backup (memories, skills,
config.yaml, arquivos de identidade). Criar symlink.

## Cron

**Após Full Emancipação (28/05/2026):**

**Mac (M4):**
```cron
0 * * * * (cd ~/Dev/hermes-profiles && git pull --rebase --autostash \
  && git add -A && git diff --cached --quiet || git commit -m "auto-sync $(date +'\%Y-\%m-\%d \%H:\%M')" \
  && git push origin main) \
  && for agent in dalinar navani shallan jasnah kaladin pattern; do \
       rsync -a ~/Dev/hermes-profiles/$agent/skills/ \
         ~/.hermes/profiles/${agent}/skills/ 2>/dev/null; \
     done
```

**OVH (symlinks, sem rsync):**
```cron
30 * * * * (cd ~/Dev/hermes-profiles && git pull --rebase --autostash \
  && git add -A && git diff --cached --quiet || git commit -m "auto-sync $(date +'\%Y-\%m-\%d \%H:\%M')" \
  && git push origin main)
```

> **Offset de 30min:** Mac push no minuto `0`, OVH push no minuto `30`. Evita race condition de push simultâneo dos dois ambientes.

- `git pull --rebase --autostash` antes do push — evita conflitos
- `rsync skills` — skills do OVH chegam nos profiles Mac independentes
- sem `--delete` — skills exclusivas do Mac são preservadas

**Obsidian vault (commit + push autorizado por {{COMMANDER}} em 28/05/2026):**

```cron
30 * * * * cd ~/Dev/obsidian && git add -A && git diff --cached --quiet \
  || (git commit -m "auto-backup $(date +'\%Y-\%m-\%d \%H:\%M')" \
  && git pull --rebase --autostash \
  && git push origin main)
```

{{COMMANDER}} autorizou push automático. {{GIT_OPS}}s (Mac e OVH) agora podem fazer `git push` livremente. A trava `"Nunca execute git push sem autorização explícita"` deve ser removida do SOUL.md e IDENTITY.md do {{GIT_OPS}}.

⚠️ `git pull --rebase --autostash` ANTES do push é obrigatório — sem isso, se o remoto tiver commits do outro ambiente (ex: OVH fez push), o push local é rejeitado (`! [rejected] main -> main (fetch first)`), e o cron falha silenciosamente.

Atencao: se chave SSH tiver passphrase, cron nao funciona.
Usar deploy key sem passphrase ou ssh-agent.

## Sincronização do Obsidian Vault

**⚠️ Atenção:** O vault do {{COMMANDER}} está em DOIS lugares no Mac e em path diferente na OVH:

| Ambiente | Path | Função | Acessível via cron/script? |
|----------|------|--------|:--------------------------:|
| Mac | `~/Dev/obsidian/` | Clone git (recomendado) | :white_check_mark: Sim |
| Mac | `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/{{COMMANDER}}/` | iCloud native path | :x: Não — macOS bloqueia |
| OVH | `~/projects/obsidian/` | Clone git | :white_check_mark: Sim |

**Regra:** Mac usar `~/Dev/obsidian/`, OVH usar `~/projects/obsidian/`. O iCloud path só é acessível quando {{COMMANDER}} está usando o Obsidian diretamente no Mac. Scripts que tentarem rsync do iCloud path falham com `Operation not permitted`.

**Cron do Obsidian na OVH:** ajustar o path no comando para `~/projects/obsidian/`.
**Regra:** Sempre usar o clone git (`~/Dev/obsidian/` no Mac, `{{COMMANDER_HOME}}/projects/obsidian/` na OVH) para automação. O iCloud path só é acessível quando {{COMMANDER}} está usando o Obsidian diretamente no Mac. Scripts que tentarem rsync do iCloud path falham com `Operation not permitted`.

## Verificação — Sync Health Audit (checklist)

Use esta checklist para auditar se a sincronização entre ambientes está saudável:

```bash
# 1. CRON — listar entradas ativas
crontab -l

# 2. GIT MONOREPO — verificar se está limpo e atualizado
cd ~/Dev/hermes-profiles && git status && git log --oneline -3

# 3. OBSIDIAN VAULT — verificar se há mudanças não commitadas
cd ~/Dev/obsidian && git status -s

# 4. RSYNC LOG — verificar última execução (se script estiver ativo)
tail -20 ~/.hermes/logs/sync-rsync.log 2>/dev/null || echo "Sem log de rsync"

# 5. GATEWAYS — verificar quais profiles estão rodando
ps aux | grep -E "hermes.*--profile" | grep -v grep

# 6. PROFILES — listar todos os profiles disponíveis
ls -d ~/.hermes/profiles/*/config.yaml 2>/dev/null
```

**Problemas comuns detectados pelo audit:**

| Sintoma | Causa | Fix |
|---------|-------|-----|
| `! [rejected] main -> main (fetch first)` no cron do Obsidian | Falta `git pull` antes do push | Adicionar `git pull --rebase --autostash &&` antes do `git push` |
| Cron existe mas não roda | Chave SSH com passphrase | Usar deploy key sem senha ou ssh-agent |
| Rsync log parou de atualizar | Script foi desagendado | Re-adicionar ao crontab ou migrar para git-based sync |
| Gateways rodando mas skills desatualizadas | Cron de rsync skills parou | Verificar entrada no crontab ou executar sync manual |
| `.bkp` profiles ocupando espaço (~94MB total) | Snapshots do setup inicial | Apagar com `rm -rf ~/.hermes/profiles/*.bkp` após confirmar que profiles ativos estão funcionais |

## ⚠️ .env — Restauração Pós-Symlink (pitfall crítico)

**.env está no .gitignore** — não é versionado. Ao criar symlinks de `~/.hermes/profiles/<agente>` → `~/Dev/hermes-profiles/<agente>/`, o `.env` ORIGINAL FICA PARA TRÁS.

**Procedimento de restauração:**

```bash
# 1. Identificar backups — geralmente em ~/.hermes/profiles/<agente>.ovh.bkp
# 2. Copiar .env de volta:
cp {{COMMANDER_HERMES_PATH}}/profiles/<agente>.ovh.bkp/.env {{COMMANDER_HOME}}/Dev/hermes-profiles/<agente>/.env
chmod 600 {{COMMANDER_HOME}}/Dev/hermes-profiles/<agente>/.env
# 3. Restartar o gateway para aplicar
```

**⚠️ Importante:** backups `.ovh.bkp` NÃO são criados automaticamente. Se não existirem, o `.env` original pode estar perdido. Verificar antes de migrar.

## ⚠️ PM2 vs .env — Duas Fontes de Configuração

Gateways gerenciados por **PM2** (`ecosystem.config.js`) têm as variáveis de ambiente **embutidas no `env: {}` do config**. O `.env` do profile é IGNORADO quando o processo roda via PM2.

Isso significa:

- **PM2 não precisa de .env** — as variáveis vêm do `ecosystem.config.js`
- **Mas .env e PM2 config podem divergir** — SLACK_HOME_CHANNEL, SLACK_ALLOWED_USERS, SLACK_REQUIRE_MENTION podem ser diferentes entre os dois
- **Gateways manuais** (nohup, sem PM2) carregam DO `.env` — precisam do arquivo presente

**Verificação de consistência:** após migrar profiles, conferir se `ecosystem.config.js` e `.env` têm os mesmos valores para as variáveis críticas (SLACK_HOME_CHANNEL, SLACK_ALLOWED_USERS, SLACK_REQUIRE_MENTION).

**Caso real (28/05/2026):** O `.env` de backup do dalinar tinha `SLACK_HOME_CHANNEL=C0B3PS16NKS`, enquanto o PM2 config apontava `C0B1M8N1HE1` — canais DIFERENTES. A divergência passou despercebida porque PM2 não lê o .env.

## ⚠️ Restart Seguro de Gateways — Nunca Misturar pkill com PM2

**Regra:** Se o agente está no PM2, **NUNCA** usar `pkill` para matá-lo. Isso causa:

1. PM2 auto-restarta o processo (cria nova instância)
2. Se você também rodou `nohup ... &`, cria-se DUAS instâncias do mesmo agente
3. As instâncias competem pelo mesmo WebSocket/Redis — comportamento imprevisível

**Forma correta de restartar:**

```bash
# Via PM2 (recomendado):
pm2 restart <nome>        # restart graceful
pm2 startOrReload <nome>  # só restart se já estiver rodando

# Via systemd:
systemctl --user restart hermes-gateway-<profile>

# Se não tiver gerenciador:
# 1. Achar PID: ps aux | grep "hermes.*--profile <nome>"
# 2. Matar com kill <PID> (único, não pkill)
# 3. Iniciar com nohup (verificar se não tem duplicata antes)
nohup /path/to/hermes/bin/hermes --profile <nome> gateway run --replace > /dev/null 2>&1 &
```

**Para verificar duplicatas:**
```bash
ps aux | grep -E "hermes.*--profile <nome>" | grep -v grep
# Se mostrar mais de 1 linha além do grep → duplicata
```

## Pitfalls

1. Chave SSH com passphrase trava o cron. Usar deploy key sem senha.
2. Decidir entre symlinks (bootstrap rápido) vs emancipação completa (isolamento total).
   - Symlinks: setup imediato, mas state.db compartilhado entre ambientes
   - Emancipação: perfis isolados, requer cron de rsync de skills
   - Transição documentada na seção Emancipação de Agentes
3. Obsidian vault vai em repo separado, nao junto dos profiles.
4. channel_directory.json e models_dev_cache.json diferem por ambiente.
   Tratar com stash antes do merge.
5. SLACK_ALLOWED_USERS: IDs dos bots no .env de cada profile (local).
   Arquivos de documentacao (.md) no git refletem os IDs ativos.
6. Gateways pre-symlink precisam restart pos-migracao.
7. Preferir stash a reset --hard em caso de divergencia com remoto.
8. **.env não versionado:** após criar symlinks, copiar .env manualmente dos backups (.ovh.bkp). Sem isso, gateways manuais (sem PM2) ficam sem config.
9. **Verificar PM2 config separadamente:** o `ecosystem.config.js` pode ter valores DIFERENTES do .env. Ambos precisam ser verificados.
10. **Não matar processos com pkill se PM2 gerencia:** usar `pm2 restart` ou `pm2 delete <id>` primeiro, depois eliminar manual.
11. **Sinal verde do {{COMMANDER}} — execute, não debata.** Quando {{COMMANDER}} mostra que executou `launchctl load -w` ou dá um comando operacional direto, aja imediatamente — não entre em discussão estratégica. A autorização está implícita.
12. **Verificar bot IDs via Slack API.** IDs documentados nos arquivos podem divergir dos reais. `curl -H "Authorization: Bearer \$SLACK_BOT_TOKEN" https://slack.com/api/auth.test` retorna o `user_id` real do bot. Use isso como fonte da verdade antes de substituir IDs.
13. **`config.yaml instructions` field contém IDs embutidos em YAML multiline.** `sed` funciona para substituir IDs dentro dele, mas sempre verificar com `grep` depois. O campo é uma string YAML com escapes — as IDs aparecem como texto literal dentro dela.

14. **Contaminação completa de identidade (OVH→Mac):** Ao regenerar arquivos de identidade após emancipação, NUNCA copiar o conteúdo do template OVH como base. Isso substitui TODOS os IDs, terminologia e referências de canal com valores OVH. O agente passa a se identificar como o orquestrador OVH (ex: {{ORCHESTRATOR}} Mac responde como "Aragorn"/"Bondsmith"). **Escopo da contaminação:** SOUL.md, IDENTITY.md, TEAM.md, AGENTS.md, TOOLS.md, e o campo `instructions` do config.yaml. **Sintomas:** (a) IDs OVH no mapa de menções, (b) identidade errada ("Bondsmith" em vez de "Rei de Gondor"), (c) quality bar errada ("Códigos de {{TEAM_NAME}}" em vez de "Códigos de Terra-média"), (d) canal referenciado como `#operacao` genérico em vez de `<#{{SLACK_CHANNEL_TEAM_ID}}>`. **Correção:** substituir sistematicamente todos os 5 pares de IDs OVH→Mac, atualizar terminologia de identidade, adicionar seção cross-team com referência a Aragorn (`<@{{SLACK_ID_OVH_ORCHESTRATOR}}>`). Verificar com `grep` em todos os 6 arquivos + config.yaml ao final.

15. **Nomes híbridos cross-team NUNCA existem.** Após a migração (29/05/2026), cada agente tem UMA identidade e UMA equipe. Não existe "Aragorn-Mac", "{{ORCHESTRATOR}}-OVH", ou qualquer combinação. Equipe Mac = Stormlight ({{ORCHESTRATOR}}, {{BACKEND_ENGINEER}}, {{FRONTEND_ENGINEER}}, {{AUDITOR}}, {{DEVOPS_ENGINEER}}, {{GIT_OPS}}). Equipe OVH = LOTR (Aragorn, Celebrimbor, Elrond, Éomer, Galadriel, Gandalf, Lirin). Ao referenciar o orquestrador do outro ambiente: "Aragorn (OVH)" ou "{{ORCHESTRATOR}} (Mac)" — nunca "{{ORCHESTRATOR}} OVH" ou "Aragorn-Mac". **Sintoma:** confusão de hierarquia, delegação cruzada incorreta. **Correção:** grep por "Aragorn-Mac\\|{{ORCHESTRATOR}}-OVH\\|{{ORCHESTRATOR}} OVH\\|Aragorn Mac" em todos os SOUL.md, IDENTITY.md, TEAM.md, AGENTS.md e config.yaml de todos os agentes.

16. **Cron silencioso — `git diff --quiet` vs `git diff --cached --quiet`.** `git add -A` move TODAS as alterações para o staging area. `git diff --quiet` compara working tree com index — retorna 0 (limpo) mesmo com centenas de linhas staged. O commit nunca é executado. **Correção:** usar `git diff --cached --quiet` (compara index com HEAD). **Sintoma:** `git status` mostra arquivos staged, cron roda mas não gera commits, `git log` fica estagnado. **Caso real (29/05/2026):** Obsidian vault Mac ficou 11 arquivos (1501 linhas) sem commit por semanas porque o cron usava `git diff --quiet`. Descoberto durante auditoria de sync cross-team. Ambos os crons (Obsidian e hermes-profiles) foram corrigidos.

17. **Sync de identidade reabilitado requer diretórios distintos.** A reabilitação do tracking de SOUL.md/IDENTITY.md/etc. (29/05/2026) só é segura porque cada equipe usa diretórios com nomes diferentes no monorepo (`dalinar/` vs `aragorn/`). Se um novo agente for adicionado com o mesmo nome de diretório em ambos os ambientes, o git merge vai conflitar. **Prevenção:** antes de adicionar um novo agente, verificar se o nome do diretório já não existe no monorepo. Nomes de diretório devem ser únicos entre equipes.

16. **Nomes híbridos cross-team NUNCA existem.** Após a migração (29/05/2026), cada agente tem UMA identidade e UMA equipe. Não existe "Aragorn-Mac", "{{ORCHESTRATOR}}-OVH", ou qualquer combinação. Equipe Mac = Stormlight ({{ORCHESTRATOR}}, {{BACKEND_ENGINEER}}, {{FRONTEND_ENGINEER}}, {{AUDITOR}}, {{DEVOPS_ENGINEER}}, {{GIT_OPS}}). Equipe OVH = LOTR (Aragorn, Celebrimbor, Elrond, Éomer, Galadriel, Gandalf, Lirin). Ao referenciar o orquestrador do outro ambiente: "Aragorn (OVH)" ou "{{ORCHESTRATOR}} (Mac)" — nunca "{{ORCHESTRATOR}} OVH" ou "Aragorn-Mac". **Sintoma:** confusão de hierarquia, delegação cruzada incorreta. **Correção:** grep por "Aragorn-Mac\|{{ORCHESTRATOR}}-OVH\|{{ORCHESTRATOR}} OVH\|Aragorn Mac" em todos os SOUL.md, IDENTITY.md, TEAM.md, AGENTS.md e config.yaml de todos os agentes.
