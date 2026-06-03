<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://img.shields.io/badge/status-active-2ea043?style=for-the-badge">
    <img alt="Agent Ops Workflow" src="https://img.shields.io/badge/status-active-2ea043?style=for-the-badge">
  </picture>
  <img alt="Licença: MIT" src="https://img.shields.io/badge/licença-MIT-blue?style=for-the-badge">
  <img alt="Versão: v1.0.0" src="https://img.shields.io/badge/versão-v1.0.0-8250df?style=for-the-badge">
  <img alt="Hermes Agent" src="https://img.shields.io/badge/feito%20para-Hermes%20Agent-ff6b35?style=for-the-badge">
</p>

<h1 align="center">🤖 Agent Ops Workflow</h1>
<h3 align="center">Planejamento Diário Multi-Agente para Hermes</h3>

<p align="center">
  <strong><a href="README-en.md">📖 Read in English</a></strong>
</p>

<p align="center">
  Um workflow de planejamento diário testado em produção para equipes de agentes de IA rodando no <strong>Hermes</strong>.<br>
  Planeje. Aprove. Delegue. Execute. Audite. Reporte. — todos os dias, em ciclo.
</p>

<p align="center">
  <a href="#-quickstart">Quickstart</a> •
  <a href="#-o-problema">O Problema</a> •
  <a href="#-a-solução">A Solução</a> •
  <a href="#-funcionalidades">Funcionalidades</a> •
  <a href="#-estrutura-do-repositório">Estrutura</a> •
  <a href="#-para-quem">Para Quem</a>
</p>

---

## 🧠 O Problema

Agentes de IA **não têm memória persistente entre sessões**. Toda vez que uma conversa começa, é uma tábula rasa — sem contexto, sem noção do que aconteceu ontem, sem compreensão do panorama geral. Sem um sistema externo de orquestração, equipes de agentes sofrem com:

- **Contexto perdido** — decisões de ontem desaparecem da noite para o dia
- **Trabalho duplicado** — múltiplos agentes resolvendo o mesmo problema sem saber
- **Motores inconsistentes** — o modelo errado é usado para a tarefa errada
- **Sem trilha de auditoria** — quem fez o quê, quando e por quê? Ninguém sabe
- **Progresso disperso** — não existe uma fonte única da verdade

Em operações multi-agente, esses problemas se multiplicam exponencialmente. Você precisa de um **sistema**, não apenas de bons prompts.

---

## 🔁 A Solução

O **Agent Ops Workflow** é um ciclo diário estruturado e repetível que dá à sua equipe de agentes Hermes um sistema operacional compartilhado. Simples por design, rigoroso por convenção.

### O Ciclo de 6 Fases

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│ PLANEJAR │ ──→ │ APROVAR  │ ──→ │ DELEGAR  │
└──────────┘     └──────────┘     └──────────┘
                                         │
                                         ▼
┌──────────┐     ┌──────────┐     ┌──────────┐
│ REPORTAR │ ←── │ AUDITAR  │ ←── │ EXECUTAR │
└──────────┘     └──────────┘     └──────────┘
```

| Fase | O que acontece |
|------|---------------|
| **📋 Planejar** | O orquestrador cria um plano diário (`PLANO.md`) com waves, tarefas, prioridades e dependências |
| **✅ Aprovar** | Um humano (ou agente líder) revisa e autoriza o plano antes da execução |
| **🎯 Delegar** | As tarefas são atribuídas a agentes específicos via Slack ou canal direto — um agente, uma tarefa |
| **⚡ Executar** | Cada agente executa sua tarefa com o motor designado, seguindo instruções detalhadas |
| **🔍 Auditar** | Um agente diferente verifica cada tarefa concluída para garantir qualidade e corretude |
| **📊 Reportar** | Os resultados são registrados, o índice é atualizado e o progresso é commitado para o próximo ciclo |

O ciclo se repete diariamente. Cada dia começa a partir do relatório do dia anterior, criando uma corrente contínua de contexto.

---

## 🚀 Quickstart

Coloque sua equipe para funcionar em menos de 60 segundos.

```bash
# 1. Clone o repositório
git clone https://github.com/rafael-fae/agent-ops-worflow.git
cd agent-ops-workflow

# 2. Execute o setup interativo
./scripts/setup-workflow.sh ~/meu-projeto "{{TEAM_NAME}}" "{{PROJECT_NAME}}"

# 3. Revise e personalize seu primeiro plano diário
open planejamento-diario/$(date +%Y-%m-%d)/PLANO.md

# 4. (Opcional) Agende a geração automática via cron
crontab -e
# Adicione: 0 5 * * * /caminho/scripts/gerar-plano-diario.sh ~/meu-projeto --tasks=5
```

Pronto. Sua equipe agora tem um sistema de planejamento diário. Personalize os templates, adicione seus agentes e comece a produzir.

---

## 📁 Estrutura do Repositório

```text
agent-ops-workflow/
│
├── planejamento-diario/        # 📅 Nosso workflow funcionando nele mesmo
│   ├── INDICE.md               # Índice mestre com progresso
│   ├── 2026-06-03/             # Nosso plano de criação do repositório
│   │   ├── PLANO.md
│   │   ├── task_01.md
│   │   └── ...
│   └── TEMPLATE_PLANO.md
│
├── docs/                       # 📖 Documentação principal (🇧🇷 pt-BR)
│   ├── 01-CONFIGURACAO-INICIAL.md
│   ├── 02-CICLO-DIARIO.md
│   ├── 03-PROTOCOLO-SLACK.md
│   ├── 04-GUIA-SKILLS.md
│   ├── 05-PERSONALIZACAO.md
│   └── 06-REFERENCIA-RAPIDA.md
│
├── docs/en/                    # 🌐 Documentação em inglês (🇺🇸 en-US)
│   ├── 01-SETUP-INITIAL.md
│   ├── 02-DAILY-CYCLE.md
│   ├── 03-SLACK-PROTOCOL.md
│   ├── 04-SKILLS-GUIDE.md
│   ├── 05-CUSTOMIZATION.md
│   └── 06-QUICK-REFERENCE.md
│
├── templates/                  # 📄 Templates oficiais (🇧🇷 pt-BR)
│   ├── PLANO.md.tpl
│   ├── TASK.md.tpl
│   ├── INDICE.md.tpl
│   └── README-WORKFLOW.md.tpl
│
├── templates/en/               # 🌐 Templates em inglês (🇺🇸 en-US)
│   ├── PLANO.md.tpl
│   ├── TASK.md.tpl
│   ├── INDICE.md.tpl
│   └── README-WORKFLOW.md.tpl
│
├── skills/                     # 🧠 Skills Hermes (sanitizadas, 43 skills)
│   ├── operacao/               # Skills operacionais (29)
│   ├── devops/                 # Skills de DevOps (5)
│   ├── security/               # Skills de segurança (2)
│   └── ...                     # + skills avulsas (7)
│
├── scripts/                    # ⚙️ Automação
│   ├── setup-workflow.sh
│   ├── gerar-plano-diario.sh
│   ├── validate-workflow.sh
│   └── rotate-key.sh
│
├── README.md                   # ← Você está aqui (🇧🇷 pt-BR)
├── README-en.md                # 🌐 Versão em inglês
├── LICENSE                     # 📄 MIT
└── .gitignore
```

> **Nota:** Este repositório já inclui toda a documentação e templates prontos para uso. Após o setup inicial, sua pasta `planejamento-diario/` será gerada automaticamente.

---

## ✨ Funcionalidades

- **📝 Templates Markdown** — Templates completos com comentários e placeholders para planos, tarefas e índices. Copie, cole, adapte.
- **🔁 Automação do Ciclo Diário** — Script pronto para cron (`gerar-plano-diario.sh`) que gera planos automaticamente às 5h da manhã.
- **🧩 Delegação Multi-Agente** — Atribua tarefas a agentes específicos com exigências explícitas de motor por tarefa.
- **🔐 Protocolo Slack** — Comunicação estruturada entre agentes via Slack com despacho por menção e zero interferência cruzada.
- **📊 Trilha de Auditoria** — Toda tarefa tem seção de conclusão com agente, timestamp, motor utilizado e observações. Auditada por outro agente.
- **✅ Validação Embutida** — `validate-workflow.sh` verifica integridade da estrutura, contadores do índice, preenchimento de checkboxes e consistência plano-vs-disco.
- **🌐 Agnóstico de Idioma** — Templates suportam qualquer idioma. Alterne entre pt-BR e en-US trocando um único placeholder.
- **🔧 Roteamento de Motores** — Defina motores de IA específicos (Opus, Gemini, GPT-4, etc.) por tarefa para garantir o modelo certo para o trabalho certo.
- **⚠️ Protocolo de Lockdown** — Mecanismo de parada de emergência via Slack que congela todos os agentes instantaneamente.
- **🔄 Autodocumentável** — O repositório documenta o próprio processo de criação via `planejamento-diario/`. Prova de que funciona.

---

## 🎯 Para Quem

Este workflow foi projetado para:

| Papel | Como se Beneficia |
|-------|------------------|
| **Usuários do Hermes** | Têm um workflow diário estruturado que resolve o problema de falta de memória entre sessões |
| **Equipes Multi-Agente** | Coordenam 3+ agentes com limites claros de tarefa, atribuição de motores e auditoria cruzada |
| **Orquestradores / Líderes** | Uma pessoa define o plano do dia, delega e revisa — sem microgerenciamento |
| **Engenheiros de Operações** | Scripts de automação integram com cron, pipelines de CI/CD e ferramentas existentes |
| **Contribuidores Open Source** | Templates limpos e documentação clara tornam o onboarding trivial |
| **Qualquer um com agentes de IA** | Se você executa mais de um agente por dia, você precisa deste sistema |

### Pré-requisitos

- **Hermes Agent** instalado e configurado
- **bash >= 4** (macOS / Linux)
- **git** para controle de versão
- Opcional: **Slack** para canal de comunicação entre agentes

---

## 📚 Documentação

| Guia | Descrição |
|------|-----------|
| [Guia de Setup](docs/01-CONFIGURACAO-INICIAL.md) | Instale dependências, configure o Hermes e inicialize seu primeiro projeto |
| [Ciclo Diário](docs/02-CICLO-DIARIO.md) | Passo a passo completo do ciclo de 6 fases |
| [Protocolo Slack](docs/03-PROTOCOLO-SLACK.md) | Padrões de comunicação entre agentes, sistema de menções e zero cross-talk |
| [Guia de Skills](docs/04-GUIA-SKILLS.md) | Como adaptar, sanitizar e compartilhar skills entre equipes |
| [Personalização](docs/05-PERSONALIZACAO.md) | Escolha de nomes, papéis, motores e exemplos práticos |
| [Referência Rápida](docs/06-REFERENCIA-RAPIDA.md) | Cheat sheet de 1 página com comandos, estrutura e regras |
| [Automação Diária](docs/07-AUTOMACAO-DIARIA.md) | Todos os fluxos automatizados: cron, Hermes, shell scripts e monitoramento |
| [Tokens GitHub para Agentes](docs/08-TOKENS-AGENTES.md) | Configuração de tokens individuais para cada agente Hermes commitar |

---

## 📄 Licença

Este projeto é open source sob a **Licença MIT**. Consulte [LICENSE](LICENSE) para detalhes.

---

## 🙏 Agradecimentos

Este projeto não seria possível sem os ensinamentos e a comunidade da [**Pycodebr**](https://pycodebr.com.br/) ([GitHub](https://github.com/pycodebr)) e do **IA Master Elite**. O conhecimento compartilhado sobre arquitetura de agentes, automação de fluxos e boas práticas com Hermes Agent foi fundamental para construir este workflow. Muito obrigado!

---

<p align="center">
  <sub>Feito para equipes Hermes. Fork, adapte, faça seu.</sub>
  <br>
  <sub>© 2026 — Licença MIT</sub>
</p>
