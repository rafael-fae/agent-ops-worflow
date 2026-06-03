---
name: execucao-wave-auditoria
description: Ciclo completo de execução de wave de implementação com auditoria independente, triagem de blockers, correção e commit. Usado quando {{ORCHESTRATOR}} recebe ordem do Comandante para implementar gaps.
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Execução de Wave com Ciclo de Auditoria

## Trigger

Quando o Comandante ({{COMMANDER}}) ou {{ORCHESTRATOR}} inicia uma **wave de implementação** — conjunto de gaps/features a implementar com supervisão de qualidade.

## Papéis na Wave

| Papel | Agente | Responsabilidade |
|:------|:--------|:-----------------|
| Orquestrador | {{ORCHESTRATOR}} | Decompor demanda, delegar, priorizar blockers, consolidar report |
| Implementador | {{BACKEND_ENGINEER}} | Executar implementações + corrigir apontamentos da auditoria |
| Auditor | {{AUDITOR}} | Validar cada item independentemente, triar por severidade |
| Git Ops | {{GIT_OPS}} | Branch, commit, push, log no vault |

## Estrutura

### 1. {{ORCHESTRATOR}} — Decomposição e Delegação

```
:red_circle: ORDEM URGENTE — [contexto]

<@{{SLACK_ID_BACKEND}}> {{BACKEND_ENGINEER}} — IMPLEMENTAR:
1. [item concreto 1]
2. [item concreto 2]
...

<@{{SLACK_ID_AUDITOR}}> {{AUDITOR}} — AUDITAR:
1. Validar implementações da {{BACKEND_ENGINEER}}
2. Rodar validation commands
3. Documentar em AUDITORIA-FINAL-{{AUDITOR_UPPER}}.md

<@{{SLACK_ID_GITOPS}}> {{GIT_OPS}} — branch para a wave, pull latest
```

**🔴 RECURSOS DONTUS em TODA delegação:** Antes de delegar QUALQUER task, avaliar se o agente precisa consultar o Dontus (site ao vivo https://sistema.dontus.com.br ou DontusClient via {{OVH_SSH_COMMAND}}). Se relevante, incluir credenciais ({{COMMANDER}} / {{DONTUS_PASSWORD}} / {{DONTUS_CLINICA_ID}}), o que consultar (UX, modelos, fluxos), e proibição explícita de modificar dados. **NUNCA esquecer** — já esquecido múltiplas vezes.

### 2. Implementador — Execução

- Validar com comandos reais (`python manage.py check`, `uv sync`)
- Se tarefa já estiver implementada, reportar claramente
- Reportar após cada item concluído
- Corrigir na ordem definida pelo orquestrador

### 3. Auditor — Validação com Triagem

Classificar cada achado por severidade:

| Severidade | Símbolo | Critério | Ação |
|:-----------|:-------:|:---------|:-----|
| **CRÍTICO** | :red_circle: | Bloqueia execução/deploy | Corrigir antes de qualquer avanço |
| **MÉDIO** | :large_yellow_circle: | Impacta qualidade/segurança mas não bloqueia | Corrigir após CRÍTICOS |
| **RESOLVIDO** | :large_green_circle: | Era problema, agora está corrigido | Documentar |

Formato da tabela de auditoria:

```
| Item | Comando | Status |
|:----:|:--------|:------:|
| 1. TenantMiddleware | Adicionar | :white_check_mark: Presente, mas ordem INCORRETA |
```

### 4. {{ORCHESTRATOR}} — Priorização e Correção

Após receber auditoria:
- Repassar CRÍTICOS primeiro ao implementador
- Exigir `manage.py check` após cada correção
- MÉDIOS podem ser feitos na sequência ou deferidos se fora de escopo
- Colateral fixes (problemas encontrados durante auditoria fora do escopo original) **devem ser incluídos** — o Comandante valoriza

### 5. Re-validação

Auditor re-valida após correções:
- `uv sync` :white_check_mark: | `manage.py check` :white_check_mark:
- Tabela antes/depois das correções
- Veredito final: **APROVADO** ou **REPROVADO**

### 6. Commit ({{GIT_OPS}})

```bash
cd ~/Dev/<projeto-correto>/   # ← VERIFICAR DIRETÓRIO!
git checkout -b wave/YYYY-MM-DD-descricao
git add -A
git commit -m "wave: resumo conciso

- Item 1
- Item 2
- Fix: item X
- Auditoria: {{AUDITOR}} aprovada (docs/refinamentos/AUDITORIA-FINAL-{{AUDITOR_UPPER}}.md)"
git push origin wave/...
```

Registrar log em `99_System/{{GIT_OPS}}/Logs/`.

## Variant: Planning-Only Wave (Cron-Driven)

When the wave is a **planning-only cycle** (no code written, only documents produced), adapt the standard execution flow:

### Trigger
- Cron job at a scheduled time (e.g., 05:30, 07:30, 11:00)
- Fase explicitly stated as "PLANEJAMENTO, NÃO IMPLEMENTAÇÃO"
- Task: consolidate existing plans, find gaps, produce unified report

### Flow Differences from Standard Wave

| Aspect | Standard Wave | Planning-Only Wave |
|--------|:------------:|:------------------:|
| Output | Code + docs | Documents only |
| Agents | Full team | {{ORCHESTRATOR}} (+ subagents for research) |
| Auditor | Validates code | Validates docs vs code state |
| Git push | Yes (branch) | Commit planning docs only |
| Success metric | `manage.py check` passes | Report covers all gaps |

### Key Difference: Tier 1 Action Items

A planning-only wave produces a **debt inventory** — a prioritized list of actions for the next implementation wave. This is the only tangible output that drives real change.

**Must include in the report:**
1. Previous wave's Tier 1 that were NOT executed (planning debt)
2. New gaps discovered
3. Updated gap count (to track inflation)
4. Clear "next: aguardando sinal verde" statement

### Accountability Check

After every planning-only wave, explicitly verify if the **previous** planning wave's action items were implemented:

```bash
# Check if items from previous wave were committed
git log --oneline --since="<previous-wave-time>"
git diff <previous-planning-commit-hash>..HEAD --stat

# Key question: were Tier 1 bugs actually fixed?
grep -n "_register_invalidation_key\|CACHES\|encryption" apps/core/middleware/cache.py scripts/backup.sh 2>/dev/null
```

Document any discrepancy: "Wave N planning committed to fix X bugs, but NONE were implemented in the commits since then."

### Output
- Consolidated document in `docs/refinamentos/WAVE-OPUS-{HHMM}-FINAL.md`
- Clear "implemented vs planned vs pending" table
- Planning debt from previous waves explicitly tracked

## Variant: Gap Inflation Tracking

When running successive planning/audit waves (every 4h), the total gap count can inflate rapidly as each wave discovers new issues while previous wave's fixes remain unexecuted.

### Tracking {{GIT_OPS}}

After each wave, record the gap evolution:

```
Wave 0530: 13 gaps (original) + 5 new (G15-G19) = 18 total
Wave 0730: 18 + 5 new (G20-G24) = 23 total
Wave 1100: 23 + 4 unplanned = 27 total
```

### When to Alert

If gap count increases by >30% between successive waves without any implementation occurring, flag to the Comandante:
- "Gaps inflating from N to M across X waves with zero implementation — recommend HALVING the audit cycle frequency to let implementation catch up, OR dedicating a full implementation wave."

This prevents the "death by gap discovery" spiral where each planning wave finds more problems than the previous wave's fixes could address.

## Variant: {{ORCHESTRATOR}} Direct Audit (Single Task)

Quando a wave consiste em **uma única task** ou {{ORCHESTRATOR}} opta por auditar pessoalmente (sem delegar a {{AUDITOR}}):

### Fluxo
1. Receber report do implementador no Slack (checkboxes, resumo)
2. **Localizar o projeto** — `find ~/Dev -maxdepth 1 -type d -name "*<nome>*" 2>/dev/null` se o path exato não for conhecido. Confirmar com `ls <path>/config/` ou `git -C <path> status`.
3. **Verificar existência dos arquivos** — `ls` ou `stat` no diretório correto do projeto (`~/Dev/<projeto>/`). Não confiar em paths assumidos.
4. **Ler arquivos modificados** — `read_file` nos arquivos listados pelo implementador. Verificar linha por linha os itens do checklist.
5. **Rodar testes independentemente** — `python3 -m pytest <test_file> -v --tb=short` (NUNCA confiar só no report do agente). Cross-check: se o agente alega "11/11 PASSED", rodar você mesmo e conferir o número de testes, a contagem de passed/failed, e o tempo de execução. Um report de "0.03s" para 11 testes é consistente; um report de "0.00s" ou tempo muito alto para poucos testes sugere output fabricado.
6. **Verificar CI status do commit auditado** — `gh run list --branch develop --limit 10`. Confirmar que o commit hash do implementador consta como `✓`. Se o CI estiver em `failure`, verificar logs para determinar se a falha é preexistente ou causada pelo commit. CI failure sem justificativa = task reaberta. **Não confiar no auto-report do agente — verificar diretamente.**
7. **Verificar hash de commit e remote** — Seguir o protocolo completo da seção Pitfalls (Hash de commit reportado pelo agente é NÃO CONFIÁVEL): `git log --oneline -10` → confirmar hash → `git show <hash> --stat` → `git branch -r --contains <hash>` (confirma push). Mapear os arquivos alterados com `git show <hash> --stat` e cruzar contra o checklist do implementador.
8. **Verificar diff** — `git status --short` + `git diff <hash>~1..<hash>` para confirmar que apenas os arquivos esperados foram alterados (sinal `M` para modificados, `A` para novos). Nenhum arquivo extra, nenhum arquivo faltando.

8a. **Verificar sincronia cross-token (quando task envolve Design System)** — Se a task alterou cores, tokens, ou variáveis CSS, verificar que TODOS os arquivos de tokens estão sincronizados:
   - `design_system/tokens.css` ↔ `static/css/tokens.css` — valores primários idênticos (`primary-600`, `--ds-*` vs `--o-*`)
   - `COMPONENTS-DETAILED.md` — documentação reflete as mesmas cores do código
   - Audit reports — status dos itens corrigidos reflete o commit real
   - Usar `grep -n "#0d9488\|primary-600" *tokens.css` para confirmar consistência. Se houver divergência entre token files, reportar como blocker — não aprovar task até sync estar 100%.

   Referência detalhada: `references/auditoria-pos-task-consistencia.md`

8b. **Verificar consistência cruzada de documentação** — Após task que atualizou PLANO.md, INDEX.md, ou relatórios de auditoria, cruzar as 3 fontes:
   - `PLANO.md` → hash do commit deve existir em `git log --oneline` e corresponder ao que `git show <hash> --stat` mostra
   - `docs/INDEX.md` → entrada atualizada do relatório/auditoria deve refletir o status correto (✅/⬜/👁)
   - Relatório de auditoria → arquivo .md de relatório deve conter os mesmos status reportados pelo agente
   - Se hash no PLANO.md não existir no log, ou INDEX.md não tiver a entrada atualizada, a task não foi devidamente documentada — solicitar correção ao implementador antes de aprovar

8c. **Sincronizar S01-CHECKLIST.md (quando task completa Sprint Item)** — Se a task implementa um item SP1-XX (ex: SP1-19), o `docs/sprint1/S01-CHECKLIST.md` DEVE ser atualizado com TODOS os 7 campos abaixo:

   | # | Campo | Exemplo (antes → depois) |
   |:-:|-------|--------------------------|
   | 1 | Checkbox | `[ ]` → `[x]` |
   | 2 | `Status:` | `❌` → `✅` |
   | 3 | `Critério:` | Atualizar texto para refletir o que foi realmente entregue (ex: "Implementação parcial — sem Grupos/Permissões") |
   | 4 | `Arquivos:` | `(a criar)` → `✅` |
   | 5 | Contagem **do módulo** | `G02: 5 concluídos` → `6` |
   | 6 | Contagem **total** | `13 concluídos` → `14` |
   | 7 | Frontmatter `updated:` | Atualizar data para o dia corrente |

   **Regra:** não pular nenhum dos 7. Pular a contagem total (6) ou o frontmatter (7) é erro de auditoria — a task não está devidamente documentada até o checklist refletir o estado real do sprint.

9. **Commit + push** — se {{GIT_OPS}} for o responsável pelo commit, apenas sinalizar a pendência no veredito. Se {{ORCHESTRATOR}} estiver commitando (ex: PLANO.md/INDICE.md/S01-CHECKLIST.md updates): mensagem estruturada `task_XX: resumo curto\\n\\n- mudança 1\\n- mudança 2\\n- testes: N/N PASSED`. Incluir na mensagem quais docs foram atualizados (ex: "PLANO.md: task_17 ✅, S01-CHECKLIST.md: SP1-19 ✅").
10. **Report com tabela** — escolher o formato conforme o tipo de auditoria (Expectativa/Realidade, Antes/Depois, ou Comando/Status). Incluir Veredito claro. Atualizar PLANO.md e INDICE.md antes de enviar o report.

### Auditoria de CSS Gerado por Batches Opus

Quando o entregável for CSS concatenado de múltiplos batches Opus, seguir o checklist completo em `references/css-batch-audit-checklist.md`. Checks mínimos obrigatórios: (a) `grep -c '\`\`\`'` para fences markdown — **zero tolerado**; (b) brace balance com Python; (c) cobertura de componentes com `grep -ci`.

### Tabela de Auditoria (Formato Antes/Depois)

Usar quando o foco é **comparar estado anterior vs posterior** (refatoração, correção, adição de feature):

```
| Item | Antes | Depois | Status |
|------|-------|--------|:------:|
| threading.local residual | Zero | Zero confirmado | :white_check_mark: |
| get_current_tenant() alias | Inexistente | context.py:101-112 | :white_check_mark: |
```

**Quando usar Antes/Depois vs Comando/Status:**
- **Antes/Depois**: refatorações, correções, adições de features — onde há transição clara de estado
- **Comando/Status**: verificações de conformidade — onde o item é binário (presente/ausente, passa/falha)

### Tabela de Conformidade (Formato Expectativa/Realidade)

Usar quando se audita **código já implementado por outro agente** — compara-se o que a especificação exige com o que foi entregue:

```
| Item | Expectativa | Realidade | Status |
|------|-------------|-----------|:------:|
| context.py | Zero threading.local, ContextVars PEP 567 | 333 linhas, 3 ContextVar, tokens de reset | :white_check_mark: |
| middleware.py | WSGI + ASGI + Celery, anti-IDOR | 555 linhas, try/finally, _reset_once, copy_context() | :white_check_mark: |
| Teste de isolamento | 300 req × 3 tenants, zero vazamento | 391 linhas, 11/11 PASSED (WSGI + ASGI + barreira + exceção) | :white_check_mark: |
```

**Quando usar Expectativa/Realidade vs outros formatos:**
- **Expectativa/Realidade**: auditoria de entrega feita por outro agente — o código já existe, verifica-se conformidade com a especificação
- **Antes/Depois**: o próprio {{ORCHESTRATOR}} (ou {{BACKEND_ENGINEER}}) fez a mudança — compara-se estado anterior com posterior
- **Comando/Status**: verificações binárias de existência/configuração — "está presente ou não"

### Veredito
Sempre encerrar com **Veredito** claro: "Aprovado sem ressalvas", "Aprovado com ressalvas (ver itens X, Y)", ou "Reprovado — corrigir itens críticos antes do merge".

## Pitfalls

- **Ação corretiva NUNCA sem ordem explícita do {{COMMANDER}}.** Se detectar erro durante auditoria (hash falso, motor errado, arquivo extra), REPORTAR e AGUARDAR — não apagar, não reverter, não corrigir por conta própria.
- **INDICE.md e PLANO.md: atualização IMEDIATA.** Após cada task auditada, atualizar AMBOS antes de passar para a próxima task. ⬜ mantido é falha grave. Ver `references/protocolo-pos-task-indice-plano.md` para o formato exato e checklist.
- **Repositório errado**: {{GIT_OPS}} monitora `~/Dev/obsidian/` por padrão. SEMPRE verificar que a branch é criada no repositório de código (`~/Dev/<projeto>/`), não no vault. O vault só recebe log + docs de auditoria.
- **Diretório do projeto**: O caminho real pode diferir do assumido. Antes de auditar, confirmar com `ls <caminho>/config/` ou `git -C <caminho> status`. Ex: `{{PROJECT_SLUG}}` está em `{{PROJECT_PATH}}/`, não em `~/{{PROJECT_SLUG}}/`.
- **Python = python3 no macOS**: `python` não existe no macOS stock — sempre usar `python3` para pytest, manage.py, etc.
- **Tarefas pré-existentes**: Implementador deve verificar se o item já existe antes de criar. Reportar "já implementado" claramente.
- **Colateral fixes**: Se durante auditoria encontrar problemas além do escopo (ex: `CheckConstraint(check=→condition=)` no Django 6.0, modelos desatualizados no `admin.py`), reportar e corrigir — o Comandante valoriza proatividade.
- **Commando sem verificação**: Nunca commitar sem `manage.py check` verde (erros pré-existentes de apps não implementados são aceitáveis, desde que documentados).
- **Planning debt across successive waves**: When running cron-driven planning waves (e.g., every 4h), the previous wave's Tier 1 items may not be implemented between waves. This causes gap inflation (each new wave finds extra gaps the old wave already knew about). The planning-only wave MUST track this explicitly — compare committed vs done between waves. If 3+ planning waves pass without implementation, default behavior: prepare a consolidated report AND recommend to the Comandante that the next cycle must be implementation-only.
- **Gap count ≠ progress**: A growing gap count between waves does not mean the project is regressing — it means discovery is outpacing implementation. Report the trend explicitly: "Gap count increased from X to Y. Of the Z new gaps, W were already known in previous wave's Tier 1 but unexecuted. Implementation velocity is the bottleneck, not discovery quality."
- **Fabricação de relatório de auditoria**: Se o auditor reportar arquivos com contagens de linhas e tabelas de conteúdo que não existem em `git ls-tree -r` em nenhuma branch, o relatório é fabricado (alucinação). Verificar SEMPRE as 3 camadas antes de aceitar claims do auditor: filesystem local → git remote todas as branches → cross-environment. Protocolo completo em `docs-governance-organization:references/verificacao-cruzada-agentes.md`. Se confirmado: pausar a wave, exigir correção do auditor, manter implementadores em stand-by.
- **Django settings que não garantem comportamento da view**: Configurar `AUTH_COOKIE`/`AUTH_COOKIE_REFRESH` no `SIMPLE_JWT` settings NÃO faz as views retornarem cookies automaticamente. As views padrão do SimpleJWT (`TokenObtainPairView`, `TokenRefreshView`) retornam tokens no corpo JSON — os cookies só são setados se a view explicitamente os adicionar ao response. Além disso, `JWTAuthentication` lê tokens do header `Authorization: Bearer`, não de cookies. Para usar cookies, é necessário `JWTCookieAuthentication` OU sobrescrever `post()` da view. Auditar JWT requer verificar: (a) o que o settings declara, (b) qual authentication class está em uso, (c) o que a view efetivamente retorna. Ver `references/django-jwt-cookie-audit.md` para o caso completo do SimpleJWT.
- **Checkboxes falsos (falso positivo)**: Agentes NÃO devem marcar checkboxes como concluídos sem evidência de execução real. Exemplos comuns: marcar "push de teste" quando o push falhou; marcar "secret configurado" quando o secret não foi criado; marcar "testado" quando o workflow não rodou. O orquestrador DEVE auditar checkboxes contra artefatos reais (commits no remote, secrets na dashboard, logs de execução). Se encontrar checkboxes falsos: reverter para `[ ]`, reportar a discrepância, e priorizar a correção.

  **Exemplo real (task_03, 01/06):** {{GIT_OPS}} marcou checkboxes 6 e 7 como `[x]` mas:
  - Item 6 (`OPENCODE_GO_API_KEY` secret): não foi configurado — e na verdade o workflow nem consumia esse secret
  - Item 7 (Push de teste): o push falhou com `refusing to allow an OAuth App to create or update workflow`
  - Ambos revertidos para `[ ]` pelo orquestrador. Após debugging (7 iterações), o workflow passou verde e os checkboxes foram re-marcados com evidência real (link do workflow run + logs).

  **Regra de ouro**: checkbox `[x]` só com artefato verificável — URL de workflow, screenshot de secret na dashboard, ou hash de commit no remote.

- **Hash de commit reportado pelo agente é NÃO CONFIÁVEL**: Agentes podem fabricar ou digitar incorretamente hashes de commit. O orquestrador DEVE verificar independentemente com `git log --oneline` + `git show <hash> --stat`. Um hash que não aparece no log é falso até prova em contrário. **Caso real (02/06):** {{AUDITOR}} reportou `e7f3a2d` — hash inexistente em qualquer branch. O hash real era `5b9b437`. Só a auditoria independente detectou. Protocolo: `git log --oneline -10` → confirmar que o hash aparece → `git show <hash> --stat` → `git branch -r --contains <hash>` para confirmar push.

- **CI failures são bloqueantes e o agente DEVE reportá-los**: Se o agente commita e o CI falha, a task NÃO está concluída. O agente deve (a) verificar `gh run list --branch develop --limit 5`, (b) ler os logs do run com falha, (c) determinar se a falha é preexistente ou causada pelas alterações, (d) se causada pelas alterações, corrigir e re-commitar. O orquestrador DEVE verificar CI como parte da auditoria — commit com CI `failure` sem justificativa = task reaberta. **Caso real (02/06):** Ambos os commits da task_04 (`5b9b437` e `2594c19`) tiveram CI `failure` — agente não mencionou, orquestrador detectou na auditoria.

- **Confusão de diretórios entre projetos irmãos**: `dontus_app` (Streamlit, `~/Dev/dontus_app/`) e `{{PROJECT_SLUG}}` (Django, `{{PROJECT_PATH}}/`) são projetos DIFERENTES no mesmo `~/Dev/`. O app Streamlit não tem `config/settings/security.py`, `planejamento-diario/`, nem estrutura Django. Ao auditar, verificar que o diretório contém os arquivos esperados (`ls config/settings/security.py`). Se `stat` falhar, está no projeto errado. Usar `find ~/Dev -maxdepth 2 -name 'security.py' -path '*/settings/*'` para localizar o projeto correto. **Caso real (02/06):** {{ORCHESTRATOR}} auditou `dontus_app` primeiro — sem `security.py`, sem `planejamento-diario/`, branch `main` em vez de `develop`. Projeto correto: `{{PROJECT_SLUG}}`.

- **Python: arquivo `.py` sombreia diretório-pacote**: 
  - **Cenário A — `.py` recém-criado colide com pacote existente:** Se existir `foo.py` E `foo/__init__.py` no mesmo diretório, o arquivo `.py` vence — o pacote `foo/` fica inacessível via `import foo`. Isso quebra imports que esperam `foo.submodule`. O orquestrador deve verificar se o agente criou um `.py` que colide com um pacote existente: `ls -d <name>.py <name>/ 2>/dev/null`. Se ambos existirem, o `.py` deve ser removido e o código migrado para dentro do pacote.
  - **Cenário B — diretório sem `__init__.py` convive com `.py` de mesmo nome:** Se `foo.py` existe como módulo original e `foo/` é criado depois (ex: para adicionar `foo/security.py`), mas sem `__init__.py`, o diretório NÃO é pacote Python. Python continua resolvendo `import foo` para o ARQUIVO `.py`. Qualquer `from foo.submodule import *` dentro de `try/except ImportError` falha **silenciosamente** — o sub-módulo nunca é carregado, mas o erro é engolido. **Correção:** mover `foo.py` → `foo/__init__.py` (conteúdo idêntico), remover o `.py` original. O diretório vira pacote legítimo e `foo.submodule` torna-se acessível. **Caso real (02/06/2026):** `config/settings.py` + `config/settings/` (sem `__init__.py`) → `from config.settings.security import *` falhou por meses silenciosamente. CSP, CSRF, CORS, HSTS, JWT — todas as 25 constantes de segurança mortas. Fix: `settings.py` → `settings/__init__.py`. **Caso real (02/06):** {{DEVOPS_ENGINEER}} criou `apps/core/managers.py` que sombreou o pacote `apps/core/managers/` (criado por {{BACKEND_ENGINEER}} em 31/05). Detectado durante auditoria, resolvido removendo o `.py` e expandindo `clinic_scoped.py` existente.

- **Motor divergente sem report — agente deve comunicar falha**: Se o motor designado (ex: Gemini CLI) falhar e o agente decidir usar outro motor (ex: DeepSeek), o agente DEVE reportar a falha e pedir autorização antes de trocar. Trocar silenciosamente dificulta a auditoria. Se a entrega tiver qualidade, aprovar com observação — mas registrar que o motor usado divergiu do especificado na task. **Caso real (02/06):** {{DEVOPS_ENGINEER}} usou DeepSeek V4 Pro em vez de Gemini CLI (motor designado da Wave 1). Auditoria aprovou com ressalva.

- **PLANO.md commit como parte do fechamento da auditoria**: Ao concluir a auditoria de uma task, o orquestrador DEVE atualizar o `PLANO.md` do dia (marcar status da task como ✅) e commitar essa atualização separadamente ou junto com o report. Isso mantém o plano sincronizado com a realidade após cada task. Usar `git add planejamento-diario/YYYY-MM-DD/PLANO.md && git commit -m "docs(plano): task_XX concluída — descrição curta" && git push origin develop`.

## Relatório Final

Formato para {{ORCHESTRATOR}} consolidar ao Comandante:

```
**RELATÓRIO FINAL — Wave [nome]**

| Gap | O quê | Status |
|:---:|:------|:------:|
| GXX | Descrição | :white_check_mark: |

**Fixes incluídos:**
- Item 1
- Item 2

**Equipe:**
- {{BACKEND_ENGINEER}} — implementação + correções
- {{AUDITOR}} — auditoria + revalidação
- {{GIT_OPS}} — branch + commit + log

**Limites Opus utilizados com eficiência.**
```
