# Guia de Configuração — Agent Ops Workflow

> Passo a passo completo para instalar, configurar e verificar seu sistema de
> planejamento diário multi-agente. Tempo até o primeiro plano: ~30 minutos se
> você tiver os pré-requisitos prontos.

---

## Sumário

1. [Pré-requisitos](#pré-requisitos)
2. [Clonar o Repositório](#clonar-o-repositório)
3. [Executar o Script de Configuração](#executar-o-script-de-configuração)
4. [Personalizar Placeholders para Seu Time](#personalizar-placeholders-para-seu-time)
5. [Configurar Agentes Hermes](#configurar-agentes-hermes)
6. [Configurar Integração com Slack](#configurar-integração-com-slack)
7. [Configurar o Cron Job](#configurar-o-cron-job)
8. [Checklist de Verificação Pós-Configuração](#checklist-de-verificação-pós-configuração)
9. [Solução de Problemas](#solução-de-problemas)
10. [Próximos Passos](#próximos-passos)

---

## Pré-requisitos

Antes de começar, certifique-se de que seu ambiente possui as seguintes
ferramentas e contas prontas.

### 1. Hermes Agent (Obrigatório)

Hermes é o framework de agente CLI que alimenta este workflow. Você precisa
tê-lo instalado e configurado na máquina que atuará como orquestradora.

```bash
# Verificar instalação
hermes --version

# Saída esperada:
# hermes/1.x.x ...
```

Se o Hermes não estiver instalado, siga o guia oficial:
https://hermes-agent.nousresearch.com/docs

Você precisará de pelo menos um perfil Hermes configurado com:
- Uma chave de API para o provedor de modelo de IA escolhido
- Opcional: tokens de integração Slack (abordados na Seção 6)
- Diretório de skills onde as skills do workflow podem ser carregadas

```bash
# Verificar sua configuração atual do Hermes
hermes config list
# ou inspecione o arquivo de configuração diretamente
cat ~/.hermes/config.yaml
```

### 2. Workspace Slack (Recomendado)

Um workspace Slack onde sua equipe se comunica. Você precisará de:
- **Administrador do Workspace** (ou permissão para instalar apps)
- Um canal dedicado para operações (ex.: `#agent-ops`)
- Capacidade de criar apps Slack se quiser delegação automatizada

Se você estiver usando uma equipe totalmente local sem Slack, pode substituir
por qualquer sistema de chat que suporte mensagens em thread e @menções. O
protocolo foi projetado para ser agnóstico de canal, mas o Slack é a
implementação de referência.

### 3. Ferramentas CLI

| Ferramenta | Versão Mínima | Comando para Verificar | Observações |
|------------|---------------|------------------------|-------------|
| bash | 4.0+ | `bash --version` | macOS tem 3.x por padrão |
| git | 2.0+ | `git --version` | Necessário para clonar e tarefas |
| sed | qualquer | `sed --version` | Usado pelo script cron |
| grep | qualquer | `grep --version` | Usado pelo script de validação |
| find | qualquer | `find --version` | Usado pelo script de validação |
| date | qualquer | `date --help` | Formatação de data para planos |

> **Nota para macOS:** O bash padrão é versão 3.x. Instale bash 4+ via Homebrew:
> `brew install bash`. Todos os scripts usam shebang `#!/bin/bash`, então
> atualize seu PATH ou altere o shebang se necessário.

### 4. Chave SSH (Opcional mas Recomendado)

```bash
# Gerar uma chave ed25519 se você não tiver uma
ssh-keygen -t ed25519 -C "seu-email@exemplo.com"

# Adicionar ao ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

O projeto inclui um helper `scripts/rotate-key.sh` para rotação de chaves.

---

## Clonar o Repositório

Comece clonando o repositório agent-ops-workflow para sua máquina local.

```bash
# Navegue até seu diretório de desenvolvimento
cd /caminho/para/seu/projetos

# Clone o repositório
git clone https://github.com/rafael-fae/agent-ops-workflow.git
cd agent-ops-workflow

# Torne os scripts executáveis
chmod +x scripts/*.sh
```

A estrutura do repositório que você deve ver:

```
agent-ops-workflow/
├── scripts/               # Ferramentas de automação
│   ├── setup-workflow.sh        # Inicialização do projeto
│   ├── gerar-plano-diario.sh    # Gerador de planos diários (cron-ready)
│   ├── validate-workflow.sh     # Auditor de integridade e consistência
│   └── rotate-key.sh            # Rotação de chave SSH
├── templates/             # Fonte da verdade para todos os templates
│   ├── PLANO.md.tpl             # Template de plano diário
│   ├── TASK.md.tpl              # Template de tarefa individual
│   ├── INDICE.md.tpl            # Template de índice de progresso
│   └── README-WORKFLOW.md.tpl   # Template de README da pasta
├── docs/                  # Documentação completa (você está aqui)
├── planejamento-diario/   # O workflow executando em si mesmo
├── files/                 # Área de trabalho .gitignored
├── README.md              # Guia em português
└── README-en.md           # Guia em inglês
```

> **Importante:** O diretório `files/` está no `.gitignore`. É uma área de
> trabalho para dados brutos e específicos do time. Nada em `files/` é
> commitado.

---

## Executar o Script de Configuração

O script `setup-workflow.sh` cria a estrutura de pastas de planejamento diário
dentro do **diretório do seu projeto** (não dentro do agent-ops-workflow). Ele
copia templates, gera um `INDICE.md` inicial e cria uma pasta para hoje com um
`PLANO.md` esqueleto.

### Modo Interativo

Execute sem argumentos para ser guiado passo a passo:

```bash
cd agent-ops-workflow
./scripts/setup-workflow.sh
```

Você será solicitado a fornecer:

1. **Diretório alvo** — Onde seu projeto vive (ex.: `~/meu-projeto`).
   O script cria `~/meu-projeto/planejamento-diario/`.

2. **Nome do time** — Seu identificador de equipe (ex.: `Time Nova`). Isso é
   incorporado nos planos gerados e arquivos de índice.

3. **Nome do projeto** — O nome do seu projeto (ex.: `Projeto Atlas`).

4. **Motor padrão** — O modelo de IA principal para tarefas de código.
   Recomendado: `Gemini CLI` ou `Claude Code`.

5. **Motores adicionais** — Lista separada por vírgulas de motores alternativos.

6. **Idioma da documentação** — `pt-BR` ou `en-US`.

Exemplo de sessão interativa:

```
╔══════════════════════════════════════════════════════════════╗
║       Setup do Workflow de Planejamento Diário             ║
╚══════════════════════════════════════════════════════════════╝

Diretório do projeto (ex: ~/meu-projeto): ~/meu-projeto
Nome do time (ex: Time Alfa): Time Nova
Nome do projeto (ex: Projeto X): Projeto Atlas
Motor padrão [Gemini CLI]:
Outros motores (separados por vírgula) [Claude Code, OpenAI API, DeepSeek]:
Idioma da documentação [pt-BR]:
```

### Modo Não Interativo

Passe todos os parâmetros como argumentos para configuração headless (útil em CI/CD):

```bash
./scripts/setup-workflow.sh ~/meu-projeto "Time Nova" "Projeto Atlas"
```

Fallbacks de variáveis de ambiente:

```bash
export WORKFLOW_TEAM_NAME="Time Nova"
export WORKFLOW_PROJECT_NAME="Projeto Atlas"
./scripts/setup-workflow.sh ~/meu-projeto
```

### O que o Script Cria

Após a execução, seu diretório de projeto terá:

```
~/meu-projeto/
└── planejamento-diario/
    ├── INDICE.md                    # Índice mestre de progresso
    ├── TEMPLATES/                   # Copiado de agent-ops-workflow/templates/
    │   ├── PLANO.md
    │   ├── TASK.md
    │   ├── INDICE.md
    │   └── README-WORKFLOW.md
    └── YYYY-MM-DD/                  # Data de hoje (ex.: 2026-06-03)
        └── PLANO.md                 # Plano esqueleto para o dia
```

---

## Personalizar Placeholders para Seu Time

Os templates usam a sintaxe `__PLACEHOLDER__` (sublinhados duplos). Esses
placeholders são substituídos pelo `setup-workflow.sh` com os valores que você
forneceu, mas você pode personalizar ainda mais.

### Arquivos de Template para Revisar

Revise e edite os seguintes arquivos em `~/meu-projeto/planejamento-diario/TEMPLATES/`:

| Arquivo | Propósito | Placeholders Principais |
|---------|-----------|-------------------------|
| `PLANO.md` | Template de plano de execução diário | `__DATA__`, `__COMANDANTE__`, `__TIME__` |
| `TASK.md` | Template de brief de tarefa individual | `__AGENTE__`, `__MOTOR__`, `__CONTEXTO__` |
| `INDICE.md` | Template de índice mestre de progresso | `__NOME_DO_PROJETO__`, `__DATA__` |
| `README-WORKFLOW.md` | README da pasta de planejamento | `__NOME_DO_TIME__`, `__URL_DOCS__` |

### Exemplo de Personalização para o Time Nova

Edite `PLANO.md` para substituir a seção de regras de execução:

```markdown
## Regras de Execução

1. **Motor padrão:** Gemini CLI (gemini-3.1-pro-preview)
2. **NUNCA modifique arquivos originais** — trabalhe em cópias ou branches
3. **Repositório:** Commit apenas conteúdo sanitizado/genérico
4. **Autossuficiente:** Este projeto não depende de infraestrutura externa
5. **Idioma:** Português (Brasil) para toda a documentação
6. **Commits semânticos:** Commits descritivos em português
7. **Máximo de threads concorrentes:** 3 agentes
8. **Auditoria:** Toda tarefa concluída deve ser revisada por outro agente
```

### Troca de Idioma

Para alternar de Português (padrão) para Inglês:

1. Defina `IDIOMA="en-US"` durante o setup
2. Edite `TEMPLATES/PLANO.md` e substitua a regra #6 com seu idioma
3. Atualize `INDICE.md` — texto do cabeçalho e nomes das seções

---

## Configurar Agentes Hermes

A máquina orquestradora precisa do Hermes configurado com perfis de agente que
correspondam às funções da sua equipe.

### Entendendo o Modelo de Agente

No Agent Ops Workflow, cada agente é uma **função**, não uma pessoa. Uma única
instância do Hermes pode atuar como vários agentes alternando contextos. As
funções padrão da equipe são:

| Função | Descrição |
|--------|-----------|
| Comandante | Humano — revisa planos, dá aprovação final |
| Orquestrador | Agente Hermes — cria planos, delega, audita |
| Agente Dev | Agente Hermes — executa tarefas de código |
| Agente Auditor | Agente Hermes — verifica trabalho concluído |
| Agente Relator | Agente Hermes — consolida relatório diário |

### Criando AGENTS.md

Crie um arquivo `AGENTS.md` na raiz do seu projeto que documente sua equipe.
Exemplo para o Time Nova:

```markdown
# Time Nova — Registro de Agentes

| ID do Agente | Função | ID do Slack | Motor Padrão |
|--------------|--------|-------------|--------------|
| @nova-orch | Orquestrador | <@U0123456789> | Gemini 3.1 Pro |
| @nova-dev | Agente Dev | <@U9876543210> | Gemini 3.1 Pro |
| @nova-audit | Agente Auditor | <@U5555555555> | Opus 4.7 |
| @nova-report | Agente Relator | <@U1111111111> | Gemini 3.1 Pro |
```

Este arquivo não é consumido diretamente por nenhum script, mas serve como
referência canônica de quem é quem na equipe.

### config.yaml do Hermes

Sua configuração do Hermes (`~/.hermes/config.yaml`) deve incluir:

```yaml
profiles:
  nova-orch:
    model: gemini-3.1-pro-preview
    skills_dir: ~/meu-projeto/skills/
    slack:
      enabled: true
      bot_token: xoxb-...
      app_token: xapp-...
      home_channel: C0123456789

  nova-dev:
    model: gemini-3.1-pro-preview
    # Sem configuração Slack necessária para executores
    # Eles se comunicam através do orquestrador

  nova-audit:
    model: opus-4.7
```

> Os tokens Slack são abordados na próxima seção. Você pode pular a
> configuração `slack:` se estiver usando uma configuração apenas local.

### Carregando Skills

Skills são workflows reutilizáveis que os agentes podem carregar. O repositório
inclui skills sanitizadas em `files/skills/sanitized/` (se disponível). Para
carregar uma skill:

```bash
# Inspecionar uma skill antes de carregar
hermes skill_view caminho/para/skill/SKILL.md

# Carregar e ativar uma skill
hermes skill_manage add caminho/para/skill/SKILL.md
```

Skills usam sintaxe `{{PLACEHOLDER}}` (chaves duplas). Arquivos de template
usam `__PLACEHOLDER__` (sublinhados duplos). Essa distinção evita conflitos.

---

## Configurar Integração com Slack

O Slack é a camada de comunicação recomendada para delegar tarefas aos agentes.
Esta seção orienta a criação de um app Slack, obtenção de tokens e configuração
do workspace.

### Passo 1: Criar um App Slack

1. Acesse https://api.slack.com/apps
2. Clique em **Create New App** → **From Scratch**
3. Dê um nome (ex.: `Time Nova Agent Ops`) e selecione seu workspace
4. Clique em **Create App**

### Passo 2: Configurar Escopos do Token Bot

Navegue até **OAuth & Permissions** → **Scopes** → **Bot Token Scopes**.
Adicione os seguintes escopos:

| Escopo | Propósito |
|--------|-----------|
| `channels:history` | Ler histórico do canal (encontrar threads) |
| `channels:read` | Visualizar informações do canal e listas de membros |
| `chat:write` | Enviar mensagens e postar em threads |
| `reactions:read` | Ler reações de emoji (sinais de auditoria) |
| `users:read` | Ler informações do usuário (resolver @menções) |

Adicione também estes **User Token Scopes** se quiser que o app atue em nome
de um usuário:

| Escopo | Propósito |
|--------|-----------|
| `channels:manage` | Criar/gerenciar canais (se necessário) |

### Passo 3: Instalar o App no Seu Workspace

1. Em **OAuth & Permissions**, clique em **Install to Workspace**
2. Revise as permissões e clique em **Allow**
3. Copie o **Bot User OAuth Token** (começa com `xoxb-`)

### Passo 4: Obter Token Bot e Token App

Você precisa de dois tokens:

1. **Token Bot** (`SLACK_BOT_TOKEN`): `xoxb-...` do passo anterior
2. **Token de Nível de App** (`SLACK_APP_TOKEN`): Vá em **Basic Information** →
   **App-Level Tokens** → **Generate Token**. Adicione escopos:
   `connections:write`, `authorizations:read`

> Armazene tokens com segurança. Nunca os commit no controle de versão. Use
> variáveis de ambiente ou um gerenciador de segredos.

### Passo 5: Encontrar IDs do Seu Workspace Slack

**ID do Canal** (o canal principal para operações):
```bash
# No Slack, clique com o botão direito no nome do canal → Copiar Link
# A URL contém o ID do canal:
# https://workspace.slack.com/archives/C0123456789
#                                    ^^^^^^^^^^^^
```

**IDs de Usuário** para os membros da sua equipe:
```bash
# Método 1: Página do app Slack
# Acesse api.slack.com/methods/users.list → Try It
# Digite seu token e encontre os IDs dos usuários

# Método 2: Abra o Slack, clique no perfil de um usuário → More → Copy member ID
# IDs de usuário parecem com: U0123456789
```

**Canal principal**: Crie um canal dedicado (ex.: `#agent-ops-nova`) e
use seu ID como `home_channel` na configuração do Hermes.

### Passo 6: Configurar Hermes com Tokens Slack

Adicione a configuração Slack ao seu perfil Hermes:

```bash
# Método A: Variáveis de ambiente (recomendado para segurança)
export SLACK_BOT_TOKEN=xoxb-seu-token
export SLACK_APP_TOKEN=xapp-seu-app-token
export SLACK_HOME_CHANNEL=C0123456789

# Método B: config.yaml do Hermes
# Edite ~/.hermes/config.yaml
```

### Passo 7: Testar a Conexão

Envie uma mensagem de teste para verificar se o bot está funcionando:

```bash
# Usando a capacidade Slack do Hermes (se disponível)
hermes slack send --channel C0123456789 --text "Time Nova online. Pronto para operações diárias."

# Esperado: O bot envia uma mensagem para o canal
```

Se você vir erros, verifique:
- Tokens estão corretos e não expiraram
- O bot foi convidado para o canal (`/invite @TimeNovaBot`)
- O ID do canal principal está correto

---

## Configurar o Cron Job

O gerador de planos diários (`gerar-plano-diario.sh`) foi projetado para rodar
via cron no início de cada dia. Ele cria uma nova pasta e um plano esqueleto
para que a equipe tenha uma estrutura nova esperando.

### Agendamento Cron

```bash
# Edite seu crontab
crontab -e

# Adicione esta linha para gerar um plano diário às 5:00 AM
0 5 * * * /caminho/para/agent-ops-workflow/scripts/gerar-plano-diario.sh \
  /Users/seu-usuario/meu-projeto \
  >> /Users/seu-usuario/meu-projeto/planejamento-diario/cron.log 2>&1
```

### Testando o Comando Cron

Execute o comando manualmente para verificar se funciona:

```bash
/caminho/para/agent-ops-workflow/scripts/gerar-plano-diario.sh \
  /Users/seu-usuario/meu-projeto --tasks=5
```

A saída deve ser:

```
[INFO]  Plano diário gerado com sucesso:
[INFO]    Local: /Users/seu-usuario/meu-projeto/planejamento-diario/YYYY-MM-DD/PLANO.md
[INFO]    Data: DD/MM/YYYY
[INFO]    Tasks por wave: 5
```

### Opções do Cron

| Opção | Descrição |
|-------|-----------|
| `--tasks=N` | Número de tarefas esqueleto por wave (padrão: 5) |
| `--force, -f` | Sobrescrever plano existente para hoje (use com cuidado) |
| `--help, -h` | Mostrar mensagem de ajuda |

### Log do Cron

O script anexa a `planejamento-diario/cron.log` automaticamente. Monitore
este arquivo para falhas:

```bash
tail -f ~/meu-projeto/planejamento-diario/cron.log
```

### Variáveis de Ambiente para o Cron

O cron executa com um ambiente mínimo. Defina estas no seu crontab:

```bash
# Antes do comando cron, defina:
WORKFLOW_TEAM_NAME="Time Nova"
WORKFLOW_PROJECT_NAME="Projeto Atlas"
SLACK_BOT_TOKEN=xoxb-...
SLACK_APP_TOKEN=xapp-...
SLACK_HOME_CHANNEL=C0123456789

# Depois o comando cron
0 5 * * * export WORKFLOW_TEAM_NAME="Time Nova" WORKFLOW_PROJECT_NAME="Projeto Atlas"; /caminho/para/gerar-plano-diario.sh ~/meu-projeto >> ~/meu-projeto/planejamento-diario/cron.log 2>&1
```

Ou use um script wrapper que carrega as variáveis de ambiente primeiro.

---

## Checklist de Verificação Pós-Configuração

Execute este checklist após concluir a configuração para confirmar que tudo
está funcionando corretamente.

### Verificação de Estrutura

```
~/meu-projeto/
├── planejamento-diario/
│   ├── INDICE.md                     ← [ ] Existe e é markdown válido
│   ├── TEMPLATES/
│   │   ├── PLANO.md                  ← [ ] Copiado de .tpl
│   │   ├── TASK.md                   ← [ ] Copiado de .tpl
│   │   ├── INDICE.md                 ← [ ] Copiado de .tpl
│   │   └── README-WORKFLOW.md        ← [ ] Opcional, mas útil
│   └── YYYY-MM-DD/                   ← [ ] Pasta de hoje existe
│       └── PLANO.md                  ← [ ] Contém plano esqueleto
```

### Verificação de Template

- [ ] `PLANO.md` tem valores `__PLACEHOLDER__` substituídos pelas informações do time
- [ ] `TASK.md` tem nomes de agentes e motores padrão corretos
- [ ] `INDICE.md` mostra o nome do seu projeto no cabeçalho

### Verificação de Script

```bash
# Execute o script de validação
./scripts/validate-workflow.sh ~/meu-projeto

# Código de saída esperado: 0 (ou 1 com avisos, aceitável para configuração inicial)
# Se código de saída 2, algo está faltando — corrija antes de prosseguir
```

### Verificação do Slack

- [ ] Token bot é válido e tem escopos corretos
- [ ] Bot foi convidado para o canal principal
- [ ] ID do canal está correto na configuração do Hermes
- [ ] IDs de usuário estão documentados em AGENTS.md
- [ ] Mensagem de teste foi enviada e recebida

### Verificação do Cron

- [ ] Cron job está agendado (`crontab -l` mostra a entrada)
- [ ] Execução manual não produz erros
- [ ] Arquivo `cron.log` existe em `planejamento-diario/`
- [ ] Plano foi gerado para a data correta

### Verificação de Autenticação

- [ ] Git pode fazer push para seu remoto (se estiver usando um)
- [ ] Chave SSH está carregada no ssh-agent
- [ ] Hermes consegue acessar seu endpoint de API
- [ ] Tokens Slack não estão expirados

---

## Solução de Problemas

### Erros de Script

| Erro | Causa Provável | Correção |
|------|---------------|----------|
| `bash: ./scripts/*.sh: Permission denied` | Scripts não executáveis | `chmod +x scripts/*.sh` |
| `Pasta de templates não encontrada` | Executando fora da raiz do projeto | `cd agent-ops-workflow` primeiro |
| `sed: RE error: illegal byte sequence` | sed do macOS + caracteres não-ASCII | Instale GNU sed: `brew install gnu-sed` |
| `date: illegal option` | Problema de sintaxe date do macOS | Use `gdate` do coreutils se necessário |

### Problemas com Slack

| Problema | Causa Provável | Correção |
|----------|---------------|----------|
| Bot não responde a @menções | Bot não está no canal | `/invite @TimeNovaBot` |
| Erro `not_in_channel` | Bot não foi convidado ao canal | Convide o bot para o canal |
| Erro `invalid_auth` | Token expirado ou errado | Regere token no painel Slack API |
| Mensagem não aparece na thread | Parâmetro `thread_ts` ausente | Sempre responda na thread, não como nova mensagem |
| Erro de escopo faltando | Bot não tem o escopo necessário | Adicione escopo, reinstale app no workspace |

### Problemas com Cron

| Problema | Causa Provável | Correção |
|----------|---------------|----------|
| Cron job não executa | PATH não definido no cron | Use caminhos absolutos ou defina PATH no crontab |
| Cron não produz saída | stderr não redirecionado | Adicione `2>&1` ao comando cron |
| Script executa mas plano não gerado | Template faltando | Execute `setup-workflow.sh` primeiro |

### Falhas de Validação

```bash
# Se validate-workflow.sh retornar erros, use --fix para auto-corrigir
./scripts/validate-workflow.sh ~/meu-projeto --fix

# Execute com --verbose para ver todas as verificações em detalhes
./scripts/validate-workflow.sh ~/meu-projeto --verbose
```

Avisos de validação comuns e como resolvê-los:

| Aviso | Resolução |
|-------|-----------|
| Contador incorreto no INDICE.md | Execute com `--fix` para auto-corrigir, ou manualmente |
| Task X: nenhum checkbox preenchido | Preencha os checkboxes no arquivo da tarefa |
| PLANO.md lista N tasks, disco tem M | Adicione ou remova arquivos de tarefa para igualar |
| Pasta TEMPLATES/ vazia | Re-execute `setup-workflow.sh` para copiar templates |

---

## Próximos Passos

Após a configuração estar completa, sua equipe está pronta para o primeiro
ciclo diário.

1. **Leia o Guia do Ciclo Diário** (`02-CICLO-DIARIO.md`) — Entenda as 6
   fases (Planejar → Aprovar → Delegar → Executar → Auditar → Reportar).

2. **Leia o Protocolo Slack** (`03-PROTOCOLO-SLACK.md`) — Aprenda como os
   agentes se comunicam, o sistema de menções, regras de thread e
   procedimentos de lock down.

3. **Execute seu primeiro ciclo seco** — Crie um dia de teste com 1-2 tarefas,
   percorra todas as 6 fases e verifique se o loop fecha corretamente.

4. **Personalize seus templates** — Edite os arquivos `TEMPLATES/` para
   corresponder às convenções da sua equipe, motores preferidos e idioma.

5. **Convide sua equipe** — Compartilhe `AGENTS.md`, o link de convite do
   canal principal e o agendamento cron. Certifique-se de que todos conhecem
   as regras de ouro.

---

## Referência Rápida

```bash
# Inicializar um novo projeto
./scripts/setup-workflow.sh ~/novo-projeto "Time Nova" "Projeto Nova"

# Gerar plano de hoje (manual)
./scripts/gerar-plano-diario.sh ~/novo-projeto

# Validar estrutura
./scripts/validate-workflow.sh ~/novo-projeto

# Validar e auto-corrigir
./scripts/validate-workflow.sh ~/novo-projeto --fix

# Rotacionar chave SSH
./scripts/rotate-key.sh id_nova
```

---

## Referência de Variáveis de Ambiente

| Variável | Usado Por | Propósito |
|----------|-----------|-----------|
| `WORKFLOW_TEAM_NAME` | setup, gerar-plano | Nome do time para placeholders |
| `WORKFLOW_PROJECT_NAME` | setup, gerar-plano | Nome do projeto para placeholders |
| `SLACK_BOT_TOKEN` | Integração Slack Hermes | Autenticação do bot |
| `SLACK_APP_TOKEN` | Integração Slack Hermes | Socket mode de nível de app |
| `SLACK_HOME_CHANNEL` | Integração Slack Hermes | Canal de operações padrão |

---

## 🔓 Configuração de Approvals (Segurança)

Por padrão, o Hermes Agent pede autorização para QUALQUER comando executado via terminal. Para não travar o fluxo dos agentes com comandos de leitura/verificação, configure `auto_approve_patterns` no `config.yaml` de cada agente:

```yaml
# ~/.hermes/profiles/meu-agente/config.yaml
approvals:
  mode: auto
  timeout: 60
  auto_approve_patterns:
    # Leitura e verificação segura
    - "python* -c \"import ast*"
    - "python* -c \"import py_compile*"
    - "python* -c \"import os*"
    - "python* -c \"print*"
    - "git log*"
    - "git show*"
    - "git status*"
    - "git diff*"
    - "git branch*"
    - "cat *"
    - "head *"
    - "tail *"
    - "wc *"
    - "find *"
    - "grep *"
    - "ls *"
    - "mkdir *"
    - "pwd*"
    - "echo*"
    - "which*"
    - "file *"
    - "stat *"
    # Compilação
    - "python* -m py_compile*"
    # Git add/commit/push (já autorizados pela task)
    - "git add*"
    - "git commit*"
    - "git push*"
    # Django check (sem destruição)
    - "python manage.py check*"
    - "python manage.py showmigrations*"
    - "python manage.py sqlmigrate*"
```

Comandos **DESTRUTIVOS** continuam exigindo autorização explícita e NUNCA devem ser adicionados a esta lista:
- `rm -rf`, `rm *`, `DROP DATABASE`, `DELETE`, `TRUNCATE`
- `docker compose down -v`, `docker system prune`
- `format`, `mkfs`, `dd`, `chmod -R 777`, `chown -R`
- Qualquer comando via SSH que modifique dados

Para aplicar esta configuração em todos os agentes da sua equipe, edite o `config.yaml` de cada perfil em `~/.hermes/profiles/<AGENTE>/config.yaml`.

> Configuração completa. Sua equipe agora tem um sistema de planejamento diário
> multi-agente testado em produção rodando no Hermes. O próximo passo é
> aprender o ciclo diário — vá para `02-CICLO-DIARIO.md`.
