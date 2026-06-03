# Sanitizacao para Publicacao — Caso agent-ops-workflow

> **Propósito:** Relato da implementacao real do protocolo de sanitizacao usado em 03/06/2026
> para criar o template publico `agent-ops-workflow` a partir dos arquivos internos do time {{TEAM_NAME}}.
> Sirva-se deste registro como exemplo concreto ao executar sanitizacoes futuras.

---

## Contexto

Em 03/06/2026, {{COMMANDER}} solicitou a criacao de um repositorio publico contendo o
fluxo de trabalho multi-agente Hermes (skills, templates, scripts, documentacao),
removendo todas as referencias especificas ao time {{TEAM_NAME}}, Oeste Gestao e ao proprio {{COMMANDER}}.

## Estrutura criada

```
~/Dev/agent-ops-workflow/
├── planejamento-diario/         ← Prova viva: o workflow usado para construir o projeto
│   ├── INDICE.md
│   └── 2026-06-03/
│       ├── PLANO.md
│       └── task_01.md .. task_10.md
└── files/                       ← Staging (removido antes do commit final)
    ├── MANIFEST-GERAL.md
    ├── skills/
    │   ├── raw/                 ← Cópias literais dos originais
    │   └── sanitized/           ← Versões com placeholders
    ├── scripts/raw/
    └── templates/raw/
```

## Placeholders definidos

| Termo original | Placeholder | Onde usar |
|----------------|-------------|-----------|
| {{TEAM_NAME}} | `{{TEAM_NAME}}` | Skills, docs |
| {{ORCHESTRATOR}} | `{{ORCHESTRATOR}}` | Skills, templates |
| {{BACKEND_ENGINEER}} | `{{BACKEND_ENGINEER}}` | Skills |
| {{DEVOPS_ENGINEER}} | `{{DEVOPS_ENGINEER}}` | Skills |
| {{FRONTEND_ENGINEER}} | `{{FRONTEND_ENGINEER}}` | Skills |
| {{AUDITOR}} | `{{AUDITOR}}` | Skills |
| {{GIT_OPS}} | `{{GIT_OPS}}` | Skills |
| Oeste Gestao | `{{PROJECT_NAME}}` | Skills, docs |
| {{COMMANDER}} / {{COMMANDER_NAME}} | `{{COMMANDER}}` / `{{COMMANDER_NAME}}` | Skills, docs |
| {{PROJECT_SLUG}} | `{{PROJECT_SLUG}}` | Scripts, paths |
| {{PROJECT_PATH}} | `{{PROJECT_PATH}}` | Scripts |
| {{BLOG_URL}} | `{{BLOG_URL}}` | Docs, README |
| {{DONTUS_PASSWORD}} | `{{DONTUS_PASSWORD}}` (ou remover) | Skills |
| {{DONTUS_CLINICA_ID}} | `{{DONTUS_CLINICA_ID}}` (ou remover) | Skills |
| {{SLACK_ID_ORCHESTRATOR}} etc. | `{{SLACK_ID_ORCHESTRATOR}}` etc. | Configs |
| {{SLACK_CHANNEL_TEAM_ID}} | `{{SLACK_CHANNEL_TEAM}}` | Configs |
| {{SLACK_CHANNEL_TEAM}} | `{{SLACK_CHANNEL_TEAM}}` | SOUL.md, TEAM.md |
| {{SLACK_CHANNEL_WAR_ROOM}} | `{{SLACK_CHANNEL_WAR_ROOM}}` | SOUL.md |

## Formato de placeholders

- Skills sanitizadas: `{{NOME}}` (Mustache-style)
- Templates .tpl: `__NOME__` (double-underscore) — para diferenciar dos placeholders de skills

## Comando de verificacao

```bash
grep -rn "{{TEAM_NAME}}\|{{COMMANDER}}\|{{ORCHESTRATOR}}\|{{BACKEND_ENGINEER}}\|{{DEVOPS_ENGINEER}}\|{{FRONTEND_ENGINEER}}\|{{AUDITOR}}\|{{GIT_OPS}}\|{{PROJECT_NAME}}\|{{PROJECT_SLUG}}" \
  files/skills/sanitized/ || echo "OK — nenhum termo original encontrado"
```

## Licoes aprendidas

1. **Nao listar assets especulativos** — {{COMMANDER}} cortou `sync-repo.sh`, `design-system/` e `logos/` da proposta porque nao existiam ou nao eram uteis. So incluir no plano o que realmente sera utilizado.
2. **Meta-uso funciona** — ter o `planejamento-diario/` dentro do proprio projeto template foi bem recebido como "prova viva".
3. **files/ e seguro** — a pasta staging permite trabalhar sem medo de corromper os originais. O .gitignore com `files/` e o `git status` antes do commit sao a rede de seguranca final.
4. **Distincao de placeholders** — usar `{{NOME}}` para skills (substituicao unica) e `__NOME__` para templates (substituicao a cada uso) evita conflitos e deixa claro o que e cada coisa.
