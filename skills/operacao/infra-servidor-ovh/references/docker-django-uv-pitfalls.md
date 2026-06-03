# Docker + Django + uv — Multi-Stage Pitfalls (01/06/2026)

## 1. `UV_SYSTEM_PYTHON=1` quebra COPY --from builder

**Problema:** Com `UV_SYSTEM_PYTHON=1`, `uv sync` instala pacotes no Python do SISTEMA, não em `.venv`. O `COPY --from=builder /app/.venv /app/.venv` no estágio runtime copia um diretório VAZIO porque `.venv` nunca foi criado.

**Solução:** Remover `UV_SYSTEM_PYTHON=1` do builder. Sem ele, `uv sync` cria automaticamente `.venv` e instala as dependências lá.

## 2. `command:` no docker-compose.yml SOBRESCREVE Dockerfile CMD

Este é o pitfall #1. Causou 40+ tentativas de debug no Dockerfile quando o problema real era 1 linha no compose.

**Sintoma:** Container falha com `exec: "gunicorn": executable file not found` mesmo com gunicorn instalado e PATH configurado. Debug do Dockerfile parece correto.

**Causa:** `docker-compose.yml` tem `command: gunicorn ...` que sobrescreve completamente o `CMD` do Dockerfile. Se o Dockerfile define `CMD ["uv", "run", "gunicorn"...]`, o compose ignora e tenta executar `gunicorn` diretamente (sem uv/venv).

**Correção:** Ou remover `command:` do compose (usar CMD do Dockerfile), ou garantir que ambos estejam sincronizados.

## 3. `uv run` no CMD precisa de `uv` no runtime

Se o CMD usa `uv run gunicorn`, o binário `uv` precisa existir NO estágio runtime, não só no builder. Adicionar:
```dockerfile
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
```
no estágio runtime também.

## 4. FIELD_ENCRYPTION_KEY no build

O `collectstatic` roda durante o build e dispara o Django setup, que carrega `encrypted_model_fields`. Se `FIELD_ENCRYPTION_KEY` não estiver definida, o build falha.

**Solução:**
```dockerfile
ARG FIELD_ENCRYPTION_KEY=dummy
ENV FIELD_ENCRYPTION_KEY=${FIELD_ENCRYPTION_KEY}
```
E passar uma chave válida no build: `docker compose build --build-arg FIELD_ENCRYPTION_KEY=<chave>`

## 5. STATIC_ROOT ausente no settings.py

Se `STATIC_ROOT` não estiver definido, `collectstatic` falha com `ImproperlyConfigured`. Adicionar:
```python
STATIC_ROOT = BASE_DIR / "staticfiles"
```

## 6. Apps inexistentes em INSTALLED_APPS

Apps planejados (`orcamento`, `crc`, `financeiro`) estão em `INSTALLED_APPS` mas não existem ainda (estão em `_archive/`). Comentá-los até que sejam implementados.

## 7. Single-stage é mais simples que multi-stage para dev

Para ambiente de desenvolvimento, single-stage com `uv sync && uv pip install gunicorn` no mesmo estágio evita todos os problemas de COPY entre estágios. Deixar multi-stage para produção quando a otimização de camadas importa.

## 8. Port binding: SEMPRE usar `127.0.0.1`

No docker-compose, ports devem ser `127.0.0.1:8000:8000`, NUNCA `8000:8000` (que faz bind em `0.0.0.0`). O acesso externo deve ser EXCLUSIVAMENTE via Cloudflare Tunnel ou Nginx.
