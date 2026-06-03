<!--
==============================================================================
  PLANO.md.tpl — Template Genérico de Plano Diário
  ============================================================================
  Este é um template para o plano de execução diário de qualquer equipe que
  usa o workflow multi-agente. Copie para planejamento-diario/__DATA__/PLANO.md
  e preencha os placeholders __ASSIM__.

  Como usar:
    1. Copie este arquivo para planejamento-diario/__DATA__/PLANO.md
    2. Substitua todos os __PLACEHOLDERS__ pelos valores do seu time
    3. Ajuste as waves conforme sua realidade (Manhã/Tarde/Noite)
    4. Preencha a tabela de tasks no início de cada wave

  Sobre os placeholders:
    __PLACEHOLDER__ = texto que você DEVE substituir (duplo underscore)
    <!-- comentário = instrução didática explicando a seção
    (exemplo)       = ilustração de como preencher, remova ou adapte
==============================================================================
-->

# Plano de Execução — __NOME_DO_PROJETO__

<!--
  Cabeçalho editável: preencha data, time e comandante.
  O comandante é a pessoa (ou agente orquestrador) que define o plano do dia.
-->
**Criado por:** __COMANDANTE__ / __TIME__
**Data:** __DATA__ (formato: DD/MM/AAAA)
**Propósito:** __PROPOSITO_DO_DIA__ (ex: "Finalizar sprint atual", "Corrigir bugs críticos", "Preparar release")
**Workflow:** Este plano SEGUE o workflow de planejamento diário documentado no repositório.

---

<!-- =====================================================================
  SEÇÃO: RECURSOS DO PROJETO
  Liste aqui todos os recursos que sua equipe vai consultar durante o dia.
  Preencha a tabela com o que for relevante para o projeto.
  Deixe vazia e preencha no início do dia — os exemplos abaixo são ilustrativos.
===================================================================== -->
## 📚 RECURSOS DO PROJETO

| Recurso | Local | Propósito |
|---------|-------|-----------|
<!--
  Exemplos (remova ou adapte):
  | Repositório principal | github.com/seu-time/seu-projeto | Código fonte |
  | Documentação da API  | docs.seuprojeto.com/api         | Referência técnica |
  | Quadro de tarefas    | link-do-seu-board               | Acompanhamento de issues |
  | Ambiente de staging  | https://staging.seuprojeto.com   | Testes e validação |
  | Pipeline CI/CD       | link-do-seu-ci                   | Deploys e builds |
-->
| __RECURSO_1__ | __LOCAL_1__ | __PROPOSITO_1__ |
| __RECURSO_2__ | __LOCAL_2__ | __PROPOSITO_2__ |
| __RECURSO_3__ | __LOCAL_3__ | __PROPOSITO_3__ |

---

<!-- =====================================================================
  SEÇÃO: RESUMO
  Descreva em 2-3 frases o objetivo macro do dia.
  Exemplo: "Hoje vamos finalizar a integração com o gateway de pagamento
  e corrigir os 3 bugs apontados na última auditoria."
===================================================================== -->
## Resumo

__RESUMO_DO_DIA__

Descreva aqui, em linhas gerais, o que precisa ser entregue ao final do dia.
Que problemas serão resolvidos? Que funcionalidades serão implementadas?
Qual o critério de sucesso?

---

<!-- =====================================================================
  SEÇÃO: WAVES
  As waves dividem o dia em blocos de execução. O padrão mais comum é:
    Wave 1 — Manhã
    Wave 2 — Tarde
    Wave 3 — Noite
  Cada wave tem um conjunto de tasks com prioridade, agente e status.

  Você pode renomear as waves ou usar menos/mais — o importante é agrupar
  tasks por turno ou por fase lógica.

  Como preencher:
    1. Copie o bloco abaixo para cada wave que você precisar
    2. Ajuste o nome (ex: "Wave 1 — Manhã 🔴 ✅" se já concluída)
    3. Preencha a tabela de tasks

  Status: ✅ concluída | 🔴 em execução | ⬜ pendente
===================================================================== -->

## Waves

### Wave 1 — __NOME_DA_WAVE_1__ (__TURNO_1__) 🔴

<!--
  Exemplo de wave:
  ### Wave 1 — Setup e Planejamento (Manhã) 🔴 ✅
-->

| Task | Descrição | Agente | Motor | Prioridade | Status |
|:----:|-----------|:------:|:-----:|:----------:|:------:|
<!--
  Exemplo de linha (adaptar):
  | task_01 | Configurar ambiente de desenvolvimento | Agente Alpha | Gemini CLI | 🔴 | ✅ |
  | task_02 | Revisar requisitos do sprint | Agente Beta | Claude Code | 🟡 | ⬜ |
  | task_03 | Corrigir bug crítico no login | Agente Gamma | OpenAI API | 🔴 | 🔴 |
-->
| __TASK_ID_1__ | __DESCRICAO_1__ | __AGENTE_1__ | __MOTOR_1__ | __PRIORIDADE_1__ | __STATUS_1__ |
| __TASK_ID_2__ | __DESCRICAO_2__ | __AGENTE_2__ | __MOTOR_2__ | __PRIORIDADE_2__ | __STATUS_2__ |

**Objetivo:** __OBJETIVO_DA_WAVE_1__

---

### Wave 2 — __NOME_DA_WAVE_2__ (__TURNO_2__) 🟡

| Task | Descrição | Agente | Motor | Prioridade | Status |
|:----:|-----------|:------:|:-----:|:----------:|:------:|
| __TASK_ID_3__ | __DESCRICAO_3__ | __AGENTE_3__ | __MOTOR_3__ | __PRIORIDADE_3__ | __STATUS_3__ |
| __TASK_ID_4__ | __DESCRICAO_4__ | __AGENTE_4__ | __MOTOR_4__ | __PRIORIDADE_4__ | __STATUS_4__ |

**Objetivo:** __OBJETIVO_DA_WAVE_2__

---

### Wave 3 — __NOME_DA_WAVE_3__ (__TURNO_3__) 🟢

| Task | Descrição | Agente | Motor | Prioridade | Status |
|:----:|-----------|:------:|:-----:|:----------:|:------:|
| __TASK_ID_5__ | __DESCRICAO_5__ | __AGENTE_5__ | __MOTOR_5__ | __PRIORIDADE_5__ | __STATUS_5__ |
| __TASK_ID_6__ | __DESCRICAO_6__ | __AGENTE_6__ | __MOTOR_6__ | __PRIORIDADE_6__ | __STATUS_6__ |

**Objetivo:** __OBJETIVO_DA_WAVE_3__

---

<!-- =====================================================================
  SEÇÃO: DEPENDÊNCIAS
  Diagrama ASCII mostrando quais tasks dependem de quais.
  Use setas (→) para indicar fluxo.
  Tasks paralelas ficam no mesmo nível; tasks sequenciais em níveis diferentes.
===================================================================== -->
## Dependências

```

<!--
  Exemplo de diagrama de dependências:
  Wave 1 (Setup)
    task_01 (infra) + task_02 (config) — paralelo

  Wave 2 (Desenvolvimento)
    task_03 (backend) depende de task_01
    task_04 (frontend) depende de task_02
    task_05 (testes) depende de task_03, task_04

  Wave 3 (Finalização)
    task_06 (deploy) depende de task_05
-->

__DIAGRAMA_DE_DEPENDENCIAS__

```

---

<!-- =====================================================================
  SEÇÃO: REGRAS DA EXECUÇÃO
  Regras inegociáveis que a equipe deve seguir.
  Personalize conforme o combinado pelo time.
===================================================================== -->
## ⚠️ REGRAS DA EXECUÇÃO

1. **Motor padrão:** __MOTOR_PADRAO__ (ex: "Gemini CLI" ou "Claude Code" ou "OpenAI API")
2. **NUNCA modificar arquivos originais** — trabalhe sempre em cópias ou branches
3. **Repositório:** Commitar apenas o que for sanitizado/genérico — __ARQUIVOS_IGNORADOS__ NÃO sobem
4. **Independência:** Este projeto é auto-contido. Não depende de recursos externos não documentados
5. **Didático:** Cada arquivo DEVE ser comentado e explicado — outras pessoas vão ler
6. **Idioma:** Documentação em __IDIOMA__ (ex: pt-BR, en-US)
7. **Commit semântico:** Commits descritivos no idioma escolhido
8. **Threads:** Máximo de __MAX_THREADS__ agentes simultâneos
9. **Auditoria:** Toda task concluída DEVE ser auditada por outro agente antes de fechar

---

<!-- =====================================================================
  SEÇÃO: CHECKLIST DE FINAL DE DIA
  Marque os itens ao encerrar o dia de trabalho.
===================================================================== -->
## Ao final do dia

- [ ] __TOTAL_TASKS__/__TOTAL_TASKS__ tasks concluídas e auditadas
- [ ] INDICE.md atualizado com status do dia
- [ ] Todos os commits feitos e push realizado
- [ ] Pendências documentadas para o próximo dia
- [ ] Checklist de segurança verificado (se aplicável)
- [ ] Link do plano compartilhado com a equipe (se houver canal)

---

<!-- =====================================================================
  SEÇÃO: MÉTRICAS-ALVO
  Defina as metas do dia — pode ser número de tasks, cobertura de testes,
  deploys, etc.
===================================================================== -->
## Métricas-alvo

| Métrica | Meta | Realizado |
|---------|:----:|:---------:|
| Tasks concluídas | __META_TASKS__ | __REALIZADO_TASKS__ |
| __METRICA_EXTRA_1__ | __META_EXTRA_1__ | __REALIZADO_EXTRA_1__ |
| __METRICA_EXTRA_2__ | __META_EXTRA_2__ | __REALIZADO_EXTRA_2__ |
