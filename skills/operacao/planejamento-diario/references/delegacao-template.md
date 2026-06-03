# Template de Mensagem de Delegação no Slack

## Regras

1. **Menção no INÍCIO** da primeira linha
2. **NUNCA usar tabelas markdown** na mesma mensagem da menção (quebra parser)
3. **Cada task = UMA thread** — primeira mensagem ABRE a thread, todas as outras RESPONDEM
4. **Motor EXPLÍCITO** com bloco ORDEM ABSOLUTA
5. **Hash do commit** é obrigatório no relatório final

## Template

```
<@USER_ID> task_XX — TÍTULO

Prioridade: [CRÍTICO/ALTO/MÉDIO/BAIXO] | Motor: [CLI] | Wave: [Manhã/Tarde/Noite]

[1-2 linhas de contexto]

ORDEM ABSOLUTA: Motor EXCLUSIVAMENTE [CLI]. Comando: [exato]. NÃO usar outro. Se falhar, PARAR e reportar.

1. git checkout develop && git pull
2. [CLI] obrigatório
3. COMMITAR + PUSH — confirmar hash

Checklist: planejamento-diario/YYYY-MM-DD/task_XX.md
Recursos: [PRD §X, Blueprint §Y, Dontus, etc.]
Responder nesta thread mencionando <@{{SLACK_ID_ORCHESTRATOR}}>
```

## Exemplo Preenchido

```
<@{{SLACK_ID_DEVOPS}}> task_07 — SP1-17: Decorator @require_permissions

Prioridade: CRÍTICO | Motor: Gemini 3.1 Pro CLI | Wave: Tarde

Implementar decorator de permissões + validador de escopo clínica. G02: 55% → 70%.

ORDEM ABSOLUTA: Motor EXCLUSIVAMENTE Gemini CLI. Comando: gemini -m "gemini-3.1-pro-preview". NÃO usar DeepSeek. Se Gemini falhar, PARAR e reportar.

1. git checkout develop
2. Gemini CLI obrigatório
3. COMMITAR + PUSH — confirmar hash

Checklist: planejamento-diario/2026-06-02/task_07.md
Recursos: PRD §2.2, Blueprint §6, apps/core/models.py
Responder nesta thread mencionando <@{{SLACK_ID_ORCHESTRATOR}}>
```

## Anti-Padrões

- ❌ "Motor: Gemini 3.1 Pro" sem ORDEM ABSOLUTA → agente ignora e usa DeepSeek
- ❌ "Responder mencionando @{{ORCHESTRATOR}}" — usar SEMPRE `<@{{SLACK_ID_ORCHESTRATOR}}>`, nunca texto puro
- ❌ Múltiplas mensagens de delegação para a mesma task → cria threads separadas
- ❌ Delegar múltiplas tasks simultaneamente sem autorização do {{COMMANDER}}
- ❌ Tabelas markdown na mesma mensagem da menção → quebra parser Slack
