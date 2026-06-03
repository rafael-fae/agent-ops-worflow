# Operações Seguras em Arquivos de Perfil Hermes

## PITFALL CRÍTICO: execute_code read_file/write_file corrompe arquivos

**Descoberto em 29/05/2026 durante correção em lote de 6 agentes Mac.**

### O problema

No `execute_code`, a função `read_file` do `hermes_tools` retorna conteúdo COM prefixos de número de linha:

```
1|model:
2|  default: deepseek-v4-flash
3|  provider: opencode-go
```

Quando esse conteúdo é passado para `write_file`, os prefixos são escritos no disco:

```
1|     1|model:
2|     2|  default: deepseek-v4-flash
```

Operações repetidas de read→write multiplicam os prefixos (`1|     1|     1|model:`).

### Arquivos afetados

- `config.yaml` — YAML torna-se inválido (duplicação de chaves, valores com prefixos)
- `TEAM.md`, `AGENTS.md` — markdown corrompido com prefixos de linha
- `SOUL.md`, `IDENTITY.md` — idem

### Como detectar

```bash
head -1 arquivo.md
# Corrompido: "1|# Título"
# Limpo:      "# Título"
```

### Correção

Arquivos rastreados pelo git: `git checkout -- arquivo`
Arquivos não rastreados (.gitignore): reescrever do zero com `write_file` (ferramenta principal, não a do execute_code)

### Prevenção — use estas ferramentas, NUNCA execute_code read/write

| Ferramenta | Segura? | Uso |
|---|---|---|
| `patch` (tool principal) | ✅ SIM | old_string/new_string direto, sem prefixos |
| `write_file` (tool principal) | ✅ SIM | Conteúdo limpo, sem prefixos |
| `sed` no `terminal()` | ✅ SIM | Manipulação direta de arquivos |
| `perl -i -pe` no `terminal()` | ✅ SIM | Alternativa ao sed com melhor suporte a newlines |
| `execute_code` + `read_file` + `write_file` | ❌ NÃO | Adiciona prefixos de linha |

### BSD sed (macOS) — newline em replacement

BSD sed no macOS NÃO interpreta `\n` em strings de substituição. Use:

```bash
# ERRADO (macOS):
sed -i '' 's/old/new\nline/g' arquivo

# CERTO (macOS):
perl -i -pe 's/old/new\nline/g' arquivo
```

Ou use a ferramenta `patch` que lida com quebras de linha em qualquer plataforma.

### Arquivos não rastreados pelo git

Após a emancipação dos agentes Mac (commit 6fcfa04), os seguintes arquivos foram removidos do tracking:
- `SOUL.md`, `IDENTITY.md`, `TEAM.md`, `AGENTS.md`, `USER.md`, `TOOLS.md`, `HEARTBEAT.md`
- `memories/MEMORY.md`, `memories/USER.md`

Se corrompidos, NÃO podem ser restaurados com `git checkout`. Precisam ser reescritos manualmente.

### Quando usar execute_code para manipular arquivos

Apesar do pitfall, `execute_code` pode ser usado para:
- Análise de arquivos (read-only) — desde que o código extraia o conteúdo sem depender do formato
- Processamento de dados que não serão re-escritos nos arquivos de perfil
- Operações em arquivos fora dos diretórios de perfil

**Regra de ouro:** Se for escrever de volta em arquivos de perfil Hermes, use `sed`/`perl` no `terminal()` ou as ferramentas `patch`/`write_file`. Nunca `execute_code`.
