# Exemplo Real: Bridge Document para Legado Dontus

## Contexto

O projeto **{{PROJECT_NAME}}** tem documentação sobre o legado Dontus (sistema ASP.NET legado a ser migrado para Django) espalhada em 3 camadas independentes. Foi criado um bridge document (`LEGADO-DONTUS-REFERENCIA.md`) para unificar a navegação.

## As 3 Camadas

| Camada | Caminho real | O quê | Read-only? |
|--------|-------------|-------|:----------:|
| 🟣 Obsidian (real) | `~/Dev/obsidian/10_Projects/{{PROJECT_SLUG}}/` | `.obsidian` vault completo; bíblia consolidada; revisões {{AUDITOR}}; mapeamento campo-a-campo | ❌ Sim |
| 🟢 Vault canônico | `{{PROJECT_PATH}}/docs/vault/` | Espelho estruturado do conteúdo do Obsidian no repositório git, organizado em `01-Arquitetura/`, `02-Modulos/`, etc. | ✅ |
| 🔵 Docs do projeto | `{{PROJECT_PATH}}/docs/` | Deep-dives, especificações Opus, planos, refinamentos, prompts | ✅ |

## Estrutura do Bridge Document

```
---
title: "LEGADO DONTUS — Ponte entre Obsidian e Projeto (Mapa de Referência)"
created: 2026-05-31
tags: [dontus, referencia, migracao, bridge, index]
modulo: G03
estagio: final
---

# 1. As Três Camadas             ← tabela com caminhos + permissões
# 2. Mapa de Tópicos Dontus      ← 9 subseções tabeladas, cada tópico com linha por camada
# 3. Fluxo de Trabalho           ← como consultar, o que não fazer
# 4. Arquivos com Dontus         ← inventário com tamanhos
# 5. Documentos Relacionados     ← cross-links para INDEX.md etc.
```

## Tópicos Mapeados (9)

1. **Plano de Migração ETL** — deep-dive técnico (102 KB, 2865 linhas) em `docs/deep-dives/`
2. **Mapeamento Campo-a-Campo** — APENAS no Obsidian (16 KB), é a fonte da verdade para transformação de dados
3. **Revisões {{AUDITOR}}** — APENAS no Obsidian (`REVISAO-G03-{{AUDITOR_UPPER}}.md`)
4. **Bíblia Consolidada** — APENAS no Obsidian (`biblia/BIBLIA-CONSOLIDADA.md`)
5. **Modelo de Dados / ER** — vault canônico (`07-BD/`) + Obsidian
6. **Blueprint Arquitetural** — vault (`01-Arquitetura/`) + docs raiz
7. **PRD** — vault (`08-Referencias/PRD.md`) + Obsidian
8. **Código Gerado** — APENAS no Obsidian (G04, G07, G08, G09, G12, G14)
9. **Planos de Gaps** — vault (`gaps/G03-MIGRACAO-DONTUS.md`) + docs raiz + Obsidian

## Regras de Agente

- ❌ NÃO criar/editar/deletar em `~/Dev/obsidian/` — domínio do {{GIT_OPS}} CLI
- ❌ NÃO duplicar conteúdo do Obsidian — criar cross-links
- ✅ Preferir `docs/vault/` e `docs/` para documentação operacional
- ✅ Se um documento do Obsidian não tem clone, bridge document aponta com caminho absoluto

## Arquivo Criado

`/Users/{{COMMANDER}}fae/Dev/{{PROJECT_SLUG}}/docs/LEGADO-DONTUS-REFERENCIA.md` (157 linhas, 9.4 KB)
