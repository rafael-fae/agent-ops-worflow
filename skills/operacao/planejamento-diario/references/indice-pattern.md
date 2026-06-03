# INDICE.md — Padrão de Referência

## Propósito

Índice central em `planejamento-diario/INDICE.md` que permite a qualquer agente localizar tarefas passadas, commits e contexto sem precisar abrir dezenas de arquivos.

## Formato

```markdown
# Índice de Planejamento Diário — {{PROJECT_NAME}}

> **Propósito:** Referência rápida.
> **Regra:** Atualizar SEMPRE após cada task auditada e aprovada. Preencher commits ao criar novas tasks.

---

## DD/MM/AAAA — N/M concluídas [símbolo]

| Task | Agente | Descrição | Commit |
|------|--------|-----------|--------|
| task_01 | {{BACKEND_ENGINEER}} | SP1-07+10: Tenant model + exports | 6962a8e |
| task_02 | {{DEVOPS_ENGINEER}} | SP1-20: ClinicaScopeManager | 168ec41 |

---

## Progresso Sprint 1

| Módulo | Ontem | Hoje |
|--------|-------|------|
| K3 | 65% | 95% |
```

## Regras

1. **Criação do planejamento:** Tasks já nascem no índice. Linha preenchida com descrição + SP, commit vazio.
2. **Após auditoria + aprovação:** Preencher commit hash.
3. **Novas tasks durante o dia:** Popular imediatamente — não esperar encerramento.
4. **Encerramento do dia:** Índice completo com todos os commits, métricas de progresso atualizadas.

## Exemplo real (02/06/2026)

Ver `planejamento-diario/INDICE.md` no repositório para o formato exato em uso.
