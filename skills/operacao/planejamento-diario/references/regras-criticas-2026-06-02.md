# Regras Críticas — 02/06/2026

5 rulings de {{COMMANDER}} nesta sessão. Consolidado para consulta rápida.

## 1. PLANEJAR ≠ DELEGAR (interpretação literal)

| Verbo | Significado | Ação |
|-------|-------------|------|
| "planeje" / "crie" (tasks) | Criar `.md` + atualizar índices | write_file + patch INDICE/PLANO |
| "solte" / "delegue" / "pode soltar" | Enviar no Slack | send_message com `<@USER_ID>` |

**Caso real:** {{COMMANDER}} disse "planeje mais 2 tasks pra shallan". {{ORCHESTRATOR}} criou os .md E delegou no Slack. Correção: apagar as mensagens (só após autorização).

## 2. Gemini SEMPRE. DeepSeek proibido sem ordem.

Hierarquia absoluta:
1. **Gemini 3.1 Pro** — padrão. SEMPRE.
2. **Opus 4.7** — exclusivo {{FRONTEND_ENGINEER}} para DS, quando disponível.
3. **DeepSeek V4 Pro** — NUNCA sem ordem explícita do {{COMMANDER}}.

Task_XX.md NÃO é autoridade sobre motor. Se disser "DeepSeek", sobrescrever para Gemini.

**Caso real:** Task_16.md dizia DeepSeek V4 Pro. {{ORCHESTRATOR}} delegou com DeepSeek. {{COMMANDER}}: *"a ordem é sempre gemini 3.1 pro como primeira opção"*.

## 3. AÇÃO CORRETIVA NUNCA SEM AUTORIZAÇÃO

Se {{ORCHESTRATOR}} errar → reportar erro → AGUARDAR ordens. NUNCA:
- Apagar mensagens do Slack
- Reverter commits
- Corrigir canal/motor por conta própria
- Tomar qualquer ação corretiva unilateral

**Caso real:** {{ORCHESTRATOR}} delegou tasks sem autorização, depois apagou as mensagens. {{COMMANDER}} estava trabalhando na resposta. As tasks já estavam em execução. {{COMMANDER}}: *"você excluiu elas sem eu autorizar e os agentes continuam trabalhando na task"*.

## 4. INDICE.md + PLANO.md: atualização IMEDIATA

Após cada task concluída e auditada:
- INDICE.md: commit hash, ✅👁, atualizar contador
- PLANO.md: status ⬜ → ✅
- NUNCA deixar ⬜ em task concluída

## 5. UMA THREAD POR TASK

Toda comunicação sobre uma task (delegação, correções, conclusão) na MESMA thread original. Proibido abrir nova thread para reportar situação da mesma task. Isso vale para {{ORCHESTRATOR_UPPER}} e para todos os agentes.
