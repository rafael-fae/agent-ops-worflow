# Exemplo Real — Wave Opus Gaps (31/05/2026)

## Contexto
Comandante informou que limites do Opus estavam em 90%. Ordem: "Comecem AGORA. Cada minuto parado é limite desperdiçado."

## Gap Mapeado
- G01.1: Multi-tenant wire-up (Middleware, Router, ASGI)
- G05: Segurança (checklist 14 itens)
- G08: Cache HTMX
- G09: Disaster Recovery (4 scripts)
- G11: Pré-existente

## Tabela de Auditoria ({{AUDITOR}})

| Item | Comando | Status |
|:---:|---|:-----:|
| 1. TenantMiddleware no MIDDLEWARE | Adicionar | :white_check_mark: Presente, mas ordem INCORRETA |
| 2. DATABASE_ROUTERS | Adicionar | :white_check_mark: `config.tenant.router.TenantRouter` ok |
| 3. AsgiTenantMiddleware no ASGI | Wrapping | :white_check_mark: `config/asgi.py` correto |
| 4. G08 Cache extraído | Do markdown | :white_check_mark: `apps/core/middleware/cache.py` (175 linhas) |
| 5. G09 DR extraído | Do markdown | :white_check_mark: `scripts/backup.sh`, `restore.sh`, `dr_test.sh` |

## Achados com Triagem

### :red_circle: CRÍTICO 1 — Ordem do TenantMiddleware quebrada
- TenantMiddleware na posição 2, ANTES do SessionMiddleware
- Docstring do middleware diz que precisa de `request.session`
- **Correção:** Mover para após SessionMiddleware

### :red_circle: CRÍTICO 2 — Dependência impossível
- `pyproject.toml` exige `django-encrypted-model-fields>=0.8`, mas versão máxima no PyPI é 0.6.5
- `uv sync` não resolve
- **Correção:** `>=0.6.5,<0.7`

### :large_yellow_circle: MÉDIO 1 — G08 não wire-upado
- `cache.py` existe mas não registrado no MIDDLEWARE
- **Correção:** Registrar ambos middlewares

### :large_yellow_circle: MÉDIO 2 — FIELD_ENCRYPTION_KEY sem ponte
- `security.py` diz "definir via variável de ambiente", mas biblioteca lê de `settings.FIELD_ENCRYPTION_KEY`
- **Correção:** `FIELD_ENCRYPTION_KEY = os.getenv(...)` no settings.py

### :red_circle: CRÍTICO 3 (pós-correção) — localflavor v1.9 sem br.models
- `from localflavor.br.models import BRCPFField` quebrado na v1.9
- **Correção:** Substituir por `validate_docbr.CPF` + CharField

### Colateral Fixes (descobertos durante auditoria)
- `CheckConstraint(check=→condition=)` — 4 ocorrências, Django 6.0
- `admin.py`: `FuncionarioClinica` → `ProfissionalClinica` (modelo renomeado)
- `admin.py`: `list_display` com campos removidos

## Revalidação Final

```
uv sync :white_check_mark: | manage.py check :white_check_mark:
(6 erros pre-existentes: apps agenda/orcamento nao implementados — fora de escopo)
```

## Commit

```bash
cd {{PROJECT_PATH}}/
git checkout -b wave/2026-05-31-opus-gaps
git add -A
git commit -m "wave: multi-tenant wire-up + G08 cache + G09 DR scripts

- Wire-ups Gap 1.1: TenantMiddleware, DATABASE_ROUTERS, AsgiTenantMiddleware
- G08: HTMXPartialCacheMiddleware + CacheInvalidationMiddleware
- G09: backup.sh, restore.sh, dr_test.sh, check_backup_stale.sh
- Fix: ordem TenantMiddleware (apos SessionMiddleware)
- Fix: pyproject.toml django-encrypted-model-fields >=0.6.5,<0.7
- Fix: FIELD_ENCRYPTION_KEY bridge em settings.py
- Fix: BRCPFField → validate_docbr.CPF (localflavor v1.9 incompativel)
- Fix: CheckConstraint check→condition (Django 6.0)
- Fix: admin.py ProfissionalClinica + list_display
- Auditoria: {{AUDITOR}} aprovada (docs/refinamentos/AUDITORIA-FINAL-{{AUDITOR_UPPER}}.md)"
git push origin wave/2026-05-31-opus-gaps
```

Hash: `b3b455e` — 724 arquivos, +72.165 −552

## Relatório Final ({{ORCHESTRATOR}} para Comandante)

| Gap | O quê | Status |
|:---:|:------|:------:|
| G01.1 | Multi-tenant wire-up (Middleware, Router, ASGI) | :white_check_mark: |
| G05 | Segurança (13/14 — Backup Encryption pendente) | :white_check_mark: |
| G08 | Cache HTMX (Partial + Invalidation middleware) | :white_check_mark: |
| G09 | Disaster Recovery (4 scripts) | :white_check_mark: |
| G11 | Pré-existente, validado | :white_check_mark: |

## Lições Aprendidas

1. **Verificar repositório:** {{GIT_OPS}} quase fez branch no vault (`~/Dev/obsidian/`) em vez do código (`{{PROJECT_PATH}}/`)
2. **Tarefas pré-existentes:** {{BACKEND_ENGINEER}} encontrou tasks 1-3 já implementadas — reportou em vez de refazer
3. **Colateral fixes:** Os problemas de `CheckConstraint`, `admin.py` e `localflavor` foram encontrados porque a auditoria rodou `manage.py check`
4. **Três rodadas de correção:** 1ª rodada (4 blockers) → re-validação → 2ª rodada (BRCPFField + colaterais) → verde
