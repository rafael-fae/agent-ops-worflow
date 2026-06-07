# Prompt Master {{GIT_OPS}} — Forçando LLMs a Não Resumir

## Problema

LLMs têm viés de summarização. Quando recebem 100+ arquivos e instrução para gerar um PRD, o comportamento padrão é resumir — produzindo PRDs superficiais com 20% de cobertura. O modelo precisa ser FORÇADO a ler tudo antes de escrever.

## Template Base

```markdown
# [NOME DO PROMPT]

> **Uso:** `cd ~/path && [comando]` e cole este arquivo inteiro.
> **Objetivo:** [uma frase clara do que deve ser gerado]

---

## :red_circle: REGRA ZERO — [REGRA MÁXIMA QUE OVERRIDE O COMPORTAMENTO PADRÃO]

[Descrição da regra que força o modelo a não resumir. Ex: "Você DEVE ler cada arquivo antes de escrever."]

---

## ARQUIVOS PARA LER (nesta ordem exata)

```
📁 [pasta]/
   ├── arquivo1.md  ← [anotação do que contém]
   ├── arquivo2.md  ← [anotação]
   └── arquivo3.md
```

## ESTRUTURA DO OUTPUT

[Especificação detalhada com seções numeradas, checkboxes, formatos de tabela]

## REGRAS

1. MÍNIMO [N] linhas. Se ficar menor, você não leu tudo.
2. NENHUM placeholder.
3. [Regras específicas do domínio]
```

## Elementos Críticos

### 1. REGRA ZERO
A primeira seção após o cabeçalho deve ser uma regra máxima que override o viés de summarização. Usar :red_circle: e linguagem imperativa.

**Exemplos eficazes:**
- "Leia cada arquivo .md nessa pasta — cada um documenta uma tela do sistema legado"
- "Se o PRD anterior ficou com 20% de cobertura, este precisa ter 100%"
- "Não resumir nem pular nada — cada tela, cada campo, cada regra importa"

### 2. Fases de Leitura Obrigatórias
Dividir os arquivos fonte em FASES numeradas. Isso força leitura sequencial completa antes da geração:

```
FASE 0 — FONTE PRIMÁRIA (OBRIGATÓRIO — LEIA TUDO)
FASE 1 — FONTE SECUNDÁRIA
FASE 2 — CÓDIGO EXISTENTE
```

O marcador "OBRIGATÓRIO — LEIA TUDO" é psicologicamente eficaz contra o viés de skip do modelo.

### 3. Mínimo Explícito de Linhas
"MÍNIMO 3000 linhas. Se ficar menor, você não leu tudo."

Sem esse piso, o modelo entrega 700-1000 linhas e considera "completo".

### 4. Estrutura com Sub-Checklists
Cada seção do output deve ter sub-itens obrigatórios:

```
2.1 Nome do Módulo
a) Propósito e escopo
b) Modelos de dados (TODOS os campos, tipos, validações, relações, índices)
c) Regras de negócio (TODAS, explícitas, sem exceção)
d) Fluxos de usuário (passo a passo)
e) Critérios de aceite (testáveis, específicos, mensuráveis)
f) Integrações com outros módulos
g) Pontos de atenção
h) Referência ao legado (qual tela/fluxo corresponde)
```

Isso impede que o modelo "pule" seções inteiras por economia de tokens.

### 5. Proibição Explícita de Placeholders
"NENHUM placeholder. Toda decisão é concreta e justificada."

Sem isso, o modelo preenche seções com "A definir", "TBD", "[placeholder]".

### 6. Caminhos Absolutos com Anotações
Cada arquivo listado deve ter:
- Caminho completo a partir de ~/
- Anotação do que contém (← isto é crítico)

```
📁 ~/Dev/obsidian/10_Projects/{{PROJECT_SLUG}}/01-Biblia/
   ├── ER-MODEL.md                 ← 39 entidades, diagrama Mermaid
   ├── MODULE-DEPS.md              ← Grafo de 14 módulos
   └── PESQUISA-SATISFACAO.md      ← Módulo NPS completo
```

As anotações ajudam o modelo a priorizar a leitura e evitam que ele "pule" arquivos que parecem irrelevantes pelo nome.

## Quando Usar

- Gerar PRD de clone de sistema (50+ módulos)
- Gerar Blueprint arquitetural (12+ seções)
- Qualquer documento >2000 linhas que dependa de 20+ arquivos fonte

## Quando NÃO Usar

- Documentos <500 linhas — o overhead do prompt é maior que o benefício
- Tarefas que não dependem de leitura extensiva de arquivos
- Quando o LLM tem contexto suficiente (2M tokens) para ler tudo de uma vez

## Verificação Pós-Geração

Protocolo de 5 pontos para auditar o output:

1. `wc -l` — verificar tamanho real vs mínimo prometido
2. `head -200` — verificar estrutura e qualidade das primeiras seções
3. Pular para ~70% do arquivo, ler 200 linhas — detectar degradação
4. `tail -200` — verificar se há dump de arquivos brutos (YAML frontmatter repetido, seções sem transição)
5. `tail -10 | grep -P '[^\x00-\x7F]'` — detectar caracteres não-ASCII inesperados (chinês, mandarim) inseridos ao final de gerações longas

**Se detectado dump:** isolar apenas o conteúdo real com `head -N` e reportar a linha de transição.

**Sintoma clássico de dump:**
```
## DOCUMENTO: arquivo_qualquer.md     ← sem transição, frontmatter YAML
---                                    ← repetido para cada arquivo
title: "Título do Obsidian"
tags: [{{PROJECT_SLUG}}]
---
```

**Sintoma de contaminação:** Caracteres CJK (ex: `的事务隔离级别`) no final de exemplos ou seções de risco. O Gemini ocasionalmente insere texto em chinês quando o contexto está no limite. Corrigir substituindo pela tradução correta em português.
