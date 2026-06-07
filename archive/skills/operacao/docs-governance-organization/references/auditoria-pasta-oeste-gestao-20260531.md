# Auditoria de Pasta — {{PROJECT_SLUG}} (31/05/2026)

**Contexto:** {{COMMANDER}} solicitou auditoria da pasta `{{PROJECT_SLUG}}` para verificar se continha APENAS planejamento, modelos e itens auditados.
**Resultado:** :red_circle: NÃO CONFORME — ~14.176+ linhas de código de desenvolvimento presentes.

## Estrutura Encontrada

| Diretório | Linhas | Classificação |
|:---------:|:------:|:-------------|
| `docs/` + `docs/refinamentos/` + `docs/vault/` | ~120 .md | :white_check_mark: Planejamento |
| `design_system/` (prompts Opus) | 17 arquivos | :white_check_mark: Modelos/{{FRONTEND_ENGINEER}} |
| `apps/` | 7.267 | :x: Código Django |
| `config/` | 1.535 | :x: Config Django |
| `templates/` | 806 | :x: HTML real |
| `static/` | 4.568 | :x: CSS/JS real |
| Root (manage.py, uv.lock, .venv, etc.) | — | :x: Scaffold |

## Commits Investigados

| Commit | Data | Tipo | Responsável |
|:------:|:----:|:----:|:-----------:|
| `8ad50f4` | 29/05 | 🔴 MISTURADO (código + 30 .md) | {{COMMANDER}}-fae |
| `737151e` | 29/05 | 🖥️ Só código (apps/agenda) | {{COMMANDER}}-fae |
| `d682c73` | 29/05 | 🟢 Só docs | {{COMMANDER}}-fae |
| `b3b455e` | 31/05 | 🔴 MISTURADO MASSIVO (724 arquivos) | {{COMMANDER}}-fae |
| `f1641ed` | 31/05 | 🟢 Só docs | {{COMMANDER}}-fae |
| `a919422` | 31/05 | 🟢 Só docs | {{COMMANDER}}-fae |

## Conclusão

Reset simples para `b1c8355` destruiria ~70% dos docs de descoberta. Recomendação: Opção D (criar develop, reset main, cherry-pick docs-only, extração seletiva, PR gate).

## Artefato Original

`docs/refinamentos/AUDITORIA-PASTA-OESTE-GESTAO.md` no repositório `{{PROJECT_SLUG}}`.
167 linhas. Autor: {{AUDITOR}}.
