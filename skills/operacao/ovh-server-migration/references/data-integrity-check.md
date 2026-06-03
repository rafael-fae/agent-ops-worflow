# Data Integrity Verification Checklist (Server Migration)

## When to run
After completing all data transfers (Fase 1) and before the Cloudflare Tunnel switch (Fase 4).

## Critical data to verify

### 1. SIA data files
```bash
# Compare checksums of all JSON mapping files
ssh ovh-old "sudo find {{COMMANDER_HOME}}/sia_projeto/data -name '*.json' -exec md5sum {} \;" | sort > /tmp/old_sia.md5
{{OVH_SSH_COMMAND}} "sudo find {{COMMANDER_HOME}}fae/sia_projeto/data -name '*.json' -exec md5sum {} \;" | sort > /tmp/new_sia.md5
diff /tmp/old_sia.md5 /tmp/new_sia.md5
# Empty diff = all files match
```

### 2. sistema-orto-sia mapping files
```bash
ssh ovh-old "sudo find {{COMMANDER_HOME}}/sistema-orto-sia/data -type f -exec md5sum {} \;" | sort > /tmp/old_orto.md5
{{OVH_SSH_COMMAND}} "sudo find {{COMMANDER_HOME}}fae/sistema-orto-sia/data -type f -exec md5sum {} \;" | sort > /tmp/new_orto.md5
diff /tmp/old_orto.md5 /tmp/new_orto.md5
```

### 3. Database integrity
```bash
# PostgreSQL (Evolution)
{{OVH_SSH_COMMAND}} "sudo docker exec evolution-postgres pg_dump -U evolution_user evolution --schema-only | wc -c"
# Should be non-zero

# MySQL (Oeste)
{{OVH_SSH_COMMAND}} "sudo docker exec oeste-odontologia-db mysql -u root -p\$MYSQL_ROOT_PASSWORD oeste_odontologia -e 'SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=\"oeste_odontologia\"'"
```

### 4. Directory comparison
```bash
# Compare file counts for key directories
for dir in "projects/pycode-blog" "projects/pycode-cerebro" "sia_projeto" "hermes-roshar" "Dev/hermes-profiles" "sistema-orto-sia"; do
    old_count=$(ssh ovh-old "sudo find {{COMMANDER_HOME}}/$dir -type f 2>/dev/null | wc -l")
    new_count=$({{OVH_SSH_COMMAND}} "sudo find {{COMMANDER_HOME}}fae/$dir -type f 2>/dev/null | wc -l")
    diff=$((old_count - new_count))
    if [ $diff -ne 0 ]; then echo "❌ $dir: $diff files missing"; else echo "✅ $dir: $new_count files OK"; fi
done
```

### 5. Expected differences (not errors)
- `.venv/` directories: excluded from rsync, recreated with `uv sync`
- `__pycache__/`: regenerated on first run
- `node_modules/`: excluded, reinstalled with `npm install`
- Docker volumes: may differ if old server continued running after copy
- `.git/` objects: may differ due to gc operations
