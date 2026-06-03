# Regras Maximas Institudas por {{COMMANDER}} em 02/06/2026

Estas 5 decisoes foram tomadas por {{COMMANDER}} apos erros ocorridos durante a sessao. Servem como jurisprudencia da equipe {{TEAM_NAME}}.

---

## Regra 1: PLANEJAR ≠ DELEGAR

**Contexto:** {{COMMANDER}} disse "planeje mais 2 tasks pra shallan". {{ORCHESTRATOR}} criou os arquivos E delegou no Slack.

**Consequencia:** {{FRONTEND_ENGINEER}} comecou a trabalhar nas tasks 19 e 20 sem autorizacao. {{COMMANDER}} teve que mandar "pare".

**Ruling:** "Planeje" = criar arquivos .md + indices. "Solte/delegue" = enviar no Slack. Interpretacao literal.

---

## Regra 2: Gemini SEMPRE, DeepSeek PROIBIDO

**Contexto:** Task_16.md dizia "Motor: DeepSeek V4 Pro". {{ORCHESTRATOR}} delegou com DeepSeek.

**Ruling:** Gemini 3.1 Pro e o motor padrao absoluto. Nao existe "DeepSeek autorizado" em task_XX.md. O arquivo define O QUE fazer, nao QUAL motor usar. Sobrescrever sempre para Gemini.

---

## Regra 3: ACAO CORRETIVA NUNCA SEM AUTORIZACAO

**Contexto:** Apos delegar tasks 19 e 20 sem autorizacao, {{ORCHESTRATOR}} apagou as mensagens do Slack por conta propria.

**Ruling:** Se errar: reportar o erro e AGUARDAR. Nunca desfazer, apagar, reverter. Acao corretiva so com ordem explicita de {{COMMANDER}}.

---

## Regra 4: RECURSOS DONTUS EM TODA DELEGACAO

**Contexto:** {{ORCHESTRATOR}} esqueceu de incluir Dontus nas delegacoes das tasks 16, 17 e 21.

**Ruling:** Antes de delegar QUALQUER task, avaliar se o agente precisa consultar o Dontus. Incluir credenciais, o que consultar, proibicao de modificar dados.

---

## Regra 5: INDICE E PLANO — ATUALIZACAO IMEDIATA

**Contexto:** Tasks 12 e 13 concluidas e auditadas, mas INDICE e PLANO ficaram com ⬜.

**Ruling:** Apos CADA task auditada, atualizar IMEDIATAMENTE. ⬜ mantido = falha grave. Commit hash e 👁 obrigatorios.
