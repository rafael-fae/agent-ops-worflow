# Referência Rápida — Agent Ops Workflow

> Folha de dicas de uma página para o workflow de planejamento diário multi-agente.
> Consulte a documentação completa para detalhes.

---

## Comandos

| Ação | Comando |
|------|---------|
| **Inicializar** | `./scripts/setup-workflow.sh ~/projeto "Nome do Time" "Nome do Projeto"` |
| **Gerar plano diário** | `./scripts/gerar-plano-diario.sh ~/projeto` |
| **Validar workflow** | `./scripts/validate-workflow.sh ~/projeto` |
| **Validar + auto-corrigir** | `./scripts/validate-workflow.sh ~/projeto --fix` |
| **Validar (verboso)** | `./scripts/validate-workflow.sh ~/projeto --verbose` |
| **Carregar skill (inspecionar)** | `hermes skill_view caminho/para/skill/SKILL.md` |
| **Carregar skill (ativar)** | `hermes skill_manage add caminho/para/skill/SKILL.md` |
| **Agendar cron (5 AM)** | `0 5 * * * /caminho/gerar-plano-diario.sh ~/projeto >> ~/projeto/planejamento-diario/cron.log 2>&1` |

---

## Estrutura do Projeto

```
projeto/
└── planejamento-diario/
    ├── INDICE.md              ← Índice mestre de progresso (TODOS os dias)
    ├── TEMPLATES/             ← Arquivos de template (não edite diretamente)
    │   ├── PLANO.md           ← Copiado de templates/PLANO.md.tpl
    │   ├── TASK.md            ← Copiado de templates/TASK.md.tpl
    │   └── INDICE.md          ← Copiado de templates/INDICE.md.tpl
    └── YYYY-MM-DD/            ← Um diretório por dia
        ├── PLANO.md           ← Plano do dia (waves, tarefas, status)
        ├── task_01.md         ← Brief da tarefa + checklist
        ├── task_02.md
        └── ...
```

### Layout do Repositório (agent-ops-workflow/)

```
agent-ops-workflow/
├── planejamento-diario/    # Dogfooding — o workflow executando em si mesmo
├── templates/              # Fonte da verdade: PLANO.md.tpl, TASK.md.tpl, INDICE.md.tpl
├── scripts/                # setup-workflow.sh, gerar-plano-diario.sh, validate-workflow.sh, rotate-key.sh
├── docs/                   # Documentação completa (6 guias)
├── files/                  # Área de trabalho — NÃO commitada (.gitignored)
│   └── skills/
│       ├── raw/            # Skills originais antes da sanitização
│       └── sanitized/      # Skills com placeholders para reuso
└── LICENSE                 # MIT
```

---

## As 6 Fases

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│ PLANEJAR │ ──→ │  APROVAR │ ──→ │  DELEGAR │
└──────────┘     └──────────┘     └──────────┘
                                         │
                                         ▼
┌──────────┐     ┌──────────┐     ┌──────────┐
│ REPORTAR │ ←── │ AUDITAR  │ ←── │ EXECUTAR │
└──────────┘     └──────────┘     └──────────┘
```

| Fase | O que Acontece |
|------|---------------|
| **1. PLANEJAR** | Orquestrador cria `PLANO.md` com waves, tarefas, prioridades e dependências. Cria arquivos `task_XX.md` com briefings, checklists e restrições. Atualiza `INDICE.md`. |
| **2. APROVAR** | Comandante (humano) revisa o plano, ajusta prioridades, aprova ou rejeita tarefas. **Nunca implemente sem o sinal verde.** |
| **3. DELEGAR** | Orquestrador envia tarefas para agentes via Slack — uma tarefa por @menção em uma thread. Cada mensagem inclui obrigação de motor, instruções e restrições. |
| **4. EXECUTAR** | Agente lê docs obrigatórios, segue instruções, marca checkboxes, preenche seção de conclusão, commita + push, reporta na thread. |
| **5. AUDITAR** | Orquestrador verifica commits (`git log`, `git show`), checa diffs, lê arquivos alterados. Se aprovado: atualiza PLANO + INDICE e commita registros. |
| **6. REPORTAR** | Orquestrador produz tabela consolidada, veredito por tarefa (✅/⚠️/❌), commita todos os registros (PLANO.md, INDICE.md). |

---

## Regras de Ouro

1. **INDICE.md e PLANO.md** — Atualize IMEDIATAMENTE após cada tarefa auditada.
   ⬜ deixado aberto = falha crítica. Hash do commit e 👁 obrigatórios.

2. **PLANEJAR ≠ DELEGAR** — "Planejar" significa criar arquivos .md + atualizar índices.
   "Delegar" significa enviar no Slack. Um não implica o outro.

3. **Uma tarefa = uma thread Slack** — Toda comunicação sobre uma tarefa vai em
   sua thread original. Sem novas threads para correções, complementos ou
   re-auditorias.

4. **Motor padrão = Gemini 3.1 Pro** — Toda tarefa de código usa Gemini.
   Se falhar (RESOURCE_EXHAUSTED, erro), divida em subtarefas menores.
   NUNCA troque de modelos. Se ainda falhar, PARE e reporte.

5. **Sempre commit + push antes de reportar** — Se não há hash de commit,
   a tarefa não está concluída.

5. **⬜ mantido é falha grave — atualize IMEDIATAMENTE após cada auditoria.**
   INDICE.md e PLANO.md DEVEM ser atualizados no mesmo momento da auditoria:
   ✅ na task, 👁 na task, hash do commit, contador X/Y. Nunca acumule.
6. **Nunca tome ação corretiva sem o sinal verde do Comandante.**
   Cometeu um erro? Reporte e ESPERE. Não delete, reverta ou corrija.

---

## Hierarquia de Motores

| Prioridade | Motor | Uso |
|:----------:|-------|-----|
| **1 (PADRÃO)** | Gemini 3.1 Pro | TODAS as tarefas de código |
| **2** | Opus 4.7 | UI/visão/design (Engenheiro Frontend), auditorias complexas, migrações de dados cross-DB |
| **3** | OpenCode Go / GLM 5.1 | Tarefas rápidas, exploração, operações de arquivo |
| — | DeepSeek V4 Pro | **PROIBIDO** sem ordem explícita do Comandante |

> O motor no `task_XX.md` NÃO é autoritativo. Substitua para Gemini antes
> de delegar.

---

## Protocolo Slack

| Regra | Descrição |
|-------|-----------|
| **Formato de menção** | Sempre `<@USER_ID>` no início da mensagem |
| **Sem tabelas na delegação** | Caracteres pipe quebram o parser de menção |
| **Um agente por menção** | Apenas o agente mencionado responde |
| **Regra do silêncio** | Se não for mencionado, fique em silêncio |
| **Lockdown** | "sinal vermelho" congela todos os agentes — sem ações até ser suspenso |

### Escopos Slack Obrigatórios (Token Bot)

- `channels:history` — Ler histórico do canal
- `channels:read` — Visualizar informações do canal
- `chat:write` — Enviar mensagens
- `reactions:read` — Ler reações
- `users:read` — Ler informações do usuário

---

## Seções do Arquivo de Tarefa (task_XX.md)

Todo arquivo de tarefa deve conter:

- **Leitura Obrigatoria** — Seções de PRD, seções de Blueprint, referências
- **Checklist** — Itens binários numerados (feito/não feito)
- **Conclusao** — Agente, Data, Motor, Hash do commit, Observações
- **Restricoes** — Motor obrigatório, modificações proibidas,
  ações que nunca devem ser feitas

---

## Formato do INDICE.md

```
## DD/MM/AAAA — CONCLUÍDAS/TOTAL

| Tarefa   | Descrição          | Wave | ✅ | 👁 | Commit    |
|----------|--------------------|:----:|---|---|-----------|
| task_01  | Descrição curta    | 1    | ✅ | ✅ | abc1234   |
| task_02  | Descrição curta    | 2    | ⬜ | ⬜ | —         |
```

**Legenda:** ✅ = concluído | 👁 = auditado e aprovado | ⬜ = pendente

---

## Referência de Arquivos do Workflow

| Arquivo | Propósito |
|---------|-----------|
| `docs/01-CONFIGURACAO-INICIAL.md` | Configuração de ambiente, pré-requisitos, primeira execução |
| `docs/02-CICLO-DIARIO.md` | Passo a passo do ciclo de 6 fases |
| `docs/03-PROTOCOLO-SLACK.md` | Regras de comunicação de agentes |
| `docs/04-GUIA-SKILLS.md` | Referência completa de skills, criação, adaptação |
| `docs/05-PERSONALIZACAO.md` | Configuração do time, templates, motores |
| `docs/06-REFERENCIA-RAPIDA.md` | Dicas, armadilhas, convenções |

---

## Armadilhas Comuns

| Armadilha | Prevenção |
|-----------|-----------|
| Menção Slack quebrada por tabelas | Nunca use `|` em mensagens de delegação |
| Agente reporta hash de commit falso | Sempre verifique com `git log --oneline` |
| Índice não atualizado após auditoria | Atualize INDICE + PLANO imediatamente após cada tarefa |
| Motor errado usado | "ORDEM ABSOLUTA" + comando de motor exato na delegação |
| Delegação sem autorização | Aprovação do Comandante necessária antes de qualquer envio Slack |
| Thread quebrada (agente responde no canal) | Apenas o orquestrador publica fora de threads |
| Checklists vazios | Reforce no momento da delegação — preencha antes de reportar |
| Contador do índice errado | Recalcule X/Y após cada tarefa auditada |

---

## Dicas Rápidas

- **Plano diário às 5 AM:** Cron `gerar-plano-diario.sh` para planos prontos de manhã
- **Placeholders de skill usam `{{ ... }}`** ; Placeholders de template usam `__ ... __`
- **`files/` é .gitignored** — é uma área de trabalho, nunca commitada
- **Valide diariamente** antes de iniciar novas tarefas: `validate-workflow.sh`
- **Lockdown sobrepõe tudo** — até mesmo as regras de ouro

---

## Licença

MIT — Livre para usar, adaptar e compartilhar. Veja [LICENSE](../LICENSE) para detalhes.

© 2026 — Agent Ops Workflow
