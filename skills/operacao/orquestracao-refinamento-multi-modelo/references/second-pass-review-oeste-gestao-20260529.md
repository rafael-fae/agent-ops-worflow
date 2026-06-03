# Exemplo Real: Second-Pass Comprehensive Review — {{PROJECT_NAME}} (2026-05-29)

## Contexto
Após a conclusão dos 4 deep-dives com Opus (Modo 2), {{COMMANDER}} solicitou duas ações paralelas:
1. {{BACKEND_ENGINEER}}-mac revisar tecnicamente os 4 deep-dives e validar a arquitetura
2. {{AUDITOR}}-mac fazer uma revisão completa de TODO o planejamento com Claude Opus para encontrar lacunas que os deep-dives iniciais podem ter deixado passar

Este foi o padrão **Modo 3** — a segunda passagem de revisão.

## Estado Antes

Os seguintes documentos já existiam em `{{PROJECT_PATH}}/docs/`:
- `PLANO-IMPLEMENTACAO.md` (3.491 linhas)
- `ARCHITECTURAL-BLUEPRINT-v3.1-FINAL.md` (547 linhas)
- `RELATORIO-FINAL-WAVE6.md` (181 linhas)
- `DEEP-DIVE-VAZAMENTO-MULTI-TENANT.md` (646 linhas)
- `DEEP-DIVE-GARGALO-WAVE3.md` (401 linhas)
- `DEEP-DIVE-SESSION-IDOR.md` (725 linhas)
- `DEEP-DIVE-EVENT-BUS-ASYNC.md` (907 linhas)
- `refinamentos/SEC-1-2-ESTRATEGIA-REFINADO.md` (545 linhas)
- `refinamentos/SUMMARY-POS-OPUS.md` (65 linhas — compilação dos 4 deep-dives)

## Delegações Enviadas

Enviadas no Slack `<#{{SLACK_CHANNEL_TEAM_ID}}>` (canal Mac):

**{{BACKEND_ENGINEER}}-mac** (`<@{{SLACK_ID_BACKEND}}>`): Revisar os 4 deep-dives + blueprint + plano
- Validar soluções propostas
- Verificar coerência com a arquitetura
- Reportar ✅/⚠️/❌

**{{AUDITOR}}-mac** (`<@{{SLACK_ID_AUDITOR}}>`): Revisão completa com Claude Opus
- Alimentar Opus com todo o material
- Buscar gaps NÃO mapeados
- Reportar lacunas priorizadas

## Ferramentas Confirmadas

- **Claude CLI**: v2.1.118 em `~/.local/bin/claude` — modelo Opus disponível via `--model opus`
- **Gemini API**: modelos `gemini-3.1-pro-preview` e `gemini-3.1-flash-preview` via API HTTP direta (não CLI)
- **OpenCode Go**: Provider `opencode-go` configurado nos Hermes configs com base URL `https://opencode.ai/zen/go/v1`

## Resultados (29/05/2026, ~10:00 BRT)

### Trilha A — {{BACKEND_ENGINEER}}-mac (Arquitetura)
- **Status:** ✅ Concluído
- Todos os 4 deep-dives aprovados com observações:
  - DD#1 Vazamento MT: ✅ — `contextvars` correto, mas stub `resolve_tenant_from_request` não implementado
  - DD#2 Session IDOR: ✅ — `X-Clinic-ID` aprovado, mas `ClinicScopeManager.get_queryset()` não escopa automaticamente
  - DD#3 Event Bus: ✅ — `on_commit()` + Celery exemplar
  - DD#4 Gargalo W3: ✅ — wave 3A/3B aprovada
- 7 gaps residuais identificados (GAP-01 a GAP-07)
- Artefato: `VALIDACAO-{{BACKEND_ENGINEER_UPPER}}-4DEEP-DIVES.md` (217 linhas)

### Trilha B — {{AUDITOR}}-mac (Qualidade/Produto)
- **Status:** ✅ Concluído (com fallback — Opus em rate limit)
- 14 gaps NÃO mapeados descobertos (G01–G14)
- 3 críticos (Sala/Cadeira, RBAC, Migração), 4 altos, 4 médios, 3 baixos
- Modelo usado: Gemini 3.1 Pro (Opus rate-limitado, DeepSeek não necessário)
- Análise cruzada com 4 gaps já conhecidos de {{DEVOPS_ENGINEER}} → 18 gaps totais

### Decisões de {{COMMANDER}} Durante a Sessão
- **G01 (Sala/Cadeira):** Descartado — manter agendamento por profissional
- **Hierarquia de modelos:** Opus → Gemini 3.1 Pro → DeepSeek v4 Pro (regra máxima)
- **G02 (RBAC) e G03 (Migração):** Pendentes de decisão

### Problemas de Infra
- **{{GIT_OPS}}-mac:** 3 reinícios, estado limpo, `auth.test` OK — mas zero eventos. Diagnosticado como Event Stream Morto (Sintoma C2). Requer verificação no dashboard Slack.
- **{{DEVOPS_ENGINEER}}-mac:** Zumbi clássico (16h parado) — corrigido com kill + restart

## Lições Operacionais

1. **Separar papéis é crítico:** {{BACKEND_ENGINEER}} (arquitetura técnica) e {{AUDITOR}} (produto/completude) revisam de ângulos diferentes — não centralizar
2. **SUMMARY-POS-OPUS.md já gerado** — o orquestrador não precisa refazer o que já foi feito; apenas apontar o que já existe e delegar a revisão
3. **Opus já rodou uma vez** (4 deep-dives); a segunda passagem é mais ampla e precisa de budget maior
4. **Ferramentas disponíveis ao time M4** — verificar antes de delegar tarefas que exigem CLIs específicos
5. **Evidência bruta obrigatória no reporting:** Quando um agente executa Claude Opus, o report deve incluir path do arquivo, tamanho, linhas, timestamp, e amostra do conteúdo. {{COMMANDER}} NÃO aceita "task concluída" sem mostrar a saída do modelo. (29/05/2026 — {{COMMANDER}} questionou se o Opus foi realmente executado porque o report inicial não continha evidência da saída bruta.)
6. **Verificação pré-delegação de gateways:** Antes de delegar tarefas de execução, confirmar que o agente alvo está realmente online (gateway_state.updated recente, inbound messages recentes). {{DEVOPS_ENGINEER}}-mac e {{AUDITOR}}-mac estavam zumbis em momentos diferentes — custou ~40 min de retrabalho cada.
