# Blueprint Filler {{GIT_OPS}}s — Catálogo de Detecção

> Quando Gemini gera documentos longos com contexto insuficiente, produz templates numerados em vez de conteúdo real. Este catálogo documenta os padrões conhecidos e comandos de detecção.

---

## Padrão 1: Tabela_Referencia_N (Modelos de Dados)

**Onde:** Blueprint Seção 3 (Modelos de Dados)
**Aparência:**
```
#### Modelo `Tabela_Referencia_1` (App Core/Agenda)
- `nome_identificador_1` (CharField, max_length=255): Identificação de negócios...
- `status_operacional_1` (BooleanField, default=True): Reflete exclusão lógica...
```
**Comando:** `grep -c 'Tabela_Referencia_' BLUEPRINT.md`
**Threshold:** > 20 = filler. Nomes genéricos `nome_identificador_N`, `status_operacional_N`.

---

## Padrão 2: Role_N (Matriz RBAC)

**Onde:** Blueprint Seção 6 (Segurança / RBAC)
**Aparência:**
```
- **Role_0**: Administrador Clínico Nível 0
  - Permissões Inclusas: `['agenda.view', 'agenda.edit', 'pacientes.full', 'financeiro.view_0']`
- **Role_1**: Administrador Clínico Nível 1
  - Permissões Inclusas: `['agenda.view', 'agenda.edit', 'pacientes.full', 'financeiro.view_1']`
```
**Comando:** `grep -c 'Role_[0-9]' BLUEPRINT.md`
**Threshold:** > 20 = filler. Nomes genéricos "Administrador Clínico Nível N", permissões idênticas com sufixo numérico.

---

## Padrão 3: Pipeline Step N (DevOps / CI/CD)

**Onde:** Blueprint Seção 9 (DevOps e Deploy)
**Aparência:**
```
### 9.2 Estratégia CI/CD (Pipeline Step 0)
1. **Lint e Type Checking**: Ocorre no GitHub Actions executando Ruff e Pyright.
2. **Testes Unitários**: Pytest validando as lógicas de isolamento tenant e rulesets (Step validation 0).
...
### 9.2 Estratégia CI/CD (Pipeline Step 1)
[mesmo conteúdo, só muda o número]
```
**Comando:** `grep -c 'Pipeline Step' BLUEPRINT.md`
**Threshold:** > 5 = filler. Mesmo pipeline repetido N vezes com "Step validation N".

---

## Padrão 4: ETL Mapping N (Migração de Dados)

**Onde:** Blueprint Seção 11 (Migração G03)
**Aparência:**
```
**ETL Mapping 1**
- Tabela Origem: `dontus_legacy_table_1`
- Target (Oeste): `apps.models.TargetModel_1`
- Transformação de Dado: Conversão de datas BR para ISO 8601...
```
**Comando:** `grep -c 'ETL Mapping' BLUEPRINT.md`
**Threshold:** > 20 = filler. Mapeamentos genéricos com `dontus_legacy_table_N` → `TargetModel_N`.

---

## Padrão 5: Implementação Técnica Categoria N (Roadmap)

**Onde:** Blueprint Seção 12 (Roadmap Técnico)
**Aparência:**
```
**Sprint 1: Implementação Técnica Categoria 1**
- **Task 1.1**: Estruturar serializers base e testes (Esforço: Médio).
- **Task 1.2**: Criar views HTMX interativas usando os partials do Design System (Esforço: Alto).
- **Task 1.3**: Revisão de Segurança do OWASP (Injection, XSS, CSRF).
- **Entregável 1**: Módulo 1 perfeitamente testado com coverage > 85%...
```
**Comando:** `grep -c 'Implementação Técnica Categoria' BLUEPRINT.md`
**Threshold:** > 10 = filler. 100 sprints idênticas com tasks genéricas.

---

## Protocolo de Auditoria Rápida (30 segundos)

```bash
F=docs/BLUEPRINT-ARQUITETURAL.md
echo "Seção 3 (Modelos): $(grep -c 'Tabela_Referencia_' $F) — $( [ $(grep -c 'Tabela_Referencia_' $F) -gt 20 ] && echo '❌ FILLER' || echo '✅ OK' )"
echo "Seção 6 (RBAC):    $(grep -c 'Role_[0-9]' $F) — $( [ $(grep -c 'Role_[0-9]' $F) -gt 20 ] && echo '❌ FILLER' || echo '✅ OK' )"
echo "Seção 9 (DevOps):  $(grep -c 'Pipeline Step' $F) — $( [ $(grep -c 'Pipeline Step' $F) -gt 5 ] && echo '❌ FILLER' || echo '✅ OK' )"
echo "Seção 11 (Migra):  $(grep -c 'ETL Mapping' $F) — $( [ $(grep -c 'ETL Mapping' $F) -gt 20 ] && echo '❌ FILLER' || echo '✅ OK' )"
echo "Seção 12 (Roadmap):$(grep -c 'Implementação Técnica Categoria' $F) — $( [ $(grep -c 'Implementação Técnica Categoria' $F) -gt 10 ] && echo '❌ FILLER' || echo '✅ OK' )"
```

---

## Estratégia de Correção

**NÃO regere o documento inteiro.** Apenas as seções com filler. Procedimento:

1. Identificar seções com filler usando os comandos acima
2. Criar prompt focado para CADA seção problemática (ex: "gere APENAS a Seção 6 do Blueprint com a matriz RBAC real extraída do PRD")
3. Alimentar o prompt com:
   - PRD (para regras de negócio e modelos reais)
   - Código fonte existente (apps/core/models.py, etc.)
   - Seções boas do Blueprint (para contexto arquitetural)
4. Substituir apenas o bloco de filler pela nova seção gerada
5. Re-verificar com os mesmos comandos grep

**Caso real ({{PROJECT_NAME}}, 31/05/2026):** Blueprint de 7.004 linhas tinha filler nas 5 seções. Seção 12 foi corrigida com prompt focado de 161 linhas → 15 sprints reais substituíram 100 sprints template. Arquivo final: 6.806 linhas, todas reais.
