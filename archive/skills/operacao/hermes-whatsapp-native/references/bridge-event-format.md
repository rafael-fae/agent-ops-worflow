# Bridge Event Format — Schema do JSON

Cada mensagem recebida pela bridge é enfileirada (e opcionalmente webhook-POSTada) como um objeto JSON com este schema:

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
  "timestamp": 1780191647393
}
```

## Campos-chave para o broker

| Campo | Descrição | Uso no broker |
|-------|-----------|---------------|
| `chatId` | JID do chat. Grupo: `1203...@g.us`, DM: `5567...@s.whatsapp.net`, LID: `1346...@lid` | Filtrar por grupo vs DM |
| `isGroup` | `true` se for grupo | Decidir destino (hoje.md vs inbox.md) |
| `senderId` | JID de quem enviou | Identificar Comandante (sem `@s.whatsapp.net`) |
| `senderName` | Nome de exibição no WhatsApp | Formatar linha: `[timestamp] Nome: texto` |
| `body` | Texto da mensagem (pode ser `""` se for mídia sem caption) | Conteúdo a salvar |
| `hasMedia` | `true` se contém imagem/vídeo/áudio/documento | Pular ou processar mídia |
| `timestamp` | Unix timestamp (ms) | Ordenação |

## Exemplo — mensagem de grupo

```json
{
  "messageId": "BAE5...",
  "chatId": "120363425868389123@g.us",
  "senderId": "556799623440@s.whatsapp.net",
  "senderName": "{{COMMANDER}} Faé",
  "chatName": "120363425868389123",
  "isGroup": true,
  "body": "@204445426163895 teste",
  "hasMedia": false,
  "mediaType": "",
  "mediaUrls": [],
  "mentionedIds": ["204445426163895@s.whatsapp.net"],
  "quotedMessageId": null,
  "quotedParticipant": null,
  "quotedRemoteJid": null,
  "hasQuotedMessage": false,
  "botIds": [],
  "timestamp": 1780191647
}
```

## Exemplo — DM do Comandante

```json
{
  "messageId": "3EB0...",
  "chatId": "556799623440@s.whatsapp.net",
  "senderId": "556799623440@s.whatsapp.net",
  "senderName": "{{COMMANDER}} Faé",
  "chatName": "{{COMMANDER}} Faé",
  "isGroup": false,
  "body": "Olá Aragorn, tudo bem?",
  "hasMedia": false,
  "mediaType": "",
  "mediaUrls": [],
  "mentionedIds": [],
  "timestamp": 1780191650
}
```

## Nota sobre LID vs JID

O WhatsApp pode entregar mensagens com remetente em formato LID (`134604409290999@lid`) em vez de JID (`556799623440@s.whatsapp.net`). A bridge mantém mappings no `session_path` (`lid-mapping-*.json`). Para compatibilidade, normalizar o senderId removendo o sufixo (`@s.whatsapp.net` ou `@lid`) e comparar apenas os dígitos.
