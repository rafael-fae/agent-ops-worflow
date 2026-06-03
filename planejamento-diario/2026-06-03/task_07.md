# Task 07 — Docs: setup inicial + ciclo diário + protocolo Slack

**Wave:** 3 (Documentação)
**Prioridade:** 🟡
**Ferramenta:** Gemini CLI
**Depende de:** task_06

---

## Contexto

A documentação principal do workflow precisa ser completa e didática.
Vamos criar 3 documentos fundamentais na pasta `docs/`.

---

## Instruções

Criar em `agent-ops-workflow/docs/`:

### 1. `docs/01-SETUP-INICIAL.md`

Guia passo-a-passo para configurar o workflow em um projeto novo:

**Conteúdo:**
- Pré-requisitos (Hermes Agent instalado, CLI configurado)
- Clonar o repositório
- Executar `setup-workflow.sh`
- Personalizar placeholders no projeto
- Configurar agentes Hermes (config.yaml, AGENTS.md)
- Configurar canais Slack (criação do app, tokens, home_channel)
- Testar com uma task simples

**Incluir:**
- Comandos exatos para cada passo
- Prints/ exemplos de config.yaml
- Checklist de verificação pós-setup

---

### 2. `docs/02-CICLO-DIARIO.md`

O coração do workflow — as 6 fases do ciclo diário:

| Fase | O que acontece | Quem faz |
|:----:|---------------|:--------:|
| 1 — Planejar | Criar PLANO.md + tasks + INDICE | Orquestrador |
| 2 — Aprovar | Revisar e autorizar | Comandante (humano) |
| 3 — Delegar | Enviar no Slack com menções | Orquestrador |
| 4 — Executar | Rodar task, preencher checklist | Agente |
| 5 — Auditar | Verificar commits, diff, report | Orquestrador |
| 6 — Relatar | Tabela consolidada + veredito | Orquestrador |

**Conteúdo:**
- Explicação detalhada de cada fase
- Template de mensagem Slack (com placeholders)
- Exemplo real (anônimo) de um dia completo
- Diagrama ASCII do fluxo
- Regras de thread (uma task = uma thread)
- O que fazer quando algo dá errado

---

### 3. `docs/03-PROTOCOLO-SLACK.md`

Regras de comunicação no Slack para a equipe multi-agente:

**Conteúdo:**
- Hierarquia de mensagens (quem pode postar no canal vs. thread)
- Formato de menção `<@USER_ID>` (com explicação de por que é obrigatório)
- Template de delegação (com exemplos)
- Regra de silêncio (só responde quem é mencionado)
- Protocolo de lockdown (sinal vermelho do comandante)
- Boas práticas (não abrir threads duplicadas)
- Troubleshooting (menção não funcionou, thread quebrada, etc.)

---

## Checklist

- [x] docs/01-SETUP-INITIAL.md criado (inglês) — 697 linhas
- [x] docs/02-DAILY-CYCLE.md criado (inglês) — 900 linhas
- [x] docs/03-SLACK-PROTOCOL.md criado (inglês) — 817 linhas
- [x] Todos os documentos com exemplos práticos
- [x] Cross-links entre documentos funcionais
- [x] Nenhuma referência a Roshar/Oeste Gestão/Rafael

---

## Restrições

- Conteúdo 100% genérico — qualquer time deve conseguir seguir
- Exemplos usam placeholders (__TIME__, __ORCHESTRATOR__, etc.)
- Tom didático — assumir que o leitor é novo no Hermes

---

## Conclusão

**Agente:** Dalinar (via subagentes)
**Concluída em:** 03/06/2026 ~11:00
**Motor utilizado:** deepseek-v4-flash (subagente)
**Observações:**
- 01-SETUP-INITIAL.md — 697 linhas, guia completo de setup (pré-requisitos, clone, run setup-workflow.sh, configurar agentes, Slack, cron)
- 02-DAILY-CYCLE.md — 900 linhas, 6 fases detalhadas com fluxograma ASCII, exemplo completo "Team Nova"
- 03-SLACK-PROTOCOL.md — 817 linhas, hierarquia de mensagens, formato de menção, protocolo de lockdown, troubleshooting
- Todos em INGLÊS (US), sem referências a Roshar/Rafael/Oeste Gestão
- Templates .tpl também convertidos para inglês
