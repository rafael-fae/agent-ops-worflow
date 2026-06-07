# 10 — DuckDB Cache Pilot: Local Cache with DuckDB + Markdown Snapshots

> **Purpose of this document:** Present the DuckDB Cache Pilot — a local cache
> solution for database queries that transforms SQL results into
> markdown files readable by humans and AI agents. Includes the problem,
> architecture, 3 security layers, cron job automation, and how to
> reuse it in your projects.
>
> **Target audience:** Developers, data analysts, and automation enthusiasts
> who want to speed up repetitive queries and provide quick context to AI agents.

---

## Table of Contents

1. [The Problem — Why Do We Need Cache?](#section-1-the-problem-why-do-we-need-cache)
2. [The Solution — DuckDB + Markdown Snapshots](#section-2-the-solution-duckdb--markdown-snapshots)
3. [Pipeline Architecture](#section-3-pipeline-architecture)
4. [The `sources.yaml` File](#section-4-the-sourcesyaml-file)
5. [The `export-cache.sh` Script](#section-5-the-export-cachesh-script)
6. [The Markdown Snapshot Format](#section-6-the-markdown-snapshot-format)
7. [The Cron Job](#section-7-the-cron-job)
8. [How to Reuse for Your Projects](#section-8-how-to-reuse-for-your-projects)
9. [Benefits](#section-9-benefits)

---

## Section 1: The Problem — Why Do We Need Cache?

Imagine you have a PostgreSQL database with thousands of records. Every day,
your AI agents or analysis tools need to ask the **same questions**:

- "How many active users do we have today?"
- "What's the record count per category?"
- "List the top 10 customers by revenue."

Every time one of these questions is asked, the database needs to:

1.  Accept the connection
2.  Authenticate
3.  Plan the query (query planner)
4.  Scan the tables (disk I/O)
5.  Calculate aggregations (CPU)
6.  Return serialized data over the network

This is **expensive** — especially if the data changes little and the query is always the same.

### The Resource Waste

| Situation | Without Cache | With Cache |
|-----------|--------------|------------|
| Query executed | 100 times/day | 1 time (the first) |
| Average response time | 2-5 seconds | < 50ms (local file) |
| PostgreSQL load | High (connections + queries) | Minimal (only refresh) |
| Availability for agents | Depends on network/PG | Immediate (local file) |

### The Bottleneck with AI Agents

Hermes agents (and other AI agents) **read markdown files** much more
efficiently than they execute SQL. Each SQL query requires:

- A `think` step to build the query
- A tool call
- Waiting for the database to respond
- Interpreting the tabular result

If the data is already in a `.md` file in the project, the agent **reads and understands it**
in milliseconds, without needing to touch the database.

### The Concept of Cache

Cache is a **local, fast copy** of data that is expensive to obtain from the original source.
It's like your refrigerator: instead of going to the supermarket (database) every time you want
to eat something (query), you keep a small portion at home (cache). Every now and
then, you restock (refresh).

---

## Section 2: The Solution — DuckDB + Markdown Snapshots

The solution combines three simple and powerful technologies:

### 2.1 DuckDB — The Embedded SQL Database for Analytics

**DuckDB** is an embedded SQL database, like SQLite, but **optimized
for analytical workloads** (OLAP). While SQLite is excellent for transactions
(insert, update, delete), DuckDB shines in queries that aggregate lots of data
— exactly what we need for extracting snapshots.

Key characteristics:

| Feature | DuckDB | PostgreSQL | SQLite |
|---------|--------|------------|--------|
| Operation mode | Embedded (library) | Separate server | Embedded |
| Optimized for | Analytics (OLAP) | General (OLTP) | Transactions (OLTP) |
| Aggregate queries | Very fast | Good | Slow |
| External dependency | None (standalone) | Server running | None |

### 2.2 DuckDB CLI — Command Line Tool

The DuckDB CLI is a single executable (`duckdb`) that opens an interactive SQL shell or
executes SQL commands directly via argument:

```bash
duckdb -c "SELECT 1 + 1 AS result;"
```

This means we can call DuckDB from **any shell script** without needing
a running server. Perfect for automation.

### 2.3 postgres_scanner — Bridge to PostgreSQL

DuckDB has an ecosystem of extensions. One of the most useful is the
**postgres_scanner**, which allows connecting directly to a PostgreSQL database and
querying its tables as if they were local:

```sql
ATTACH 'host=localhost port=5432 dbname=your_db' AS pg_db (TYPE postgres);
SELECT * FROM pg_db.example_table;
```

This means DuckDB becomes a **lightweight ETL** tool: it fetches data from PostgreSQL,
processes it locally, and returns the result immediately.

### 2.4 Markdown Snapshots — The Universal Format for Humans and Agents

After DuckDB executes the query, the result is converted to a **Markdown** file
with metadata in **frontmatter** (YAML between `---`).

**Why Markdown?**

> Hermes agents READ markdown. They don't execute SQL. If the data is in markdown,
> the agent simply opens the file and already understands the context — no tool calls,
> no network connection, no delay.

The chosen format:

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

Humans read the title and table. Agents read the frontmatter and body. Everyone is happy.

---

## Section 3: Pipeline Architecture

The complete pipeline follows this flow:

```
┌────────────────────────────────────────────────────────────┐
│                    sources.yaml                             │
│  (declarative configuration of data sources)               │
└────────────────────┬───────────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────────────┐
│                  export-cache.sh                            │
│         (main orchestrator in bash)                        │
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
│ Query    │  │ Query    │  │ Query            │
│ Source A │  │ Source B │  │ Source C         │
└────┬─────┘  └────┬─────┘  └────────┬─────────┘
     │             │                 │
     └──────┬──────┴────────┬────────┘
            │               │
            ▼               ▼
┌────────────────────────────────────────────────────────────┐
│              3 Security Layers                             │
│                                                           │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ 1. Safe-write: .new → validate → mv                │  │
│  │    (writes to temporary file)                      │  │
│  └─────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ 2. Python Validation: 6 frontmatter fields          │  │
│  │    (checks metadata integrity)                      │  │
│  └─────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ 3. Count Canary: >50% different? STOPS             │  │
│  │    (silent regression alert)                       │  │
│  └─────────────────────────────────────────────────────┘  │
└────────────────────────┬──────────────────────────────────┘
                         │
                         ▼
┌────────────────────────────────────────────────────────────┐
│              snapshots/*.md                                │
│  (markdown files with frontmatter data lineage)            │
│                                                           │
│  ├── docs/data/snapshots/seed-counts.md                   │
│  ├── docs/data/snapshots/active-users.md                  │
│  └── docs/data/snapshots/top-customers.md                 │
└────────────────────────────────────────────────────────────┘
```

### Flow Details

1. **Input:** The script reads the `sources.yaml` file that lists all data
   sources to be queried.
2. **Parallel processing:** For each source, the script fires a query
   via DuckDB CLI with the postgres_scanner extension.
3. **Raw result:** DuckDB returns the result as CSV/JSON.
4. **Conversion:** The result is converted to markdown with frontmatter.
5. **3 security layers:** The file goes through validation before replacing
   the previous snapshot (detailed in Section 5).
6. **Final snapshot:** The validated `.md` file is saved to the snapshots directory.

---

## Section 4: The `sources.yaml` File

The `sources.yaml` is the **heart of the configuration**. It declares which queries
to execute, how often, and where to save the result.

### Declarative YAML Format

YAML is a human-readable serialization format, widely used
in DevOps tools (Docker Compose, Kubernetes, GitHub Actions). Each data
source is a block in the `sources` list.

### Complete Structure

```yaml
# sources.yaml — Data source declaration for cache
# Each source generates a markdown snapshot.

sources:
  - name: seed-counts
    description: "Seed record count by tenant"
    query: |
      SELECT tenant, COUNT(*) as total
      FROM core_procedimento
      GROUP BY tenant
      ORDER BY tenant
    schedule: 24h
    output: docs/data/snapshots/seed-counts.md

  - name: active-users
    description: "Users who logged in the last 7 days"
    query: |
      SELECT u.name, u.email, u.last_login
      FROM auth_user u
      WHERE u.last_login >= CURRENT_DATE - INTERVAL '7 days'
      ORDER BY u.last_login DESC
    schedule: 6h
    output: docs/data/snapshots/active-users.md

  - name: general-metrics
    description: "Aggregated system metrics"
    query: |
      SELECT
        COUNT(DISTINCT tenant) as total_tenants,
        COUNT(*) as total_records,
        AVG(avg_time) as overall_avg_time
      FROM vw_system_metrics
    schedule: 12h
    output: docs/data/snapshots/general-metrics.md
```

### Fields for Each Source

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique source identifier (no spaces) |
| `description` | No | Human-readable description of what the query returns |
| `query` | Yes | SQL query to execute on PostgreSQL |
| `schedule` | Yes | Interval between refreshes (e.g., `24h`, `6h`, `12h`, `1h`) |
| `output` | Yes | Path to the output `.md` file |

### Important Query Tips

Write queries that return **stable, summarized data**. The goal is not to
replace PostgreSQL for transactional queries, but to create **consolidated
views** that change little. Avoid:

- `SELECT *` from large tables
- Complex joins across many tables
- Binary data or blobs

Prefer:

- Aggregations (`COUNT`, `SUM`, `AVG`, `GROUP BY`)
- Ordered samples (`LIMIT 100`)
- Consolidated lists with well-defined joins

---

## Section 5: The `export-cache.sh` Script

The `export-cache.sh` is the orchestrator that brings the pipeline to life. It reads the
`sources.yaml`, iterates over each source, executes the query via DuckDB,
validates the result, and saves the snapshot.

### Complete Script Flow

```
1.  Check dependencies (duckdb, python3, yq/jq)
2.  Load sources.yaml
3.  For each source in sources:
    │
    ├─ 3.1. Execute query via DuckDB CLI + postgres_scanner
    │      └─ Generates .tmp file (raw CSV result)
    │
    ├─ 3.2. Convert CSV → Markdown with frontmatter
    │      └─ Generates .new file (temporary markdown)
    │
    ├─ ─ ─ ─ 3 Security Layers ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
    │
    ├─ 3.3. Safe-write: .new file hasn't replaced .md yet
    │
    ├─ 3.4. Validate frontmatter (Python):
    │      ├─ source (string, not empty)
    │      ├─ exported_at (valid ISO datetime)
    │      ├─ rows (integer >= 0)
    │      ├─ query (string, not empty)
    │      ├─ schedule (Xh, Xd, etc. format)
    │      └─ sha256 (content hash, integrity)
    │
    ├─ 3.5. Count canary:
    │      ├─ Reads rows from previous snapshot (if it exists)
    │      ├─ Compares with new snapshot rows
    │      └─ If difference > 50% → STOPS (alert)
    │
    ├─ 3.6. If all validations pass:
    │      └─ mv .new → .md (atomic replacement)
    │
    └─ 3.7. Log: success/error with timestamp
```

### 5.1 Safe-write (Layer 1)

The first security layer prevents a corrupted or incomplete file from
replacing a valid snapshot.

```bash
#!/usr/bin/env bash
# Safe-write strategy: writes to .new, then moves

OUTPUT_FILE="docs/data/snapshots/seed-counts.md"
TEMP_FILE="${OUTPUT_FILE}.new"

# Write markdown to temporary file
cat > "$TEMP_FILE" << 'MARKDOWN'
---
source: seed-counts
exported_at: 2026-06-06T16:26:23-04:00
rows: 42
query: SELECT tenant, COUNT(*)...
schedule: 24h
---
... content ...
MARKDOWN

# Only after validation, move .new to .md (atomic replacement)
if python3 validate_frontmatter.py "$TEMP_FILE"; then
    mv "$TEMP_FILE" "$OUTPUT_FILE"
    echo "✅ Snapshot updated: $OUTPUT_FILE"
else
    rm -f "$TEMP_FILE"
    echo "❌ Validation failed. Previous snapshot preserved."
    exit 1
fi
```

Why `.new` → `mv`?

- If the script dies mid-write, `.new` is left incomplete, but the original `.md`
  remains intact
- `mv` is an **atomic** operation on the same filesystem: the destination file
  is replaced instantly
- No reader (human or agent) will read a partially written file

### 5.2 Python Frontmatter Validation (Layer 2)

The second layer checks if the YAML frontmatter contains all required
fields with correct types.

```python
#!/usr/bin/env python3
"""validate_frontmatter.py — Validates the 6 frontmatter fields of the snapshot."""

import sys
import yaml
import re
from datetime import datetime

REQUIRED_FIELDS = ["source", "exported_at", "rows", "query", "schedule"]


def validate_iso_datetime(value):
    """Checks if the value is a valid ISO 8601 datetime."""
    try:
        datetime.fromisoformat(value)
        return True
    except (ValueError, TypeError):
        return False


def validate_schedule(value):
    """Validates schedule format: number followed by h, d, m (e.g., 24h, 7d)."""
    return bool(re.match(r'^\d+[hdm]$', str(value)))


def validate_frontmatter(filepath):
    """Validates the 6 frontmatter fields."""
    with open(filepath, 'r') as f:
        content = f.read()

    # Extract frontmatter between ---
    parts = content.split('---')
    if len(parts) < 3:
        print("❌ Frontmatter not found (--- delimiters missing)")
        return False

    try:
        metadata = yaml.safe_load(parts[1])
    except yaml.YAMLError as e:
        print(f"❌ Error parsing YAML: {e}")
        return False

    if not isinstance(metadata, dict):
        print("❌ Frontmatter is not a valid dictionary")
        return False

    # Validate field by field
    errors = []

    # 1. source: non-empty string
    source = metadata.get('source')
    if not source or not isinstance(source, str):
        errors.append("❌ Field 'source' missing or invalid (must be string)")

    # 2. exported_at: ISO datetime
    exported_at = metadata.get('exported_at')
    if not exported_at or not validate_iso_datetime(exported_at):
        errors.append(f"❌ Field 'exported_at' missing or invalid: {exported_at}")

    # 3. rows: integer >= 0
    rows = metadata.get('rows')
    if rows is None or not isinstance(rows, int) or rows < 0:
        errors.append(f"❌ Field 'rows' missing or invalid (must be int >= 0): {rows}")

    # 4. query: non-empty string
    query = metadata.get('query')
    if not query or not isinstance(query, str):
        errors.append("❌ Field 'query' missing or invalid (must be string)")

    # 5. schedule: Xh, Xd, Xm format
    schedule = metadata.get('schedule')
    if not schedule or not validate_schedule(schedule):
        errors.append(f"❌ Field 'schedule' missing or invalid: {schedule}")

    # 6. sha256: SHA-256 hash (optional but recommended)
    sha256 = metadata.get('sha256')
    if sha256 and not re.match(r'^[a-f0-9]{64}$', str(sha256)):
        errors.append(f"❌ Field 'sha256' invalid (must be 64-char hex): {sha256}")

    if errors:
        for error in errors:
            print(error)
        return False

    print(f"✅ Valid frontmatter: {rows} rows, source '{source}'")
    return True


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: validate_frontmatter.py <file.md>")
        sys.exit(1)

    filepath = sys.argv[1]
    if not validate_frontmatter(filepath):
        sys.exit(1)
```

**The 6 validated fields:**

| # | Field | Type | What it checks |
|---|-------|------|----------------|
| 1 | `source` | string | Not empty, matches source name |
| 2 | `exported_at` | datetime | Valid ISO 8601 format |
| 3 | `rows` | int | >= 0 (number of rows returned) |
| 4 | `query` | string | Not empty (the SQL that generated the data) |
| 5 | `schedule` | string | `Xd`, `Xh` or `Xm` format |
| 6 | `sha256` | string (opt.) | 64-character hex hash |

### 5.3 Count Canary (Layer 3)

The third layer is a **canary** — an early warning that something changed
drastically. If the new snapshot's row count is more than 50%
different from the previous one, the script stops.

```bash
#!/usr/bin/env bash
# Count canary — detects silent regressions

canary_check() {
    local FILE="$1"       # Path to previous snapshot (e.g., .md)
    local NEW_ROWS="$2"  # New snapshot row count
    local THRESHOLD=50          # Maximum percentage difference

    # If no previous snapshot exists, it's the first run — ok
    if [ ! -f "$FILE" ]; then
        echo "  ℹ️  First run — canary ignored"
        return 0
    fi

    # Extract previous count from frontmatter
    local PREVIOUS_ROWS
    PREVIOUS_ROWS=$(grep '^rows:' "$FILE" | head -1 | cut -d' ' -f2)

    # If can't extract, ignore (might be old format)
    if [ -z "$PREVIOUS_ROWS" ] || [ "$PREVIOUS_ROWS" -eq 0 ] 2>/dev/null; then
        echo "  ⚠️  Could not read previous count — canary ignored"
        return 0
    fi

    # Calculate percentage difference
    local DIFFERENCE
    local LARGER=$PREVIOUS_ROWS
    local SMALLER=$NEW_ROWS

    if [ "$NEW_ROWS" -gt "$PREVIOUS_ROWS" ]; then
        LARGER=$NEW_ROWS
        SMALLER=$PREVIOUS_ROWS
    fi

    DIFFERENCE=$(( (LARGER - SMALLER) * 100 / LARGER ))

    echo "  📊 Canary: previous=$PREVIOUS_ROWS new=$NEW_ROWS diff=${DIFFERENCE}%"

    if [ "$DIFFERENCE" -gt "$THRESHOLD" ]; then
        echo "  🚨 CANARY TRIPPED! Difference of ${DIFFERENCE}% > ${THRESHOLD}%"
        echo "  🚨 Snapshot NOT updated. Investigation required."
        return 1
    fi

    return 0
}
```

**When does the canary trip?**

- A table was accidentally truncated (e.g., 1000 rows → 0 rows)
- The query changed unintentionally and now returns a subset
- The source database suffered a regression (rollback, data loss)
- A filter was altered without documentation

The canary **doesn't prevent execution**, only prevents **file replacement**.
The previous snapshot remains available and intact, and the alert allows investigating
before propagating wrong data.

---

## Section 6: The Markdown Snapshot Format

Each generated snapshot follows a standardized format.

### Complete Example

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

Count of seed records by tenant.

## Data

| tenant   | total |
|----------|-------|
| Tenant A | 15    |
| Tenant B | 27    |

---

*Snapshot generated at 2026-06-06T16:26:23-04:00 | Schedule: 24h | Source: seed-counts*
```

### What Each Frontmatter Field Means

| Field | What it is | Why it's important |
|-------|-----------|---------------------|
| `source` | Source name in `sources.yaml` | Allows tracing where the data came from |
| `exported_at` | Exact extraction date/time | Data lineage |
| `rows` | How many rows were returned | Enables canary and auditing |
| `query` | SQL that generated this data | Reproducibility — you can execute it again |
| `schedule` | Refresh frequency | Informs the agent/cron when to update |
| `sha256` | Content hash | Integrity — detects unauthorized changes |

### Why Frontmatter?

YAML frontmatter (delimited by `---`) is a widely used standard in
static documentation tools (Jekyll, Hugo, MkDocs). It allows:

- **Humans** to read metadata clearly at the top of the file
- **Agents** to do structured parsing with YAML libraries
- **Tools** (like the validation script) to extract fields without needing
  to interpret the markdown body

---

## Section 7: The Cron Job

To automate snapshot updates, we use the **Hermes Agent cron job system**
or a traditional Linux/macOS cron.

### 7.1 Using Hermes Agent Cron

Hermes Agent has a native command for creating cron jobs:

```bash
hermes --profile orchestrator cronjob create \
  --name "snapshot-cache-refresh" \
  --schedule "0 */12 * * *" \
  --script scripts/export-cache.sh
```

**Explaining each parameter:**

| Parameter | Value | Meaning |
|-----------|-------|---------|
| `--profile` | `orchestrator` | Hermes profile with permission to execute the script |
| `--name` | `snapshot-cache-refresh` | Cron job identifier name |
| `--schedule` | `0 */12 * * *` | Every 12 hours (minute 0) — cron format |
| `--script` | `scripts/export-cache.sh` | Script to execute |

### 7.2 Understanding Cron Format

The schedule `0 */12 * * *` means:

```
 ┌───────── minute (0)
 │ ┌─────── hour (every 12 hours)
 │ │ ┌───── day of month (* = any)
 │ │ │ ┌─── month (* = any)
 │ │ │ │ ┌─ day of week (* = any)
 │ │ │ │ │
 0 */12 * * *
```

Other examples:

| Schedule | Meaning |
|----------|---------|
| `0 */6 * * *` | Every 6 hours |
| `0 6 * * *` | Every day at 06:00 |
| `0 */1 * * *` | Every 1 hour |
| `30 8 * * 1-5` | Weekdays at 08:30 |

### 7.3 Using System Cron (Alternative)

If you don't use Hermes Agent as a cron manager, you can use traditional cron:

```bash
# Edit crontab
crontab -e

# Add line (executes every 12 hours)
0 */12 * * * /path/to/project/scripts/export-cache.sh >> /path/to/project/logs/cache-refresh.log 2>&1
```

### 7.4 Manual Execution

You can also execute manually for testing:

```bash
cd /path/to/project
bash scripts/export-cache.sh
```

---

## Section 8: How to Reuse for Your Projects

This section shows how to adapt the DuckDB Cache Pilot for your own project.

### 8.1 Step by Step

**Step 1: Install dependencies**

```bash
# DuckDB CLI (macOS, Linux, Windows)
# Download the binary at: https://duckdb.org/docs/installation/

# macOS (via Homebrew)
brew install duckdb

# Linux (via curl)
curl -fsSL https://install.duckdb.org | sh

# Python for validation
pip install pyyaml
```

**Step 2: Create the directory structure**

```bash
mkdir -p your-project/scripts
mkdir -p your-project/docs/data/snapshots
```

**Step 3: Create `sources.yaml`**

```yaml
# your-project/sources.yaml
sources:
  - name: active-customers
    description: "Customers with activity in the last 30 days"
    query: |
      SELECT c.id, c.name, c.email, MAX(o.date) as last_purchase
      FROM customers c
      LEFT JOIN orders o ON o.customer_id = c.id
      GROUP BY c.id, c.name, c.email
      HAVING MAX(o.date) >= CURRENT_DATE - INTERVAL '30 days'
      ORDER BY last_purchase DESC
    schedule: 12h
    output: docs/data/snapshots/active-customers.md
```

**Step 4: Configure environment variables for PostgreSQL connection**

```bash
# .env or direct export
export PG_HOST="your-server"
export PG_PORT="5432"
export PG_DB="your_database"
export PG_USER="your_user"
export PG_PASSWORD="your_password"
```

**Step 5: Run the script manually**

```bash
cd your-project
bash scripts/export-cache.sh
```

**Step 6: Check the result**

```bash
cat docs/data/snapshots/active-customers.md
```

**Step 7: Automate with cron**

```bash
hermes --profile orchestrator cronjob create \
  --name "your-cache-refresh" \
  --schedule "0 */12 * * *" \
  --script scripts/export-cache.sh
```

### 8.2 Minimal Project Template

```
your-project/
├── sources.yaml              ← Source configuration
├── scripts/
│   ├── export-cache.sh       ← Main orchestrator
│   └── validate_frontmatter.py ← Python validator
├── docs/
│   └── data/
│       └── snapshots/        ← Generated snapshots
│           ├── active-customers.md
│           └── daily-metrics.md
└── .gitignore
    ├── *.new
    └── *.tmp
```

### 8.3 How Agents Consume Snapshots

Inside a skill or agent prompt, you can reference the snapshots
directly:

```markdown
## Available Context

The following cache files are available in the project:

- `docs/data/snapshots/active-customers.md` — Active customers in the last 30 days
- `docs/data/snapshots/daily-metrics.md` — Aggregated system metrics

If you need updated data, read the corresponding file.
Do not execute SQL on the production database unless strictly necessary.
```

The Hermes agent, upon reading this instruction, will know it can open the `.md` files
to obtain context without needing to query the database.

### 8.4 Git Integration

Snapshots can (and should) be versioned in Git. This brings benefits:

- **History:** You can see how data evolved over time
- **Traceability:** Each commit shows the data state at that moment
- **Rollback:** If wrong data is propagated, you go back to the previous commit

```bash
# Add snapshots to the repository
git add docs/data/snapshots/
git commit -m "📸 snapshots: automatic update $(date +%Y-%m-%d)"
```

---

## Section 9: Benefits

### Benefits Summary

| Benefit | Details |
|---------|---------|
| **Local cache** | Data available in milliseconds, no PostgreSQL query needed |
| **Universal format** | Markdown is readable by humans AND AI agents |
| **Traceable** | Frontmatter with `source`, `exported_at`, `query` — complete data lineage |
| **Safe** | 3 validation layers (safe-write, frontmatter, canary) |
| **Automatable** | Cron job (Hermes or system) runs unsupervised |
| **Lightweight** | DuckDB CLI is a single binary, no server, no heavy dependencies |
| **Reproducible** | The query is in the frontmatter — anyone can re-execute |
| **Integrity** | SHA-256 hash in frontmatter detects unauthorized changes |
| **Economical** | Drastically reduces load on production database |
| **Didactic** | Data in markdown is easier to understand than raw SQL tables |

### When to Use (and When Not to)

**Use DuckDB Cache when:**

- The data changes little but is queried frequently (>10x/day)
- AI agents need quick context from the database
- You want to reduce load on production PostgreSQL
- You need an offline cache that works without network connection

**Do NOT use when:**

- The data changes every second (real-time transactions)
- The query needs the most recent result (immediate consistency)
- The data volume is too large to fit in a markdown file (millions of rows)
- You need to write data back to the database (cache is read-only)

---

## Glossary

| Term | Definition |
|------|-----------|
| **Cache** | Local copy of expensive-to-obtain data, stored for quick access |
| **Snapshot** | "Photograph" of data at a given point in time |
| **Frontmatter** | YAML block at the start of a markdown file, between `---` |
| **Safe-write** | Technique of writing to a temporary file and then moving (atomic) |
| **Canary** | Early warning that detects abnormal changes before they become problems |
| **Data lineage** | Traceability of data origin and transformation |
| **postgres_scanner** | DuckDB extension that queries PostgreSQL directly |
| **Cron** | Unix/Linux task scheduler |
| **OLAP** | Online Analytical Processing — analytical processing (aggregations) |
| **OLTP** | Online Transaction Processing — transactional processing (INSERT/UPDATE) |

---

> **Next steps:** After implementing DuckDB cache, consider expanding with
> an alert system (Slack/email when the canary trips), dashboards using
> the snapshots, or even a Hermes skill that automates the creation of
> new sources in `sources.yaml`.
>
> See also:
> - [01-SETUP-WORKFLOW.md](./01-SETUP-WORKFLOW.md) — Hermes Agent Setup
> - [08-DAILY-AUTOMATION.md](./08-DAILY-AUTOMATION.md) — Cron job automation
> - [09-MEMORIA-OPERACIONAL.md](./09-MEMORIA-OPERACIONAL.md) — Agent operational memory
