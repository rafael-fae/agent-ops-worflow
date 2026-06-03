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

- [ ] setup-workflow.sh criado com variáveis configuráveis
- [ ] gerar-plano-diario.sh criado com suporte a cron
- [ ] validate-workflow.sh criado com relatório
- [ ] rotate-key.sh genérico criado
- [ ] Scripts comentados em português
- [ ] Todos com `set -euo pipefail` e tratamento de erro
- [ ] `scripts/README.md` com instruções de uso de cada script

---

## Restrições

- NENHUMA referência a Rafael, Roshar, Oeste Gestão
- Comentários explicativos em português
- Tratamento de erro em todos os scripts

---

## Conclusão

`TBD`
