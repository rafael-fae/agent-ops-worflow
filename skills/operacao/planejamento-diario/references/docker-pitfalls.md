# Docker Pitfalls — {{PROJECT_NAME}}

## 1. `command:` no docker-compose SOBRESCREVE CMD do Dockerfile

**Sintoma:** Container não inicia, erro "executable not found", mas o Dockerfile está correto.

**Causa:** docker-compose.yml tem `command:` que sobrescreve o CMD do Dockerfile.

**Exemplo real (01/06/2026):**
```yaml
# docker-compose.yml
web:
    command: gunicorn config.wsgi:application --config /app/docker/web/gunicorn.conf.py
```
Este `command:` sobrescrevia o CMD do Dockerfile (`uv run gunicorn...`). 
O container tentava executar `gunicorn` diretamente (sem `uv run`), quebrando porque o venv não estava no PATH.

**Correção:** Sempre verificar ambos os arquivos quando um container não inicia.

## 2. Multi-stage COPY --from não copia .venv

**Sintoma:** Dependências instaladas no builder não aparecem no runtime.

**Causa:** `UV_SYSTEM_PYTHON=1` faz uv instalar no sistema Python, sem criar `.venv`. O `COPY --from=builder /app/.venv /app/.venv` copia um diretório que não existe.

**Correção:** Remover `UV_SYSTEM_PYTHON=1` do builder, ou usar single-stage com `uv run`.

## 3. Imagem PgBouncer: tags corretas

**Errado:** `edoburu/pgbouncer:1.21`, `edoburu/pgbouncer:1.21-alpine`
**Correto:** `edoburu/pgbouncer:latest`, `edoburu/pgbouncer:v1.25.1-p0`

As tags semânticas deste image seguem o formato `v1.X.Y-pN`.

## 4. FIELD_ENCRYPTION_KEY precisa ser Fernet válida

**Sintoma:** `django.core.exceptions.ImproperlyConfigured: Fernet key must be 32 url-safe base64-encoded bytes`

**Correção:** Gerar com `python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"` e passar como build-arg.

## 5. Portas Docker em 0.0.0.0 expõem serviços à internet

**Sintoma:** PostgreSQL, Redis, Django acessíveis via IP direto.

**Correção:** Todas as portas em docker-compose devem usar `127.0.0.1:PORT:PORT`, nunca `PORT:PORT` (que defaulta para 0.0.0.0).
