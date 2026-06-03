# Emancipação Completa de Agentes — Break Symlinks

> Registro da operação de desacoplamento realizada em 28/05/2026 por {{ORCHESTRATOR}}-mac e {{ORCHESTRATOR}} OVH.
> Contexto: Equipe Hermes (6 agentes) clonada do OVH para MacBook M4. Perfis ainda compartilhavam
> configs, state.db, identidade via symlinks para o monorepo git. Objetivo: perfis Mac independentes.

## Pré-requisitos

- [ ] Perfis `*-mac` já existem em `~/.hermes/profiles/` (clone feito) — OU são symlinks para o monorepo
- [ ] `.bkp` dos perfis: `~/.hermes/profiles/<agente>-mac.bkp/` (segurança)
- [ ] LaunchAgents (Mac) ou PM2/systemd (Linux) apontando para `~/.hermes/profiles/*-mac/`
- [ ] IDs Slack dos Mac bots conhecidos (verificar via Slack API `/auth.test`)
- [ ] Monorepo git `~/Dev/hermes-profiles/` com profiles OVH
- [ ] GitHub remote configurado e autenticado

## Passo a Passo

### 1. Break Symlinks + Copy Content (Lado Mac)

```bash
PROFILES_DIR="$HOME/.hermes/profiles"
AGENTS=("dalinar-mac" "navani-mac" "shallan-mac" "jasnah-mac" "kaladin-mac" "pattern-mac")
OVH_SOURCES=(
  "/Users/{{COMMANDER}}fae/Dev/hermes-profiles/dalinar"
  "/Users/{{COMMANDER}}fae/Dev/hermes-profiles/navani"
  "/Users/{{COMMANDER}}fae/Dev/hermes-profiles/shallan"
  "/Users/{{COMMANDER}}fae/Dev/hermes-profiles/jasnah"
  "/Users/{{COMMANDER}}fae/Dev/hermes-profiles/kaladin"
  "/Users/{{COMMANDER}}fae/Dev/hermes-profiles/pattern"
)

for i in "${!AGENTS[@]}"; do
  agent="${AGENTS[$i]}"
  target="${OVH_SOURCES[$i]}"
  path="$PROFILES_DIR/$agent"

  # Remove symlink
  rm "$path"
  
  # Copy content (exclude runtime state)
  rsync -a --delete \
    --exclude='state.db' --exclude='state.db-wal' --exclude='state.db-shm' \
    --exclude='sessions/' --exclude='logs/' --exclude='.git/' \
    --exclude='cron/output/' \
    "${target}/" "$path/"
done
```

**Verificar:** Nenhum symlink remanescente:
```bash
for p in dalinar-mac navani-mac shallan-mac jasnah-mac kaladin-mac pattern-mac; do
  if [ -L ~/.hermes/profiles/$p ]; then echo "SYMLINK: $p"; else echo "REAL: $p"; fi
done
```

### 2. Descobrir Bot IDs (Slack API)

Nunca confie em IDs documentados. Verifique ao vivo:

```bash
curl -s -H "Authorization: Bearer $(grep SLACK_BOT_TOKEN ~/.hermes/profiles/<agente>-mac/.env | head -1 | cut -d= -f2)" \
  "https://slack.com/api/auth.test" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'{d.get(\"user_id\",\"UNKOWN\")}')"
```

Repita para cada agente. Anote o mapa.

**Mapa do ambiente {{COMMANDER}} (28/05/2026):**
| Agente Mac | ID | Agente OVH | ID |
|-----------|:---:|-----------|:---:|
| {{ORCHESTRATOR}}-mac | {{SLACK_ID_ORCHESTRATOR}} | {{ORCHESTRATOR}} | {{SLACK_ID_OVH_ORCHESTRATOR}} |
| {{BACKEND_ENGINEER}}-mac | {{SLACK_ID_BACKEND}} | {{BACKEND_ENGINEER}} | {{SLACK_ID_OVH_BACKEND}} |
| {{FRONTEND_ENGINEER}}-mac | {{SLACK_ID_FRONTEND}} | {{FRONTEND_ENGINEER}} | {{SLACK_ID_OVH_FRONTEND}} |
| {{AUDITOR}}-mac | {{SLACK_ID_AUDITOR}} | {{AUDITOR}} | {{SLACK_ID_OVH_PRODUCT}} |
| {{DEVOPS_ENGINEER}}-mac | {{SLACK_ID_DEVOPS}} | {{DEVOPS_ENGINEER}} | {{SLACK_ID_OVH_DEVOPS}} |
| {{GIT_OPS}}-mac | U0B5YAXHPPF | {{GIT_OPS}} | — (só Mac) |

### 3. Substituir IDs OVH → Mac

Em TODOS os profiles Mac, substituir IDs OVH por Mac nos arquivos:
`config.yaml`, `AGENTS.md`, `TEAM.md`, `TOOLS.md`, `SOUL.md`, `IDENTITY.md`, `USER.md`, `HEARTBEAT.md`

```bash
for agent in dalinar-mac navani-mac shallan-mac jasnah-mac kaladin-mac pattern-mac; do
  for f in config.yaml AGENTS.md TEAM.md TOOLS.md SOUL.md IDENTITY.md HEARTBEAT.md USER.md; do
    [ -f "$HOME/.hermes/profiles/$agent/$f" ] || continue
    sed -i '' \
      -e 's/{{SLACK_ID_OVH_ORCHESTRATOR}}/{{SLACK_ID_ORCHESTRATOR}}/g' \  # {{ORCHESTRATOR}} OVH → {{ORCHESTRATOR}}-mac
      -e 's/{{SLACK_ID_OVH_BACKEND}}/{{SLACK_ID_BACKEND}}/g' \  # {{BACKEND_ENGINEER}} OVH → {{BACKEND_ENGINEER}}-mac
      -e 's/{{SLACK_ID_OVH_FRONTEND}}/{{SLACK_ID_FRONTEND}}/g' \  # {{FRONTEND_ENGINEER}} OVH → {{FRONTEND_ENGINEER}}-mac
      -e 's/{{SLACK_ID_OVH_PRODUCT}}/{{SLACK_ID_AUDITOR}}/g' \  # {{AUDITOR}} OVH → {{AUDITOR}}-mac
      -e 's/{{SLACK_ID_OVH_DEVOPS}}/{{SLACK_ID_DEVOPS}}/g' \  # {{DEVOPS_ENGINEER}} OVH → {{DEVOPS_ENGINEER}}-mac
      "$HOME/.hermes/profiles/$agent/$f"
  done
done
```

**Verificar:** Zero IDs OVH remanescentes:
```bash
for agent in dalinar-mac navani-mac shallan-mac jasnah-mac kaladin-mac pattern-mac; do
  ovh=$(grep -c '{{SLACK_ID_OVH_ORCHESTRATOR}}\|{{SLACK_ID_OVH_BACKEND}}\|{{SLACK_ID_OVH_FRONTEND}}\|{{SLACK_ID_OVH_PRODUCT}}\|{{SLACK_ID_OVH_DEVOPS}}' \
    "$HOME/.hermes/profiles/$agent/AGENTS.md" 2>/dev/null)
  mac=$(grep -c '{{SLACK_ID_ORCHESTRATOR}}\|{{SLACK_ID_BACKEND}}\|{{SLACK_ID_FRONTEND}}\|{{SLACK_ID_AUDITOR}}\|{{SLACK_ID_DEVOPS}}' \
    "$HOME/.hermes/profiles/$agent/AGENTS.md" 2>/dev/null)
  echo "$agent: OVH=$ovh Mac=$mac"
done
```

### 4. Atualizar Nomes (adicionar sufixo `-mac`)

Em SOUL.md, IDENTITY.md, USER.md, HEARTBEAT.md, AGENTS.md, TEAM.md:

```bash
# Padrões de substituição (um sed por agente):
# "— {{ORCHESTRATOR}}" → "— {{ORCHESTRATOR}}-mac"
# "# {{ORCHESTRATOR}} —" → "# {{ORCHESTRATOR}}-mac —"
# "pela ótica de {{ORCHESTRATOR}}" → "pela ótica de {{ORCHESTRATOR}}-mac"

sed -i '' \
  -e 's/^# {{ORCHESTRATOR}} —/# {{ORCHESTRATOR}}-mac —/' \
  -e 's/^# [A-Z]\+\.md — {{ORCHESTRATOR}}$/# &-mac/' \
  -e 's/— {{ORCHESTRATOR}}$/— {{ORCHESTRATOR}}-mac/' \
  -e 's/de {{ORCHESTRATOR}} /de {{ORCHESTRATOR}}-mac /g' \
  "$HOME/.hermes/profiles/dalinar-mac/SOUL.md"
# Repetir para cada agente com seu nome
```

**Verificar double `-mac` (caso sed rode duas vezes):**
```bash
grep -c '\-mac-mac' *.md  # Deve ser 0
sed -i '' 's/-mac-mac/-mac/g' *.md  # Correção se necessário
```

### 5. Atualizar .gitignore do Monorepo (Lado OVH)

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
# Remover do tracking (não deleta local):
for agent in dalinar navani shallan jasnah kaladin pattern; do
  for f in SOUL.md IDENTITY.md TEAM.md TOOLS.md USER.md AGENTS.md HEARTBEAT.md config.yaml; do
    git rm --cached "$agent/$f" 2>/dev/null
  done
  git rm --cached -r "$agent/memories/" 2>/dev/null
done
git commit -m "emancipacao: remove identidade/memoria/config do tracking"
git push
```

### 6. Atualizar Crontab (Mac)

Substituir o cron anterior (que só fazia `git push`) por:

```cron
# sync-m4-ovh — Git monorepo + rsync skills para profiles Mac
0 * * * * (cd ~/Dev/hermes-profiles && git pull --rebase --autostash \
  && git add -A && git diff --quiet || git commit -m "auto-sync $(date +'\%Y-\%m-\%d \%H:\%M')" \
  && git push origin main) \
  && for agent in dalinar navani shallan jasnah kaladin pattern; do \
       rsync -a ~/Dev/hermes-profiles/$agent/skills/ \
         ~/.hermes/profiles/${agent}-mac/skills/ 2>/dev/null; \
     done

# obsidian-vault — backup git (commit + push autorizado por {{COMMANDER}} 28/05/2026)
30 * * * * cd ~/Dev/obsidian && git add -A && git diff --quiet \
  || (git commit -m "auto-backup $(date +'\%Y-\%m-\%d \%H:\%M')" \
  && git push origin main)
```

Notas:
- `git pull --rebase --autostash` evita conflitos com o que o outro ambiente empurrou
- `rsync skills` sem `--delete` — skills exclusivas do Mac são preservadas
- Obsidian agora com `git push` autorizado — {{GIT_OPS}}s não precisam mais de permissão explícita

### 7. Atualizar {{GIT_OPS}} — Push Liberado

Remover travas de push manual do SOUL.md e IDENTITY.md do {{GIT_OPS}}-mac:

| Arquivo | Antes | Depois |
|---------|-------|--------|
| SOUL.md | `Nunca execute git push sem autorização explícita do {{COMMANDER}} ou {{ORCHESTRATOR}}.` | `Push automático autorizado. git push é livre. {{COMMANDER}} autorizou em 28/05/2026.` |
| IDENTITY.md (domínio) | `git add -A && git commit && git push sob autorização.` | `git add -A && git commit && git push automáticos.` |
| IDENTITY.md (escala) | `git push: nunca sem autorização explícita ({{COMMANDER}} ou {{ORCHESTRATOR}}).` | `git push: automático — autorizado por {{COMMANDER}} (28/05/2026).` |

### 8. Coordenação Cross-Ambiente

Ambos os {{ORCHESTRATOR}}s (Mac e OVH) devem:

1. Adicionar o ID um do outro em seus AGENTS.md e TEAM.md
2. Registrar a regra: "{{ORCHESTRATOR}}-mac ↔ {{ORCHESTRATOR}} OVH — contato direto autorizado para coordenar equipes"
3. Cada {{ORCHESTRATOR}} coordena APENAS sua própria equipe (Mac ou OVH)
4. Usar o Slack `#operacao` para comunicação cross-ambiente

**Exemplo (AGENTS.md — {{ORCHESTRATOR}}-mac):**
```markdown
Mapa oficial de menções:
- {{ORCHESTRATOR}}-mac: `<@{{SLACK_ID_ORCHESTRATOR}}>`
- {{ORCHESTRATOR}} OVH: `<@{{SLACK_ID_OVH_ORCHESTRATOR}}>` (coordenação cross-ambiente)
- {{BACKEND_ENGINEER}}: `<@{{SLACK_ID_BACKEND}}>`
...

## Coordenação entre ambientes (autorizado por {{COMMANDER}} — 28/05/2026)
- {{ORCHESTRATOR}}-mac ↔ {{ORCHESTRATOR}} OVH (`<@{{SLACK_ID_OVH_ORCHESTRATOR}}>`) — contato direto autorizado
  para coordenar as equipes Mac e OVH.
- Cada {{ORCHESTRATOR}} coordena sua própria equipe. Não interferir nos agentes do outro ambiente.
```

### 9. Verificação Final

- [ ] Nenhum symlink: `[ -L ~/.hermes/profiles/*-mac/ ]` retorna false
- [ ] IDs OVH: `grep` nos AGENTS.md retorna zero
- [ ] IDs Mac: `grep` nos AGENTS.md retorna 5 IDs corretos
- [ ] Nomes com `-mac` em SOUL.md e IDENTITY.md
- [ ] Bot IDs confirmados via Slack API (curl /auth.test)
- [ ] Cron dry-run: `cd ~/Dev/hermes-profiles && git status` está limpo
- [ ] Rsync skills: `ls -R ~/.hermes/profiles/*-mac/skills/ | wc -l` mostra skills
- [ ] .gitignore atualizado com exclusões de identidade
- [ ] {{GIT_OPS}} OVH e {{GIT_OPS}}-mac com push automático liberado
- [ ] AGENTS.md/TEAM.md de ambos os {{ORCHESTRATOR}}s com ID cross-ambiente
- [ ] Crontab instalado: `crontab -l` mostra as 2 linhas corretas

## ⚠️ Pitfalls Específicos

1. **~ expansion in grep:** `"~/foo"` com aspas duplas não expande `~`. Usar `$HOME/foo`.
2. **Double `-mac-mac`:** Se sed rodar duas vezes, ocorre duplicação. Corrigir com `sed -i '' 's/-mac-mac/-mac/g'`.
3. **config.yaml `instructions` field é YAML multiline:** IDs aparecem como texto literal. `sed` funciona mas verificar com `grep` depois.
4. **Bot IDs documentados != reais:** Documentação pode estar desatualizada. Sempre verificar via Slack API.
5. **`.clean_shutdown` files:** Runtime markers que vazam pro staging. Adicionar ao `.gitignore`.
6. **Sinal verde do {{COMMANDER}} — execute, não debata:** Quando ele mostra `launchctl load -w` executado ou pergunta "já fez sua parte?", aja imediatamente.
7. **Skills criadas no Mac:** Sem `--delete` no rsync, skills exclusivas do Mac são preservadas. Se quiser propagá-las para OVH, precisam ser commitadas no monorepo.
8. **LaunchAgent loading — carregar TODOS, não apenas um:** `launchctl load -w com.{{COMMANDER}}.hermes.dalinar-mac.plist` carrega SÓ o {{ORCHESTRATOR}}. Os outros 5 agentes (navani, shallan, jasnah, kaladin, pattern) ficam com plists em disco mas NUNCA registrados no launchd. Após break dos symlinks + customização, é necessário carregar TODOS os plists explicitamente. Verificar com `launchctl list | grep hermes`. Se algum PID estiver faltando, carregar individualmente ou com loop.
