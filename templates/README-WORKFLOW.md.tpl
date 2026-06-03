<!--
==============================================================================
  README-WORKFLOW.md.tpl — README da Pasta de Planejamento Diário
  ============================================================================
  Este arquivo serve como README para a pasta `planejamento-diario/` do seu
  projeto. Copie para planejamento-diario/README.md e adapte.

  O propósito deste README é explicar para QUALQUER pessoa que entrar na pasta
  o que ela é, como funciona, e como participar do workflow diário.

  Como usar:
    1. Copie este template para planejamento-diario/README.md
    2. Substitua __PLACEHOLDERS__ pelos dados do seu time
    3. Adapte os exemplos conforme sua realidade
    4. Mantenha o tom didático — novatos precisam entender rápido
==============================================================================
-->

# 📋 Planejamento Diário — __NOME_DO_TIME__

> **Esta pasta é o CORAÇÃO do nosso workflow de planejamento diário.**
> Aqui documentamos o que fizemos, o que estamos fazendo e o que faremos.

---

<!-- =====================================================================
  SEÇÃO: O QUE É
  Explica o propósito da pasta em linguagem simples.
===================================================================== -->
## O que é esta pasta?

A pasta `planejamento-diario/` é o sistema nervoso central da nossa operação
multi-agente. Ela contém:

- **`INDICE.md`** — O painel de controle. Mostra o progresso geral, dia a dia,
  com status de cada task (concluída, auditada, pendente).

- **`__DATA__/`** — Pastas com data ISO (ex: `2026-06-03/`) contendo o plano
  e as tasks de cada dia:
  - `PLANO.md` — O plano de execução do dia: waves, tasks, dependências
  - `task_01.md`, `task_02.md`, ... — Tasks individuais com instruções detalhadas

O workflow é simples:
1. **Planeje** — Crie o PLANO.md do dia com as waves e tasks
2. **Execute** — Cada agente pega uma task e executa
3. **Registre** — Atualize o status no INDICE.md
4. **Audite** — Outro agente revisa a task concluída
5. **Repita** — No dia seguinte, comece de novo

---

<!-- =====================================================================
  SEÇÃO: ESTRUTURA DA PASTA
  Mostra a árvore de diretórios para referência rápida.
===================================================================== -->
## Estrutura

```
planejamento-diario/
├── README.md              ← Este arquivo (instruções de uso)
├── INDICE.md              ← Índice geral com progresso
├── __DATA_1__/            ← Ex: 2026-06-03/
│   ├── PLANO.md           ← Plano do dia
│   ├── task_01.md         ← Task individual
│   ├── task_02.md
│   └── ...
└── __DATA_2__/            ← Ex: 2026-06-04/
    ├── PLANO.md
    └── ...
```

---

<!-- =====================================================================
  SEÇÃO: CICLO DIÁRIO
  Explica passo a passo como usar o workflow no dia a dia.
===================================================================== -->
## Como usar no dia a dia

### 🌅 Início do dia (Comandante / Orquestrador)

1. **Leia o INDICE.md** — veja o que ficou pendente do dia anterior
2. **Crie a pasta do dia:** `mkdir -p planejamento-diario/$(date +%Y-%m-%d)`
3. **Copie o template PLANO.md.tpl** para dentro da pasta e preencha:
   - Data, time, propósito do dia
   - Waves (Manhã/Tarde/Noite — quantas fizer sentido)
   - Tasks com descrição, agente, motor, prioridade
   - Diagrama de dependências
4. **Copie templates TASK.md.tpl** para cada task do plano
5. **Atualize o INDICE.md** com as novas tasks do dia

### 🏃 Durante o dia (Agentes)

1. **Pegue uma task** — escolha uma task pendente no INDICE.md
2. **Leia a task** — entenda o contexto, instruções e restrições
3. **Execute** — siga as instruções passo a passo
4. **Marque o checklist** — vá marcando os itens concluídos
5. **Preencha a Conclusão** — documente o que foi feito
6. **Atualize o INDICE.md** — marque ✅ e adicione o hash do commit
7. **Avise o auditor** — a task precisa ser revisada

### ✅ Final do dia (Comandante / Orquestrador)

1. **Verifique o progresso** — quantas tasks foram concluídas?
2. **Audite as tasks pendentes** — 👁 deve virar ✅
3. **Atualize o contador** no cabeçalho do INDICE.md
4. **Atualize a seção de Progresso** por wave
5. **Commit e push**:
   ```bash
   git add -A
   git commit -m "planejamento: atualiza dia __DATA__"
   git push
   ```
6. **Documente pendências** para o dia seguinte no INDICE.md

---

<!-- =====================================================================
  SEÇÃO: CONVENÇÕES
  Regras de nomenclatura e formatação para manter consistência.
===================================================================== -->
## Convenções

### Nomenclatura

| Item | Formato | Exemplo |
|------|---------|---------|
| Pasta de data | `YYYY-MM-DD` | `2026-06-03/` |
| Plano do dia | `PLANO.md` | `2026-06-03/PLANO.md` |
| Task individual | `task_NN.md` | `task_01.md` |
| Índice geral | `INDICE.md` | `INDICE.md` |

### Símbolos de status

| Símbolo | Significado |
|:-------:|-------------|
| ✅ | Task concluída |
| 👁 | Task auditada (revisada por outro agente) |
| ⬜ | Pendente (não iniciada) |
| 🔴 | Prioridade alta |
| 🟡 | Prioridade média |
| 🟢 | Prioridade baixa |

### Prioridades

- **🔴 Alta:** Bloqueante. Impede outras tasks. Deve ser feita primeiro.
- **🟡 Média:** Importante mas não bloqueia outras tasks.
- **🟢 Baixa:** Melhoria, refinamento, débito técnico.

---

<!-- =====================================================================
  SEÇÃO: REFERÊNCIA
  Links para documentação completa e exemplos.
===================================================================== -->
## Referência

- **Documentação completa do workflow:** __URL_DOCS__ (ex: https://docs.seutime.com/workflow)
- **Repositório do projeto:** __URL_REPO__ (ex: github.com/seu-time/seu-projeto)
- **Templates disponíveis em:** `templates/` (PLANO.md.tpl, TASK.md.tpl, INDICE.md.tpl)
- **Canal da equipe:** __CANAL_DO_TIME__ (ex: #canal-do-time no Slack)
- **Comandante atual:** __COMANDANTE__

---

<!-- =====================================================================
  SEÇÃO: EXEMPLO RÁPIDO
  Um mini-tutorial para quem quer começar imediatamente.
===================================================================== -->
## Exemplo rápido

```bash
# 1. Criar a pasta do dia
mkdir -p planejamento-diario/$(date +%Y-%m-%d)

# 2. Copiar o template do plano
cp templates/PLANO.md.tpl planejamento-diario/$(date +%Y-%m-%d)/PLANO.md

# 3. Editar o plano (preencher placeholders)
# Abra o arquivo e substitua __DATA__, __NOME_DO_PROJETO__, etc.

# 4. Criar tasks
cp templates/TASK.md.tpl planejamento-diario/$(date +%Y-%m-%d)/task_01.md
cp templates/TASK.md.tpl planejamento-diario/$(date +%Y-%m-%d)/task_02.md

# 5. Atualizar o índice
# Adicione as tasks no INDICE.md com status ⬜

# 6. Commit inicial
git add -A
git commit -m "planejamento: inicia dia $(date +%Y-%m-%d)"
git push
```

---

<!-- =====================================================================
  SEÇÃO: LICENÇA / INFORMAÇÕES FINAIS
===================================================================== -->
---
*Parte do projeto __NOME_DO_PROJETO__ · Documentação interna da equipe __NOME_DO_TIME__*
*Licença: __LICENCA__ (ex: MIT, Apache 2.0)*
