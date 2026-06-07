# 11 — Piloto DuckDB Cache: Cache Local com DuckDB + Markdown Snapshots

> **Propósito deste documento:** Apresentar o Piloto DuckDB Cache — uma solução de cache
> local para consultas de banco de dados que transforma resultados SQL em arquivos
> markdown legíveis por humanos e agentes de IA. Inclui o problema, a arquitetura,
> as 3 camadas de segurança, o cron job de automação e como reutilizar em seus projetos.
>
> **Público-alvo:** Desenvolvedores, analistas de dados, e entusiastas de automação
> que querem acelerar consultas repetitivas e dar contexto rápido a agentes de IA.

---

## Sumário

1. [O Problema — Por que precisamos de cache?](#seção-1-o-problema--por-que-precisamos-de-cache)
2. [A Solução — DuckDB + Markdown Snapshots](#seção-2-a-solução--duckdb--markdown-snapshots)
3. [Arquitetura do Pipeline](#seção-3-arquitetura-do-pipeline)
4. [O Arquivo `sources.yaml`](#seção-4-o-arquivo-sourcesyaml)
5. [O Script `export-cache.sh`](#seção-5-o-script-export-cachesh)
6. [O Formato do Snapshot Markdown](#seção-6-o-formato-do-snapshot-markdown)
7. [O Cron Job](#seção-7-o-cron-job)
8. [Como Reutilizar para Seus Projetos](#seção-8-como-reutilizar-para-seus-projetos)
9. [Benefícios](#seção-9-benefícios)

---

## Seção 1: O Problema — Por que precisamos de cache?

Imagine que você tem um banco de dados PostgreSQL com milhares de registros. Todo dia,
seus agentes de IA ou suas ferramentas de análise precisam fazer as **mesmas perguntas**:

- "Quantos usuários ativos temos hoje?"
- "Qual a contagem de registros por categoria?"
- "Liste os 10 maiores clientes por faturamento."

Cada vez que uma dessas perguntas é feita, o banco de dados precisa:

1.  Receber a conexão
2.  Autenticar
3.  Planejar a consulta (query planner)
4.  Escanear as tabelas (disk I/O)
5.  Calcular as agregações (CPU)
6.  Devolver os dados serializados pela rede

Isso é **caro** — especialmente se os dados mudam pouco e a consulta é sempre a mesma.

### O desperdício de recursos

| Situação | Sem cache | Com cache |
|----------|-----------|-----------|
| Consulta executada | 100 vezes/dia | 1 vez (a primeira) |
| Tempo médio de resposta | 2-5 segundos | < 50ms (arquivo local) |
| Carga no PostgreSQL | Alta (conexões + queries) | Mínima (só a refresh) |
| Disponibilidade para agentes | Depende de rede/PG | Imediata (arquivo local) |

### O gargalo com agentes de IA

Agentes Hermes (e outros agentes de IA) **leem arquivos markdown** com muito mais
eficiência do que executam SQL. Cada consulta SQL exige:

- Um passo de `think` para montar a consulta
- Uma chamada de ferramenta (tool call)
- Esperar o banco responder
- Interpretar o resultado tabular

Se os dados já estiverem em um arquivo `.md` no projeto, o agente **leu e entendeu**
em milissegundos, sem precisar tocar no banco.

### O conceito de cache

Cache é uma **cópia local e rápida** de um dado que é caro de obter da fonte original.
É como sua geladeira: em vez de ir ao supermercado (banco de dados) toda vez que quer
comer algo (consultar), você mantém uma pequena porção em casa (cache). De vez em
quando, você reabastece (refresh).

---

## Seção 2: A Solução — DuckDB + Markdown Snapshots

A solução combina três tecnologias simples e poderosas:

### 2.1 DuckDB — O banco SQL embarcado para análise

**DuckDB** é um banco de dados SQL embarcado, assim como o SQLite, mas **otimizado
para cargas analíticas** (OLAP). Enquanto o SQLite é excelente para transações
(inserir, atualizar, deletar), o DuckDB brilha em consultas que agregam muitos dados
— exatamente o que precisamos para extrair snapshots.

Principais características:

| Característica | DuckDB | PostgreSQL | SQLite |
|----------------|--------|------------|--------|
| Modo de operação | Embutido (library) | Servidor separado | Embutido |
| Otimizado para | Análise (OLAP) | Geral (OLTP) | Transações (OLTP) |
| Consultas agregadas | Muito rápido | Bom | Lento |
| Dependência externa | Nenhuma (standalone) | Servidor rodando | Nenhuma |

### 2.2 DuckDB CLI — Ferramenta de linha de comando

O DuckDB CLI é um executável único (`duckdb`) que abre um shell SQL interativo ou
executa comandos SQL direto via argumento:

```bash
duckdb -c "SELECT 1 + 1 AS resultado;"
```

Isso significa que podemos chamar o DuckDB de **qualquer script shell** sem precisar
de um servidor rodando. Perfeito para automação.

### 2.3 postgres_scanner — Ponte para o PostgreSQL

O DuckDB possui um ecossistema de extensões. Uma das mais úteis é a
**postgres_scanner**, que permite conectar diretamente a um banco PostgreSQL e
consultar suas tabelas como se fossem locais:

```sql
ATTACH 'host=localhost port=5432 dbname=seu_banco' AS pg_db (TYPE postgres);
SELECT * FROM pg_db.tabela_exemplo;
```

Isso significa que o DuckDB vira um **ETL leve**: ele busca os dados no PostgreSQL,
processa localmente, e devolve o resultado na hora.

### 2.4 Markdown Snapshots — O formato universal para humanos e agentes

Depois que o DuckDB executa a consulta, o resultado é convertido para um arquivo
**Markdown** com metadados no **frontmatter** (YAML entre `---`).

**Por que Markdown?**

> Agentes Hermes LEEM markdown. Eles não executam SQL. Se o dado está em markdown,
> o agente simplesmente abre o arquivo e já entende o contexto — sem tool calls,
> sem conexão de rede, sem demora.

O formato escolhido:

```markdown
---
source: seed-counts
exported_at: 2026-06-06T16:26:23-04:00
rows: 42
query: SELECT tenant, COUNT(*)...
schedule: 24h
---

# Seed Counts

| tenant   | count |
|----------|-------|
| Tenant A | 15    |
| Tenant B | 27    |
```

Humanos leem o título, a tabela. Agentes leem o frontmatter e o corpo. Todos felizes.

---

## Seção 3: Arquitetura do Pipeline

O pipeline completo segue este fluxo:

```
┌────────────────────────────────────────────────────────────┐
│                    sources.yaml                             │
│  (configuração declarativa das fontes de dados)            │
└────────────────────┬───────────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────────────┐
│                  export-cache.sh                            │
│         (orquestrador principal em bash)                    │
└────────────────────┬───────────────────────────────────────┘
                     │
     ┌───────────────┼───────────────┐
     │               │               │
     ▼               ▼               ▼
┌──────────┐  ┌──────────┐  ┌──────────────────┐
│ DuckDB   │  │ DuckDB   │  │ DuckDB           │
│ CLI +    │  │ CLI +    │  │ CLI +            │
│ postgres │  │ postgres │  │ postgres         │
│ scanner  │  │ scanner  │  │ scanner          │
│          │  │          │  │                  │
│ Consulta │  │ Consulta │  │ Consulta         │
│ Fonte A  │  │ Fonte B  │  │ Fonte C          │
└────┬─────┘  └────┬─────┘  └────────┬─────────┘
     │             │                 │
     └──────┬──────┴────────┬────────┘
            │               │
            ▼               ▼
┌────────────────────────────────────────────────────────────┐
│              3 Camadas de Segurança                        │
│                                                           │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ 1. Safe-write: .new → valida → mv                  │  │
│  │    (escreve em arquivo temporário)                  │  │
│  └─────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ 2. Validação Python: 6 campos do frontmatter       │  │
│  │    (verifica integridade dos metadados)             │  │
│  └─────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ 3. Canary de contagem: >50% diferente? TRAVA       │  │
│  │    (alerta de regressão silenciosa)                 │  │
│  └─────────────────────────────────────────────────────┘  │
└────────────────────────┬──────────────────────────────────┘
                         │
                         ▼
┌────────────────────────────────────────────────────────────┐
│              snapshots/*.md                                │
│  (notas markdown com frontmatter de data lineage)          │
│                                                           │
│  ├── docs/data/snapshots/seed-counts.md                   │
│  ├── docs/data/snapshots/usuarios-ativos.md               │
│  └── docs/data/snapshots/top-clientes.md                  │
└────────────────────────────────────────────────────────────┘
```

### Detalhamento do fluxo

1. **Entrada:** O script lê o arquivo `sources.yaml` que lista todas as fontes de
   dados a serem consultadas.
2. **Processamento paralelo:** Para cada fonte, o script dispara uma consulta
   via DuckDB CLI com a extensão postgres_scanner.
3. **Resultado bruto:** O DuckDB devolve o resultado CSV/JSON.
4. **Conversão:** O resultado é convertido para markdown com frontmatter.
5. **3 camadas de segurança:** O arquivo passa por validação antes de substituir
   o snapshot anterior (explicado em detalhes na Seção 5).
6. **Snapshot final:** O arquivo `.md` validado é salvo no diretório de snapshots.

---

## Seção 4: O Arquivo `sources.yaml`

O `sources.yaml` é o **coração da configuração**. Ele declara quais consultas
executar, com que frequência, e onde salvar o resultado.

### Formato YAML declarativo

O YAML é um formato de serialização legível por humanos, usado extensivamente
em ferramentas DevOps (Docker Compose, Kubernetes, GitHub Actions). Cada fonte
de dados é um bloco na lista `sources`.

### Estrutura completa

```yaml
# sources.yaml — Declaração das fontes de dados para cache
# Cada fonte gera um snapshot markdown.

sources:
  - name: seed-counts
    description: "Contagem de registros seed por tenant"
    query: |
      SELECT tenant, COUNT(*) as total
      FROM core_procedimento
      GROUP BY tenant
      ORDER BY tenant
    schedule: 24h
    output: docs/data/snapshots/seed-counts.md

  - name: usuarios-ativos
    description: "Usuários que acessaram nos últimos 7 dias"
    query: |
      SELECT u.nome, u.email, u.ultimo_acesso
      FROM auth_user u
      WHERE u.ultimo_acesso >= CURRENT_DATE - INTERVAL '7 days'
      ORDER BY u.ultimo_acesso DESC
    schedule: 6h
    output: docs/data/snapshots/usuarios-ativos.md

  - name: metricas-gerais
    description: "Métricas agregadas do sistema"
    query: |
      SELECT
        COUNT(DISTINCT tenant) as total_tenants,
        COUNT(*) as total_registros,
        AVG(tempo_medio) as tempo_medio_geral
      FROM vw_metricas_sistema
    schedule: 12h
    output: docs/data/snapshots/metricas-gerais.md
```

### Campos de cada fonte

| Campo | Obrigatório | Descrição |
|-------|-------------|-----------|
| `name` | Sim | Identificador único da fonte (sem espaços) |
| `description` | Não | Descrição legível do que a consulta retorna |
| `query` | Sim | Consulta SQL a ser executada no PostgreSQL |
| `schedule` | Sim | Intervalo entre refreshes (ex: `24h`, `6h`, `12h`, `1h`) |
| `output` | Sim | Caminho do arquivo `.md` de saída |

### Dica importante sobre a query

Escreva queries que retornem **dados estáveis e resumidos**. O objetivo não é
substituir o PostgreSQL para consultas transacionais, mas sim criar **visões
consolidadas** que mudam pouco. Evite:

- `SELECT *` de tabelas grandes
- Joins complexos entre muitas tabelas
- Dados binários ou blobs

Prefira:

- Agregações (`COUNT`, `SUM`, `AVG`, `GROUP BY`)
- Amostras ordenadas (`LIMIT 100`)
- Listas consolidadas com joins bem definidos

---

## Seção 5: O Script `export-cache.sh`

O `export-cache.sh` é o orquestrador que dá vida ao pipeline. Ele lê o
`sources.yaml`, itera sobre cada fonte, executa a consulta via DuckDB,
valida o resultado, e salva o snapshot.

### Fluxo completo do script

```
1.  Verificar dependências (duckdb, python3, yq/jq)
2.  Carregar sources.yaml
3.  Para cada fonte em sources:
    │
    ├─ 3.1. Executar query via DuckDB CLI + postgres_scanner
    │      └─ Gera arquivo .tmp (resultado bruto CSV)
    │
    ├─ 3.2. Converter CSV → Markdown com frontmatter
    │      └─ Gera arquivo .new (markdown temporário)
    │
    ├─ ─ ─ ─ 3 Camadas de Segurança ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
    │
    ├─ 3.3. Safe-write: arquivo .new ainda não substituiu o .md
    │
    ├─ 3.4. Validar frontmatter (Python):
    │      ├─ source (string, não vazio)
    │      ├─ exported_at (ISO datetime válido)
    │      ├─ rows (inteiro >= 0)
    │      ├─ query (string, não vazio)
    │      ├─ schedule (formato Xh, Xd, etc.)
    │      └─ sha256 (hash do conteúdo, integridade)
    │
    ├─ 3.5. Canary de contagem:
    │      ├─ Lê rows do snapshot anterior (se existir)
    │      ├─ Compara com rows do novo snapshot
    │      └─ Se diferença > 50% → TRAVA (alerta)
    │
    ├─ 3.6. Se todas as validações passam:
    │      └─ mv .new → .md (substituição atômica)
    │
    └─ 3.7. Log: sucesso/erro com timestamp
```

### 5.1 Safe-write (Camada 1)

A primeira camada de segurança impede que um arquivo corrompido ou incompleto
substitua o snapshot válido.

```bash
#!/usr/bin/env bash
# Estratégia safe-write: escreve em .new, depois move

OUTPUT_FILE="docs/data/snapshots/seed-counts.md"
TEMP_FILE="${OUTPUT_FILE}.new"

# Escreve o markdown no arquivo temporário
cat > "$TEMP_FILE" << 'MARKDOWN'
---
source: seed-counts
exported_at: 2026-06-06T16:26:23-04:00
rows: 42
query: SELECT tenant, COUNT(*)...
schedule: 24h
---
... conteúdo ...
MARKDOWN

# Só depois de validado, move o .new para .md (substituição atômica)
if python3 validar_frontmatter.py "$TEMP_FILE"; then
    mv "$TEMP_FILE" "$OUTPUT_FILE"
    echo "✅ Snapshot atualizado: $OUTPUT_FILE"
else
    rm -f "$TEMP_FILE"
    echo "❌ Validação falhou. Snapshot anterior mantido."
    exit 1
fi
```

Por que `.new` → `mv`?

- Se o script morrer no meio da escrita, o `.new` fica incompleto, mas o `.md`
  original permanece intacto
- `mv` é uma operação **atômica** no mesmo sistema de arquivos: o arquivo de
  destino é substituído instantaneamente
- Nenhum leitor (humano ou agente) vai ler um arquivo parcialmente escrito

### 5.2 Validação Python do frontmatter (Camada 2)

A segunda camada verifica se o frontmatter YAML contém todos os campos
obrigatórios com tipos corretos.

```python
#!/usr/bin/env python3
"""validar_frontmatter.py — Valida os 6 campos do frontmatter do snapshot."""

import sys
import yaml
import re
from datetime import datetime

CAMPOS_OBRIGATORIOS = ["source", "exported_at", "rows", "query", "schedule"]


def validar_iso_datetime(valor):
    """Verifica se o valor é uma data ISO 8601 válida."""
    try:
        datetime.fromisoformat(valor)
        return True
    except (ValueError, TypeError):
        return False


def validar_schedule(valor):
    """Valida formato de schedule: número seguido de h, d, m (ex: 24h, 7d)."""
    return bool(re.match(r'^\d+[hdm]$', str(valor)))


def validar_frontmatter(arquivo):
    """Valida os 6 campos do frontmatter."""
    with open(arquivo, 'r') as f:
        conteudo = f.read()

    # Extrai frontmatter entre ---
    partes = conteudo.split('---')
    if len(partes) < 3:
        print("❌ Frontmatter não encontrado (delimitadores --- ausentes)")
        return False

    try:
        metadata = yaml.safe_load(partes[1])
    except yaml.YAMLError as e:
        print(f"❌ Erro ao parsear YAML: {e}")
        return False

    if not isinstance(metadata, dict):
        print("❌ Frontmatter não é um dicionário válido")
        return False

    # Valida campo por campo
    erros = []

    # 1. source: string não vazia
    source = metadata.get('source')
    if not source or not isinstance(source, str):
        erros.append("❌ Campo 'source' ausente ou inválido (deve ser string)")

    # 2. exported_at: ISO datetime
    exported_at = metadata.get('exported_at')
    if not exported_at or not validar_iso_datetime(exported_at):
        erros.append(f"❌ Campo 'exported_at' ausente ou inválido: {exported_at}")

    # 3. rows: inteiro >= 0
    rows = metadata.get('rows')
    if rows is None or not isinstance(rows, int) or rows < 0:
        erros.append(f"❌ Campo 'rows' ausente ou inválido (deve ser int >= 0): {rows}")

    # 4. query: string não vazia
    query = metadata.get('query')
    if not query or not isinstance(query, str):
        erros.append("❌ Campo 'query' ausente ou inválido (deve ser string)")

    # 5. schedule: formato Xh, Xd, Xm
    schedule = metadata.get('schedule')
    if not schedule or not validar_schedule(schedule):
        erros.append(f"❌ Campo 'schedule' ausente ou inválido: {schedule}")

    # 6. sha256: hash SHA-256 (opcional mas recomendado)
    sha256 = metadata.get('sha256')
    if sha256 and not re.match(r'^[a-f0-9]{64}$', str(sha256)):
        erros.append(f"❌ Campo 'sha256' inválido (deve ser hex 64 caracteres): {sha256}")

    if erros:
        for erro in erros:
            print(erro)
        return False

    print(f"✅ Frontmatter válido: {rows} linhas, fonte '{source}'")
    return True


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: validar_frontmatter.py <arquivo.md>")
        sys.exit(1)

    arquivo = sys.argv[1]
    if not validar_frontmatter(arquivo):
        sys.exit(1)
```

**Os 6 campos validados:**

| # | Campo | Tipo | O que verifica |
|---|-------|------|----------------|
| 1 | `source` | string | Não vazio, corresponde ao nome da fonte |
| 2 | `exported_at` | datetime | Formato ISO 8601 válido |
| 3 | `rows` | int | >= 0 (número de linhas retornadas) |
| 4 | `query` | string | Não vazio (a SQL que gerou os dados) |
| 5 | `schedule` | string | Formato `Xd`, `Xh` ou `Xm` |
| 6 | `sha256` | string (opc.) | Hash hexadecimal de 64 caracteres |

### 5.3 Canary de contagem (Camada 3)

A terceira camada é um **canary** — um alerta precoce de que algo mudou
drasticamente. Se a contagem de linhas do snapshot novo for mais de 50%
diferente do anterior, o script trava.

```bash
#!/usr/bin/env bash
# Canary de contagem — detecta regressões silenciosas

canary_check() {
    local ARQUIVO="$1"       # Caminho do snapshot anterior (ex: .md)
    local NOVAS_LINHAS="$2"  # Contagem do novo snapshot
    local LIMIAR=50          # Percentual máximo de diferença

    # Se não existe snapshot anterior, é a primeira execução — ok
    if [ ! -f "$ARQUIVO" ]; then
        echo "  ℹ️  Primeira execução — canary ignorado"
        return 0
    fi

    # Extrai a contagem anterior do frontmatter
    local LINHAS_ANTERIORES
    LINHAS_ANTERIORES=$(grep '^rows:' "$ARQUIVO" | head -1 | cut -d' ' -f2)

    # Se não conseguir extrair, ignora (pode ser formato antigo)
    if [ -z "$LINHAS_ANTERIORES" ] || [ "$LINHAS_ANTERIORES" -eq 0 ] 2>/dev/null; then
        echo "  ⚠️  Não foi possível ler contagem anterior — canary ignorado"
        return 0
    fi

    # Calcula diferença percentual
    local DIFERENCA
    local MAIOR=$LINHAS_ANTERIORES
    local MENOR=$NOVAS_LINHAS

    if [ "$NOVAS_LINHAS" -gt "$LINHAS_ANTERIORES" ]; then
        MAIOR=$NOVAS_LINHAS
        MENOR=$LINHAS_ANTERIORES
    fi

    DIFERENCA=$(( (MAIOR - MENOR) * 100 / MAIOR ))

    echo "  📊 Canary: anterior=$LINHAS_ANTERIORES novo=$NOVAS_LINHAS diff=${DIFERENCA}%"

    if [ "$DIFERENCA" -gt "$LIMIAR" ]; then
        echo "  🚨 CANARY DISPARADO! Diferença de ${DIFERENCA}% > ${LIMIAR}%"
        echo "  🚨 Snapshot NÃO foi atualizado. Investigação necessária."
        return 1
    fi

    return 0
}
```

**Quando o canary dispara?**

- Uma tabela foi truncada acidentalmente (ex: 1000 linhas → 0 linhas)
- A query mudou sem querer e passou a retornar subconjunto
- O banco de origem sofreu uma regressão (rollback, perda de dados)
- Um filtro foi alterado sem documentação

O canary **não impede a execução**, apenas impede a **substituição do arquivo**.
O snapshot anterior continua disponível e íntegro, e o alerta permite investigar
antes de propagar dados errados.

---

## Seção 6: O Formato do Snapshot Markdown

Cada snapshot gerado segue um formato padronizado.

### Exemplo completo

```markdown
---
source: seed-counts
exported_at: 2026-06-06T16:26:23-04:00
rows: 42
query: |
  SELECT tenant, COUNT(*) as total
  FROM core_procedimento
  GROUP BY tenant
  ORDER BY tenant
schedule: 24h
sha256: a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2
---

# Seed Counts

Contagem de registros seed por tenant.

## Dados

| tenant   | total |
|----------|-------|
| Tenant A | 15    |
| Tenant B | 27    |

---

*Snapshot gerado em 2026-06-06T16:26:23-04:00 | Schedule: 24h | Fonte: seed-counts*
```

### O que cada campo do frontmatter significa

| Campo | O que é | Por que é importante |
|-------|---------|---------------------|
| `source` | Nome da fonte em `sources.yaml` | Permite rastrear de onde o dado veio |
| `exported_at` | Data/hora exata da extração | Linhagem do dado (data lineage) |
| `rows` | Quantas linhas foram retornadas | Permite canary e auditoria |
| `query` | SQL que gerou estes dados | Reproducibilidade — você pode executar de novo |
| `schedule` | Frequência de refresh | Informa ao agente/cron quando atualizar |
| `sha256` | Hash do conteúdo | Integridade — detecta alterações não autorizadas |

### Por que frontmatter?

Frontmatter YAML (delimitado por `---`) é um padrão amplamente usado em
ferramentas de documentação estática (Jekyll, Hugo, MkDocs). Ele permite que:

- **Humanos** leiam os metadados claramente no topo do arquivo
- **Agentes** façam parsing estruturado com bibliotecas YAML
- **Ferramentas** (como o script de validação) extraiam campos sem precisar
  interpretar o corpo do markdown

---

## Seção 7: O Cron Job

Para automatizar a atualização dos snapshots, usamos o **sistema de cron jobs**
do Hermes Agent ou um cron tradicional do Linux/macOS.

### 7.1 Usando o Hermes Agent Cron

O Hermes Agent possui um comando nativo para criar cron jobs:

```bash
hermes --profile orquestrador cronjob create \
  --name "snapshot-cache-refresh" \
  --schedule "0 */12 * * *" \
  --script scripts/export-cache.sh
```

**Explicando cada parâmetro:**

| Parâmetro | Valor | Significado |
|-----------|-------|-------------|
| `--profile` | `orquestrador` | Perfil do Hermes que tem permissão para executar o script |
| `--name` | `snapshot-cache-refresh` | Nome identificador do cron job |
| `--schedule` | `0 */12 * * *` | A cada 12 horas (minuto 0) — formato cron |
| `--script` | `scripts/export-cache.sh` | Script a ser executado |

### 7.2 Entendendo o formato cron

O schedule `0 */12 * * *` significa:

```
 ┌───────── minuto (0)
 │ ┌─────── hora (a cada 12 horas)
 │ │ ┌───── dia do mês (* = qualquer)
 │ │ │ ┌─── mês (* = qualquer)
 │ │ │ │ ┌─ dia da semana (* = qualquer)
 │ │ │ │ │
 0 */12 * * *
```

Outros exemplos:

| Schedule | Significado |
|----------|-------------|
| `0 */6 * * *` | A cada 6 horas |
| `0 6 * * *` | Todos os dias às 06:00 |
| `0 */1 * * *` | A cada 1 hora |
| `30 8 * * 1-5` | Dias úteis às 08:30 |

### 7.3 Usando cron do sistema (alternativa)

Se você não usa o Hermes Agent como cron manager, pode usar o cron tradicional:

```bash
# Editar crontab
crontab -e

# Adicionar linha (executa a cada 12 horas)
0 */12 * * * /caminho/do/projeto/scripts/export-cache.sh >> /caminho/do/projeto/logs/cache-refresh.log 2>&1
```

### 7.4 Execução manual

Você também pode executar manualmente para testar:

```bash
cd /caminho/do/projeto
bash scripts/export-cache.sh
```

---

## Seção 8: Como Reutilizar para Seus Projetos

Esta seção mostra como adaptar o Piloto DuckDB Cache para seu próprio projeto.

### 8.1 Passo a passo

**Passo 1: Instalar as dependências**

```bash
# DuckDB CLI (macOS, Linux, Windows)
# Baixe o binário em: https://duckdb.org/docs/installation/

# macOS (via Homebrew)
brew install duckdb

# Linux (via curl)
curl -fsSL https://install.duckdb.org | sh

# Python para validação
pip install pyyaml
```

**Passo 2: Criar a estrutura de diretórios**

```bash
mkdir -p seu-projeto/scripts
mkdir -p seu-projeto/docs/data/snapshots
```

**Passo 3: Criar o `sources.yaml`**

```yaml
# seu-projeto/sources.yaml
sources:
  - name: clientes-ativos
    description: "Clientes com atividade nos últimos 30 dias"
    query: |
      SELECT c.id, c.nome, c.email, MAX(p.data) as ultima_compra
      FROM clientes c
      LEFT JOIN pedidos p ON p.cliente_id = c.id
      GROUP BY c.id, c.nome, c.email
      HAVING MAX(p.data) >= CURRENT_DATE - INTERVAL '30 days'
      ORDER BY ultima_compra DESC
    schedule: 12h
    output: docs/data/snapshots/clientes-ativos.md
```

**Passo 4: Configurar variáveis de ambiente para conexão PostgreSQL**

```bash
# .env ou export direto
export PG_HOST="seu-servidor"
export PG_PORT="5432"
export PG_DB="seu_banco"
export PG_USER="seu_usuario"
export PG_PASSWORD="sua_senha"
```

**Passo 5: Executar o script manualmente**

```bash
cd seu-projeto
bash scripts/export-cache.sh
```

**Passo 6: Verificar o resultado**

```bash
cat docs/data/snapshots/clientes-ativos.md
```

**Passo 7: Automatizar com cron**

```bash
hermes --profile orquestrador cronjob create \
  --name "seu-cache-refresh" \
  --schedule "0 */12 * * *" \
  --script scripts/export-cache.sh
```

### 8.2 Template de projeto mínimo

```
seu-projeto/
├── sources.yaml              ← Configuração das fontes
├── scripts/
│   ├── export-cache.sh       ← Orquestrador principal
│   └── validar_frontmatter.py ← Validador Python
├── docs/
│   └── data/
│       └── snapshots/        ← Snapshots gerados
│           ├── clientes-ativos.md
│           └── metricas-diarias.md
└── .gitignore
    ├── *.new
    └── *.tmp
```

### 8.3 Como os agentes consomem os snapshots

Dentro de um skill ou prompt de agente, você pode referenciar os snapshots
diretamente:

```markdown
## Contexto disponível

Os seguintes arquivos de cache estão disponíveis no projeto:

- `docs/data/snapshots/clientes-ativos.md` — Clientes ativos nos últimos 30 dias
- `docs/data/snapshots/metricas-diarias.md` — Métricas agregadas do sistema

Se precisar de dados atualizados, leia o arquivo correspondente. 
Não execute SQL no banco de produção a menos que seja estritamente necessário.
```

O agente Hermes, ao ler essa instrução, saberá que pode abrir os arquivos `.md`
para obter contexto sem precisar consultar o banco.

### 8.4 Integração com Git

Os snapshots podem (e devem) ser versionados no Git. Isso traz benefícios:

- **Histórico:** Você pode ver como os dados evoluíram ao longo do tempo
- **Rastreabilidade:** Cada commit mostra o estado dos dados naquele momento
- **Rollback:** Se um dado errado for propagado, você volta ao commit anterior

```bash
# Adicione os snapshots ao repositório
git add docs/data/snapshots/
git commit -m "📸 snapshots: atualização automática $(date +%Y-%m-%d)"
```

---

## Seção 9: Benefícios

### Resumo dos benefícios

| Benefício | Detalhamento |
|-----------|--------------|
| **Cache local** | Dados disponíveis em milissegundos, sem consultar PostgreSQL |
| **Formato universal** | Markdown é legível por humanos E por agentes de IA |
| **Rastreável** | Frontmatter com `source`, `exported_at`, `query` — data lineage completa |
| **Seguro** | 3 camadas de validação (safe-write, frontmatter, canary) |
| **Automatizável** | Cron job (Hermes ou sistema) executa sem supervisão |
| **Leve** | DuckDB CLI é um binário único, sem servidor, sem dependências pesadas |
| **Reproduzível** | A query está no frontmatter — qualquer pessoa pode reexecutar |
| **Integridade** | Hash SHA-256 no frontmatter detecta alterações não autorizadas |
| **Econômico** | Reduz drasticamente a carga no banco de dados de produção |
| **Didático** | Dados em markdown são mais fáceis de entender que tabelas SQL brutas |

### Quando usar (e quando não usar)

**Use o DuckDB Cache quando:**

- Os dados mudam pouco mas são consultados com frequência (>10x/dia)
- Agentes de IA precisam de contexto rápido do banco de dados
- Você quer reduzir a carga no PostgreSQL de produção
- Precisa de um cache offline que funcione sem conexão de rede

**Não use quando:**

- Os dados mudam a cada segundo (transações em tempo real)
- A consulta precisa do resultado mais recente (consistência imediata)
- O volume de dados é muito grande para caber em um arquivo markdown (milhões de linhas)
- Você precisa escrever dados de volta no banco (cache é somente leitura)

---

## Glossário

| Termo | Definição |
|-------|-----------|
| **Cache** | Cópia local de dados caros de obter, armazenada para acesso rápido |
| **Snapshot** | "Fotografia" dos dados em um determinado momento |
| **Frontmatter** | Bloco YAML no início de um arquivo markdown, entre `---` |
| **Safe-write** | Técnica de escrever em arquivo temporário e depois mover (atômico) |
| **Canary** | Alerta precoce que detecta mudanças anormais antes que virem problema |
| **Data lineage** | Rastreabilidade da origem e transformação dos dados |
| **postgres_scanner** | Extensão do DuckDB que consulta PostgreSQL diretamente |
| **Cron** | Agendador de tarefas do Unix/Linux |
| **OLAP** | Online Analytical Processing — processamento analítico (agregações) |
| **OLTP** | Online Transaction Processing — processamento transacional (INSERT/UPDATE) |

---

> **Próximos passos:** Após implementar o cache DuckDB, considere expandir com
> um sistema de alertas (Slack/email quando o canary disparar), dashboards com
> os snapshots, ou até mesmo uma skill Hermes que automatize a criação de
> novas fontes no `sources.yaml`.
>
> Veja também:
> - [01-CONFIGURACAO-INICIAL.md](./01-CONFIGURACAO-INICIAL.md) — Configuração do Hermes Agent
> - [07-AUTOMACAO-DIARIA.md](./07-AUTOMACAO-DIARIA.md) — Automação com cron jobs
> - [10-MEMORIA-OPERACIONAL.md](./10-MEMORIA-OPERACIONAL.md) — Memória operacional do agente
