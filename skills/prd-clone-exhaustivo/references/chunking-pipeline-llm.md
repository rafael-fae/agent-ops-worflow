# Chunking Pipeline para Geração de PRD/Blueprint com LLM

## Problema

LLMs (Gemini, Claude) estouram o limite de contexto quando tentam ler 100+ arquivos fonte + gerar 3000+ linhas de PRD numa única sessão. O sintoma: as primeiras ~700 linhas são conteúdo sintetizado de qualidade, depois o modelo começa a concatenar arquivos fonte brutos como filler (YAML frontmatter repetido, seções sem transição).

## Solução: Pipeline de 3 Fases

```
FASE A (Extração)          FASE B (Compilação)       FASE C (Blueprint)
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│ 3 lotes paralelos│       │ 1 sessão         │       │ 1 sessão         │
│ 13-14 arqs cada  │  →   │ Lê 24 fichas     │  →   │ Lê PRD + fichas  │
│ ↓                │       │ ↓                │       │ ↓                │
│ 24 fichas .md    │       │ PRD.md (3000+)   │       │ BLUEPRINT.md     │
└─────────────────┘       └─────────────────┘       └─────────────────┘
  3 sessões (paralelo)      1 sessão                 1 sessão
```

**Total: 5 sessões, contexto nunca estoura.**

## Por que funciona

- Cada lote da Fase A processa no máximo 14 arquivos — bem abaixo do limite de contexto
- As fichas são "alta densidade" — toda informação relevante extraída, sem ruído de frontmatter YAML, comentários, ou formatação
- A Fase B lê 24 fichas (~1.600 linhas densas) em vez de 100+ arquivos brutos
- A Fase C lê PRD + fichas em vez de 100+ arquivos

## Estrutura de Arquivos

```
docs/planejamento/
├── FASE-A-LOTE-1.md       # Prompt para lote 1 (~100 linhas)
├── FASE-A-LOTE-2.md       # Prompt para lote 2 (~80 linhas)
├── FASE-A-LOTE-3.md       # Prompt para lote 3 (~100 linhas)
├── FASE-B-PRD.md          # Prompt de compilação (~140 linhas)
├── FASE-C-BLUEPRINT.md    # Prompt do blueprint (~160 linhas)
└── INSTRUCOES-GERACAO.md  # Guia passo a passo

docs/prd/modulos/          # Gerado na Fase A
├── 01-multi-tenant.md
├── 02-rbac-auth.md
├── ...
└── 24-admin-config.md

docs/
├── PRD.md                 # Gerado na Fase B
└── BLUEPRINT-ARQUITETURAL.md  # Gerado na Fase C
```

## Regras para Fichas da Fase A

Cada ficha deve seguir estrutura fixa de 8 seções:
1. Propósito e Escopo
2. Modelos de Dados (TODOS os campos, tipos, validações, relações)
3. Regras de Negócio (numeradas, específicas, extraídas dos arquivos fonte)
4. Fluxos de Usuário (passo a passo)
5. Telas e Interfaces (URLs, campos, tabelas, botões)
6. Integrações
7. Pontos de Atenção
8. Referências (quais arquivos fonte)

## Critérios de Aceite das Fichas

**Meta ideal:** 150+ linhas por ficha
**Mínimo aceitável:** 50+ linhas com alta densidade técnica

**Fichas naturalmente menores (50-80 linhas) são ACEITÁVEIS quando:**
- O material fonte são arquivos de REVISÃO/AUDITORIA (ex: REVISAO-K1-{{AUDITOR_UPPER}}.md), não especificações completas
- O Gemini extraiu TODO o conteúdo disponível sem fabricar informação
- As regras de negócio são específicas (extraídas de arquivos reais), não genéricas
- Os nomes de campos são REAIS do sistema legado, não inventados

**Fichas devem ser REJEITADAS quando:**
- Menos de 40 linhas (extração falhou ou arquivo fonte estava vazio)
- Conteúdo genérico sem referência a arquivos fonte específicos
- Campos/modelos inventados que não existem nos arquivos fonte

## Paralelismo na Fase A

Os 3 lotes da Fase A podem rodar EM PARALELO (3 terminais simultâneos) porque:
- Cada lote escreve em arquivos diferentes (01-07, 08-16, 17-24)
- São processos independentes — apenas leitura nos arquivos fonte
- Sem sobreposição de paths de saída

**Único risco:** rate limit da API. Se uma sessão travar com erro de cota, esperar 2 min e reenviar.

## Verificação Pós-Fase A

```bash
ls docs/prd/modulos/ | wc -l    # Deve retornar 24
wc -l docs/prd/modulos/*.md     # Nenhum arquivo < 40 linhas
```

## O Padrão "Prompt do Prompter"

Uma inovação desta metodologia: em vez de escrever prompts manualmente para cada lote, use o PRÓPRIO ORQUESTRADOR ({{ORCHESTRATOR}}) para gerar os prompts da Fase A. O orquestrador:

1. Lista os arquivos do vault fonte
2. Divide em 3 lotes balanceados (~13-14 arquivos cada)
3. Agrupa por afinidade temática (arquitetura, revisões, bíblia)
4. Gera um prompt por lote com a lista exata de arquivos e fichas esperadas

Isso garante que os prompts sejam precisos e não referenciem arquivos inexistentes (pitfall: BIBLIA_{{BACKEND_ENGINEER}}_Financeiro_Orcamento_Indicativos.md de 8237 linhas foi referenciado em documentos mas não existia no vault).

## Pitfalls

1. **Verificar existência de arquivos fonte antes de buildar prompts.** Arquivos referenciados em documentos de índice podem não existir no disco.
2. **Fichas de revisão são naturalmente menores.** Não rejeitar ficha de 50 linhas se o arquivo fonte (REVISAO-*.md) tem apenas 100 linhas.
3. **Limpar diretório temporário.** O Gemini pode criar `tmp_obsidian/` durante a extração — limpar após cada lote.
4. **Sessão nova para cada lote.** Não reutilizar a mesma sessão Gemini entre lotes — o contexto acumulado reduz a qualidade.
5. **Fase B só depois de TODAS as fichas prontas.** Não compilar com fichas faltando.
6. **Blueprint Section 12 (Roadmap) pode degenerar em template filler.** O Gemini tende a gerar 80-100 "sprints" idênticas com tasks genéricas (`Estruturar serializers`, `Criar views HTMX`, `Revisão OWASP`) quando o roadmap real exigiria conhecimento específico de implementação. **Solução:** auditar a Seção 12 isoladamente com `grep -c "Sprint.*Implementação Técnica Categoria" BLUEPRINT.md`. Se count > 20, a seção é template filler e precisa ser regenerada com prompt focado ou refinada manualmente pós-geração.
7. **Arquivo fonte referenciado pode não existir no disco.** Sempre verificar com `search_files` antes de incluir no prompt. Ex: BIBLIA_{{BACKEND_ENGINEER}}_Financeiro_Orcamento_Indicativos.md (8237 linhas) era referenciado em índices mas NUNCA foi commitado no git.

## Fase A-Extra: Lote de Garimpo (PRD Antigo como Fonte)

Quando o vault Obsidian tem conteúdo incompleto (ex: arquivos referenciados mas não commitados), o PRD antigo gerado por uma tentativa anterior pode conter o conteúdo concatenado que falta. Use um "Lote 4 de Garimpo":

1. O Gemini lê o PRD antigo (ex: `docs/PRD.md` com 9499 linhas — que é uma colagem de Obsidian)
2. Cruza com as fichas existentes para evitar duplicação
3. Adiciona seção `## 9. Complemento do PRD Antigo` APENAS nas fichas que têm informação nova
4. Foco nas fichas que o PRD antigo cobre melhor (financeiro, orçamentos, dashboard)
5. Mínimo 30 linhas de informação nova por ficha — se não tem, não adiciona

**Resultado típico:** +17-24 linhas por ficha enriquecida. Suficiente para cobrir gaps sem inflar.

## Dados Reais de Execução ({{PROJECT_NAME}}, 31/05/2026)

| Lote | Fichas | Linhas por ficha | Material fonte |
|------|--------|:-----------------:|---------------|
| Lote 1 (Arquitetura) | 01-07 | 63-113 | K3, G02, G05, G06, Infra, Design System, G11 |
| Lote 2 (Revisões) | 08-16 | 44-71 | REVISAO-*.md (auditorias — fonte naturalmente fina) |
| Lote 3 (Bíblia) | 17-24 | 48-84 | BIBLIA-CONSOLIDADA.md, {{DEVOPS_ENGINEER}} cadastros, PARTIAL-PAGES |
| Lote 4 (Garimpo) | 6 enriquecidas | +17-24 cada | PRD antigo (9499 linhas de Obsidian concatenado) |
| **Total** | **24 fichas** | **~1.850 linhas** | — |

**PRD final:** 5.343 linhas (meta: 3.000+) ✅
**Blueprint final:** 7.004 linhas (meta: 4.000+) — Seção 12 com template filler ⚠️

## Protocolo de Auditoria Pós-Blueprint

Além do protocolo de 4 pontos do Prompt Master {{GIT_OPS}}, adicionar verificação específica para Blueprint:

```bash
# 1. Verificar tamanho
wc -l docs/BLUEPRINT-ARQUITETURAL.md

# 2. Verificar seções obrigatórias (devem ser 12)
grep -c "^## " docs/BLUEPRINT-ARQUITETURAL.md

# 3. Verificar Seção 12 (Roadmap) — detectar template filler
grep -c "Estruturar serializers base e testes" docs/BLUEPRINT-ARQUITETURAL.md
# Se count > 10: template filler detectado → regenerar Seção 12

# 4. Verificar se termina limpo (sem dump de Obsidian)
tail -30 docs/BLUEPRINT-ARQUITETURAL.md
# Se houver "---\ntitle:" ou frontmatter YAML: dump detectado
```

## Fase D: Regeneração Focada de Seção Única

Quando apenas UMA seção do Blueprint (ou PRD) está ruim — tipicamente a Seção 12 (Roadmap) — não refaça o documento inteiro. Use o padrão Fase D:

1. Criar prompt focado que lê o PRD completo + seções boas do Blueprint (1-11) como contexto
2. Prompt instrui: "Gere APENAS a Seção 12. Nada antes, nada depois. Comece com `## 12. ROADMAP TÉCNICO`."
3. Fornecer exemplo concreto do nível de detalhe esperado (1 sprint completa como template)
4. Especificar número máximo de sprints (ex: 15, não 100)
5. Gemini gera output standalone com apenas a seção

**File surgery para substituição:**
```bash
# Extrair parte boa (seções 1-11) + nova seção 12
head -6382 BLUEPRINT-ARQUITETURAL.md > /tmp/parte1.md
cat /tmp/secao12-nova.md >> /tmp/parte1.md
mv /tmp/parte1.md BLUEPRINT-ARQUITETURAL.md
```

**Verificação pós-cirurgia:**
```bash
wc -l BLUEPRINT-ARQUITETURAL.md          # Deve ser ~6800 (não 7004)
tail -5 BLUEPRINT-ARQUITETURAL.md        # Deve terminar com Sprint 15, não Sprint 100
grep -c "Estruturar serializers" BLUEPRINT-ARQUITETURAL.md  # Deve ser 0
```

## ⚠️ Pitfall: Contaminação por Texto Não-Português

Gemini ocasionalmente insere texto em chinês/mandarim no final de gerações longas — especialmente em exemplos de código ou seções de risco. **Sempre verificar as últimas 10 linhas de cada prompt gerado ou seção antes de usar.**

**Detecção:**
```bash
tail -10 arquivo.md | grep -P '[\x{4e00}-\x{9fff}]'  # Detecta caracteres CJK
```

**Sintoma real (31/05/2026):** Prompt FASE-D-ROADMAP.md terminava com `testar com的事务隔离级别` (chinês misturado). Corrigido para `testar isolamento de transação`.
