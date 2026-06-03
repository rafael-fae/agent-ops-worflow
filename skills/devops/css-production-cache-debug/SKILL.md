---
name: css-production-cache-debug
title: "Debugging CSS Breakage in Production (Express + Cloudflare)"
description: "Diagnóstico e correção de CSS quebrado em produção com Express, EJS, PM2 e Cloudflare. Cobre cache busting, restauração de classes perdidas, migração de syntax highlighting, e verificação de cache CDN."
category: devops
created: 2026-05-26
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Debugging CSS Breakage in Production (Express + Cloudflare)

## Trigger Conditions

- CSS foi modificado mas as mudanças não aparecem no browser
- Página inicial ou componentes perderam estilo após alteração no `main.css`
- Syntax highlighting ou classes de design system sumiram
- Cloudflare/NGINX cache servindo CSS antigo

## Step-by-Step Diagnosis

### 1. Verify Current CSS on Origin

```bash
# Check local server directly (bypasses CDN)
curl -s http://localhost:8080/css/main.css | head -20

# Check which cache bust version is being served
curl -s http://localhost:8080/ | grep -o 'v=[0-9]*'
```

### 2. Check Cloudflare Cache Status

```bash
# Check if CF has cached the CSS
curl -sI https://SEU_DOMINIO/css/main.css | grep -i "cf-cache-status\|age:"
# cf-cache-status: HIT → cached; MISS → will fetch fresh
# age: seconds since cached
```

### 3. Verify Template Cache Bust

```bash
# Confirm the template references the right version
grep 'v=' views/base.ejs
# Output: <link rel="stylesheet" href="/css/main.css?v=N">
```

### 4. Force CSS Refresh

```bash
# Edit views/base.ejs — bump v=N to next integer
# Then restart PM2:
pm2 restart pycode-blog

# Verify cache bust took effect:
curl -s http://localhost:8080/ | grep -o 'v=[0-9]*'
# Should show the new version number

# Verify CF cache miss:
curl -sI "https://SEU_DOMINIO/css/main.css?v=N" | grep "cf-cache-status"
# Should show MISS on first request
```

## Common Pitfalls & Fixes

### CSS Classes Missing After Edit

**Symptom:** Buttons, cards, stats, or sections unstyled.

**Cause:** A CSS edit (e.g., adding syntax highlighting) accidentally removed entire rule blocks.

**Fix:** Audit all classes used by templates vs. CSS:

```bash
# Extract all classes used in templates
grep -roP 'class="([^"]*)"' views/*.ejs | sort -u

# Check each class exists in CSS
for cls in btn-primary btn-outline stats-bar stat-value section-title; do
    grep -q "\.$cls" public/css/main.css && echo "✅ $cls" || echo "❌ $cls"
done
```

Restore missing classes from a known-good version. If no git history, reconstruct from:
- Previous session transcripts (via session_search)
- Known design token values
- MongoDB design system reference:
  - `--forest: #001e2b`, `--green: #00ed64`, `--dark-green: #00684a`
  - `--blue: #006cfa`, `--teal: #1c2d38`, `--teal-gray: #3d4f58`
  - `--cool-gray: #5c6c75`, `--silver: #b8c4c2`

### Syntax Highlighting Migration (hljs → Prism)

- Highlight.js uses `.hljs-*` classes
- Prism.js uses `.token.*` classes
- **Do NOT remove existing `.hljs-*` rules** when adding Prism — keep both as fallback
- Test both light and dark mode after migration

### PM2 Watch Not Detecting Changes

**Symptom:** File changed on disk but server still serves old version.

**Fix:**
```bash
pm2 restart pycode-blog
```

**Prevention** — use `ecosystem.config.cjs` with explicit watch paths.

### Grid Layout: auto-fill vs Fixed Columns

- `repeat(auto-fill, minmax(340px, 1fr))` — responsive but may show 2 columns
- `repeat(3, 1fr)` — exactly 3 columns guaranteed on desktop
- Use `@media (max-width: 768px)` to collapse to 1 column

## Verification Checklist

- [ ] `cf-cache-status: MISS` for new CSS URL
- [ ] Template references new cache bust version
- [ ] All template classes exist in CSS
- [ ] Homepage renders: grid, buttons, stats, cards, topics
- [ ] Tutorial renders: headings, code blocks, index
- [ ] Light mode and dark mode both functional
- [ ] `pm2 status` — server online

## Team Protocol: CSS Change Management

**CRITICAL: Never modify CSS unilaterally on a multi-page production site.**

### The 3-Role Workflow

1. **Designer ({{FRONTEND_ENGINEER}})** — defines the visual spec: exact values for font-size, spacing, colors, layout. Audits all pages first.
2. **Engineer ({{AUDITOR}}/{{BACKEND_ENGINEER}})** — implements EXACTLY what the designer specified in CSS. No creative interpretation.
3. **Orchestrator ({{ORCHESTRATOR}})** — validates across ALL pages before closing.

### The "Test Every Page" Rule

After ANY CSS change, test ALL of these before reporting done:
```
curl -s http://localhost:PORT/        # Landing page
curl -s http://localhost:PORT/tutorial  # Tutorial page
curl -s http://localhost:PORT/blog/xyz  # A blog post
curl -s http://localhost:PORT/nonexist  # 404 page
```

A change that only fixes the tutorial can break the landing page. Visual regression testing of ALL templates is mandatory.

### The "Don't Remove, Append" Principle

When adding new CSS features (e.g., Prism syntax highlighting):
- **NEVER remove existing CSS rule blocks** — append new rules at the end of the file
- Keep old selectors as fallback (e.g., `.hljs-*` + `.token-*`)
- If a class is truly obsolete, deprecate in a separate PR/change, not in the feature addition

### Landing Page Component Values (PyCode Blog Reference)

After restoring missing classes, iterate with user feedback on specific values:

```
Hero h1:         font-size: 1.75rem (fits 1 line)
Hero padding:    32px 16px 24px (compact)
Hero margin-bottom: 16px (tight spacing to stats)
Stats bar pad:   32px 32px (top/bottom reduced by half from 64px)
Stat value:      3rem, serif, dark-green
Stat label:      uppercase, letter-spacing 1.5px, mono, medium weight
Section pad:     var(--space-64) var(--space-32)
Card grid:       repeat(3, 1fr) fixed columns
Nav padding:     8px 16px (compact)
Nav brand:       REMOVED on user request
Code bg:         #0d1c24 (darker for contrast)
```

### Prism.js Dual-Mode Syntax Highlighting

Light mode = MongoDB brand colors (blue keywords, green strings).
Dark mode = VS Code Dark colors (blue #569cd6 keywords, orange #ce9178 strings).
Keep `.hljs-*` as fallback alongside `.token-*`.

### Restoring CSS Without Git

When CSS is lost because there's no version control:

1. Use `session_search` to find previous reads of the CSS file in conversation history
2. Reconstruct from known design token values (the MongoDB design system is the source of truth)
3. Extract ALL classes used by templates:
   ```bash
   grep -roP 'class="([^"]*)"' views/*.ejs | sort -u
   ```
4. Check each against CSS; reconstruct any that are missing
5. Cross-reference with the original MongoDB design system colors:
   - Forest: `#001e2b`, Green: `#00ed64`, Dark-green: `#00684a`
   - Blue: `#006cfa`, Teal: `#1c2d38`, Teal-gray: `#3d4f58`
   - Cool-gray: `#5c6c75`, Silver: `#b8c4c2`

### Server Port Discovery

When PM2 server isn't responding on expected port:
```bash
# Check logs for actual port
tail -20 {{COMMANDER_HOME}}/.pm2/logs/pycode-blog-out.log
# Look for: "Server running on http://localhost:XXXXX"

# Test discovered port
curl -s http://localhost:XXXXX/
```

## Common Pitfalls: Lessons from Production Incidents

### The Cascade Break

**Scenario:** Engineer adds Prism.js syntax highlighting to `main.css`. In the process, deletes `.btn`, `.stats-bar`, `.card-accent`, `.topics-cloud`, `.filter-banner`, `.empty-state`, `.error-page`, `.section-dark` — all landing page classes.

**Root Cause:** Copy-pasting a new CSS block into the file without checking if surrounding blocks remain intact. The delete key was used to make room, and critical sections adjacent to the edit point were lost.

**Prevention:** When inserting a large block of new CSS, ALWAYS:
1. Append at the END of the file, not in the middle
2. Run the class audit script before and after
3. Test every page template

### The Cache Bust Chain

Each CSS change requires:
1. Bump `v=N` in `base.ejs`
2. `pm2 restart pycode-blog`
3. Wait for Cloudflare to cache new version
4. Verify with hard refresh (Ctrl+F5)

Do NOT skip steps. A missing cache bust = user sees broken site for up to 24h.

### The Wrong-Port Trap

If `curl localhost:3100` returns nothing, check:
```bash
pm2 show pycode-blog | grep "PORT"
```
The server might be running on 8080, not 3100. The `server.js` uses `process.env.PORT` first, falls back to 3100.
