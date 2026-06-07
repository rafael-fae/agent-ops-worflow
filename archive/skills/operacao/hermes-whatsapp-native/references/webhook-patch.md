# Webhook Patch para bridge.js

Adiciona suporte a `WHATSAPP_WEBHOOK_URL` na bridge Baileys do Hermes.
Isso permite que um broker externo (ex: porta 8001 → `hoje.md`) receba cópias
das mensagens enquanto o gateway Hermes consome via `/messages`.

## Motivo

O endpoint `/messages` da bridge usa `splice()` — é uma fila de consumidor único.
Gateway e broker não podem consumir simultaneamente. O webhook resolve isso:
cada mensagem é POSTada para o broker E enfileirada para o gateway.

## Patch (2 alterações)

### 1. Adicionar variável (após SEND_TIMEOUT_MS)

```diff
 const SEND_TIMEOUT_MS = parseInt(process.env.WHATSAPP_SEND_TIMEOUT_MS || '60000', 10);
+const WHATSAPP_WEBHOOK_URL = process.env.WHATSAPP_WEBHOOK_URL || null;
```

### 2. Adicionar POST (após o bloco messageQueue)

```diff
       messageQueue.push(event);
       if (messageQueue.length > MAX_QUEUE_SIZE) {
         messageQueue.shift();
       }
+
+      // Webhook forward: POST to broker for side effects (e.g. grupo -> hoje.md)
+      if (WHATSAPP_WEBHOOK_URL) {
+        const webhookPayload = JSON.stringify(event);
+        fetch(WHATSAPP_WEBHOOK_URL, {
+          method: 'POST',
+          headers: { 'Content-Type': 'application/json' },
+          body: webhookPayload,
+        }).catch(function() {}); // fire-and-forget
+      }
```

## Configuração no systemd

```ini
Environment="WHATSAPP_WEBHOOK_URL=http://127.0.0.1:8001/webhook"
```

## Formato do evento

```json
{
  "messageId": "3EB0...",
  "chatId": "120363425868389123@g.us",
  "senderId": "556799623440@s.whatsapp.net",
  "senderName": "{{COMMANDER}} Faé",
  "chatName": "IA Master Elite",
  "isGroup": true,
  "body": "texto da mensagem",
  "hasMedia": false,
  "mediaType": "",
  "mediaUrls": [],
  "mentionedIds": [],
  "quotedMessageId": null,
  "quotedParticipant": null,
  "quotedRemoteJid": null,
  "hasQuotedMessage": false,
  "botIds": [],
  "timestamp": 1234567890
}
```
