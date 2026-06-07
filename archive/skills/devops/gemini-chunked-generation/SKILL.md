---
name: gemini-chunked-generation
description: Pipeline de 3 fases para gerar documentos grandes com Gemini CLI sem estourar limite de contexto. Extração em lotes → compilação → blueprint. Reutilizável para PRDs, especificações técnicas, documentação extensa.
category: devops
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Gemini CLI — Geração Fracionada de Documentos Grandes

## Gatilho

- Gerar PRD, blueprint, especificação técnica ou documentação com 3000+ linhas
- O Gemini CLI estoura o contexto ao tentar processar 50+ arquivos fonte de uma vez
- O output fica com filler/template quando o contexto esgota

## Problema

O Gemini CLI tem limite de contexto. Ao processar muitos arquivos (ex: 100+ .md de engenharia reversa) e gerar um documento grande (3000+ linhas), ele:
1. Começa bem — sintetiza conteúdo real
2. Estoura o contexto — para de sintetizar
3. Despeja arquivos fonte brutos como "filler" (ex: concatenar .md do Obsidian no final do PRD)
4. Ou gera templates repetitivos (ex: 100 sprints idênticas)

## Solução: Pipeline de 3 Fases

```
FASE A (Extração)          FASE B (Compilação)       FASE C (Blueprint/Derivado)
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│ Lotes de ~14     │       │ Lê ~24 fichas    │       │ Lê PRD + fichas │
│ arquivos fonte   │  →   │ (não 100+ arqs)  │  →   │ (não 100+ arqs) │
│ ↓                │       │ ↓                │       │ ↓                │
│ 1 ficha .md por  │       │ Documento final  │       │ Documento final │
│ módulo/tópico    │       │ (3000+ linhas)   │       │ (4000+ linhas)  │
└─────────────────┘       └─────────────────┘       └─────────────────┘
  N sessões Gemini          1 sessão Gemini          1 sessão Gemini
```

### Fase A — Extração (N sessões)

Cada sessão processa ~14 arquivos fonte e gera fichas de extração.

**Regras:**
- Máximo 15 arquivos fonte por lote
- Cada lote gera fichas `.md` independentes (sem sobreposição de paths)
- Os lotes podem rodar em PARALELO (cada um escreve em arquivos diferentes)
- Formato da ficha: 8 seções padronizadas (Propósito, Modelos, Regras, Fluxos, Telas, Integrações, Pontos, Referências)
- Mínimo 150 linhas por ficha (se ficar menor, a extração foi incompleta)
- Se atingir 80% do contexto, PARAR e salvar — não continuar

**Prompt template:**
```markdown
# FASE A — LOTE X/N: Extração de Fichas

REGRA ZERO — VOCÊ É UM EXTRATOR, NÃO UM ESCRITOR
- ❌ NÃO escreva o documento final
- ✅ LEIA cada arquivo listado
- ✅ EXTRAIA informações estruturadas
- ✅ SALVE cada ficha em {output_dir}/

ARQUIVOS PARA LER:
📁 {source_dir}/
   ├── arquivo1.md
   ├── arquivo2.md
   └── ...

FICHAS A GERAR:
| # | Módulo | Arquivo de saída |
|---|--------|-----------------|
| 1 | {nome} | {output_dir}/01-{nome}.md |

FORMATO DE CADA FICHA:
## 1. Propósito e Escopo
## 2. Modelos de Dados
## 3. Regras de Negócio
## 4. Fluxos de Usuário
## 5. Telas e Interfaces
## 6. Integrações
## 7. Pontos de Atenção
## 8. Referências
```

### Fase B — Compilação (1 sessão)

Lê as fichas geradas na Fase A e compila o documento final.

**Regras:**
- NÃO reler os arquivos fonte originais — usar apenas as fichas
- As fichas são "alta densidade" — sem ruído, só informação relevante
- Sintetizar, não concatenar — remover redundâncias entre fichas
- Mínimo 3000 linhas no output

### Fase C — Documento Derivado (1 sessão)

Lê o output da Fase B + fichas e gera documento complementar (ex: blueprint a partir do PRD).

---

## Pitfalls

1. **Gemini cola arquivos fonte como "anexo"**: Se o output tiver blocos brutos de outros .md concatenados, o contexto estourou. Reduzir o lote.
2. **Fichas com menos de 100 linhas**: A extração foi incompleta. Reexecutar o lote com instrução mais específica ou fazer um "lote de enriquecimento" pós-extração.
3. **Template auto-complete**: Se o Gemini gerar dezenas de itens idênticos (ex: 100 sprints placeholder), ele ficou sem informação específica. Adicionar constraint "máximo N itens" no prompt.
4. **Build cache do Docker**: `docker compose build --no-cache` pode não invalidar cache de layer se o Dockerfile não mudou. Usar `docker compose down --rmi all` antes para garantir.
5. **`command:` do compose sobrescreve CMD**: Se o container não inicia com o comando esperado, verificar se o `docker-compose.yml` tem `command:` que sobrescreve o `CMD` do Dockerfile.

## Verificação Pós-Geração

```bash
# Fase A: verificar fichas
ls {output_dir}/ | wc -l          # deve bater com o esperado
wc -l {output_dir}/*.md | tail -1 # total de linhas

# Fase B/C: verificar documento final
wc -l {output_file}               # deve ser 3000+
grep -c "filler_pattern" {output_file}  # deve ser 0
```
