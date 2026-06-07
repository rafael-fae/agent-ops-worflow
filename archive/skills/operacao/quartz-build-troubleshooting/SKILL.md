---
name: quartz-build-troubleshooting
description: Troubleshooting de build e serve do Quartz 4 para o blog Pycode Cérebro — configuração, tags indesejadas, servidor crashando, e rebuild limpo.
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Quartz Build & Serve — Troubleshooting

## Contexto

> ⚠️ **SUPERSEDIDO (25/05/2026)**: O Quartz foi substituído pelo PyCode Blog (Express + EJS dinâmico) em `{{BLOG_URL}}`. Ver skill `pycode-blog-architecture` para a arquitetura atual. O Quartz permanece instalado como rollback (`pm2 restart quartz-cerebro`).

O blog Pycode Cérebro usava Quartz 4 estático, servido via PM2 (`quartz-cerebro`) na porta 8080. O conteúdo está em `content/blog/` (arquivos `.md`). O Quartz foi substituído por um app Express que lê os mesmos arquivos `.md` em runtime (sem build).

## Estrutura de diretórios

```
{{COMMANDER_HOME}}/projects/pycode-cerebro/public/
├── content/blog/          # Markdown fonte
├── content/zettelkasten/  # Notas de Zettelkasten
├── quartz.config.ts       # Configuração do Quartz
├── public/                # OUTPUT do build (HTML gerado)
└── package.json
```

**Atenção**: o output vai para `public/public/` (subdiretório `public` dentro do projeto `public/`).

## PM2 — Servidor Quartz

```bash
pm2 status quartz-cerebro
# Comando: npx quartz build --serve --port 8080
# CWD: {{COMMANDER_HOME}}/projects/pycode-cerebro/public
```

O `--serve` faz build + serve. Sem `--serve`, apenas builda.

## Problema 1: Tags indesejadas (centenas)

### Sintoma

O site mostra centenas de tags (ex: `Groq`, `Hermes`, `Claude Code`, nomes de pessoas) no Explorer e nas páginas.

### Causa

O `Plugin.TagPage()` no `quartz.config.ts` gera automaticamente uma página de tag para cada `[[wikilink]]` encontrado no conteúdo. Como os posts do blog usam wikilinks para navegação no Graph View, cada termo vira uma tag.

### Solução

Remover `Plugin.TagPage()` dos emitters em `quartz.config.ts`:

```typescript
emitters: [
  Plugin.AliasRedirects(),
  Plugin.ComponentResources(),
  Plugin.ContentPage(),
  Plugin.FolderPage(),
  // Plugin.TagPage(),  ← REMOVER esta linha
  Plugin.ContentIndex({...}),
  ...
],
```

Após remover, rebuildar (Problema 3).

## Problema 2: baseUrl errado

### Sintoma

Navegação SPA quebrada, links quebrados, Explorer não lista corretamente.

### Causa

`baseUrl` padrão é `"quartz.jzhao.xyz"` — precisa ser o domínio real.

### Solução

Em `quartz.config.ts`:
```typescript
baseUrl: "{{BLOG_URL}}",  // domínio real
```

## Problema 3: Build falha com `ENOTEMPTY`

### Sintoma

```
ERROR: ENOTEMPTY: directory not empty, rmdir 'public'
```

### Causa

O PM2 está servindo arquivos do diretório `public/` enquanto o build tenta limpar e recriar o mesmo diretório. Conflito de I/O.

### Solução — Rebuild limpo completo

```bash
# 1. Parar o servidor
pm2 stop quartz-cerebro

# 2. Limpar output antigo
cd {{COMMANDER_HOME}}/projects/pycode-cerebro/public
rm -rf public/ tags/

# 3. Build limpo (sem --serve)
npx quartz build

# 4. Reiniciar servidor
pm2 restart quartz-cerebro
# ou recriar:
pm2 delete quartz-cerebro
pm2 start "npx quartz build --serve --port 8080" --name quartz-cerebro
```

### Verificação pós-build

```bash
# Verificar se o servidor está ouvindo
ss -tlnp | grep 8080

# Testar acesso
curl -s -o /dev/null -w "HTTP:%{http_code}" http://127.0.0.1:8080/blog/
curl -s -o /dev/null -w "HTTP:%{http_code}" http://127.0.0.1:8080/blog/2026-05-21

# Contar arquivos gerados
find public/public -type f | wc -l
```

## Problema 4: Servidor Python não resolve URLs limpas

### Sintoma

`/blog/` funciona mas `/blog/2026-05-21` retorna 404.

### Causa

`python3 -m http.server` não faz SPA routing nem resolve URLs sem extensão `.html`.

### Solução

Usar SEMPRE `npx quartz build --serve` do próprio Quartz, que implementa o SPA routing correto. Se o build falhar, resolver o Problema 3 primeiro.

## Pipeline de processamento (LEGADO — Quartz)

> ⚠️ **Atualizado (25/05/2026)**: O último passo mudou. O `npx quartz build` foi removido do `fechamento_diario.sh`. O novo app Express lê os `.md` em runtime — sem build. O pipeline de geração (WhatsApp → .md) permanece idêntico.

```
WhatsApp → Evolution API → webhook-whatsapp (8001) → hoje.md
                                                            ↓
                                             fechamento_diario.sh (22:55)
                                                            ↓
                                             sintetizador.py (IA analisa)
                                                            ↓
                                             content/blog/YYYY-MM-DD.md
                                                            ↓
                                             Express lê em runtime (sem build)
```

### Processar dias históricos manualmente

```bash
cd {{COMMANDER_HOME}}/projects/pycode-cerebro/scripts
source {{COMMANDER_HOME}}/hermes_env/bin/activate

# Um dia específico
python3 sintetizador.py --arquivo ../data/historico/grupo_21-05-2026.md

# Múltiplos dias (encadeado)
python3 sintetizador.py --arquivo ../data/historico/grupo_22-05-2026.md && \
python3 sintetizador.py --arquivo ../data/historico/grupo_23-05-2026.md
```

O script usa `OPENCODE_GO_API_KEY` do `.env` do {{ORCHESTRATOR}}, modelo `deepseek-v4-pro`, e gera tanto o post do blog quanto notas de Zettelkasten.

## Lições 25/05/2026

1. **Sempre parar o PM2 antes de rebuildar** — `rm -rf public/` com servidor rodando causa `ENOTEMPTY`.
2. **TagPage gera poluição** — 436 tags de wikilinks. Remover o plugin resolve, mas é preciso rebuild limpo.
3. **baseUrl importa** — valor padrão quebra SPA e Explorer.
4. **O output do build manual vai para `public/public/`** — confirmar com `find` antes de testar.
5. **Python http.server não substitui Quartz serve** — não faz SPA routing.
