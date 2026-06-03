---
name: planejamento-diario
description: Sistema de planejamento diario baseado em markdown para equipe multi-agente. Fluxo completo de 6 fases planejar, aprovar, delegar, executar, auditar, registrar.
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Planejamento Diario — Sistema de Tasks

## Gatilho

- {{COMMANDER}} pede "crie o planejamento do dia"
- Iniciar dia de trabalho com a equipe multi-agente
- Organizar waves de trabalho com multiplos agentes e motores

---

## Os 6 Mandamentos ({{COMMANDER}} 02/06/2026)

Estas 6 regras substituem TODAS as anteriores. Qualquer conflito, estas vencem.

```
🔴 1. INDICE.md e PLANO.md: atualizacao IMEDIATA apos cada task auditada.
     ⬜ mantido = falha grave. Commit hash e 👁 obrigatorios.

🔴 2. PLANEJAR ≠ DELEGAR
     "Planeje" = criar .md + indices. "Solte/delegue" = enviar no Slack.
     Um NAO implica o outro. {{COMMANDER}} e literal.

🔴 3. Gemini 3.1 Pro SEMPRE. DeepSeek PROIBIDO sem ordem explicita.
     Se falhar, dividir em subtarefas. Se ainda falhar, PARAR e reportar.
     O motor no task_XX.md NAO e autoridade — sobrescrever para Gemini.

🔴 4. UMA thread por task — toda comunicacao na MESMA thread.
     Proibido abrir thread nova para correcoes, complementos, re-auditorias.

🔴 5. Canal Mac = {{SLACK_CHANNEL_TEAM}}. {{SLACK_CHANNEL_OVH}} = exclusivo OVH.

🔴 6. ACAO CORRETIVA NUNCA sem autorizacao do {{COMMANDER}}.
     Errou? Reporte e AGUARDE. Nao apagar, nao reverter, nao corrigir.
```

---

## Estrutura de Diretorios

```
projeto/
└── planejamento-diario/
    ├── INDICE.md              ← Indice mestre (TODOS os dias)
    ├── TEMPLATE_PLANO.md      ← Template do plano diario
    ├── TEMPLATE_TASK.md       ← Template de task individual
    └── YYYY-MM-DD/            ← Uma pasta por dia
        ├── PLANO.md           ← Quadro de comando do dia
        ├── task_01.md         ← Briefing + checklist + conclusao
        ├── task_02.md
        └── ...
```

---

## Formato Padrao do INDICE.md

```markdown
## DD/MM/AAAA — N/X

| Task | Agente | Descricao | SP | ✅ | 👁 | Commit |
|------|--------|-----------|-----|---|---|--------|
| task_01 | Agente | Descricao curta | Modulo | ✅ | 👁 | hash |
```

**Legenda:** ✅ = agente concluiu | 👁 = {{ORCHESTRATOR}} auditou e aprovou | ⬜ = pendente

**Regras:**
- SP = codigo do modulo (K3, G02, G05, DS, infra, docs, devops, —)
- Contador N/X: N = tasks com ✅, X = total de tasks do dia. Recalcular apos cada task.
- Atualizar IMEDIATAMENTE apos cada auditoria. Commit hash obrigatorio.
- Ao adicionar tasks durante o dia, popula-las no indice na hora.

---

## O Ciclo Diario — 6 Fases

```
FASE 1 — PLANEJAR (criar .md + indices)
FASE 2 — APROVAR ({{COMMANDER}} revisa e autoriza)
FASE 3 — DELEGAR ({{ORCHESTRATOR}} envia no Slack)
FASE 4 — EXECUTAR (agente roda, reporta na thread)
FASE 5 — AUDITAR ({{ORCHESTRATOR}} verifica, atualiza PLANO + INDICE)
FASE 6 — RELATORIO FINAL (tabela consolidada, veredito)
```

---

### Fase 1 — PLANEJAR (criacao)

{{ORCHESTRATOR}} cria:
1. `PLANO.md` — waves com agente, motor, prioridade, status ⬜
2. `task_XX.md` — briefing, Leitura Obrigatoria, checklist, Conclusao
3. `INDICE.md` — adicionar tasks com ⬜, atualizar contador

**Toda task_XX.md DEVE conter:**
- Secao "Leitura Obrigatoria" listando PRD §X + Blueprint §Y
- Secao "Checklist" com itens numerados
- Secao "Conclusao" com campos: Agente, Data, Motor, Commit, Observacoes
- Secao "Restricoes" com: motor obrigatorio, proibido modificar X, NUNCA fazer Y

**Waves:** agrupar tasks por turno e dependencia (Manha, Tarde, Noite, Extra). Cada wave declara motor.

---

### Fase 2 — APROVACAO

{{COMMANDER}} revisa `PLANO.md`. Ajusta prioridades, waves, motores. Da OK verbal.
**NUNCA implementar codigo sem "sinal verde" do {{COMMANDER}}.**

---

### Fase 3 — DELEGACAO (envio no Slack)

**Pre-Delegation Checklist (NUNCA pular):**

[] Motor no task_XX.md e Gemini? Se DeepSeek, sobrescrever para Gemini.
[] **Analise complexidade da task:**
   - Mecanica/configurativa (sem dados, sem risco) → Gemini OK
   - Migracao de dados / FK cross-DB / risco de perda → consultar {{COMMANDER}} se deve escalar para Opus
   - DS / UI / visao → Opus ({{FRONTEND_ENGINEER}})
[] Dontus: o agente precisa consultar o sistema ao vivo para esta task?
   Sim → incluir URL + credenciais + proibicao de modificar na msg
   Nao → ok, seguir
[] {{COMMANDER}} autorizou esta task especifica? (So delegar 1 por vez, ou multiplas se autorizado)
[] Ja existe thread aberta para esta task? Se sim, responder na thread — nunca abrir nova.

**Template completo da mensagem:**

```
<@AGENTE_ID> task_N — Titulo. Wave X. Prioridade 🔴.

ORDEM ABSOLUTA: Motor EXCLUSIVAMENTE [CLI] ([comando exato]).
NAO usar outro. Se falhar, PARAR e reportar.

1. Instrucao 1
2. Instrucao 2
N. COMMIT + PUSH

Leitura Obrigatoria: PRD §X, Blueprint §Y.

Restricoes: [motor], NAO modificar X, NUNCA Y.

Recursos Dontus: https://sistema.dontus.com.br (consultar se necessario).
NUNCA modificar dados no Dontus.
Credenciais: {{COMMANDER}} / {{DONTUS_PASSWORD}} / {{DONTUS_CLINICA_ID}}
```

**Regras da delegacao:**
1. `<@USER_ID>` no INICIO da mensagem — zero texto antes
2. Sem tabelas/pipes na mesma msg — quebram parser de mencao
3. "ORDEM ABSOLUTA" + motor + comando exato — obrigatorio
4. **UMA task = UMA thread** — primeira mensagem ABRE a thread
5. Recursos Dontus: SEMPRE avaliar e incluir se relevante
6. **So delegar 1 task por vez** (ou multiplas se {{COMMANDER}} autorizar)
7. Verificar motor no task_XX.md — se DeepSeek, sobrescrever para Gemini

---

### Fase 4 — EXECUCAO (pelo agente)

O agente:
1. Le PRD + Blueprint (leitura obrigatoria ANTES de executar)
2. Le task_XX.md
3. Executa no motor especificado (NUNCA trocar sem autorizacao)
4. Marca checkboxes `[x]` ao concluir cada item
5. Preenche secao Conclusao (data, motor real, commit hash, observacoes)
6. COMMIT + PUSH
7. Reporta na MESMA thread: `@{{ORCHESTRATOR}} task_N concluida. Commit: hash.`

---

### Fase 5 — AUDITORIA (por {{ORCHESTRATOR}})

{{ORCHESTRATOR}}:
1. Le relatorio do agente na thread
2. Verifica commits: `git log --oneline -3` + `git show <hash> --stat`
3. Verifica diff: apenas arquivos esperados foram alterados
4. Le arquivos criados/modificados
5. Se aprovado:
   - Atualiza `PLANO.md` (status ✅)
   - Atualiza `INDICE.md` (hash, 👁)
   - `git add + commit + push` dos registros
   - Reporta veredito na thread
6. Se precisa de correcao: lista o que mudar, aguarda novo reporte, re-audita

**Self-report do agente NAO e confiavel.** Sempre verificar:
- Hash existe em `git log --oneline`
- Push confirmado: `git branch -r --contains <hash>`
- Se CI existe: `gh run list --branch develop --limit 5`
- Diff real com `git show` — modelo mente sobre ter escrito arquivos

---

### Fase 6 — RELATORIO FINAL (fim do dia)

{{ORCHESTRATOR}} produz tabela consolidada no Slack:

```
| Task | Agente | Wave | Status | Observacoes |
|------|--------|------|--------|-------------|
| task_01 — desc | Agente | Manha | ✅ | commit hash |
```

- Veredito por task (✅/⚠️/❌)
- Proximo passo claro
- Commitar todos os registros (PLANO.md, INDICE.md)

---

## Hierarquia de Motores (02/06/2026)

| Prioridade | Motor | Uso | Comando |
|:----------:|-------|-----|---------|
| 1o PADRAO | Gemini 3.1 Pro | SEMPRE — TODAS as tasks de codigo | `gemini -m "gemini-3.1-pro-preview"` |
| 2o | Opus 4.7 | Exclusivo {{FRONTEND_ENGINEER}} (DS/visao/UI) | `claude --print --dangerously-skip-permissions --effort max` |
| — | DeepSeek V4 Pro | PROIBIDO sem ordem explicita do {{COMMANDER}} | — |

**:red_circle: REGRA ABSOLUTA:** Gemini 3.1 Pro e o motor padrao. Se falhar (RESOURCE_EXHAUSTED, erro), dividir em subtarefas menores — NUNCA trocar de modelo. Se ainda falhar, PARAR e reportar ao {{ORCHESTRATOR}} que reporta ao {{COMMANDER}}.

**:red_circle: O motor no task_XX.md NAO e autoridade.** Pode conter "DeepSeek" como residuo de planejamento. Sobrescrever para Gemini. Verificar antes de delegar.

### Criterios de Selecao — Gemini vs Opus (03/06/2026)

Quando {{COMMANDER}} pergunta "Gemini e suficiente ou Opus?" (padrao recorrente), aplicar esta heuristica:

| Cenario | Motor | Razao |
|---------|-------|-------|
| Configuracao mecanica (mover apps, ajustar settings, mudar router) | Gemini OK | Baixo risco, trabalho mecânico |
| Migracao de dados (replicar tabelas, ETL, seed) | Gemini para inicio, **escalar para Opus se houver FKs cross-DB ou dados irreversiveis** | Risco de perda de dados justifica custo do Opus |
| Inspecao de FKs, constraints, relacoes complexas | Opus recomendado | Modelo mais confiavel para detectar consistência |
| Design System / UI / visao | Opus SEMPRE ({{FRONTEND_ENGINEER}}) | Qualidade visual superior |
| Auditoria de codigo alheio (cross-validate) | Opus recomendado | Exige deteccao de sutilezas |
| Tasks simples e bem definidas (1 arquivo, sem dados) | Gemini OK | Custo mais baixo, mesma qualidade |

**Regra pratica:** se a task envolve *perda de dados, FK cross-DB, migracao irreversivel, ou validacao de terceiros* — considerar Opus. Se e configuracao mecanica ou implementacao direta — Gemini e suficiente.

---

## Meta-uso: aplicando o workflow ao proprio projeto

O workflow `planejamento-diario` pode ser usado de forma **auto-referencial** — ou seja,
para planejar a criacao do proprio projeto que documenta o workflow. Isso serve como:

- **Prova viva** de que o workflow funciona (as pessoas veem o plano dentro do projeto)
- **Validacao pratica** — se o workflow nao funciona para planejar a si mesmo, nao funciona para nada
- **Demonstracao didatica** — novos usuarios podem ver o fluxo em acao

### Exemplo: agent-ops-workflow (03/06/2026)

O repositorio `agent-ops-workflow` (template publico do fluxo) contem:

```
agent-ops-workflow/
└── planejamento-diario/         ← O PLANO dentro do proprio projeto
    ├── INDICE.md                 ← 10 tasks, 0/10
    └── 2026-06-03/
        ├── PLANO.md              ← 4 waves de criacao do template
        ├── task_01.md            ← Mapear skills → files/
        ├── ...
        └── task_10.md            ← Publicar no GitHub + auditar
```

**Regras do meta-uso:**
1. O planejamento-diario do projeto meta fica DENTRO do repositorio (nao em {{PROJECT_PATH}})
2. Usar os MESMOS templates (PLANO.md.tpl, TASK.md.tpl) que estao sendo criados para o publico
3. O INDICE.md e o registro historico da construcao do proprio projeto
4. Ao final, o planejamento-diario permanece no repositorio como documentacao viva e exemplo funcional
5. Cada task_XX.md preenchida com conclusao real vira um case de uso documentado

### Gatilhos do meta-uso

- Criar template publico / open-source do workflow
- Documentar o workflow enquanto o utiliza (dogfooding)
- Onboarding de novos usuarios demonstrando na pratica
- Palestras, workshops, tutoriais

---

## Sanitizacao para Publicacao (criar templates publicos a partir de projetos internos)

Quando o {{COMMANDER}} pede para criar uma versao publica de ferramentas internas
(ex: `agent-ops-workflow`), seguir este protocolo:

### Fase 1 — Staging (nunca tocar nos originais)

1. Criar pasta `files/` no diretorio do novo projeto
2. **Copiar** (nunca mover) arquivos originais para `files/<categoria>/raw/`
   - Skills → `files/skills/raw/`
   - Scripts → `files/scripts/raw/`
   - Templates → `files/templates/raw/`
3. Criar `MANIFEST.md` em `files/` com inventario completo

### Fase 2 — Sanitizacao

1. Criar diretorio `files/<categoria>/sanitized/`
2. Para cada arquivo raw, criar copia sanitizada substituindo:
   - Nomes de agentes → `{{ORCHESTRATOR}}`, `{{BACKEND_ENGINEER}}`, etc.
   - Nome do projeto → `{{PROJECT_NAME}}`
   - Nome do comandante → `{{COMMANDER}}`
   - IDs Slack, canais, URLs → `{{SLACK_CHANNEL_TEAM}}`, `{{BLOG_URL}}`
   - Credenciais → `{{DONTUS_PASSWORD}}` (ou remover)
3. Adicionar comment header em cada arquivo sanitizado
4. Verificar com `grep -rn "TermoOriginal" sanitized/ || echo "OK"`

### Fase 3 — Montagem do repositorio final

1. Skills sanitizadas vao para `skills/` na raiz do projeto
2. Templates vao para `templates/` com placeholders `__PLACEHOLDER__`
3. Scripts vao para `scripts/` com variaveis de configuracao
4. Documentacao vai para `docs/`
5. **Remover `files/`** antes do primeiro commit (`git add` confirmar que nao entrou)
6. Adicionar `files/` ao `.gitignore` (seguranca extra)

### Regras de ouro da sanitizacao

- 🔴 **NUNCA modificar arquivos originais** — so mexe em copias em `files/`
- 🔴 `files/` NUNCA e commitada — e area de trabalho temporaria
- 🔴 Placeholders usam `{{NOME}}` em skills e `__NOME__` em templates (distincao intencional)
- 🟢 Manter comentarios e didatica — outras pessoas vao ler
- 🟢 Manter o `planejamento-diario/` no repositorio final como prova viva

### Referencia

- `references/sanitizacao-publicacao.md` — detalhes da implementacao real do `agent-ops-workflow`

---

## Referencias Externas

- `references/tutorial-equipe-roshar.md` — tutorial publicado em {{BLOG_URL}}/equipe-roshar com visao geral do fluxo para novos integrantes
- `references/sanitizacao-publicacao.md` — protocolo de sanitizacao usado na criacao do template publico agent-ops-workflow

## Automacao — Cron Job Diario

```bash
hermes --profile dalinar cronjob create \
  --name "planejamento-diario-5am" \
  --schedule "0 5 * * *" \
  --skills planejamento-diario \
  --prompt "Gere o plano diario..."
```

⚠️ Cron usa hora LOCAL, nao UTC.
⚠️ Cron gera .md mas NAO delega no Slack — delegacao e manual.
⚠️ Cron pode gerar plano de "recuperacao" obsoleto se dia anterior nao executou. Verificar e limpar.

---

## Pitfalls (selecionados)

1. **Mencoes Slack quebradas por tabelas:** `<@USER_ID>` + `|` na mesma msg quebram parser. Mencao em linha isolada, sem markdown complexo na mesma mensagem.
2. **Pipe duplicado em patches de tabelas:** Ao usar `patch` em tabelas markdown, matching fuzzy pode adicionar `|||`. Preferir `patch` com blocos grandes de contexto ou `sed`/`perl`. Sempre verificar com `read_file` apos patch.
3. **Checklists vazios:** Agentes esquecem de preencher. Reforcar na delegacao. Preenchimento ANTES de reportar.
4. **Thread quebrada:** Agentes respondem no canal em vez da thread. So {{ORCHESTRATOR}} posta no canal.
5. **Delegacao sem autorizacao:** Criar task_XX.md ≠ delegar. So enviar no Slack quando {{COMMANDER}} autorizar.
6. **Motor errado:** Agente usa DeepSeek sem autorizacao. ORDEM ABSOLUTA na delegacao previne.
7. **Hash de commit falso:** Agente reporta hash que nao existe. SEMPRE verificar com `git log`.
8. **Indice desatualizado:** {{ORCHESTRATOR}} esquece de atualizar INDICE/PLANO apos auditoria. ⬜ mantido = falha grave.
9. **Docker command: sobrescreve CMD:** `docker-compose.yml` com `command:` anula CMD do Dockerfile.
10. **Cron gera plano de recuperacao obsoleto:** Tasks ja concluidas podem ser replicadas. Verificar e limpar.
