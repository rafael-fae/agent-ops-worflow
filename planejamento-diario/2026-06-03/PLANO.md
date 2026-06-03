# Plano de Execução — agent-ops-workflow

**Criado por:** Dalinar / Rafael Fae
**Data:** 03/06/2026
**Propósito:** Criar repositório público template com o fluxo de trabalho multi-agente Hermes
**Workflow:** Este plano SEGUE o próprio workflow que está sendo documentado — prova viva de que funciona.

---

## 📚 RECURSOS DO PROJETO

| Recurso | Local | Propósito |
|---------|-------|-----------|
| Tutorial publicado | https://pycode.rafaelfae.com.br/equipe-roshar | Base conceitual do fluxo |
| Skills atuais | ~/.hermes/profiles/dalinar/skills/ | Fonte das skills a serem generalizadas |
| Scripts atuais | ~/.hermes/profiles/dalinar/skills/*/scripts/ | Automações existentes |
| Templates atuais | ~/.hermes/profiles/dalinar/skills/*/templates/ | Templates de plano e task |
| Este plano | agent-ops-workflow/planejamento-diario/ | O PLANO em ação |

---

## Resumo

Criar o repositório `agent-ops-workflow` que documenta e empacota o sistema de
planejamento diário multi-agente para Hermes. O repositório conterá:

1. **Templates** — PLANO.md, TASK.md, INDICE.md (genéricos, sem nomes específicos)
2. **Skills** — skills Hermes sanitizadas (sem refs a Roshar, Oeste Gestão, Rafael)
3. **Scripts** — automações de cron, rotação de chaves, setup
4. **Documentação** — tutorial completo em português sobre o fluxo
5. **Assets** — mínimos (apenas o necessário)

**Regra de ouro:** A pasta `files/` contém cópias RAW dos nossos arquivos — NUNCA
será commitada. Ao final, será removida. O repositório final tem apenas conteúdo
sanitizado e genérico.

---

## Waves

### Wave 1 — Mapeamento e Cópia (Manhã) 🔴 ✅

| Task | Descrição | Ferramenta | Status |
|:----:|-----------|:----------:|:------:|
| task_01 | Mapear skills existentes + copiar raw para files/skills/raw/ | Gemini | ✅ |
| task_02 | Mapear scripts, templates, assets → files/ respectivos | Gemini | ✅ |

**Objetivo:** ✅ 2/2 — 43 skills copiadas, 120+ arquivos de scripts/templates/references

### Wave 2 — Sanitização e Generalização (Tarde) 🔴

| Task | Descrição | Ferramenta |
|:----:|-----------|:----------:|
| task_03 | Sanitizar skills — substituir Roshar→{{TEAM_NAME}}, Oeste Gestão→{{PROJECT_NAME}}, etc. | Gemini |
| task_04 | Criar templates .tpl com placeholders | Gemini |
| task_05 | Criar scripts genéricos (cron, setup, rotate-key, validate) | Gemini |

**Objetivo:** Gerar o conteúdo final do repositório a partir do material bruto.

### Wave 3 — Documentação (Noite) 🟡

| Task | Descrição | Ferramenta |
|:----:|-----------|:----------:|
| task_06 | README.md + visão geral (o que é, para quem serve, quickstart) | Gemini |
| task_07 | Docs: setup inicial, ciclo diário, protocolo Slack | Gemini |
| task_08 | Docs: guia de skills, adaptação, melhores práticas | Gemini |

**Objetivo:** Documentação completa, didática, em português.

### Wave 4 — Finalização (Madrugada) 🟢

| Task | Descrição | Ferramenta |
|:----:|-----------|:----------:|
| task_09 | Estruturar repositório final (organizar, remover files/, .gitignore) | Gemini |
| task_10 | Publicar no GitHub + auditoria final + README atualizado | Gemini |

**Objetivo:** Repositório publicado, indexado, documentado.

---

## Dependências

```
Wave 1 (Mapeamento)
  task_01 (skills) + task_02 (scripts/templates) — paralelo

Wave 2 (Sanitização)
  task_03 (skills sanitizadas) depende de task_01
  task_04 (templates) depende de task_02
  task_05 (scripts) depende de task_02

Wave 3 (Documentação)
  task_06 (README) depende de task_03, task_04, task_05
  task_07 (ciclo+setup) depende de task_06
  task_08 (skills guide) depende de task_03

Wave 4 (Publicação)
  task_09 (estruturação) depende de task_06, task_07, task_08
  task_10 (publicar) depende de task_09
```

---

## ⚠️ REGRAS DA EXECUÇÃO

1. **Motor padrão:** Gemini CLI (`gemini -m "gemini-3.1-pro-preview"`)
2. **NUNCA modificar arquivos originais** — só mexer em `files/` e na raiz do projeto
3. **files/ NÃO é commitada** — adicionar ao .gitignore no final
4. **Independência:** Este projeto NÃO depende do Oeste Gestão. É auto-contido.
5. **Didático:** Cada arquivo DEVE ser comentado e explicado — outras pessoas vão ler.
6. **Português:** Documentação em pt-BR (pelo menos v1).
7. **Commit semántico:** Commits descritivos em português.

---

## Ao final do projeto

- [ ] 10/10 tasks concluídas e auditadas
- [ ] Repositório publicado no GitHub (público)
- [ ] README com quickstart funcional
- [ ] Pasta files/ removida
- [ ] Link compartilhado com Rafael
