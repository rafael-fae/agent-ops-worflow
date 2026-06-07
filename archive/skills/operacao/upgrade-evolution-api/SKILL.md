---
name: upgrade-evolution-api
description: Procedimento para upgrade da Evolution API (v2.3.7 → v2.4.0+) e reset de banco de dados quando migrations falham. Cobre licenciamento, foreign key orphans, e re-ativação pós-reset.
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Upgrade da Evolution API — v2.3.7 para v2.4.0+

## Contexto

A Evolution API v2.4.0+ (tags `homolog`, `latest`, `2.4.0-rc*`) introduziu:
- **Licenciamento obrigatório** (`LICENSE_REQUIRED`) — a API não funciona sem ativar licença
- **Novas migrations** que adicionam constraints FK nas tabelas `Setting` e `IntegrationSession`
- **Integração nativa com Meta Cloud API** (WhatsApp Business oficial)

## Pitfalls conhecidos

### Pitfall 1: Foreign Key orphans após deletar instâncias

Se você deletou uma instância na v2.3.7, os registros na tabela `Setting` com `instanceId` da instância deletada ficam órfãos. A v2.3.7 não tinha constraint `Setting_instanceId_fkey` — a v2.4.0 tenta criar e **falha**.

**Sintoma após upgrade:**
```
PrismaClientValidationError: Invalid `a.integrationSession.update()` invocation
Foreign key constraint violated on the constraint: `Setting_instanceId_fkey`
```

**Solução:** Reset completo do banco (ver abaixo).

### Pitfall 2: Licença invalidada após reset

Resetar o banco gera um novo `instance_id`, invalidando a licença anterior. É preciso re-ativar em `http://evolution.oesteodontologia.com.br/manager/login`.

### Pitfall 4: Instância sobrevive apenas em cache Redis pós-upgrade

Após upgrade `v2.3.7` → `v2.4.0-rc2`, a instância WhatsApp pode **parecer funcionar** (webhooks ativos, fetchInstances retorna a instância, mensagens chegando) sem estar realmente no PostgreSQL. A instância existe apenas em cache Redis e sobrevive enquanto o container não é recriado.

**Confirmado em 21/05/2026:** Instância `{{COMMANDER}}` criada na v2.3.7 (SQLite) sobreviveu ao upgrade para `2.4.0-rc2` (PostgreSQL) apenas via Redis. Ao recriar o container com `docker compose up -d`, o Redis foi limpo e a instância se perdeu permanentemente.

**Verificação obrigatória pós-upgrade:**
```bash
# NÃO confie em fetchInstances — verifique o banco diretamente
docker exec evolution-postgres psql -U evolution_user -d evolution -c \
  "SELECT id, name, status FROM evolution_api.\"Instance\";"
# Se 0 rows: instância perdida. Recriar via Manager UI com QR code.
```

### Pitfall 3: Nginx com DNS cacheado após recriar containers

Após `docker rm` + `docker compose up -d`, o container evolution-api ganha um novo IP na rede bridge. O nginx pode manter o IP antigo em cache DNS, causando **502 Bad Gateway** em todas as requisições.

**Sintoma:**
- `docker exec oeste-odontologia-nginx sh -c 'curl -s http://evolution-api:8080/'` → 200 OK
- `curl -s -H "Host: evolution.oesteodontologia.com.br" http://127.0.0.1:80/` → 502 Bad Gateway

**Solução:** `docker restart oeste-odontologia-nginx`

## Procedimento de Upgrade Limpo (com reset de banco)

Este procedimento **apaga todo o histórico** (mensagens, contatos, instâncias). Só execute se não se importar com os dados.

### Passo 1: Alterar tag da imagem

Editar `/var/www/oeste-odontologia/docker-compose.yml`:
```yaml
evolution-api:
  image: evoapicloud/evolution-api:homolog  # era v2.3.7
```

### Passo 2: Pull da nova imagem

```bash
cd /var/www/oeste-odontologia
docker compose pull evolution-api
```

### Passo 3: Derrubar containers e remover volumes

```bash
cd /var/www/oeste-odontologia
docker compose stop evolution-api evolution-postgres evolution-redis
docker rm evolution-api evolution-postgres evolution-redis
docker volume rm oeste-odontologia_evolution_postgres_data oeste-odontologia_evolution_data oeste-odontologia_evolution_redis_data
```

### Passo 4: Subir do zero

```bash
cd /var/www/oeste-odontologia
docker compose up -d evolution-postgres evolution-redis evolution-api
```

As migrations rodarão automaticamente na inicialização com o banco limpo.

### Passo 4b (CRÍTICO): Restartar o Nginx

Após recriar os containers, o nginx pode manter cache DNS com o IP antigo do `evolution-api`, causando **502 Bad Gateway** mesmo com a API funcionando internamente.

```bash
docker restart oeste-odontologia-nginx
```

**Verificação rápida:** se `curl` de dentro do nginx funciona (`docker exec oeste-odontologia-nginx sh -c 'curl -s http://evolution-api:8080/'`) mas `curl` externo via Host header retorna 502, é DNS cacheado.

### Passo 5: Ativar licença

Acessar `http://evolution.oesteodontologia.com.br/manager/login` e ativar a licença com conta Google.

:warning: Se o manager/login retornar 502, verifique o Passo 4b. Durante o estado LICENSE_REQUIRED, o endpoint `/manager/login` **é acessível** mesmo com a API retornando 503 para outros endpoints.

### Passo 6: Verificar

```bash
curl -s -H "Host: evolution.oesteodontologia.com.br" http://127.0.0.1:80/
# Deve retornar: {"status":200,"message":"Welcome to the Evolution API, it is working!","version":"2.4.0",...}

curl -s -H "apikey: <API_KEY>" -H "Host: evolution.oesteodontologia.com.br" http://127.0.0.1:80/instance/fetchInstances
# Deve retornar array vazio [] (banco limpo)
```

## Diagnosticando migrations quebradas (sem reset)

Se NÃO quiser resetar o banco, verifique inconsistências:

```bash
# Verificar settings órfãos
docker exec evolution-postgres psql -U evolution_user -d evolution -c \
  "SELECT s.id, s.\"instanceId\" FROM evolution_api.\"Setting\" s 
   WHERE s.\"instanceId\" NOT IN (SELECT id FROM evolution_api.\"Instance\");"

# Se houver registros, removê-los:
docker exec evolution-postgres psql -U evolution_user -d evolution -c \
  "DELETE FROM evolution_api.\"Setting\" 
   WHERE \"instanceId\" NOT IN (SELECT id FROM evolution_api.\"Instance\");"
```

## Configuração de Webhook (Evolution → Host)

O webhook-whatsapp (FastAPI) roda no **host** (porta 8001, processo PM2), não em container.
O container Evolution precisa alcançar o host via **gateway da rede bridge Docker**:

```bash
# Descobrir o gateway
docker inspect evolution-api --format '{{range .NetworkSettings.Networks}}{{.Gateway}}{{end}}'
# Resultado típico: 172.18.0.1
```

**URL do webhook na instância (manager ou API):**
```
http://172.18.0.1:8001/webhook
```

Eventos obrigatórios: `MESSAGES_UPSERT` (maiúsculo, plural). Na v2.3.7 era `messages.upsert` (minúsculo, ponto). A v2.4.x mudou o nome para `MESSAGES_UPSERT`.

### Body da requisição de webhook (API v2.4.x)

Ao configurar webhook via API (`/instance/setWebhook/{instanceName}`), o body é:
```json
{
  "enabled": true,
  "events": ["MESSAGES_UPSERT"],
  "url": "http://172.18.0.1:8001/webhook"
}
```
**Atenção:** O campo é `events` (array), e o nome do evento é `MESSAGES_UPSERT` (maiúsculo, com `S` no final). Body errado → Evolution retorna 404 na configuração.

:warning: **NUNCA usar `localhost` ou `127.0.0.1`** — dentro do container, isso aponta para o próprio container, não para o host.

## Atenção: Dontus App — dependência de instância

O dashboard Dontus (`/var/www/dontus_app/config.yaml`) referencia diretamente a instância Evolution:

```yaml
whatsapp:
  provider: evolution
  evolution_instance: oeste-odontologia
  evolution_apikey: <API_KEY>
```

**Se deletar uma instância, atualize `config.yaml`** — caso contrário o envio de WhatsApp pelo Dontus quebra silenciosamente.

## Rollback para v2.3.7

Se a v2.4.0 der problemas e quiser voltar:

```bash
# Reverter tag no docker-compose.yml
# image: evoapicloud/evolution-api:v2.3.7

docker compose pull evolution-api
docker compose up -d evolution-api
```

O banco da v2.4.0 é compatível com v2.3.7 na maioria dos casos (tabelas extras são ignoradas).

## API Key

A API key global está em `/var/www/oeste-odontologia/.env` como `EVOLUTION_API_KEY`.
Para verificar o valor real (sem máscara `***`):

```bash
grep "EVOLUTION_API_KEY" /var/www/oeste-odontologia/.env | xxd | head -8
```

NUNCA usar `cat` — o terminal mascara tokens.

## Tags disponíveis (Maio/2026)

| Tag | Atualizada | Notas |
|-----|-----------|-------|
| `v2.3.7` | Dez/2025 | Estável, sem licenciamento, bug ao criar instância WhatsApp Business |
| `2.4.0-rc1` | 06/05/2026 | Release candidate |
| **`2.4.0-rc2`** | **17/05/2026** | **Recomendada — estável, Meta Cloud API funcional, licenciamento ok** |
| `homolog` | 19/05/2026 | :x: **EVITAR — bug FK `Setting_instanceId_fkey` mesmo com banco limpo. Use rc2.** |
| `latest` | 06/05/2026 | Última estável |

### Lições da troca `homolog` → `2.4.0-rc2`

Em 20/05/2026, trocamos `v2.3.7` → `homolog`. Sintomas:
1. Licenciamento exigido — ativado com conta Google
2. Ao criar instância WhatsApp Business: `Foreign key constraint violated: Setting_instanceId_fkey`
3. Resetamos banco (containers + volumes removidos, recriados do zero)
4. **Mesmo erro** após reset completo
5. Trocamos para `2.4.0-rc2` — funcionou imediatamente

**Conclusão:** O bug é da tag `homolog` (homologação, 2 dias após rc2), não do banco. A `rc2` é estável.

## Cloudflare Access vs Webhook da Meta

### Problema

O Cloudflare Access (2FA) no subdomínio `evolution.oesteodontologia.com.br` **bloqueia a verificação de webhook da Meta**. O Cloudflare redireciona (302) para a página de login 2FA antes que a requisição chegue ao nginx. A Meta não segue redirects de autenticação.

**Sintoma no Meta Developer Dashboard:**
```
Não foi possível validar a URL de callback ou o token de verificação.
(#N/A:WBxP--1514189430-3819318114)
```

**Verificação via terminal:**
```bash
curl -s -w "\nHTTP:%{http_code}" "https://evolution.oesteodontologia.com.br/webhook/meta?hub.mode=subscribe&hub.verify_token=evolution&hub.challenge=test"
# Se retornar HTTP:302 com HTML do Cloudflare → Access está bloqueando
```

### Solução: Subdomínio dedicado sem Access

**Passo 1 — Criar subdomínio no Cloudflare Tunnel:**
- Acessar `https://one.dash.cloudflare.com` → Zero Trust → Networks → Tunnels
- Editar o túnel ativo → Public Hostname → Add
  - **Subdomain**: `webhook`
  - **Domain**: `oesteodontologia.com.br`
  - **Service**: `http://nginx:80`
- **NÃO** habilitar Cloudflare Access para este subdomínio

**Passo 2 — Adicionar subdomínio ao nginx:**
Editar `/var/www/oeste-odontologia/nginx.conf`, server block do Evolution:
```nginx
server_name evolution.oesteodontologia.com.br webhook.oesteodontologia.com.br;
```
Recarregar: `docker exec oeste-odontologia-nginx nginx -s reload`

**Passo 3 — Testar:**
```bash
curl -s -w "\nHTTP:%{http_code}" "http://127.0.0.1:80/webhook/meta?hub.mode=subscribe&hub.verify_token=<TOKEN>&hub.challenge=TEST" -H "Host: webhook.oesteodontologia.com.br"
# Deve retornar: TEST + HTTP:200
```

**Passo 4 — No Meta Developer Dashboard:**
- **Callback URL**: `https://webhook.oesteodontologia.com.br/webhook/meta`
- **Verify token**: o mesmo token configurado em `WA_BUSINESS_TOKEN_WEBHOOK`

### Por que não usar o subdomínio `evolution` sem Access?

O subdomínio `evolution` expõe o manager e a API da Evolution. Manter o Access nele é uma camada extra de segurança. O subdomínio `webhook` expõe apenas o endpoint de webhook (`/webhook/meta`), que já tem autenticação própria via token de verificação e assinatura da Meta. Separação de responsabilidades.

## Configuração de Webhook da Meta Cloud API

### Endpoint

A Evolution v2.4.0+ expõe o endpoint **`/webhook/meta`** para receber webhooks da Meta (WhatsApp Cloud API). A URL pública é:

```
https://evolution.oesteodontologia.com.br/webhook/meta
```

### Variáveis de ambiente (adicionar ao docker-compose.yml, serviço `evolution-api`)

```yaml
- WA_BUSINESS_TOKEN_WEBHOOK=<token_seguro>  # padrão: "evolution"
- WA_BUSINESS_URL=https://graph.facebook.com
- WA_BUSINESS_VERSION=v18.0
- WA_BUSINESS_LANGUAGE=en
```

**Gerar token seguro:**
```bash
openssl rand -hex 24
```

### Configuração no Meta Developer Dashboard

1. Acessar `https://developers.facebook.com` → App → WhatsApp → Configuration
2. **Callback URL**: `https://evolution.oesteodontologia.com.br/webhook/meta`
3. **Verify token**: o valor de `WA_BUSINESS_TOKEN_WEBHOOK` (ou `evolution` se não configurado)
4. Clicar **Verify and Save**
5. Assinar eventos: `messages`, `message_template_status_update`

### Criar instância WhatsApp Business na Evolution

No manager ou via API:
- **Integration**: `WHATSAPP-BUSINESS`
- **Token**: Token de acesso permanente gerado no Meta Developer Dashboard
- **Number**: `phone_number_id` do WABA

### Webhooks independentes — não conflitam

| | Instância Baileys ({{COMMANDER}}) | Instância Meta (WhatsApp Business) |
|---|---|---|
| **Direção** | Evolution → Host (`172.18.0.1:8001/webhook`) | Meta → Evolution (`/webhook/meta`) |
| **Propósito** | Alimentar blog pycode-cerebro | Atendimento do consultório |
| **Evento** | `messages.upsert` | `messages` (padrão Meta) |

Ambos podem coexistir sem conflito.
