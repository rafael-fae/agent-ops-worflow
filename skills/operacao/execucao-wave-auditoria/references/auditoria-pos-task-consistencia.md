# Auditoria Pós-Task — Integridade Cruzada de Documentação

## Propósito

Verificar que, após uma task reportada como concluída, todos os artefatos de documentação estão consistentes entre si e com o git log. Evita falso-positivos de task "concluída" com documentação desatualizada.

---

## Checklist de Verificação

### 1. Hash do Commit

| O quê | Como | Falha comum |
|-------|------|-------------|
| Hash no PLANO.md existe no git log | `git log --oneline -10` | Agente reporta hash que não existe (fabricação ou erro de digitação) |
| Hash corresponde ao commit certo | `git show <hash> --stat` — arquivos alterados devem bater com o escopo da task | Hash existe mas é de commit não relacionado |
| Commit foi feito push | `git branch -r --contains <hash>` — deve retornar `origin/develop` | Commit apenas local — OVH fica desatualizado |

### 2. PLANO.md

- [ ] Status da task atualizado (⬜ → ✅ ou 👁)
- [ ] Hash do commit presente (se aplicável)
- [ ] Hash é o MESMO do commit final da task (não de commit intermediário ou não relacionado)

**🔴 Regra:** Se o hash no PLANO.md não aparece em `git log --oneline -10`, a task NÃO foi concluída — o hash é inválido.

### 3. INDEX.md (docs/INDEX.md)

- [ ] Se a task produziu/corrigiu um documento .md, a entrada existe no INDEX.md
- [ ] Descrição da entrada reflete o novo status (ex: "C1/C5 corrigidos ✅")
- [ ] Link relativo funcional (`../design_system/...` → arquivo existe)

### 4. Relatório de Auditoria

- [ ] Status dos itens corrigidos reflete o commit real
- [ ] Tabela de divergências com marcadores ✅ para itens corrigidos
- [ ] Data/metadados atualizados (frontmatter YAML `updated`)

### 5. Sincronia Cross-Tokens (Design System)

Quando a task envolve cores, variáveis CSS, ou tokens de design:

```
design_system/tokens.css --ds-color-primary-600
        ↔
static/css/tokens.css    --o-color-primary-600
```

- [ ] Valor hex de `primary-600` é IDÊNTICO nos dois arquivos
- [ ] `COMPONENTS-DETAILED.md` documenta o mesmo hex
- [ ] Todas as menções ao antigo valor (ex: Cyan `#0891B2`) foram substituídas

**Comando de verificação:**
```bash
grep -n "primary-600\|#0891B2\|#0d9488\|#06B6D4\|#14b8a6" \
  design_system/tokens.css static/css/tokens.css \
  design_system/COMPONENTS-DETAILED.md | grep -v "^\-\-$\|//\|/\*"
```

**Critério de aprovação:** Zero ocorrências do valor antigo (ex: `#0891B2` Cyan) em qualquer token file.

### 6. Verificação Final Contra Self-Report

Comparar o que o agente REPORTou com o que os artefatos mostram:

| Afirmação do Agente | Verificação |
|---------------------|-------------|
| "Commit `abc1234`" | `git log --oneline` → existe? `git show abc1234 --stat` → arquivos batem? |
| "PLANO.md atualizado" | `grep "task_XX" planejamento-diario/YYYY-MM-DD/PLANO.md` → ✅ presente |
| "INDEX.md atualizado" | `grep "C1/C5" docs/INDEX.md` → ✅ descrição contém atualização |
| "Tokens sincronizados" | Comando grep acima → zero ocorrências do valor antigo |

---

## Exemplo Real (02/06/2026 — Task 19)

**Agente:** {{FRONTEND_ENGINEER}}  
**Task:** C1 (Cyan→Teal) + C5 (success naming) no Design System  
**Motor:** Opus 4.7  

### Passos executados:

1. `git log --oneline -10` → `3b2fb4d` e `2995b5a` aparecem como commits recentes
2. `git show 3b2fb4d --stat` → confirma PLANO.md e INDEX.md modificados
3. `git show 2995b5a --stat` → confirma COMPONENTS-DETAILED.md + relatório modificados
4. `grep -n "primary-600\|#0891B2" design_system/tokens.css static/css/tokens.css` → zero Cyan
5. `grep "C1" design_system/RELATORIO-AUDITORIA-VISUAL.md` → ✅ Corrigido
6. Confere hash no PLANO.md: `8753815` (hash intermediário do commit de cleanup) → deveria ser `2995b5a` (commit das correções reais)

**Lições:** 
- O hash no PLANO.md era de um commit de cleanup (`remove _prompt_task16.md`), não do commit de correções. Idealmente, o hash deveria refletir o commit de trabalho principal (`2995b5a`).
- As verificações de documentação (INDEX.md, relatório) estavam corretas — o problema foi apenas o hash apontar para commit não relacionado ao escopo da task.
- Sempre verificar se o hash no PLANO.md corresponde ao commit que fez AS ALTERAÇÕES da task, não a commits auxiliares posteriores.
