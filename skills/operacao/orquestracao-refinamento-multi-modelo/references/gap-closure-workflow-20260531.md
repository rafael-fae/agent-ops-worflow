# Gap Closure Workflow — {{PROJECT_NAME}} (31/05/2026)

## Contexto
Fechamento de 7 gaps técnicos + 1 logger de segurança no projeto {{PROJECT_SLUG}} (Django multi-tenant). Operação orquestrada por {{ORCHESTRATOR}} com implementação de {{BACKEND_ENGINEER}} e auditoria independente de {{AUDITOR}}.

## Timeline da Operação

| Horário | Ação | Ator |
|---------|------|------|
| 00:24 | Wire-up Gap 1.1 (3 alterações) + delega G08/G09/Logger | {{ORCHESTRATOR}} |
| 00:24 | {{AUDITOR}} inicia validação do wire-up | {{AUDITOR}} |
| 00:24 | {{BACKEND_ENGINEER}} absorve delegação de G08/G09/Logger | {{BACKEND_ENGINEER}} |
| — | {{AUDITOR}} descobre ERRO de ordenação: TenantMiddleware antes de SessionMiddleware | {{AUDITOR}} |
| — | {{BACKEND_ENGINEER}} conclui G08, G09, Logger (17 arquivos) | {{BACKEND_ENGINEER}} |
| — | {{ORCHESTRATOR}} autoriza correção do middleware | {{ORCHESTRATOR}} |
| — | {{AUDITOR}} corrige ordenação + valida logger | {{AUDITOR}} |
| — | {{BACKEND_ENGINEER}} mapeia gaps 2.2 e 2.3, aguarda sinal verde | {{BACKEND_ENGINEER}} |
| — | {{AUDITOR}} dá sinal verde para gaps 2.2 e 2.3 | {{AUDITOR}} |
| — | {{ORCHESTRATOR}} autoriza execução de 2.2 e 2.3 | {{ORCHESTRATOR}} |
| — | {{BACKEND_ENGINEER}} executa 2.2 e 2.3 (17 arquivos, 100% sintaxe OK) | {{BACKEND_ENGINEER}} |
| — | {{AUDITOR}} revisa e aprova ambos os gaps | {{AUDITOR}} |
| — | {{ORCHESTRATOR}} consolida relatório final — 7 gaps + 1 logger fechados | {{ORCHESTRATOR}} |

## Artefatos Produzidos

### Gap 1.1 — Multi-tenant (Wire-up + Correção)
- `config/settings.py`: DATABASE_ROUTERS + MIDDLEWARE corrigido (Session antes de Tenant)
- `config/asgi.py`: AsgiTenantMiddleware wrapper

### G08 — Cache
- `apps/core/middleware/cache.py` (153 linhas): HTMXPartialCacheMiddleware + CacheInvalidationMiddleware

### G09 — Disaster Recovery
- `scripts/backup.sh`, `scripts/restore.sh`, `scripts/dr_test.sh`, `scripts/check_backup_stale.sh`

### Logger oeste.security
- `config/settings.py` (l.133-210): LOGGING dict com RotatingFileHandler, JSON format, loggers auxiliares

### Gap 2.2 — PgBouncer/HTMX
- `docker-compose.yml` + `docker-compose.prod.yml`
- `docker/pgbouncer/pgbouncer.ini` + `userlist.txt`
- `config/settings.py`: PGBOUNCER_HOST env var
- `docs/infra/PGBOUNCER-SETUP.md` (428 linhas)

### Gap 2.3 — Signals CRC/Orçamento (Event Bus)
- `apps/agenda/signals.py`, `exceptions.py`, `statemachine.py`
- `apps/orcamento/signals.py`, `exceptions.py`, `statemachine.py`
- `apps/crc/handlers.py`, `tasks.py`, `models.py`, `exceptions.py`
- `config/settings.py`: INSTALLED_APPS atualizado

## Padrões Validados

1. **Cadeia de delegação**: {{ORCHESTRATOR}} → Implementador → Auditor → Consolidação
2. **Priorização**: P0 (infra/docker) antes de P1 (ADRs/scaffold) antes de P2
3. **Gate de auditoria**: {{AUDITOR}} revisou cada artefato antes de aprovar fechamento
4. **Paralelismo**: gaps 2.2 e 2.3 executados simultaneamente por {{BACKEND_ENGINEER}}
5. **Bug catch**: {{AUDITOR}} detectou erro de ordenação no middleware que teria causado resolução incorreta de tenant por session
