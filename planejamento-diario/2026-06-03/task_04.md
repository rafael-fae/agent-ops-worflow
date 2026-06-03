# Task 04 — Criar templates genéricos (PLANO, TASK, INDICE .tpl)

**Wave:** 2 (Sanitização)
**Prioridade:** 🔴
**Ferramenta:** Gemini CLI
**Depende de:** task_02

---

## Contexto

Os templates atuais (PLANO.md, TASK.md, INDICE.md) estão adaptados ao Oeste Gestão.
Precisamos criar versões .tpl (template) genéricas que qualquer time possa usar
substituindo placeholders.

---

## Instruções

Criar os seguintes templates em `agent-ops-workflow/templates/`:

### 1. `templates/PLANO.md.tpl`

Template de plano diário com:
- Cabeçalho editável (data, nome do time, comandante)
- Seção de recursos do projeto (vazia, para preencher)
- Seção de waves (Manhã/Tarde/Noite — editável)
- Tabela de tasks por wave (Task, Agente, Motor, Prioridade, Status)
- Seção de dependências (diagrama Mermaid ou lista)
- Regras inegociáveis (genéricas)
- Checklist de final de dia
- Métricas-alvo (editáveis)

### 2. `templates/TASK.md.tpl`

Template de task individual com:
- Cabeçalho (Task ID, Wave, Prioridade, Depende de)
- Seção de Leitura Obrigatória (vazia, para preencher)
- Contexto (explicação do porquê)
- Instruções numeradas
- Checklist template
- Restrições de motor
- Arquivos relevantes (tabela editável)
- Seção Conclusão (pré-formatada)

### 3. `templates/INDICE.md.tpl`

Template de índice com:
- Cabeçalho com legenda (✅ 👁 ⬜)
- Tabela de tasks (Task, Descrição, Wave, ✅, 👁, Commit)
- Seção de progresso por wave
- Instruções de atualização

### 4. `templates/README-WORKFLOW.md.tpl`

Template de README para a pasta `planejamento-diario/` do projeto do usuário:
- Explicação do que é a pasta
- Como usar
- Referência para documentação completa

### Formato dos placeholders

Usar `__PLACEHOLDER__` (com duplo underscore) para placeholders dentro dos templates,
para diferenciar dos `{{PLACEHOLDER}}` usados nas skills sanitizadas.

Exemplo:
```markdown
# Plano Diário — __DATA__

**Aprovado por:** __COMANDANTE__
```

---

## Checklist

- [x] PLANO.md.tpl criado com todas as seções
- [x] TASK.md.tpl criado com todos os campos
- [x] INDICE.md.tpl criado com legenda e tabela
- [x] README-WORKFLOW.md.tpl criado
- [x] Placeholders usam formato __PLACEHOLDER__ consistente
- [x] Templates testáveis (alguém consegue preencher e usar)

---

## Restrições

- NÃO copiar conteúdo específico do Oeste Gestão
- Manter comentários explicativos no template

---

## Conclusão

**Agente:** Dalinar (via subagentes)
**Concluída em:** 03/06/2026 ~10:30
**Motor utilizado:** deepseek-v4-flash (subagente)
**Observações:**
- PLANO.md.tpl — 215 linhas, ~70 placeholders, waves editáveis, dependências, regras
- TASK.md.tpl — 251 linhas, ~50 placeholders, seções completas
- INDICE.md.tpl — 147 linhas, ~65 placeholders, contador automático
- README-WORKFLOW.md.tpl — 202 linhas, 11 placeholders, visão geral do workflow
- Todos com placeholders __DUPLO_UNDERSCORE__ e comentários HTML
- Zero referências a Roshar/Rafael/Oeste Gestão
- Baseados nos exemplos reais do planejamento-diario/
