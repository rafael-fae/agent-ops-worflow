# WhatsApp — Número vs JID

## Regra de Ouro

**NUNCA assuma que o número de telefone informado é igual ao JID do WhatsApp.**

O JID (Jabber ID) é o identificador interno do WhatsApp no formato `CCDDNNNNNNNN@s.whatsapp.net`.
O número de telefone informado pelo usuário pode ter dígitos extras ou faltantes,
especialmente com o 9º dígito no Brasil.

## Caso documentado (30/05/2026)

| Fonte | Valor |
|---|---|
| Número informado pelo Comandante | `67999623440` |
| JID real no WhatsApp | `556799623440@s.whatsapp.net` |
| Número correto derivado do JID | `556799623440` → `+55 67 99623-3440` |

**Diferença:** O número informado tinha um `9` extra (`99623` vs `99962`).
Mensagens enviadas para `5567999623440` NUNCA chegaram ao destinatário.

## Como Obter o JID Real

### Via Evolution API (se instância estiver conectada)
```bash
# Verificar chats recentes no banco
sudo docker exec evolution-postgres psql -U evolution_user -d evolution -c \
  "SELECT \"remoteJid\", name FROM evolution_api.\"Chat\" ORDER BY created_at DESC LIMIT 10;"
```

### Via Webhook Receiver
```javascript
// Adicionar log temporário no broker
if remote_jid != GRUPO_ID and remote_jid != COMANDANTE_ID:
    print(f"JID_DESCONHECIDO: {remote_jid} — {nome}: {texto}")
    # Salvar em arquivo para análise
```

### Via Manager UI
- Acesse a aba "Chats" no Evolution Manager
- O JID aparece abaixo do nome do contato

## Formato de Envio via Evolution API

```bash
# CORRETO — número sem @s.whatsapp.net
curl -X POST "http://127.0.0.1:80/message/sendText/INSTANCE" \
  -H "apikey: KEY" \
  -H "Content-Type: application/json" \
  -d '{"number":"556799623440","text":"Mensagem"}'

# ERRADO — com sufixo JID
curl ... -d '{"number":"556799623440@s.whatsapp.net","text":"..."}'
```

O endpoint `sendText` da Evolution API aceita apenas o número puro (sem `@s.whatsapp.net`).

## Formato de Envio via Hermes Bridge

O bridge Baileys do Hermes **requer o JID completo** com sufixo:
```json
{"chatId": "556799623440@s.whatsapp.net", "message": "Texto"}
```

## Estrutura de um JID WhatsApp

```
CCDDNNNNNNNN@s.whatsapp.net  → usuário
CCDDNNNNNNNN-XXXXXXXX@g.us   → grupo
status@broadcast              → status/stories
```

- `CC`: código do país (55 = Brasil)
- `DD`: código de área/DDD (67 = MS)
- `NNNNNNNNN`: número do telefone (8-9 dígitos no Brasil)
