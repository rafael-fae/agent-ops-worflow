# Pipeline de Extração — Gemini (Chunking)

## Problema

Gemini CLI estoura o limite de contexto quando alimentado com 100+ arquivos de uma vez. Sintoma: começa a colar arquivos fonte brutos no output em vez de sintetizar.

## Solução: Pipeline de 3 Fases

### Fase A — Extração (múltiplas sessões)
- Dividir os arquivos fonte em lotes de ~15
- Cada sessão processa um lote e gera "fichas técnicas" (.md por módulo)
- Fichas com formato padronizado: Propósito, Modelos, Regras, Fluxos, Telas, Integrações

### Fase B — Compilação (1 sessão)
- Ler as fichas geradas (não os 100+ arquivos originais)
- Fichas são densas — ~150 linhas cada, sem ruído
- Sintetizar no documento final unificado

### Fase C — Produto final (1 sessão)
- Usar o documento da Fase B + fichas como contexto
- Gerar artefato final (PRD, Blueprint, etc.)

## Regras para prompts de extração
1. "VOCÊ É UM EXTRATOR, NÃO UM ESCRITOR" — deixar claro que não é para gerar o documento final
2. Lista exata de arquivos a processar naquela sessão
3. Formato de saída padronizado para cada ficha
4. "Se atingir 80% do contexto, PARE e salve o que já fez"

## Exemplo real
- Projeto {{PROJECT_NAME}}: 40 arquivos Obsidian → 3 lotes → 24 fichas → PRD 5.343 linhas + Blueprint 6.806 linhas
- Funcionou porque cada sessão processou no máximo 14 arquivos
