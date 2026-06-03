# Padrão: Chunking para evitar estouro de contexto do Gemini

> Descoberto em 31/05/2026 durante geração do PRD (9499 linhas, só 702 reais)

## Problema

O Gemini, ao processar 100+ arquivos de uma vez, estoura o limite de contexto e começa a:
1. Colar arquivos fonte brutos como "anexo" (filler)
2. Gerar templates repetitivos (100× mesmo padrão)
3. Produzir conteúdo genérico em vez de específico

## Solução: Pipeline de 3 Fases

```
FASE A (Extração)          FASE B (Síntese)         FASE C (Blueprint)
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│ Lotes de ~15     │       │ Lê 24 fichas     │       │ Lê PRD + fichas │
│ arquivos fonte   │  →   │ (não 100+ arqs)  │  →   │ (não 100+ arqs) │
│ ↓                │       │ ↓                │       │ ↓                │
│ 1 ficha .md por  │       │ Documento final  │       │ Documento final  │
│ módulo           │       │ (3000+ linhas)   │       │ (4000+ linhas)   │
└─────────────────┘       └─────────────────┘       └─────────────────┘
   ~3-5 sessões             1 sessão                 1 sessão
```

### Fase A — Extração
- Dividir fontes em lotes de ~15 arquivos
- Cada lote gera fichas técnicas em `docs/prd/modulos/XX-nome.md`
- Formato padronizado: Propósito, Modelos, Regras, Fluxos, Telas, Integrações
- Mínimo 150 linhas por ficha (densidade, não volume)
- Se estourar contexto, parar e reportar quais fichas faltaram

### Fase B — Compilação
- Ler APENAS as fichas (não os arquivos fonte originais)
- Sintetizar no documento final
- Fichas têm alta densidade → ~1800 linhas de entrada produzem ~5000 linhas de saída

### Fase C — Blueprint/Derivados
- Usar o documento final + fichas como entrada
- Nunca reler os arquivos fonte brutos

## Regras Anti-Filler

1. **"Máximo N itens"** no prompt — ex: "Máximo 15 sprints" evita 100 sprints template
2. **"NOME REAL, não placeholder"** — ex: "Use Admin, Dentista, Recepcionista, não Role_0, Role_1"
3. **"Se não tiver informação específica, MARQUE COMO PENDENTE"** — evita invenção
4. **"Leia primeiro, escreva depois"** — evita começar a gerar antes de processar todas as fontes
5. **"Se atingir 80% do contexto, PARE e salve"** — evita o dump de arquivos brutos

## Template de Prompt Anti-Filler

```markdown
## REGRA ZERO — VOCÊ É UM [EXTRATOR|COMPILADOR]

- ❌ NÃO escreva o documento completo
- ❌ NÃO invente informações
- ❌ NÃO use templates automáticos (nada de "Item_N")
- ✅ LEIA cada arquivo listado
- ✅ EXTRAIA informações estruturadas
- ✅ Use nomes REAIS, não placeholders
- ✅ Se atingir 80% do contexto, PARE e reporte
```
