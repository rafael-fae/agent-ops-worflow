# Docker Pitfalls — Lições do {{PROJECT_NAME}}

> Atualizado: 01/06/2026

## 1. `command:` no compose SOBRESCREVE Dockerfile CMD

**Sintoma:** Container não inicia, erro "exec: gunicorn: not found" mesmo com CMD correto no Dockerfile.

**Causa:** O `docker-compose.yml` tinha `command: gunicorn ...` que sobrescrevia completamente o CMD do Dockerfile. O Dockerfile foi debugado por 1h antes de descobrir a causa real.

**Solução:** Verificar SEMPRE o docker-compose.yml quando o container não iniciar. O `command:` no compose vence o CMD do Dockerfile.

```yaml
# ERRADO — sobrescreve CMD do Dockerfile
web:
  command: gunicorn config.wsgi:application --config ...

# CERTO — usar uv run no compose OU deixar o Dockerfile gerenciar
web:
  command: uv run gunicorn config.wsgi:application --bind 0.0.0.0:8000
```

## 2. Multi-stage com uv — `COPY --from=builder` não copia `.venv`

**Sintoma:** Build OK, mas container não encontra gunicorn/django. `ls /app/.venv/bin/` vazio.

**Causa:** `UV_SYSTEM_PYTHON=1` no builder faz uv instalar no sistema Python (não cria `.venv`). O runtime faz `COPY --from=builder /app/.venv` que copia NADA.

**Solução:** Remover `UV_SYSTEM_PYTHON=1` do builder. O `uv sync` sem essa env var cria `.venv` automaticamente.

```dockerfile
# ERRADO — instala no sistema, .venv nunca é criado
ENV UV_SYSTEM_PYTHON=1
RUN uv sync --frozen --no-dev --no-cache

# CERTO — cria .venv e copia pro runtime
RUN uv sync --frozen --no-dev --no-cache
# ...runtime stage...
COPY --from=builder /app/.venv /app/.venv
```

## 3. Single-stage com uv run é mais simples e confiável

Para evitar completamente os problemas de multi-stage COPY, usar single-stage:

```dockerfile
FROM python:3.12-slim
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
WORKDIR /app
COPY pyproject.toml uv.lock* ./
RUN uv sync --frozen --no-dev --no-cache
RUN uv pip install gunicorn
COPY . .
RUN uv run python manage.py collectstatic --noinput --clear
CMD ["uv", "run", "gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000"]
```

## 4. PgBouncer — tags de imagem

A imagem `edoburu/pgbouncer` usa tags `v1.X.Y-pN`, não `1.21` ou `1.21-alpine`.

```yaml
# ERRADO
image: edoburu/pgbouncer:1.21-alpine   # não existe

# CERTO
image: edoburu/pgbouncer:latest        # ou v1.25.1-p0
```

## 5. FIELD_ENCRYPTION_KEY no build

O pacote `django-encrypted-model-fields` exige `FIELD_ENCRYPTION_KEY` válida (Fernet 32 bytes base64) até mesmo durante `collectstatic`. Passar via build-arg:

```bash
docker compose build --build-arg FIELD_ENCRYPTION_KEY=$(python3 -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())') web
```
