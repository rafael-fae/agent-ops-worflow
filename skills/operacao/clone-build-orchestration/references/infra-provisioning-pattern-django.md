# Padrão de Provisionamento de Infraestrutura — Django + HTMX + PostgreSQL

## Origem

Estabelecido durante onboarding do projeto {{PROJECT_NAME}} (30/05/2026). {{DEVOPS_ENGINEER}}-mac produziu 6 artefatos de infra como rascunho pré-sinal-verde.

## Stack Alvo

- **App:** Django 6 + Gunicorn (gthread)
- **Frontend:** HTMX + Alpine.js + Tailwind (partials small, I/O-bound)
- **DB:** PostgreSQL 16 (database-per-tenant)
- **Proxy:** nginx (alpine)
- **Tunnel:** Cloudflare Tunnel (zero portas expostas)
- **Cache pós-MVP:** Redis
- **CI/CD:** GitHub Actions → ghcr.io → SSH deploy

## Artefatos de Infra (6 arquivos)

| # | Arquivo | Finalidade |
|:-:|---------|------------|
| 1 | `infra/docker-compose.yml` | Stack base parametrizada por `${TENANT_ID}`. Health checks em todos os serviços. |
| 2 | `infra/Dockerfile` | Multi-stage: builder com `uv`, runtime slim com gunicorn. Usuário não-root. Healthcheck embutido. |
| 3 | `infra/nginx/tenants/TENANT-TEMPLATE.conf` | Proxy reverso. Subs `DOMAIN` no provisionamento. Cache de static/media, gzip de partials HTMX. Headers de segurança. |
| 4 | `.github/workflows/deploy.yml` | 3 jobs: test → build (Docker buildx + ghcr.io) → deploy (SSH + snapshot volume + health check + rollback automático). Multi-tenant via `${{ vars.TENANTS }}`. |
| 5 | `scripts/provision-tenant.sh` | Automatiza: criar dirs → gerar `.env` (senha randômica + secret key) → copiar compose/nginx → `docker compose up -d` → migrações → superuser → health check. |
| 6 | `docs/infra/README.md` | Documentação: estrutura, fluxo, rollback, monitoria, checklist pré-deploy. |

## Decisões Técnicas e Justificativas

### Gunicorn gthread (4 workers, 2 threads cada)
- Django + HTMX é I/O-bound (partials, DB queries), não CPU-bound.
- 8 conexões simultâneas por instância app.
- Thread pool é mais leve que processos adicionais para I/O.

### ghcr.io como container registry
- Gratuito, integrado com GitHub Actions.
- Sem rate limits de Docker Hub.
- Push automático via `docker/build-push-action`.

### nginx como proxy separado (não embutido no Django)
- Serve static/media com cache de 7/30 dias sem bater no app Django.
- Gzip de partials HTMX (text/html) reduz payload em ~70%.
- Headers de segurança (X-Frame-Options, HSTS, Content-Type) centralizados.

### Rollback via snapshot de volume
- CI/CD tira `docker volume backup` antes de `docker compose up -d`.
- Se health check falhar após deploy → restaura volume anterior.
- Mais simples que blue/green para MVP. Blue/green fica para Wave de escalabilidade.

### Matrix de tenants no CI/CD
- `${{ vars.TENANTS }}` (GitHub Actions variable) permite adicionar tenants sem mexer no workflow YAML.
- Exemplo: `TENANTS: '["oesteodonto","outraclinica"]'`

### Provisionamento com senha randômica + secret key
- `openssl rand -base64 32` para senha do banco e SECRET_KEY.
- Gera `.env` por tenant com valores únicos.
- `docker compose up -d` já aponta para o `.env` correto via `env_file`.

## Monitoria Recomendada (free tier)

| Ferramenta | Alvo | Custo |
|------------|------|:-----:|
| UptimeRobot | Ping no domínio via tunnel → alerta se cloudflared cair | Free |
| Healthchecks.io | Cron do pg_dump → alerta se backup não executar | Free |
| Cloudflare Analytics | Tráfego, erros 5xx, latência | Incluso |

## Pipeline CI/CD

3 jobs encadeados com fail-fast:

```
test → build → deploy
```

1. **test:** ruff + mypy + pytest com PostgreSQL service container. Se falhar, cancela os seguintes.
2. **build:** Docker buildx com cache do GitHub Actions → push para ghcr.io.
3. **deploy:** SSH no servidor → tira snapshot de volume → `docker compose pull && docker compose up -d` → health check (30s timeout, 3 retries) → se falhar, restaura snapshot anterior e alerta.

## Checklist Pré-Deploy

- [ ] `TENANT_ID` definido no `.env` e no `${{ vars.TENANTS }}`
- [ ] Domínio configurado no Cloudflare (DNS + Tunnel)
- [ ] Volume de dados do PostgreSQL provisionado
- [ ] Migrações testadas localmente
- [ ] `.env` com SECRET_KEY, DB_PASSWORD, CLOUDFLARE_TOKEN
- [ ] Health check endpoint implementado (ex: `GET /health/`)
- [ ] Backup cron configurado
