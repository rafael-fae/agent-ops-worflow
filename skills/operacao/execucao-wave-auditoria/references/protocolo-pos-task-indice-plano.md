# Protocolo Pós-Task — Atualização de INDICE.md e PLANO.md

**Regra máxima ({{COMMANDER}}, 02/06/2026):** INDICE.md e PLANO.md DEVEM ser atualizados IMEDIATAMENTE após cada task auditada. ⬜ mantido é falha grave.

## Passos Imediatos Após Auditoria

1. **Atualizar PLANO.md** — marcar status da task como `✅`, atualizar contador `N/X`
2. **Atualizar INDICE.md** — preencher: agente, `✅`, `👁`, commit hash, contador
3. **Commits dos registros** — `git add planejamento-diario/ && git commit -m "docs: INDICE+PLANO — task_N ✅👁 (hash)"`
4. **Push** — `git push origin develop`

## Formato INDICE.md (6 colunas)

```markdown
| Task | Agente | Descrição | SP | ✅ | 👁 | Commit |
|------|--------|-----------|-----|---|---|--------|
| task_N | Agente | descrição | SP | ✅ | 👁 | hash |
```

**Legenda:**
- `✅` = agente concluiu a execução
- `👁` = {{ORCHESTRATOR}} auditou e aprovou
- `⬜` = pendente / não iniciado

## Verificação Final

```bash
git log --oneline -5              # confirmar commits
grep "task_N" INDICE.md           # confirmar entrada com ✅👁
grep "task_N" PLANO.md            # confirmar status ✅
git push origin develop           # sincronizar
```

## Erro Comum (02/06/2026)

{{ORCHESTRATOR}} no Slack atualizou PLANO.md e docs/INDEX.md mas ESQUECEU o planejamento-diario/INDICE.md. Tasks 16, 17, 19, 21 ficaram como `⬜` no INDICE por horas. {{COMMANDER}} notou e corrigiu.

**Regra:** INDICE.md e PLANO.md são AMBOS obrigatórios. Um sem o outro = falha.
