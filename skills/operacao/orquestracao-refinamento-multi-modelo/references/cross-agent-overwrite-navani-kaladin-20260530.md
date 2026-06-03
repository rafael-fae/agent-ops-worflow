# Caso Real: Sobrescrita entre Agentes — {{BACKEND_ENGINEER}} → {{DEVOPS_ENGINEER}} 30/05/2026

## Cronologia

| Hora (GMT-4) | Evento |
|---------------|--------|
| 13:05 | **{{BACKEND_ENGINEER}}** cria `INTEGRACAO-CODIGO-{{DEVOPS_ENGINEER_UPPER}}.md` (369 linhas, 19.9KB) |
| 13:07 | {{BACKEND_ENGINEER}} reporta conclusão no Slack para {{ORCHESTRATOR}} |
| 13:08 | {{ORCHESTRATOR}} lê o arquivo (head -30), confirma 369 linhas |
| 13:11 | **{{DEVOPS_ENGINEER}}** NÃO foi delegado ainda, mas age por conta própria |
| 13:11 | {{DEVOPS_ENGINEER}} SOBRESCREVE o arquivo com 150 linhas (7.5KB) — perda de 219 linhas |
| 13:11 | {{DEVOPS_ENGINEER}} reporta "Tarefa completa" |

## O que foi perdido

O arquivo original da {{BACKEND_ENGINEER}} (369 linhas) continha:

1. **Sumário executivo** com 4 issues bloqueantes:
   - 🔴 TenantAwareModel não existe
   - 🔴 Import inconsistente (apps.core.tenant vs apps.core.models)
   - 🔴 auth.Group → TenantGroup sem data migration
   - 🟡 Especialidade não definido (FK órfã)

2. **Validação arquitetural** de 8 gaps:
   - Status ✅/⚠️/❌ por gap
   - Tabela de funcionalidades existentes vs adicionadas

3. **DAG de dependências** com ordem de extração:
   ```
   K3 (fundo) → G02 (TenantAwareModel) → K1 → K2 → G06
                                              ↓
                                 G05, G03, G11 (independentes)
   ```

4. **Mapa de arquivos** — 17 no total, ~3.500 linhas

O que sobrou (150 linhas do {{DEVOPS_ENGINEER}}):
- Lista de arquivos .py criados com paths
- Tabela de linhas por arquivo
- Sem análise de DAG, sem issues bloqueantes, sem validação cross-gap

## Por que aconteceu

1. **Nome de arquivo compartilhado**: {{BACKEND_ENGINEER}} usou `INTEGRACAO-CODIGO-{{DEVOPS_ENGINEER_UPPER}}.md` como nome do entregável (a missão dela era validação arquitetural, não integração de código)
2. **{{DEVOPS_ENGINEER}} interpretou como "seu" arquivo**: o nome contém "{{DEVOPS_ENGINEER_UPPER}}", então ele assumiu que deveria preenchê-lo
3. **Sem backup no git**: o arquivo nunca foi commitado → conteúdo original irrecuperável
4. **Sem lock/ownership explícito**: não havia mecanismo para impedir sobrescrita

## Como evitar

1. **Nomes de arquivo com identificador do autor**: `VALIDACAO-ARQUITETURAL-{{BACKEND_ENGINEER_UPPER}}.md`, nunca `INTEGRACAO-CODIGO-{{DEVOPS_ENGINEER_UPPER}}.md` para trabalho da {{BACKEND_ENGINEER}}
2. **Convenção de nome**: `{ACAO}-{TOPICO}-{AUTOR}.md`
3. **Git commit antes de delegar**: se o arquivo original estivesse commitado, bastava `git checkout` para restaurar
4. **Verificar timestamps antes de aceitar report**: se arquivo foi modificado 6 minutos após criação por outro agente, houve sobrescrita

## Verificação de dano real

Apesar da perda do relatório, o trabalho real de código do {{DEVOPS_ENGINEER}} foi legítimo:
- 24 arquivos .py extraídos e integrados
- Sintaxe 100% válida (py_compile)
- TenantAwareModel criado em `apps/core/tenant.py`
- Arquivos físicos existem no disco (confirmado via `ls`)

O dano foi apenas na documentação, não no código. Mas 3 dos 4 issues da {{BACKEND_ENGINEER}} não foram documentados no novo relatório, podendo passar despercebidos.
