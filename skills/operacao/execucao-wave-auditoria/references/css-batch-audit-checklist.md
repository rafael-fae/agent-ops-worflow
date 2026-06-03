# Checklist de Auditoria — CSS Gerado por Batches Opus

## Contexto

Quando agentes geram CSS via múltiplos batches do Opus 4.7 e concatenam com `cat`, artefatos de concatenação são comuns. Esta checklist cobre a auditoria de qualidade para esses arquivos.

## Gatilho

- Arquivo `.css` foi gerado por concatenação de 2+ batches do Opus
- Agente reporta "CSS gerado, N linhas, M classes"
- Task de Design System ou Frontend com entrega de CSS

## Checklist de Verificação

### 1. Contagem de Linhas

```bash
wc -l design_system/tokens.css design_system/components.css
```

Comparar com o reportado pelo agente. Tolerância: ±5 linhas.

### 2. Markdown Code Fences (CRÍTICO)

```bash
grep -c '```' arquivo.css
```

**Zero tolerado.** Cada ` ``` ` quebra o parse CSS. Se > 0:
```bash
sed -i '' '/^```$/d' arquivo.css
```

Re-verificar após remoção.

### 3. Brace Balance

```bash
python3 -c "f=open('arquivo.css').read(); print(f.count('{') - f.count('}'))"
```

- **0**: OK
- **≠ 0**: Chaves fantasmas de wrappers de batch. Localizar com script de rastreamento:

```python
lines = open('arquivo.css').readlines()
balance = 0
for i, line in enumerate(lines, 1):
    balance += line.count('{') - line.count('}')
    if balance < 0:
        print(f"Line {i}: balance={balance} | {line.rstrip()}")
```

**Impacto:** Modern browsers são tolerantes — `}` extra no top-level é ignorada. Mas é débito técnico.

### 4. Batch Headers

```bash
grep -in 'BATCH' arquivo.css
```

Headers como `/* {{PROJECT_NAME_UPPER}} — DESIGN SYSTEM (BATCH 4) */` são artefatos de concatenação. Não quebram parse (estão em comentários), mas poluem CSS de produção.

### 5. Custom Properties

```bash
grep -c '\-\-ds-' tokens.css
```

**Atenção:** `grep -c` conta TODAS as ocorrências, incluindo referências em valores e comentários. Para contar definições reais no `:root`:

```bash
sed -n '/:root {/,/^}/p' tokens.css | grep -c '\-\-ds-'
```

### 6. Unique Classes

```bash
grep -oE '\.ds-[a-zA-Z0-9_-]+' components.css | sort -u | wc -l
```

Comparar com cobertura esperada (ex: 20 componentes → ~200 classes).

### 7. Cobertura de Componentes

Para cada componente esperado, verificar presença no CSS:

```bash
for c in btn input table modal card tabs badge toast dropdown sidebar breadcrumb pagination empty-state loading form-group avatar tooltip progress alert; do
  count=$(grep -ci "$c" components.css)
  echo "  $c: $count matches"
done
```

**Atenção:** `grep -ci` não distingue classe CSS de comentário ou seletor composto. Se count < 3 para um componente, inspecionar manualmente.

### 8. Dark Mode

```bash
grep -c 'prefers-color-scheme\|data-theme.*dark' arquivo.css
```

Zero = sem dark mode. Esperado: dezenas de referências.

### 9. Animações & Responsivo

```bash
grep -c '@keyframes' components.css
grep -c '@media' components.css
```

Zero em qualquer = sem animações ou sem responsividade.

### 10. Sintaxe CSS (Validação Rápida)

```bash
python3 -c "
import re
f = open('arquivo.css').read()
# Verificar seletor sem bloco
selectors = re.findall(r'([^{]+)\{', f)
for s in selectors:
    if s.strip().startswith('/*'):
        continue  # comentário
# Verificar @import (proibido em standalone)
if '@import' in f:
    print('WARNING: @import encontrado — arquivo não é standalone')
"
```

## Resumo da Auditoria

| Item | Comando | Critério |
|------|---------|----------|
| Linhas | `wc -l` | Comparar com report |
| Fences | `grep -c '\`\`\`'` | **0** |
| Brace balance | `python3 -c "..."` | **0** (ideal) |
| Batch headers | `grep -i BATCH` | 0 (ideal) |
| Custom props | `grep -c '\-\-ds-'` | Comparar com report |
| Classes únicas | `grep -oE '\.ds-...' \| sort -u \| wc -l` | Comparar com report |
| Componentes | `grep -ci` por componente | ≥3 cada |
| Dark mode | `grep -c 'data-theme'` | > 0 |
| Animações | `grep -c '@keyframes'` | > 0 |
| Responsivo | `grep -c '@media'` | > 0 |

## Pitfalls

- **`grep -P` não existe no macOS.** Usar `grep -oE` para regex estendida, ou `python3 -c` para padrões complexos.
- **Brace balance ≠ 0 não é bloqueante.** CSS moderno tolera `}` extras. Mas é sinal de concatenação descuidada.
- **Contagem de tokens inclui referências.** `--ds-primary` aparece como definição no `:root` e como uso em `components.css`. Separar contagens.
- **Checkboxes da task ≠ evidência real.** Verificar SEMPRE os arquivos no disco, independente do que o agente reportou.
