---
name: clone-build-orchestration
description: "Estratégia de transição do mapeamento → implementação de clone SaaS com múltiplos agentes. Decomposição em waves paralelas, otimização de dependências (models-first), e coordenação de bloqueios entre agentes."
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Clone Build Orchestration — Transição Mapeamento → Implementação

## Gatilho

- Mapeamento exaustivo do sistema original concluído (~100% páginas) — **ou em andamento**
- PRD/Blueprint registrado
- Equipe disponível para paralelizar

## ⚠️ Regra Crítica: Há DOIS Sinais Verdes Diferentes

**Isso foi aprendido na prática quando {{COMMANDER}} parou toda a equipe por interpretação errada.**

| Sinal Verde | Autoriza | Exemplo de frase de {{COMMANDER}} |
|---|---|---|
| **RE / Levantamento** | Crawling, engenharia reversa, documentação, análise, schemas, state machines, blueprint | "ótimo, podemos fazer isso em 3 waves" — ISSO NÃO É SINAL VERDE DE IMPLEMENTAÇÃO |
| **Implementação** | Codificar models, settings, views, templates, CRUDs, deploy | "sinal verde", "autorizo", "pode implementar", "vai", "partiu codificar" |

**Frases que NÃO são sinal verde de implementação (aprendido na prática):**
- "ótimo, podemos fazer isso em X waves" → É autorização para RE/levantamento apenas
- "não temos pressa" → Confirma que é RE, não implementação
- Definir waves, planejar, estimar → Tudo RE

Se {{COMMANDER}} disser algo como "ótimo, acredito que já devemos iniciar...", tratar como **RE autorizada**, não implementação. Se houver dúvida, perguntar explicitamente: "{{COMMANDER}}, autorização para RE (levantamento de dados) ou para implementação (codificar)?"
 
## Objetivo

Estruturar a implementação de um clone SaaS em waves paralelas, minimizando bloqueios entre agentes e entregando valor rapidamente. A implementação só começa **após ciclo completo de RE + auditoria + Sinal Verde explícito de implementação**.

## Fase 0 — Engenharia Reversa (RE) em Paralelo

Antes de qualquer implementação, execute **RE completa** com 3 trilhas paralelas:

```
RE ├── Trilha A — API/Dados (agente técnico)
│   ├── Schema de entidades (models)
│   ├── Catálogo de endpoints (via Playwright/HTTP intercept)
│   └── Máquinas de estado (workflows, transições)
│
├── Trilha B — UI/Componentes (agente de UI)
│   ├── Mapeamento de modais reais (deduplicar clones)
│   ├── Padrões de binding/framework (KO, React, Alpine)
│   └── Taxonomia de componentes reutilizáveis
│
└── Trilha C — Dados/Infra (agente de dados)
    ├── Crawl completo de controllers
    ├── Schema multi-tenant
    ├── Dependências entre módulos
    └── Blueprint de infraestrutura
```

### RE — Descoberta de Multi-Tenant (aprendido na prática)

**⚠️ IMPORTANTE: A armadilha do multi-tenant já custou horas extras de trabalho. Leia a skill dedicada antes de começar:**

➡️ **Skill:** `multi-tenant-discovery-re` — Metodologia completa para descobrir o modelo real de tenant em sistemas SaaS legados

**Durante a RE do Dontus, {{DEVOPS_ENGINEER}} descobriu que o sistema é multi-tenant com `iddontus` + `id_clinica` em TODOS os endpoints. O time inicialmente assumiu shared-db com `clinica_id` — mas {{COMMANDER}} revelou que é database-per-tenant. Isso simplificou drasticamente a arquitetura.**

**Resumo dos passos essenciais:**

1. **Inspecione todos os payloads** (POST/GET params) — procure por `idClinica`, `iddontus`, `tenant`, `cliente`, `empresa`, `clinica`
2. **Verifique o header de navegação** — se há seletor de clínica/empresa (ex: "Trocar Clinica")
3. **Analise objetos JS** (`var src`, `ko_Clinicas`) — o tenant costuma aparecer como observable global
4. **Pergunte sobre o FLUXO DE LOGIN** — se o cliente digita um ID antes de usuário/senha, é database-per-tenant
5. **Pergunte sobre PROFISSIONAIS MULTI-CLÍNICA** — se podem atender em várias, as lookup tables são compartilhadas dentro do tenant
6. **Documente FKs** — toda tabela com FK de tenant deve ser identificada na RE (separando FK diretas, herdadas e lookups a decidir)
7. **Apresente ao cliente** — mostre o que encontrou e peça CONFIRMAÇÃO antes de definir a arquitetura

## ⚠️ ARMADILHA: Cobertura Superficial vs Profundidade Real

**Aprendido na prática com {{PROJECT_NAME}} — O time reportou "100% de cobertura" mas só havia mapeado listagens e schemas. {{COMMANDER}} provou que as sub-abas, formulários aninhados e conteúdo dinâmico KO não haviam sido penetrados.**

**O erro:** O time confundiu "URL mapeada" com "página completamente dissecada". Uma URL pode ter 40 sub-abas carregadas via AJAX, modais clicáveis e bindings condicionais — e nosso mapeamento inicial capturou só a casca.

### O Protocolo — Nunca reporte % sem qualificar profundidade

| Tipo de cobertura | O que significa | Exemplo |
|:-----------------|----------------|---------|
| **Superfície** | URL acessada, HTML baixado, estrutura geral identificada | `/Clinica/Edit/1` — sabemos que existe, tem header, tem abas |
| **Profundidade Parcial** | Sub-abas identificadas, alguns bindings extraídos | Sabemos que `#agenda` existe mas não extraímos os bindings de "Configurar Dias da Semana" |
| **Profundidade Total** | Todo conteúdo dinâmico extraído, bindings KO/React catalogados, sub-abas penetradas, formulários aninhados documentados | `#agenda` com bindings de `ConfiguracoesAgendaOnline.AgendaRadioButton`, `Configurar Dias da Semana` com `foreach: HorariosFuncionamentoClinica` |

### Checklist de profundidade — Só considere uma página "completa" quando:

- [ ] **Sub-abas**: Navegou e extraiu cada aba/tab-pane? (Ex: Clinica Edit tem 14+ sub-abas)
- [ ] **Conteúdo dinâmico**: Clicou em cada opção de radio/select para revelar campos ocultos? (Ex: "Agenda Simples/Completa/Desativado" → cada um revela campos diferentes)
- [ ] **Modais aninhados**: Algum botão abre modal que tem outro botão que abre outro modal?
- [ ] **Bindings condicionais**: Documentou `visible`, `enable`, `foreach` que controlam visibilidade?
- [ ] **Links clicáveis**: Botões de "Adicionar", "Criar", "Editar" levam a formulários que precisam ser mapeados separadamente?

### Quando o cliente diz "falta muito para 100%"

Isso é um **sinal de alerta** — significa que o mapeamento atual é superficial demais. Faça:

1. **Peça screenshots** das telas mais profundas (use Gemini Vision para analisar)
2. **Use Playwright com interação** — não só navegação, mas clique em abas, radio buttons, selects
3. **Mapeie sub-abas individualmente** — cada `#hash` na URL pode ser uma página inteira de formulários
4. **Documente a profundidade real** — não reporte 100% se só tem a superfície

### Relato real ({{PROJECT_NAME}})

```
Dia 1: "97% de cobertura" → {{COMMANDER}} envia prints → {{FRONTEND_ENGINEER}} descobre 40 tab-panes no Clinica Edit
Dia 2: Refinamento → 35 perguntas de anamnese (vs 25 estimadas), 187 campos Clinica (vs 6)
Dia 3: Cobertura real de profundidade → ~60% (não 97%)
```

**Regra de ouro:** Se o cliente está dizendo "falta muito", é porque ele conhece a profundidade do próprio sistema. **Acredite nele, não nos seus números.**

### Entregáveis obrigatórios da RE (antes da implementação)

| Camada | Entregável | Volume mínimo |
|--------|-----------|:-------------:|
| Dados | Schema de entidades com tipos Django e FKs | 26+ entidades |
| API | Catálogo de endpoints (100+ esperado) | 114 endpoints |
| Estados | Máquinas de estado (NFSe, Orçamento, Agendamento, pipeline de lead) | 4+ máquinas |
| UI | Matriz de componentes reais vs aparentes | 72+ modais únicos identificados |
| Componentes | Padrões de binding mapeados para stack-alvo | 22+ padrões |
| Infra | Blueprint de infraestrutura (Docker, CI/CD, backup, domínios) | 10+ tópicos |
| Dados ER | Modelo entidade-relacionamento com diagrama | 39+ entidades |
| Módulos | Grafo de dependências entre módulos | 14+ módulos |
| Blueprint | Documento consolidado com stack, módulos, divergências, riscos | 12 seções |
| Auditoria | Dashboard de cobertura por agente | 16/16 entregáveis |

Após todos os entregáveis, **time entra em standby** aguardando:

### Protocolo de Consolidação de Auditoria (aprendido na prática)

Quando múltiplos agentes auditam o mesmo sistema, é **comum** que os números de cobertura divirjam. Exemplo real desta conversa:

| Auditor | Cobertura APIs | Cobertura Multi-Tenant | Cobertura Geral |
|---------|:-------------:|:----------------------:|:---------------:|
| {{AUDITOR}} | 100% | 60% (3 perguntas) | 93% |
| {{BACKEND_ENGINEER}} | 85% (POST faltando) | 70% (29 entidades categorizadas) | 97% |

**Protocolo para resolver:**

1. **Não ignore a divergência** — Ambos os números têm mérito
2. **Compare a granularidade** — Quem foi mais fundo? {{BACKEND_ENGINEER}} categorizou 29 entidades individualmente vs {{AUDITOR}} com visão transversal
3. **Identifique a métrica mais conservadora** — APIs 85% ({{BACKEND_ENGINEER}}) é mais preciso que 100% ({{AUDITOR}}) porque {{BACKEND_ENGINEER}} descobriu que POST de escrita não foram capturados
4. **Consolide com honestidade** — Use o número mais conservador de cada camada, não a média
5. **Documente o gap residual** — Os 3% restantes não são erro, são decisões de negócio que só o cliente pode dar

**Resultado final:** {{AUDITOR}} reconheceu publicamente que os dados da {{BACKEND_ENGINEER}} eram mais precisos ("Relatório da {{BACKEND_ENGINEER}} é mais preciso que o meu em pontos críticos") e consolidou ambos. A cobertura final de ~97% reflete a análise mais granular, não a mais otimista.

**Este protocolo se aplica SEMPRE que:**
- Dois ou mais agentes auditarem o mesmo sistema independentemente
- Os números de cobertura divergirem
- Um agente tiver granularidade de análise e outro visão transversal
1. Revisão do {{ORCHESTRATOR}}
2. Revisão do {{COMMANDER}}/{{COMMANDER}}
3. Sinal Verde explícito de implementação

### Protocolo de Standby após RE

Quando o time terminar a RE e estiver aguardando decisão:

1. **Todo mundo para.** Nenhum código, nenhum model, nenhuma settings.
2. **Documente a parada:** "Time em standby. 16/16 entregáveis. Zero pendência."
3. **Ofereça ao cliente:** "Quer revisar agora, agendar call, ou dar sinal verde?"
4. **Não presuma nada.** Nem "ótimo", nem "vamos nessa", nem "podemos fazer em waves" é sinal verde de implementação.

### 🔴 Gap-Filling + Second-Pass Review (Obrigatório antes do Sinal Verde)

**Aprendido na prática ({{PROJECT_NAME}}, 29/05/2026):** {{COMMANDER}} solicitou uma revisão completa com Claude Opus APÓS os 4 deep-dives já terem sido gerados. O padrão de qualidade dele exige que não apenas os gaps conhecidos sejam endereçados, mas que uma varredura de espectro completo busque lacunas que ninguém identificou.

**Protocolo obrigatório antes de reportar "pronto para implementação":**

```
Fase 1 ── Gap-Filling (Modo 2 da skill `orquestracao-refinamento-multi-modelo`)
  ├── Gera deep-dives para gaps prioridade 1-2
  └── Compila SUMMARY-POS-OPUS.md

Fase 2 ── Second-Pass Review (Modo 3 da skill `orquestracao-refinamento-multi-modelo`)
  ├── Trilha A: Arquiteto revisa deep-dives tecnicamente
  ├── Trilha B: Qualidade/Produto roda Opus com TODO o plano
  └── Consolida ambos os relatórios

Fase 3 ── Ajuste do plano
  ├── Incorpora correções dos deep-dives
  ├── Incorpora gaps encontrados na second-pass
  └── Atualiza estimativas se necessário

Fase 4 ── Sinal Verde
  └── {{COMMANDER}} autoriza implementação
```

**Nunca pule a Fase 2.** Uma revisão de espectro completo com Opus pode encontrar gaps críticos que os deep-dives focados (Modo 2) deixaram passar, pois o Modo 2 só cobre gaps PRÉ-identificados no GAPS-REPORT.md. O Modo 3 é uma varredura cega que não depende de suspeitas iniciais.

```
Wave 1 (Fundação) ──┬── Models Core ─────┐ (desbloqueia Wave 2)
                     ├── Settings/Auth     │
                     └── UI Base/Tailwind ─┼── (Wave 3 precisa)
                                           │
Wave 2 (CRUDs Simples) ────────────────────┘ (só precisa dos models)
                        30+ CRUDs independentes
                        Sem regra de negócio complexa
                        Comum: Cadastros (Usuário, Profissional, Procedimento...)

Wave 3 (Complexa) ─── UI + Regras + Dashboard
                     Agendamento, Atendimento, Financeiro, Relatórios
```

## Otimização Crítica — Models-First

**Regra de ouro:** Identifique a dependência mínima que desbloqueia Waves paralelas. Em clones de ERP/SaaS clínico, o gargalo são os **models core**:

| Model | Desbloqueia | Prioridade |
|-------|-------------|:----------:|
| Clinica | Todos os CRUDs | ⭐ Máxima |
| Usuario | Auth + CRUDs | ⭐ Máxima |
| Profissional | Agendamento, Procedimento | ⭐ Máxima |
| Paciente | Agendamento, Financeiro | ⭐ Máxima |
| Procedimento | Agendamento, Financeiro | ⭐ Máxima |
| Convenio | Financeiro | Alta |

O agente da Wave 1 **deve entregar os models core no primeiro lote**, antes de settings/auth/Tailwind. O agente da Wave 2 **não precisa de auth, Tailwind nem templates** para começar — só dos models + serializers.

## Passo a Passo

### 1. Analisar dependências ({{ORCHESTRATOR}})

Identificar a cadeia crítica:
```
Models Core → Settings/DB → Auth JWT → UI Templates
         ↘ CRUDs Simples → Telas CRUD
         ↘ Regras Complexas → Telas Complexas (precisa UI também)
```

### 2. Decompor Wave 1 em sub-tasks ordenadas

1. **Models core** (desbloqueia Wave 2) — prioridade máxima
2. Settings (PostgreSQL, DRF, .env, CORS)
3. Auth JWT + Roles/Permissões
4. Tailwind + templates base (pode ficar por último)

### 3. Delegar com prioridade explícita

Ordem ao agente da Wave 1:
```
<@AGENTE_WAVE1> [SINAL VERDE] AJUSTE DE PRIORIDADE.
Mude a ordem. Wave 2 está bloqueado.
1. Models core PRIMEIRO (desbloqueia Wave 2)
2. Settings depois
3. Auth depois
4. Templates por último
```

### 4. Wave 2 (CRUDs) roda com dependência mínima

O agente de CRUDs só precisa de:
- Models (definição + migrações)
- DRF instalado
- Database configurado

Não precisa esperar: auth, Tailwind, templates, UI base.

### 5. Registrar divergências deliberadas

Durante o mapeamento/build, o cliente pode apontar comportamentos do sistema original que **não devem** ser replicados:
- UX ruins (autocomplete 3-char, modais excessivos, lentidão)
- Regras de negócio que não se aplicam ao novo contexto
- Funcionalidades obsoletas

Registrar em seção `## Divergências Deliberadas` no PRD e em memory.

## Referências

- `references/infra-provisioning-pattern-django.md` — Padrão de artefatos de infra (Docker, nginx, CI/CD, provisionamento) para projetos Django + HTMX + PostgreSQL, estabelecido durante onboarding do {{PROJECT_NAME}}.

## Comunicação no Slack

Quando {{COMMANDER}} aprovar o plano:

```
<@AGENTE_WAVE1> [SINAL VERDE] Wave N — descrição.
1. Subtask 1 (prioridade máxima)
2. Subtask 2
3. ...
```

Para agentes bloqueados:

```
<@AGENTE_BLOQUEADO> Status: aguardando models core de <@AGENTE_WAVE1>.
Enquanto isso: [preparação paralela].
```

## Verificação (Quality Gate)

- [ ] Models core entregues e migrações rodando?
- [ ] Wave 2 desbloqueado?
- [ ] Divergências deliberadas registradas no PRD?
- [ ] .env nunca versionado?
- [ ] Cada app segue padrão: Model → Serializer → ViewSet → URL → Test básico?
- [ ] Cadeia de dependências revista e otimizada?

## Exemplo Real ({{PROJECT_NAME}})

**Contexto:** Mapeamento de 199 páginas do Dontus concluído. PRD v3 registrado. 4 agentes disponíveis.

**Divisão:**
- **Wave 1 ({{BACKEND_ENGINEER}}):** Models core + Settings + Auth JWT + Tailwind
- **Wave 2 ({{DEVOPS_ENGINEER}}):** 30 CRUDs de Cadastros
- **Wave 3 ({{FRONTEND_ENGINEER}}):** Agendamento + Atendimento + Dashboard
- **Coordenação ({{AUDITOR}}):** Quality gate, PRD, rastreamento

**Otimização aplicada:** {{AUDITOR}} identificou que {{DEVOPS_ENGINEER}} só precisa dos models core — não de auth nem Tailwind. {{ORCHESTRATOR}} reordenou a prioridade da {{BACKEND_ENGINEER}}: models primeiro, settings depois, auth depois, templates por último. {{DEVOPS_ENGINEER}} começou horas antes.

**Divergência registrada:** Autocomplete 3-char do Dontus — não implementar (UX ruim).

**Ferramenta para crawlers RE:** Skill `dontus-api-endpoints` para identificar controllers e endpoints.
