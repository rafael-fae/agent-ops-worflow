<!--
==============================================================================
  PLANO.md.tpl — Template Genérico de Plano Diário
  ============================================================================
  Este é um template para o plano de execução diária de qualquer equipe que
  utilize o fluxo de trabalho multiagente. Copie para planejamento-diario/__DATA__/PLANO.md
  e preencha os tokens __PLACEHOLDER__.

  Como usar:
    1. Copie este arquivo para planejamento-diario/__DATA__/PLANO.md
    2. Substitua todos os __PLACEHOLDERS__ pelos valores da sua equipe
    3. Ajuste as ondas conforme necessário (Manhã/Tarde/Noite)
    4. Preencha a tabela de tarefas no início de cada onda

  Sobre os placeholders:
    __PLACEHOLDER__ = texto que você DEVE substituir (sublinhado duplo)
    <!-- comentário  = instrução didática explicando a seção
    (exemplo)       = ilustração de como preencher, remover ou adaptar
==============================================================================
-->

# Plano de Execução — __NOME_DO_PROJETO__

<!--
  Cabeçalho editável: preencha data, equipe e comandante.
  O comandante é a pessoa (ou agente orquestrador) que define o plano do dia.
-->
**Criado por:** __COMANDANTE__ / __TIME__
**Data:** __DATA__ (formato: DD/MM/YYYY)
**Propósito:** __PROPOSITO_DO_DIA__ (ex.: "Finalizar sprint atual", "Corrigir bugs críticos", "Preparar release")
**Fluxo de trabalho:** Este plano SEGUE o fluxo de planejamento diário documentado no repositório.

---

<!-- =====================================================================
  SEÇÃO: RECURSOS DO PROJETO
  Liste aqui todos os recursos que sua equipe consultará durante o dia.
  Preencha a tabela com o que for relevante ao projeto.
  Deixe vazio e preencha no início do dia — exemplos abaixo são ilustrativos.
===================================================================== -->
## 📚 RECURSOS DO PROJETO

| Recurso | Localização | Propósito |
|---------|-------------|-----------|
<!--
  Exemplos (remova ou adapte):
  | Repositório principal     | github.com/sua-equipe/seu-projeto  | Código fonte |
  | Documentação da API       | docs.seuprojeto.com/api             | Referência técnica |
  | Quadro de tarefas         | link-para-o-seu-quadro              | Acompanhamento de issues |
  | Ambiente de staging       | https://staging.seuprojeto.com      | Teste e validação |
  | Pipeline CI/CD            | link-para-sua-ci                    | Deploys e builds |
-->
| __RECURSO_1__ | __LOCAL_1__ | __PROPOSITO_1__ |
| __RECURSO_2__ | __LOCAL_2__ | __PROPOSITO_2__ |
| __RECURSO_3__ | __LOCAL_3__ | __PROPOSITO_3__ |

---

<!-- =====================================================================
  SEÇÃO: SUMÁRIO
  Descreva em 2-3 frases o objetivo macro do dia.
  Exemplo: "Hoje vamos finalizar a integração com o gateway de pagamento
  e corrigir os 3 bugs identificados na última auditoria."
===================================================================== -->
## Sumário

__RESUMO_DO_DIA__

Descreva aqui, em termos gerais, o que precisa ser entregue até o fim do dia.
Quais problemas serão resolvidos? Quais funcionalidades serão implementadas?
Qual é o critério de sucesso?

---

<!-- =====================================================================
  SEÇÃO: ONDAS
  As ondas dividem o dia em blocos de execução. O padrão mais comum é:
    Onda 1 — Manhã
    Onda 2 — Tarde
    Onda 3 — Noite
  Cada onda tem um conjunto de tarefas com prioridade, agente e status.

  Você pode renomear as ondas ou usar menos/mais — o importante é agrupar
  tarefas por turno ou fase lógica.

  Como preencher:
    1. Copie o bloco abaixo para cada onda que você precisar
    2. Ajuste o nome (ex.: "Onda 1 — Manhã 🔴 ✅" se já concluída)
    3. Preencha a tabela de tarefas

  Status: ✅ concluída | 🔴 em andamento | ⬜ pendente
===================================================================== -->

## Ondas

### Onda 1 — __NOME_DA_WAVE_1__ (__TURNO_1__) 🔴

<!--
  Exemplo de onda:
  ### Onda 1 — Setup e Planejamento (Manhã) 🔴 ✅
-->

| Tarefa | Descrição | Agente | Motor | Prioridade | Status |
|:------:|-----------|:------:|:-----:|:----------:|:------:|
<!--
  Exemplo de linha (adapte):
  | task_01 | Configurar ambiente de desenvolvimento     | Agente Alpha  | Gemini CLI  | 🔴 | ✅ |
  | task_02 | Revisar requisitos da sprint               | Agente Beta   | Claude Code | 🟡 | ⬜ |
  | task_03 | Corrigir bug crítico no login              | Agente Gamma  | OpenAI API  | 🔴 | 🔴 |
-->
| __TASK_ID_1__ | __DESCRICAO_1__ | __AGENTE_1__ | __MOTOR_1__ | __PRIORIDADE_1__ | __STATUS_1__ |
| __TASK_ID_2__ | __DESCRICAO_2__ | __AGENTE_2__ | __MOTOR_2__ | __PRIORIDADE_2__ | __STATUS_2__ |

**Objetivo:** __OBJETIVO_DA_WAVE_1__

---

### Onda 2 — __NOME_DA_WAVE_2__ (__TURNO_2__) 🟡

| Tarefa | Descrição | Agente | Motor | Prioridade | Status |
|:------:|-----------|:------:|:-----:|:----------:|:------:|
| __TASK_ID_3__ | __DESCRICAO_3__ | __AGENTE_3__ | __MOTOR_3__ | __PRIORIDADE_3__ | __STATUS_3__ |
| __TASK_ID_4__ | __DESCRICAO_4__ | __AGENTE_4__ | __MOTOR_4__ | __PRIORIDADE_4__ | __STATUS_4__ |

**Objetivo:** __OBJETIVO_DA_WAVE_2__

---

### Onda 3 — __NOME_DA_WAVE_3__ (__TURNO_3__) 🟢

| Tarefa | Descrição | Agente | Motor | Prioridade | Status |
|:------:|-----------|:------:|:-----:|:----------:|:------:|
| __TASK_ID_5__ | __DESCRICAO_5__ | __AGENTE_5__ | __MOTOR_5__ | __PRIORIDADE_5__ | __STATUS_5__ |
| __TASK_ID_6__ | __DESCRICAO_6__ | __AGENTE_6__ | __MOTOR_6__ | __PRIORIDADE_6__ | __STATUS_6__ |

**Objetivo:** __OBJETIVO_DA_WAVE_3__

---

<!-- =====================================================================
  SEÇÃO: DEPENDÊNCIAS
  Diagrama ASCII mostrando quais tarefas dependem de quais.
  Use setas (→) para indicar fluxo.
  Tarefas paralelas ficam no mesmo nível; tarefas sequenciais em níveis diferentes.
===================================================================== -->
## Dependências

```

<!--
  Exemplo de diagrama de dependências:
  Onda 1 (Setup)
    task_01 (infra) + task_02 (config) — paralelas

  Onda 2 (Desenvolvimento)
    task_03 (backend) depende de task_01
    task_04 (frontend) depende de task_02
    task_05 (testes) depende de task_03, task_04

  Onda 3 (Finalização)
    task_06 (deploy) depende de task_05
-->

__DIAGRAMA_DE_DEPENDENCIAS__

```

---

<!-- =====================================================================
  SEÇÃO: REGRAS DE EXECUÇÃO
  Regras inegociáveis que a equipe deve seguir.
  Personalize conforme acordado pela equipe.
===================================================================== -->
## ⚠️ REGRAS DE EXECUÇÃO

1. **Motor padrão:** __MOTOR_PADRAO__ (ex.: "Gemini CLI" ou "Claude Code" ou "OpenAI API")
2. **NUNCA modifique arquivos originais** — sempre trabalhe em cópias ou branches
3. **Repositório:** Somente conteúdo sanitizado/genérico — __ARQUIVOS_IGNORADOS__ NÃO são enviados
4. **Independência:** Este projeto é autocontido. Não depende de recursos externos não documentados
5. **Didática:** Todo arquivo DEVE ser comentado e explicado — outras pessoas vão lê-lo
6. **Idioma:** Documentação em __IDIOMA__ (ex.: pt-BR, en-US)
7. **Commit semântico:** Commits descritivos no idioma escolhido
8. **Threads:** Máximo de __MAX_THREADS__ agentes simultâneos
9. **Auditoria:** Toda tarefa concluída DEVE ser auditada por outro agente antes de fechar

---

<!-- =====================================================================
  SEÇÃO: CHECKLIST DO FINAL DO DIA
  Marque os itens ao encerrar o dia de trabalho.
===================================================================== -->
## Final do Dia

- [ ] __TOTAL_TASKS__/__TOTAL_TASKS__ tarefas concluídas e auditadas
- [ ] INDICE.md atualizado com o status do dia
- [ ] Todos os commits feitos e enviados
- [ ] Itens pendentes documentados para o próximo dia
- [ ] Checklist de segurança verificado (se aplicável)
- [ ] Link do plano compartilhado com a equipe (se houver um canal)

---

<!-- =====================================================================
  SEÇÃO: MÉTRICAS-ALVO
  Defina as metas do dia — pode ser número de tarefas, cobertura de testes,
  deploys, etc.
===================================================================== -->
## Métricas-Alvo

| Métrica | Meta | Realizado |
|---------|:----:|:---------:|
| Tarefas concluídas | __META_TASKS__ | __REALIZADO_TASKS__ |
| __METRICA_EXTRA_1__ | __META_EXTRA_1__ | __REALIZADO_EXTRA_1__ |
| __METRICA_EXTRA_2__ | __META_EXTRA_2__ | __REALIZADO_EXTRA_2__ |
