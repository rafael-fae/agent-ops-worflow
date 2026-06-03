<!--
==============================================================================
  INDICE.md.tpl — Template Genérico de Índice de Planejamento
  ============================================================================
  Este é o template para o índice geral do planejamento diário.
  Copie para planejamento-diario/INDICE.md e preencha.

  O índice é a VITRINE do progresso da equipe. Ele mostra:
    - O que foi planejado vs. realizado
    - O status de cada task (concluída, auditada, pendente)
    - O progresso por wave
    - Os commits associados a cada entrega

  Como usar:
    1. Copie este template para planejamento-diario/INDICE.md
    2. A cada novo dia, adicione uma seção "## DD/MM/AAAA — X/Y"
    3. Preencha a tabela com as tasks do dia
    4. Atualize a seção de progresso por wave
    5. Mantenha a legenda no topo

  Atualização diária:
    - Ao começar o dia: adicione a seção da data com tasks pendentes
    - Ao concluir uma task: mude ⬜ para ✅ e adicione o hash do commit
    - Após auditoria: mude 👁 ⬜ para 👁 ✅
    - Ao final do dia: atualize o contador X/Y e a seção de progresso
==============================================================================
-->

# Índice de Planejamento — __NOME_DO_PROJETO__

<!--
  Legenda: explica os símbolos usados nas tabelas.
  ✅ = task concluída (execução finalizada)
  👁 = task auditada (revisão cruzada feita por outro agente)
  ⬜ = pendente (não iniciado ou não concluído)
-->
> **Propósito:** Este índice documenta o planejamento e progresso do projeto
> __NOME_DO_PROJETO__ — um sistema de planejamento diário multi-agente.
>
> **Legenda:** ✅ = concluído | 👁 = auditado | ⬜ = pendente
>
> **Meta:** Este arquivo é o TERMÔMETRO do workflow — ele mostra a saúde da execução.

---

<!-- =====================================================================
  SEÇÃO DO DIA
  A cada dia de trabalho, adicione um bloco como este abaixo.

  Formato do cabeçalho:
    ## DD/MM/AAAA — TASKS_CONCLUIDAS/TOTAL_TASKS

  Exemplo:
    ## 03/06/2026 — 2/10

  A tabela tem 6 colunas:
    Task      | Nome do arquivo (link)
    Descrição | Resumo do que a task faz
    Wave      | Número da wave
    ✅        | Concluída? (✅ ou ⬜)
    👁        | Auditada? (✅ ou ⬜)
    Commit    | Hash do commit (ou "—" se não commitado)

  IMPORTANTE: O contador no título DEVE refletir a soma real de ✅ na coluna.
  Ao final do dia, o contador deve bater com o total de tasks concluídas.
===================================================================== -->

## __DATA__ — __TASKS_CONCLUIDAS__/__TOTAL_TASKS__

| Task | Descrição | Wave | ✅ | 👁 | Commit |
|------|-----------|:----:|---|---|--------|
<!--
  Exemplo de linha (preencher para cada task):
  | task_01 | Configurar ambiente de desenvolvimento | 1 | ✅ | ⬜ | a1b2c3d |
  | task_02 | Revisar requisitos | 1 | ✅ | ✅ | e4f5g6h |
  | task_03 | Corrigir bug crítico | 2 | ⬜ | ⬜ | — |
-->
| __TASK_1__ | __DESCRICAO_1__ | __WAVE_1__ | __STATUS_1__ | __AUDIT_1__ | __COMMIT_1__ |
| __TASK_2__ | __DESCRICAO_2__ | __WAVE_2__ | __STATUS_2__ | __AUDIT_2__ | __COMMIT_2__ |
| __TASK_3__ | __DESCRICAO_3__ | __WAVE_3__ | __STATUS_3__ | __AUDIT_3__ | __COMMIT_3__ |
| __TASK_4__ | __DESCRICAO_4__ | __WAVE_4__ | __STATUS_4__ | __AUDIT_4__ | __COMMIT_4__ |
| __TASK_5__ | __DESCRICAO_5__ | __WAVE_5__ | __STATUS_5__ | __AUDIT_5__ | __COMMIT_5__ |
| __TASK_6__ | __DESCRICAO_6__ | __WAVE_6__ | __STATUS_6__ | __AUDIT_6__ | __COMMIT_6__ |
| __TASK_7__ | __DESCRICAO_7__ | __WAVE_7__ | __STATUS_7__ | __AUDIT_7__ | __COMMIT_7__ |
| __TASK_8__ | __DESCRICAO_8__ | __WAVE_8__ | __STATUS_8__ | __AUDIT_8__ | __COMMIT_8__ |
| __TASK_9__ | __DESCRICAO_9__ | __WAVE_9__ | __STATUS_9__ | __AUDIT_9__ | __COMMIT_9__ |
| __TASK_10__ | __DESCRICAO_10__ | __WAVE_10__ | __STATUS_10__ | __AUDIT_10__ | __COMMIT_10__ |

_Adicione ou remova linhas conforme o número de tasks do dia._

---

<!-- =====================================================================
  SEÇÃO: PROGRESSO POR WAVE
  Resumo visual do progresso consolidado de todas as waves do projeto.
  A tabela mostra:
    - Nome da wave
    - Total de tasks na wave
    - Quantas concluídas
    - Status visual (barra de progresso)

  Formato da barra: "X/Y" onde X é concluídas e Y é total.
  Exemplo: "3/5" ou "✅ 3/5" se wave concluída.

  OPCIONAL: você pode adicionar uma linha de Total ao final.
===================================================================== -->

## Progresso

| Wave | Tasks | Status |
|:----:|:-----:|:------:|
<!--
  Exemplo:
  | 1 — Setup | 2 | ✅ 2/2 |
  | 2 — Desenvolvimento | 3 | ⬜ 1/3 |
  | 3 — Testes | 3 | ⬜ 0/3 |
  | 4 — Deploy | 2 | ⬜ 0/2 |
  | **Total** | **10** | **3/10** |
-->
| 1 — __NOME_WAVE_1__ | __TOTAL_WAVE_1__ | __STATUS_WAVE_1__ |
| 2 — __NOME_WAVE_2__ | __TOTAL_WAVE_2__ | __STATUS_WAVE_2__ |
| 3 — __NOME_WAVE_3__ | __TOTAL_WAVE_3__ | __STATUS_WAVE_3__ |
| 4 — __NOME_WAVE_4__ | __TOTAL_WAVE_4__ | __STATUS_WAVE_4__ |
| **Total** | **__TOTAL_GERAL__** | **__STATUS_GERAL__** |

---

<!-- =====================================================================
  SEÇÃO: INSTRUÇÕES DE ATUALIZAÇÃO
  Mantenha estas instruções no final do arquivo para referência rápida.
  Qualquer pessoa da equipe deve ser capaz de atualizar o índice.
===================================================================== -->

## Como atualizar este índice

1. **Adicionar novo dia:** copie o bloco da seção "## __DATA__" e ajuste
2. **Marcar task concluída:** troque ⬜ por ✅ na coluna ✅ e adicione o hash do commit
3. **Marcar task auditada:** troque ⬜ por ✅ na coluna 👁
4. **Atualizar contador do cabeçalho:** conte quantos ✅ existem na coluna ✅ e atualize __TASKS_CONCLUIDAS__/__TOTAL_TASKS__
5. **Atualizar progresso por wave:** atualize os status de cada wave na seção "Progresso"
6. **Commite as alterações:** `git add -A && git commit -m "índice: atualiza progresso do dia __DATA__" && git push`

### Lembrete

> O índice SÓ é útil se estiver atualizado. Reserve 2 minutos ao final de cada
> wave para refletir o progresso real. Não acumule atualizações — elas
> tendem a nunca acontecer.
