# Bridge Modes — Lógica de Filtro

A bridge Baileys suporta dois modos: `self-chat` (default) e `bot`.

## Modo `bot` — DMs Externas (Produção)

Fluxo de filtro para cada mensagem recebida:

```
Mensagem recebida
├─ fromMe (eco da própria resposta)?
│   ├─ Grupo ou status? → IGNORAR
│   └─ DM? → IGNORAR (eco — evita loop infinito)
│
└─ !fromMe (mensagem de outra pessoa)?
    ├─ É grupo E chatId == grupo autorizado? → PROCESSAR
    ├─ É DM E senderId está na allowlist? → PROCESSAR
    └─ Senão → IGNORAR (log: allowlist_mismatch)
```

**Nota:** Mensagens de grupo passam pelo filtro de grupo (`group_allow_from`), não pelo allowlist individual.

### Exemplo de log (bot mode, allowlist OK):
```
🌉 WhatsApp bridge listening on port 3000 (mode: bot)
🔒 Allowed users: 556799623440
✅ WhatsApp connected!
```

### Exemplo de rejeição (bot mode, remetente não autorizado):
```json
{"event":"ignored","reason":"allowlist_mismatch","chatId":"...","senderId":"..."}
```

## Modo `self-chat` — Self-Messaging (Teste)

SÓ processa mensagens que você envia para SI MESMO (WhatsApp "Message Yourself").

```
Mensagem recebida
├─ fromMe?
│   ├─ Grupo ou status? → IGNORAR
│   └─ chatId == meu próprio número (self-chat)? → PROCESSAR
│       └─ Senão → IGNORAR
│
└─ !fromMe?
    └─ QUALQUER mensagem → IGNORAR (log: self_chat_mode_rejects_non_self)
```

### Exemplo de rejeição (self-chat mode):
```json
{"event":"ignored","reason":"self_chat_mode_rejects_non_self","chatId":"134604409290999@lid","senderId":"134604409290999@lid"}
{"event":"ignored","reason":"self_chat_mode_rejects_non_self","chatId":"120363425868389123@g.us","senderId":"195906410422485@lid"}
```

**:red_circle: Toda DM externa é rejeitada silenciosamente no modo `self-chat`.** Se o Comandante precisa enviar DMs para o agente, usar `bot`.
