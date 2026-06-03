# Anexo de Governança — {{PROJECT_SLUG}} (31/05/2026)

**Contexto:** Segunda passada de {{AUDITOR}} na auditoria da pasta {{PROJECT_SLUG}}, com 4 artefatos: entrelaçamento, risco, delegação, horas.

## 1. Mapa de Entrelaçamento

| Commit | Tipo | Docs entrelaçados |
|:------:|:----:|:-----------------:|
| `8ad50f4` | 🔴 MISTURADO | 30+ .md (deep dives, waves, refinamentos) |
| `737151e` | 🖥️ SÓ CÓDIGO | 0 |
| `d682c73` | 🟢 SÓ DOCS | G11-PROVISION-TENANT.md |
| `b3b455e` | 🔴 MISTURADO MASSIVO | 40+ .md + design_system + ADRs |

Reset simples destrói ~70% dos docs. Inviável sem extração seletiva.

## 2. Classificação de Risco

| Risco | Qtd | Módulos |
|:-----:|:---:|---------|
| 🟢 Alinhado | 10 | Core Models, K3 Router, Agenda, Segurança, Cache, DR, Provisionamento, Event Bus, Migração Dontus, Scripts |
| 🟡 Parcial | 7 | CRC, Financeiro, Orçamento, Multi-Tenant Models, Design System, PgBouncer, HTMX Wire-up |
| 🔴 Crítico | 0 | Nenhum |

## 3. Cadeia de Delegação

Todos os 6 commits são de `{{COMMANDER}}-fae`. Nenhum passou por PR ou code review. A falha não é "agente desobedeceu" mas "ausência de esteira de review".

## 4. Estimativa de Horas

~350-400h homem (±30%) + ~$230-720 USD em custo de API.

## Recomendação (Opção D)

1. Cria `develop` em HEAD (preserva código)
2. Reseta `main` para `b1c8355`
3. Cherry-pick docs-only: `d682c73`, `f1641ed`, `a919422`
4. Extrai docs de `8ad50f4` e `b3b455e` seletivamente
5. PR gate obrigatório

## Artefato Original

`docs/refinamentos/ANEXO-AUDITORIA-GOVERNANCA.md` no repositório `{{PROJECT_SLUG}}`.
235 linhas. Autor: {{AUDITOR}} (DeepSeek v4 Flash).
