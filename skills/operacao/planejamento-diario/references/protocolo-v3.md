# Protocolo de Delegação v3 (01/06/2026)

## CRIAR tasks ≠ DELEGAR tasks

| Ação | O que é | Quem faz | Quando |
|---|---|---|---|
| **CRIAR** | Escrever arquivo `task_XX.md` no disco | {{ORCHESTRATOR}} | A qualquer momento, sob demanda do {{COMMANDER}} |
| **DELEGAR** | Enviar mensagem no Slack mencionando agente | {{ORCHESTRATOR}} | Só após autorização explícita do {{COMMANDER}} |

## Regras de delegação

1. Máximo **1 task delegada por vez**
2. Múltiplas tasks só se {{COMMANDER}} autorizar explicitamente
3. Cada task = **UMA thread** no Slack. Nunca criar múltiplas threads para a mesma task
4. Toda mensagem de delegação deve conter: menção do agente, motor, prioridade, instruções, link pro checklist
5. Após task concluída e auditada, só delegar a próxima após ordem do {{COMMANDER}}

## Motor padrão

- **Gemini CLI**: `gemini -m "gemini-3.1-pro-preview"` — SEMPRE o padrão
- **DeepSeek V4 Pro**: só com autorização explícita do {{COMMANDER}}. Nunca como fallback automático
- **Opus 4.7**: apenas para análise profunda, quando houver limites

## Canais

- Equipe Mac: `{{SLACK_CHANNEL_TEAM}}`
- Cross-team (Mac ↔ OVH): `{{SLACK_CHANNEL_WAR_ROOM}}`
- **NUNCA** usar `{{SLACK_CHANNEL_OVH}}` (é da Sociedade do Anel)

## Thread única

Todas as mensagens sobre uma task (delegação, atualização, sinal verde, dúvidas, conclusão, auditoria) devem ficar na MESMA thread. Nunca enviar uma nova mensagem no canal que inicie uma thread separada.

## Sinal verde

Nenhum agente inicia execução sem sinal verde do {{COMMANDER}} (via {{ORCHESTRATOR}}). A mensagem de delegação NÃO é autorização automática.

Evoluído através de múltiplos testes e correções durante a sessão.

## :red_circle: REGRA MÁXIMA

**NUNCA implementar código sem autorização explícita do Comandante {{COMMANDER}}.**
Fase atual: planejamento. Código só com "sinal verde".

## Fluxo de Comunicação

1. **{{ORCHESTRATOR}} inicia tópico** no canal com menção ao(s) agente(s)
2. **Agente responde NA MESMA THREAD** — nunca em thread separada, nunca no canal
3. **Toda resposta começa com `<@{{SLACK_ID_ORCHESTRATOR}}>` ({{ORCHESTRATOR}})** — corrente NUNCA se quebra
4. **Só {{ORCHESTRATOR}} posta no canal** — agentes respondem apenas em threads

## Regra ANTI-DELEGAÇÃO

- APENAS {{ORCHESTRATOR}} delega tarefas
- Agentes mencionam outros apenas para INFORMAÇÕES
- Pedidos de ajuda → mencionar {{ORCHESTRATOR}}, NUNCA outro agente

## Preenchimento de Tasks

1. Executar → 2. Marcar checkboxes → 3. Preencher Conclusão → 4. Reportar no Slack

## Casos Reais

| Data | Violação | Correção |
|------|----------|----------|
| 31/05 | {{BACKEND_ENGINEER}} sem `<@{{ORCHESTRATOR}}>` | Toda resposta começa com menção |
| 31/05 | {{BACKEND_ENGINEER}} executou código | Regra máxima reforçada |
| 31/05 | {{BACKEND_ENGINEER}} postou no canal | Só threads |
| 31/05 | {{DEVOPS_ENGINEER}} delegou p/ {{FRONTEND_ENGINEER}} | Anti-delegação |
| 31/05 | {{FRONTEND_ENGINEER}} sem checklist | Preenchimento obrigatório |
