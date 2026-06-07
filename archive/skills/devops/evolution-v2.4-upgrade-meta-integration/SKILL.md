---
name: evolution-v2.4-upgrade-meta-integration
description: Procedimento para upgrade da Evolution API v2.3.7 → v2.4.0-rc2, ativação de licença, e integração com Meta Cloud API (WhatsApp Oficial). Inclui pitfalls de Cloudflare Tunnel, nginx, e licenciamento.
category: devops
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Evolution API — Upgrade v2.3.7 → v2.4.0 + Meta Cloud API

## Contexto
A v2.3.7 não suporta integração com Meta Cloud API (WhatsApp Business oficial). A v2.4.0 introduz suporte nativo via `WHATSAPP-BUSINESS` integration, mas exige **licenciamento obrigatório**.

## Versões

| Tag | Status | Meta Cloud API | Licença |
|---|---|---|---|
| `v2.3.7` | Estável | ❌ | Não exige |
| `2.4.0-rc2` | Funcional | ✅ | Exige |
| `homolog` | **BUGADO** — FK violation `Setting_instanceId_fkey` | ✅ | Exige |

:warning: **Use SEMPRE `evoapicloud/evolution-api:2.4.0-rc2`**, nunca `homolog`.

---

## Procedimento de Upgrade

### 1. Alterar tag no docker-compose.yml

```yaml
evolution-api:
    image: evoapicloud/evolution-api:2.4.0-rc2
```

### 2. Resetar banco (obrigatório — migrations novas)

```bash
cd /var/www/oeste-odontologia
docker compose stop evolution-api evolution-postgres evolution-redis
docker rm evolution-api evolution-postgres evolution-redis
docker volume rm oeste-odontologia_evolution_postgres_data oeste-odontologia_evolution_data oeste-odontologia_evolution_redis_data
docker compose up -d evolution-postgres evolution-redis evolution-api
```

### 3. Restartar nginx (DNS cache)

```bash
docker restart oeste-odontologia-nginx
```

O nginx mantém cache do IP do container `evolution-api`. Após recriar o container, o IP muda e o nginx retorna 502 até ser reiniciado.

### 4. Ativar licença

1. Acessar `http://evolution.oesteodontologia.com.br/manager/login`
2. Logar com Google
3. A licença é vinculada ao `instance_id` — resetar o banco gera um novo ID e invalida licenças anteriores
4. O novo `instance_id` aparece na resposta de erro 503: `"instance_id":"53550b0a-..."`

---

## Meta Cloud API — Configuração

### Variáveis de ambiente no docker-compose.yml

```yaml
- WA_BUSINESS_TOKEN_WEBHOOK=<token_hex_48_chars>
- WA_BUSINESS_URL=https://graph.facebook.com
- WA_BUSINESS_VERSION=v18.0
- WA_BUSINESS_LANGUAGE=en
```

`WA_BUSINESS_TOKEN_WEBHOOK` é o verify token que a Meta usa para validar o webhook. Padrão é `"evolution"` — **troque por um token seguro**:

```bash
openssl rand -hex 24
```

### Endpoint do webhook

`https://webhook.oesteodontologia.com.br/webhook/meta`

### Cloudflare Tunnel — Subdomínio dedicado

O webhook da Meta **não funciona com Cloudflare Access (2FA)** — a Meta não consegue passar pela autenticação. Solução:

1. Criar subdomínio separado `webhook.oesteodontologia.com.br` **sem Cloudflare Access**
2. **IMPORTANTE:** O Cloudflare Tunnel no servidor OVH é **gerenciado remotamente** (Cloudflare Zero Trust dashboard), não pelo `/etc/cloudflared/config.yml`. Editar o arquivo local NÃO funciona.
3. Adicionar a rota no painel: **Cloudflare Zero Trust → Networks → Tunnels → [seu tunnel] → Public Hostnames → Add**:
   - Subdomain: `webhook`
   - Domain: `oesteodontologia.com.br`
   - Type: HTTP
   - URL: `localhost:80`
4. Adicionar `webhook.oesteodontologia.com.br` ao `server_name` no nginx:

```nginx
server_name evolution.oesteodontologia.com.br webhook.oesteodontologia.com.br;
```

Recarregar: `docker exec oeste-odontologia-nginx nginx -s reload`

### Configuração no Meta Developer Dashboard

1. Acessar `https://developers.facebook.com` → App → WhatsApp → Configuration
2. Callback URL: `https://webhook.oesteodontologia.com.br/webhook/meta`
3. Verify token: o mesmo de `WA_BUSINESS_TOKEN_WEBHOOK`
4. Assinar eventos: `messages`, `message_template_status_update`

### Criar instância no Evolution

1. Integration: `WHATSAPP-BUSINESS`
2. Token: token de acesso permanente da Meta

---

## Meta Cloud API — Limitações

- **NÃO suporta grupos** — apenas conversas 1:1 (business ↔ cliente)
- Para capturar mensagens de grupos, use instância `WHATSAPP-BAILEYS` (Baileys)
- Risco de ban: ZERO na Meta Cloud API (oficial). Existe no Baileys (não-oficial)

---

## Pitfalls

1. **Nginx DNS cache:** Recriar container evolution-api → restartar nginx
2. **Cloudflare Tunnel remoto:** Editar `/etc/cloudflared/config.yml` é inútil — usar painel Zero Trust
3. **Cloudflare Access bloqueia webhook:** Meta não passa por 2FA — usar subdomínio sem Access
4. **Licença vinculada ao instance_id:** Resetar banco → nova licença necessária
5. **Versão `homolog` bugada:** FK constraint `Setting_instanceId_fkey` — usar `2.4.0-rc2`
6. **Meta Cloud API rate limit:** 1000 conversas/mês gratuitas, depois ~R$0,25-0,50/conversa

---

## Teste de verificação

```bash
# Testar webhook localmente
curl -s "http://127.0.0.1:80/webhook/meta?hub.mode=subscribe&hub.verify_token=SEU_TOKEN&hub.challenge=TEST123" \
  -H "Host: webhook.oesteodontologia.com.br"

# Deve retornar: TEST123 (HTTP 200)

# Testar via internet
curl -s "https://webhook.oesteodontologia.com.br/webhook/meta?hub.mode=subscribe&hub.verify_token=SEU_TOKEN&hub.challenge=TEST123"
```

---

## :red_circle: Meta Cloud API nativa NÃO funciona (mesmo na rc2)

A v2.4.0-rc2 **cria** instâncias WhatsApp Business com sucesso, mas **não processa mensagens recebidas**:

```
TypeError: Cannot read properties of undefined (reading '0')
at Gs.connectToWhatsapp (/evolution/dist/main.js:300:17776)
```

O webhook da Meta chega (HTTP 200) mas a Evolution quebra ao tentar processar a mensagem.

**Solução definitiva:** Usar um webhook receiver FastAPI próprio que substitui completamente a Evolution para Meta Cloud API. Ver skill `meta-webhook-receiver-setup`.

A Evolution continua útil apenas para instâncias **Baileys** (WhatsApp Web não-oficial), como o número pessoal `{{COMMANDER}}` que alimenta o blog do pycode-cerebro.

## Configuração de Instâncias Baileys na v2.4.0-rc2

### Privacidade e Notificações

Após recriar uma instância Baileys, configurar:

| Setting | Valor | Manager UI (v2.4.x) | API field |
|---------|-------|---------------------|-----------|
| Não marcar como lida | `false` | **Read Messages** | `readMessages` |
| Não suprimir notificações | `false` | **Read Status** ← era "Mark Messages Read" | `readStatus` |
| Não sincronizar histórico | `false` | Sync Full History | `syncFullHistory` |
| Webhook | `http://172.18.0.1:8001/webhook` | — | eventos: `MESSAGES_UPSERT` |

**⚠️ Renomeação na v2.4.x:** O antigo "Mark Messages Read" agora se chama **"Read Status"** no Manager UI. O campo na API é `readStatus`.

### Persistência — docker-compose.yml (global)

```yaml
- DATABASE_SAVE_DATA_INSTANCE=true
- DATABASE_SAVE_DATA_NEW_MESSAGE=false    # não armazenar mensagens
- DATABASE_SAVE_MESSAGE_UPDATE=false
- DATABASE_SAVE_DATA_CONTACTS=false
- DATABASE_SAVE_DATA_CHATS=false
```

### Webhook para Host (Docker bridge)

URL do webhook: `http://172.18.0.1:8001/webhook`
O gateway `172.18.0.1` é o IP do host visto de dentro da rede Docker bridge. **NUNCA usar `localhost`**.

---

## Verificação pós-upgrade

```bash
# Status da API
curl -s -H "Host: evolution.oesteodontologia.com.br" http://127.0.0.1:80/

# Listar instâncias
curl -s -H "apikey: API_KEY" -H "Host: evolution.oesteodontologia.com.br" \
  http://127.0.0.1:80/instance/fetchInstances

# Estado da conexão
curl -s -H "apikey: API_KEY" -H "Host: evolution.oesteodontologia.com.br" \
  http://127.0.0.1:80/instance/connectionState/NOME_INSTANCIA
```
