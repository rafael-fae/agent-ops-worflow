# Pitfall: read_file corrompe arquivos quando usado como fonte para write_file/patch

## Sintoma

Arquivo YAML/Python/JS aparece com números de linha literais no conteúdo:

```yaml
     1|model:
     2|  default: deepseek-v4-pro
    10|     9|  bot_user_name: kaladin   ← numeração aninhada
```

## Causa

O `read_file` do Hermes formata a saída com números de linha (ex: `     1|model:`). Se este output for usado como:
- `content` no `write_file`
- `old_string` no `patch`

...os números de linha viram texto LITERAL no arquivo, corrompendo-o.

A numeração pode aninhar se o arquivo já foi corrompido uma vez antes (ex: `    10|     9|  bot_user_name`).

## Correção

Usar `terminal` com `cat` para obter conteúdo limpo antes de editar:

```bash
# ✅ CORRETO: ler via cat (sem numeração)
{{OVH_SSH_COMMAND}} "cat /path/to/file"

# ❌ ERRADO: usar read_file como fonte para edição
result = read_file(path)
content = result['content']  # contém "     1|..." — NÃO USAR para write_file
```

## Recuperação

Se o arquivo foi corrompido e não há git:

```bash
# Verificar se o início do arquivo está OK
head -5 /path/to/file

# Se tiver numeração, restaurar de backup ou reescrever
# Opção 1: git checkout (se existe)
git checkout -- /path/to/file

# Opção 2: reescrever a partir de template limpo
python3 << 'EOF'
# Usar conteúdo conhecido (ex: config de outro agente similar)
with open('/path/to/clean_reference', 'r') as src:
    content = src.read()
# Ajustar campos específicos
content = content.replace('bot_user_id: "OLD"', 'bot_user_id: "NEW"')
with open('/path/to/corrupted', 'w') as dst:
    dst.write(content)
EOF

# Opção 3: se o conteúdo original ainda está lá, extrair removendo numeração
python3 << 'EOF'
import re
with open('/path/to/corrupted', 'r') as f:
    lines = f.readlines()
clean = []
for line in lines:
    # Remove numeração no formato "     1|" ou "    10|     9|"
    cleaned = re.sub(r'^\s*\d+\|\s*', '', line)
    clean.append(cleaned)
with open('/path/to/corrupted', 'w') as f:
    f.writelines(clean)
print('Numeração removida')
EOF
```

## Prevenção

- `read_file` é seguro para **inspeção visual** (ex: mostrar ao usuário)
- Para **edição**, sempre obter conteúdo via `terminal("cat ...")`
- O `execute_code` com `from hermes_tools import read_file` também retorna conteúdo com numeração — mesmo cuidado
