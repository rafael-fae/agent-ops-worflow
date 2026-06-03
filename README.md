# Agent Ops Workflow

Sistema de planejamento diário multi-agente para equipes Hermes.
Organize, delegue e audite tarefas entre seus agentes de IA com um fluxo testado em produção.

> **Status:** Projeto em construção — v0.1.0
> Este README será expandido nas próximas tasks (consulte `planejamento-diario/` para o plano completo).

---

## Estrutura Atual

```
agent-ops-workflow/
├── LICENSE              ← MIT
├── .gitignore
├── planejamento-diario/ ← Nosso próprio workflow em ação
│   ├── INDICE.md        ← Progresso geral
│   └── 2026-06-03/      ← Plano de criação deste repositório
│       ├── PLANO.md
│       ├── task_01.md
│       └── ...
└── files/               ← Material bruto (não commitado — .gitignore)
```

---

## Por que este projeto existe?

Agentes IA não têm memória entre sessões. Sem um sistema externo de registro,
tarefas se perdem, motores errados são usados, e o progresso jamais é consolidado.
Este workflow resolve isso com um sistema de planejamento diário em markdown,
delegação via Slack, e auditoria multi-agente.

---

## Licença

MIT
