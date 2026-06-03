---
name: cli-tools-agent-setup
description: >-
  Instalação, configuração e mandato de uso dos 3 CLIs externos (Claude Code/Opus,
  Gemini, OpenCode) para agentes Hermes em ambos os ambientes (Mac e OVH). Inclui
  o Mandato dos 3 Motores ({{COMMANDER}}, 29/05/2026): código de implementação usa EXCLUSIVAMENTE
  Claude Opus, Gemini 3.1 Pro ou OpenCode GLM 5.1 — deepseek-v4-flash PROIBIDO.
  Cobre também a regra de honestidade de atribuição de modelo no frontmatter.
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# CLI Tools — Setup para Agentes Hermes

**Escopo:** Este skill cobre AMBOS os ambientes (OVH server + Mac local).
- Conteúdo original documenta o OVH.
- Seções com 📱 são específicas do ambiente Mac (M4).
- Agentes Mac ({{ORCHESTRATOR}}-mac) carregam este skill e precisam saber onde cada CLI vive.

## Gatilho
- {{COMMANDER}} instala um novo CLI no servidor (ex: Gemini CLI, OpenCode CLI)
- Precisa que os agentes Hermes ({{ORCHESTRATOR}}, {{BACKEND_ENGINEER}}, {{FRONTEND_ENGINEER}}, {{AUDITOR}}, {{DEVOPS_ENGINEER}}) possam usar o CLI
- O CLI está funcionando no terminal como `{{COMMANDER}}` mas falha quando chamado por um agente
- Um agente Mac precisa determinar se um CLI está disponível localmente ou apenas no OVH

## O Problema: $HOME Isolado dos Profiles

Cada agente Hermes roda com `$HOME` apontando para seu diretório de profile:

```
{{COMMANDER_HERMES_PATH}}/profiles/<agente>/home/
```

CLIs armazenam configuração e credenciais em `~/.<cli>/` — que resolve para o profile, **não** para `{{COMMANDER_HOME}}/`. Por isso um CLI logado no terminal do {{COMMANDER}} não é encontrado pelos agentes.

## Diagnóstico Rápido

```bash
# Verificar o HOME do contexto Hermes
echo $HOME
# → {{COMMANDER_HERMES_PATH}}/profiles/dalinar/home/

# Testar CLI com HOME correto (credenciais do {{COMMANDER}})
HOME={{COMMANDER_HOME}} gemini -p "teste"                    # Gemini
HOME={{COMMANDER_HOME}} {{COMMANDER_HOME}}/.opencode/bin/opencode   # OpenCode
```

## Duas Soluções

### Solução A — Variáveis de Ambiente (recomendada para chaves API)

Adicionar as variáveis no `.env` global (`{{COMMANDER_HERMES_PATH}}/.env`) ou no profile de cada agente:

```
GEMINI_API_KEY=AIza...
OPENCODE_API_KEY=...
```

**Vantagens:** Limpo, não depende de filesystem, funciona cross-profile.
**Desvantagens:** Nem todo CLI suporta env var para auth (ex: Gemini OAuth não usa API key).

### Solução B — Symlinks dos diretórios de config

Para CLIs que usam OAuth ou config em arquivos (Gemini, etc.):

```bash
# Lista completa de agentes (inclui lirin e pattern)
agents=(dalinar navani shallan jasnah kaladin lirin pattern)

for agent in "${agents[@]}"; do
    profile_home="{{COMMANDER_HERMES_PATH}}/profiles/$agent/home"
    
    # ⚠️ Se o profile já tiver diretórios próprios (criados em execuções anteriores),
    # fazer backup antes de substituir pelo symlink
    for d in .gemini .config/opencode .local/share/opencode; do
        [ -d "$profile_home/$d" ] && mv "$profile_home/$d" "$profile_home/${d}.bak" 2>/dev/null
    done
    
    # Gemini CLI
    mkdir -p "$profile_home"
    rm -rf "$profile_home/.gemini"  # remove resíduos se houver
    ln -sfn {{COMMANDER_HOME}}/.gemini "$profile_home/.gemini"
    
    # OpenCode CLI — requer 2 diretórios
    mkdir -p "$profile_home/.local/share"
    mkdir -p "$profile_home/.config"
    rm -rf "$profile_home/.local/share/opencode" "$profile_home/.config/opencode"
    ln -sfn {{COMMANDER_HOME}}/.local/share/opencode "$profile_home/.local/share/opencode"
    ln -sfn {{COMMANDER_HOME}}/.config/opencode "$profile_home/.config/opencode"
    
    echo "$agent: OK"
done
```

**Vantagens:** Funciona para qualquer CLI (OAuth, API key, config).
**Desvantagens:** Cada novo CLI precisa de symlink manual.

## CLIs Instalados no Servidor

### Gemini CLI (`gemini`)

| Atributo | Valor |
|----------|-------|
| Path | `/usr/bin/gemini` |
| Versão | 0.43.0 |
| Auth | OAuth (conta Google) — credenciais em `{{COMMANDER_HOME}}/.gemini/` |
| Modo non-interactive | `gemini -p "prompt"` (com `-m` para modelo) |
| Contexto para planejamento | `gemini --include-directories /tmp -m "modelo" -p "leia o arquivo X.md e..."` (NÃO existe `-f`) |
| Teste | `HOME={{COMMANDER_HOME}} gemini -p "responda apenas: OK"` |

### Modelos Disponíveis (Google One AI Advanced)

Testados e confirmados funcionais no CLI:

| Modelo | Status | Contexto | Uso |
|--------|--------|----------|-----|
| `gemini-3.1-pro-preview` | ✅ | **2.097.152 tokens (2M)** | **Planejamento pesado** |
| `gemini-3-flash-preview` | ✅ | ~2.000.000 tokens | Rápido/raspagem |
| `gemini-3.1-flash-lite-preview` | ✅ | — | Ligeiro |
| `gemini-2.5-pro` | ✅ | 1.048.576 tokens | Produção estável |
| `gemini-2.5-flash` | ✅ | 1.048.576 tokens | Produção rápido |
| `gemini-2.5-flash-lite` | ✅ | — | Leve máximo |
| `gemini-3.5-flash-preview` | ❌ (404) | — | Lançado pelo Google (27/05/2026) mas retorna 404 no CLI v0.43.0. Testar após upgrade do CLI |
| `gemini-3.1-flash-lite-preview` | ✅ | — | Preview leve, rápido — útil para tarefas simples |
| `gemini-3.1-pro-preview` | **USAR PARA PLANEJAMENTO PESADO** | **2.097.152 tokens (2M)** | Comando: `gemini -m "gemini-3.1-pro-preview" --include-directories /tmp -p "leia o arquivo X.md e..."` |
| `gemma-4-31b-it` | ❌ (erro) | — | Ainda não funcional |

⚠️ **gemini-3.5-flash-preview** — Google lançou recentemente mas retorna 404 no CLI versão 0.43.0. Tentar após atualização do Gemini CLI.

⚠️ **gemini-3.1-flash-preview** — Retorna 404 tanto no OVH (v0.43.0) quanto no Mac (v0.44.1). O nome correto do modelo flash mais recente disponível em ambos é `gemini-3-flash-preview`. Se o flash não funcionar, usar `gemini-3.1-pro-preview` como fallback.

### OpenCode CLI (`opencode`)

| Atributo | Valor |
|----------|-------|
| Path | `{{COMMANDER_HOME}}/.opencode/bin/opencode` |
| Versão | 1.15.11 |
| Auth | API key — credencial em `{{COMMANDER_HOME}}/.local/share/opencode/auth.json` |
| Provider | `zai-coding-plan` (z.ai / GLM-5.1) |
| Modelos | `glm-4.5-air`, `glm-4.7`, `glm-5-turbo`, `glm-5.1`, `glm-5v-turbo` |
| Modo non-interactive | `opencode run -m <provider/modelo> "prompt"` (saída TUI limitada) |
| Instalação | **NÃO** está no npm público. É o pacote `@opencode-ai/plugin` instalado em `~/.opencode/`. Ver abaixo. |
| Teste | `HOME={{COMMANDER_HOME}} opencode run -m zai-coding-plan/glm-4.5-air "teste"` |

**⚠️ Instalação:** O OpenCode CLI não está disponível no registro npm público como `@opencode-ai/cli`. O binário standalone (138 MB, Go) fica em `~/.opencode/bin/opencode`. Para instalar em um novo ambiente:

```bash
# Método 1: Copiar binário de outro servidor (mais confiável)
rsync -avz user@source:~/.opencode/bin/opencode ~/.opencode/bin/opencode

# Método 2: Instalar via npm no diretório ~/.opencode/
mkdir -p ~/.opencode && cd ~/.opencode
echo '{"dependencies": {"@opencode-ai/plugin": "1.15.11"}}' > package.json
npm install
# O binário em node_modules/.bin/opencode é um wrapper Node.js (~2 MB).
# O binário standalone (138 MB Go) é baixado na primeira execução.
```

**⚠️ Corrupção por transferência parcial:** Se o binário for transferido via SCP/rsync e a conexão cair, o arquivo fica incompleto (ex: 33 MB de 138 MB). Sintoma: `Bus error (core dumped)`. Verificar tamanho: `ls -lh ~/.opencode/bin/opencode` (deve ser ~138 MB).

⚠️ **OpenCode CLI é TUI-first. NÃO suporta batch não-interativo.** Descoberto 29/05/2026:

**`--format json` NÃO emite respostas textuais.** Em modo não-interativo (`opencode run`), o `--format json` emite APENAS o evento `step_start` no stdout. Os eventos `text` e `step_end` são processados internamente pelo bus de eventos e renderizados na TUI — NUNCA chegam ao stdout em modo batch. O comando sai com code 0 sem produzir a resposta.

**Comportamento confirmado com `--print-logs`:**
```
INFO  service=llm providerID=zai-coding-plan modelID=glm-5.1 ... stream
INFO  service=bus type=message.part.delta publishing       ← resposta aparece aqui
INFO  service=session.prompt ... exiting loop
{"type":"step_start",...}                                  ← ÚNICO output stdout
```

- **`--format json`**: emite APENAS `step_start` no stdout. Resposta textual NÃO vai para stdout.
- **`--format default`**: stdout completamente vazio em modo batch.
- **`-p/--prompt`**: abre TUI interativa, não retorna.
- **`--command <nome>`**: executa comandos/skills do OpenCode (ex: `init`, `review`, `caveman`). NÃO aceita prompt livre.
- **`--variant minimal|high|max`**: controla esforço de raciocínio do provider.
- Sessões são persistentes no banco SQLite: `opencode session list`, `opencode session delete`.

**:white_check_mark: Uso correto do OpenCode CLI para agentes:**

| Modo | Comando | Quando usar |
|------|---------|-------------|
| **TUI interativa** | `terminal(pty=true)` → `opencode run -m zai-coding-plan/glm-5.1` | Geração de código complexo com iteração |
| **Batch (NÃO suportado)** | — | Usar Claude Opus ou Gemini 3.1 Pro em vez disso |

**Para geração de código batch, usar SEMPRE Claude Opus (1ª opção) ou Gemini 3.1 Pro (2ª opção). OpenCode CLI apenas para sessões interativas com `terminal(pty=true)`.**

Ver `references/opencode-cli-batch-failure-evidence.md` para o diagnóstico completo com logs que comprovam que a resposta fica no bus interno.

### Estrutura de Providers no auth.json

O arquivo `~/.local/share/opencode/auth.json` contém as credenciais:

| Provider ID | Tipo | API Key | Uso |
|-------------|------|---------|-----|
| `zai` | api | `f4f72d1b...` | Z.AI — uso geral |
| `google` | api | `AIzaSy...` | Google (Gemini API) |
| `opencode-go` | api | `sk-Lqr...` | OpenCode Go — **exclusivo do motor Hermes (config.yaml)** |
| `zai-coding-plan` | api | `6490cee4...` | **Z.AI Coding Plan — usar com OpenCode CLI** |

**:x: `opencode-go` NUNCA usar para geração de código.** É o motor de conversa do Hermes (definido no `config.yaml` dos agentes).  
**:white_check_mark: `zai-coding-plan`** é o provider correto para o OpenCode CLI (`-m zai-coding-plan/glm-5.1`).

---

## Mapa Cross-Ambiente (Mac  OVH)

Agentes Mac ({{ORCHESTRATOR}}-mac, {{BACKEND_ENGINEER}}-mac, etc.) executam no **M4 Mac local**. Os CLIs disponíveis DIFEREM entre Mac e OVH.

| CLI | Mac (M4 local) | OVH (servidor) |
|-----|:--------------:|:--------------:|
| **Claude Code** (`claude`) | ✅ `~/.local/bin/claude` v2.1.118 | ❌ (não instalado) |
| **Gemini CLI** (`gemini`) | ✅ `/Users/{{COMMANDER}}fae/.local/share/mise/installs/node/24.13.1/bin/gemini` v0.44.1 (via mise) | ✅ `/usr/bin/gemini` v0.43.0 |
| **OpenCode CLI** (`opencode`) | ✅ `/Users/{{COMMANDER}}fae/.local/share/mise/installs/node/24.13.1/bin/opencode` v1.15.12 (via mise) | ✅ `{{COMMANDER_HOME}}/.opencode/bin/opencode` v1.15.11 |

### :warning: OpenCode CLI em migrações OVH

O binário standalone (138 MB ELF) **não** é instalável via npm. O pacote `@opencode-ai/plugin`
no npm gera apenas um wrapper JavaScript que depende de `node_modules` completos e
não funciona standalone.

**Transferência correta (servidor antigo → novo):**
```bash
# No servidor antigo
rsync -avz {{COMMANDER_HOME}}/.opencode/bin/opencode new-ovh:/tmp/opencode

# No servidor novo
sudo cp /tmp/opencode {{COMMANDER_HOME}}fae/.opencode/bin/opencode
sudo chown {{COMMANDER}}fae:{{COMMANDER}}fae {{COMMANDER_HOME}}fae/.opencode/bin/opencode
sudo chmod +x {{COMMANDER_HOME}}fae/.opencode/bin/opencode
```

### Como agentes Mac usam CLIs do OVH

1. **Delegar para {{ORCHESTRATOR}} OVH** (<@{{SLACK_ID_OVH_ORCHESTRATOR}}>) — contato direto autorizado por {{COMMANDER}}
   - Ex: `{{ORCHESTRATOR}} OVH, preciso rodar Gemini no OVH com contexto X — retorne o resultado`
2. **SSH direto para OVH** (quando autorizado por {{COMMANDER}})
   - `ssh {{COMMANDER}}@<ovh-host> 'HOME={{COMMANDER_HOME}} gemini -p "..."'`
3. **Cron job cross-ambiente** — agendar no Mac mas delegar execução no OVH

### 📱 Claude CLI (Mac local)

| Atributo | Valor |
|----------|-------|
| Path | `~/.local/bin/claude` |
| Versão | 2.1.118 (Claude Code) |
| Auth | Sessão do usuário local |
| Modelos | Opus (planejamento pesado), Sonnet (rápido) |
| Modo non-interactive | `claude -p "prompt" --print` (ou pipe via stdin) |
| Flags essenciais | `--dangerously-skip-permissions` (para bypassar prompts de confirmação em modo não-interativo), `--add-dir <path>` (adicionar diretórios ao contexto), `--effort <low|medium|high|xhigh|max>` (qualidade), `--max-budget-usd <valor>` (limite de gasto) |
| Teste | `~/.local/bin/claude --version` |

### 📱 Gemini CLI (Mac local)

| Atributo | Valor |
|----------|-------|
| Path | `/Users/{{COMMANDER}}fae/.local/share/mise/installs/node/24.13.1/bin/gemini` |
| Versão | 0.44.1 (v0.43.0 no OVH) |
| Auth | OAuth (conta Google) — credenciais via login interativo |
| Modo non-interactive | `GEMINI_CLI_TRUST_WORKSPACE=true /path/gemini -m "gemini-3.1-pro-preview" -p "prompt"` |
| Teste | `GEMINI_CLI_TRUST_WORKSPACE=true /path/gemini -p "responda apenas: OK"` |

**⚠️ Geminis flash no Mac:** `gemini-3.1-flash-preview` retorna **ModelNotFoundError (404)** tanto no Mac (v0.44.1) quanto no OVH (v0.43.0). Mesmo sintoma. Usar `gemini-3.1-pro-preview` como fallback. O modelo flash funcional mais recente nos dois ambientes é `gemini-3-flash-preview`.

### 📱 OpenCode CLI (Mac local)

| Atributo | Valor |
|----------|-------|
| Path | `/Users/{{COMMANDER}}fae/.local/share/mise/installs/node/24.13.1/bin/opencode` |
| Versão | 1.15.12 (1.15.11 no OVH) |
| Auth | API key z.ai — configurado via coding plan para glm-5.1 |
| Modo non-interactive | `opencode run "prompt"` (TUI-first, saída limitada) |
| Provider padrão | glm-5.1 (z.ai) |

**⚠️ OpenCode é TUI-first.** Para uso programático, preferir Gemini 3.1 Pro ou Claude Code. O `opencode run` inicia sessão interativa — não há equivalente ao `--print` do Claude/Gemini.

**⚠️ Pitfall crítico — `--dangerously-skip-permissions`:** Em modo `--print` (non-interactive), Claude Code SOLICITA PERMISSÃO para escrever arquivos. Sem `--dangerously-skip-permissions`, o processo trava esperando input e eventualmente expira. Sempre incluir esta flag quando o prompt requisitar criação/alteração de arquivos. Combinação padrão: `claude --add-dir <dir> -p "..." --print --dangerously-skip-permissions --effort max --max-budget-usd 3`.

**⚠️ Gemini no Mac — `GEMINI_CLI_TRUST_WORKSPACE`:** O Gemini CLI (instalado via mise, não via homebrew) roda em `/Users/{{COMMANDER}}fae/.local/share/mise/installs/node/24.13.1/bin/gemini`. Em modo não-interativo, exige `GEMINI_CLI_TRUST_WORKSPACE=true` para executar sem confirmação de diretório confiável. Sempre prefixar: `GEMINI_CLI_TRUST_WORKSPACE=true /path/gemini -m "gemini-3.1-pro-preview" -p "prompt"`.

**Padrão de processo background:** Para refinamentos longos (+2 min), usar terminal(background=true, notify_on_complete=true) com redirecionamento de saída:
```bash
# Claude Code em background com output para arquivo
claude --add-dir docs/ -p "leia X.md e refine..." \
  --print --dangerously-skip-permissions --effort max --max-budget-usd 3 \
  2>/dev/null > docs/X-REFINADO.md
```
O Hermes notifica quando o processo terminar.

**Pipeline alternativa (mais confiável):** Pipe do conteúdo via stdin + redirecionamento de stdout:
```bash
cat docs/ORIGINAL.md | claude -p "refine isto..." \
  --print --dangerously-skip-permissions --effort max --max-budget-usd 3 \
  2>/dev/null > docs/REFINADO.md
```
Isso evita problemas de `--add-dir` com paths relativos e é mais previsível para processos background.

**⚠️ ⚠️ Pitfall crítico: backticks em prompts `-p` com aspas duplas.** Se o prompt passado via `-p "..."` contém backticks (ex: ``` `python` ``` ou triplos backticks ````` ````` para code blocks), o bash interpreta os backticks como **command substitution**, tentando executar o conteúdo como comandos shell. Sintoma: erros como `bash: python: command not found` e `bash: from: command not found` aparecem no terminal.

**Correção:** Escrever o prompt completo em um arquivo `.md` e usar pipe:
```bash
# ✅ CORRETO: prompt em arquivo, pipe via stdin
cat prompt.md | claude --print --dangerously-skip-permissions --effort max --max-budget-usd 3 2>/dev/null > saida.md

# ❌ ERRADO: backticks no -p quebram o shell
claude -p "Use \`\`\`python\nclass Foo:\n    pass\n\`\`\`" --print  # shells de furar!
```

O pipe é seguro porque o conteúdo do arquivo é lido byte a byte sem interpretação shell.

**⚠️ Claude Code com `--dangerously-skip-permissions` escreve arquivos diretamente.** Quando o prompt contém instruções do tipo "produza um documento X", o Claude Code internamente decide salvar o arquivo no disco. Apenas um resumo ("Documento criado em `path/ARQUIVO.md`") vai para o stdout. A redireção `> saida.md` NÃO captura o conteúdo real do documento. **Para gerar no stdout:** incluir no prompt "Gere APENAS o conteúdo como texto markdown no stdout — não crie arquivos."

**⚠️ Pitfall: `--add-dir` não funciona com background + `--print`.** Quando se usa `--add-dir docs/` em modo `--print` e o processo roda em background, o Claude Code aguarda stdin por 3s e emite "no stdin data received in 3s" — depois falha (exit 1). Preferir SEMPRE o pipe via stdin para submissão de conteúdo ao Claude Code em background.

**⚠️ Pitfall: Gemini CLI + background mode = 0 bytes.** O Gemini CLI com redirecionamento de saída (`> arquivo`) quando executado via `terminal(background=true)` frequentemente produz arquivos vazios (0 bytes). **Solução:** Executar em foreground com `timeout=300` ou superior. O foreground retorna quando o comando termina — mesmo que leve 5 minutos, o Hermes espera com o timeout definido. Exemplo:
```bash
# ✅ CORRETO: foreground com timeout alto
terminal(command="gemini ... > saida.md", timeout=300)

# ❌ ERRADO: background produz arquivos vazios
terminal(command="gemini ... > saida.md", background=true, timeout=600)
```

**Pipeline de refinamento multi-modelo (documentos grandes):**
Para refinar planos de implementação e documentos extensos, usar dois modelos em paralelo:
1. **Claude Opus** (`claude --effort max`) — profundidade técnica, código detalhado, especificações de implementação. Melhor para Waves individuais com muito código.
2. **Gemini 3.1 Pro** (`GEMINI_CLI_TRUST_WORKSPACE=true gemini -m "gemini-3.1-pro-preview" -p "..."`) — coeficiente de contexto 2M tokens, visão arquitetural cross-Wave. Melhor para visão geral, coerência entre módulos, ADRs.
3. Quando Claude Opus bater no limite de tokens/rate (≈$3-5 de budget por ~50 min), alternar para Gemini 3.1 Pro para continuar o trabalho.

**Estratégia de execução:** Foreground é 3-5x mais confiável que background para refinamentos. Usar terminal(timeout=N) com N = 300-600 segundos. O Hermes retorna imediatamente se o comando terminar rápido, e espera até N segundos se for lento.

---

## Operações Longas (Background)

O Gemini CLI com prompts extensos (ex: gerar plano de implementação completo) pode levar vários minutos. Usar o padrão de background com notificação:

```bash
# Iniciar em background, salvar em arquivo
HOME={{COMMANDER_HOME}} gemini -m "gemini-3.1-pro-preview" \
  --include-directories /tmp \
  -p "prompt longo..." > /tmp/saida.md 2>/tmp/erro.log
```

O Hermes notifica automaticamente quando o processo terminar (`notify_on_complete=true`).

## ⚠️ OpenCode CLI — Limitação Crítica (TUI-Only)

**OpenCode CLI NÃO suporta batch não-interativo.** Diferente de Claude (`--print`) e Gemini (`-p`), o `opencode run` inicia uma sessão TUI interativa. Mesmo com `--format json`, apenas o evento `step_start` vai para stdout — a resposta do modelo fica presa na TUI.

| Modo | Claude Opus | Gemini 3.1 Pro | OpenCode CLI |
|------|:-----------:|:--------------:|:------------:|
| Batch (stdout) | ✅ `echo "prompt" \| claude --print` | ✅ `gemini -p "prompt"` | ❌ Impossível |
| Interativo (TUI) | ✅ `claude` | ✅ `gemini` | ✅ `terminal(pty=true)` → `opencode run` |

**Uso correto do OpenCode CLI:** apenas via `terminal(pty=true)` para sessões interativas. Para batch, usar Claude Opus (1ª opção) ou Gemini 3.1 Pro (2ª opção).

**Provider `opencode-go` NÃO é o CLI.** O `opencode-go` configurado no `config.yaml` dos agentes é o motor de conversa do Hermes — a API key é DIFERENTE da z.ai coding plan. O CLI do OpenCode usa a chave `zai-coding-plan` em `~/.local/share/opencode/auth.json`.

## ⚠️ Frontmatter Honesty — Modelo Real vs Declarado

**Pitfall crítico:** agentes podem escrever `model: Opus 4.7` no frontmatter mas o conteúdo foi processado pelo provider padrão (`deepseek-v4-flash`). O frontmatter deve refletir o modelo que REALMENTE processou o conteúdo.

**Verificação pós-entrega (obrigatória para {{ORCHESTRATOR}}):**
1. Confirmar arquivo existe em disco (`search_files` + `wc -c`)
2. Conferir o `model:` no frontmatter vs provider real do agente (`grep provider config.yaml`)
3. Cruzar com contador de tokens da sessão (se aplicável)
4. Para gaps críticos/altos: exigir comprovação do comando `terminal()` usado

| Agente | Provider real | Modelo real | Se declara Opus... |
|--------|:------------:|:-----------:|--------------------|
| {{ORCHESTRATOR}}-mac | opencode-go | deepseek-v4-pro | ✅ Provider equivalente |
| {{BACKEND_ENGINEER}}-mac | opencode-go | deepseek-v4-flash | ❌ Falso — precisa usar `~/.local/bin/claude` |
| {{AUDITOR}}-mac | opencode-go | deepseek-v4-flash | ⚠️ Usa `terminal()` → `claude` (OK se comprovado) |
| {{DEVOPS_ENGINEER}}-mac | opencode-go | deepseek-v4-flash | ❌ Falso — precisa usar `~/.local/bin/claude` |
| {{FRONTEND_ENGINEER}}-mac | opencode-go | deepseek-v4-flash | ❌ Falso — precisa usar `~/.local/bin/claude` |

**Regra para agentes:** se a instrução é "use Opus", NÃO basta escrever `model: Opus` no frontmatter. É obrigatório chamar `~/.local/bin/claude` via `terminal()`.

## Matriz de Decisão — Qual CLI Usar

| Tarefa | CLI Primário | CLI Secundário | Proibido |
|--------|:-----------:|:-------------:|:--------:|
| Código de produção | Claude Opus (`--print`) | Gemini 3.1 Pro (`-p`) | deepseek-v4-flash |
| Revisão arquitetural | Claude Opus (`--effort max`) | Gemini 3.1 Pro (2M ctx) | deepseek-v4-flash |
| Contexto massivo (>200K tokens) | Gemini 3.1 Pro (`-m "gemini-3.1-pro-preview"`) | — | — |
| Sessão interativa | Claude (`claude` TUI) | OpenCode CLI (`pty=true`) | — |
| Motor de conversa Hermes | opencode-go (config.yaml) | — | NUNCA usar para gerar código |

## Teste Rápido dos 3 CLIs

1. Verificar instalação:
   ```bash
   which gemini && gemini --version
   {{COMMANDER_HOME}}/.opencode/bin/opencode --version
   ```

2. Listar modelos disponíveis:
   ```bash
   HOME={{COMMANDER_HOME}} {{COMMANDER_HOME}}/.opencode/bin/opencode models
   ```

3. Testar chamada real com HOME correto:
   ```bash
   HOME={{COMMANDER_HOME}} gemini -p "responda apenas: OK"
   ```

4. Aplicar symlinks para profiles:
   ```bash
   # (comandos da Solução B acima)
   ```

5. Testar de dentro do contexto do agente:
   ```bash
   HOME={{COMMANDER_HERMES_PATH}}/profiles/dalinar/home gemini -p "responda apenas: OK"
   ```

## 📱 MANDATO DOS 3 MOTORES — {{COMMANDER}} (29/05/2026, reforçado 02/06/2026)

**Ordem direta de {{COMMANDER}}. Inquebrável.**

A partir de 29/05/2026, **toda geração de código de implementação** deve usar EXCLUSIVAMENTE estes 3 motores via `terminal()`:

| Motor | CLI (Mac M4) | Modelo | Modo Batch | Uso |
|-------|-------------|--------|:----------:|-----|
| **Claude Opus** | `~/.local/bin/claude` | Opus 4.7 | :white_check_mark: `--print` | Primário: gaps críticos/altos, arquitetura, código de produção |
| **Gemini 3.1 Pro** | `...mise/.../gemini` | `gemini-3.1-pro-preview` | :white_check_mark: `-p` | Secundário: contexto massivo (2M tokens), revisão cross-Wave |
| **OpenCode GLM 5.1** | `...mise/.../opencode` | `zai-coding-plan/glm-5.1` | :x: TUI-only | Terciário: sessões interativas via `terminal(pty=true)` |

### :red_circle: Gemini 3.1 Pro é o PADRÃO ABSOLUTO (02/06/2026)

Reforço de {{COMMANDER}} nesta data: **Gemini 3.1 Pro é o motor padrão para TODAS as tasks de código.** Opus é exclusivo {{FRONTEND_ENGINEER}} para DS. A ordem prática é:

1. **Gemini 3.1 Pro** — sempre, para tudo. Se falhar (RESOURCE_EXHAUSTED), dividir em subtarefas menores.
2. **Opus 4.7** — exclusivo {{FRONTEND_ENGINEER}} para tarefas de Design System com visão/design.
3. **DeepSeek V4 Pro** — NUNCA sem ordem explícita do {{COMMANDER}}.

### :red_circle: O motor no task_XX.md NÃO é autoridade (02/06/2026)

**Pitfall crítico:** Arquivos task_XX.md pré-escritos podem conter "Motor: DeepSeek V4 Pro" como resquício de planejamento anterior. Isso NÃO autoriza o uso. O motor é definido pela hierarquia acima.

**Verificação pré-delegação (obrigatória para {{ORCHESTRATOR}}):**
Antes de delegar qualquer task, SEMPRE verificar o motor no task_XX.md:
- Se for "DeepSeek" → sobrescrever para Gemini CLI e reportar a discrepância
- Se for "Opus 4.7" → confirmar que é {{FRONTEND_ENGINEER}} + DS
- Se houver dúvida → perguntar ao {{COMMANDER}}

**Caso real (02/06):** Task_16.md dizia "Motor: DeepSeek V4 Pro". {{ORCHESTRATOR}} delegou com DeepSeek. {{COMMANDER}}: *"a ordem é sempre gemini 3.1 pro como primeira opção, se ele não funcionar parar, reportar e aguardar nova ordem."*

### :x: PROIBIDO

**`deepseek-v4-flash` está PROIBIDO para geração de código de implementação.** Pode ser usado apenas para conversação/respostas no Slack.

**:warning: Evidência de auditoria (29/05/2026):** 17 gaps gerados com deepseek-v4-flash foram auditados com Claude Opus 4.7. Taxa de reprovação: **100%** — todos os 17 gaps continham issues (54 total: 11 críticos, 13 altos, 30 médios/baixos). Ver `references/deepseek-v4-flash-audit-failure-evidence.md` para o relatório completo.

### Teste de Prontidão — Comandos Canônicos

Cada agente deve conseguir executar estes 3 comandos via `terminal()` e obter `OK` como resposta:

```bash
# Teste 1 — Claude Opus
echo "responda apenas: OK" | ~/.local/bin/claude --print --dangerously-skip-permissions 2>/dev/null

# Teste 2 — Gemini 3.1 Pro
GEMINI_CLI_TRUST_WORKSPACE=true /Users/{{COMMANDER}}fae/.local/share/mise/installs/node/24.13.1/bin/gemini -m "gemini-3.1-pro-preview" -p "responda apenas: OK"

# Teste 3 — OpenCode GLM 5.1 (verifica inicialização, NÃO resposta textual)
# OpenCode CLI é TUI-only — este teste confirma que o CLI inicia, conecta ao provider e sai limpo
/Users/{{COMMANDER}}fae/.local/share/mise/installs/node/24.13.1/bin/opencode run -m zai-coding-plan/glm-5.1 "responda apenas: OK" --format json --variant minimal 2>/dev/null
# ✅ Sucesso = JSON com {"type":"step_start",...} e exit code 0
# ❌ Falha = sem output ou exit code ≠ 0
```

### Pipeline Padrão para Geração de Código

```bash
# 1. Escrever prompt em arquivo (evita quebra de shell com backticks)
cat > /tmp/prompt.md << 'EOF'
# Prompt detalhado aqui...
EOF

# 2. Invocar CLI via terminal() com pipe
cat /tmp/prompt.md | ~/.local/bin/claude \
  --print --dangerously-skip-permissions \
  --effort max --max-budget-usd 3 \
  2>/dev/null > resultado.md

# 3. Verificar saída
wc -c resultado.md  # Deve ser > 0
```

### :warning: O provider `opencode-go` NÃO é Opus

O `config.yaml` dos agentes define `provider: opencode-go` com `default: deepseek-v4-flash`. Este provider é usado apenas para **conversação no Slack**. Para gerar código de qualidade, SEMPRE usar `terminal()` com os 3 CLIs acima.

---

## ⚠️ REGRA CRÍTICA: Honestidade de Atribuição de Modelo (Model Attribution Honesty)

**Estabelecido 29/05/2026 após incidente sistêmico com a equipe M4.**

### O Problema

Agentes recebem instrução para "usar Opus 4.7" e escrevem `model: Opus 4.7` no frontmatter dos artefatos — mas seu **provider real** no `config.yaml` é `deepseek-v4-flash`. O conteúdo NÃO passou pelo Opus, mas o frontmatter mente.

### Causa Raiz

- O `config.yaml` do agente define `model.default` e `model.provider` — este é o modelo que **realmente processa** as respostas
- A instrução recebida ("use Opus") NÃO altera o provider do agente
- O agente escreve no frontmatter o modelo **instruído**, não o modelo **real**

### Regra (Inquebrável)

**O campo `model:` no frontmatter DEVE SEMPRE refletir o modelo que REALMENTE processou o conteúdo.**

```yaml
# ❌ ERRADO — instrução diz "use Opus" mas provider real é deepseek-v4-flash
model: Opus 4.7

# ✅ CORRETO — reporta o modelo real do config.yaml
model: deepseek-v4-flash (provider: opencode-go)
```

### Como saber qual modelo você realmente está usando

1. Verifique seu `config.yaml`:
   ```bash
   grep -A3 "^model:" ~/.hermes/profiles/$(whoami | sed 's/hermes-//')/config.yaml
   ```
2. O valor de `model.default` é o modelo REAL que processa suas respostas
3. Se você não tem `model.default` definido, o sistema usa o default do provider

### Como REALMENTE usar Opus

Para gerar conteúdo com Opus, o agente deve usar `terminal()` para invocar o Claude CLI:
```bash
cat prompt.md | ~/.local/bin/claude \
  --print --dangerously-skip-permissions \
  --effort max --max-budget-usd 3 \
  2>/dev/null > resultado.md
```

O conteúdo desse arquivo `resultado.md` FOI processado pelo Opus — e pode ser atribuído como tal.

### Checklist de Atribuição

Antes de escrever `model:` no frontmatter:
1. [ ] Este conteúdo veio do meu provider padrão? → `model: <model.default do config.yaml>`
2. [ ] Este conteúdo veio do Claude CLI via `terminal()`? → `model: Opus 4.7 (Claude CLI)`
3. [ ] Este conteúdo veio do Gemini CLI via `terminal()`? → `model: Gemini 3.1 Pro (CLI)`
4. [ ] Este conteúdo veio de outro modelo? → especificar qual e como

### Consequência da Violação

{{COMMANDER}} perde confiança em TODOS os artefatos da equipe. Revisão sistêmica é necessária. Trabalho precisa ser refeito. Ocorreu em 29/05/2026: {{DEVOPS_ENGINEER}}-mac escreveu `model: Opus 4.7` em 12 artefatos, mas todos foram processados por `deepseek-v4-flash`. Todos precisarão ser reauditados.

---

### Instalação do OpenCode CLI

**:red_circle: PITFALL: O pacote npm `@opencode-ai/plugin` NÃO é o CLI.** O pacote npm contém apenas a SDK Node.js, não o binário standalone do OpenCode CLI. O CLI é um binário Go/Bun standalone (~145 MB) que deve ser transferido como arquivo binário.

```bash
# ❌ ERRADO — npm install NÃO produz o binário CLI funcional
npm install @opencode-ai/plugin
# Isso instala a SDK Node.js, não o CLI

# ✅ CORRETO — transferir o binário standalone do servidor de origem
rsync -avz {{COMMANDER_HOME}}/.opencode/bin/opencode <destino>:{{COMMANDER_HOME}}fae/.opencode/bin/opencode
chmod +x {{COMMANDER_HOME}}fae/.opencode/bin/opencode
# O binário tem ~145 MB e é um ELF 64-bit (Go/Bun)
```

**Verificação pós-instalação:**
```bash
file {{COMMANDER_HOME}}fae/.opencode/bin/opencode
# Deve mostrar: ELF 64-bit LSB executable, x86-64
# Se mostrar menos de 10 MB ou for um script Node.js, está errado

{{COMMANDER_HOME}}fae/.opencode/bin/opencode --version
# Deve retornar: Bun v1.x.x (Linux x64 baseline)
```

**Transferência em migração:** Ver skill `ovh-server-migration` para o procedimento de transferência OVH→OVH (evita timeout de SCP do Mac).

## Pitfalls

1. **$HOME diferente no Hermes.** Sempre testar com `HOME={{COMMANDER_HOME}}` antes de concluir que o CLI está quebrado.
2. **CLI instalado local (npm global user).** `which` pode não encontrar. Verificar em `~/.npm-global/bin/` ou `~/.opencode/bin/`.
3. **OpenCode CLI NÃO suporta batch.** `opencode run` com `--format json` emite APENAS `step_start` no stdout — a resposta textual NUNCA chega ao stdout (fica na TUI). Para batch scriptado, use Claude Opus ou Gemini 3.1 Pro. OpenCode CLI é exclusivamente interativo via `terminal(pty=true)`.
4. **npm install @opencode-ai/plugin NÃO instala o CLI.** O pacote npm é apenas a SDK. O CLI é um binário Go standalone de ~145 MB. Transferir via rsync, não via npm.
5. **Binário truncado por SCP interrompido.** Se `file <binario>` mostrar "missing section headers", o arquivo está corrompido. Verificar tamanho: deve ser ~145 MB. Re-transferir.
6. **Gemini CLI NÃO tem flag `-f` para arquivos.** Use `--include-directories /caminho` para adicionar diretórios ao workspace, depois refira o arquivo pelo nome (não pelo path completo) no prompt. Ex: `gemini --include-directories /tmp -m "gemini-3.1-pro-preview" -p "leia o arquivo X.md e responda"`. O Gemini CLI encontra o arquivo pelo nome dentro dos diretórios incluídos.
7. **Gemini CLI requer OAuth para login interativo.** Se o OAuth expirar, {{COMMANDER}} precisa reautenticar com `gemini` no terminal. Alternativa: configurar `GEMINI_API_KEY`.
8. **Symlinks precisam ser recriados se o profile for resetado.** Incluir no onboarding de novos agentes.
9. **Token masking do Hermes.** `cat` de arquivos de credencial mostra `***`. Usar `xxd` ou `stat -c '%s'` para verificar se o token real está presente.
