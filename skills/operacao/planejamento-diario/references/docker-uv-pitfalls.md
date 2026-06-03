# Docker + uv — Pitfalls e Soluções (01/06/2026)

## 1. UV_SYSTEM_PYTHON=1 quebra multi-stage COPY

**Problema:** Com `UV_SYSTEM_PYTHON=1`, o `uv sync` instala tudo no sistema Python, NÃO criando diretório `.venv`. O runtime stage faz `COPY --from=builder /app/.venv /app/.venv` e copia NADA.

**Solução:** Remover `UV_SYSTEM_PYTHON=1` do builder stage. Sem essa env var, `uv sync` cria `.venv` automaticamente.

**Alternativa (usada em produção):** Single-stage Dockerfile. Mais simples, sem surpresas de COPY entre stages.

## 2. docker-compose `command:` sobrescreve CMD do Dockerfile

**Problema:** Container falha com `exec: "gunicorn": executable file not found` mas a imagem tem o binário. Passou 1h debugando o Dockerfile enquanto o problema era:

```yaml
# docker-compose.yml — ESTA LINHA SOBRESCREVE O CMD!
command: gunicorn config.wsgi:application --config /app/docker/web/gunicorn.conf.py
```

O `command:` no compose sobrescreve qualquer CMD definido no Dockerfile.

**Solução:** Remover `command:` do compose ou usar `uv run gunicorn ...` se precisar dele.

## 3. uv sync --frozen trava sem uv.lock

**Problema:** Ao adicionar dependências manualmente em `pyproject.toml` (ex: gunicorn), o `uv sync --frozen` falha porque o lock file não foi atualizado.

**Solução:** Adicionar a dep no Dockerfile com `RUN uv pip install gunicorn` após o `uv sync`, ou regenerar o lock file antes do build.

## 4. FIELD_ENCRYPTION_KEY obrigatória no build

**Problema:** `encrypted_model_fields` exige `FIELD_ENCRYPTION_KEY` válida no `settings.py`. O `collectstatic` falha no build sem ela.

**Solução:**
```dockerfile
ARG FIELD_ENCRYPTION_KEY=dummy
ENV FIELD_ENCRYPTION_KEY=${FIELD_ENCRYPTION_KEY}
```
Passar chave real via `--build-arg FIELD_ENCRYPTION_KEY=<key>`.

## 5. ALLOWED_HOSTS vazio = 400 do Django atrás de proxy

**Problema:** Cloudflare Tunnel → Django retorna `DisallowedHost` porque `ALLOWED_HOSTS = []`.

**Solução:** Adicionar o domínio do Tunnel:
```python
ALLOWED_HOSTS = ["gestao.oesteodontologia.com.br", "localhost", "127.0.0.1"]
```

## 6. Imagem pgbouncer — tag correta

**Problema:** `edoburu/pgbouncer:1.21-alpine` não existe. Tags disponíveis: `latest`, `v1.25.1-p0`, `v1.24.1-p1`, etc.

**Solução:** Usar `edoburu/pgbouncer:latest` para dev.

## 7. Apps não existentes quebram collectstatic

**Problema:** `INSTALLED_APPS` referencia `apps.orcamento`, `apps.crc`, `apps.financeiro` que não existem (foram arquivados ou ainda não implementados).

**Solução:** Comentar com `# TODO Sprint N`:
```python
# 'apps.orcamento',  # TODO Sprint 10
# 'apps.crc',        # TODO Sprint 21
# 'apps.financeiro', # TODO Sprint 11
```

## Checklist de Deploy OVH

```bash
# 1. Pull
cd {{PROJECT_PATH}} && git pull origin develop

# 2. Rebuild
FERNET=$(python3 -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())')
docker compose build --no-cache --build-arg FIELD_ENCRYPTION_KEY=$FERNET web

# 3. Up
docker compose up -d

# 4. Verify
docker compose ps          # todos healthy
curl -s localhost:8000/admin/  # 302 = OK
```
