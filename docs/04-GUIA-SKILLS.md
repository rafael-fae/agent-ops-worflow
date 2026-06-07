# Guia de Skills — Agent Ops Workflow

> Referência completa para skills do Hermes Agent: o que são, como carregá-las,
> como adaptá-las e criá-las, e como solucionar problemas. Este guia cobre
> todas as skills do repositório sanitizado.

---

## Sumário

1. [O que é uma Skill Hermes?](#o-que-é-uma-skill-hermes)
2. [Anatomia de uma Skill](#anatomia-de-uma-skill)
3. [O Sistema de Placeholders](#o-sistema-de-placeholders)
4. [Como Carregar Skills](#como-carregar-skills)
5. [Tabela de Referência Completa de Skills](#tabela-de-referência-completa-de-skills)
6. [Como Adaptar Skills para Seu Time](#como-adaptar-skills-para-seu-time)
7. [Como Criar Novas Skills](#como-criar-novas-skills)
8. [Melhores Práticas](#melhores-práticas)
9. [Solução de Problemas](#solução-de-problemas)

---

## O que é uma Skill Hermes?

Uma skill Hermes é um documento processual reutilizável — um arquivo markdown
(ou um diretório de arquivos) que ensina um agente como executar uma tarefa
específica. Pense nela como um **playbook** ou **procedimento operacional
padrão** que um agente pode carregar em tempo de execução.

Skills são os blocos de construção da inteligência do agente no Agent Ops
Workflow. Em vez de programar comportamento de agente em Python ou JavaScript,
você escreve skills em markdown usando linguagem natural, seções estruturadas
e variáveis `{{PLACEHOLDER}}` que são substituídas pelos valores reais do seu
time.

### Por que Skills em vez de Código?

| Aspecto | Skills (Markdown) | Scripts (Código) |
|---------|-------------------|------------------|
| **Criação** | Escreva em qualquer editor de texto | Requer conhecimento de programação |
| **Leitura** | Humanos e agentes leem igualmente bem | Humanos precisam interpretar código |
| **Versionamento** | Texto simples no git, diffs fáceis | Funciona, mas mais difícil de revisar |
| **Adaptação** | Substitua placeholders, pronto | Precisa de refatoração |
| **Escopo** | Uma operação autocontida | Pode ser qualquer lógica programável |
| **Execução** | Carregada pelo agente em tempo de execução | Executa via CLI ou cron |

### Quando Escrever uma Skill vs. um Script

- **Escreva uma skill** quando um humano daria as mesmas instruções toda vez —
  checklists de deploy, procedimentos de auditoria, workflows de solução de problemas.
- **Escreva um script** quando a operação é puramente computacional — manipulação
  de arquivos, chamadas de API, processamento de dados que não precisa de
  julgamento do agente.

Os dois podem trabalhar juntos: uma skill pode referenciar e invocar um script.

---

## Anatomia de uma Skill

Toda skill Hermes tem no mínimo um arquivo `SKILL.md`. Skills complexas podem
também incluir um diretório `references/` com documentos de suporte, e
opcionalmente um diretório `scripts/` com helpers executáveis.

### A Estrutura do Arquivo SKILL.md

```yaml
---
name: minha-skill                      # Identificador único (kebab-case)
description: Resumo em uma linha       # O que esta skill faz
category: operacao                     # Categoria de agrupamento
---
```

Após o frontmatter YAML, um `SKILL.md` sanitizado inclui um cabeçalho de
comentário:

```markdown
<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/04-GUIA-SKILLS.md para instruções completas.
-->
```

Depois o corpo segue, organizado em seções:

```
# Título da Skill — Breve Subtítulo

## Gatilho

Condições que iniciam esta skill (comandos humanos, eventos do sistema).

---

## Pré-requisitos

O que deve estar em vigor antes de usar esta skill.

---

## Procedimento Passo a Passo

Instruções numeradas que o agente segue.

---

## Verificação

Como confirmar que a skill foi executada corretamente.

---

## Armadilhas

Problemas conhecidos, casos extremos e como evitá-los.

---

## Referências

Links para arquivos de suporte no diretório `references/`.
```

### Exemplos de Layout de Diretório

**Skill simples (arquivo único):**
```
skills/
└── minha-skill/
    └── SKILL.md
```

**Skill complexa (múltiplos arquivos):**
```
skills/
└── minha-skill/
    ├── SKILL.md                    # Ponto de entrada
    ├── references/
    │   ├── guia-de-arquitetura.md
    │   ├── comandos-de-troubleshooting.md
    │   └── config-exemplo.yaml
    └── scripts/
        ├── deploy.sh
        └── verify.py
```

O agente lê `SKILL.md` primeiro. Se a skill referenciar arquivos em
`references/` ou `scripts/`, espera-se que o agente também os leia.

---

## O Sistema de Placeholders

Skills usam **chaves duplas** `{{PLACEHOLDER}}` para variáveis que devem ser
substituídas pelos valores reais do seu time. Isso é intencional — distingue
placeholders de skill de placeholders de template, que usam sublinhados duplos
`__PLACEHOLDER__`.

### Placeholders Padrão

| Placeholder | Significado | Exemplo de Valor |
|-------------|-------------|------------------|
| `{{PROJECT_PATH}}` | Caminho absoluto para o projeto | `/home/alice/meu-projeto` |
| `{{PROJECT_NAME}}` | Nome legível do projeto | `Projeto Atlas` |
| `{{PROJECT_SLUG}}` | Identificador seguro para URL | `projeto-atlas` |
| `{{TEAM_NAME}}` | Identificador do time | `Time Nova` |
| `{{COMMANDER}}` | Nome do comandante humano | `Alice` |
| `{{COMMANDER_NAME}}` | Nome completo | `Alice Silva` |
| `{{COMMANDER_HOME}}` | Home dir do comandante | `/home/alice` |
| `{{COMMANDER_HERMES_PATH}}` | Caminho Hermes do comandante | `/home/alice/.hermes` |
| `{{ORCHESTRATOR}}` | Nome do agente orquestrador | `Nova` |
| `{{BACKEND_ENGINEER}}` | Nome do agente backend | `Atlas` |
| `{{FRONTEND_ENGINEER}}` | Nome do agente frontend | `Orion` |
| `{{DEVOPS_ENGINEER}}` | Nome do agente DevOps | `Phoenix` |
| `{{AUDITOR}}` | Nome do agente auditor | `Vega` |
| `{{GIT_OPS}}` | Nome do agente de operações git | `Gitbot` |
| `{{SLACK_CHANNEL_TEAM}}` | Canal Slack do time | `#agent-ops-nova` |
| `{{SLACK_CHANNEL_WAR_ROOM}}` | Canal multi-time | `#war-room` |
| `{{SLACK_CHANNEL_TEAM_ID}}` | ID do canal (prefixo C) | `C0123456789` |
| `{{SLACK_ID_ORCHESTRATOR}}` | ID Slack do orquestrador | `U0123456789` |
| `{{SLACK_ID_BACKEND}}` | ID Slack do backend | `U9876543210` |
| `{{BLOG_URL}}` | URL do blog ou documentação | `https://blog.exemplo.com` |
| `{{CONTACT_EMAIL}}` | Email de contato | `alice@exemplo.com` |
| `{{GITHUB_USERNAME}}` | Usuário do GitHub | `alice-silva` |

### Regras de Convenção de Placeholders

1. **Sempre substitua antes do primeiro uso.** Uma skill com `{{PLACEHOLDER}}`
   brutos não funcionará corretamente — o agente verá texto literal do placeholder.
2. **Mantenha substituições consistentes.** Se `{{ORCHESTRATOR}}` é `Nova` em uma
   skill, deve ser `Nova` em todas as skills.
3. **Não aninhe placeholders.** `{{TEAM_NAME_UPPER}}` é derivado, não aninhado.
4. **Skills usam `{{ }}`; Templates usam `__ __`.** Nunca misture os dois sistemas.

---

## Como Carregar Skills

O Hermes fornece dois comandos para trabalhar com skills:

### Inspecionar uma Skill (Sem Carregar)

Antes de ativar uma skill, inspecione-a para entender o que ela faz:

```bash
hermes skill_view caminho/para/skill/SKILL.md
```

Isso exibe o conteúdo da skill para que você (ou o agente) possa avaliá-la
antes de se comprometer a carregá-la.

### Carregar e Ativar uma Skill

```bash
hermes skill_manage add caminho/para/skill/SKILL.md
```

Isso registra a skill no registro de skills do agente. Uma vez carregada, o
agente pode invocar a skill por nome ou condição de gatilho.

### Verificar Skills Carregadas

```bash
# Listar todas as skills carregadas
hermes skill_manage list
```

### Onde Armazenar Skills

Skills podem viver em qualquer lugar no sistema de arquivos. A convenção
recomendada é:

```
projeto/
└── skills/
    └── nome-da-categoria/
        ├── SKILL.md
        └── references/
```

O `skills_dir` da sua configuração Hermes aponta para a raiz desta árvore:

```yaml
profiles:
  nova-orch:
    skills_dir: ~/meu-projeto/skills/
```

### Ordem de Carregamento de Skills

Quando um agente recebe uma tarefa, ele busca skills carregadas nesta ordem:

1. Skills explicitamente invocadas pelo orquestrador (por nome)
2. Skills que correspondem à descrição da tarefa (correspondência semântica frouxa)
3. Todas as skills carregadas como contexto (se nenhuma correspondência explícita)

Para melhores resultados, referencie o nome da skill explicitamente em mensagens
de delegação.

---

## Tabela de Referência Completa de Skills

O repositório inclui 43 skills sanitizadas organizadas em 3 categorias. Todas
as skills foram processadas para substituir valores específicos do time por
tokens `{{PLACEHOLDER}}`.

### Categoria: operacao (Operações) — 30 skills

| # | Nome da Skill | Descrição | Complexidade |
|---|--------------|-----------|--------------|
| 1 | `planejamento-diario` | Sistema de planejamento diário — fluxo completo de 6 fases: planejar, aprovar, delegar, executar, auditar, reportar | Alta |
| 2 | `mandos-operacao-cerebro-pycode` | Operações Cerebro — coordenação de agentes, gerenciamento de toolset, vault design system | Alta |
| 3 | `execucao-wave-auditoria` | Execução de wave e protocolo de auditoria — verificação por tarefa, atualizações de índice/plano | Média |
| 4 | `orquestracao-refinamento-multi-modelo` | Orquestração e refinamento multi-modelo — seleção de motor, divisão de tarefas | Média |
| 5 | `re-audit-consolidation` | Workflow de re-auditoria — consolidação de tarefas corrigidas, verificação cruzada | Média |
| 6 | `diagnostico-agentes-mudos-slack` | Diagnosticar agentes silenciosos — verificações de gateway, validação de token Slack, erros WebSocket | Alta |
| 7 | `diagnostico-interrupcoes-agentes` | Diagnosticar interrupções de agentes — análise de crash, inspeção de logs, recuperação | Média |
| 8 | `diagnostico-evolution-api` | Diagnóstico de Evolution API — problemas de webhook, solução de problemas de conexão | Média |
| 9 | `docs-governance-organization` | Governança de documentação — auditoria de pastas, sistema de três camadas, verificação cruzada | Média |
| 10 | `slack-app-creation-hermes` | Criar apps Slack para Hermes — templates de manifesto, escopos OAuth, Socket Mode | Baixa |
| 11 | `cli-tools-agent-setup` | Configuração de ferramentas CLI para agentes — OpenCode, Claude Code, Gemini CLI | Baixa |
| 12 | `gemini-vision-analysis` | Análise de imagem via Gemini Vision — inspeção de screenshot, auditoria visual | Baixa |
| 13 | `gemini-vault-fusion` | Fusão Gemini + Obsidian vault — geração de notas com IA | Média |
| 14 | `opencode-api-key-fallback` | Fallback de chave API OpenCode — lidando com limites de taxa, rotação de chaves | Baixa |
| 15 | `opencode-go-api-key-fallback` | Fallback de chave API OpenCode Go — lógica de retry específica por motor | Baixa |
| 16 | `m4-mac-team-clone-sync` | Clonar equipe Hermes de OVH para Mac — sincronização bidirecional, configuração de perfil | Alta |
| 17 | `equipe-m4-clone-local` | Clone local de equipe Mac — equipe autocontida no macOS | Média |
| 18 | `multi-team-hermes-architecture` | Isolamento multi-time — isolamento de perfil, PM2, systemd, roteamento | Alta |
| 19 | `hermes-whatsapp-native` | Integração nativa com WhatsApp — ponte Evolution API, roteamento de mensagens | Média |
| 20 | `git-vault-agent-pattern` | Agente utilitário Git-Vault — versionamento git dedicado para Obsidian vault | Baixa |
| 21 | `prd-clone-exhaustivo` | Metodologia de clone exaustivo de PRD — módulo por módulo, página por página, campo por campo | Alta |
| 22 | `clone-build-orchestration` | Orquestração de clone build — provisionamento de infra, configuração Django, deploy | Média |
| 23 | `sistema-legado-api-endpoints` | Referência de endpoints da API do sistema legado — documentação de integração | Baixa |
| 24 | `sistema-legado-relatorios-mapeamento` | Mapeamento de relatórios do sistema legado — geração de relatórios e extração de dados | Baixa |
| 25 | `multi-tenant-discovery-re` | Descoberta e engenharia reversa multi-tenant — análise de schema | Média |
| 26 | `server-migration-ovh` | Migração de servidor para OVH — planejamento, execução, verificação | Alta |
| 27 | `ovh-server-migration` | Migração de servidor OVH (procedimento alternativo) — método de transferência alternativo | Alta |
| 28 | `migracao-servidor-ovh` | Migração de servidor OVH (Português) — etapas detalhadas de migração | Alta |
| 29 | `infra-servidor-ovh` | Infraestrutura de servidor OVH — Nginx, Docker, PM2, segurança | Média |
| 30 | `troubleshoot-m4-ovh-sync` | Solucionar problemas de sincronização M4-OVH — falhas de rsync, conflitos git, problemas de cron | Média |

### Categoria: devops (DevOps) — 7 skills

| # | Nome da Skill | Descrição | Complexidade |
|---|--------------|-----------|--------------|
| 1 | `hermes-profiles-git-sync` | Sincronizar perfis Hermes entre máquinas via git monorepo — emancipação, cron, rsync | Alta |
| 2 | `correcao-fechamento-diario` | Corrigir erros de fechamento diário — consistência índice/plano, recálculo de contadores | Média |
| 3 | `css-production-cache-debug` | Depurar cache de produção CSS — cache-busting, invalidação de CDN | Baixa |
| 4 | `gemini-chunked-generation` | Geração fragmentada Gemini — divisão de documentos grandes, protocolo de continuação | Média |
| 5 | `evolution-v2.4-upgrade-meta-integration` | Upgrade Evolution API v2.4 — integração Meta, migração de webhook | Média |
| 6 | `github-pat-private-repos` | GitHub PAT para repositórios privados — configuração de token de granularidade fina, escopos de acesso | Baixa |
| 7 | `meta-webhook-receiver-setup` | Configuração de receiver Meta webhook — endpoint FastAPI, Cloudflare Tunnel, Nginx | Média |

### Categoria: security (Segurança) — 2 skills

| # | Nome da Skill | Descrição | Complexidade |
|---|--------------|-----------|--------------|
| 1 | `deploy-equipe-isolada` | Implantar equipe de agente isolada — isolamento de usuário Linux, separação de credenciais, PM2 | Alta |
| 2 | `auditoria-supply-chain` | Auditoria de cadeia de suprimentos — revisão de dependências, varredura de vulnerabilidades, SBOM | Média |

### Skills Não Categorizadas / Nível Superior — 4 skills

| # | Nome da Skill | Descrição | Complexidade |
|---|--------------|-----------|--------------|
| 1 | `m4-mac-team-clone-sync` | (Listada em operacao) | Alta |
| 2 | `git-vault-agent-pattern` | (Listada em operacao) | Baixa |
| 3 | `diagnostico-agentes-mudos-slack` | (Listada em operacao) | Alta |
| 4 | `prd-clone-exhaustivo` | (Listada em operacao) | Alta |

### Níveis de Complexidade Explicados

| Nível | Características | Tamanho Típico | Tempo Estimado do Agente |
|-------|-----------------|----------------|--------------------------|
| **Baixa** | Procedimento único, poucas decisões | 30-100 linhas | 5-15 minutos |
| **Média** | Múltiplos passos com ramificação, referência a arquivos externos | 100-300 linhas | 15-45 minutos |
| **Alta** | Processo multifásico, dependências significativas, alto risco | 300-800+ linhas | 1-4 horas |

---

## Como Adaptar Skills para Seu Time

Skills no repositório estão **sanitizadas** — valores específicos do time foram
substituídos por tokens `{{PLACEHOLDER}}`. Antes de usar uma skill, você deve
substituir esses placeholders pelos valores reais do seu time.

### Passo 1: Mapeie Seus Placeholders

Crie uma tabela de substituição em um arquivo chamado `PLACEHOLDER-MAP.md` na
raiz do seu projeto:

```markdown
# Mapa de Placeholders — Time Nova

| Placeholder | Valor |
|-------------|-------|
| `{{PROJECT_PATH}}` | `/home/alice/projeto-atlas` |
| `{{PROJECT_NAME}}` | `Projeto Atlas` |
| `{{TEAM_NAME}}` | `Time Nova` |
| `{{COMMANDER}}` | `Alice` |
| `{{ORCHESTRATOR}}` | `Nova` |
| `{{BACKEND_ENGINEER}}` | `Atlas` |
| `{{FRONTEND_ENGINEER}}` | `Orion` |
| `{{DEVOPS_ENGINEER}}` | `Phoenix` |
| `{{AUDITOR}}` | `Vega` |
| `{{GIT_OPS}}` | `Gitbot` |
| `{{SLACK_CHANNEL_TEAM}}` | `#agent-ops-nova` |
| `{{SLACK_CHANNEL_TEAM_ID}}` | `C0123456789` |
| `{{SLACK_ID_ORCHESTRATOR}}` | `U0123456789` |
| `{{SLACK_ID_BACKEND}}` | `U9876543210` |
| `{{SLACK_ID_FRONTEND}}` | `U5555555555` |
| `{{SLACK_ID_AUDITOR}}` | `U4444444444` |
| `{{SLACK_ID_DEVOPS}}` | `U3333333333` |
| `{{SLACK_ID_GITOPS}}` | `U2222222222` |
| `{{BLOG_URL}}` | `https://blog.time-nova.com` |
| `{{CONTACT_EMAIL}}` | `alice@time-nova.com` |
| `{{GITHUB_USERNAME}}` | `alice-nova` |
```

### Passo 2: Copie Skills para Seu Projeto

Não modifique skills no diretório `agent-ops-workflow/files/skills/sanitized/`
— esses são a fonte da verdade. Copie-os para o diretório de skills do seu
projeto:

```bash
mkdir -p ~/meu-projeto/skills
cp -r ~/Dev/agent-ops-workflow/files/skills/sanitized/* ~/meu-projeto/skills/
```

### Passo 3: Substitua Placeholders

Use uma substituição sistemática de localizar e substituir em todos os arquivos
de skill. Um script `sed` é a abordagem mais confiável:

```bash
# Script de substituição de placeholders
# Salve como ~/meu-projeto/scripts/substituir-placeholders.sh

SKILLS_DIR=~/meu-projeto/skills

find "$SKILLS_DIR" -name "SKILL.md" -o -name "*.md" | while read f; do
  sed -i '' \
    -e 's/{{PROJECT_PATH}}/\/home\/alice\/projeto-atlas/g' \
    -e 's/{{PROJECT_NAME}}/Projeto Atlas/g' \
    -e 's/{{TEAM_NAME}}/Time Nova/g' \
    -e 's/{{COMMANDER}}/Alice/g' \
    -e 's/{{ORCHESTRATOR}}/Nova/g' \
    -e 's/{{BACKEND_ENGINEER}}/Atlas/g' \
    -e 's/{{FRONTEND_ENGINEER}}/Orion/g' \
    -e 's/{{DEVOPS_ENGINEER}}/Phoenix/g' \
    -e 's/{{AUDITOR}}/Vega/g' \
    -e 's/{{GIT_OPS}}/Gitbot/g' \
    -e 's/{{SLACK_CHANNEL_TEAM}}/#agent-ops-nova/g' \
    -e 's/{{SLACK_CHANNEL_TEAM_ID}}/C0123456789/g' \
    -e 's/{{SLACK_ID_ORCHESTRATOR}}/U0123456789/g' \
    -e 's/{{SLACK_ID_BACKEND}}/U9876543210/g' \
    -e 's/{{SLACK_ID_FRONTEND}}/U5555555555/g' \
    -e 's/{{SLACK_ID_AUDITOR}}/U4444444444/g' \
    -e 's/{{SLACK_ID_DEVOPS}}/U3333333333/g' \
    -e 's/{{SLACK_ID_GITOPS}}/U2222222222/g' \
    -e 's/{{BLOG_URL}}/https:\/\/blog.time-nova.com/g' \
    -e 's/{{CONTACT_EMAIL}}/alice@time-nova.com/g' \
    -e 's/{{GITHUB_USERNAME}}/alice-nova/g' \
    "$f"
done
```

### Passo 4: Verifique se Não Restam Placeholders

```bash
grep -rn "{{\" ~/meu-projeto/skills/ | grep -v "\\.git" || echo "OK — nenhum placeholder restante"
```

### Passo 5: Carregue as Skills Adaptadas

```bash
# Carregue cada skill que você precisa
hermes skill_manage add ~/meu-projeto/skills/planejamento-diario/SKILL.md
hermes skill_manage add ~/meu-projeto/skills/hermes-profiles-git-sync/SKILL.md

# Verifique
hermes skill_manage list
```

### Importante: Nunca Commite Placeholders Brutos

Se você estiver publicando skills publicamente (open source), mantenha os
placeholders e deixe os usuários substituí-los. Se estas são skills internas
do time, substitua todos os placeholders antes de commitar no seu repositório
privado.

---

## Como Criar Novas Skills

Criar uma nova skill é simples. Siga este processo passo a passo.

### Passo 1: Identifique o Procedimento

Um bom candidato a skill é qualquer procedimento que:
- Um agente repete regularmente (deploy, auditoria, solução de problemas)
- Tem passos claros com verificação em cada estágio
- Pode ser documentado em 30-800 linhas
- Se beneficia do julgamento do agente (se for puramente computacional, escreva um script)

### Passo 2: Crie o Diretório da Skill

```bash
mkdir -p ~/meu-projeto/skills/minha-nova-skill/references
mkdir -p ~/meu-projeto/skills/minha-nova-skill/scripts
```

### Passo 3: Escreva o Frontmatter SKILL.md

```yaml
---
name: minha-nova-skill
description: Descrição em uma linha do que esta skill faz.
category: operacao
---
```

Escolha a categoria que melhor se encaixa:
- `operacao` — Operações gerais, planejamento, workflows de execução
- `devops` — Infraestrutura, CI/CD, deploy, git
- `security` — Auditorias, isolamento, gerenciamento de vulnerabilidades

### Passo 4: Escreva o Corpo

Use este template como ponto de partida:

```markdown
---
name: minha-nova-skill
description: Resumo breve de uma linha que diz ao agente quando usar esta skill.
category: operacao
---

# Minha Nova Skill — Subtítulo

## Gatilho

Descreva as condições que acionam esta skill. Exemplos:
- Comando humano: "execute o checklist de deploy"
- Evento: "nova pull request aberta contra main"
- Tempo: "primeira execução do dia"

---

## Pré-requisitos

O que deve estar em vigor antes de começar:
- Credenciais de acesso
- Ferramentas necessárias (liste com versões mínimas)
- Quaisquer pré-verificações a executar

---

## Procedimento

Passos numerados que o agente segue. Cada passo deve ser:
- **Verificável** — Como o agente (ou auditor) sabe que este passo está concluído?
- **Concreto** — Inclua caminhos de arquivo, comandos e saídas esperadas
- **Consequente** — Se o passo 4 falhar, o que acontece? Lógica de ramificação é aceitável.

### Passo 1: Preparação

```bash
# Exemplo de comando que o passo 1 executa
git checkout -b feature/minha-feature
```

### Passo 2: Execução

Instruções detalhadas com resultados esperados.

### Passo 3: Verificação

Como confirmar que o passo funcionou.

---

## Verificação

Checklist de verificação final — o agente executa estas verificações e reporta resultados:

- [ ] Saída esperada corresponde à saída real
- [ ] Logs não mostram erros
- [ ] Testes passam (se aplicável)
- [ ] Alterações commitadas e enviadas

---

## Rollback

Se algo der errado, como desfazer a operação:

```bash
git revert <hash>
git push
```

---

## Armadilhas

Problemas conhecidos e como evitá-los:

1. **Nome da armadilha** — Descrição e prevenção.
2. **Outra armadilha** — Descrição e prevenção.

---

## Referências

- `references/guia-detalhado.md` — Informações suplementares
- `scripts/helper.py` — Script de automação referenciado no passo 2
```

### Passo 5: Adicione Arquivos de Suporte

Se a skill precisar de documentos de referência, adicione-os a `references/`.
Se ela chamar scripts auxiliares, adicione-os a `scripts/` e torne-os executáveis.

### Passo 6: Teste a Skill

Carregue a skill em um agente sandbox e execute o procedimento:

```bash
hermes skill_manage add ~/meu-projeto/skills/minha-nova-skill/SKILL.md
hermes skill_manage list  # Verifique se carregou
```

Depois peça ao agente para executar a skill com um cenário de teste.

### Passo 7: Itere

Após testar, refine:
- Remova ambiguidades nas instruções
- Adicione etapas de verificação ausentes
- Documente novas armadilhas descobertas durante o teste
- Adicione referências a skills relacionadas

---

## Melhores Práticas

### Estrutura

1. **Um procedimento por skill.** Se uma skill tem múltiplos procedimentos não
   relacionados, divida-a em várias skills.

2. **Contexto no início.** A primeira seção após o título deve explicar
   *quando* e *por que* usar esta skill. Agentes leem isso antes dos detalhes.

3. **Use nomes de seção consistentes.** Agentes aprendem a encontrar
   informações mais rápido quando as seções seguem um padrão previsível. Use
   os mesmos nomes de seção em todas as skills (Gatilho, Pré-requisitos,
   Procedimento, Verificação, Armadilhas).

4. **Inclua critérios de saída.** Toda skill deve terminar com uma definição
   clara de concluído — como é o sucesso? Como é a falha?

### Estilo de Escrita

5. **Escreva para humanos e agentes.** Skills são lidas por ambos. Use
   linguagem clara e imperativa. Evite jargões a menos que definidos na skill.

6. **Seja concreto.** Prefira caminhos de arquivo e comandos específicos em
   vez de descrições abstratas. Um agente executa o que lê — ambiguidade leva
   a erros.

7. **Numere instruções.** Listas numeradas facilitam para agentes
   acompanharem o progresso e para auditores verificarem a conclusão.

8. **Use checklists para verificação.** Itens de checklist binários (`[ ]` / `[x]`)
   mapeiam diretamente para a capacidade do agente. São a forma mais confiável
   de confirmar a conclusão da tarefa.

### Higiene de Placeholders

9. **Sempre sanitize antes de publicar.** Se você abrir o código de uma skill,
   substitua todos os valores específicos do time por tokens `{{PLACEHOLDER}}`
   primeiro.

10. **Nunca codifique segredos.** Use `{{PLACEHOLDER}}` para credenciais, chaves
    de API e tokens — ou melhor, referencie variáveis de ambiente.

11. **Mantenha placeholders com escopo.** Uma skill não deve referenciar mais de
    15-20 placeholders. Se referenciar, considere dividi-la.

### Manutenção

12. **Revise skills trimestralmente.** Procedimentos mudam, ferramentas
    atualizam, pessoas saem. Defina um lembrete recorrente para auditar suas
    skills quanto à precisão.

13. **Versione suas skills.** Commit mudanças no SKILL.md com mensagens
    descritivas: `skill: atualizar checklist de deploy para v2.1`.

14. **Faça referência cruzada a skills relacionadas.** Se a skill A depende da
    skill B estar carregada primeiro, note isso em ambos os arquivos SKILL.md.

---

## Solução de Problemas

### Skill Não Encontrada ao ser Invocada

**Sintoma:** Agente diz "Não tenho uma skill chamada X" ou retorna resultados
não relacionados.

**Checklist:**
- [ ] Você executou `hermes skill_manage add ...`? Carregar requer um comando
      explícito.
- [ ] O caminho para `SKILL.md` está correto? `hermes skill_view caminho/para/SKILL.md`
      deve exibir o conteúdo.
- [ ] Você verificou com `hermes skill_manage list`? Execute isso para confirmar
      que a skill está registrada.
- [ ] O perfil Hermes tem o `skills_dir` correto apontando para o diretório
      pai de suas skills?

### Placeholders Não Substituídos

**Sintoma:** Agente lê texto literal `{{PLACEHOLDER}}` em sua resposta.

**Causa:** A skill foi carregada do diretório sanitizado sem substituições.

**Correção:**
```bash
# Verifique placeholders restantes
grep -rn "{{\" ~/meu-projeto/skills/ | grep -v "\\.git"

# Se algum restar, execute seu script de substituição
~/meu-projeto/scripts/substituir-placeholders.sh
```

### Agente Não Consegue Encontrar Arquivos Referenciados

**Sintoma:** Skill referencia `references/X.md` ou `scripts/Y.sh` mas o agente
reporta arquivo não encontrado.

**Checklist:**
- [ ] Os arquivos estão presentes no diretório da skill?
- [ ] O caminho de referência usa caminhos relativos (recomendado)?
- [ ] O arquivo de referência está nomeado exatamente como referenciado (case-sensitive)?
- [ ] Você copiou o diretório inteiro da skill (não apenas SKILL.md)?

### Skill Carrega mas o Agente a Ignora

**Sintoma:** A skill está listada em `hermes skill_manage list` mas o agente
não a usa durante uma tarefa relevante.

**Causas possíveis:**
- O `name` no frontmatter YAML não corresponde a como você a referencia
  em mensagens de delegação.
- A seção `Gatilho` da skill não corresponde ao contexto atual do agente.
- Outra skill carregada tem prioridade maior para o mesmo tipo de tarefa.

**Correção:** Referencie explicitamente a skill pelo nome em sua delegação:
```
Use a skill "minha-nova-skill" para esta tarefa.
```

### Performance: Muitas Skills Carregadas

**Sintoma:** Respostas do agente ficam lentas ou janelas de contexto enchem.

**Causa:** Cada skill carregada adiciona tokens de contexto. Carregar todas as
43 skills simultaneamente pode exceder limites de contexto.

**Melhor prática:** Carregue apenas as skills necessárias para as tarefas do dia.
O orquestrador pode carregar/descarregar skills dinamicamente por wave:

```bash
# Antes do dia começar, carregue skills relevantes
hermes skill_manage add skills/planejamento-diario/SKILL.md
hermes skill_manage add skills/deploy-equipe-isolada/SKILL.md

# Após o dia terminar (ou após waves que precisam delas), descarregue
hermes skill_manage remove skills/deploy-equipe-isolada/SKILL.md
```

### Conteúdo da Skill Não Renderiza Corretamente

**Sintoma:** Seções faltando, tabelas quebradas, blocos de código sem syntax highlight.

**Checklist:**
- [ ] O frontmatter YAML é válido? Certifique-se de que `name:`, `description:` e
      `category:` estão presentes e separados por `---`.
- [ ] Há blocos de código não fechados? Todo ``` deve ter um ``` de fechamento.
- [ ] As tabelas estão formatadas corretamente? Cada linha da tabela deve ter o
      mesmo número de colunas que o cabeçalho.
- [ ] Você usou caracteres `|` dentro de células de tabela? Isso quebra o parser
      da tabela — use quebras HTML `<br>` em vez disso.

### Skill Tem Informações Desatualizadas

**Sintoma:** Agente segue o procedimento mas os passos não correspondem mais ao
estado atual do sistema.

**Correção:** Atualize o arquivo da skill e recarregue:
```bash
# Edite o SKILL.md
vim ~/meu-projeto/skills/minha-skill/SKILL.md

# Recarregue (remove e adiciona novamente)
hermes skill_manage remove skills/minha-skill/SKILL.md
hermes skill_manage add skills/minha-skill/SKILL.md
```

Agende uma auditoria trimestral de skills para detectar desatualização antes
que cause problemas.

---

## Apêndice: Convenções de Nomenclatura de Arquivos de Skill

| Artefato | Convenção | Exemplo |
|----------|-----------|---------|
| Diretório da skill | `kebab-case` | `planejamento-diario/` |
| Ponto de entrada | `SKILL.md` (maiúsculo) | `SKILL.md` |
| Arquivos de referência | `kebab-case.md` | `guia-de-arquitetura.md` |
| Arquivos de script | `kebab-case.sh` ou `.py` | `deploy-skill.sh` |
| Nome YAML | `kebab-case` | `name: planejamento-diario` |

---

## Apêndice: Definições de Categoria

| Categoria | Escopo | Skills Típicas |
|-----------|--------|---------------|
| `operacao` | Operações gerais de agente, workflows diários, solução de problemas | Planejamento, diagnósticos, migração, criação de PRD |
| `devops` | Infraestrutura, CI/CD, ferramentas, controle de versão | Sincronização de perfil, configuração PAT, receivers webhook |
| `security` | Isolamento, auditorias, gerenciamento de vulnerabilidades | Implantar equipe isolada, auditoria de cadeia de suprimentos |

---

> Skills são a abstração mais poderosa no Agent Ops Workflow. Elas codificam
> expertise humana em procedimentos legíveis por agentes, tornando sua equipe
> mais inteligente a cada skill que você escreve.
