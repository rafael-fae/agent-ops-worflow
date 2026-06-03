---
name: server-migration-ovh
description: Procedimento completo para migração de infraestrutura entre servidores OVH — Docker, PM2, systemd, Cloudflare Tunnel, Hermes agents. Cobre o workflow OVH→OVH com rsync direto, armadilhas de venv, switch de túnel, e verificação pós-migração.
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Server Migration — OVH to OVH

## Gatilho
- {{COMMANDER}} adquire novo servidor OVH e quer migrar toda a infraestrutura
- Substituição de servidor (hardware upgrade, fim de vida, etc.)
- Clonagem de ambiente para disaster recovery

## Workflow Completo

### FASE 0 — Preparação do Servidor Novo
1. Criar usuário (ex: `{{COMMANDER}}fae`) com sudo, copiar chaves SSH
2. Remover usuário padrão (`ubuntu`) após confirmar acesso
3. Configurar SSH-only (PasswordAuthentication no)
4. Instalar: Docker, Node 22, Python 3.12, uv, PM2, ZSH, cloudflared
5. Instalar CLIs: Gemini CLI, OpenCode CLI
6. Configurar UFW com as mesmas regras
7. Configurar timezone America/Cuiaba
8. Configurar sudo NOPASSWD para o novo usuário

### FASE 1 — Conexão Entre Servidores
1. Gerar chave SSH SEM passphrase no servidor antigo:
   `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_migrate -N ''`
2. Adicionar chave pública ao `authorized_keys` do servidor novo
3. Configurar SSH config no antigo com `IdentitiesOnly yes` e `StrictHostKeyChecking accept-new`
4. Testar: `ssh -i ~/.ssh/id_ed25519_migrate user@<new-ip>`

### FASE 2 — Copiar Dados (OVH→OVH via rsync)
Transferência direta entre servidores OVH é rápida (~30 MB/s).

```bash
# SEMPRE excluir .venv, node_modules, __pycache__
rsync -avz --exclude='.venv' --exclude='__pycache__' --exclude='node_modules' \
  /path/old/ new-ovh:/path/new/
```

Diretórios típicos:
- `/var/www/` — sites, docker-compose
- `/home/user/projects/` — pycode-blog, pycode-cerebro, meta-webhook
- `/home/user/sia_projeto/` — SIA (pode ser 13GB+)
- `/home/user/hermes-roshar/` — Docker agents
- `/home/user/Dev/hermes-profiles/` — Perfis dos agentes
- `/home/otheruser/` — Ambiente da Thaísa (300 MB)

### FASE 3 — Docker
1. Parar containers no servidor antigo: `docker compose stop`
2. Copiar volumes:
```bash
for vol in mysql_data evolution_postgres_data evolution_redis_data dontus_data; do
  rsync -avz /var/lib/docker/volumes/oeste-odontologia_$vol/ new-ovh:/tmp/docker-volumes/$vol/
done
```
3. No servidor novo, mover volumes para `/var/lib/docker/volumes/oeste-odontologia_*/`
4. `docker compose pull && docker compose up -d`

### FASE 4 — Serviços Host
- PM2: pycode-blog (porta 8080), webhook-meta (porta 8002)
- systemd: SIA (8501), cloudflared, Thaísa agents, Lirin gateway
- webhook-whatsapp: usar systemd com ExecStart apontando para `.venv/bin/uvicorn`

### FASE 5 — Switch Cloudflare Tunnel
1. **Parar** cloudflared no servidor antigo
2. **Iniciar** cloudflared no servidor novo (mesmo tunnel ID/credentials)
3. Tráfego migra em ~30 segundos — zero mudança de DNS
4. Testar todos os subdomínios
5. Habilitar cloudflared no boot: `systemctl enable cloudflared`

**Importante**: Garantir acesso SSH por IP direto a AMBOS os servidores antes do switch. Se o túnel falhar, o IP direto é o acesso de contingência.

### FASE 6 — Pós-Migração
1. Evolution API: re-ativar licença em `/manager/login` (Google OAuth)
2. Recriar instância WhatsApp (o `instance_id` muda com novo servidor)
3. Configurar webhook da instância → `http://172.18.0.1:8001/webhook`
4. Desabilitar/parar serviços no servidor antigo
5. Monitorar por 24h

## :red_circle: PITFALLS CRÍTICOS

### P1 — .venv com paths hardcoded do servidor antigo
**Sintoma**: `ModuleNotFoundError: No module named 'fastapi'` mesmo com o venv ativado.
**Causa**: O `VIRTUAL_ENV` no script de ativação aponta para `{{COMMANDER_HOME}}/...` (servidor antigo), mas o novo servidor tem `{{COMMANDER_HOME}}fae/...`.
**Solução**: NUNCA copiar .venv via rsync. Recriar com `uv venv --python 3.12 && uv sync`.
**Verificação**: `source .venv/bin/activate && echo $VIRTUAL_ENV` — deve apontar para o path do novo servidor.

### P2 — PM2 usa python3 do sistema, não do .venv
Mesmo com `--interpreter .venv/bin/python3`, o PM2 pode não propagar o `VIRTUAL_ENV` corretamente.
**Solução**: Para serviços Python, preferir **systemd** com `ExecStart` apontando diretamente para `.venv/bin/uvicorn` (ou `.venv/bin/python3`).

### P3 — webhook-whatsapp usa uvicorn, não o script Python
O script `receptor_whatsapp.py` define `app = FastAPI()` mas NÃO contém `uvicorn.run()`. A execução correta é:
```
.venv/bin/uvicorn receptor_whatsapp:app --host 0.0.0.0 --port 8001
```
NUNCA executar o script Python diretamente — ele apenas define o app e sai.

### P4 — SSH config com diretivas órfãs
Ao editar `~/.ssh/config`, linhas que sobraram de um bloco `Host` removido tornam-se configurações GLOBAIS.
**Exemplo**: Se sobrar `User {{COMMANDER}}` fora de um bloco `Host`, TODAS as conexões SSH usarão esse usuário.
**Solução**: Sempre comentar ou remover linhas inteiras ao remover um bloco Host.

### P5 — Rotas do Cloudflare Tunnel são gerenciadas remotamente
O arquivo `/etc/cloudflared/config.yml` local é IGNORADO para hostnames. As rotas reais vêm do Cloudflare Zero Trust dashboard.
- NÃO adicionar rotas manualmente no config local — serão sobrescritas
- O túnel recebe a configuração remotamente ao conectar
- Verificar com `sudo journalctl -u cloudflared | grep "config="` para ver a configuração real

### P6 — Evolution API: licença invalidada com novo servidor
O `instance_id` é derivado do hardware/SO. Um novo servidor gera novo `instance_id`, invalidando a licença anterior.
**Solução**: Após o switch do túnel, acessar `/manager/login` e re-ativar com Google OAuth.

## Serviços — Padrão de Deploy

| Serviço | Melhor via | Motivo |
|---|---|---|
| Node.js (Express) | PM2 | PM2 é ótimo para Node |
| Python/FastAPI | systemd | Evita o bug de venv do PM2 |
| Streamlit | systemd | `uv run streamlit` via systemd |
| Docker compose | docker compose | Padrão |
| Hermes agents | systemd | Isolamento, restart, logging |

## Verificação Pós-Migração

```bash
# Todos os serviços
docker ps --format 'table {{.Names}}\t{{.Status}}'
systemctl list-units --type=service --state=running | grep -E 'hermes|orto|webhook|cloudflared'
pm2 status

# Portas
ss -tlnp | grep -E '80 |8080|8001|8002|8501|8502'

# Subdomínios
for domain in oesteodontologia.com.br dashboard.oesteodontologia.com.br evolution.oesteodontologia.com.br sia.oesteodontologia.com.br webhook.oesteodontologia.com.br {{BLOG_URL}}; do
  echo -n "$domain: "
  curl -s -o /dev/null -w '%{http_code}' "https://$domain/"
  echo ""
done
```
