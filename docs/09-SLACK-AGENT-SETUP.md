# Configuração do Slack para Agentes Hermes + Personalidade e Memória

> Guia didático — do workspace vazio ao agente operacional no Slack,
> passando por personalidade, memória permanente e múltiplos agentes.

---

## Sumário

1. [Workspace Slack](#1-workspace-slack)
2. [Criar Slack App para o Agente (com Manifest)](#2-criar-slack-app-para-o-agente-com-manifest)
3. [Obter Tokens](#3-obter-tokens)
4. [Configurar Tokens no Perfil Hermes](#4-configurar-tokens-no-perfil-hermes)
5. [Personalidade do Agente (system_prompt)](#5-personalidade-do-agente-system_prompt)
6. [Memória Permanente do Agente](#6-memória-permanente-do-agente)
7. [Criando Múltiplos Agentes](#7-criando-múltiplos-agentes)
8. [Checklist Pós-Configuração](#8-checklist-pós-configuração)

---

## 1. Workspace Slack

### 1.1 Criar um workspace grátis

1. Acesse **[slack.com](https://slack.com)** e clique em **"Criar um workspace"**.
2. Informe seu e-mail e siga o fluxo de criação.
3. Escolha um nome para sua empresa/equipe (ex: `Minha Empresa`).
4. Defina um nome curto para o workspace (ex: `minha-empresa`). Esse nome aparece na URL: `minha-empresa.slack.com`.
5. O plano **Free** é suficiente para testar — você tem acesso ao histórico dos últimos 90 dias, integrações com apps e até 10 apps conectados.

> Dica: O plano Free já permite usar Socket Mode (obrigatório para o Hermes)
> sem custos. Para produção com muitos usuários, avalie o plano Pro.

### 1.2 Criar canal dedicado para operações

Canais são onde os agentes vão ouvir e responder. Crie pelo menos um canal:

1. Na barra lateral esquerda, clique no **+** ao lado de "Canais".
2. Nome: `#agentes` (ou `#ops`, `#automacoes`).
3. Defina como **Público** (qualquer membro pode entrar) ou **Privado** (só convidados).
4. Clique em **Criar**.

```
   #agentes  ← canal público onde seu agente vai operar
   ┌─────────────────────────────────────┐
   │  Você: @meu-agente, rode o relatório │
   │                                     │
   │  Agente: Relatório gerado!          │
   │  [arquivo.pdf]                      │
   └─────────────────────────────────────┘
```

### 1.3 Convidar membros (se necessário)

- Vá em **Configurações > Gerenciar membros**.
- Clique em **Convidar** e envie o link por e-mail.
- Cada membro precisa criar uma conta gratuita para participar.

---

## 2. Criar Slack App para o Agente (com Manifest)

### 2.1 O que é um Slack App?

Um **Slack App** é a identidade do seu agente dentro do workspace. Ele possui:

- Um **nome e ícone** que aparecem nas mensagens.
- **Permissões** (scopes) que definem o que o bot pode fazer.
- **Tokens** que o Hermes usa para se autenticar.

O Hermes se conecta ao Slack via **Socket Mode** — uma conexão WebSocket direta, sem precisar de servidor HTTP público. Isso significa que seu agente roda localmente ou em um servidor privado, sem expor portas.

> Resumo: Slack App = crachá do agente. Socket Mode = canal seguro
> de comunicação. Hermes = o cérebro que processa as mensagens.

### 2.2 Passo a passo no browser

#### Passo 1 — Acessar o dashboard de apps

Vá para **[api.slack.com/apps](https://api.slack.com/apps)** e clique em **"Create New App"**.

#### Passo 2 — Escolher "From an app manifest"

Na tela de criação, selecione:

```
○ From scratch    (criação manual — mais passos)
● From an app manifest   ← ESCOLHA ESTA OPÇÃO
```

O **manifest** é um arquivo JSON que declara tudo que o app precisa: nome, permissões, eventos que escuta, configurações. É a forma mais rápida e segura de configurar.

#### Passo 3 — Escolher o workspace

Selecione o workspace que você criou na seção anterior.

#### Passo 4 — Colar o JSON do manifest

Uma tela de editor aparecerá. Cole o JSON abaixo e clique em **"Next"** e depois **"Create"**.

### 2.3 Modelo de Manifest (com explicações)

```json
{
  "display_information": {
    "name": "Seu Agente",
    "description": "Descrição do seu agente — exemplo: Assistente de Operações",
    "background_color": "#1A1A2E"
  },
  "features": {
    "app_home": {
      "home_tab_enabled": false,
      "messages_tab_enabled": true,
      "messages_tab_read_only_enabled": false
    },
    "bot_user": {
      "display_name": "seu-agente",
      "always_online": true
    }
  },
  "oauth_config": {
    "scopes": {
      "bot": [
        "app_mentions:read",
        "channels:history",
        "channels:read",
        "chat:write",
        "groups:history",
        "groups:read",
        "users:read",
        "files:read",
        "files:write",
        "reactions:read",
        "reactions:write"
      ]
    },
    "pkce_enabled": false
  },
  "settings": {
    "event_subscriptions": {
      "bot_events": [
        "app_mention",
        "message.channels",
        "message.groups"
      ]
    },
    "interactivity": {
      "is_enabled": true
    },
    "org_deploy_enabled": false,
    "socket_mode_enabled": true,
    "token_rotation_enabled": false,
    "is_mcp_enabled": false
  }
}
```

#### Explicação de cada seção

| Campo | O que faz | Obrigatório modificar? |
|-------|-----------|:----------------------:|
| `display_information.name` | **Nome visível do bot no Slack.** Aparece em menções (`@Seu Agente`) | ✅ **SIM** — coloque o nome do seu agente |
| `display_information.description` | Texto curto exibido no perfil do app | ✅ **SIM** — descreva o papel do agente |
| `display_information.background_color` | Cor hexadecimal do card do app (ex: `#1A1A2E`) | 🟡 Opcional — personalize a cor |
| `features.app_home.home_tab_enabled` | Aba "Início" no perfil do bot (recomendado: false) | ❌ Deixar como está |
| `features.app_home.messages_tab_enabled` | Aba de mensagens no perfil do bot (recomendado: true) | ❌ Deixar como está |
| `features.bot_user.display_name` | **Nome de usuário do bot** (sem espaços, usado em @menções como `@seu-agente`) | ✅ **SIM** — mesmo nome do `name` mas sem espaços |
| `features.bot_user.always_online` | Se `true`, o bot aparece como online 24h | ❌ Deixar como está |

##### Scopes (oauth_config.scopes.bot)

Cada scope é uma permissão que o bot solicita:

| Scope | O que permite |
|-------|---------------|
| `app_mentions:read` | Saber quando o bot é mencionado (`@seu-agente`) |
| `channels:history` | Ler histórico de canais públicos onde o bot está |
| `channels:read` | Ver lista e metadados de canais públicos |
| `chat:write` | **Enviar mensagens como o bot** — essencial para responder |
| `groups:history` | Ler histórico de canais privados |
| `groups:read` | Ver lista e metadados de canais privados |
| `users:read` | Ver informações de usuários (nome, email) |
| `files:read` | Ler arquivos enviados nos canais |
| `files:write` | Enviar arquivos como o bot |
| `reactions:read` | Ver reações em mensagens |
| `reactions:write` | Adicionar reações a mensagens |

##### Event Subscriptions (settings.event_subscriptions.bot_events)

| Evento | Quando dispara |
|--------|----------------|
| `app_mention` | Quando alguém menciona `@seu-agente` em um canal |
| `message.channels` | Quando qualquer mensagem é enviada em canais públicos onde o bot está |
| `message.groups` | Quando qualquer mensagem é enviada em canais privados onde o bot está |

##### Outras Configurações

| Campo | O que faz |
|-------|-----------|
| `oauth_config.pkce_enabled` | Segurança OAuth (deixar `false` para Socket Mode) |
| `settings.socket_mode_enabled` | **OBRIGATÓRIO** — permite conexão via WebSocket sem expor端口 |
| `settings.interactivity.is_enabled` | Permite botões e modais interativos |
| `settings.token_rotation_enabled` | Rotação automática de tokens (deixar `false`) |
| `settings.is_mcp_enabled` | MCP (Model Context Protocol — deixar `false` por enquanto) |

> Importante: O Hermes usa **chat:write** para responder,
> **channels:history** / **groups:history** para ler contextos,
> e **app_mentions:read** + **message.im** para receber comandos.

##### Event Subscriptions (settings.event_subscriptions.bot_events)

- **`app_mention`** — O bot recebe um evento toda vez que alguém o menciona em um canal público ou privado. Ex: `@meu-agente quanto falta para o prazo?`
- **`message.im`** — O bot recebe mensagens diretas (DMs). Ex: o usuário abre uma DM com o bot e digita "relatório de hoje".

Esses dois eventos são **essenciais** para o Hermes funcionar. Sem eles, o agente não sabe quando foi chamado.

##### Socket Mode (settings.socket_mode_enabled)

**OBRIGATÓRIO para o Hermes.** Coloque como `true`.

Socket Mode faz o Slack se conectar ao seu agente via WebSocket em vez de HTTP. Vantagens:

- Sem necessidade de servidor público com SSL.
- Seu agente pode rodar no seu notebook, em um VPS, ou em qualquer lugar.
- A conexão é bidirecional e em tempo real.

---

## 3. Obter Tokens

### 3.1 Diferença entre Bot Token e App Token

Após criar o app, você precisa de **dois tokens**:

| Token | Prefixo | O que é |
|---|---|---|
| **Bot Token** | `xoxb-...` | Identifica o **bot** (o usuário robô). Usado para ler/escrever mensagens, agir no workspace |
| **App Token** | `xapp-...` | Identifica o **app** (a configuração). Usado exclusivamente para autenticar a conexão Socket Mode |

> Analogia: o Bot Token é a "carteira de motorista" do bot (permite dirigir),
> o App Token é a "chave do carro" (permite ligar o motor/Socket).

### 3.2 Onde encontrar cada token

**Bot Token:**

1. No dashboard do seu app, vá em **OAuth & Permissions**.
2. Role até **OAuth Tokens for Your Workspace**.
3. Clique em **"Install to Workspace"** (se ainda não instalou).
4. Autorize as permissões.
5. O token `xoxb-...` aparecerá. Copie e guarde com segurança.

```
  OAuth & Permissions
  ┌────────────────────────────────────────────┐
  │  OAuth Tokens for Your Workspace           │
  │                                            │
  │  ● Bot User OAuth Token                    │
  │    xoxb-SEU-BOT-TOKEN-AQUI         │
  │    [Copy]                                  │
  │                                            │
  │  ● Install to Workspace  (se não instalou) │
  └────────────────────────────────────────────┘
```

**App Token (nível de app):**

1. Vá em **Basic Information**.
2. Role até **App-Level Tokens**.
3. Clique em **"Generate Token"**.
4. Dê um nome (ex: `socket-token`).
5. Adicione o scope **`connections:write`** (obrigatório para Socket Mode).
6. Gere e copie o token `xapp-...`.

```
  Basic Information
  ┌────────────────────────────────────────────┐
  │  App-Level Tokens                         │
  │                                            │
  │  ● socket-token                            │
  │    xapp-SEU-APP-TOKEN-AQUI         │
  │    Scopes: connections:write               │
  │                                            │
  │  [Generate Token]                          │
  └────────────────────────────────────────────┘
```

### 3.3 Instalar o app no workspace

Se você ainda não instalou ao copiar o Bot Token:

1. Vá em **OAuth & Permissions**.
2. Clique em **"Install to Workspace"**.
3. Revise as permissões solicitadas.
4. Clique em **"Permitir"**.
5. Pronto — o bot agora é membro do workspace!

### 3.4 Adicionar o bot ao canal

O bot precisa ser convidado para o canal onde vai operar:

```
  No Slack, dentro do canal #agentes, digite:

  /invite @meu-agente
```

O bot aparecerá como membro do canal. Você também pode convidar via interface: clique no nome do canal > Integrações > Adicionar apps.

> Se o bot não for adicionado ao canal, ele não verá as mensagens
> (a menos que receba uma DM).

---

## 4. Configurar Tokens no Perfil Hermes

### 4.1 Estrutura de perfil do Hermes

O Hermes organiza configurações por **perfis**. Cada perfil tem:

```
~/.hermes/profiles/<nome-do-perfil>/
├── .env               ← variáveis de ambiente (tokens)
└── config.yaml        ← configurações do agente
```

Se você ainda não tem um perfil, crie:

```bash
mkdir -p ~/.hermes/profiles/meu-agente
```

### 4.2 Arquivo .env

Crie ou edite `~/.hermes/profiles/meu-agente/.env`:

```env
# ─── Slack ──────────────────────────────────────
SLACK_BOT_TOKEN=xoxb-SEU-BOT-TOKEN-AQUI
SLACK_APP_TOKEN=xapp-SEU-APP-TOKEN-AQUI
SLACK_HOME_CHANNEL=C0123456789
SLACK_REQUIRE_MENTION=true
```

| Variável | Obrigatório? | Descrição |
|---|---|---|
| `SLACK_BOT_TOKEN` | Sim | Token do bot (xoxb-...). Permite ao Hermes agir como o bot |
| `SLACK_APP_TOKEN` | Sim | Token de app (xapp-...). Usado para Socket Mode |
| `SLACK_HOME_CHANNEL` | Sim | ID do canal principal (ex: #agentes). O Hermes usa como canal padrão |
| `SLACK_REQUIRE_MENTION` | Não (default: true) | Se `true`, o bot só responde quando mencionado. Se `false`, responde a qualquer mensagem no canal |

**Como obter o ID do canal (SLACK_HOME_CHANNEL):**

No Slack, clique com o botão direito no nome do canal > **"Copiar link"**.
O link terá o formato:
```
https://minha-empresa.slack.com/archives/C0123456789
```
O ID é o trecho `C0123456789`.

> Alternativa: clique no nome do canal, vá em "Sobre" e veja o ID
> no final da página.

### 4.3 Arquivo config.yaml

Crie ou edite `~/.hermes/profiles/meu-agente/config.yaml`:

```yaml
agent:
  name: "Meu Agente"
  system_prompt: "..."  # ← será explicado na Seção 5

slack:
  bot_user_id: "U0123456789"
  bot_user_name: "meu-agente"
  home_channel: "C0123456789"
```

**Como obter o bot_user_id:**

1. No Slack, envie uma DM para o bot.
2. O Hermes (quando conectado) consegue identificar. Mas para configurar antes:
   - Acesse `api.slack.com/apps` > Seu app > **OAuth & Permissions**.
   - O `Bot User ID` aparece na seção "Bot User".
   - Ou simplesmente mencione o bot em um canal e veja o ID na URL do perfil.

---

## 5. Personalidade do Agente (system_prompt)

### 5.1 O que é system_prompt?

O **system_prompt** é a instrução fundamental que define **QUEM** o agente é, **COMO** ele pensa e **QUAL** o tom das respostas. É como o DNA da personalidade do seu assistente.

> Pense no system_prompt como o "manual de conduta" do agente.
> Tudo que ele faz é guiado por essa instrução.

### 5.2 Onde configurar

No `config.yaml` do perfil:

```yaml
agent:
  name: "Meu Agente"
  system_prompt: |
    Você é um assistente administrativo focado em organização de tarefas
    diárias da equipe. Seu tom é profissional mas amigável. Responda em
    português. Sempre que receber uma solicitação, confirme o recebimento
    e informe o prazo estimado. Use bullet points para listar itens.
    Se algo não estiver claro, peça esclarecimentos antes de agir.
```

### 5.3 Exemplos de personalidades

#### Exemplo 1 — Assistente Administrativo

```yaml
agent:
  name: "Assistente Admin"
  system_prompt: |
    Você é um assistente administrativo especializado em organização
    de tarefas, agenda e documentos da equipe.

    Tom de resposta: profissional, direto, educado.
    Idioma: português (pt-BR).

    Regras:
    - Sempre cumprimente quem chamou.
    - Confirme tarefas com prazo estimado.
    - Use bullet points em listas.
    - Pergunte antes de executar ações destrutivas (deletar, sobrescrever).
    - Se não souber, diga "Não sei" e ofereça ajuda alternativa.
```

#### Exemplo 2 — Analista de Dados

```yaml
agent:
  name: "Analista de Dados"
  system_prompt: |
    Você é um analista de dados especializado em gerar relatórios
    financeiros e métricas de desempenho.

    Tom de resposta: técnico, objetivo, baseado em dados.
    Idioma: português (pt-BR).

    Regras:
    - Sempre apresente dados com contexto (comparação, tendência).
    - Use tabelas para comparar resultados.
    - Se um dado estiver ausente, informe a lacuna.
    - Sugira ações baseadas nos números.
    - Prefira gráficos quando relevante (ascii ou referência a arquivo).
```

#### Exemplo 3 — Generalista (multi-função)

```yaml
agent:
  name: "Assistente Geral"
  system_prompt: |
    Você é um assistente generalista que ajuda no dia a dia da empresa.
    Você pode pesquisar informações, organizar arquivos, responder dúvidas
    e executar automações simples.

    Tom de resposta: amigável e solícito, como um colega de equipe.
    Idioma: português (pt-BR), mas entende comandos em inglês.

    Regras:
    - Para perguntas de conhecimento geral, pesquise antes de responder.
    - Se o usuário estiver frustrado, seja paciente e ajude a resolver.
    - Ofereça atalhos: "Na próxima vez, você pode pedir..."
    - Mantenha respostas curtas em canais movimentados, detalhadas em DMs.
```

### 5.4 Dicas para um bom system_prompt

1. **Seja específico** — "Você é um assistente" é vago. "Você é um assistente que organiza reuniões" é melhor.
2. **Defina o tom** — "profissional", "casual", "técnico", "amigável".
3. **Inclua regras claras** — "Nunca delete arquivos sem confirmação", "Sempre confirme antes de enviar".
4. **Exemplifique formato de resposta** — "Use bullet points", "Responda em parágrafos curtos".
5. **Limite a 300-500 palavras** — Prompts muito longos podem diluir a instrução principal.

---

## 6. Memória Permanente do Agente

### 6.1 O que é memória permanente?

Diferente de um chatbot comum que esquece tudo após a conversa, o Hermes mantém dois arquivos de memória que persistem entre sessões:

| Arquivo | Conteúdo |
|---|---|
| `MEMORY.md` | Fatos, decisões, contexto do projeto |
| `USER.md` | Perfil do usuário (nome, preferências, histórico) |

Esses arquivos ficam no diretório do perfil:

```
~/.hermes/profiles/meu-agente/
├── .env
├── config.yaml
├── MEMORY.md       ← fatos que o agente lembra
└── USER.md         ← perfil do usuário
```

### 6.2 Como funciona na prática

O agente usa a ferramenta (**tool**) `memory` para:

- **Salvar** informações: `memory save "O usuário prefere relatórios em PDF"`.
- **Consultar** informações: `memory read` (lê ambos os arquivos).

Toda vez que o agente inicia uma sessão, ele lê `MEMORY.md` e `USER.md` automaticamente. É como se ele "acordasse" lembrando de tudo que foi registrado.

### 6.3 O que salvar no MEMORY.md

```
~/.hermes/profiles/meu-agente/MEMORY.md
```

Exemplo de conteúdo:

```markdown
# Memória do Agente

## Decisões Tomadas
- Relatórios semanais devem ser gerados toda segunda-feira às 9h.
- Backup automático configurado para pastas críticas.

## Contexto do Projeto
- Projeto ativo: Migração de servidor (prazo: 30/06).
- Contato técnico: João (joao@empresa.com).

## Preferências de Formatação
- Relatórios em PDF com logo da empresa.
- Respostas no Slack com emojis de status (✅ concluído, ❌ erro).
```

### 6.4 O que salvar no USER.md

```markdown
# Perfil do Usuário

## Identificação
- Nome: Maria Silva
- Cargo: Gerente de Operações
- Fuso horário: UTC-3 (Brasília)

## Preferências
- Idioma: Português (pt-BR)
- Tom de resposta: Formal
- Formato de relatório: PDF, enviado por e-mail
- Horário de trabalho: 8h às 18h (não enviar notificações fora disso)

## Histórico
- 01/06: Solicitou dashboards semanais de vendas.
- 05/06: Pediu para testar nova skill de agendamento.
```

### 6.5 Dicas de uso da memória

- **Revisite periodicamente** — Peça ao agente: "O que você sabe sobre mim?" Ele lê os arquivos e responde.
- **Atualize quando mudar** — Se uma preferência mudar, o usuário pode pedir: "Atualize minha memória: agora prefiro relatórios em Excel."
- **Não salve tudo** — Apenas o que for relevante para o médio/longo prazo. Detalhes de uma única conversa são melhor deixados no histórico do chat.

---

## 7. Criando Múltiplos Agentes

### 7.1 Cada agente precisa de...

| Componente | Por quê |
|---|---|
| Perfil próprio | Cada perfil tem seu `.env`, `config.yaml`, memória |
| Slack App próprio | Cada app tem seu token, nome, permissões |
| Personalidade própria | Cada system_prompt define um papel diferente |
| (Opcional) Canal próprio | Pode separar por assunto ou manter todos no mesmo canal |

### 7.2 Estrutura de pastas para múltiplos agentes

```
~/.hermes/profiles/
├── agente-admin/
│   ├── .env              ← tokens do Slack App "Assistente Admin"
│   ├── config.yaml       ← system_prompt: admin
│   ├── MEMORY.md
│   └── USER.md
│
└── agente-dev/
    ├── .env              ← tokens do Slack App "Assistente Dev"
    ├── config.yaml       ← system_prompt: desenvolvedor
    ├── MEMORY.md
    └── USER.md
```

### 7.3 No mesmo canal ou canais separados?

```
Mesmo canal (#agentes)              Canais separados
─────────────────────────           ─────────────────────────
#agentes                            #admin  +  #dev
│                                   │            │
├─ @admin: relatório                @admin:      @dev:
├─ @dev: deploy agora               "relatório"  "deploy"
└─ (confuso se muitos agentes)      (organizado, cada um no seu)
```

**Recomendação:** Comece com o mesmo canal. Se ficar confuso, crie canais separados.

### 7.4 Nomes únicos para cada Slack App

No manifesto de cada app, use nomes diferentes:

| App | `display_information.name` | `display_name` |
|---|---|---|
| Admin | "Assistente Admin" | `assistente-admin` |
| Dev | "Assistente Dev" | `assistente-dev` |

Isso evita confusão visual e conflitos de @menção.

### 7.5 Compartilhando o workspace

Todos os agentes podem compartilhar o **mesmo workspace**. Não há limite no plano Free para quantidade de bots (apenas para apps conectados: 10).

---

## 8. Checklist Pós-Configuração

Use esta lista para verificar se tudo está funcionando:

```
[ ] Slack App criado com manifest (api.slack.com/apps)
[ ] Tokens copiados para .env do perfil
[ ] Bot adicionado ao canal (/invite @meu-agente)
[ ] Gateway iniciado (hermes --profile meu-agente gateway run)
[ ] TESTE: Mencionar @meu-agente no canal
[ ] TESTE: Enviar DM para o bot
[ ] Personalidade configurada no system_prompt
[ ] MEMORY.md criado com fatos iniciais
[ ] USER.md criado com perfil do usuário
```

### Teste rápido

Após iniciar o gateway:

```bash
hermes --profile meu-agente gateway run
```

Você deve ver logs parecidos com:

```
[INFO] Conectado ao Slack via Socket Mode
[INFO] Bot @meu-agente ouvindo em #agentes
[INFO] Aguardando mensagens...
```

No Slack, digite:

```
@meu-agente olá, está funcionando?
```

O bot deve responder.

---

> **Próximo passo:** Consulte `04-GUIA-SKILLS.md` para adicionar habilidades
> ao seu agente, ou `05-PERSONALIZACAO.md` para ajustes finos de
> comportamento.
