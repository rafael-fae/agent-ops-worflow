# Auditoria de Documento Único — Checklist Completa

Checklist para {{ORCHESTRATOR}} auditar documentos de planejamento criados por {{AUDITOR}}, {{BACKEND_ENGINEER}} ou {{FRONTEND_ENGINEER}}. Complementa `docs-governance-organization/SKILL.md` Variant: Auditoria de Documento Único.

---

## 1. Checklist de 7 Critérios

### 1. Existência e Integridade

```bash
ls -la <caminho-do-arquivo>
wc -l <caminho-do-arquivo>
```

O que validar:
- Arquivo não é vazio (wc -l > 10)
- Tamanho compatível com o escopo (plano de 2 gaps = 400-600 linhas esperado)
- Nome segue convenção (PLANO-GXX-GYY-DESCRICAO.md ou equivalente)

### 2. Frontmatter YAML

Campos obrigatórios:
- `title` — descritivo, inclui os gaps cobertos
- `created` — data no formato YYYY-MM-DD
- `updated` — mesma data na criação
- `tags` — ao menos 2 tags do catálogo oficial
- `modulo` — módulo primário (G01..G11, K1..K4, cross)
- `estagio` — `rascunho` para documentos não revisados

### 3. Registro no INDEX.md

Verificar:
- Entrada na seção principal (ex: Planejamento)
- Entrada em seção específica se aplicável (ex: Infraestrutura para docs de infra)
- Nome do arquivo e descrição consistentes com o conteúdo real

### 4. Cross-links

Usar script Python via `execute_code`:

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

Mínimo: 1 cross-link. Ideal: 5+ para documentos de planejamento.

### 5. ZERO Código Executável

Se a task proibia código, verificar:
- Nenhum bloco ` ```python ` com implementação real
- Snippets de configuração (` ```yaml `, ` ```json `) são aceitáveis se forem documentais
- Tabelas e diagramas em markdown são sempre aceitáveis

### 6. ZERO Terminal Usado

Se a task proibia terminal, verificar no histórico da thread que o agente não usou `terminal()` nem `execute_code()`.

### 7. Cobertura dos Itens Solicitados

Comparar com a delegação original:
| Item solicitado | Seção correspondente | Status |
|-----------------|---------------------|:------:|
| Item 1 | §X | :white_check_mark: |
| Item 2 | §Y | :white_check_mark: |

---

## 2. Classificação de Ressalvas

| Tipo | Exemplos | Ação |
|------|----------|------|
| **Cosmética** | Tags não-canônicas, `modulo` cobre só 1 de 2 gaps, título vs nome de arquivo inconsistente | Corrigir no commit de implementação, NÃO reabrir task |
| **Bloqueante** | Link quebrado, seção solicitada ausente, frontmatter sem tags, INDEX.md não atualizado, dado fabricado | Reabrir task, agente corrige antes do sinal verde |

---

## 3. Exemplo Real: task_06 ({{AUDITOR}}) — PLANO-G01-G07-INFRA.md

### Delegação Original

> G01 (Docker) + G07 (Logs). Base: docs/infra/INFRA-BLUEPRINT.md.
> 1. Estrutura do docker-compose.yml (PostgreSQL, Redis, PgBouncer)
> 2. Logger oeste.security: handlers, níveis, Sentry
> 3. Health checks (/health/, /ready/)
> 4. Documentar em docs/planejamento/PLANO-G01-G07-INFRA.md
> ⚠️ ZERO código. ZERO terminal. Só markdown.

### Resultado da Auditoria

| Critério | Status |
|----------|:------:|
| Arquivo existe (526 linhas, 24.8 KB) | :white_check_mark: |
| Frontmatter YAML completo | :white_check_mark: |
| Registrado em INDEX.md (2 seções: Planejamento + Infra) | :white_check_mark: |
| 17 cross-links — todos resolvem | :white_check_mark: |
| ZERO código executável | :white_check_mark: |
| ZERO terminal usado | :white_check_mark: |
| Cobertura dos 4 itens solicitados | :white_check_mark: |

**Veredito: APROVADO com 1 ressalva cosmética.**

### Ressalvas

| # | Tipo | Descrição |
|---|------|-----------|
| 1 | Cosmética | Tags `docker`, `logging`, `observabilidade`, `health-check` não constam no catálogo oficial de tags permitidas |
| 2 | Cosmética | `modulo: G01` — documento cobre G01+G07; manter G01 como primário é aceitável |

---

## 4. Tags Canônicas (Catálogo Oficial)

Conforme `REGRAS-ORGANIZACAO.md`:

| Tag | Uso |
|-----|-----|
| `planejamento` | Documentos de planejamento estratégico |
| `especificacao` | Especificações técnicas e reescritas |
| `auditoria` | Auditorias, revisões e validações |
| `prompt` | Prompts de geração (Opus, Gemini) |
| `adr` | Architectural Decision Records |
| `infra` | Infraestrutura e deploy |
| `deep-dive` | Análises aprofundadas |
| `report` | Relatórios de status |
| `wave` | Documentos de planejamento de waves |
| `ui` | Interface e design system |
| `bd` | Banco de dados |
| `index` | Índices e navegação |
| `rules` | Regras e governança |
