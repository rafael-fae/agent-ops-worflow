---
name: diagnostico-evolution-api
description: Diagnosticar problemas na Evolution API (container, instâncias, webhooks, manager UI, autenticação) no servidor OVH de produção.
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Diagnóstico de Evolution API

## Checklist rápida de verificação

1. **Container UP?** `docker ps --filter "name=evolution-api"`
2. **API respondendo?** `curl localhost:80/ -H "Host: evolution.oesteodontologia.com.br"`
3. **Instâncias conectadas?** `curl -H "apikey: <KEY>" .../instance/fetchInstances`
4. **Webhook recebendo?** `sudo journalctl -u webhook-whatsapp --no-pager -n 20 | grep -v systemd`
5. **Mensagens no hoje.md?** `tail -3 {{COMMANDER_HOME}}fae/projects/pycode-cerebro/data/historico/hoje.md`
6. **Grupos acessíveis?** `curl -s "http://127.0.0.1:80/group/fetchAllGroups/<INSTANCE>?getParticipants=false" -H "apikey: <KEY>" -H "Host: evolution.oesteodontologia.com.br"`

## Máscara de Tokens — Armadilha Crítica

O terminal mascara tokens no output (`cat` mostra `***`). NUNCA confie no `cat`/`grep` simples para verificar tokens.

### Extração segura

```bash
# API key real (hex dump não mente)
docker inspect evolution-api --format '{{range .Config.Env}}{{println .}}{{end}}' | grep AUTHENTICATION_API_KEY | xxd

# Ou via docker exec direto (sem máscara)
docker exec evolution-api sh -c 'echo ${#AUTHENTICATION_API_KEY} && echo ${AUTHENTICATION_API_KEY:0:8}...${AUTHENTICATION_API_KEY: -4}'
```

### Valores confirmados (produção, 20/05/2026)

| Local | Chave | Valor (64 chars) |
|-------|-------|-------------------|
| Container env | `AUTHENTICATION_API_KEY` | `57c8b82fb8c16641c181ae040563b2254aa8efbfac61d04aeddd7d08d6c11ec9` |
| `/var/www/oeste-odontologia/.env` | `EVOLUTION_API_KEY` | idêntico ao container |
| `/var/www/dontus_app/config.yaml` | `evolution_apikey` | mesma chave |

### Validação de autenticação

```bash
# Teste com a API key CORRETA
curl -s --max-time 10 -w "\nHTTP:%{http_code}" \
  -H "apikey: 57c8b82fb8c16641c181ae040563b2254aa8efbfac61d04aeddd7d08d6c11ec9" \
  -H "Host: evolution.oesteodontologia.com.br" \
  http://127.0.0.1:80/instance/fetchInstances
# Esperado: HTTP 200 com JSON das instâncias
```

## Status "stopped" do fechamento-pycode = NORMAL

O `fechamento-pycode` é um **cron job PM2** (`55 22 * * *`). Após executar, fica com status `stopped` até a próxima execução agendada. NÃO é falha.

```bash
pm2 show fechamento-pycode  # Ver cron restart
pm2 logs fechamento-pycode  # Ver última execução
```

## Manager UI — "No chats found" (grupos não aparecem)

**Sintoma:** O Manager mostra "2 chats, 2 mensagens" no dashboard mas ao clicar em Chats não lista nenhum grupo. Os grupos EXISTEM e são retornados pela API (`/group/fetchAllGroups`).

**Causa:** `DATABASE_SAVE_DATA_CHATS=false` impede que grupos sejam persistidos na tabela `Chat`. A Evolution sabe dos grupos (vêm do WhatsApp), mas não os salva localmente. Os 2 chats que aparecem são chats de sistema (`lid` e `0@s.whatsapp.net`), não grupos reais.

**Solução:**
```bash
# 1. Alterar no docker-compose.yml
#    DATABASE_SAVE_DATA_CHATS=false → true
cd /var/www/oeste-odontologia
sed -i 's/DATABASE_SAVE_DATA_CHATS=false/DATABASE_SAVE_DATA_CHATS=true/' docker-compose.yml

# 2. Recriar o container
docker compose up -d evolution-api

# 3. Grupos aparecerão após a primeira mensagem recebida
```

**Verificação:** Conferir se grupos estão acessíveis via API mesmo sem aparecer no Manager:
```bash
curl -s "http://127.0.0.1:80/group/fetchAllGroups/<INSTANCE>?getParticipants=false" \
  -H "apikey: <KEY>" -H "Host: evolution.oesteodontologia.com.br"
```

**Nota:** Após os grupos aparecerem, pode voltar `DATABASE_SAVE_DATA_CHATS=false` se desejar privacidade. Os grupos já persistidos permanecem.

## Manager UI — "No instances found"

Possíveis causas e soluções:

| Causa | Verificação | Solução |
|-------|-------------|---------|
| API key expirada no browser | Testar endpoint com curl | Reinserir API key no manager |
| API key errada (máscara) | `xxd` do .env e container | Usar valor real extraído |
| Bug na versão da Evolution | `docker exec evolution-api node -e "..." /` → version | Atualizar imagem |
| `AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES` | Verificar env do container | Deve ser `true` (mas mesmo assim exige autenticação na v2.3.7) |

## Bug: WhatsApp Business na v2.3.7

**Sintoma:** Ao criar instância com integração `WHATSAPP_BUSINESS` (Meta Cloud API):
```
Error: Invalid `a.integrationSession.update()` invocation
PrismaClientKnownRequestError
meta: { modelName: 'Instance', column_name: '(not available)' }
```

**Causa:** Bug no Prisma da versão 2.3.7 (dezembro/2025) ao manipular sessões de WhatsApp Business. O método `integrationSession.update()` recebe metadados do Baileys (`deviceListMetadata`) em vez dos parâmetros corretos da Meta Cloud API.

**Solução:** A v2.4.0+ resolve o bug, mas introduz **licenciamento obrigatório**. Avalie antes de atualizar:

### Opções de upgrade

| Opção | Tag | WhatsApp Business | Licenciamento |
|-------|-----|-------------------|---------------|
| Ficar na v2.3.7 | `v2.3.7` | :x: Bug — não funciona | Grátis |
| Atualizar para homolog | `homolog` | :white_check_mark: Corrigido | :warning: **LICENSE_REQUIRED** |
| Atualizar para RC | `2.4.0-rc1` ou `2.4.0-rc2` | Incerto | Incerto — testar |

### ⚠️ Licenciamento v2.4.0+

A partir da versão 2.4.0, a Evolution API exige ativação de licença. Ao subir o container novo sem licença:

```json
{"error":"service not activated","code":"LICENSE_REQUIRED",
 "message":"This Evolution API instance is not activated. Open .../manager/login to activate,
 or set AUTHENTICATION_API_KEY in your .env with a valid licensing key."}
```

**TODAS as instâncias existentes (incluindo Baileys) ficam offline** até a licença ser ativada.

A ativação é feita em `https://evolution.oesteodontologia.com.br/manager/login`.

### Procedimento de atualização (se decidir prosseguir)

```bash
cd /var/www/oeste-odontologia
# Editar docker-compose.yml: trocar v2.3.7 por homolog
docker compose pull evolution-api
docker compose up -d evolution-api
# ⚠️ Imediatamente após: acessar /manager/login para ativar licença
```

### Rollback imediato (se licenciamento for bloqueador)

```bash
cd /var/www/oeste-odontologia
# Reverter tag no docker-compose.yml para v2.3.7
docker compose pull evolution-api
docker compose up -d evolution-api
# Container volta em ~30s, instâncias Baileys re-conectam automaticamente
```

### Procedimento de rollback aplicado (20/05/2026)

Durante este incidente, o rollback de `homolog` → `v2.3.7` foi necessário e bem-sucedido:
- Tag corrigida no `docker-compose.yml`
- `docker compose pull evolution-api && docker compose up -d evolution-api`
- Instância `{{COMMANDER}}` voltou a conectar automaticamente
- Manager UI voltou a funcionar sem licença

**Versões disponíveis (20/05/2026):**

| Tag | Data | Licenciamento | WhatsApp Business |
|-----|------|---------------|-------------------|
| `v2.3.7` | Dez/2025 | Grátis | :x: Bug Prisma |
| `2.4.0-rc1` | 06/05/2026 | Não testado | Desconhecido |
| `2.4.0-rc2` | 17/05/2026 | Não testado | Desconhecido |
| `homolog` | 19/05/2026 | :warning: LICENSE_REQUIRED | :white_check_mark: Corrigido |

## Estrutura de containers Evolution

```
evolution-api (evoapicloud/evolution-api)
evolution-postgres (postgres:15) — DB evolution, schema evolution_api, 37 tabelas
evolution-redis (redis:7-alpine) — cache
```

Rede: bridge `oeste-odontologia_oeste-network` (172.18.0.0/16)
Evolution API IP interno: 172.18.0.4:8080
NGINX proxy: evolution.oesteodontologia.com.br → evolution-api:8080

## Tabelas relevantes no PostgreSQL

```bash
docker exec evolution-postgres psql -U evolution_user -d evolution -c "
  SELECT table_name FROM information_schema.tables 
  WHERE table_schema='evolution_api' 
  AND table_name IN ('Instance','IntegrationSession','Setting','Webhook')
  ORDER BY table_name;
"
```

- `Instance`: instâncias (nome, número, connectionStatus, token)
- `IntegrationSession`: sessões de integração (type, status, parameters)
- `Setting`: configurações por instância (rejectCall, groupsIgnore, etc.)
- `Webhook`: configurações de webhook por instância

## Privacidade e Notificações — Configuração Recomendada

### Problema

A Evolution API com Baileys conecta como sessão WhatsApp Web completa. Por padrão:
2. **Todas as mensagens** de todos os chats (pessoais, grupos) são salvas no PostgreSQL
3. **Todas as contatos** são persistidos
4. **Notificações do celular são suprimidas** — WhatsApp considera a sessão Web como "leitor" e não envia push

### Solução: Desligar persistência + instância em modo "não-marca-lido"

**Nível 1 — docker-compose.yml (global, desliga armazenamento):**

```yaml
# Desligar tudo exceto instância (necessário para funcionamento)
- DATABASE_SAVE_DATA_INSTANCE=true
- DATABASE_SAVE_DATA_NEW_MESSAGE=false    # não salvar mensagens
- DATABASE_SAVE_MESSAGE_UPDATE=false      # não salvar edições
- DATABASE_SAVE_DATA_CONTACTS=false       # não salvar contatos
- DATABASE_SAVE_DATA_CHATS=false          # não salvar metadados de chats
```

**Nível 2 — Configuração da instância (via Manager UI ou API):**

Ao criar (ou editar) a instância WhatsApp:
- `Read Messages`: **false**
- `Read Status`: **false**  ← Na v2.4.0+, o antigo "Mark Messages Read" foi renomeado para "Read Status"

Isso garante que o WhatsApp continue enviando notificações push para o celular.

**Verificação via API (confirma os valores reais):**
```bash
curl -s -H "apikey: <KEY>" -H "Host: evolution.oesteodontologia.com.br" \
  http://127.0.0.1:80/instance/fetchInstances | python3 -c "
import json,sys
for i in json.load(sys.stdin):
    s = i.get('Setting', {})
    print(f'{i[\"name\"]}: readMessages={s.get(\"readMessages\")}, readStatus={s.get(\"readStatus\")}')
"
```

**⚠️ Mudança de nome na v2.4.0+:** No Manager UI da v2.4.0-rc2, o campo "Mark Messages Read" foi renomeado para **"Read Status"**. Na API, o campo é `readStatus`. Se não encontrar "Mark Messages Read", procure por "Read Status".

**Nível 3 — Definitivo (médio prazo):**
Número de WhatsApp dedicado para o bot (chip pré-pago, ~R$30/mês). Adicionar apenas ao grupo monitorado. Isolamento total — zero acesso a conversas pessoais.

## ⚠️ Licença invalidada ao migrar servidor

Ao migrar o Evolution para outro servidor (ou recriar o container com novo volume), o `instance_id` muda. A licença anterior é invalidada e a API retorna `LICENSE_REQUIRED`.

**Sintoma:** `fetchInstances` retorna `{"error":"service not activated","code":"LICENSE_REQUIRED"}` mas o endpoint `/` (root) e `/manager/login` continuam funcionando.

**Solução:** Acessar `https://evolution.oesteodontologia.com.br/manager/login` e re-ativar com conta Google.

**⚠️ Pós-reativação:** As instâncias SOMEM (novo `instance_id`). É necessário recriar a instância WhatsApp e re-escanear o QR code.

## Formato de JID do WhatsApp

### Sintoma

- `fetchInstances` retorna `[]`
- Banco PostgreSQL: `SELECT * FROM evolution_api."Instance"` retorna 0 rows
- Blog não atualiza (sem mensagens no `hoje.md`)
- Manager UI mostra "No instances found"

### Causas comuns

| Causa | Quando ocorre |
|-------|--------------|
| Upgrade 2.3.7 → 2.4.0 com reset de banco | Migração de SQLite para PostgreSQL |
| Container recriado e volume `evolution_data` vazio | Instâncias estavam só em cache Redis |
| `docker compose down -v` executado acidentalmente | Volumes removidos |
| Banco PostgreSQL resetado manualmente | `docker volume rm evolution_postgres_data` |

### :warning: Pitfall: Perda silenciosa pós-upgrade v2.4.0 (confirmado 21/05/2026)

Ao fazer upgrade `v2.3.7` → `2.4.0-rc2` (17/05), a instância WhatsApp pode **parecer funcionar normalmente** (webhooks ativos, mensagens chegando) mesmo sem estar no banco PostgreSQL. A instância sobrevive **apenas em cache Redis** — ao recriar o container (`docker compose up -d`), o Redis é limpo e a instância se perde **permanentemente**. Verificação obrigatória pós-upgrade:

```bash
# Confirmar que a instância está REALMENTE no PostgreSQL, não só em Redis
docker exec evolution-postgres psql -U evolution_user -d evolution -c \
  "SELECT id, name, status FROM evolution_api.\"Instance\";"
# Se retornar 0 rows após upgrade: instância perdida. Recriar via Manager UI.
```

NÃO confie em `fetchInstances` da API — ele pode retornar instâncias do cache Redis sem persistência real no banco.

### Procedimento de Recriação (requer acesso ao Manager UI + WhatsApp)

1. Acessar `https://evolution.{{COMMANDER}}fae.com.br/manager` (ou domínio equivalente)
2. Login com API key
3. Criar nova instância WhatsApp:
   - **Integration**: `WHATSAPP-BAILEYS`
   - **Name**: sugestivo (ex: `pycode-bot`)
   - **Read Messages**: `false`
   - **Read Status**: `false` (≡ "Mark Messages Read" da v2.3.7)
4. Configurar Webhook da instância:
   - Via Manager UI: URL `http://172.18.0.1:8001/webhook`, Events `MESSAGES_UPSERT`
   - Ou via API: `POST /webhook/set/{name}` com body `{"webhook":{"url":"...","events":["MESSAGES_UPSERT"],"enabled":true}}`
5. Escanear QR code com WhatsApp Mobile → Linked Devices
6. Aguardar status `connected` (verde)
7. Verificar: enviar mensagem no grupo Pycode e conferir se aparece em `hoje.md`

:warning: Gateway `172.18.0.1` é o IP do host visto de dentro da rede Docker bridge. **NUNCA usar `localhost`** — dentro do container aponta para o próprio container.

## ⚠️ Pitfall: Mudança de nome de evento na v2.4.0

Na v2.3.7, o Evolution enviava eventos webhook como `messages.upsert` (minúsculo, ponto).
Na **v2.4.0+**, o formato mudou para `MESSAGES_UPSERT` (maiúsculo, underscore).

Se o webhook receiver (FastAPI) filtra por `evento == "messages.upsert"`, ele **não vai capturar** eventos da v2.4.0+.

**Correção:** Aceitar ambos os formatos:
```python
if evento in ("messages.upsert", "MESSAGES_UPSERT"):
```

## ⚠️ Pitfall: Grupos não aparecem no Manager UI

Se `DATABASE_SAVE_DATA_CHATS=false`, os grupos NÃO são persistidos no banco.
O endpoint `fetchAllGroups` retorna os grupos corretamente, mas a aba "Chats" do Manager UI consulta a tabela `Chat`, que estará vazia.

**Sintoma:** Contador mostra "2 chats" mas ao clicar não aparece nada (os 2 são chats de sistema: `@lid` e `0@s.whatsapp.net`).

**Solução:** Temporariamente setar `DATABASE_SAVE_DATA_CHATS=true`, interagir com o grupo, depois reverter.

## Webhook WhatsApp — arquitetura

Ver `references/evolution-broker-pattern.md` para o código completo do broker
e configuração systemd. O broker substituiu o receptor simples em 30/05/2026.

```
Evolution API (172.18.0.4:8080) 
  → POST /webhook → 
webhook-whatsapp (systemd, porta 8001, FastAPI via uvicorn) 
  → salva em {{COMMANDER_HOME}}/projects/pycode-cerebro/data/historico/hoje.md
  → filtrado: apenas grupo 120363425868389123@g.us
```

Logs: `sudo journalctl -u webhook-whatsapp`

### :warning: O webhook NÃO executa o script Python diretamente

O arquivo `receptor_whatsapp.py` **define** `app = FastAPI()` mas **NÃO contém** `uvicorn.run()`. A execução correta é via **uvicorn** como entry point:

```
# CORRETO — uvicorn carrega o módulo como aplicação ASGI
.venv/bin/uvicorn receptor_whatsapp:app --host 0.0.0.0 --port 8001

# ERRADO — apenas define a classe e sai (exit code 0, sem escutar porta)
.venv/bin/python3 receptor_whatsapp.py
```

No PM2 do servidor antigo, isso era configurado como:
- `script`: `.venv/bin/uvicorn`
- `args`: `receptor_whatsapp:app --host 0.0.0.0 --port 8001`
- `interpreter`: `.venv/bin/python`

**Preferir systemd sobre PM2** para este serviço — evita problemas de `VIRTUAL_ENV` não propagado.

### Recriação do serviço (systemd)

```ini
[Service]
User={{COMMANDER}}fae
WorkingDirectory={{COMMANDER_HOME}}fae/projects/pycode-cerebro/scripts
ExecStart={{COMMANDER_HOME}}fae/projects/pycode-cerebro/scripts/.venv/bin/uvicorn receptor_whatsapp:app --host 0.0.0.0 --port 8001
Restart=always
```

## Configuração de Webhook via API (v2.4.0+)

Na v2.4.x, o endpoint de webhook mudou. Usa o **nome da instância** (não UUID) e requer body aninhado.

### Formato correto (v2.4.0-rc2)

```bash
# Usar NOME da instância, não UUID!
curl -s -X POST "http://127.0.0.1:80/webhook/set/pycode-bot" \
  -H "apikey: <API_KEY>" \
  -H "Host: evolution.oesteodontologia.com.br" \
  -H "Content-Type: application/json" \
  -d '{
    "webhook": {
      "url": "http://172.18.0.1:8001/webhook",
      "events": ["MESSAGES_UPSERT"],
      "enabled": true
    }
  }'
```

### Pitfalls de webhook na v2.4.x

| Erro | Causa | Correção |
|------|-------|----------|
| Body plano `{"url":"...","events":[...]}` → `"instance requires property 'webhook'"` | v2.4.x exige `{"webhook": {...}}` | Aninhar dentro de `"webhook"` |
| Usar UUID → 404 `"instance does not exist"` | Endpoint usa `instanceName`, não `instanceId` | Usar nome (ex: `pycode-bot`) |
| `GET /webhook/find/{name}` → 404 | Endpoint `find` não existe na v2.4.x | Ver webhook via `fetchInstances` |
| **Webhook não recebe mensagens (ZERO requests)** | **v2.4.0 mudou nome do evento de `messages.upsert` para `MESSAGES_UPSERT`** | **Atualizar `receptor_whatsapp.py` para aceitar ambos** |

### :red_circle: Pitfall: Mudança no nome do evento na v2.4.0

A Evolution API v2.4.0 alterou o formato dos nomes de eventos nos webhooks:

| Versão | Nome do evento |
|--------|---------------|
| v2.3.7 | `messages.upsert` (minúsculo, ponto) |
| v2.4.0+ | `MESSAGES_UPSERT` (maiúsculo, underscore) |

**Sintoma:** Webhook configurado corretamente, Evolution envia, mas o receptor NUNCA processa — `journalctl -u webhook-whatsapp` mostra zero requisições. O endpoint responde a testes manuais (curl), mas mensagens reais do WhatsApp não são salvas.

**Correção no `receptor_whatsapp.py`:**
```python
# Antes (só v2.3.x)
if evento == "messages.upsert":

# Depois (compatível com ambas)
if evento == "messages.upsert" or evento == "MESSAGES_UPSERT":
```

**Verificação pós-correção:**
```bash
sudo systemctl restart webhook-whatsapp
# Enviar mensagem no grupo e conferir:
tail -3 {{COMMANDER_HOME}}fae/projects/pycode-cerebro/data/historico/hoje.md
```

## Envio de Mensagens via Evolution API

Agentes Hermes podem enviar mensagens WhatsApp pela Evolution API usando o endpoint `sendText`. Padrão útil para notificações e comunicação direta.

### Formato da requisição

```bash
curl -s -X POST "http://127.0.0.1:80/message/sendText/<INSTANCE>" \
  -H "apikey: <API_KEY>" \
  -H "Host: evolution.oesteodontologia.com.br" \
  -H "Content-Type: application/json" \
  -d '{"number":"<NUMERO>","text":"<MENSAGEM>"}'
```

### Número do destinatário

Ver referência completa: `references/whatsapp-number-vs-jid.md`

- **Formato:** código do país + DDD + número, sem `+` ou espaços
- **Exemplo (Brasil):** `5567999623440` (55=BR, 67=MS, 999623440=número)
- **NÃO usar** o `ownerJid` da instância (`556796445811@s.whatsapp.net`) — é o JID interno do WhatsApp, não o número de telefone
- **NÃO usar** `@s.whatsapp.net` ou `@g.us` no parâmetro `number`
- **⚠️ O número informado pode não corresponder ao JID real.** Sempre validar via webhook antes de configurar filtros. Ver `references/whatsapp-number-vs-jid.md`.

### Status da resposta

- `PENDING`: mensagem enfileirada para envio (normal)
- `status: 1` nos logs do container: mensagem enviada com sucesso
- Se o destinatário não recebeu: verificar se o número está no formato correto (sem JID suffix)

### Uso programático (Python)

```python
import requests

def send_whatsapp(instance, number, text):
    return requests.post(
        f"http://127.0.0.1:80/message/sendText/{instance}",
        headers={
            "apikey": "57c8b82fb8c16641c181ae040563b2254aa8efbfac61d04aeddd7d08d6c11ec9",
            "Host": "evolution.oesteodontologia.com.br",
            "Content-Type": "application/json"
        },
        json={"number": number, "text": text},
        timeout=10
    ).json()
```

## Limpeza de Mensagens Armazenadas

Quando `DATABASE_SAVE_DATA_NEW_MESSAGE=false` é configurado **após** a instância já ter sincronizado, as mensagens antigas permanecem no PostgreSQL. Para limpar:

```bash
# Verificar contagem
docker exec evolution-postgres psql -U evolution_user -d evolution -c \
  "SELECT COUNT(*) FROM evolution_api.\"Message\";"

# Deletar todas as mensagens
docker exec evolution-postgres psql -U evolution_user -d evolution -c \
  "DELETE FROM evolution_api.\"Message\";"

# Confirmar que ficou zero
docker exec evolution-postgres psql -U evolution_user -d evolution -c \
  "SELECT COUNT(*) FROM evolution_api.\"Message\";"
```

### Verificação de que novas mensagens NÃO estão sendo salvas

Após a limpeza, aguardar alguns minutos e recontar. Se o número continuar 0, `DATABASE_SAVE_DATA_NEW_MESSAGE=false` está sendo respeitado.

### ⚠️ Sincronização inicial enche o banco mesmo com SAVE=false

Ao conectar uma nova instância Baileys, o WhatsApp sincroniza mensagens recentes de todos os chats. Essas mensagens entram como "new message" e **são salvas antes** que a configuração `DATABASE_SAVE_DATA_NEW_MESSAGE=false` tenha efeito (race condition na inicialização). A limpeza pós-sincronização é necessária.
