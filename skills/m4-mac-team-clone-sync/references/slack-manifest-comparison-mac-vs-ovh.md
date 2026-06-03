# Slack Manifest Comparison — Mac (M4) vs OVH

Comparação dos manifests dos bots {{ORCHESTRATOR}} nos dois ambientes (28/05/2026).

## Diferenças Chave

| Aspecto | Mac (dalinar-mac) | OVH (dalinar) |
|---------|-------------------|---------------|
| Display name | `{{ORCHESTRATOR}}-mac` | `{{ORCHESTRATOR}}` |
| Description | `General e Orquestrador — Equipe M4` | (vazio) |
| Background color | `#1A1A2E` | (vazio / default) |
| always_online | `true` | `false` |

## Scopes — Mac tem mais

**Exclusivos do Mac (não estão no OVH):**
- `channels:join` — entrar em canais automaticamente
- `channels:write` — escrever em canais públicos
- `reactions:read` — ler reações
- `reactions:write` — adicionar reações
- `users:write` — gerenciar usuários
- `team:read` — ler informações do time

**Exclusivos do OVH (não estão no Mac):**
- `chat:write.public` — escrever em canais sem ser membro
- `users:read.email` — ler email dos usuários

**Compartilhados (ambos têm):**
- `app_mentions:read`, `channels:history`, `channels:read`
- `chat:write`, `files:read`, `files:write`
- `groups:history`, `groups:read`, `groups:write`
- `im:history`, `im:read`, `im:write`
- `users:read`

## Bot Events

| Evento | Mac | OVH |
|--------|:---:|:---:|
| `app_mention` | ✅ | ✅ |
| `message.channels` | ✅ | ✅ |
| `message.groups` | ✅ | ❌ |
| `message.im` | ✅ | ✅ |

O Mac escuta `message.groups` (canais privados/grupos) — o OVH não.

## Recomendação para Novos Bots

Usar o manifest do Mac como template base — ele é mais completo. Adicionar `chat:write.public` e `users:read.email` do OVH se o bot precisar postar em canais sem ser membro ou ler emails.
