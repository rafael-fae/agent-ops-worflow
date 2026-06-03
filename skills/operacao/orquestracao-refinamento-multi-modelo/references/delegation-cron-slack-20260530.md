# Cron de Delegação Slack — Padrão Comprovado

**Validado:** 30/05/2026 — {{PROJECT_NAME}} (Dontus Clone)
**Gatilho:** {{COMMANDER}} ordena "agendar no cron para delegar para a equipe às HH:MM"

## Quando usar

- O projeto tem múltiplos agentes que precisam ser acionados em um horário específico
- O orquestrador não estará disponível no horário exato para enviar as menções
- O trabalho preparatório (reescrita, build) já foi concluído ou será concluído antes do horário
- A delegação depende de verificação de estado dos arquivos no disco

## Estrutura do Cron

O cron job tem 3 fases:

### Fase 1 — Verificação de Estado

Antes de delegar, o cron verifica o estado real dos arquivos:

```bash
echo "=== GAPS REESCRITOS ==="
for f in K3 G02 G06 K1 K2 G03 G05 G11; do
  echo "--- $f ---"
  wc -l {{PROJECT_PATH}}/docs/refinamentos/REESCRITA-OPUS-$f.md 2>/dev/null || echo "ARQUIVO NÃO ENCONTRADO"
  stat -f '%Sm' {{PROJECT_PATH}}/docs/refinamentos/REESCRITA-OPUS-$f.md 2>/dev/null
done
```

### Fase 2 — Produzir Mensagem de Delegação

Com base na verificação, produzir UMA mensagem formatada com menções reais do Slack. A mensagem é a resposta final do cron, que o sistema entrega no canal.

**Regras absolutas para menções:**
- Usar SEMPRE `<@USER_ID>` nu, sem backticks, sem formatação
- Mapa oficial:
  - {{BACKEND_ENGINEER}}: `<@{{SLACK_ID_BACKEND}}>`
  - {{AUDITOR}}: `<@{{SLACK_ID_AUDITOR}}>`
  - {{DEVOPS_ENGINEER}}: `<@{{SLACK_ID_DEVOPS}}>`
  - {{FRONTEND_ENGINEER}}: `<@{{SLACK_ID_FRONTEND}}>`
  - {{ORCHESTRATOR}}: `<@{{SLACK_ID_ORCHESTRATOR}}>`

**Template de mensagem:**

```
⚔️ [FASE] — [NOME DA OPERAÇÃO] ⚔️

[Contexto de 1-2 linhas sobre o estado atual]

══════════════════════
<@USER_ID> — [PAPEL]
══════════════════════
Documentos: [paths reais verificados na Fase 1]

Missão:
1. [Tarefa específica 1]
2. [Tarefa específica 2]
3. [Tarefa específica 3]

Modelo: [qual CLI usar]
Arquivos em: [diretório real]
Entregável: [path do arquivo de saída esperado]

[Repetir para cada agente]

══════════════════════
PRAZO: HH:MM (Xh de execução)
══════════════════════
Ordem de prioridade:
1. [Agente A] ([tipo] — [justificativa]) — [tempo]
2. [Agente B] + [Agente C] (paralelo) — [tempo]
3. [Agente D] ([dependência]) — [tempo]

Eu ({{ORCHESTRATOR}}) consolidarei os relatórios às HH:MM e reportarei ao {{COMMANDER}}.

— {{ORCHESTRATOR}}, Orquestrador
```

### Fase 3 — Entrega

A resposta final do cron DEVE ser exatamente a mensagem formatada. O sistema a entrega no canal configurado (`deliver: origin`).

## Configuração do Cron

```python
cronjob(
    action='create',
    name='Delegação Equipe M4 — Cross-Validação 13h',
    schedule='2026-05-30T17:00:00Z',  # UTC = local+4 para GMT-4
    deliver='origin',
    skills=['cli-tools-agent-setup', 'orquestracao-refinamento-multi-modelo'],
    workdir='/Users/{{COMMANDER}}fae/Dev/{{PROJECT_SLUG}}',
    prompt='...'  # prompt completo com as 3 fases
)
```

## Cálculo de Horário

O fuso de {{COMMANDER}} é GMT-4 (Campo Grande/MS). Para converter horário local → UTC:

```bash
# Ex: 13:00 local → UTC
date -u -v+4H -v+13H -v+0M '+%Y-%m-%dT%H:%M:%SZ'
# Resultado: 2026-05-30T17:00:00Z
```

Ou simplesmente: `horário_local + 4 = UTC`.

## Pitfalls

1. **Cron não interage com Slack em tempo real.** O job roda em sessão isolada — a ÚNICA coisa que chega ao canal é a resposta final. Não adianta tentar "mencionar e esperar resposta" dentro do prompt do cron.

2. **Menções com backticks quebram.** `` `<@USER_ID>` `` vira texto literal. Usar sempre `<@USER_ID>` nu.

3. **Verificação de estado é obrigatória.** Se o cron das 07:50 falhou e o das 13:00 delega tarefas baseadas em arquivos que não existem, os agentes vão reportar "arquivo não encontrado" e perder tempo.

4. **Ajustar delegação conforme estado real.** Se G05 ainda tem 156 linhas (Gemini), a delegação para {{AUDITOR}} deve incluir "G05 precisa de revisão mais profunda — versão Gemini é superficial". Se já tem 800 linhas (Opus), a delegação muda para "validar completude".

5. **Um cron por horário de delegação.** Não tente encadear múltiplas delegações no mesmo cron — cada uma merece seu próprio job com verificação de estado fresca.

6. **Crons de uma sessão não sobrevivem ao reset.** Se a sessão do Hermes for reiniciada, os crons são perdidos. Após um reset, liste os crons (`cronjob(action='list')`) e recrie os necessários.

## Exemplo Real

Cron `31ab4567370b` — Delegação Equipe M4 às 13:00 (30/05/2026):
- Verificou 8 gaps reescritos + Design System
- Produziu mensagem com delegações para {{BACKEND_ENGINEER}} (arquitetura), {{AUDITOR}} (auditoria), {{DEVOPS_ENGINEER}} (código), {{FRONTEND_ENGINEER}} (UI)
- Prazo: 17:00 (4h de execução)
- Entregue via `deliver: origin` no canal {{SLACK_CHANNEL_OVH}}
