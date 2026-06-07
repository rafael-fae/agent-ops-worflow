---
name: docs-governance-organization
description: Auditoria de conformidade + organização de documentação .md em repositórios de planejamento. Cobre inventário, classificação, indexação, regras de frontmatter, cross-linking, e uso de Gemini 3.1 Pro para processamento de ~150+ arquivos.
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Documentação: Governança e Organização

## Gatilho

- {{COMMANDER}} ou {{ORCHESTRATOR}} solicita auditoria de pasta de documentação para verificar se contém APENAS planejamento (não código)
- {{COMMANDER}} solicita organização de documentação existente, criação de índices, ou estabelecimento de regras
- Um repositório de planejamento está poluído com código de desenvolvimento (Django, config, templates, static)
- Documentos estão soltos em diretórios sem índice mestre, sem padrão de nomenclatura, sem cross-links
- Documentação descritiva precisa ser organizada e sistematizada

## Premissas

1. **Nada é deletado** — todo conteúdo existente é preservado. A organização é aditiva (índices, regras) e reorganizacional (movimentação segura), nunca destrutiva.
2. **Separação docs vs código** — repositórios de planejamento contêm APENAS .md, prompts, specs, auditados. Código Django/React/etc. pertence a branch `develop` ou repositório separado.
3. **Gemini 3.1 Pro para contexto grande** — Para processar ~150+ arquivos .md simultaneamente, use Gemini 3.1 Pro (2M tokens de contexto). O Claude Opus tem contexto limitado e é reservado para profundidade técnica.
4. **Índices antes de movimentação** — Nunca mover arquivos sem primeiro criar os índices que referenciam os novos caminhos. Links quebrados são inaceitáveis.

## Papéis

| Papel | Agente | Responsabilidade |
|:------|:--------|:-----------------|
| Orquestrador | {{ORCHESTRATOR}} | Decompor, delegar, consolidar report, escalar decisões |
| Auditor/Organizador | {{AUDITOR}} | Inventariar, classificar risco, criar índices, estabelecer regras |
| Executor de Terminal | {{ORCHESTRATOR}} ou {{AUDITOR}} | Executar movimentação física de arquivos (após sinal verde) |

## Procedimento

### Fase 0: Verificar o Estado

Antes de qualquer ação, confirmar o estado git atual:

```bash
cd /path/to/repo
git log --oneline -5
git status --short
git log --oneline --since="2026-05-28"  # últimas alterações recentes
```

Se o trabalho for complexo (multi-agente): commit prévio de backup obrigatório:
```bash
git add -A && git commit -m "backup: pre-organization snapshot $(date +%Y-%m-%d)" && git push
```

### Fase 1: Auditoria de Conformidade

#### 1.1. Mapeamento de arquivos

```bash
# Total de arquivos .md
find . -name "*.md" -not -path "./.git/*" -not -path "./design_system/*" | wc -l

# Arquivos de código (Django, etc.)
find . -name "*.py" -not -path "./.git/*" -not -path "./design_system/*" -not -path "./.venv/*" | wc -l

# Total de linhas por categoria
find . -name "*.py" -not -path "./.git/*" -not -path "./design_system/*" -not -path "./.venv/*" -exec cat {} + | wc -l
```

#### 1.2. Classificação de arquivos

Categorizar cada diretório:

| Categoria | Exemplos | Ação |
|-----------|----------|------|
| :white_check_mark: Planejamento | `docs/`, `docs/vault/` | Indexar |
| :white_check_mark: Modelos/Auditados | `design_system/` (prompts) | :lock: NÃO TOCAR |
| :x: Código desenvolvimento | `apps/`, `config/`, `templates/`, `static/` | Mover para `develop` |
| :x: Scaffold | `manage.py`, `.venv/`, `uv.lock` | Mover para `develop` |
| :warning: Misto | `scripts/` | Avaliar caso a caso |

#### 1.3. Análise de commits (Git Log)

```bash
# Identificar commits docs-only vs mixed
git log --oneline --format="%h %an %ai %s" <ultimo_commit_docs>..HEAD

# Verificar entrelaçamento docs↔código em commits suspeitos
git show --stat <commit_hash>
```

Marcar commits como:
- 🟢 **Só docs** — apenas .md
- 🖥️ **Só código** — apenas .py, .js, etc.
- 🔴 **MISTURADO** — docs e código no mesmo commit (requer extração seletiva)

### Fase 2: Investigação de Entrelaçamento

Quando docs e código estão misturados nos mesmos commits, um reset simples destrói a documentação. Mapear:

#### 2.1. Mapa de Entrelaçamento

Por commit misturado, listar:
- Arquivos .py (código) no commit
- Arquivos .md (docs) no mesmo commit
- Risco: quantos docs seriam perdidos no reset?

#### 2.2. Classificação de Risco por Módulo

Para cada módulo/sistema identificado no repositório:

| Risco | Critério |
|:-----:|----------|
| 🟢 Alinhado | Código + descoberta/documentação existem e estão sincronizados |
| 🟡 Parcial | Código existe, docs existem mas com gaps (sem critérios de aceite, sem validação Opus) |
| 🔴 Crítico | Código sem PRD / descoberta correspondente alguma |

#### 2.3. Cadeia de Delegação

Investigar quem realmente executou cada commit:

| Commit | Autor Git | Agente Declarado | Modelo | Evidência de Review |
|--------|:---------:|:----------------:|:------:|:-------------------:|

Mapear o fluxo real: `{{COMMANDER}} ──> Agente ──> Código ──> commit direto (❌ sem PR)`

#### 2.4. Estimativa de Horas

Estimar horas investidas por categoria (linhas × complexidade):

| Complexidade | Taxa (linhas/h) | Exemplos |
|:------------:|:----------------:|----------|
| 🔴 Alta | ~30 | Models Django, views, serializers, state machines |
| 🟡 Média | ~50 | CRUD, handlers, configuração |
| 🟢 Baixa | ~100 | Scripts, templates simples, CSS |

### 2.5. Two-Tier Documentation Architecture

When auditing reveals documentation scattered across **two independent systems** (e.g. project repo + Obsidian vault), define a **two-tier architecture** with explicit responsibilities:

| Tier | Path | Role | Agents edit? |
|------|------|------|:------------:|
| 🔵 **Active Source of Truth** | `{{PROJECT_PATH}}/docs/` | Active specs, ADRs, plans, audits | ✅ Yes (via PR) |
| 🟣 **Historical Reference** | `~/Dev/obsidian/10_Projects/{{PROJECT_SLUG}}/` | Reverse engineering, Dontus mapping, raw discovery | ❌ Read-only |

**Hierarquia de Verdade (data flow):**
```
obsidian/ (raw discovery, Dontus mapping, drafts)
     │
     ▼  (when mature, migrate to docs/)
     │
docs/  (active, indexed, canonical)
     │
     ▼  (reference for implementation)
     │
código/ (apps, config, templates, generated code)
```

**Key rule:** Agents never write to the Historical Reference tier. All new documentation goes to Active Source of Truth. The bridge document (see §3.0) maps topics between tiers so agents know where to find each type of content.

**AGENTS.md** — Place a rules file in the project root (`AGENTS.md`) that encodes the architecture for all agents to reference. It must include:
1. The two-tier table with paths and rules
2. The Hierarquia de Verdade diagram
3. Directory structure for `docs/`
4. Frontmatter rules and cross-link requirements
5. A checklist for pre-commit verification
6. Cross-links to the bridge document, INDEX.md, REGRAS-ORGANIZACAO.md
7. Explicit prohibition: "Nenhum agente Hermes cria, edita ou move arquivos no Obsidian."

This file lives in the project root (not inside `docs/`) so it's the first thing agents see when accessing the repo. See `references/agents-md-template.md` for the full template adapted from the {{PROJECT_NAME}} session.

### Fase 3: Organização e Indexação

#### 3.0. Bridge Documents — Ponte entre Silos de Documentação

Quando a documentação de um domínio está espalhada entre **múltiplos sistemas** (ex: Obsidian real vault, vault clone no repo, docs operacionais do projeto), crie um **bridge document** — um arquivo `.md` que serve como mapa único de navegação e deixa explícitas as regras de cada camada.

**Cenário típico (ex: {{PROJECT_NAME}}):**

| Camada | Função | Agentes editam? |
|--------|--------|:---------------:|
| 🟣 Obsidian (real) `~/Dev/obsidian/` | Segundo cérebro, revisões, doc raw | ❌ Read-only |
| 🟢 Vault canônico `docs/vault/` | Espelho estruturado do Obsidian no repo | ✅ Sim |
| 🔵 Docs do projeto `docs/` | Deep-dives, especificações, planos | ✅ Sim |

**Regras do bridge document:**

1. **Nomeie** como `LEGADO-<DOMINIO>-REFERENCIA.md` no diretório `docs/` raiz
2. **Frontmatter** obrigatório (tags, modulo, estagio) conforme REGRAS-ORGANIZACAO.md
3. **Tabela das camadas** no topo — caminho, função, permissão de edição
4. **Mapa de tópicos** — cada tópico do domínio com tabela de 3 linhas (uma por camada), contendo caminho real e descrição do que contém
5. **Seção de fluxo de trabalho** — como consultar, o que NÃO fazer, o que FAZER com novos achados
6. **Inventário de arquivos** — tabela de todos os arquivos mencionados com tamanho e relevância
7. **Cross-links** para INDEX.md, REGRAS-ORGANIZACAO.md e índices específicos

**⚠️ Pitfall:** Não duplicar conteúdo do Obsidian no repo sem necessidade — bridge document aponta, não copia. Se o Obsidian tem o mapeamento definitivo e o repo não tem clone, o bridge document diz "leia no Obsidian" com caminho absoluto, não recria o conteúdo.

**Exemplo real:** `LEGADO-DONTUS-REFERENCIA.md` mapeia 9 tópicos (ETL, mapeamento campo-a-campo, revisões {{AUDITOR}}, bíblia, modelo ER, blueprint, PRD, código gerado, gaps) entre as 3 camadas do projeto {{PROJECT_NAME}}.

Usar Gemini 3.1 Pro para processar ~150+ arquivos.md de uma vez.

O Gemini CLI (v0.44.1+) está instalado via mise node 24.13.1, **pré-autenticado via Google OAuth** (NÃO usa API key do OpenRouter). Disponível como `gemini` no terminal do {{COMMANDER}}, ou pelo caminho completo:

```bash
# Opção 1: find + pipe para alimentar contexto via stdin
find docs/ -name "*.md" -not -path "./design_system/*" | head -150 | \
  GEMINI_CLI_TRUST_WORKSPACE=true \
  /Users/{{COMMANDER}}fae/.local/share/mise/installs/node/24.13.1/bin/gemini \
  -m "gemini-3.1-pro-preview" \
  -p "Leia os arquivos abaixo e produza um índice mestre categorizado..." \
  2>/dev/null > docs/INDEX.md

# Opção 2 (se gemini estiver no PATH, como no terminal do {{COMMANDER}}):
find docs/ -name "*.md" -not -path "./design_system/*" | head -150 | \
  gemini -m "gemini-3.1-pro-preview" -p "(prompt)" 2>/dev/null > docs/INDEX.md
```

**⚠️ Importante:** 
- O Gemini CLI NÃO funciona em background mode no Mac — executar em foreground com `timeout=300+`.
- O Gemini CLI é autenticado via Google OAuth na conta do {{COMMANDER}}, não via API key.
- O flag `--include-directories` NÃO existe no Gemini CLI. Use `find` + pipe para alimentar contexto via stdin.

#### 3.1. Índices a criar

| Índice | Conteúdo | Local |
|--------|----------|-------|
| **Índice Mestre** | Todas as categorias com links reais | `docs/INDEX.md` |
| **Índice de Módulos** | G01-G11, K1-K4 com todos os documentos | `docs/vault/INDEX-MODULOS.md` |
| **Índice de Refinamentos** | Agrupados por gap + tipo | `docs/refinamentos/INDEX-REFINAMENTOS.md` |
| **Índice de Prompts** | Todos os prompts de IA | `docs/refinamentos/INDEX-PROMPTS.md` |

#### 3.2. Regras de índices

- Usar **caminhos relativos reais** (não caminhos de diretórios destino que não existem)
- Cada entrada: link + breve descrição + módulo
- Frontmatter YAML obrigatório (`title`, `created`, `updated`, `tags`, `modulo`, `estagio`)

### Fase 4: Regras de Organização

Criar `docs/REGRAS-ORGANIZACAO.md` com:

#### 4.1. Frontmatter Obrigatório

```yaml
---
title: Título Descritivo
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [planejamento, especificacao, auditoria, prompt, adr, infra, deep-dive, report, wave, ui, bd, index, rules]
modulo: G01 | G02 | ... | G11 | K1 | ... | K4 | cross
estagio: rascunho | revisado | final
---
```

#### 4.2. Cross-links

- Todo documento novo DEVE ter pelo menos 1 link para outro documento do repositório
- Proibido commit de .md sem índice atualizado

#### 4.3. Estrutura de Diretórios Alvo (para futuro)

```
docs/
├── INDEX.md
├── adr/
├── infra/
├── planejamento/
├── especificacao/
│   ├── G02-core-models/
│   └── G06-agenda/
├── refinamentos/
│   ├── INDEX.md
│   ├── auditorias/
│   ├── prompts/
│   └── revisoes/
└── vault/
    ├── INDEX.md
    ├── G01-G11/
    └── K1-K4/
```

### Fase 5: Sinal Verde e Execução

Nenhuma ação destrutiva (git reset, branch, merge, deleção) sem autorização explícita de {{COMMANDER}}.

**O que pode ser feito sem autorização:**
- :white_check_mark: Criar índices (arquivos novos)
- :white_check_mark: Criar regras de organização
- :white_check_mark: Mapear e classificar arquivos existentes
- :white_check_mark: Identificar overlaps e duplicações

**O que requer Sinal Verde de {{COMMANDER}}:**
- :red_circle: git reset / branch / merge
- :red_circle: Mover arquivos fisicamente (se houver risco de quebrar links)
- :red_circle: Deletar qualquer arquivo
- :red_circle: Commitar alterações em nome de {{COMMANDER}}
- :red_circle: Qualquer operação em branches do repositório

## Exemplo de Output

Após a organização, o report final deve conter:

```
**Organização de Documentação — Relatório Final**

| Métrica | Valor |
|:--------|:-----:|
| Total de .md processados | ~160 |
| Índices criados | 5 (X linhas) |
| Arquivos movidos | N (ou 0 com justificativa) |
| Overlaps identificados | X grupos |
| Regras estabelecidas | X seções |

**Índices:**
- docs/INDEX.md (X linhas)
- docs/vault/INDEX-MODULOS.md (X linhas)

**Pendências para {{COMMANDER}}:**
1. Decidir movimentação física (risco de quebrar ~N links)
2. Aprovar ou rejeitar opção de git reorganize
```

## ⚠️ Pitfalls

1. **Reset simples DESTRÓI docs** se houver entrelaçamento. Sempre verificar antes com `git show --stat`.
2. **Gemini CLI não funciona background** no Mac — executar foreground com timeout alto.
3. **Índices podem apontar para diretórios inexistentes** se o processo de indexação criar caminhos de destino que não foram criados ainda. SEMPRE verificar que cada link no índice aponta para um arquivo real: `python3 -c "import os; [print(f'MISSING: {f}') for f in open('docs/INDEX.md').read().split('(') if ')' in f and f.split(')')[0].endswith('.md') and not os.path.exists(os.path.join('docs', f.split(')')[0]))]"` pode ajudar a detectar links quebrados.
4. **Cross-links entre arquivos impedem movimentação segura.** Se um arquivo em `docs/` é referenciado por 50+ outros documentos, movê-lo quebrará dezenas de links. A movimentação física só deve ocorrer após mapeamento completo de referências.
5. **Design system NUNCA é tocado.** Os prompts, previews e assets de design system são considerados canônicos e imutáveis — qualquer modificação requer autorização direta de {{COMMANDER}} + aprovação de {{FRONTEND_ENGINEER}}.
6. **Código Django não deve ser movido ou deletado** — apenas preservado em branch `develop` separada. O código pode conter lógica de negócio validada contra a documentação.
7. **Sessão de terminal é preferível a Slack** para trabalho complexo de organização. {{COMMANDER}} explicitamente prefere resolver via terminal para evitar perda de contexto em threads longas.
8. **Mover arquivos antes de atualizar referências quebra links.** Em caso real (31/05/2026), ~100 arquivos foram movidos para nova estrutura de diretórios, mas os índices não foram todos atualizados simultaneamente — alguns INDEX.md passaram a apontar para diretórios que não existiam mais. **Regra:** após CADA movimento de grupo de arquivos, executar `grep -r "caminho/antigo" docs/ --include="*.md" -l` para detectar orphans. Corrigir índices antes de prosseguir para o próximo grupo.
9. **A organização física (movimentação de arquivos) requer aprovação explícita de {{COMMANDER}} quando há cross-links extensos.** Nesta sessão, optou-se por NÃO mover arquivos (apenas criar índices + regras) porque ~50+ cross-links entre documentos seriam quebrados. A decisão correta foi: indexar primeiro, apresentar o risco a {{COMMANDER}}, deixar ele decidir o movimento.

10. **Gemini CLI autenticado via Google OAuth, NÃO por API key.** Não configurar OpenRouter ou API keys para o Gemini. O comando `gemini` funciona diretamente no terminal do {{COMMANDER}} (shim do mise). O caminho completo é `/Users/{{COMMANDER}}fae/.local/share/mise/installs/node/24.13.1/bin/gemini`.

11. **Agentes podem fabricar relatórios de arquivos inexistentes.** Se um agente reportar que um arquivo existe com contagem de linhas e tabelas de conteúdo específicas, mas o arquivo não aparece em `git ls-tree -r` em NENHUMA branch (develop, wave, main), o relatório é fabricado. JAMAIS aceite o claim sem verificar as 3 camadas: filesystem local → git remote (todas as branches) → cross-environment. Protocolo completo em `references/verificacao-cruzada-agentes.md`.

12. **:red_circle: Antes de acusar fabricação, verificar TODOS os repositórios onde o arquivo pode estar.** O projeto `{{PROJECT_SLUG}}` tem DUAS localizações: (1) `{{PROJECT_SLUG}}/docs/` = fonte ativa (agentes escrevem aqui), (2) `obsidian/10_Projects/{{PROJECT_SLUG}}/` = histórico Dontus read-only. Se um agente reporta arquivos em `docs/`, verifique PRIMEIRO em `{{PROJECT_SLUG}}/docs/` — NÃO no vault Obsidian. A DOC ARCHITECTURE (AGENTS.md) define onde cada coisa vive. Exemplo real (31/05/2026): {{AUDITOR}} reportou `docs/INDEX.md` (427 linhas) e `docs/refinamentos/auditorias/AUDITORIA-CONSISTENCIA-POS-REORG.md` (184 linhas). {{ORCHESTRATOR}} verificou em `obsidian/` e `git ls-tree` do repo errado — ambos vazios. Acusou {{AUDITOR}} de fabricação. {{COMMANDER}} corrigiu: os arquivos estavam em `{{PROJECT_SLUG}}/docs/`, exatamente onde deveriam estar. A {{AUDITOR}} estava correta. O erro foi do orquestrador. **Sempre verifique `ls -la` no path COMPLETO do projeto ativo antes de acusar outro agente.**

## Variant: Migration Workflow (Obsidian → docs/)

When the two-tier architecture is established and {{COMMANDER}} approves migrating actionable files from Historical Reference to Active Source of Truth:

### Step 1: Classify All Files

| Classificação | Critério | Ação |
|:-------------|----------|------|
| **ACTIONABLE** | Code specs, implementation plans, {{AUDITOR}} reviews, migration mappings, architecture decisions | Migrate to `docs/` |
| **HISTORICAL** | Reverse engineering artifacts, Dontus bíblia, ER models (reference only), indexes | Keep in Obsidian |
| **ALREADY IN DOCS** | Newer/equivalent version already in `docs/` | ❌ Do NOT copy — reference in index |

### Step 2: Check for Duplicates

For each actionable file, verify it doesn't already exist in `docs/` with a more recent version.

### Step 3: Copy in Batches

```bash
OBSIDIAN="~/Dev/obsidian/10_Projects/{{PROJECT_SLUG}}"
DOCS="{{PROJECT_PATH}}/docs"

# Revisões → refinamentos/revisoes/
mkdir -p "$DOCS/refinamentos/revisoes"
cp "$OBSIDIAN/REVISAO-G03-{{AUDITOR_UPPER}}.md" "$DOCS/refinamentos/revisoes/revisao-g03-jasnah.md"

# Code gaps → especificacao/
mkdir -p "$DOCS/especificacao"
cp "$OBSIDIAN/G04-WHATSAPP-CODIGO.md" "$DOCS/especificacao/g04-whatsapp-code.md"

# Plans → planejamento/
mkdir -p "$DOCS/planejamento"
cp "$OBSIDIAN/PLANO-GAPS-{{AUDITOR_UPPER}}.md" "$DOCS/planejamento/plano-gaps-jasnah.md"
```

### Step 4: Rename Convention

When migrating, rename files to lowercase-with-hyphens:
- `G04-WHATSAPP-CODIGO.md` → `g04-whatsapp-code.md`
- `REVISAO-G03-{{AUDITOR_UPPER}}.md` → `revisao-g03-jasnah.md`

### Step 5: Register in INDEX.md

After each batch, add entries to `docs/INDEX.md` in the "Documentos Relacionados" section:
```markdown
- [`docs/especificacao/g04-whatsapp-code.md`](./especificacao/g04-whatsapp-code.md) — Código WhatsApp G04 (migrado do Obsidian)
```

### Step 6: Verify

```bash
ls -la docs/especificacao/ | grep -c ".md"
grep -c "migrado do Obsidian" docs/INDEX.md
```

## Variant: Reorganização Física (Pós-Aprovação)

Se {{COMMANDER}} autorizar a movimentação física de arquivos:

### Preparação

1. Antes de mover: mapear todas as referências ao arquivo
   ```bash
   grep -r "nome-do-arquivo.md" docs/ --include="*.md" -l
   ```

2. Verificar se há links em outros repositórios ou no Obsidian vault

3. Criar redirecionamento/nota no local original apontando para o novo caminho

### Execução

1. Mover arquivos um por um, começando pelos que têm menos referências
2. Após cada movimento, atualizar TODOS os arquivos que referenciam o caminho antigo
3. Atualizar índices
4. Verificar com `grep -r "caminho/antigo" --include="*.md" -l` que não ficaram orphans
5. git commit atômico (todos os ajustes no mesmo commit)

## Variant: Auditoria de Documento Único (Planos e Especificações)

Quando {{AUDITOR}}, {{BACKEND_ENGINEER}} ou {{FRONTEND_ENGINEER}} entrega um documento de planejamento (.md) e {{ORCHESTRATOR}} precisa auditar antes do sinal verde. Diferente da auditoria de repositório (Fase 1-2), esta é **leve**: foco em conformidade estrutural e completude, não em análise de commits ou entrelaçamento de código.

### Checklist de 7 Critérios

| # | Critério | Como Verificar |
|---|----------|----------------|
| 1 | Arquivo existe e íntegro | `ls -la <path>` + `wc -l <path>` |
| 2 | Frontmatter YAML completo | `read_file` primeiras 10 linhas — conferir `title`, `created`, `updated`, `tags`, `modulo`, `estagio` |
| 3 | Registrado no INDEX.md | `grep -n "nome-do-arquivo.md" docs/INDEX.md` — ao menos 1 seção + seção específica (Infra, Planejamento, etc.) |
| 4 | Cross-links resolvem | Script via `execute_code`: regex extrai `[text](path)`, `os.path.exists` cada link relativo à base do documento |
| 5 | ZERO código executável | Se a task proibia código, verificar ausência de blocos ` ```python ` com implementação real |
| 6 | ZERO terminal usado | Se a task proibia terminal, verificar que o agente não executou comandos |
| 7 | Cobertura dos itens solicitados | Comparar headings/seções com os itens da delegação original |

### Formato do Report de Auditoria

O report deve seguir estrutura consistente para que {{COMMANDER}} possa scanear rapidamente:

```markdown
## :white_check_mark: / :x: Auditoria — task_XX (Agente) · DOCUMENTO.md

**Veredito: APROVADO / APROVADO COM RESSALVAS / REPROVADO**

| Critério | Status |
|----------|:------:|
| Arquivo existe (N linhas, X KB) | :white_check_mark: |
| Frontmatter YAML completo | :white_check_mark: |
| Registrado em INDEX.md (N seções) | :white_check_mark: |
| N cross-links — todos resolvem | :white_check_mark: |
| ZERO código executável | :white_check_mark: |
| ZERO terminal usado | :white_check_mark: |
| Cobertura dos N itens solicitados | :white_check_mark: |

### :warning: Ressalvas
| # | Tipo | Descrição |
|---|------|-----------|
| N | Cosmética | ... |
```

### Classificação de Ressalvas

| Tipo | Significado | Ação |
|------|-------------|------|
| **Cosmética** | Não bloqueia implementação (tag fora do catálogo, inconsistência de nomenclatura) | Corrigir no commit de implementação |
| **Bloqueante** | Impede implementação correta (link quebrado, seção ausente, dado fabricado) | Reabrir task, exigir correção |

### Estendido: Auditoria de Conteúdo (Finding/Gaps Documentos)

Quando o documento sob auditoria é uma **análise de descobertas** (gap analysis, mapping, reverse engineering report) e não apenas um plano de implementação, a auditoria estrutural (7 critérios) é insuficiente. Adicione 3 critérios complementares:

| # | Critério de Conteúdo | Como Verificar | Exemplo |
|---|----------------------|----------------|---------|
| 8 | **Evidência das descobertas** | As alegações são baseadas em observação direta ou são inferências não fundamentadas? | "2 usuários, ambos SUPERVISOR" — verificável via acesso ao sistema |
| 9 | **Consistência da severidade** | A classificação de cada gap segue critério uniforme? | 🔴 Crítico = bloqueia segurança/deploy; 🟡 Alto = impacto qualidade sem bloqueio |
| 10 | **Ação prática derivável** | Cada gap termina com recomendação acionável que pode virar task? | Setup "Quarentena" pós-ETL → diretamente mapeável para SP1-18 |

#### Como auditar achados vs inferências

Ao ler um documento de descoberta, separar:
- **Observation** (direto): "Página /Grupo retorna 'Nenhum registro encontrado'" → verificável
- **Claim** (inferência): "O sistema não comporta multi-clínica com perfis diferenciados" → apoiado por, mas não idêntico a, observação
- **Recommendation** (derivada): "Ignorar modelo legado, fazer setup limpo pós-ETL" → ação concreta

Se um claim não tiver observation que o suporte → ressalva bloqueante.

### Estendido: Decisão de Correção (Fix Direto vs Delegar)

Ao encontrar não-conformidades na auditoria, decidir:

| Tipo de Issue | Fix Direto (Orquestrador) | Delegar de Volta (Implementador) |
|---------------|:-------------------------:|:--------------------------------:|
| INDEX.md desatualizado | ✅ Sim — 1 linha, sem risco de erro de conteúdo | ❌ |
| Cross-links ausentes | ❌ | ✅ Sim — requer edição no documento original |
| Frontmatter (cosmética) | ✅ Sim — tags, `updated` | ❌ |
| Seção inteira ausente | ❌ | ✅ Sim — conteúdo faltando |
| Verificação de links quebrados | ✅ Sim — script automatizado | ❌ |

Regra geral: **edição de conteúdo** → implementador. **Metadados/índice** → orquestrador.

### Estendido: Decisão de Roteamento Pós-Aprovação

Após aprovação do documento, o orquestrador DEVE produzir uma **decisão de roteamento** — o que fazer com as descobertas. Não deixar o documento aprovado órfão.

| Tipo de Decisão | Quando Usar | Exemplo |
|:---------------:|-------------|---------|
| **Criar task** | Descoberta requer implementação isolada | "Quarentena group: criar task SP1-18-b" |
| **Incorporar em task existente** | Descoberta é incremento natural de task já planejada | "Quarentena → adicionar ao SP1-18 como requisito" |
| **Deferir para wave seguinte** | Descoberta é válida mas fora do escopo atual | "Portal do Paciente (Gap 2) → Wave 4" |
| **Arquivar como observação** | Descoberta é informacional, não requer ação imediata | "Dontus tem 10 módulos, todos visíveis para Supervisor — documentado, sem ação" |

Documentar a decisão no veredito da auditoria, com justificativa de uma linha.

### Pitfalls Específicos

1. **Tags não-canônicas**: O catálogo oficial é `planejamento, especificacao, auditoria, prompt, adr, infra, deep-dive, report, wave, ui, bd, index, rules`. Tags como `docker`, `logging`, `health-check` são descritivas mas não-canônicas — ressalva cosmética, não bloqueante.
2. **Módulo vs Cobertura**: Se `modulo: G01` mas o doc cobre G01+G07, manter `G01` como primário no frontmatter. O INDEX.md pode registrar como `G01/G07`.
3. **INDEX.md dupla entrada**: Documentos de infraestrutura devem aparecer tanto na seção de planejamento quanto na de infraestrutura.
4. **Cross-links em §Referências ≠ cross-links no corpo**: Ambos contam. Verificar todos.

### Script de Verificação de Cross-links

```python
from hermes_tools import terminal
import re, os

with open("<caminho>") as f:
    content = f.read()

links = re.findall(r'\[([^\]]*)\]\(([^)]+)\)', content)
base = os.path.dirname(os.path.abspath("<caminho>"))

broken = []
for text, path in links:
    if path.startswith("http"):
        continue
    full = os.path.normpath(os.path.join(base, path))
    if not os.path.exists(full):
        broken.append((text, path, full))

if broken:
    for text, path, full in broken:
        print(f"❌ BROKEN: [{text}]({path}) → {full}")
else:
    print(f"✅ {len(links)} cross-links — todos resolvem")
```

Consulte `references/auditoria-documento-unico-checklist.md` para a checklist completa com exemplos de reports reais.

## Referências

- `references/verificacao-cruzada-agentes.md` — Protocolo de verificação quando agentes reportam arquivos com conteúdo que não existe em git (fabricação/alucinação)
- `references/auditoria-pasta-{{PROJECT_SLUG}}-20260531.md` — Exemplo real de auditoria de pasta de planejamento com ~14K linhas de código intruso
- `references/anexo-auditoria-governanca-20260531.md` — Investigação de 4 artefatos: entrelaçamento, risco, delegação, horas
- `references/auditoria-documento-unico-checklist.md` — Checklist completa para auditoria de documento único com exemplos de reports reais
