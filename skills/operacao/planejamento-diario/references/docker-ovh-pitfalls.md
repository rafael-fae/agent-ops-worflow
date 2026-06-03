# Docker + uv + OVH — Pitfalls e Soluções (01/06)

## 1. docker-compose `command:` SOBRESCREVE Dockerfile CMD

**Sintoma:** Container falha com "executable not found" mesmo com Dockerfile correto.
**Causa:** `docker-compose.yml` tem `command: gunicorn ...` que sobrescreve o CMD.
**Solução:** Verificar SEMPRE o compose antes de debugar o Dockerfile.

## 2. UV_SYSTEM_PYTHON=1 → sem .venv

**Sintoma:** `COPY --from=builder /app/.venv` copia nada. Módulos não encontrados no runtime.
**Causa:** `UV_SYSTEM_PYTHON=1` instala tudo no sistema, não cria `.venv`.
**Solução:** Remover `UV_SYSTEM_PYTHON=1`. Single-stage com `uv run` é mais confiável que multi-stage COPY.

## 3. PgBouncer tag inexistente

**Sintoma:** `edoburu/pgbouncer:1.21-alpine` → "not found"
**Causa:** Tags do edoburu usam formato `v1.25.1-p0`, não `1.21-alpine`.
**Solução:** Usar `edoburu/pgbouncer:latest` ou tag exata `v1.25.1-p0`.

## 4. FIELD_ENCRYPTION_KEY ausente

**Sintoma:** `ImproperlyConfigured: Fernet key must be 32 url-safe base64-encoded bytes`
**Causa:** `django-encrypted-model-fields` exige a key no settings.
**Solução:** Gerar com `python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"` e passar como `--build-arg FIELD_ENCRYPTION_KEY=$KEY`.

## 5. STATIC_ROOT não configurado

**Sintoma:** `collectstatic` falha com "You're using the staticfiles app without having set STATIC_ROOT"
**Solução:** `STATIC_ROOT = BASE_DIR / "staticfiles"` no settings.py.

## 6. Apps inexistentes no INSTALLED_APPS

**Sintoma:** `ModuleNotFoundError: No module named 'apps.orcamento'`
**Solução:** Comentar apps ainda não implementados: `# 'apps.orcamento',  # TODO Sprint 10`

## 7. Gunicorn não instalado

**Solução:** Adicionar `"gunicorn>=23.0"` no pyproject.toml + `uv pip install gunicorn`.

## 8. SSH + systemd socket no Ubuntu 24.04

**Sintoma:** `Port 2222` no sshd_config é ignorado.
**Causa:** Socket activation controla as portas, não o sshd_config.
**Solução:** Override em `/etc/systemd/system/ssh.socket.d/override.conf`. NUNCA fechar porta 22 antes de testar a nova.
