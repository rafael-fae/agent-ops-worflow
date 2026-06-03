<!--
==============================================================================
  README-WORKFLOW.md.tpl — README da Pasta de Planejamento Diário
  ============================================================================
  Este arquivo serve como README da pasta `planejamento-diario/` do seu
  projeto. Copie para planejamento-diario/README.md e adapte.

  O propósito deste README é explicar a QUALQUER UM que entre na pasta
  o que é, como funciona e como participar do fluxo de trabalho diário.

  Como usar:
    1. Copie este template para planejamento-diario/README.md
    2. Substitua __PLACEHOLDERS__ pelos dados da sua equipe
    3. Adapte os exemplos conforme necessário
    4. Mantenha o tom didático — recém-chegados precisam entender rápido
==============================================================================
-->

# 📋 Planejamento Diário — __NOME_DO_TIME__

> **Esta pasta é o CORAÇÃO do nosso fluxo de planejamento diário.**
> Aqui documentamos o que fizemos, o que estamos fazendo e o que faremos.

---

<!-- =====================================================================
  SEÇÃO: O QUE É
  Explica o propósito da pasta em linguagem simples.
===================================================================== -->
## O que é esta pasta?

A pasta `planejamento-diario/` é o sistema nervoso central da nossa
operação multiagente. Ela contém:

- **`INDICE.md`** — O painel de controle. Mostra o progresso geral, dia a dia,
  com status de cada tarefa (concluída, auditada, pendente).

- **`__DATA__/`** — Pastas com data (ex.: `2026-06-03/`) contendo o plano
  e as tarefas de cada dia:
  - `PLANO.md` — O plano de execução do dia: ondas, tarefas, dependências
  - `task_01.md`, `task_02.md`, ... — Tarefas individuais com instruções detalhadas

O fluxo de trabalho é simples:
1. **Planejar** — Crie o PLANO.md do dia com ondas e tarefas
2. **Executar** — Cada agente pega uma tarefa e a executa
3. **Registrar** — Atualize o status no INDICE.md
4. **Auditar** — Outro agente revisa a tarefa concluída
5. **Repetir** — No dia seguinte, comece novamente

---

<!-- =====================================================================
  SEÇÃO: ESTRUTURA DE PASTAS
  Mostra a árvore de diretórios para consulta rápida.
===================================================================== -->
## Estrutura

```
planejamento-diario/
├── README.md              ← Este arquivo (instruções de uso)
├── INDICE.md              ← Índice geral com progresso
├── __DATA_1__/            ← Ex.: 2026-06-03/
│   ├── PLANO.md           ← Plano do dia
│   ├── task_01.md         ← Tarefa individual
│   ├── task_02.md
│   └── ...
└── __DATA_2__/            ← Ex.: 2026-06-04/
    ├── PLANO.md
    └── ...
```

---

<!-- =====================================================================
  SEÇÃO: CICLO DIÁRIO
  Explica passo a passo como usar o fluxo de trabalho no dia a dia.
===================================================================== -->
## Uso diário

### 🌅 Início do dia (Comandante / Orquestrador)

1. **Leia o INDICE.md** — veja o que ficou pendente do dia anterior
2. **Crie a pasta do dia:** `mkdir -p planejamento-diario/$(date +%Y-%m-%d)`
3. **Copie o template PLANO.md.tpl** para a pasta e preencha:
   - Data, equipe, propósito do dia
   - Ondas (Manhã/Tarde/Noite — quantas fizerem sentido)
   - Tarefas com descrição, agente, motor, prioridade
   - Diagrama de dependências
4. **Copie os templates TASK.md.tpl** para cada tarefa do plano
5. **Atualize o INDICE.md** com as tarefas do novo dia

### 🏃 Durante o dia (Agentes)

1. **Escolha uma tarefa** — selecione uma tarefa pendente do INDICE.md
2. **Leia a tarefa** — entenda o contexto, as instruções e as restrições
3. **Execute** — siga as instruções passo a passo
4. **Marque o checklist** — assinale os itens conforme forem concluídos
5. **Preencha a Conclusão** — documente o que foi feito
6. **Atualize o INDICE.md** — marque ✅ e adicione o hash do commit
7. **Notifique o auditor** — a tarefa precisa ser revisada

### ✅ Final do dia (Comandante / Orquestrador)

1. **Verifique o progresso** — quantas tarefas foram concluídas?
2. **Audite tarefas pendentes** — 👁 deve se tornar ✅
3. **Atualize o contador** no cabeçalho do INDICE.md
4. **Atualize a seção de Progresso** por onda
5. **Commite e envie**:
   ```bash
   git add -A
   git commit -m "planejamento: atualiza dia __DATA__"
   git push
   ```
6. **Documente itens pendentes** para o próximo dia no INDICE.md

---

<!-- =====================================================================
  SEÇÃO: CONVENÇÕES
  Regras de nomenclatura e formatação para manter a consistência.
===================================================================== -->
## Convenções

### Nomenclatura

| Item | Formato | Exemplo |
|------|---------|---------|
| Pasta de data | `YYYY-MM-DD` | `2026-06-03/` |
| Plano do dia | `PLANO.md` | `2026-06-03/PLANO.md` |
| Tarefa individual | `task_NN.md` | `task_01.md` |
| Índice geral | `INDICE.md` | `INDICE.md` |

### Símbolos de status

| Símbolo | Significado |
|:-------:|------------|
| ✅ | Tarefa concluída |
| 👁 | Tarefa auditada (revisada por outro agente) |
| ⬜ | Pendente (não iniciada) |
| 🔴 | Prioridade alta |
| 🟡 | Prioridade média |
| 🟢 | Prioridade baixa |

### Prioridades

- **🔴 Alta:** Bloqueante. Impede outras tarefas. Deve ser feita primeiro.
- **🟡 Média:** Importante mas não bloqueia outras tarefas.
- **🟢 Baixa:** Melhoria, refinamento, dívida técnica.

---

<!-- =====================================================================
  SEÇÃO: REFERÊNCIA
  Links para documentação completa e exemplos.
===================================================================== -->
## Referência

- **Documentação completa do fluxo:** __URL_DOCS__ (ex.: https://docs.suaequipe.com/workflow)
- **Repositório do projeto:** __URL_REPO__ (ex.: github.com/sua-equipe/seu-projeto)
- **Templates disponíveis em:** `templates/` (PLANO.md.tpl, TASK.md.tpl, INDICE.md.tpl)
- **Canal da equipe:** __CANAL_DO_TIME__ (ex.: #canal-da-equipe no Slack)
- **Comandante atual:** __COMANDANTE__

---

<!-- =====================================================================
  SEÇÃO: EXEMPLO RÁPIDO
  Um mini-tutorial para quem quiser começar imediatamente.
===================================================================== -->
## Exemplo rápido

```bash
# 1. Crie a pasta do dia
mkdir -p planejamento-diario/$(date +%Y-%m-%d)

# 2. Copie o template do plano
cp templates/PLANO.md.tpl planejamento-diario/$(date +%Y-%m-%d)/PLANO.md

# 3. Edite o plano (preencha os placeholders)
# Abra o arquivo e substitua __DATA__, __NOME_DO_PROJETO__, etc.

# 4. Crie as tarefas
cp templates/TASK.md.tpl planejamento-diario/$(date +%Y-%m-%d)/task_01.md
cp templates/TASK.md.tpl planejamento-diario/$(date +%Y-%m-%d)/task_02.md

# 5. Atualize o índice
# Adicione as tarefas no INDICE.md com status ⬜

# 6. Commit inicial
git add -A
git commit -m "planejamento: inicia dia $(date +%Y-%m-%d)"
git push
```

---

<!-- =====================================================================
  SEÇÃO: LICENÇA / INFORMAÇÕES DE ENCERRAMENTO
===================================================================== -->
---
*Parte do projeto __NOME_DO_PROJETO__ · Documentação interna da equipe __NOME_DO_TIME__*
*Licença: __LICENCA__ (ex.: MIT, Apache 2.0)*
