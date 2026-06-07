# 00 — Hermes Agent: Fundamentos e Primeira Execução

> **Propósito deste documento:** Apresentar o Hermes Agent, seus conceitos fundamentais,
> guias de instalação no macOS e Ubuntu, configuração do provedor OpenCode Go (DeepSeek),
> criação do primeiro perfil de agente, e execução inicial — tudo em português claro e didático.

---

## Sumário

1. [O que é o Hermes Agent?](#seção-1-o-que-é-o-hermes-agent)
2. [Instalação no macOS](#seção-2-instalação-no-macos)
3. [Instalação no Ubuntu](#seção-3-instalação-no-ubuntu)
4. [Configuração do Provedor OpenCode Go (DeepSeek)](#seção-4-configuração-do-provedor-opencode-go-deepseek)
5. [Criando o Primeiro Perfil de Agente](#seção-5-criando-o-primeiro-perfil-de-agente)
6. [Primeira Execução](#seção-6-primeira-execução)

---

## Seção 1: O que é o Hermes Agent?

O **Hermes Agent** é um **framework de agentes de IA autônomos** que operam diretamente
no terminal. Diferente de um chatbot comum (que apenas responde perguntas em uma janela
de chat), um agente Hermes **executa ações reais**: ele lê e escreve arquivos, roda
comandos no shell, navega na web, gerencia repositórios Git, e até se comunica pelo Slack.

### Arquitetura em 3 Pilares

| Conceito | O que é | Exemplo |
|----------|---------|---------|
| **Perfis independentes** | Cada agente é uma pasta com identidade, personalidade e configuração própria | `~/.hermes/profiles/devops/`, `~/.hermes/profiles/escritor/` |
| **Gateway** | Modo servidor que expõe o agente via API/Slack | `hermes --profile devops gateway run` |
| **Skills** | Módulos de memória procedural — conhecimento sobre como fazer algo | Skill de Git, skill de Docker, skill de deploy |

### O que torna um Hermes Agent diferente de um chatbot?

| Característica | Chatbot (ChatGPT, Claude Web) | Hermes Agent |
|----------------|-------------------------------|--------------|
| **Memória** | Efêmera (morre com a sessão) | **Permanente** — arquivos, logs, contexto salvo em disco |
| **Ferramentas** | Nenhuma (só texto) | **Terminal, sistema de arquivos, browser, Git, Slack** |
| **Autonomia** | Nenhuma (você copia/cola tudo) | **Executa comandos, escreve código, faz deploy sozinho** |
| **Identidade** | Genérica | **Personalidade configurável via system_prompt + SOUL.md** |
| **Offline/Fim** | Morre quando você fecha o navegador | **Continua existindo — você reativa o perfil** |

### Provedores de IA Suportados

Hermes Agent é **agnóstico de provedor**. Você pode usar:

- **OpenAI** — GPT-4o, GPT-4o-mini, o-series
- **Anthropic** — Claude 3.5 Sonnet, Claude 3 Opus
- **OpenCode Go** — DeepSeek V4 Flash e V4 Pro (gateway)
- **Google** — Gemini 1.5 Pro, Gemini 2.0 Flash

---

## Seção 2: Instalação no macOS

### Pré-requisitos

| Requisito | Versão Mínima | Como verificar |
|-----------|---------------|----------------|
| **Python** | 3.11+ | `python3 --version` |
| **Homebrew** | Qualquer | `brew --version` |
| **Git** | 2.x | `git --version` |
| **Bash** | 4+ | `bash --version` |

> ⚠️ **Bash 4+ é obrigatório no macOS.** O macOS vem com Bash 3.2 por padrão
> (muito antigo). Instale a versão moderna:
>
> ```bash
> brew install bash
> # Verifique a localização do novo bash:
> which bash            # Deve mostrar /opt/homebrew/bin/bash
> ```

### Método 1: Instalação via pip (recomendado)

```bash
pip install hermes-agent
```

Após a instalação, verifique:

```bash
hermes --version
```

Se o comando não for encontrado, seu `PATH` provavelmente não inclui
`~/.local/bin`. Corrija com:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
hermes --version
```

### Método 2: Instalação via Homebrew

```bash
brew install nousresearch/tap/hermes
```

Verifique:

```bash
hermes --version
```

### Timezone — Configuração Obrigatória

Hermes Agent **exige** que o fuso horário esteja configurado no sistema e no perfil.
No macOS:

```bash
# Verificar timezone atual
sudo systemsetup -gettimezone

# Se precisar alterar (exemplo: America/Sao_Paulo)
sudo systemsetup -settimezone America/Sao_Paulo
```

Ou via `timedatectl` (se disponível no macOS via brew):

```bash
brew install coreutils
timedatectl list-timezones | grep -i sao
```

### Solução de Problemas Comuns no macOS

#### 1. `hermes: command not found`
**Causa:** `~/.local/bin` não está no PATH.
**Solução:** Adicione ao `~/.zshrc` conforme mostrado acima.

#### 2. Erro de permissão: `Permission denied` ao instalar pacotes pip
**Causa:** Python instalado via Homebrew e permissões do diretório site-packages.
**Solução:**
```bash
# Use um virtualenv ou instale com --user
pip install --user hermes-agent
```

#### 3. Sandboxd bloqueando execução
**Causa:** macOS Sandbox ou TCC (Transparency, Consent, and Control) bloqueando
o acesso a arquivos/pastas.
**Solução:**
- Vá em **Preferências do Sistema → Privacidade e Segurança → Arquivos e Pastas**
- Permita que o Terminal (ou iTerm2) tenha acesso à pasta onde o Hermes opera
- Alternativamente: use o Finder para arrastar a pasta `~/.hermes` para o Terminal
  quando o prompt de permissão aparecer

#### 4. `bash: line 0: printf: `: invalid format character`
**Causa:** Bash 3.2 do macOS é incompatível com Hermes.
**Solução:** Instale Bash 4+ via Homebrew e configure o Hermes para usá-lo:

```bash
brew install bash
# No arquivo de perfil do agente (explicado na Seção 5), configure:
# terminal:
#   bash_path: /opt/homebrew/bin/bash
```

#### 5. Erro `dyld: Library not loaded` relacionado a Python
**Causa:** Python foi atualizado e as bibliotecas nativas perderam a referência.
**Solução:**
```bash
brew reinstall python@3.11
pip install --force-reinstall hermes-agent
```

---

## Seção 3: Instalação no Ubuntu

### Pré-requisitos

```bash
# Python 3.11+
sudo apt update
sudo apt install -y python3 python3-pip python3-venv git build-essential

# Dependências de sistema necessárias para compilação de pacotes nativos
sudo apt install -y python3-dev libffi-dev libssl-dev

# Verificar instalação
python3 --version
pip3 --version
git --version
```

### Instalação via pip

```bash
pip3 install hermes-agent
```

Verifique:

```bash
hermes --version
```

Se não encontrar, ajuste o PATH:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
hermes --version
```

### Timezone — Configuração Obrigatória

```bash
# Verificar timezone atual
timedatectl

# Listar timezones disponíveis
timedatectl list-timezones | grep -i sao

# Configurar (exemplo)
sudo timedatectl set-timezone America/Sao_Paulo

# Confirmar
timedatectl
```

### Solução de Problemas Comuns no Ubuntu

#### 1. `externally-managed-environment` error ao usar pip
**Causa:** Ubuntu 23.04+ bloqueia pip fora de virtualenv.
**Solução:**
```bash
# Opção A — Use um virtualenv
python3 -m venv ~/hermes-env
source ~/hermes-env/bin/activate
pip install hermes-agent

# Opção B — Force a instalação (não recomendado)
pip install --break-system-packages hermes-agent
```

#### 2. Erro de compilação: `fatal error: Python.h: No such file or directory`
**Causa:** Falta o pacote `python3-dev`.
**Solução:**
```bash
sudo apt install python3-dev
pip install --force-reinstall hermes-agent
```

#### 3. `ModuleNotFoundError: No module named '_cffi_backend'`
**Causa:** Falta `libffi-dev`.
**Solução:**
```bash
sudo apt install libffi-dev
pip install --force-reinstall hermes-agent
```

---

## Seção 4: Configuração do Provedor OpenCode Go (DeepSeek)

### O que é OpenCode Go?

**OpenCode Go** é um gateway de API que dá acesso aos modelos **DeepSeek** —
modelos de linguagem chineses de alta qualidade, conhecidos por excelente
custo-benefício. Ele funciona como um proxy: você paga por uso diretamente
no OpenCode, sem precisar de conta na DeepSeek.

### DeepSeek V4 Flash vs V4 Pro

| Característica | DeepSeek V4 Flash | DeepSeek V4 Pro |
|----------------|-------------------|-----------------|
| **Velocidade** | ⚡ Muito rápido | 🐢 Mais lento (raciocínio mais profundo) |
| **Custo** | 💰 Barato (ideal para uso diário) | 💵 Moderado |
| **Melhor para** | Código simples, leitura de arquivos, tarefas rotineiras, prototipação | Debug complexo, auditoria, refatoração, análise profunda |
| **Contexto** | 128K tokens | 128K tokens |
| **Indicado quando** | Você quer resposta rápida sem pensar muito | O problema é cabeludo e precisa de análise |

**Regra prática:** Comece sempre com **Flash**. Se o agente estiver errando
ou não conseguir resolver, troque para **Pro**.

### Obtendo a API Key

1. Acesse [opencode.ai](https://opencode.ai)
2. Crie uma conta (ou faça login)
3. Vá em **API Keys** no menu do usuário
4. Clique em **Create New Key**
5. Dê um nome (ex.: "hermes-agent")
6. Copie a chave gerada — ela começa com `oc_...`

### Configurando a Variável de Ambiente

```bash
# Adicione ao seu ~/.zshrc (macOS) ou ~/.bashrc (Linux)
echo 'export OPENCODE_GO_API_KEY="oc_sua_chave_aqui"' >> ~/.zshrc
source ~/.zshrc

# Teste se a variável está acessível
echo $OPENCODE_GO_API_KEY
```

### Testando a Conexão

```bash
hermes run --model deepseek-v4-flash --prompt "Responda apenas 'OK' se ouvir minha voz."
```

Se tudo estiver configurado corretamente, o Hermes responderá com "OK" ou
uma frase similar. Se aparecer um erro de API key, verifique se a variável
de ambiente está correta.

> 💡 **Dica:** Você também pode definir a API Key dentro do arquivo `.env`
> do perfil do agente (explicado na Seção 5), o que é mais seguro e permite
> usar chaves diferentes para cada agente.

---

## Seção 5: Criando o Primeiro Perfil de Agente

### Estrutura de Diretórios

Cada agente Hermes vive dentro de `~/.hermes/profiles/`. Crie a estrutura
completa para seu primeiro agente:

```bash
# Crie a pasta do perfil
mkdir -p ~/.hermes/profiles/meu-primeiro-agente

# Crie as pastas de suporte
mkdir -p ~/.hermes/profiles/meu-primeiro-agente/logs
mkdir -p ~/.hermes/profiles/meu-primeiro-agente/sessions
```

### Arquivo `config.yaml`

Este é o coração do perfil. Cada campo tem um propósito específico.

```yaml
# ~/.hermes/profiles/meu-primeiro-agente/config.yaml

model: deepseek-v4-flash
provider: opencode-go
base_url: https://api.opencode.ai/v1
api_mode: chat

# === Ferramentas que o agente pode usar ===
toolsets:
  - terminal    # Executar comandos no shell
  - filesystem  # Ler, escrever, editar arquivos
  - git         # Operações Git
  - browser     # Navegação web (se necessário)

# === Terminal ===
terminal:
  bash_path: /bin/bash           # macOS: /opt/homebrew/bin/bash
  working_directory: /home/seu-user/seu-projeto   # Diretório padrão
  allowed_commands: []           # [] = todos permitidos (recomendado)
  blocked_commands: []           # Comandos bloqueados (ex: rm -rf /)

# === Sistema de Arquivos ===
filesystem:
  allowed_directories:
    - /home/seu-user/seu-projeto
    - /home/seu-user/Documents
  blocked_patterns:              # Arquivos que o agente NÃO pode ler
    - "*.key"
    - "*.pem"
    - ".env"

# === Git ===
git:
  enabled: true
  allowed_repositories:
    - /home/seu-user/seu-projeto

# === Navegador (opcional) ===
browser:
  enabled: false                 # Ative apenas se precisar

# === Slack Gateway (opcional) ===
slack:
  enabled: false

# === Timezone (OBRIGATÓRIO) ===
timezone: America/Sao_Paulo
```

#### ⚠️ Por que `timezone` é obrigatório?

O Hermes Agent usa o timezone para:
- Carimbar logs e mensagens com data/hora correta
- Calcular deadlines e timers
- Organizar sessões e memórias cronológicas
- Garantir consistência entre o sistema e o agente

**Sem timezone configurado, o agente pode se recusar a iniciar ou operar
com timestamps errados.**

### Arquivo `.env`

As chaves de API ficam aqui, **fora do arquivo de configuração** (nunca
commite `.env` no Git se um dia versionar seu perfil):

```bash
# ~/.hermes/profiles/meu-primeiro-agente/.env

OPENCODE_GO_API_KEY=oc_sua_chave_aqui
```

### Arquivos de Identidade e Personalidade

Cada perfil pode (e deve) conter arquivos que definem **quem** o agente é.
Isso é o que transforma um LLM genérico em um **assistente com caráter**.

#### `AGENTS.md` — Quem são os membros da equipe

```markdown
# AGENTS.md — Equipe do Projeto

## Eu (meu-primeiro-agente)
- Nome: Assistente Dev
- Função: Agente principal de desenvolvimento
- Responsabilidades: codificação, revisão, deploy

## Humanos
- Nome do usuário principal (você define)
```

#### `SOUL.md` — A alma e valores do agente

```markdown
# SOUL.md — Alma do Assistente Dev

## Propósito
Ajudar o time de desenvolvimento com código, automação e documentação.

## Valores
1. **Clareza** — Explicações didáticas e completas
2. **Eficiência** — Resolver o problema sem rodeios
3. **Honestidade** — Assumir quando não sabe algo
4. **Segurança** — Nunca executar comandos destrutivos sem confirmação
```

#### `IDENTITY.md` — Personalidade e estilo

```markdown
# IDENTITY.md — Identidade do Assistente Dev

- Tom: profissional mas amigável
- Idioma principal: português brasileiro
- Estilo de código: Python moderno com type hints
- Preferências: testes antes de implementar, documentação junto com código
- Fraquezas: não tem acesso a dados externos além do que você prover
```

#### `TEAM.md` — Dinâmica de equipe

```markdown
# TEAM.md — Dinâmica do Time

- Eu (assistente) executo tarefas sob demanda
- O humano (usuário) revisa antes de deploy em produção
- Feedbacks são registrados nos logs para aprendizado contínuo
```

### Injetando o Protocolo Diário no `system_prompt`

O **Protocolo Diário** é uma prática que dá ao agente uma estrutura de
pensamento e ação. Injete-o no `system_prompt` do `config.yaml`:

```yaml
# Adicione esta seção ao config.yaml
agent:
  system_prompt: |
    Você é um assistente de desenvolvimento autônomo.
    
    ## PROTOCOLO DIÁRIO
    1. Ao iniciar, leia seu SOUL.md e IDENTITY.md para relembrar quem você é.
    2. Antes de cada ação, pense: "Isso está alinhado com meu propósito?"
    3. Para comandos destrutivos (rm, drop, delete), PEÇA CONFIRMAÇÃO.
    4. Sempre explique o que vai fazer ANTES de executar.
    5. Ao final, resuma o que foi feito e quais foram os resultados.
    6. Se encontrar um erro, registre-o e tente uma abordagem alternativa.
    
    ## DIRETRIZES
    - Prefira comandos seguros e reversíveis.
    - Use Git com frequência para versionar mudanças.
    - Quando em dúvida, pergunte ao humano.
```

> 💡 **Dica importante:** O número de linhas do `system_prompt` impacta
> diretamente o custo (cada chamada envia o prompt inteiro). Seja conciso
> mas completo. Mantenha detalhes longos em `SOUL.md` e referencie-o no
> prompt em vez de copiar tudo.

### Estrutura Final do Perfil

```
~/.hermes/profiles/meu-primeiro-agente/
├── config.yaml         # Configurações do agente
├── .env                # API keys (NUNCA versionar)
├── AGENTS.md           # Quem são os agentes/humanos
├── SOUL.md             # Propósito e valores
├── IDENTITY.md         # Personalidade e estilo
├── TEAM.md             # Dinâmica de equipe
├── logs/               # Logs de execução (criado automaticamente)
└── sessions/           # Sessões salvas (criado automaticamente)
```

---

## Seção 6: Primeira Execução

### Modo CLI (Comando Único)

O modo mais simples: você passa um comando diretamente e o agente executa
e responde:

```bash
hermes --profile meu-primeiro-agente run --prompt "Liste os arquivos na pasta atual, me mostre o conteúdo do config.yaml e me diga qual é a data de hoje."
```

O agente vai:
1. Ler o `config.yaml` para entender seu perfil
2. Ler `SOUL.md`, `IDENTITY.md` etc. para saber quem ele é
3. Executar `ls` no terminal
4. Ler o `config.yaml` com o filesystem
5. Descobrir a data atual
6. Responder com tudo organizado

### Modo Gateway (Slack / API)

Para deixar o agente **sempre disponível** (como um bot no Slack):

```bash
hermes --profile meu-primeiro-agente gateway run
```

Isso inicia um servidor que escuta mensagens do Slack (ou de uma API REST)
e responde autonomamente. Consulte a documentação oficial para configurar
o bot do Slack.

### Testando com Comandos no Terminal

Experimente estes prompts para ver o agente em ação:

```bash
# Teste 1: Execução de comando
hermes --profile meu-primeiro-agente run --prompt "Crie um arquivo chamado ola-mundo.txt com o conteúdo 'Olá, Hermes Agent!'"

# Teste 2: Leitura de arquivo
hermes --profile meu-primeiro-agente run --prompt "Leia o arquivo ola-mundo.txt que acabamos de criar"

# Teste 3: Sistema e informações
hermes --profile meu-primeiro-agente run --prompt "Me diga qual sistema operacional estamos rodando, quanta memória RAM livre temos, e quanto espaço em disco está disponível"

# Teste 4: Operação Git
cd /caminho/do/seu/repositorio
hermes --profile meu-primeiro-agente run --prompt "Mostre o status do Git, os últimos 3 commits, e me diga se há branches não mesclados"
```

### Verificando Logs

Toda interação do agente fica registrada. Isso é útil para debug, auditoria
e para o próprio agente aprender com execuções passadas:

```bash
# Listar os logs disponíveis
ls ~/.hermes/profiles/meu-primeiro-agente/logs/

# Ver o log mais recente
cat ~/.hermes/profiles/meu-primeiro-agente/logs/$(ls -t ~/.hermes/profiles/meu-primeiro-agente/logs/ | head -1)
```

Os logs contêm:
- Timestamp de cada ação
- Comando executado e sua saída
- Arquivos lidos/escritos
- Decisões do agente
- Erros encontrados

---

## Template do config.yaml

### ⚠️ Atenção: O Hermes NÃO cria a pasta do perfil automaticamente

Você precisa criar a estrutura manualmente:

```bash
mkdir -p ~/.hermes/profiles/meu-agente/
```

### Template Completo

Copie e cole este conteúdo no arquivo `~/.hermes/profiles/meu-agente/config.yaml`:

```yaml
# =============================================================================
# ~/.hermes/profiles/meu-agente/config.yaml
# =============================================================================

# --- MODELO (QUAL IA USAR) ---
model:
  default: deepseek-v4-flash
  provider: opencode-go
  base_url: https://opencode.ai/zen/go/v1
  api_mode: chat_completions

# Provedores adicionais (opcional)
providers: {}

# Fallback: se o modelo principal falhar, tenta este
fallback_providers:
  - provider: opencode-go
    model: deepseek-v4-pro

# --- FERRAMENTAS LIBERADAS ---
toolsets:
  - terminal    # Executar comandos no shell
  - file        # Ler, escrever, editar arquivos
  - web         # Acessar URLs e fazer requisições
  - browser     # Navegação web assistida
  - search      # Busca em arquivos e código
  - memory      # Memória de longo prazo
  - cronjob     # Agendar tarefas recorrentes

# --- CONFIGURAÇÕES DO AGENTE ---
agent:
  max_turns: 90              # Máximo de ações por sessão
  gateway_timeout: 1800      # Timeout do gateway em segundos (30 min)
  system_prompt: "Você é meu-agente. Aqui você define a personalidade."

# --- TERMINAL ---
terminal:
  backend: local
  cwd: .                     # Diretório de trabalho padrão
  timeout: 180               # Timeout por comando (3 min)

# --- TIMEZONE (OBRIGATÓRIO!) ---
# MUDE PARA SEU FUSO! Exemplos:
#   America/Sao_Paulo    (BR)
#   America/Campo_Grande (MS/MT)
#   America/New_York     (NY)
#   Europe/Lisbon        (PT)
timezone: America/Campo_Grande

# --- SLACK GATEWAY (opcional) ---
slack:
  bot_user_id: U0XXXXXXX         # ID do bot no Slack
  bot_user_name: meu-agente      # Nome de usuário do bot
  home_channel: C0XXXXXXX        # Canal principal do bot
  require_mention: true          # Só responde se for mencionado
```

### Explicação de Cada Seção

| Seção | Para que serve |
|-------|---------------|
| **model** | Define qual inteligência artificial o agente vai usar. `default` é o modelo principal; `provider` é o gateway que serve o modelo; `base_url` é o endpoint da API; `api_mode` define o formato da chamada (`chat_completions` para LLMs conversacionais). |
| **fallback_providers** | Se o modelo principal estiver fora do ar ou falhar, o Hermes tenta automaticamente este modelo secundário. |
| **toolsets** | As ferramentas que o agente pode usar. Cada uma dá um poder diferente: `terminal` para rodar comandos, `file` para manipular arquivos, `web` para acessar URLs, `browser` para navegação interativa, `search` para buscar em arquivos, `memory` para lembrar de conversas passadas, `cronjob` para agendar tarefas. |
| **agent** | Limites de execução. `max_turns` impede loops infinitos; `gateway_timeout`控制 quanto tempo o gateway espera antes de desistir; `system_prompt` é a instrução raiz que define a personalidade do agente. |
| **terminal** | Configuração do shell. `backend: local` usa o terminal da sua máquina; `cwd` é o diretório onde comandos são executados; `timeout` evita que comandos travem para sempre. |
| **timezone** | **Obrigatório.** O Hermes usa o fuso para timestamps em logs, sessões e mensagens no Slack. Se estiver errado, tudo fica com hora errada. |
| **slack** | Configuração do bot do Slack. Necessário apenas se você quiser conversar com o agente pelo Slack. |

---

## Setup via Terminal (Mais Simples)

### Por que configurar pelo terminal é mais fácil?

Configurar pelo terminal é **MUITO mais fácil** do que editar YAML manualmente. Você não precisa:
- Lembrar a sintaxe exata do YAML (indentação, hífens, dois-pontos)
- Saber onde cada campo fica no arquivo
- Preocupar com erros de digitação que quebram o parsing

Os comandos do Hermes são **auto-documentados**: você vê imediatamente o que cada configuração faz.

### Comandos Básicos

```bash
# 1. CRIAR O PERFIL
# -----------------
# Comando oficial (recomendado):
hermes --profile meu-agente init

# OU manualmente (se preferir):
mkdir -p ~/.hermes/profiles/meu-agente/


# 2. CONFIGURAR O MODELO VIA TERMINAL
# ------------------------------------
hermes --profile meu-agente config set model.default deepseek-v4-flash
hermes --profile meu-agente config set model.provider opencode-go
hermes --profile meu-agente config set model.base_url https://opencode.ai/zen/go/v1


# 3. CONFIGURAR TIMEZONE (mais fácil que achar no YAML!)
# ------------------------------------------------------
hermes --profile meu-agente config set timezone America/Campo_Grande


# 4. VER A CONFIGURAÇÃO COMPLETA
# ------------------------------
hermes --profile meu-agente config show


# 5. ADICIONAR CHAVES DE API NO .env
# -----------------------------------
# Chave do OpenCode (OBRIGATÓRIA para usar DeepSeek)
echo 'OPENCODE_GO_API_KEY=sk-...' >> ~/.hermes/profiles/meu-agente/.env

# Chaves do Slack (se for usar o bot no Slack)
echo 'SLACK_BOT_TOKEN=xoxb-...' >> ~/.hermes/profiles/meu-agente/.env
echo 'SLACK_APP_TOKEN=xapp-...' >> ~/.hermes/profiles/meu-agente/.env


# 6. TESTAR O AGENTE
# ------------------
hermes --profile meu-agente run --prompt "Ola, quem e voce?"
```

### Vantagens do Terminal

- ✅ **Não precisa saber YAML** — comandos de terminal são intuitivos
- ✅ **Auto-completa** — o Hermes sugere opções se você errar
- ✅ **Feedback imediato** — erros aparecem na hora, sem mistério
- ✅ **Mudanças são instantâneas** — não precisa reiniciar nada
- ✅ **Histórico** — seu terminal guarda os comandos, você pode repetir depois

---

## Setup Simples vs Completo

Você pode escolher entre dois níveis de setup, dependendo do que precisa:

### Setup SIMPLES (5 minutos)

Apenas o essencial para ter um agente funcional:

```
1. mkdir -p ~/.hermes/profiles/meu-agente/
2. Configurar model via terminal (3 comandos)
3. Adicionar API key no .env
4. Testar: hermes --profile meu-agente run --prompt "teste"
```

**Indicado para:** Testar o Hermes pela primeira vez, experimentar a plataforma, fazer provas de conceito rápidas.

**O que você tem no final:**
- Um agente que responde no terminal
- Ferramentas básicas habilitadas (terminal, arquivos, web)
- Capacidade de executar tarefas simples

### Setup COMPLETO (2 horas)

Setup profissional com personalidade, memória e integração com Slack:

```
1. Setup simples (acima)
2. Criar AGENTS.md, SOUL.md, IDENTITY.md, TEAM.md
3. Criar operacional/DIARIO.md e ESTADO-DA-EQUIPE.md
4. Configurar Slack (app, tokens, gateway)
5. Instalar skills do agent-ops-workflow
6. Injetar PROTOCOLO DIARIO no system_prompt
7. Iniciar gateway
```

**Indicado para:** Uso diário em projetos reais, times que precisam de automação contínua, operações com múltiplos agentes.

**O que você tem no final:**
- Agente com personalidade definida (SOUL.md, IDENTITY.md)
- Memória de longo prazo (arquivos de estado)
- Bot no Slack que responde 24/7
- Protocolo diário (planejamento e revisão automáticos)
- Habilidade de trabalhar em equipe com outros agentes

> 💡 **Dica:** Comece com o setup simples. Depois que sentir confiança, evolua para o completo. Você não precisa fazer tudo de uma vez.

---

## Próximos Passos Expandidos

Agora que você tem um agente funcional, aqui estão os próximos passos com instruções detalhadas:

### Automatize com Cron

O Hermes pode executar tarefas automaticamente em horários agendados — ideal para gerar planos diários, relatórios de auditoria, ou sincronizar dados.

#### Via Cron do Sistema (mais confiável)

```bash
# Exemplo: todo dia às 5h da manhã, gere um plano diário
# Edite o crontab:
crontab -e

# Adicione esta linha:
0 5 * * * /caminho/para/scripts/gerar-plano-diario.sh ~/meu-projeto --tasks=5

# O script gerar-plano-diario.sh internamente chama:
# hermes --profile meu-agente run --prompt "Gere o plano de hoje com 5 tarefas"
```

#### Via Cron do Hermes (integrado ao agente)

```bash
# Criar um cronjob que roda todo dia às 5h
hermes cronjob create \
  --name "plano-diario" \
  --schedule "0 5 * * *" \
  --prompt "Gere o plano de hoje baseado no estado atual do projeto"
```

#### Refresh Automático do DuckDB Cache

Se você usa o sistema de auditoria DuckDB, pode usar o script `export-cache.sh` para atualizar o cache periodicamente:

```bash
# No crontab:
*/30 * * * * /caminho/para/export-cache.sh
```

### Expanda sua Equipe

Adicionar mais agentes é simples: repita o processo de criar perfil, configurar modelo e dar personalidade. Cada agente pode ter um papel diferente.

#### Sugestões de Papéis

| Papel | Personalidade | Ferramentas | Para que serve |
|-------|---------------|-------------|----------------|
| **Assistente Admin** | Organizado, conciso | terminal, file, cronjob | Gerenciar arquivos, agendar tarefas, manter diários |
| **Analista de Dados** | Analítico, detalhista | terminal, file, web, search | Gerar relatórios, analisar logs, cruzar dados |
| **Auditor** | Cético, rigoroso | terminal, file, git | Revisar código, checar conformidade, detectar anomalias |

#### Reusando o Mesmo Workspace do Slack

Você pode ter múltiplos agentes no mesmo workspace do Slack. Cada um precisa do seu próprio **Slack App** (ou do mesmo app com nomes de bot diferentes). Basta criar outro perfil e configurar o Slack com um nome de bot único.

```bash
# Criar um segundo agente
mkdir -p ~/.hermes/profiles/analista-dados/
# Configurar modelo
hermes --profile analista-dados config set model.default deepseek-v4-flash
hermes --profile analista-dados config set model.provider opencode-go
# Adicionar personalidade (criar SOUL.md, IDENTITY.md etc.)
```

### Crie Skills Próprias

Skills são **módulos de conhecimento procedural** que ensinam o agente a fazer algo específico. Elas ficam em arquivos markdown dentro da pasta `skills/` do perfil.

#### Estrutura de uma Skill

```markdown
---
name: minha-skill
description: O que esta skill faz
---

# Minha Skill

## Gatilho
- Quando o usuario pedir para fazer X
- Quando Y acontecer no fluxo de trabalho
- Quando o agente detectar uma condicao Z

## Instrucoes
1. Primeiro, verifique se o arquivo de configuracao existe
2. Se existir, leia e interprete os parametros
3. Execute a acao principal usando as ferramentas disponiveis
4. Registre o resultado no log da skill

## Pitfalls (ARMADILHAS COMUNS)
- Cuidado com caminhos relativos: sempre use caminhos absolutos
- Nao assuma que variaveis de ambiente existem — verifique antes
- Se a acao falhar, tente uma abordagem alternativa em vez de travar
- Lembre-se de pedir confirmacao para acoes destrutivas

## Exemplos
- `"Execute o deploy do projeto"` → Le o config, roda tests, faz deploy
- `"Verifique a saude do sistema"` → Checa CPU, memoria, disco, logs de erro
```

#### Como Instalar uma Skill

```bash
# 1. Crie a pasta de skills
mkdir -p ~/.hermes/profiles/meu-agente/skills/

# 2. Crie o arquivo da skill
touch ~/.hermes/profiles/meu-agente/skills/minha-skill.md

# 3. Edite com o conteudo acima (use seu editor favorito)

# 4. Referencie a skill no config.yaml (opcional, mas recomendado)
hermes --profile meu-agente config set skills.minha-skill enabled true
```

### Configure Alertas do DuckDB

Se você usa o sistema de auditoria com DuckDB, existe um mecanismo de **canary** que monitora a integridade dos dados.

#### Como funciona o Canary

O script de auditoria compara o número de registros atuais com a média histórica. Se houver uma variação **acima de 50%**, o script trava e emite um alerta. Isso evita que dados corrompidos ou incompletos passem despercebidos.

#### Configurar Notificação no Slack

```bash
# Opção 1: Webhook do Slack (simples)
# Crie um webhook no Slack e adicione ao script de auditoria:
# curl -X POST -H 'Content-type: application/json' \
#   --data '{"text":"ALERTA: Variacao detectada no DuckDB cache!"}' \
#   SEU_WEBHOOK_URL

# Opção 2: Deixe o próprio agente monitorar
# Crie um cronjob que verifica o estado do cache periodicamente:
hermes cronjob create \
  --name "verificar-cache" \
  --schedule "0 */2 * * *" \
  --prompt "Verifique o cache do DuckDB. Se houver variacao >50% em relacao a media, me avise imediatamente."
```

### Integre com CI/CD

Após a auditoria do código, o orquestrador pode disparar deploys automáticos. Isso fecha o ciclo: código chega → agente revisa → auditor aprova → deploy automatico.

#### Exemplo de Pipeline

```
[Dev faz commit] → [Agente auditor revisa] → [Task aprovada]
                                              ↓
                                   [Orquestrador executa:]
                                   1. git push para main
                                   2. GitHub Actions detecta o push
                                   3. Pipeline de CI/CD roda
                                   4. Deploy em staging/producao
```

#### Configuração com GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy Automático
on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy
        run: |
          echo "Deploy acionado apos auditoria do Hermes Agent"
          # Seus comandos de deploy aqui
```

> 💡 **Dica:** Você pode fazer o agente executar o `git push` automaticamente após aprovação, ou deixar que ele apenas prepare o merge request para revisão humana. O nível de autonomia é configurável.

---

## Checklist de Verificação

Use esta lista para confirmar que tudo está funcionando:

- [ ] `hermes --version` exibe a versão instalada
- [ ] `echo $OPENCODE_GO_API_KEY` exibe sua chave (ou ela está no `.env`)
- [ ] `~/.hermes/profiles/meu-primeiro-agente/config.yaml` existe e tem `timezone` configurado
- [ ] `~/.hermes/profiles/meu-primeiro-agente/.env` existe com a API key
- [ ] `AGENTS.md`, `SOUL.md`, `IDENTITY.md`, `TEAM.md` foram criados
- [ ] O comando de teste com `--prompt` retorna resposta sem erros
- [ ] Os logs foram gerados em `logs/`

---

> **Documento gerado em:** junho de 2026
> **Versão do Hermes Agent:** Consulte `hermes --version`
> **Provedor recomendado:** OpenCode Go (DeepSeek V4 Flash para uso diário,
> V4 Pro para tarefas complexas)
