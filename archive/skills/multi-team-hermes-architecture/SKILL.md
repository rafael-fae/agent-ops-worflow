---
name: multi-team-hermes-architecture
description: "Arquitetura para criar ambientes isolados de agentes Hermes no mesmo servidor. Perfis, WhatsApp multi-numero, PM2, systemd e roteamento."
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Multi-Team Hermes Architecture — Ambiente Isolado de Agentes

## Contexto

O Hermes suporta múltiplos times de agentes isolados no mesmo servidor via **profile isolation**. Cada agente tem seu próprio `HERMES_HOME`, isolando sessão, memória, skills, e estado. Este skill documenta como criar um segundo time completo coexistindo com o time existente.

## Arquitetura de Profiles

```
{{COMMANDER_HOME}}/hermes-roshar/profiles/       ← diretório real
├── dalinar/          ← Time {{COMMANDER}} (existente)
├── navani/
├── jasnah/
├── shallan/
├── kaladin/
│
└── EQUIPE_NOIVA/                   ← NOVO: namespace isolado
    ├── .env_global                 ← variáveis prefixadas (AGENTE_SLACK_BOT_TOKEN, etc.)
    ├── orquestradora/              ← agente âncora — ÚNICA com WhatsApp
    │   ├── .env
    │   ├── config.yaml             ← whatsapp: {enabled: true, bridge_port: 3001}
    │   ├── SOUL.md / IDENTITY.md / TEAM.md
    │   ├── platforms/whatsapp/session/  ← sessão WhatsApp Web
    │   └── skills/
    ├── conselheira/                ← demais agentes (SEM WhatsApp)
    ├── guardia/
    └── artista/
```

**Princípio**: `profiles -> {{COMMANDER_HOME}}/hermes-roshar/profiles` (symlink). Cada agente tem `HERMES_HOME` apontando para seu diretório de profile.

## Isolamento — Níveis

O Hermes resolve `HERMES_HOME` via `hermes_constants.get_hermes_home()`:
- Lê env var `HERMES_HOME` ou usa `~/.hermes`
- Com `--profile <name>`, o CLI seta `HERMES_HOME=<root>/profiles/<name>`
- Todo estado (sessões, skills, cache, memories) fica isolado

### Níveis de Isolamento

| Nível | Medida | Esforço | Risco Residual |
|-------|--------|---------|----------------|
| **N0** (atual) | Mesmo user Linux, mesmo filesystem, profiles side-by-side | — | Agentes podem ler sessions/memories/tokens uns dos outros (`cat` trivial) |
| **N1** (mínimo) | Corrigir permissões (`chmod 600`) + remover `terminal` toolset | 15 min | Reduz, mas não elimina — mesmo user ainda pode ler tudo |
| **N2** (recomendado) | **Usuário Linux separado** (`useradd`) + permissões 700 no home + PM2 ou systemd rodando como esse user | 30 min | Isolamento real via DAC do Linux. Agentes do {{COMMANDER}} não conseguem `cat` nos arquivos da noiva |
| **N3** (enterprise) | Container Docker por equipe | 2h | Isolamento via namespaces |
| **N4** (máximo) | VMs separadas + rede isolada | Dias | Isolamento total |

**Recomendação para time novo: N2.** Comando base:
```bash
sudo useradd -m -s /bin/bash <novo_user>
sudo -u <novo_user> python3 -m venv /home/<novo_user>/hermes_env
# O setup_thaisa_infra.sh cria ambas as estruturas automaticamente
```

### ⚠️ Estrutura Dual de Diretórios (19/05/2026)

O deploy de equipe isolada cria DOIS conjuntos de diretórios que coexistem:

| Diretório | Função | Conteúdo |
|-----------|--------|----------|
| `/home/<user>/profiles/` | Artefatos de deploy + credenciais globais | `.env_global`, documentação, templates |
| `/home/<user>/.hermes/profiles/` | Runtime real dos agentes Hermes | `.env` individual, `sessions/`, `skills/`, `SOUL.md`, `config.yaml` |

**Pitfall:** O `.env_global` fica em `/home/<user>/profiles/.env_global` (diretório de deploy). Os `.env` individuais ficam em `/home/<user>/.hermes/profiles/<agente>/.env` (runtime). Não são o mesmo diretório. Confundir os dois paths causa "arquivo não encontrado" e falsos diagnósticos de token ausente.

### ⚠️ Contaminação de Memória Entre Equipes (M4 vs OVH)

Quando duas equipes (M4 e OVH) operam no mesmo workspace Slack com apps diferentes, as memórias dos agentes podem ser contaminadas com IDs incorretos.

**Como acontece:**
1. {{ORCHESTRATOR}}-mac menciona {{BACKEND_ENGINEER}}-OVH com o ID correto de {{BACKEND_ENGINEER}}-OVH
2. {{BACKEND_ENGINEER}}-mac (que tem app diferente mas registra o ID visto) salva na memória: "meu ID = {{SLACK_ID_OVH_BACKEND}}"
3. Mas {{BACKEND_ENGINEER}}-mac tem ID real {{SLACK_ID_BACKEND}}
4. Nas sessões seguintes, {{BACKEND_ENGINEER}}-mac age como se fosse {{BACKEND_ENGINEER}}-OVH

**Diagnóstico:**
```bash
grep "user_id\|U0B" ~/.hermes/profiles/<agente>/memories/MEMORY.md
# Comparar com o bot_user_id no config.yaml do agente
grep "bot_user_id" ~/.hermes/profiles/<agente>/config.yaml
```

**Correção completa:**
```bash
# 1. Corrigir MEMORY.md com o ID correto
# 2. Limpar cache do state.db
rm -f ~/.hermes/profiles/<agente>/state.db*
# 3. Limpar sessões antigas
rm -rf ~/.hermes/profiles/<agente>/sessions/
mkdir -p ~/.hermes/profiles/<agente>/sessions/
# 4. Reiniciar gateway
```

**Prevenção:** Incluir verificação de `memories/MEMORY.md` no checklist pós-criação. Ver também `diagnostico-agentes-mudos-slack` para procedimento completo de depuração.

### ⚠️ Mascaração de Tokens no Terminal

O terminal do Hermes mascara tokens no output. `cat` mostra `***` para strings como `xoxb-`, `xapp-`, `sk-or-`. Isto NÃO significa vazio/placeholder. Para verificar presença real: usar `xxd` (hex dump). Ver skill `infra-servidor-ovh` para procedimento completo.

### ⚠️ Edição de .env com Placeholders

Ao editar `.env` que tem placeholder `SLACK_BOT_TOKEN=***`, **substitua a linha inteira**, não concatene no final:
```
❌ SLACK_BOT_TOKEN=***xoxb-...    ← token prefixado com ***, autenticação falha
✅ SLACK_BOT_TOKEN=xoxb-...       ← substituição completa da linha
```
Este erro ocorreu em 19/05/2026 nos 4 agentes da equipe Thaísa e foi detectado por `xxd`.

### Regra de Nomenclatura: Sempre verificar colisão de nomes
Antes de batizar qualquer agente, verificar se o nome já existe no ecossistema. Nomes duplicados causam confusão em logs, menções Slack e debugging. Exemplo real: "{{AUDITOR}}" foi vetada para o time da noiva porque já existe uma {{AUDITOR}} no time do {{COMMANDER}} (`<@{{SLACK_ID_OVH_PRODUCT}}>`). Substituída por "Ash".

## WhatsApp Multi-Número

### Como funciona nativamente

O WhatsApp adapter (`gateway/platforms/whatsapp.py`) usa um **bridge Node.js** (Baileys) que:
1. Conecta ao WhatsApp Web via WebSocket
2. Expõe API HTTP em `127.0.0.1:<bridge_port>` (default 3000)
3. Salva sessão em `{HERMES_HOME}/platforms/whatsapp/session/`
4. Primeiro startup: exibe QR code para pareamento
5. Sessões subsequentes: autentica via arquivo de sessão salvo

### Dois números → duas bridges

| Número | Bridge Port | Session Path | Profile |
|--------|-------------|--------------|---------|
| {{COMMANDER}} | 3000 | `~/.hermes/profiles/dalinar/platforms/whatsapp/session/` | dalinar |
| Noiva  | 3001 | `~/.hermes/profiles/EQUIPE_NOIVA/orquestradora/platforms/whatsapp/session/` | orquestradora |

**Configuração no config.yaml da orquestradora:**
```yaml
whatsapp:
  enabled: true
  extra:
    bridge_port: 3001
    reply_prefix: "🤖 "
    require_mention: true
```

### ⚠️ NÃO confundir com Evolution API

Existe um processo separado `webhook-whatsapp` (PM2) rodando uvicorn na porta 8001 (`receptor_whatsapp.py`). Este é um receptor **legado** de webhooks do Evolution API — apenas faz log de mensagens de grupo. **Não é necessário para a integração nativa do Hermes.** A integração nativa é auto-contida via bridge Node.js.

### Limitação: 1 número por gateway

Cada `GatewayRunner` suporta **1 WhatsAppAdapter** = 1 bridge = 1 número. Para ter mais de um agente respondendo no mesmo número, use o modelo **Orquestrador + Delegação**:

```
Noiva ──WhatsApp──> [número dela] ──bridge:3001──> Orquestradora
                                                       │
                                                       │ (delegação)
                                                       ▼
                                          ┌─────────┼─────────┐
                                     Conselheira  Guardiã  Artista
                                      (Slack)    (Slack)   (Slack)
```

A orquestradora detecta menções por nome e delega para os outros agentes via Slack.

## Gerenciamento de Processos — PM2 ou systemd

O Hermes suporta dois métodos de gerenciamento. A Ponte Quatro ({{COMMANDER}}) usa PM2. A equipe Thaísa (19/05/2026) foi implantada com systemd — que se mostrou superior para isolamento N2.

### systemd (recomendado para N2 — user Linux separado)

**Vantagens sobre PM2:**
- Sobrevive reboot sem `pm2 startup` (basta `systemctl enable`)
- Isolamento real: `User=thaisa` no unit file garante que o processo RODE como o user
- Security hardening nativo: `ProtectSystem=strict`, `NoNewPrivileges=yes`, `PrivateTmp=yes`
- Logs via `journalctl` — centralizados, rotacionados, queryáveis
- `Restart=always` built-in — sem dependência de PM2 daemon

**Comando de instalação (1 por agente):**
```bash
# Para user service (padrão — recomendado para mesmo user Linux):
/home/<user>/hermes_env/bin/hermes --profile <nome> gateway install

# Exemplo real ({{GIT_OPS}}, 25/05/2026):
{{COMMANDER_HOME}}/hermes_env/bin/hermes --profile pattern gateway install
```

**⚠️ Nota sobre sintaxe:** O subcomando `gateway service install --replace` NÃO existe. A partir de Hermes v0.14+, o comando correto é `gateway install` (sem `service`, sem `--replace`). Verificar com `hermes gateway --help` antes de instalar.

Isso gera um **user service** em `~/.config/systemd/user/hermes-gateway-<profile>.service` com:
- `ExecStart=/home/<user>/hermes_env/bin/python -m hermes_cli.main --profile <nome> gateway run`
- `Environment="HERMES_HOME=<hermes_root>/profiles/<nome>"`
- `Restart=on-failure`, `RestartSec=30`
- `TimeoutStopSec=60`

**Pós-instalação (user service):**
```bash
# Habilitar linger para o serviço sobreviver a logout SSH
sudo loginctl enable-linger <user>

# Comandos (sempre com --user):
systemctl --user daemon-reload
systemctl --user enable hermes-gateway-<profile>
systemctl --user start hermes-gateway-<profile>
systemctl --user status hermes-gateway-<profile>
journalctl --user -u hermes-gateway-<profile> -f
```

**Para user Linux separado (N2 — ex: Thaísa):**
```bash
sudo -u thaisa /home/thaisa/hermes_env/bin/hermes --profile jade gateway install

# Pós-instalação:
sudo systemctl --user daemon-reload
sudo systemctl --user enable hermes-thaisa-jade
sudo systemctl --user start hermes-thaisa-jade
```

### ⚠️ TimeoutStopSec vs drain_timeout (systemd)

O `hermes gateway install` gera `TimeoutStopSec=60s`. Se o `drain_timeout` do agente for maior (ex: 180s), o systemd pode SIGKILL o processo durante desligamento. O warning aparece nos logs:
```
WARNING: Stale systemd unit detected: TimeoutStopSec=60s but drain_timeout=180s
```
Para corrigir: aumentar `TimeoutStopSec` no unit file para >= `drain_timeout + 30s`, ou reduzir `drain_timeout` no `config.yaml`. Editar manualmente:
```bash
systemctl --user edit hermes-gateway-<profile>
# Adicionar:
# [Service]
# TimeoutStopSec=210
```

### Verificação de status (systemd)
```bash
sudo systemctl is-active hermes-thaisa-jade   # → active
sudo systemctl is-enabled hermes-thaisa-jade  # → enabled
sudo journalctl -u hermes-thaisa-jade -n 20   # últimas 20 linhas de log
```

### PM2 (usado na Ponte Quatro)

### Opção A: Comandos diretos (usado em produção atualmente)

```bash
pm2 start {{COMMANDER_HOME}}/hermes_env/bin/hermes \
  --name noiva-orquestradora \
  --interpreter {{COMMANDER_HOME}}/hermes_env/bin/python \
  -- --profile EQUIPE_NOIVA/orquestradora gateway run

pm2 start {{COMMANDER_HOME}}/hermes_env/bin/hermes \
  --name noiva-conselheira \
  --interpreter {{COMMANDER_HOME}}/hermes_env/bin/python \
  -- --profile EQUIPE_NOIVA/conselheira gateway run
# ... etc
```

### Opção B: ecosystem.config.js unificado

```javascript
// {{COMMANDER_HOME}}/hermes-configs/ecosystem.config.js
{ name: "noiva-orquestradora",
  script: "{{COMMANDER_HOME}}/hermes_env/bin/hermes",
  interpreter: "{{COMMANDER_HOME}}/hermes_env/bin/python3",
  args: "--profile EQUIPE_NOIVA/orquestradora gateway run",
  env: { HERMES_HOME: "{{COMMANDER_HOME}}/hermes-roshar/profiles/EQUIPE_NOIVA/orquestradora" }
},
```

### Agentes ativos no servidor (referência)

### Ponte Quatro (PM2 — time {{COMMANDER}})
- `dalinar`, `navani`, `jasnah`, `shallan`, `kaladin` — Radiantes do {{COMMANDER}}
- `webhook-whatsapp` — receptor Evolution API legado (porta 8001)
- `quartz-cerebro` — build do site
- `fechamento-pycode` — script diário (parado)

### Agentes systemd user service
- `hermes-gateway-pattern` — {{GIT_OPS}}, guardião do vault Obsidian (25/05/2026)

Cada processo gateway consome ~150-300 MB RAM. {{GIT_OPS}} é o mais leve (~150 MB) por não ter WhatsApp, bridge, ou acesso externo.

### Perfil restrito → systemd user service

```bash
# Instalar (cria ~/.config/systemd/user/hermes-gateway-<nome>.service)
hermes --profile <nome> gateway install

# Gerenciar
systemctl --user start hermes-gateway-<nome>
systemctl --user status hermes-gateway-<nome>
journalctl --user -u hermes-gateway-<nome> -f
```

## Slack — Opções

### Opção A: Mesmo workspace, canais separados (recomendado para início)
- Criar canais `#equipe-noiva`, `#noiva-orquestradora` no workspace atual
- Cada agente ganha seu Slack Bot (Bot Token + App Token)
- `SLACK_ALLOWED_USERS` restrito à noiva + agentes do time
- Vantagem: simples, sem custo, {{COMMANDER}} pode supervisionar
- Desvantagem: menor isolamento

### Opção B: Workspace separado
- Novo workspace Slack para a noiva
- Isolamento total
- Mais trabalho de configuração

## Credenciais — Padrão 2 Camadas

Manter o padrão existente:

**Camada Global** (`.env_global` no diretório do time):
```
ORQUESTRADORA_SLACK_BOT_TOKEN=***
ORQUESTRADORA_SLACK_APP_TOKEN=***
CONSELHEIRA_SLACK_BOT_TOKEN=***
# ... etc
```

**Camada Profile** (`.env` dentro de cada agente):
```
OPENCODE_GO_API_KEY=***
SLACK_BOT_TOKEN=***
SLACK_APP_TOKEN=***
SLACK_HOME_CHANNEL=...
SLACK_REQUIRE_MENTION=true
```

## Renomeação de Agentes em Produção (Zero Downtime)

### Gatilho
- Renomear agentes de uma equipe Hermes (ex: Stormlight → Senhor dos Anéis)
- Migração cosmética — personalidades e funções permanecem as mesmas
- Pode ser feito em um ambiente (OVH) e espelhado no outro (Mac)

### Princípios
1. **Slack IDs são permanentes.** Apenas `display_name` no manifest muda. `bot_user_id` no `config.yaml` NÃO muda.
2. **`state.db` é preservado.** Memórias e continuidade de sessão intactas.
3. **Renomear diretórios de profile** — o nome do diretório é o identificador do agente para PM2/systemd/launchctl.
4. **Atualizar referências cross-team** — o outro time (Mac ou OVH) precisa atualizar AGENTS.md, TEAM.md, SOUL.md com os novos nomes.
5. **Fazer todas as alterações de uma vez.** Só reiniciar gateways DEPOIS de tudo pronto. Reiniciar no meio do processo causa interrupção e estado inconsistente.

### Procedimento (OVH — executado com sucesso em 29/05/2026)

1. **Definir mapeamento** — nomes antigos → novos, mantendo equivalência funcional:

| Antigo (Stormlight) | Novo (LOTR) | Papel |
|---|---|---|
| {{ORCHESTRATOR}} | Aragorn | General, Orquestrador |
| {{BACKEND_ENGINEER}} | Celebrimbor | Backend, Arquiteta |
| {{AUDITOR}} | Elrond | PRD, Produto, Auditoria |
| {{DEVOPS_ENGINEER}} | Éomer | DevOps, Sprint, Tática |
| {{FRONTEND_ENGINEER}} | Galadriel | Frontend, Design, UI/UX |
| {{GIT_OPS}} | Gandalf | Vault, Git, Obsidian |

2. **Alterar SOUL.md, IDENTITY.md, TEAM.md, MEMORY.md** — trocar nome antigo → novo em cada profile.

3. **Renomear diretórios de profile:**
   ```bash
   cd {{COMMANDER_HERMES_PATH}}/profiles
   mv dalinar aragorn
   mv navani celebrimbor
   mv jasnah elrond
   mv kaladin eomer
   mv shallan galadriel
   mv pattern gandalf
   ```

4. **Atualizar PM2 ecosystem.config.js** — trocar nomes de processos e paths.

5. **Atualizar AGENTS.md raiz** no monorepo com a nova tabela.

6. **Slack:** Alterar `display_name` nos manifests dos apps Slack e reinstalar.

7. **Reiniciar gateways** (só depois de tudo pronto).

### Procedimento (Mac — espelhamento pós-OVH)

⚠️ **Referência:** Relatório completo da migração OVH em `~/Dev/RELATORIO-MIGRACAO-OVH-LOTR.md` (redigido por Aragorn em 29/05/2026). Contém o mapeamento completo de personagens, passo a passo, e checklist de verificação para a equipe Mac.

Quando a OVH migrou primeiro, a equipe Mac precisa:

1. **Remover sufixo "-mac"** e assumir nomes Stormlight originais:
   - `dalinar-mac` → `dalinar`, `navani-mac` → `navani`, etc.

2. **⚠️ Substituir TODOS os IDs OVH → Mac** nos arquivos de identidade. Este é o passo mais crítico — a renomeação de diretórios é cosmética, mas IDs errados fazem o agente se identificar como outro bot (ex: {{ORCHESTRATOR}} Mac responde como Aragorn). Ver `equipe-m4-clone-local` → "Pitfall Crítico: Contaminação Completa de Identidade".

3. **Atualizar referências à equipe OVH** em todos os arquivos:
   - "{{ORCHESTRATOR}}" (mencionando OVH) → "Aragorn (OVH)"
   - "Ponte Quatro" → "Sociedade do Anel"
   - IDs OVH (`U0B1*`, `{{SLACK_ID_OVH_ORCHESTRATOR}}`) só devem aparecer em contexto cross-team

3. **Renomear diretórios e launchctl plists** — mesmo padrão do OVH.

4. **Pull do git** para receber AGENTS.md atualizado.

### ⚠️ Regra Crítica
> **NÃO REINICIE O AGENTE DURANTE O PROCESSO.** Faça todas as alterações primeiro, reinicie gateways só depois. Reiniciar no meio causa interrupção do processo de migração e pode deixar o estado inconsistente.

### Verificação
- [ ] `state.db` intacto (memórias preservadas)
- [ ] Slack IDs inalterados (verificar com `/auth.test`)
- [ ] Diretórios renomeados
- [ ] PM2/systemd/launchctl apontando para novos paths
- [ ] Cross-team references atualizadas no outro ambiente
- [ ] Gateways respondendo com novos nomes

## Checklist de Implementação

1. **Adquirir chip/linha adicional** para o novo número WhatsApp (pré-requisito)
2. **Criar diretórios** de profile para cada agente da noiva
3. **Escrever SOUL.md, IDENTITY.md, TEAM.md** para cada agente (personalidades próprias)
4. **Configurar .env** com tokens Slack e API keys
5. **Criar 4 apps Slack Bot** (orquestradora, conselheira, guardiã, artista)
6. **Configurar config.yaml** da orquestradora com `whatsapp.enabled: true` e `bridge_port: 3001`
7. **Ligar PM2** para orquestradora primeiro, parear QR code WhatsApp
8. **Ligar PM2** para demais agentes
9. **Testar** fluxo WhatsApp → orquestradora → delegação → Slack → resposta

## Firewall (UFW)

Nenhuma alteração necessária. Bridges WhatsApp são estritamente locais (`127.0.0.1`). Apenas porta 8001 exposta (webhook Evolution legado).

## Pitfalls

- **Portas**: Garantir que `bridge_port` da noiva (3001) não conflite com a do {{COMMANDER}} (3000)
- **QR Code**: O pareamento expira em ~20s. Ter celular pronto para escanear ao ligar a bridge pela primeira vez
- **Sessão WhatsApp**: Se a sessão expirar (raro, mas acontece), deletar `platforms/whatsapp/session/` e re-parear
- **Rate limit OpenCode Go**: Ambos os times podem compartilhar a mesma API key — monitorar rate limits
- **Memória**: +4 agentes = +~1 GB RAM. Verificar RAM disponível no servidor OVH antes de ligar
- **webhook-whatsapp legado**: Não desligar — ele alimenta `hoje.md` com logs de grupo. É independente do Hermes nativo
- **Estrutura de diretórios duplicada**: No modelo N2, o `hermes setup --non-interactive` cria os perfis em `/home/<user>/.hermes/profiles/` (padrão do Hermes). O diretório `/home/<user>/profiles/` é criado separadamente para artefatos de deploy (`.env_global`, `ecosystem.config.js`, `team-protocolo.md`). São paths diferentes. Verificar o path correto antes de diagnosticar "arquivo não encontrado". (Descoberto 19/05/2026 — {{ORCHESTRATOR}} perdeu 30min procurando `.env` no path errado.)
- **Filtro de segurança mascara tokens**: O output de `cat`/`grep` no terminal substitui padrões de token (`xoxb-`, `xapp-`, `sk-`) por `***`. Tokens podem estar presentes mesmo que o display mostre `***`. Usar `xxd` para verificação binária. (Descoberto 19/05/2026 — horas perdidas caçando tokens "faltantes" que estavam lá.)
