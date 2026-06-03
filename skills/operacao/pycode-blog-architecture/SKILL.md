---
name: pycode-blog-architecture
description: Arquitetura de deploy do PyCode Blog (Express + EJS + markdown-it) sob Cloudflare Tunnel — estrutura, cache-busting, wikilinks, e decisões de arquitetura.
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# PyCode Blog — Arquitetura e Deploy

## Visão Geral

Blog dinâmico Express que substituiu o Quartz (SSG estático) em `{{BLOG_URL}}`. Serve 34 posts + 44 notas do zettelkasten renderizados a partir de markdown com pipeline customizado (wikilinks, callouts, syntax highlight, strip de tags).

## Estrutura de Diretórios

```
{{COMMANDER_HOME}}/projects/pycode-blog/     ← Deploy ativo (PM2)
├── server.js
├── package.json
├── ecosystem.config.cjs               ← PM2 config
├── content/ → {{COMMANDER_HOME}}/projects/pycode-cerebro/public/content/  (symlink)
├── views/                             ← EJS templates
│   ├── base.ejs                       ← Layout (nav, footer, dark mode)
│   ├── home.ejs                       ← Grid de cards + hero
│   ├── post.ejs                       ← Post individual
│   ├── note.ejs                       ← Zettelkasten
│   └── 404.ejs
├── public/                            ← express.static
│   ├── css/design-tokens.css
│   ├── css/main.css
│   └── js/dark-mode.js
└── src/                               ← Backend
    ├── app.js
    ├── routes/blog.js, notes.js, sobre.js, api.js
    ├── services/posts.js, markdown.js
    └── utils/frontmatter.js
```

⚠️ **Workspace de desenvolvimento**: `{{COMMANDER_HOME}}/{{COMMANDER}}-blog/` — {{FRONTEND_ENGINEER}} edita aqui. Sincronizar com `cp` para deploy.

## Pipeline de Mensagens WhatsApp → Blog

### Fluxo

```
WhatsApp (Grupo IA Master Elite) → Evolution API ou Bridge Baileys
  → Webhook POST → broker_whatsapp.py (FastAPI, porta 8001)
    → Grupo: /webhook → filtra chatId → append hoje.md
    → DM Comandante: /webhook → filtra senderId → append inbox.md
  → Fechamento diário (22:55 crontab):
    → sintetizador.py (gera resumo + zettelkasten)
    → Rotaciona hoje.md → grupo_<data>.md
    → Restart pycode-blog (cache-busting)
```

### Arquivos

| Arquivo | Função |
|---------|--------|
| `pycode-cerebro/scripts/broker_whatsapp.py` | Recebe webhook, filtra grupo→hoje.md, DM→inbox.md |
| `pycode-cerebro/scripts/sintetizador.py` | Gera resumo diário (blog) + notas Zettelkasten via API OpenCode |
| `pycode-cerebro/scripts/fechamento_diario.sh` | Orquestra: reset buffer → sintetiza → aguarda 5min → rotaciona hoje.md → restart blog |
| `pycode-cerebro/data/historico/hoje.md` | Mensagens do dia atual (buffer) |
| `pycode-cerebro/data/historico/grupo_<data>.md` | Backup diário rotacionado |

### Fechamento Diário

Crontab: `55 22 * * * {{COMMANDER_HOME}}fae/projects/pycode-cerebro/scripts/fechamento_diario.sh`

⚠️ **NÃO usar PM2 cron** — PM2 cron só dispara se o processo estiver `online`. Prefira crontab do sistema.

```bash
# fechamento_diario.sh
1. Reset grupo.txt (buffer cumulativo)
2. Roda sintetizador.py (modelo: deepseek-v4-pro, API key do Aragorn)
3. Aguarda 5 minutos (persistência)
4. Rotaciona hoje.md → grupo_<data>.md
5. Reinicia pycode-blog (cache-busting)
```

### Sintetizador

- Usa OpenCode API (`opencode.ai/zen/go/v1`)
- Modelo padrão: `deepseek-v4-pro` (tarefa pesada de síntese)
- API key: carrega do `.env` do Aragorn (OVH)
- Gera: resumo diário (blog) + notas Zettelkasten (conceitos)
- Prompt: separa por `---SEPARATOR---` as duas tarefas

### Broker WhatsApp

- FastAPI na porta 8001 (systemd `webhook-whatsapp.service`)
- `POST /webhook` — recebe evento da bridge/evolution
- `GET /send?number=X&text=Y` — agentes enviam WhatsApp
- `GET /inbox` — lê últimas mensagens do Comandante
- Adaptável: aceita formato Evolution API e formato bridge Hermes

### Formato Bridge Hermes (evento)

```json
{
  "messageId": "...",
  "chatId": "120363425868389123@g.us",
  "senderId": "556799623440@s.whatsapp.net",
  "senderName": "{{COMMANDER}}",
  "isGroup": true,
  "body": "texto da mensagem",
  "timestamp": 1234567890
}
```

### Hashtags no Markdown

⚠️ **Problema:** O sintetizador pode gerar linhas como `#hermes #agentes #obsidian #multi-pc` que viram headings H1 no markdown.

**Solução:** O `stripInlineTags()` em `src/services/markdown.js` já remove linhas que são APENAS hashtags. Regex: `/^#[\w-]+(\s+#[\w-]+)*\s*$/`. Se falhar, remover manualmente com:
```bash
python3 -c "
import re; path='blog/2026-05-28.md'
with open(path) as f: lines=f.readlines()
lines=[l for l in lines if not re.match(r'^#[a-z]',l.strip()) or re.match(r'^# ',l.strip())]
with open(path,'w') as f: f.writelines(lines)
"
```

## Migração de Servidor

Ao migrar o pycode-blog entre servidores, NÃO esquecer:

1. **`pycode-cerebro/data/historico/`** — contém `hoje.md` + `grupo_*.md` (808 KB+)
2. **Scripts** — `sintetizador.py`, `fechamento_diario.sh`, `broker_whatsapp.py`
3. **Crontab** — `fechamento_diario.sh` às 22:55
4. **Dependências Python** — `python-dotenv`, `requests` (via apt: `python3-dotenv`, `python3-requests`)
5. **Adaptar paths** — user `{{COMMANDER}}` → `{{COMMANDER}}fae` nos scripts
6. **Systemd broker** — `webhook-whatsapp.service` na porta 8001

### Por que porta 8080 e não 3100?

O Cloudflare Tunnel é gerenciado **remotamente** (Zero Trust dashboard), não via `/etc/cloudflared/config.yml`. A rota `{{BLOG_URL}} → localhost:8080` já existia para o Quartz. Em vez de reconfigurar o túnel (que exigiria acesso ao dashboard), o novo app **herdou a porta 8080** do Quartz.

Sequência: `pm2 stop quartz-cerebro` → `pm2 start pycode-blog` (porta 8080) → zero mudanças no túnel.

### Por que NÃO usar nginx?

O tráfego para `{{BLOG_URL}}` NÃO passa pelo nginx Docker (`oeste-odontologia-nginx`). O Cloudflare Tunnel roteia direto para `localhost:8080`. O nginx Docker serve apenas `oesteodontologia.com.br`, `dashboard`, `evolution`.

Adicionar server block ao container Docker de produção seria risco desnecessário (perdido em recriação de container).

### Cache-Busting sem API Cloudflare

Sem token de API Cloudflare no servidor, implementado cache-busting por query string.

**Implementação final (funcional):**
```js
// No server.js — timestamp do boot
app.locals.cacheBust = Date.now();
// ou versão manual incrementável:
app.locals.cacheVersion = '2';
```

```html
<!-- No base.ejs — usa timestamp do boot -->
<link rel="stylesheet" href="/css/main.css?v=<%= cacheBust %>">
```

Cada restart de PM2 gera fingerprint nova → Cloudflare trata como recurso inédito. Funciona mesmo quando `app.locals.cacheBust = Date.now()` é setado uma única vez no boot (não por request).

Fallback seguro (se `app.locals` falhar): hardcoded `?v=2` no `base.ejs` diretamente.

🔍 **Cloudflare cache TTL**: Servidor responde com `cache-control: public, max-age=86400` (24h). Cache-busting via query string é ESSENCIAL — sem ele, mudanças no CSS só refletem após 24h. Não há token de API disponível no servidor para purgar cache programaticamente.

### Rollback

```bash
pm2 stop pycode-blog && pm2 restart quartz-cerebro
```

2 segundos. O Quartz continua instalado e funcional.

## Pipeline de Markdown

```
raw .md
  → stripInlineTags()        # Remove #tags que virariam H1
  → processWikilinks()       # [[Target]] → <a> ou <span>
  → md.render()              # markdown-it + anchor + container + Prism.js
  → HTML
```

### Plugins ativos
- `markdown-it-anchor` — header IDs + slugify customizado (NÃO usa `permalink` para evitar `#` visível)
- `markdown-it-container` — callouts (note, tip, warning, danger, info)
- `Prism.highlight()` — syntax highlight via Prism.js (gera classes `.token-*`, NÃO `.hljs-*`)
- `gray-matter` — frontmatter YAML

⚠️ **markdown-it-anchor vs permalink**: O plugin atual NÃO usa `permalink`. Config:
```js
md.use(anchor, {
  slugify: s => s.toLowerCase().trim()
    .replace(/[^a-z0-9àáâãäåæçèéêëìíîïðñòóôõöøùúûüýþ \\-]/g, '')
    .replace(/\\s+/g, '-').replace(/-+/g, '-').replace(/^-+|-+$/g, '')
});
```
Isso gera IDs limpos sem `#` visível.

**NUNCA use `linkAfterHeader`** — ele coloca o `<a>` FORA do heading como elemento irmão, gerando texto visível (assistive text + `#`) mesmo com `.sr-only`. Se precisar de permalink, use `linkInsideHeader` com `style: 'visually-hidden'` e `visuallyHiddenClass: 'sr-only'`, E garanta que `.sr-only` CSS esteja definido.

**Slugify crítico para índice navegável**: O `defaultSlugify` do markdown-it-anchor preserva PONTOS de números (`"1."` → `"1.-"`) e URL-encoda acentos. Ex: `## 1. Visão` gera ID `1.-vis%C3%A3o...` — se o índice manual do tutorial usa `#1-visão...` (sem o ponto), o link não navega. **Custom slugify que remove caracteres especiais (., :, !) é ESSENCIAL** para que tabelas de conteúdo manuais funcionem.

### Prism.js Syntax Highlighting — Cuidados ao Adicionar/Modificar

O gerador usa `Prism.highlight()` no hook `highlight:` do markdown-it, produzindo HTML com classes `.token-*`:
```html
<code class="language-python">
  <span class="token keyword">import</span>
  <span class="token string">"texto"</span>
</code>
```

**O CSS ANTIGO** usava classes `.hljs-*` (highlight.js), que NÃO correspondem ao Prism.js — syntax highlighting ficava quebrado mesmo que o HTML estivesse correto.

**Correção**: Substituir (ou complementar) as regras `.hljs-*` por `.token-*`:
```css
/* Prism tokens — light mode (MongoDB brand colors) */
.post-body .token.keyword,
.post-body .token.control { color: #006cfa; }       /* Azul brand */
.post-body .token.string,
.post-body .token.attr-value { color: #00684a; }    /* Verde escuro */
.post-body .token.comment,
.post-body .token.prolog { color: var(--cool-gray); font-style: italic; }

/* Prism tokens — dark mode (VS Code Dark-inspired) */
[data-theme="dark"] .post-body .token.keyword { color: #569cd6; }
[data-theme="dark"] .post-body .token.string  { color: #ce9178; }
[data-theme="dark"] .post-body .token.comment { color: #6a9955; }
```

Manter `.hljs-*` como fallback para compatibilidade não quebra nada.

⚠️ **Perigo:** Ao ADICIONAR novo bloco CSS no `main.css`, NÃO remover classes existentes da landing page. Verificar se as classes usadas por `landing.ejs` continuam no CSS:
- `.btn`, `.btn-primary`, `.btn-outline`, `.btn-teal`
- `.hero-buttons`, `.stats-bar`, `.stat-value`, `.stat-label`
- `.section`, `.section-title`, `.section-dark`
- `.card-accent`, `.card h3`, `.card p`, `.card-topics`
- `.topics-cloud`, `.topic-pill`, `.topic-count`
- `.footer`
- `.filter-bar`, `.filter-tag`

Se alguma dessas sumir, a página inicial perde toda a estilização. Sempre verificar com:
```bash
# Extrair classes usadas pela landing page
grep -oP 'class="[^"]*"' views/landing.ejs | sort -u
# Verificar se cada classe tem CSS definido
for cls in btn-primary stats-bar section-title; do
  grep -q "\.$cls" public/css/main.css && echo "✅ $cls" || echo "❌ $cls"
done
```

### Wikilinks
Plugin customizado: `[[{{COMMANDER}} Faé]]` → `<a href="/notes/{{COMMANDER}}-fae" class="wikilink">`. Se a nota não existe no zettelkasten → `<span class="wikilink-broken">` (muted, borda tracejada, cursor help).

### Extração de Tópicos
`_extractTopics()` conta frequência de wikilinks no post, retorna top 3 → exposto como `post.topics[]` na API e nos cards.

## Layout — Largura do Post

### O problema do "2 boxes vs 3 boxes"

{{COMMANDER}} descreveu o problema em linguagem não-técnica: na Home, a largura é de 3 boxes (cards); no post individual, o texto ocupava "2 boxes". A causa era `max-width: 720px` nos elementos de texto.

**Solução**: remover `max-width` do `.post-body` e filhos (`p`, `h2`, `h3`, `ul`, `ol`, `blockquote`, `.callout`). O texto usa a largura total do container (`1100px`), igual à grid de 3 cards.

```css
/* Antes: texto espremido em 720px (~65ch) */
.post-body p,
.post-body h2,
.post-body h3 {
  max-width: var(--max-width-reading);
}

/* Depois: texto ocupa 1100px (3 boxes) */
.post-body p,
.post-body h2,
.post-body h3 {
  max-width: none;
}
```

A tipografia (`font-size: 1.125rem`, `line-height: 1.8`) compensa a largura extra.

### Heurística para feedback não-técnico

O usuário não-técnico descreve o problema em "boxes" (cards da grid). Se a grid tem 3 cards (~1100px), o post deve ter a mesma largura. Use essa referência visual em vez de pixels.

## Rotas (versão final — Home + Blog unificados)

| Rota | View | Descrição |
|---|---|---|
| `GET /` | `landing.ejs` | Hero + stats (33 dias, 42 tópicos) + 3 destaques + nuvem 20 tópicos + grid completo |
| `GET /blog` | — | Redirect 301 → `/` (eliminado redundância) |
| `GET /blog/:slug` | `post.ejs` | Post individual, 1100px sem max-width |
| `GET /notes/:slug` | `note.ejs` | Zettelkasten com wikilinks resolvidos |
| `GET /tutorial` | `post.ejs` | "Como funciona este Diário de Bordo" (post isolado da listagem) |
| `GET /api/posts` | JSON | Todos os posts com `topics[]` |
| `GET /api/posts/:slug` | JSON | Post específico |

⚠️ **Nav simplificada**: "Diário · Tutorial" — sem "Blog". O link "Blog" foi removido após unificação.

## PM2 + Crontab

```bash
pm2 status pycode-blog
# name: pycode-blog, script: server.js, port: 8080
# watch: disabled (restart manual para cache-busting)
# max_memory_restart: 200M

# Fechamento diário (NÃO é PM2 — é crontab do sistema):
# 55 22 * * * {{COMMANDER_HOME}}fae/projects/pycode-cerebro/scripts/fechamento_diario.sh
# Motivo: PM2 cron não dispara quando o processo está stopped.
# Crontab do sistema é mais confiável para tarefas agendadas.
```

## Migração do Fechamento Diário e Sintetizador

Os scripts que mantêm o blog atualizado residem em `pycode-cerebro/scripts/` e precisam ser migrados junto com o blog:

| Script | Função | Path |
|--------|--------|------|
| `fechamento_diario.sh` | Orquestrador diário (22:55) | `~/projects/pycode-cerebro/scripts/` |
| `sintetizador.py` | Gera resumo + zettelkasten via IA | `~/projects/pycode-cerebro/scripts/` |

**Procedimento de migração:**
1. Copiar ambos os scripts do servidor antigo
2. Adaptar paths (`{{COMMANDER_HOME}}/` → `{{COMMANDER_HOME}}fae/`)
3. No `sintetizador.py`: ajustar `load_dotenv()` para um `.env` existente (ex: `aragorn/.env`)
4. No `sintetizador.py`: ajustar `MODELO` (ex: `deepseek-v4-flash` ou `deepseek-v4-pro`)
5. No `fechamento_diario.sh`: remover `npx quartz build`, substituir por `pm2 restart pycode-blog`
6. Instalar dependências: `apt install python3-dotenv python3-requests`
7. Agendar no **crontab do sistema** (NÃO PM2 cron — ver pitfall abaixo)

### Pitfall: PM2 cron vs system crontab

PM2 `--cron` só dispara se o processo está `online`. Scripts pontuais devem usar crontab:

```bash
(crontab -l 2>/dev/null; echo '55 22 * * * /path/fechamento_diario.sh >> /path/log 2>&1') | crontab -
```

### Pitfall: Hashtags viram headings no markdown

Linhas de hashtags como `#hermes #agentes #obsidian #multi-pc` são interpretadas como H1 pelo markdown-it porque `#` no início da linha é sintaxe de heading. O `stripInlineTags()` cobre isso com regex `^#[\\w-]+(\\s+#[\\w-]+)*\\s*$`, mas posts gerados ANTES da implementação do filtro podem conter essas linhas.

**Correção para posts existentes:** remover manualmente as linhas de hashtags do arquivo `.md`.

### Pitfall: Dados históricos não migrados

O diretório `data/historico/` contém `grupo_<data>.md` (808 KB, 20+ arquivos). Sem ele, o blog perde todo o histórico e a página inicial fica vazia. Copiar com `rsync` ou `tar`.

1. **`var(--white)` no dark mode**: `--white: #001e2b` no tema escuro — usar `#ffffff` fixo em elementos que precisam ser brancos em ambos os temas (nav, hero, botões).
2. **Tags inline viram H1**: `#django #multi-tenant` no markdown é interpretado como heading. Fazer strip antes do `md.render()`.
3. **Cloudflare cache**: CSS novo não reflete sem query string ou purga. Cache-busting resolve.
4. **Symlink, não cópia**: O conteúdo reside no repo `pycode-cerebro` e é acessado via symlink. O pipeline WhatsApp → `.md` permanece intacto.
5. **Túnel é remoto**: `/etc/cloudflared/config.yml` local está desatualizado. Configuração real vem do Cloudflare Zero Trust dashboard. Verificar com `sudo journalctl -u cloudflared | grep \"config=\"`.
6. **`.sr-only` necessário para markdown-it-anchor**: Se usar `linkInsideHeader` com `visuallyHiddenClass: 'sr-only'`, o CSS `.sr-only` precisa existir. Sem ele, o `#` fica visível no final de todos os títulos.
7. **Prism.js vs highlight.js — classes divergentes**: O hook `highlight:` do markdown-it usa `Prism.highlight()` que gera classes `.token-*`. O CSS ANTIGO (e o mais comum em templates) usa `.hljs-*` (highlight.js). Se adicionar syntax highlighting, verificar qual biblioteca o gerador usa e adicionar CSS compatível. Ambas podem coexistir:
   - `.token-*` para Prism (ativo)
   - `.hljs-*` para highlight.js (fallback/compatibilidade)
8. **Code blocks ilegíveis em light mode**: `.post-body pre code { color: var(--black); }` — em light mode `--black` = `#000000`, mas o `<pre>` usa `background: var(--color-code-bg)` = `--teal` = `#001e2b` (escuro). Resultado: **texto preto em fundo escuro**. Funciona em dark mode porque `--black` vira `#e8edeb`. Fix: usar cor clara fixa ou definir `--color-code-text: #8ea6b4` (contraste ~4.8:1 contra `#001e2b`).
9. **Landing page quebra ao modificar CSS**: Ao adicionar NOVOS blocos no `main.css`, verificar se as classes da landing page (`views/landing.ejs`) continuam no CSS. Extrair classes do template e cruzar com o CSS.
10. **markdown-it-anchor `linkAfterHeader` quebra a página**: NUNCA use este permalink style.
11. **Cloudflare cache**: procedimento completo de cache-busting com bump de versão no `base.ejs`.
12. **`--color-code-text` precisa de cor fixa para light mode**.
13. **Prism.js syntax highlighting — verificar classes geradas vs CSS**.
14. **Hashtags em linhas próprias viram parágrafo denso**: O `stripInlineTags()` remove linhas que são APENAS hashtags (ex: `#hermes #agentes #obsidian`), mas só se a regex casar. Linhas como `#tailscale #ssh #rdp #macos #windows` passam pelo filtro (regex: `/^#[\\w-]+(\\s+#[\\w-]+)*\\s*$/`). Se hashtags com caracteres especiais escaparem, viram um parágrafo contínuo de texto sem espaçamento — visualmente "tags espremidas entre títulos". **Solução:** verificar o markdown fonte com `grep '^#[a-z].*#.*#'` e remover manualmente se necessário, ou ajustar a regex no `markdown.js`.
15. **Fechamento diário (PM2 cron)**: O script `fechamento_diario.sh` roda via PM2 cron (`55 22 * * *`). Fluxo:
    - Reseta `grupo.txt` (buffer cumulativo)
    - Roda `sintetizador.py` (gera resumo blog + notas zettelkasten)
    - Aguarda 5 min para persistência
    - Rotaciona `hoje.md` → `grupo_<data>.md`, cria novo `hoje.md` vazio
    - Reinicia `pycode-blog` (PM2 restart para cache-busting)
    
    **Dependências do sintetizador:** `python3-dotenv`, `python3-requests` (apt). API key: `OPENCODE_GO_API_KEY` do .env do Aragorn. Modelo: `deepseek-v4-pro` (qualidade > custo para síntese).
    
    **Migração:** Na migração OVH→OVH, copiar `data/historico/` (808 KB de arquivos `grupo_*.md`) e adaptar paths de `{{COMMANDER_HOME}}/` → `{{COMMANDER_HOME}}fae/`.
   grep -oP 'class="[^"]*"' views/landing.ejs | sort -u

   # Verificar se cada classe tem CSS definido
   for cls in btn-primary stats-bar section-title card-accent topics-cloud footer; do
     grep -q "\.$cls" public/css/main.css && echo "✅ $cls" || echo "❌ $cls"
   done
   
   # Verificar via HTTP (após restart)
   curl -s http://127.0.0.1:8080/css/main.css | grep -c "btn-primary\|stats-bar\|section-title"
   ```
   
   **Causa comum**: ao adicionar bloco de syntax highlighting no main.css, seções existentes da landing page são removidas sem perceber. O main.css encolhe de ~1050 para ~850 linhas. Restaurar as classes ausentes no final do arquivo.

   ⚠️ **Restauração aproximada NÃO é suficiente**: apenas garantir que as classes existam no CSS não resolve — os valores de `padding`, `gap`, `margin`, `font-size`, `line-height`, `border-radius` e `color` precisam ser EXATAMENTE os originais. Diferenças sutis (ex: `padding: var(--space-16)` vs `padding: var(--space-20)`) alteram proporções visíveis. Sempre reconstruir a partir do HTML renderizado + design tokens, nunca "de cabeça".

   **Procedimento de recuperação quando CSS quebrou e não há git:**

   ```bash
   # 1. Extrair TODAS as classes usadas pela landing page
   grep -oP 'class="[^"]*"' views/landing.ejs | sed 's/class="//;s/"//' | tr ' ' '\n' | sort -u
   
   # 2. Extrair do post/tutorial também
   grep -oP 'class="[^"]*"' views/post.ejs | sed 's/class="//;s/"//' | tr ' ' '\n' | sort -u
   
   # 3. Para cada classe, verificar se existe no CSS e se os valores estão corretos
   # Use os design tokens como referência de cores/espaçamentos
   grep -E '^--' public/css/design-tokens.css
   
   # 4. Caso a classe exista mas o layout ainda esteja quebrado,
   # o problema são OS VALORES, não a presença da classe. 
   # Comparar com versões anteriores via session_search ou backup
   ```

10. **markdown-it-anchor `linkAfterHeader` quebra a página**: NUNCA use este permalink style. Ele gera `<a class="sr-only">#</a>` como ELEMENTO IRMÃO do heading (fora do `<h2>`), não dentro. Mesmo com `.sr-only`, o assistive text `aria-label` pode renderizar como texto visível em alguns contextos. Prefira `linkInsideHeader` ou nenhum permalink.

11. **Cloudflare cache: procedimento completo de cache-busting**: O Cloudflare cacheia CSS por 24h (max-age=86400). Para forçar refresh imediato:

    ```bash
    # 1. Bump version no template
    # Editar base.ejs: v=N → v=N+1

    # 2. Restart PM2 para carregar novo template (watch pode não pegar)
    pm2 restart pycode-blog

    # 3. Verificar se o HTML serve com a nova versão
    curl -s http://127.0.0.1:8080/ | grep -o 'v=[0-9]'

    # 4. Verificar que Cloudflare está com MISS no CSS
    curl -sI "https://{{BLOG_URL}}/css/main.css?v=N" | grep cf-cache-status
    # Deve mostrar: cf-cache-status: MISS

    # 5. Hard-refresh no browser (Ctrl+F5) no lado do usuário
    ```

14. **Linhas de hashtags do sintetizador**: O `sintetizador.py` pode gerar linhas como `#hermes #agentes #obsidian #multi-pc` — o `stripInlineTags()` (via regex `^#[\\w-]+(\\s+#[\\w-]+)*\\s*$`) já remove essas linhas. Se aparecerem no HTML, verificar se o conteúdo passou pelo pipeline de renderização (o strip é chamado em `markdown.js:123`). Em caso de posts antigos pré-migração, remover manualmente com script Python (ver `references/cleanup-hashtags.md`).
    ```css
    :root {
      --color-code-text: #8ea6b4;  /* ~4.8:1 contra #001e2b ✅ */
    }
    [data-theme="dark"] {
      --color-code-text: var(--cool-gray);  /* #8a9ba2 — aceitável no dark */
    }
    ```
    Testar contraste com ferramentas como WebAIM Contrast Checker.

13. **Prism.js syntax highlighting — verificar classes geradas vs CSS**: Após adicionar/adotar Prism.js, confirmar que as classes geradas no HTML correspondem ao CSS:
    ```bash
    # Verificar classes Prism no HTML renderizado
    curl -s http://127.0.0.1:8080/tutorial | grep -oP 'class="language-\w+"' | sort -u
    curl -s http://127.0.0.1:8080/tutorial | grep -oP 'class="token \w+"' | sort -u
    
    # Verificar se cada classe tem CSS
    for token in keyword string comment number function builtin operator; do
      grep -q "\.token\.$token" public/css/main.css && echo "✅ .token.$token" || echo "❌ .token.$token"
    done
    ```
    
    Prism usa `<span class="token keyword">`; highlight.js usa `<span class="hljs-keyword">`. São incompatíveis. Manter ambos como fallback não quebra, mas apenas um estilo será aplicado por vez.

## Fechamento Diário e Geração de Resumos (Sintetizador)

### Pipeline Noturno

Todo dia às **22:55** (crontab do sistema, NÃO PM2 cron) o script `fechamento_diario.sh` executa:

```
1. Reset grupo.txt (buffer cumulativo — prevenção de intoxicação)
2. Roda sintetizador.py → gera resumo do dia + notas Zettelkasten (usa IA)
3. Aguarda 5 min (persistência dos arquivos gerados)
4. Rotaciona hoje.md → grupo_<data>.md, cria novo hoje.md vazio
5. pm2 restart pycode-blog (cache-busting)
```

### Scripts

| Script | Local | Função |
|--------|-------|--------|
| `fechamento_diario.sh` | `pycode-cerebro/scripts/` | Orquestrador. Agendado no crontab. |
| `sintetizador.py` | `pycode-cerebro/scripts/` | Chama IA (OpenCode) para gerar post `.md` + Zettelkasten |
| `rotina_diaria.sh` | `pycode-cerebro/scripts/` | Versão manual (sem reset/rotação) |

### Configuração do sintetizador.py

```python
load_dotenv("{{COMMANDER_HOME}}fae/.hermes/profiles/aragorn/.env")
chave_api = os.getenv("OPENCODE_GO_API_KEY")
MODELO = "deepseek-v4-pro"  # qualidade > custo para síntese
```

**:red_circle: Adaptação na migração:** Paths mudam de `{{COMMANDER_HOME}}/` → `{{COMMANDER_HOME}}fae/`. Ajustar `load_dotenv`, `PATH_RAW`, `PATH_BLOG`, `PATH_ZETTEL` e `MODELO`.

### ⚠️ Por que NÃO usar PM2 cron

PM2 `--cron` só dispara se o processo está `online`. Scripts pontuais (que executam e saem) ficam `stopped` após conclusão e o cron NÃO dispara. Usar crontab do sistema:

```bash
(crontab -l 2>/dev/null; echo '55 22 * * * /path/fechamento_diario.sh >> /path/log 2>&1') | crontab -
```

### Gerar resumo de um dia específico (retroativo)

```bash
cp hoje.md /tmp/hoje.md.bak
cp grupo_29-05-2026.md hoje.md
cd {{COMMANDER_HOME}}fae/projects/pycode-cerebro/scripts
python3 sintetizador.py
mv /tmp/hoje.md.bak hoje.md
```

### Dependências Python

```bash
sudo apt install -y python3-dotenv python3-requests
```

## Hashtags em Linhas — Problema e Correção

### Problema

O `sintetizador.py` gera linhas de "tags" como `#hermes #agentes #obsidian #multi-pc`. Estas são interpretadas como heading H1 pelo markdown-it. O `stripInlineTags()` (regex `/^#[\\w-]+(\\s+#[\\w-]+)*\\s*$/`) remove essas linhas na renderização, mas posts gerados ANTES da migração podem já contê-las no `.md`.

**Sintoma visual:** Entre títulos do post, aparece uma linha densa de texto: "hermes agentes obsidian multi-pc skill pdf conhecimento..."

### Diagnóstico

```bash
grep -n '^#[a-z].*#.*#' public/content/blog/2026-05-*.md
```

### Correção

```bash
python3 -c "
import re
for slug in ['2026-05-28', '2026-05-24']:
    path = f'public/content/blog/{slug}.md'
    with open(path) as f: lines = f.readlines()
    new = [l for l in lines if not (re.match(r'^#[a-z]', l.strip()) and not re.match(r'^# ', l.strip()))]
    with open(path, 'w') as f: f.writelines(new)
    print(f'{slug}: {len(lines)-len(new)} linhas removidas')
"
pm2 restart pycode-blog
```

## Hashtags em Linhas — Limpeza Pós-Migração

### Problema

O `sintetizador.py` gera linhas de "tags" no markdown como:

```
#hermes #agentes #obsidian #multi-pc
#skill #pdf #conhecimento
```

Essas linhas são interpretadas como **heading H1** pelo markdown-it (porque `#` no início da linha). O `stripInlineTags()` do pipeline remove essas linhas durante a renderização de novos posts, mas **posts gerados antes da migração** (no servidor antigo) podem já conter essas linhas no arquivo `.md`.

### Sintoma

No blog, entre títulos, aparece uma linha densa de texto como:

> hermes agentes obsidian multi-pc skill pdf conhecimento anthropic opus tokens sistemas-operacionais dev tailscale ssh rdp macos windows opencode copilot custo-beneficio

São todas as hashtags do post concatenadas, renderizadas como parágrafo único.

### Diagnóstico

```bash
# Procurar linhas que começam com #palavra (hashtag, não heading markdown)
grep -n '^#[a-z].*#.*#' {{COMMANDER_HOME}}fae/projects/pycode-cerebro/public/content/blog/2026-05-*.md
```

### Correção — Remover linhas de hashtags

```bash
python3 -c "
import re
for slug in ['2026-05-28', '2026-05-24']:  # posts afetados
    path = f'{{COMMANDER_HOME}}fae/projects/pycode-cerebro/public/content/blog/{slug}.md'
    with open(path) as f:
        lines = f.readlines()
    new = [l for l in lines if not (re.match(r'^#[a-z]', l.strip()) and not re.match(r'^# ', l.strip()))]
    with open(path, 'w') as f:
        f.writelines(new)
    print(f'{slug}: {len(lines) - len(new)} linhas removidas')
"
pm2 restart pycode-blog
```

### Prevenção

O `stripInlineTags()` em `src/services/markdown.js` já remove essas linhas para posts novos. A regex:

```javascript
if (/^#[\\w-]+(\\s+#[\\w-]+)*\\s*$/.test(trimmed)) return false;
```

Se posts novos ainda exibirem o problema, verificar se `stripInlineTags()` está sendo chamado no pipeline (linha 123 do `markdown.js`).

Quando usuário reporta problema visual no blog, seguir esta cadeia:

```
Problema reportado (ex: "texto ilegível", "# no fim dos títulos", "índice não navega")
  ↓
1. Marcação fonte
   - Ver o .md original (frontmatter + corpo)
   - Checar headers, links de índice, tags
  ↓
2. Pipeline de renderização
   - `stripInlineTags()` removeu algo indevido?
   - `processWikilinks()` quebrou link?
   - `md.render()` com plugins: anchor adiciona IDs? container adiciona divs?
   - Prism.js adicionou classes de syntax highlight?
  ↓
3. HTML gerado
   - Inspecionar via browser_console com expressão JS: `document.querySelector('.post-body').innerHTML`
   - Verificar IDs de headings, classes CSS, estrutura DOM
  ↓
4. CSS Design Tokens
   - `design-tokens.css`: `--color-bg`, `--color-text`, `--color-code-bg`, `--black`, `--white`
   - Lembrar que em light mode `--black = #000000`, em dark mode `--black = #e8edeb`
   - Lembrar que `--teal` NÃO é sobrescrito no dark mode (sempre `#001e2b`)
  ↓
5. CSS Specificity
   - `main.css`: regras específicas que podem sobrescrever tokens
   - Verificar se classes como `.sr-only`, `.wikilink-broken`, `.hljs-*` estão definidas
  ↓
6. Causa raiz identificada
   - Delegar correção com: arquivo, linha, diff exato, teste após deploy
```
