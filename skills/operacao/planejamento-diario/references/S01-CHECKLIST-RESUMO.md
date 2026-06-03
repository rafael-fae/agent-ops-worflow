# Checklist de Implementação — Sprint 1 (K3 + G02 + G05)

## Progresso em 01/06/2026

| Item | Descrição | Status |
|------|-----------|--------|
| SP1-01 | contextvars (PEP 567) no TenantContext | ✅ |
| SP1-02 | TenantAwareModel base abstrata | ✅ |
| SP1-03 | TenantRouter (subdomínio + header) | ✅ |
| SP1-04 | TenantMiddleware WSGI + ASGI | ✅ |
| SP1-05 | PgBouncer docker-compose | ✅ |
| SP1-06 | Testes de isolamento — 11/11 PASSED | ✅ |
| SP1-07 | Modelo Tenant no banco global | ❌ |
| SP1-08 | PgBouncer pool_mode=transaction | ❌ |
| SP1-09 | Testes isolamento 300 req × 3 tenants | ❌ |
| SP1-10 | CustomUser com Argon2 | ✅ |
| SP1-11 | Modelos Role + Permission | ✅ |
| SP1-12 | DRF SimpleJWT configurado | ❌ |
| SP1-13 | @require_permissions decorator | ✅ |
| SP1-14 | Cache de permissões com invalidação | ✅ |
| SP1-15 | CSP com django-csp + nonce Alpine.js | ❌ |
| SP1-16 | Proteção CSRF para HTMX | ✅ |
| SP1-17 | AuditLogMiddleware | ✅ |
| SP1-18 | Rate Limiting por IP + Tenant | ✅ |
| SP1-19 | Headers segurança (HSTS, CORS, etc.) | ✅ |
| SP1-20 | provision_tenant.py script | ✅ |
| SP1-21 | CI/CD GitHub Actions (3 jobs) | ✅ |
| SP1-22 | Healthcheck web no docker-compose | ✅ |
| SP1-23 | Dockerfile single-stage com uv | ✅ |
| SP1-24 | requirements.txt fallback | ✅ |
| SP1-25 | AGENTS.md lições operacionais | ✅ |
| SP1-26 | Blueprint Seção 3 — Modelos reais | ✅ |
| SP1-27 | Blueprint Seção 6 — RBAC real (8 papéis) | ✅ |
| SP1-28 | Blueprint Seções 9 + 11 — DevOps + Migração | ✅ |
| SP1-29 | Acesso Dontus documentado | ✅ |

## Progresso: 22/29 (76%)

## Pendências críticas (7 itens)
1. SP1-07 — Modelo Tenant no banco global
2. SP1-08 — PgBouncer pool_mode=transaction
3. SP1-09 — Testes isolamento 300 req × 3 tenants
4. SP1-12 — DRF SimpleJWT
5. SP1-15 — CSP com django-csp
