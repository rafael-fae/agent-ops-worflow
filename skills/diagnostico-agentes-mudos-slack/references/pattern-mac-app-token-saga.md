# {{GIT_OPS}}-mac Recovery — Linha do Tempo (29/05/2026)

## Cronologia

| Hora | Ação | Resultado |
|------|------|-----------|
| 09:44 | Convocação M4 — {{GIT_OPS}}-mac não responde | Gateway rodando (PID 28739), `state: running, slack: connected`, `updated: 09:18` |
| 09:44 | Diagnóstico inicial | `auth.test` OK (`user_id: {{SLACK_ID_GITOPS}}`), `bot_user_id` correto, MEMORY.md limpo. Última inbound: 08:41 (1h antes) |
| 09:44 | Kill + restart → PID 31129 | `Bolt app is running!`, mas zero inbound mensagens |
| 09:48 | Kill + limpeza state.db + sessions + restart → PID 31500 | `Bolt app is running!`, SESSÃO NOVA, mas zero inbound |
| 10:01 | limpeza state.db + sessions + restart → PID 31500 (relançado) | Mesmo resultado: conectado, Bolt OK, zero inbound |
| 10:01 | Encontrado `terminal.cwd: /Users/{{COMMANDER}}fae/projects/obsidian` (path inexistente) + path OVH nas instructions | **Não era a causa** — corrigido mas não resolveu |
| 10:09 | **ERRO CRÍTICO NO ERR.LOG**: `apps.connections.open → invalid_auth` | DIAGNÓSTICO DEFINITIVO: app_token (xapp-) inválido |
| 10:18 | {{COMMANDER}} renova tokens e reinstala app | Tokens novos, auth.test passa |
| 10:19 | Kill + restart → PID 32632 | **AINDA** apps.connections.open → invalid_auth (app_token velho?) |
| 10:24 | {{COMMANDER}} gera **NOVO APP TOKEN** (xapp-) | `err.log`: erro `invalid_auth` desaparece! |
| 10:25 | Restart → PID 32816 | `Bolt app running!` — primeiro sinal de vida real |
| 10:26 | {{COMMANDER}} testa em #roshar-sync: `<@{{SLACK_ID_GITOPS}}>` | **RESPONDE!** {{GIT_OPS}}-mac operacional |
| 10:27 | Gateway recebe thread context de #operacao | Confirmação: WebSocket entrega eventos de ambos canais |

## Lições

1. **`auth.test` NÃO valida app_token (xapp-)** — só valida bot_token (xoxb-)
2. **`apps.connections.open` → `invalid_auth`** é o erro definitivo de app_token inválido
3. **Reinstalar app NÃO renova app_token** — precisa gerar manualmente no dashboard
4. **Após correção, testar em canal DIFERENTE do problemático** — {{COMMANDER}} testou #roshar-sync e confirmou
5. **7 tentativas de restart** até diagnóstico correto — 3 delas desnecessárias (estado limpo não resolve app_token)

## Comando de verificação rápida

```bash
# Se auth.test OK + Bolt OK + zero inbound → verificar app_token
grep "invalid_auth" ~/.hermes/profiles/<agente>/logs/err.log
# Se aparecer "apps.connections.open → invalid_auth":
# → Regenerar SLACK_APP_TOKEN no dashboard Slack
# → Atualizar .env
# → Kill + restart gateway
```
