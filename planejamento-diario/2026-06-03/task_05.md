# Task 05 — Criar scripts de automação genéricos

**Wave:** 2 (Sanitização)
**Prioridade:** 🔴
**Ferramenta:** Gemini CLI
**Depende de:** task_02

---

## Contexto

Temos scripts de automação (cron, rotação de chaves, etc.) que são úteis para
qualquer time multi-agente. Precisamos criar versões genéricas e documentadas.

---

## Instruções

Criar em `agent-ops-workflow/scripts/`:

### 1. `scripts/setup-workflow.sh`

Script de setup inicial que:
- Cria a estrutura `planejamento-diario/` no projeto do usuário
- Copia os templates para a pasta do dia atual
- Cria INDICE.md inicial
- Permite personalizar time/nome do projeto via variáveis

```bash
# Uso:
# ./scripts/setup-workflow.sh ~/meu-projeto "Meu Time" "Meu Projeto"
```

### 2. `scripts/gerar-plano-diario.sh`

Script para cron job (execução automática):
- Lê template PLANO.md.tpl
- Substitui placeholders pela data atual
- Cria pasta YYYY-MM-DD/
- Gera PLANO.md + tasks esqueleto
- Ideal para agendar às 05:00 todo dia

```bash
# Cron sugerido:
# 0 5 * * * /caminho/scripts/gerar-plano-diario.sh ~/projeto
```

### 3. `scripts/validate-workflow.sh`

Script de validação/auditoria:
- Verifica se INDICE.md existe e está atualizado
- Verifica se tasks têm checkboxes preenchidos
- Verifica se PLANO.md reflete status reais
- Relatório de saúde do workflow

```bash
# Uso:
# ./scripts/validate-workflow.sh ~/meu-projeto
# → "3 tasks sem checklist preenchido" / "INDICE.md desatualizado"
```

### 4. `scripts/rotate-key.sh` (genérico)

Script de rotação de chaves (baseado no nosso existente):
- Gera nova chave SSH/GP
- Atualiza config
- Backup da chave antiga

---

## Checklist

- [x] setup-workflow.sh criado com variáveis configuráveis
- [x] gerar-plano-diario.sh criado com suporte a cron
- [x] validate-workflow.sh criado com relatório
- [x] rotate-key.sh genérico criado
- [x] Scripts comentados em português
- [x] Todos com `set -euo pipefail` e tratamento de erro
- [x] `scripts/README.md` com instruções de uso de cada script

---

## Restrições

- NENHUMA referência a Rafael, Roshar, Oeste Gestão
- Comentários explicativos em português
- Tratamento de erro em todos os scripts

---

## Conclusão

**Agente:** Dalinar (via subagentes)
**Concluída em:** 03/06/2026 ~10:40
**Motor utilizado:** deepseek-v4-flash (subagente)
**Observações:**
- setup-workflow.sh — 12.3KB, interativo + env vars, criação da estrutura
- gerar-plano-diario.sh — 10.2KB, cron-ready, --tasks=N, --force, logging
- validate-workflow.sh — 14.7KB, 9 verificações, --fix, exit codes
- rotate-key.sh — 10.5KB, ed25519, backup, --host, --show
- scripts/README.md — 8.3KB, documentação completa de todos os scripts
- Todos passam bash -n (syntax check), set -euo pipefail
- Zero referências a Roshar/Rafael/Oeste Gestão
