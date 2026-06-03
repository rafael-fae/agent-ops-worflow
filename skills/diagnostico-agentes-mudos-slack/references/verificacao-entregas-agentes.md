# Verificação de Entregas de Agentes

Agentes podem alucinar entregas — descrever arquivos que não existem no disco ou cujo conteúdo não corresponde ao alegado. Este padrão ocorreu 3 vezes em 29/05/2026 ({{AUDITOR}}-mac 2x, {{FRONTEND_ENGINEER}}-mac 1x).

## Checklist de verificação

Após QUALQUER claim de criação/edição de arquivo:

```bash
# 1. Arquivo existe?
ls -la /caminho/do/arquivo.md

# 2. Tamanho confere?
wc -l /caminho/do/arquivo.md

# 3. Conteúdo inicial confere com o descrito?
head -30 /caminho/do/arquivo.md

# 4. Foi realmente modificado recentemente?
find /caminho/base -name "*.md" -mmin -30 -type f
```

## Sinais de alucinação

- Agente reporta contagem de linhas diferente do real (ex: "361 linhas" vs 173 reais)
- Agente descreve seções/conteúdo que não existe no arquivo
- Agente usa nomes de arquivo diferentes dos que estão no disco
- Arquivo não foi modificado nas últimas horas (timestamp antigo)

## Como lidar

1. Confronte com evidência concreta (wc -l, ls -la, head)
2. Peça path exato — agentes frequentemente referenciam paths de memória
3. Se agente insistir em 2 verificações, o arquivo não existe — encerre
4. Aceite o trabalho real (análises na thread, contribuições ao índice) e mova adiante
5. Para tarefas críticas: execute diretamente em vez de re-delegar

## Casos reais

### {{AUDITOR}}-mac (29/05, 1ª ocorrência)
- Afirmou: INDICE-MESTRE.md com "361 linhas, 10 auditorias A01-A10, 6 deep-dives, ~35 gaps, 12 obsoletos"
- Real: 173 linhas, estrutura diferente, nenhum desses conteúdos
- Ação: Confrontada com wc -l + head. Aceito trabalho real (14 gaps já entregues).

### {{AUDITOR}}-mac (29/05, 2ª ocorrência)
- Afirmou: G04-WHATSAPP-CODIGO.md (15.7KB) e G07-FLUXO-CAIXA-CODIGO.md (13.5KB) criados
- Real: Nenhum dos arquivos existe em disco (find retornou vazio)
- Status: Confrontada. Aguardando materialização.

### {{FRONTEND_ENGINEER}}-mac (29/05)
- Afirmou: criou 6 arquivos (`01-principios-e-tokens.md`, `02-padroes-de-componentes.md`, etc.)
- Real: Arquivos reais têm nomes diferentes (`UI-ARCHITECTURE.md`, `UI-COMPONENT-PATTERNS.md`, etc.) e timestamps de 27/05
- Ação: Confrontada. Trabalho aceito como análise/confirmação.
