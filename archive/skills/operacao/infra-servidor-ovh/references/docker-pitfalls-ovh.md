# Docker Pitfalls — OVH Deploy

## docker-compose `command:` sobrescreve Dockerfile CMD

**Sintoma:** Container falha com `exec: "X": executable file not found` mesmo após rebuild bem-sucedido da imagem.

**Causa:** O `docker-compose.yml` tem `command: gunicorn ...` ou similar que SOBRESCREVE o `CMD` do Dockerfile. Toda mudança no CMD do Dockerfile é ignorada.

**Solução:**
1. Verificar `docker-compose.yml` — `grep -A5 'web:' docker-compose.yml`
2. Se houver `command:`, removê-lo ou atualizá-lo para corresponder ao CMD desejado
3. Caso real (01/06): 1h debugando Dockerfile (UV_SYSTEM_PYTHON, multi-stage COPY, venv) — problema era `command: gunicorn config.wsgi:application --config /app/docker/web/gunicorn.conf.py` no compose

## uv sync sem UV_SYSTEM_PYTHON em Docker

**Problema:** `uv sync` em container Docker instala no sistema Python, não cria `.venv`. Mesmo sem `UV_SYSTEM_PYTHON=1`, containers rodando como root podem ter comportamento imprevisível.

**Solução:** Forçar criação explícita do venv:
```dockerfile
RUN uv venv /app/.venv && uv sync --frozen --no-dev --no-cache
```
Ou usar `uv run` para todos os comandos (CMD, collectstatic, etc).

## Gunicorn não incluído nas dependências

**Sintoma:** `exec: "gunicorn": executable file not found`

**Causa:** `gunicorn` não está no `pyproject.toml`/`uv.lock`.

**Solução:** Adicionar `"gunicorn>=23.0"` ao `pyproject.toml` OU instalar separadamente com `uv pip install gunicorn`.

## FIELD_ENCRYPTION_KEY no build

**Sintoma:** Build falha em `collectstatic` com `ImproperlyConfigured: FIELD_ENCRYPTION_KEY defined incorrectly`

**Causa:** `django-encrypted-model-fields` requer `FIELD_ENCRYPTION_KEY` (Fernet key de 32 bytes) ao importar modelos.

**Solução:**
```dockerfile
ARG FIELD_ENCRYPTION_KEY
ENV FIELD_ENCRYPTION_KEY=${FIELD_ENCRYPTION_KEY}
```
E passar no build: `docker compose build --build-arg FIELD_ENCRYPTION_KEY=<key>`

## ALLOWED_HOSTS para Cloudflare Tunnel

**Sintoma:** `DisallowedHost` ao acessar via domínio Cloudflare Tunnel.

**Solução:** Adicionar o domínio ao `ALLOWED_HOSTS`:
```python
ALLOWED_HOSTS = ["gestao.oesteodontologia.com.br", "localhost", "127.0.0.1"]
```

## PgBouncer — tag de imagem

**Sintoma:** `docker.io/edoburu/pgbouncer:1.21-alpine: not found`

**Solução:** A imagem `edoburu/pgbouncer` usa tags no formato `v1.25.1-p0`. Para dev, usar `latest`.
