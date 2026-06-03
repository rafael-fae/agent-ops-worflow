---
name: multi-tenant-discovery-re
description: "Metodologia para descobrir e documentar o modelo real de multi-tenant em sistemas SaaS legados durante engenharia reversa — incluindo como diferenciar database-per-tenant de shared-db, identificar FKs de tenant, e evitar suposições arquiteturais erradas."
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Multi-Tenant Discovery during Engineering Reverse (RE)

## Gatilho

- Durante a engenharia reversa de um sistema SaaS para clonar
- Você encontra `id_empresa`, `id_clinica`, `iddontus`, `tenant`, `cliente_id` ou similar em URLs/payloads
- O cliente menciona "multi-tenant" ou "várias clínicas/empresas" durante o levantamento

## ⚠️ A Armadilha (Aprendida na Prática com o Dontus)

**NUNCA pergunte ao cliente sobre o modelo de tenant sem antes verificar os dados capturados.**

Regra de ouro: **a resposta quase sempre está nos dados que você já capturou.** Perguntar ao cliente antes de verificar os dados é uma falha de RE — o cliente paga pela engenharia reversa, não para ser consultor de arquitetura.

No {{PROJECT_NAME}}, o time preparou 3 perguntas para {{COMMANDER}} sobre multi-tenant. Ele respondeu: *"não conseguimos identificar como a Dontus trata o multi tenant?"* — corretamente apontando que a resposta estava nos dados já capturados.

**O erro original:** Assumimos shared-db baseado no `id_clinica` visível nos endpoints, sem verificar o modelo completo nos dados do `var src`.

**Onde encontrar a resposta (checklist antes de perguntar ao cliente):**

1. **`var src` / objetos JS das páginas capturadas** — Procure por `ConfiguracaoAcesso.DataBase`, `DataBase`, `iddontus`, `IDDontus`
2. **Página de login** — Campos como `iddontus` indicam database-per-tenant (o tenant é conhecido ANTES do login)
3. **Páginas de "TrocarCliente" / "TrocarClinica"** — Confirmam que o usuário pode operar em múltiplos contextos DENTRO do mesmo tenant
4. **API payloads reais** — Verifique se `idClinica` é um parâmetro de API (indicando FK organizacional) ou o único isolamento (indicando shared-db)
5. **Config/Auth tokens** — Procure nos JSONs capturados por campos como `DataBase`, `ConnectionString`, `Server`

Só pergunte ao cliente se TODAS essas fontes forem inconclusivas.

## O Processo de Descoberta em 4 Passos

### Passo 1 — Crawl Inicial: Identificar Padrões de Tenant

Durante o crawl autenticado do sistema, procure em **todos os lugares**:

**Em URLs:**
```
/Agendamento?IDClinica={{DONTUS_CLINICA_ID}}
/CaixaDiario?iddontus={{DONTUS_CLINICA_ID}}
/NFSeConfig?iddontus={{DONTUS_CLINICA_ID}}
```

**Em payloads POST:**
```
POST /Agendamento/Save
Payload: IDClinica={{DONTUS_CLINICA_ID}}&IDPaciente=48&...
```

**Em objetos JavaScript:**
```javascript
var src = {
    IDClinica: {{DONTUS_CLINICA_ID}},
    IDDontus: {{DONTUS_CLINICA_ID}},
    ko_Clinicas: [{ID: {{DONTUS_CLINICA_ID}}, Nome: "Oeste Odontologia"}]
};
```

**No HTML renderizado:**
- Headers/menus com seletor de clínica ("Trocar Clinica")
- Campos hidden: `<input type="hidden" id="IDClinica" value="{{DONTUS_CLINICA_ID}}" />`
- Observables Knockout.js: `var ko_Clinicas = ko.observableArray(...)`

### Passo 2 — Mapear FKs de Tenant

Para **cada entidade** capturada, classifique o relacionamento com tenant:

| Tipo | Descrição | Exemplo Dontus | Qtd |
|------|-----------|----------------|:---:|
| ✅ FK direta | Entidade tem coluna `id_clinica`/`iddontus` | Usuario, Funcionario, Agendamento | 10+ |
| ⚠️ Herdada | Entidade herda tenant via FK parent | OrcamentoItem → Orcamento, NFSe → NFSeConfig | 8+ |
| ❓ Lookup | Precisa decidir se é global ou por tenant | Procedimento, Grupo, FormaPagamento | 11+ |

### Passo 3 — Verificar as Evidências nos Dados Capturados (ANTES de perguntar ao cliente)

Antes de preparar qualquer pergunta para o cliente, consulte as **fontes primárias** já capturadas:

| Fonte | O Que Procurar | O Que Revela |
|-------|---------------|--------------|
| `var src` / objetos JS em páginas HTML capturadas | `ConfiguracaoAcesso.DataBase`, `DataBase`, `ConnectionString` | **Database-per-tenant** (se tiver nome `s{id}` ou similar) |
| Página de login (`/Login`) | Campos `iddontus`, `id_empresa`, `tenant_id` | Tenant separado por banco (login começa com ID) |
| Página de troca de contexto (`/TrocarClinica`, `/SwitchTenant`) | Botão/tabela para selecionar outra clínica | Multi-clínica DENTRO do mesmo tenant |
| Payloads de API (Playwright captures) | Parâmetro `idClinica` vs `iddontus` | `idClinica` = FK organizacional (dentro do tenant), `iddontus` = tenant |
| Objeto Usuario ($root.Usuario no KO) | `Clinicas[]`, `ListAcessoUsuarioClinica` | Array de clínicas acessíveis = multi-clínica |

**Exemplo real (Dontus — DASHBOARD_src.json):**
```json
"ConfiguracaoAcesso": {
    "ID": {{DONTUS_CLINICA_ID}},
    "DataBase": "s{{DONTUS_CLINICA_ID}}",       // ← Database-per-tenant DIRECTAMENTE visível
    "Versao": "Essencial"
}
"Usuario": {
    "IDClinica": 1,              // ← FK organizacional, não de isolamento
    "Clinicas": [],               // ← Array de clínicas (multi-clínica)
    "Clinica": { "IDMatriz": 1 } // ← Clínica matriz dentro do tenant
}
```

**Regra:** Se o dado capturado contém `ConfiguracaoAcesso.DataBase` com padrão `s{id}` → **database-per-tenant confirmado**. As perguntas ao cliente são desnecessárias.

**Só passe para o Passo 4 se TODAS as fontes acima forem inconclusivas.**

### Passo 4 — (Somente se necessário) Testar Hipóteses com o Cliente

Se os dados capturados não revelarem o modelo, prepare perguntas objetivas:

```
Hipótese A — Shared-DB (coluna tenant_id)
  Prós: Simples, consultas cross-tenant possíveis
  Contras: Vazamento de dados, complexidade de middleware
  Pergunta: "Os dados de diferentes clínicas ficam no mesmo banco?"

Hipótese B — Database-Per-Tenant
  Prós: Isolamento total, sem middleware, sem risco de vazamento
  Contras: Migrações precisam rodar em N bancos, sem cross-tenant
  Pergunta: "Cada ID Dontus/Cliente tem seu próprio banco? Ou tudo no mesmo banco?"

Hipótese C — Schema-Per-Tenant
  Prós: Isolamento dentro do mesmo banco
  Contras: Complexidade de migrations, difícil de gerenciar
```

**Perguntas obrigatórias para o cliente (aprendido na prática):**

1. **"No login, o que o usuário digita primeiro?"** — Se digitar um ID/tenant antes de usuário/senha, é database-per-tenant ou schema-per-tenant
2. **"Um profissional pode atender em mais de uma clínica?"** — Se sim, as clínicas compartilham cadastros DENTRO do mesmo tenant
3. **"Procedimentos/Grupos são os mesmos para todas as clínicas?"** — Dentro de um tenant, lookup tables são compartilhadas
4. **"Cada ID Dontus tem seu próprio banco?"** — A pergunta direta, depois de entender o fluxo

### Passo 4 — Documentar a Decisão no Blueprint

Após a resposta do cliente, documente a **decisão arquitetural** no Blueprint:

```markdown
## Multi-Tenant Architecture

### Modelo: Database-Per-Tenant (confirmado por {{COMMANDER}})

Cada "ID Dontus" = um banco PostgreSQL separado.
Dentro de cada banco, `clinica` é FK organizacional (não de isolamento).

### Estrutura
┌─ ID Dontus {{DONTUS_CLINICA_ID}} (Oeste)
│  ├── Banco: oeste_gestao_{{DONTUS_CLINICA_ID}}
│  │   ├── Clínica A (Matriz)
│  │   ├── Clínica B (Filial)
│  │   ├── Profissionais (compartilhados entre clínicas)
│  │   ├── Procedimentos (compartilhados)
│  │   └── Documentos (compartilhados)
│
├─ ID Dontus 123456 (outro grupo)
│  ├── Banco: oeste_gestao_123456 (completamente isolado)

### Implicações
- Simples: sem middleware de tenant, sem filtros WHERE tenant_id
- Lookup tables são globais DENTRO de cada banco
- Profissionais vinculados a múltiplas clínicas via tabela pivot
- Migrações Django precisam rodar em N bancos
- Conexão roteada por subdomínio ou parâmetro de login
```

## ⚠️ Nuance Crítica: O Que Acontece com `clinica_id` no Database-Per-Tenant

**Quando a decisão é database-per-tenant, a FK `clinica` MUDA DE SIGNIFICADO:**

| No shared-db (assumido) | No database-per-tenant (real) |
|-------------------------|-------------------------------|
| `clinica_id` = **barreira de isolamento** (sem ela, vaza dados entre tenants) | `clinica_id` = **tag organizacional** (dentro do banco de um tenant, várias clínicas) |
| Toda query PRECISA de `WHERE clinica_id = X` | Queries NÃO precisam filtrar por clinica — o banco já isola por tenant |
| Middleware de tenant é obrigatório | **Zero middleware** — cada deploy é um banco separado |
| Lookup tables duplicadas por clínica | Procedimento, Grupo, Especialidade são **compartilhados no tenant** |
| `clinica_id` em TODAS as tabelas | `clinica_id` só onde fizer sentido organizacional |

**Regra de ouro que aprendemos na prática:**
> Se o login começa com um "ID de grupo" (ID Dontus, ID Cliente, ID Empresa) ANTES de usuário/senha → é database-per-tenant.
> Se o login é só usuário/senha e a clínica é selecionada DEPOIS → pode ser shared-db.

**Quando o cliente diz "cada ID tem seu próprio banco":**
- `clinica` vira FK opcional/organizacional, não de isolamento
- 15+ entidades lookup (Procedimento, Grupo, etc.) deixam de precisar de clinica FK
- A complexidade do schema cai drasticamente
- Middleware de tenant some do código

**Exemplo real ({{PROJECT_NAME}}):**
- **Antes:** Schema tinha `clinica = ForeignKey(Clinica)` em 29 entidades, middleware de tenant planejado
- **Depois (database-per-tenant):** `clinica` FK só em 14 entidades (escopo clínica), 15 lookup tables sem clinica FK, zero middleware

## Database-Per-Tenant × Shared-DB — Guia de Decisão

| Fator | Database-Per-Tenant | Shared-DB com clinica_id |
|-------|:-------------------:|:------------------------:|
| Isolamento de dados | ✅ Total | ⚠️ Parcial (query errada vaza) |
| Simplicidade de código | ✅ Sem middleware | ❌ Middleware + filtros em toda query |
| Migrações | ❌ Roda em N bancos | ✅ Roda uma vez |
| Cross-tenant queries | ❌ Impossível | ✅ Possível |
| Custo DB | ❌ N bancos | ✅ 1 banco |
| Backup/restore | ✅ Por tenant | ❌ Tudo ou nada |
| Ideal para | Clínicas/grupos independentes | Franquias com dados centralizados |

## Quando Database-Per-Tenant é a Escolha Óbvia

1. **Login começa com um "ID de grupo"** (ex: "digite seu ID Dontus")
2. **Cada grupo tem suas próprias clínicas** independentes
3. **Profissionais podem atender em múltiplas clínicas** do mesmo grupo
4. **Lookup tables (procedimentos, documentos) são compartilhadas** entre clínicas do grupo
5. **Grupos diferentes NÃO compartilham nada**
6. **O cliente diz explicitamente** "cada ID é um banco separado"

Neste cenário, faça database-per-tenant. É mais simples, mais seguro e mais alinhado com o modelo de negócio.

## ⚠️ Pitfalls Conhecidos

1. **Não assuma shared-db só porque viu `id_clinica`** — Pode ser FK organizacional dentro de um banco de tenant, não FK de isolamento
2. **Profissionais multi-clínica é a pista mais forte** — Se profissionais podem atender em várias clínicas, as clínicas COMPARTILHAM cadastros (lookup tables são globais dentro do tenant)
3. **O cliente nem sempre sabe explicar tecnicamente** — {{COMMANDER}} sabia que era "cada ID Dontus tem seu próprio banco", mas não usou esses termos. Faça perguntas de negócio, não técnicas
4. **Documente a decisão no PRD como divergência deliberada** — Se o original usa shared-db e você vai de database-per-tenant, ou vice-versa, registre como decisão arquitetural

## Exemplo Real ({{PROJECT_NAME}} / Dontus)

**Contexto:** Durante RE do Dontus, o crawl revelou `IDClinica={{DONTUS_CLINICA_ID}}` em TODOS os endpoints. O time assumiu shared-db com clinica_id. Passou horas documentando 29 entidades com `clinica = ForeignKey` e preparou 3 perguntas para {{COMMANDER}} sobre o modelo multi-tenant.

**Correção de rota:** {{COMMANDER}} respondeu: *"não conseguimos identificar como a Dontus trata o multi tenant?"* — a resposta JÁ ESTAVA nos dados capturados:

- `DASHBOARD_src.json` → `ConfiguracaoAcesso.DataBase = "s{{DONTUS_CLINICA_ID}}"` (database-per-tenant)
- Página de login → campo `iddontus` (tenant digitado antes do login)
- `TrocarClinica.json` → funcionalidade de trocar clínica (multi-clínica dentro do tenant)
- API payloads → `idClinica` como parâmetro, não `iddontus` (FK organizacional)

**Lições registradas (corrigidas na prática):**
- ✅ **Antes de perguntar ao cliente, verifique os dados capturados** — `var src`, login page, TrocarClinica
- ✅ **`ConfiguracaoAcesso.DataBase` é a prova definitiva** de database-per-tenant
- ✅ **Login com `iddontus` antes de usuário/senha = database-per-tenant**
- ✅ **Profissionais multi-clínica confirmam compartilhamento dentro do tenant**
- ❌ **Não pergunte ao cliente o que pode ser descoberto nos dados de RE**

**Impacto:** O schema foi simplificado — sem middleware de tenant, lookup tables ficam globais dentro do banco. E {{COMMANDER}} não precisou ser interrompido para decisões que os dados já respondiam.