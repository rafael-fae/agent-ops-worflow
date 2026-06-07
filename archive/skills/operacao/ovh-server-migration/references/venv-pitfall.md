# Pitfall: Virtualenv com Paths Hardcoded Pós-Migração

## O Problema

Python virtualenvs criados com `uv venv` ou `python -m venv` contêm paths absolutos no script `bin/activate`. Quando o venv é copiado via `rsync` de um servidor onde o username é `{{COMMANDER_HOME}}/` para outro onde é `{{COMMANDER_HOME}}fae/`, o VIRTUAL_ENV no script `activate` aponta para o path antigo.

## Sintoma

- `pm2 logs` mostra `ModuleNotFoundError: No module named 'fastapi'`
- Mas `python3 -c "import fastapi; print('OK')"` funciona no terminal interativo
- `pm2 show <nome> | grep interpreter` confirma que o interpreter está correto (`.venv/bin/python3`)
- O processo PM2 restarta 15 vezes e para com status `errored`

## Diagnóstico

```bash
# Verificar o VIRTUAL_ENV hardcoded
grep 'VIRTUAL_ENV=' .venv/bin/activate
# Se mostrar {{COMMANDER_HOME}}/... mas o usuário é {{COMMANDER}}fae → venv quebrado

# Confirmar que o venv está quebrado
source .venv/bin/activate
echo $VIRTUAL_ENV
# Deve corresponder ao path REAL do venv, não ao path antigo
```

## Solução Definitiva

**Recriar o venv do zero no servidor novo:**

```bash
rm -rf .venv
uv venv --python 3.12
source .venv/bin/activate
uv pip install fastapi uvicorn python-dotenv  # reinstalar dependências
```

NUNCA confiar em venvs copiados via rsync entre servidores com usernames diferentes.

## PM2 + Venv — Padrão de Wrapper Script

Mesmo com venv recriado, o PM2 pode não ativar o venv corretamente. Usar wrapper script como padrão:

```bash
cat > /tmp/run_webhook.sh << 'WRAPPER'
#!/bin/bash
. {{COMMANDER_HOME}}fae/projects/pycode-cerebro/scripts/.venv/bin/activate
exec python3 {{COMMANDER_HOME}}fae/projects/pycode-cerebro/scripts/receptor_whatsapp.py
WRAPPER

chmod +x /tmp/run_webhook.sh
pm2 start /tmp/run_webhook.sh --name webhook-whatsapp --interpreter /bin/bash
```

## Registro da Sessão (30/05/2026)

Durante a migração OVH, este bug causou ~45 minutos de debugging:
1. PM2 mostrava `ModuleNotFoundError: No module named 'fastapi'` repetidamente
2. O teste manual `python3 -c "import fastapi"` funcionava no terminal
3. O PM2 estava configurado com `--interpreter .venv/bin/python3` correto
4. O `cwd` estava correto
5. A causa raiz: o venv foi copiado via rsync do servidor antigo (`{{COMMANDER_HOME}}/`) para o novo (`{{COMMANDER_HOME}}fae/`)
6. O `VIRTUAL_ENV` no script `activate` apontava para `{{COMMANDER_HOME}}/projects/pycode-cerebro/scripts/.venv`
7. Ao ativar o venv, o PATH era configurado com o path antigo, e o Python não encontrava os pacotes

**Tempo perdido:** ~45 min | **Lição:** SEMPRE recriar venvs em servidor novo
