---
name: prd-clone-exhaustivo
description: "Metodologia para criar PRD de clone de sistema SaaS existente — mapeamento exaustivo módulo-a-módulo, página-a-página, campo-a-campo. Abordagem bíblia que evolui em 3 profundidades: modulos, paginas, campos/regras/fluxos."
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# PRD Clone Exaustivo — Metodologia "Bíblia"

## Quando Usar

Ao documentar um sistema existente para clonar/recriar do zero. O {{COMMANDER}} exige que **nenhuma funcionalidade passe despercebida** — mesmo que seja removida depois, precisa estar documentada.

## A Armadilha (descoberta no {{PROJECT_NAME}})

**PRD v1 (8 módulos)** — "90 dias, está OK".
**PRD v2 (18 módulos, 132 páginas)** — Ainda insuficiente. {{COMMANDER}} apontou: listar paginas nao basta.
**PRD v3 (campo-a-campo)** — O que ele realmente quer. Cada formulario, botao, regra.

> Licao: **Nunca pare no nivel de "paginas".** O cliente ({{COMMANDER}}) sabe que sem o grao fino, o clone nao funciona.

## Metodologia em 3 Profundidades

### Profundidade 1 — Mapeamento de Modulos (horas)

1. Crawlear todas as URLs acessiveis do sistema autenticado
2. Agrupar por modulo (ex: Financeiro, Paciente, Agenda)
3. Catalogar: URL, tamanho HTML, numero de tabelas, formularios
4. Entregavel: lista de modulos com contagens

### Profundidade 2 — Mapeamento de Paginas (dias)

Para **cada pagina**:
- Nome da pagina/modal
- Tabelas: colunas, fontes de dados
- Formularios: lista de campos (nome, tipo aproximado)
- Acoes principais: botoes, links
- Observacoes: modals, autocomplete, comportamento especial

### Profundidade 3 — Detalhamento Biblia (semanas)

Para **cada pagina**, documentar em formato tabular:

```
## {Modulo} > {Pagina/Modal}

### Campos
| Campo | Tipo | Obrigatorio | Valores Possiveis | Validacao | Comportamento |
|---|---|---|---|---|---|
| nome | text | sim | - | max 100 chars | autocomplete |
| sexo | select | nao | M/F/Outro | - | dropdown |
| data_nasc | date | nao | - | < hoje | calendario |

### Acoes (Botoes/Links)
| Acao | Gatilho | Confirmacao | Efeito / Navegacao |
|---|---|---|---|
| Salvar | Click | "Deseja salvar?" | POST -> recarrega pagina |
| Excluir | Click | "Confirma exclusao?" | DELETE -> volta a lista |

### Regras de Negocio
- Regra 1: descricao
- Regra 2: descricao

### Fluxo
[Diagrama textual do fluxo de navegacao]
```

## Divisao de Trabalho para Forca-Tarefa

Quando o volume e grande (132+ paginas), distribuir por perfil:

| Perfil | Foco | Ideal para |
|---|---|---|
| **Estrategista ({{AUDITOR}})** | Coordenacao + modulos densos (Paciente, Orto) | 3-5 paginas densas |
| **Designer/Frontend ({{FRONTEND_ENGINEER}})** | UI/Campos: formularios, tipos, valores, botoes | ~15 paginas medias |
| **Arquiteta ({{BACKEND_ENGINEER}})** | Regras de negocio, fluxos de dados, validacoes | ~35 paginas |
| **Infra/DevOps ({{DEVOPS_ENGINEER}})** | Cadastros, configuracao, entidades CRUD | ~40+ paginas simples |

Template de documento unico:

```markdown
# PRD Biblia - {Sistema}
## 1. Escopo Geral
[resumo de modulos e contagem]
## 2. Detalhamento
{conteudo por pagina seguindo o template acima}
## 3. Contagem Final
| Metrica | Valor |
## 4. Riscos
```

## Ferramentas para Crawling

- **Acesso autenticado**: Usar client HTTP existente (ex: `DontusClient`) que mantem sessao + CSRF
- **Extracao de URLs**: Acessar pagina por pagina, extrair links do HTML
- **Headless**: Servidor OVH nao tem Chrome - usar HTTP direto via `httpx`
- **Parser**: BeautifulSoup4 para extrair formularios e tabelas do HTML
- **Regex para JS**: Extrair chamadas de API de scripts inline: `re.findall(r'(?:url|action|href)\\s*[:=]\\s*[\"]([^\"]*(?:Get|List|Load|Search|Agenda)[^\"]*)[\"]', html)`
- **Extração `var src`**: Muitos sistemas (Dontus inclusive) injetam dados via `var src = {dados: {...}}` no HTML server-side. Extraia com regex: `re.search(r'var\s+src\s*=\s*(\{.*?\});', html, re.DOTALL)` e depois normalize (`True→true`, `None→null`, trailing commas) para parsear como JSON. Isso revela objetos completos com campos, valores, status — às vezes mais fiel que a própria API.

## ⚠️ Pitfall Crítico: O "Travesseiro do Sub-Menu" (Descoberto 26/05/2026)

**ISSO É O MAIOR ERRO QUE O TIME COMETEU.** A equipe reportou "99% de cobertura" — mas estava medindo apenas a **navegação principal** (menu lateral global). As páginas individuais têm **seus próprios sub-menus internos** que NÃO foram seguidos.

**Como aconteceu:**
- 132 páginas foram visitadas via HTTP crawl ✅
- Cada página tem links internos, abas, modais condicionais que só aparecem com clique
- Ninguém clicou nesses links internos na primeira rodada
- Cobertura REAL: ~60-70%, não 99%

**Mitigação obrigatória:**
1. Depois de mapear todas as URLs do menu principal, para CADA página, extraia TODOS os links internos (excluindo o menu global que se repete)
2. Visite CADA link interno — eles levam a sub-páginas, modais, estados diferentes
3. Repita até não sobrarem URLs novas não visitadas
4. A cobertura REAL só pode ser declarada quando TODOS os links de TODAS as páginas foram seguidos

**Regra de ouro:** Se você só visitou as URLs do menu principal, sua cobertura é, no máximo, 70%.

## ⚠️ Pitfall: Framework/Biblioteca Descoberta Durante o Processo

Durante o mapeamento, você pode descobrir o framework/biblioteca que o sistema alvo usa (ex: Knockout.js, React, Angular). Isso pode mudar a abordagem de documentação e a stack do clone.

**Exemplo real:** O Dontus usa Knockout.js com lazy tabs. Isso significa que abas e modais carregam conteúdo via AJAX sob demanda. Um crawler HTTP simples não captura esse conteúdo — precisa de interação via Playwright.

**Mitigação:**
1. Inspecione o HTML em busca de `data-bind` (Knockout.js), `ng-` (Angular), `v-` (Vue), `react-` (React)
2. Identifique se há lazy loading de conteúdo (abas que só carregam quando clicadas)
3. Ajuste a ferramenta de crawling: HTTP basico não basta para páginas com carregamento lazy
4. Use Playwright ou Puppeteer para páginas interativas

## ⚠️ Pitfall: Método de Delegação — Não Esqueça Ninguém

{{COMMANDER}} notou que {{AUDITOR}}, ao delegar a força-tarefa, não incluiu {{BACKEND_ENGINEER}} na convocação inicial. **Isso é um erro de protocolo.** Ao delegar uma força-tarefa, cite TODOS os envolvidos explicitamente, mesmo que alguns já saibam do plano.

**Checklist de delegação:**
- [ ] Citei cada membro da equipe pelo `<@USER_ID>` correto?
- [ ] Cada membro tem uma missão clara e específica?
- [ ] **Ninguém foi esquecido?** (ex: {{COMMANDER}} corrigiu {{AUDITOR}} por não incluir {{BACKEND_ENGINEER}} na convocação — verifique a lista completa de agentes antes de delegar)
- [ ] O coordenador geral está identificado?
- [ ] Os prazos estão explícitos?

## 🎯 Tática de Progressão: Ondas de Profundidade com Cron

Para mapeamentos muito grandes (100+ páginas), use **ondas progressivas** em vez de tentar tudo de uma vez:

```
Wave 1 (0h):  Varredura inicial + delegação principal
Wave 2 (+2h): Segunda camada — paciente teste + sub-menus + aprofundamento
Wave 3 (+4h): Varredura final de confirmação + relatório de cobertura
```

Isso força o time a aprofundar progressivamente, em vez de declarar vitória cedo demais. Configure como cron jobs para executar automaticamente.

## 📊 Métrica de Cobertura Honesta

**Nunca declare cobertura sem qualificar o que está sendo medido.** Use esta tabela:

| Camada | Cobertura típica na 1ª onda | Método |
|---|---|---|
| Navegação principal (menus) | ~100% | HTTP crawl |
| Estrutura (tabelas, botões, forms) | ~80-90% | HTTP crawl |
| Campos estáticos | ~90-100% | HTML + JS objects |
| Campos carregados via AJAX/lazy | ~0-50% | Só com Playwright |
| Sub-menus internos de cada página | ~0-30% | Só com Playwright + clique |
| Comportamentos condicionais | ~0-70% | Parcial via browser |
| Dados reais vs ID=0 (registro vazio) | ~0% (até você testar) | Acessar registros reais |

A cobertura REAL é a **média ponderada** dessas camadas. Se você só fez HTTP crawl (camadas 1-3), sua cobertura real é ~60-70%, não 99%.

## 🧪 Validação com Dados Reais vs Registro Vazio

Além do pitfall ID=0 vs ID=real (documentado acima), crie um **paciente/registro teste** e preencha TODOS os campos de TODAS as abas. Depois compare com a documentação gerada a partir de registros vazios. As diferenças revelam:
- Abas condicionais (que só aparecem com dados)
- Campos que mudam de comportamento quando preenchidos
- Relacionamentos entre entidades (ex: orçamento → pagamento → NFSe)
- Status e fluxos que só existem com dados reais

## 🖼️ Análise Visual de Screenshots (Nova Ferramenta — Descoberta 26/05)

**Quando o crawl não basta, use screenshots + análise de imagem.**

Durante a RE do Dontus, o crawl HTTP + Playwright não conseguiu penetrar sub-abas que carregam via Knockout.js lazy loading. O clique no href `#agenda` não dispara o carregamento porque é controlado por handler KO invisível no DOM.

**Solução:** {{COMMANDER}} enviou screenshots manualmente das telas. Processei 30+ imagens com Gemini 2.5 Flash via script `gemini_vision.py`. Resultado: descobrimos que Clinica tem 16 sub-abas de configuração (não 1 como supúnhamos), WhatsApp tem sub-abas de automação/gatilhos/usuários, e Anamnese tem 35 perguntas (não 25).

**Quando usar visão em vez de crawl:**
1. Páginas com lazy loading via Knockout.js/AJAX (abas que só carregam ao clicar)
2. Conteúdo condicional (aparece só com dados reais)
3. Dropdowns que abrem opções aninhadas (ex: "Configurar Dias da Semana")
4. Modais que abrem a partir de cliques em elementos não-âncora
5. Sistemas SPA disfarçados de multi-página (ex: mesmo ScreenModel compartilhado entre rotas diferentes)

**Fluxo:**
1. Peça ao cliente para enviar screenshots das telas que o crawl não conseguiu penetrar
2. Processe cada imagem com Gemini 2.5 Flash (script: `gemini_vision.py`)
3. Extraia: campos visíveis, labels, botões, abas, modais, tabelas
4. Consolide em tabela markdown (#, Tela, URL, Descobertas)
5. Salve como documentação permanente no projeto (`docs/vision/`)

**Script:** `~/.hermes/profiles/{agente}/scripts/gemini_vision.py`
**Modelo:** Gemini 2.5 Flash (rápido, barato, suficiente para UI)
**Prompt testado 30+ vezes:** `"Descreva detalhadamente esta tela do [SISTEMA]. Qual o nome, URL, campos, botões, abas, tabelas, modais? Inclua labels, opções e detalhes de interface."`
**Processamento:** Sequencial, timeout=90, nunca em paralelo (tool limitation)

## ⚠️ Pitfall: SPA Disfarçada de Multi-Página (Descoberto 26/05)

**ISSO MUDA TUDO.** Durante RE profunda, {{FRONTEND_ENGINEER}} descobriu que Dashboard, Agendamento e Atendimento do Dontus compartilham o **mesmo ScreenModel** (219 observables + 60 métodos). O Dontus é uma SPA disfarçada de aplicação multi-página.

**Como detectar:**
- O mesmo `var src` aparece em páginas diferentes
- Bindings KO se repetem com os mesmos nomes de observable entre rotas
- Modais compartilham o mesmo viewModel
- O clique em links não navega para URLs diferentes, apenas muda o estado do mesmo model

**Implicação para o clone:** NÃO replique o ScreenModel gigante. Faça componentes isolados por página (Alpine.js) com lazy loading HTMX.

## Pitfalls Conhecidos

1. **Paginas de edicao sao imensas** — Paciente no Dontus tem 1.6MB. O HTML embute todos os 22 formularios no mesmo arquivo via modals. Uma unica pagina pode conter dezenas de sub-formularios.
2. **APIs nem sempre retornam todos os dados** — `GetAgendamentos` nao retorna horarios. Precisa de N+1 chamadas a `GetAgendamentosPaciente`.
3. **DataTables** — Alguns endpoints retornam JSON no formato DataTables (`{draw, iTotalRecords, data: [...]}`), nao array puro.
4. **O cliente nem sempre sabe o que quer** — O {{COMMANDER}} sabe que precisa do detalhamento biblia, mas so descobre depois de ver o PRD v2. Esteja preparado para iterar.
5. **Timeout do Dontus** — e lento. Usar timeout 25-30s nas requisicoes.
6. **Sessao Dontus** — O atributo do client e `_session` (privado), nao `session`.

## ⚠️ Pitfall Crítico: ID=0 vs ID=Real (Descoberto 25/05/2026)

**ISSO É CRÍTICO.** Ao documentar paginas de edicao/cadastro de um sistema existente, **NUNCA** confie apenas em paginas com ID=0 (registro novo/vazio).

No caso do Dontus:
- `/Paciente/Edit/0` mostrava **22 formularios**
- `/Paciente/Edit/48` (paciente real Vitoria) revelou **28 abas** — **6 extras** que nunca apareciam com dados vazios

**Por que acontece:** Muitos sistemas condicionam a exibicao de abas/secoes a existencia de dados. Abas de Orcamento, Orto, Pagamentos, HOF, NFSe so aparecem quando o paciente tem esses registros.

**Mitigacao obrigatoria:**
- Acesse o sistema com **3-5 registros reais diversos** (paciente com orcamento, paciente com orto, paciente com pagamentos, etc)
- Compare a arvore de navegacao (abas, modals) do ID=0 vs IDs reais
- Documente as discrepancias
- Aplique isto a **todas as entidades**: Orcamento (`/Orcamento/Edit/{id}`), Orto (`/Orto/Edit/{id}`), etc
- Cada entidade pode ter secoes condicionais diferentes

## Pitfall: Documentacao oficial e videos como fonte complementar

O sistema pode ter documentacao passo-a-passo externa (ex: `manual.dontus.com`) e videos tutoriais (`/Videos`). Extraia esses recursos — eles explicam fluxos que o HTML cru sozinho nao revela.

## Nova Profundidade: Jornadas de Usuario (PRD v3)

Apos Profundidade 3 (campos), adicione **Jornadas de Usuario** no PRD. O formato comprovado:

```markdown
## Jornada: {Nome da Funcionalidade}
### Gatilho
{O que leva o usuario a iniciar esta jornada}
### Fluxo Principal
1. Usuario acessa {URL} → ve {tela}
2. Clica em {botao} → modal {nome} abre
3. Preenche {campo1} (obrigatorio, tipo texto, autocomplete)
4. Seleciona {campo2} (dropdown com valores X, Y, Z)
5. Se {campo2} = X → campo3 aparece (condicional)
6. Clica em "Salvar" → validacao: {regras}
7. Sucesso: modal fecha + tabela atualiza + toast "Salvo"
8. Erro: mensagem {texto} + campos destacados em vermelho
### Fluxos Alternativos
- Se paciente novo → modal de cadastro rapido (Nome + Cel)
- Se conflito de horario → alerta + bloqueia salvamento
### Regras de Negocio
{regras extraidas dos objetos JS + comportamento observado}
### APIs Chamadas
{metodo + endpoint + payload}
```

O PRD precisa ter **3 camadas**: o que existe (catalogo), onde esta (campos/URLs), e como recriar (jornadas + bindings + payloads).

## Delegando a Geração do PRD para um LLM (Prompt Master {{GIT_OPS}})

Quando o PRD final precisa ser gerado por um LLM externo (Gemini CLI, Claude Code), **não basta jogar os arquivos e torcer**. O viés natural do modelo é resumir — produzir PRDs superficiais com 20% de cobertura.

Use o **Prompt Master {{GIT_OPS}}**: um arquivo `.md` autossuficiente de 200-350 linhas que FORÇA o modelo a:

1. Ler CADA arquivo fonte antes de gerar (fases numeradas obrigatórias)
2. Cumprir mínimo de linhas (3.000+ para PRD, 4.000+ para Blueprint)
3. Seguir "Regra Zero" que override o comportamento de summarização
4. Estruturar o output com seções obrigatórias e sub-checklists

**Referência completa:** `references/prompt-master-pattern.md` — template, estrutura, pitfalls, exemplo real do {{PROJECT_NAME}}.

**⚠️ Pitfall crítico: Context Exhaustion → Raw Dump.** Quando o modelo esgota o contexto no meio da geração, ele concatena arquivos fonte brutos como filler em vez de sintetizar. O arquivo parece enorme mas só as primeiras ~700 linhas são conteúdo real. **Solução:** o Chunking Pipeline (ver `references/chunking-pipeline-llm.md`) — divida em 3 fases: Extração de fichas densas em lotes → Compilação do PRD a partir das fichas → Blueprint. Total: 5 sessões, contexto nunca estoura.

**⚠️ Pitfall: Template Filler (Gemini-Specific).** Diferente do Raw Dump (que cola arquivos brutos), o Template Filler é quando o Gemini gera conteúdo ESTRUTURADO mas genérico — templates numerados com nomes placeholder e tasks idênticas. Ocorre quando o modelo tem estrutura suficiente para parecer coerente, mas não tem informação específica para preencher. Padrões conhecidos:

| Padrão | Onde aparece | Exemplo | Comando de detecção |
|---|---|---|---|
| `Tabela_Referencia_N` | Blueprint Seção 3 (Modelos) | `nome_identificador_1`, `status_operacional_1` | `grep -c 'Tabela_Referencia_'` |
| `Role_N` duplicadas | Blueprint Seção 6 (RBAC) | Role_0 a Role_99 com permissões idênticas | `grep -c 'Role_[0-9]'` |
| `Pipeline Step N` | Blueprint Seção 9 (DevOps) | Mesmo CI/CD repetido 10× | `grep -c 'Pipeline Step'` |
| `ETL Mapping N` | Blueprint Seção 11 (Migração) | `dontus_legacy_table_150` | `grep -c 'ETL Mapping'` |
| `Sprint N: Implementação Técnica Categoria N` | Blueprint Seção 12 (Roadmap) | "Estruturar serializers base e testes" × 100 | `grep -c 'Implementação Técnica Categoria'` |

**Mitigação:** Se `grep -c` retornar > 20 para qualquer padrão, a seção é filler e precisa ser regenerada com prompt focado (ex: prompt só da seção problemática, alimentado com PRD + código fonte real). O filler NÃO invalida o documento inteiro — tipicamente 8 das 12 seções do Blueprint são reais, e as 4 com filler podem ser corrigidas individualmente sem regenerar tudo. **Referência completa:** `references/blueprint-filler-patterns.md`.

**✅ Validação real (31/05/2026):** Pipeline executado com sucesso no {{PROJECT_NAME}}. 3 lotes da Fase A rodaram em paralelo (3 terminais simultâneos), 24 fichas geradas em ~30 min. Fichas de arquivos de REVISÃO (REVISAO-*.md) ficaram naturalmente menores (50-80 linhas) — isso é aceitável porque o material fonte era de auditoria, não especificação completa. Fichas de arquivos densos (BIBLIA-CONSOLIDADA.md, {{DEVOPS_ENGINEER}} cadastros) ficaram na faixa de 70-110 linhas com alta densidade técnica.

**⚠️ Pitfall: Arquivo fonte referenciado não existe no disco.** Documentos de índice podem referenciar arquivos que nunca foram commitados (ex: BIBLIA_{{BACKEND_ENGINEER}}_Financeiro_Orcamento_Indicativos.md de "8237 linhas" não existia no vault). Sempre verificar existência com `ls` ou `search_files` antes de incluir no prompt. Se o arquivo não existe, verificar se o conteúdo está versionado no git (`git log --all --full-history -- '**/arquivo.md'`) ou se foi concatenado em outro documento (ex: PRD antigo). No caso do {{PROJECT_NAME}}, o conteúdo parcial da {{BACKEND_ENGINEER}} estava no PRD antigo (linhas ~6464-6725) e foi extraído de lá via Lote 4.

**Paralelismo na Fase A:** Os lotes da Fase A podem rodar simultaneamente (3 terminais, 3 sessões Gemini) porque cada lote escreve em arquivos diferentes (01-07, 08-16, 17-24). Único risco: rate limit da API Google. Se uma sessão travar com erro de cota, esperar 2 minutos e reenviar.

**Verificação pós-geração (OBRIGATÓRIA):** Após o LLM gerar o PRD/Blueprint, SEMPRE auditar o arquivo com o protocolo de 5 pontos:

1. `wc -l` para verificar tamanho real vs esperado
2. Ler primeiras 200 linhas (verificar estrutura e qualidade)
3. Pular para ~70% do arquivo e ler 200 linhas (detectar degradação)
4. Ler últimas 200 linhas (verificar se há dump de arquivos brutos — YAML frontmatter repetido, seções sem transição)
5. **Para Blueprint especificamente:** verificar TODAS as seções com filler patterns — não apenas Seção 12. Use os comandos:
   ```bash
   grep -c 'Tabela_Referencia_' BLUEPRINT.md    # Seção 3: > 20 = filler
   grep -c 'Role_[0-9]' BLUEPRINT.md             # Seção 6: > 20 = filler  
   grep -c 'Pipeline Step' BLUEPRINT.md          # Seção 9: > 5 = filler
   grep -c 'ETL Mapping' BLUEPRINT.md            # Seção 11: > 20 = filler
   grep -c 'Implementação Técnica Categoria' BLUEPRINT.md  # Seção 12: > 10 = filler
   ```
   Se qualquer um retornar acima do threshold, aquela seção específica precisa ser regenerada com prompt focado (apenas a seção, não o documento inteiro).

Se detectado dump: isolar apenas o conteúdo real com `head -N` e reportar ao {{COMMANDER}} com a linha de transição identificada.

## Checklist de Qualidade

Antes de considerar um modulo "documentado":
- [ ] Cada campo tem: tipo, obrigatoriedade, valores, validacao
- [ ] Cada botao/acao tem: gatilho, confirmacao, efeito
- [ ] Regras de negocio estao explicitas
- [ ] Fluxo de navegacao esta descrito
- [ ] Dados mock/preenchimento padrao estao documentados
- [ ] Permissoes (se houver) estao mapeadas
