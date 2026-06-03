# Project Folder Scope — Planejamento vs Desenvolvimento

**Regra estabelecida por {{COMMANDER}} (31/05/2026):** A pasta raiz do projeto (ex: `{{PROJECT_PATH}}/`) deve conter APENAS:

## :white_check_mark: O QUE DEVE ESTAR

1. **Planejamento** — documentos, planos, blueprints, relatórios, deep-dives (`docs/`, `docs/refinamentos/`, `docs/adr/`)
2. **Modelos de arquivos** — templates de código, scaffolding, exemplos (`design_system/` specs do DS canônico)
3. **Itens criados e auditados pelo Opus** — especificações completas que servirão de fonte para o desenvolvimento futuro

## :red_circle: O QUE NÃO DEVE ESTAR (AINDA)

1. **Código de desenvolvimento** — `apps/`, `models.py`, `views.py`, `serializers.py`, `urls.py`, `tasks.py`
2. **Templates HTML funcionais** — `templates/base.html`, componentes, páginas de erro
3. **CSS/JS de produção** — `static/css/components.css`, `static/js/alpine-components.js`
4. **Scripts de infra** — scripts de backup, deploy, DR (a menos que sejam templates)
5. **Docker compose de produção** — `docker-compose.prod.yml` (só docker-compose.yml de dev)
6. **Configurações de settings** — settings.py com secrets, CACHES config, loggers ativos

## Rationale

- **Fase atual = Planejamento.** O desenvolvimento (codificação) só começa após todo o planejamento ser aprovado.
- **Riscos de código prematuro:**
  - Agentes geram código sem supervisão de {{COMMANDER}}
  - Código fica "órfão" quando o planejamento muda
  - Commit prematuro polui o histórico do git
  - {{COMMANDER}} perde controle do que é especificação vs implementação
- **Exceção:** Arquivos gerados exclusivamente pelo Opus (ex: `design_system/DESIGN-SYSTEM-OPUS-FINAL.md`) são especificação, não implementação — podem ficar.

## Verificação Rápida

Ao auditar uma pasta de projeto, classificar cada arquivo como:

| Categoria | Exemplos | Permissão |
|-----------|----------|:---------:|
| Planejamento | `docs/`, `docs/refinamentos/`, `docs/adr/` | :white_check_mark: |
| Especificação Opus | `design_system/`, `docs/vault/` | :white_check_mark: |
| Template vazio | `templates/base.html` (estrutura mínima) | :grey_question: (consultar {{COMMANDER}}) |
| Código Django | `apps/core/models.py`, `apps/agenda/views.py` | :x: |
| CSS/JS completo | `static/css/components.css` (45KB) | :x: |
| Scripts de infra | `scripts/backup.sh` | :x: (só se template) |
| Config produção | `docker-compose.prod.yml` | :x: |

## Caso Real (31/05/2026)

{{COMMANDER}} identificou que `{{PROJECT_PATH}}/` continha **~67 arquivos de desenvolvimento prematuro**:
- 44+ arquivos .py (apps, models, views, serializers, middleware)
- 6 CSS + 3 JS (componentes completos)
- 8 templates HTML (base, componentes, erros, styleguide)
- 6 scripts shell/Python (backup, restore, DR)

Agentes responsáveis pela extração prematura: {{DEVOPS_ENGINEER}} (middleware, CRC, financeiro, scripts), {{BACKEND_ENGINEER}} (core models, cache, agenda), {{FRONTEND_ENGINEER}} (templates, CSS/JS).

Os arquivos não foram removidos, mas {{COMMANDER}} determinou que a pasta deveria conter APENAS planejamento e especificação. Qualquer código de desenvolvimento novo deve ser autorizado explicitamente.
