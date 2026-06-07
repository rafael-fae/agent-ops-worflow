# Automação dos Fluxos Diários

> Guia completo e detalhado de TODOS os fluxos de automação — tanto no nível
> shell script quanto no nível Hermes Agent — para a rotina diária do Time Nova.
> Cada comando aqui é copiável e pronto para uso.

---

## Sumário

1. [Visão Geral — Os 7 Fluxos de Automação](#1-visão-geral--os-7-fluxos-de-automação)
2. [Fluxo 1 — Geração Automática do Plano Diário](#2-fluxo-1--geração-automática-do-plano-diário)
3. [Fluxo 2 — Delegação de Tasks](#3-fluxo-2--delegação-de-tasks)
4. [Fluxo 3 — Execução, Reporte e Commit](#4-fluxo-3--execução-reporte-e-commit)
5. [Fluxo 4 — Auditoria e Validação Automática](#5-fluxo-4--auditoria-e-validação-automática)
6. [Fluxo 5 — Relatório Consolidado Diário](#6-fluxo-5--relatório-consolidado-diário)
7. [Fluxo 6 — Sincronização Git e Backup](#7-fluxo-6--sincronização-git-e-backup)
8. [Fluxo 7 — Segurança e Manutenção](#8-fluxo-7--segurança-e-manutenção)
9. [Mapa Completo de Automações](#9-mapa-completo-de-automações)
10. [Checklist de Automação](#10-checklist-de-automação)

---

## 1. Visão Geral — Os 7 Fluxos de Automação

O Agent Ops Workflow possui **7 fluxos de automação** que operam em 3 níveis
distintos:

| # | Fluxo | Nível Shell | Nível Hermes (IA) | Quando | Descrição |
|:-:|-------|:-----------:|:------------------:|:------:|-----------|
| 1 | Geração do Plano Diário | `gerar-plano-diario.sh` + cron | `hermes run --skills planejamento-diario` + cron job nativo | 05:00 | Cria a estrutura do dia com PLANO.md e tasks esqueleto |
| 2 | Delegação de Tasks | Script curl Slack | `hermes run --prompt "Delegue tasks pendentes"` | 08:00 (pós-aprovação) | Atribui tasks a agentes via Slack |
| 3 | Execução, Reporte e Commit | `git add/commit/push` | Agente Hermes executa e reporta | Contínuo | Agente executa task, preenche checklist, commita, reporta |
| 4 | Auditoria e Validação | `validate-workflow.sh` + cron | `hermes run --skills execucao-wave-auditoria` | 22:00 | Verifica integridade, consistência de checkboxes e índices |
| 5 | Relatório Consolidado | Script shell de compilação | `hermes run --prompt "Gere relatório diário"` | 23:00 | Compila status, gera markdown, publica no Slack |
| 6 | Sincronização Git e Backup | `git push` automático + `rotate-key.sh` | — (operacional apenas) | 23:30 | Push diário, backup de configurações |
| 7 | Segurança e Manutenção | `rotate-key.sh` + limpeza de logs | `hermes cronjob` gerenciamento | Periódico | Rotação de chaves, limpeza, atualização de skills |

---

## 2. Fluxo 1 — Geração Automática do Plano Diário

### Nível 1: Script Shell (`gerar-plano-diario.sh`)

**Arquivo:** `scripts/gerar-plano-diario.sh`

Este script é a espinha dorsal da automação. Ele lê o template `PLANO.md`,
substitui placeholders pela data atual, cria a pasta `YYYY-MM-DD/` e gera um
`PLANO.md` com estrutura vazia (waves editáveis).

#### Comando básico

```bash
# Gera o plano para hoje no diretório do projeto
./scripts/gerar-plano-diario.sh ~/meu-projeto

# Com número personalizado de tasks por wave
./scripts/gerar-plano-diario.sh ~/meu-projeto --tasks=8

# Forçar sobrescrita se a pasta do dia já existir
./scripts/gerar-plano-diario.sh ~/meu-projeto --force
```

#### Placeholders substituídos

| Placeholder | Fonte | Exemplo |
|-------------|-------|---------|
| `__DATA__` | `date +%d/%m/%Y` | 03/06/2026 |
| `__NOME_DO_PROJETO__` | `WORKFLOW_PROJECT_NAME` ou INDICE.md | Projeto Atlas |
| `__NOME_DO_TIME__` | `WORKFLOW_TEAM_NAME` | Time Nova |
| `__COMANDANTE__` | Fixo "Comandante" | Comandante |

#### Estrutura gerada (modo template)

```
~/meu-projeto/planejamento-diario/
└── 2026-06-10/
    └── PLANO.md
```

O `PLANO.md` gerado contém:

```
# Plano de Execução — Projeto Atlas

**Criado por:** gerar-plano-diario.sh / Time Nova
**Data:** 10/06/2026

---

## Waves

### Wave 1 — Manhã 🔴

| Task | Descrição | Agente | Motor | Prioridade | Status |
|:----:|-----------|:------:|:-----:|:----------:|:------:|
| task_01 | — | — | — | 🔴 | ⬜ |
...

### Wave 2 — Tarde 🟡
...

### Wave 3 — Noite 🟢
...

## Ao final do dia

- [ ] 0/15 tasks concluídas e auditadas
- [ ] INDICE.md atualizado com status do dia
- [ ] Todos os commits feitos e push realizado
```

#### Comando cron exato

```bash
# Editar crontab
crontab -e

# Adicionar esta linha:
0 5 * * * /Users/seu-usuario/Dev/agent-ops-workflow/scripts/gerar-plano-diario.sh \
  /Users/seu-usuario/Dev/meu-projeto \
  >> /Users/seu-usuario/Dev/meu-projeto/planejamento-diario/cron.log 2>&1
```

#### Variáveis de ambiente para o cron

O cron executa com ambiente mínimo. Você precisa definir estas variáveis:

```bash
# Formato recomendado no crontab (tudo em uma linha):
WORKFLOW_TEAM_NAME="Time Nova" WORKFLOW_PROJECT_NAME="Projeto Atlas" \
  0 5 * * * /caminho/scripts/gerar-plano-diario.sh ~/meu-projeto \
  >> ~/meu-projeto/planejamento-diario/cron.log 2>&1
```

Ou use um wrapper script que carrega as variáveis primeiro:

```bash
#!/bin/bash
# ~/scripts/wrapper-plano-diario.sh
export WORKFLOW_TEAM_NAME="Time Nova"
export WORKFLOW_PROJECT_NAME="Projeto Atlas"
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

cd /Users/seu-usuario/Dev/agent-ops-workflow
./scripts/gerar-plano-diario.sh /Users/seu-usuario/Dev/meu-projeto --tasks=5 \
  >> /Users/seu-usuario/Dev/meu-projeto/planejamento-diario/cron.log 2>&1
```

#### Logs

O script anexa automaticamente ao `cron.log`:

```bash
# Monitorar o log
tail -f ~/meu-projeto/planejamento-diario/cron.log

# Exemplo de saída
[2026-06-10 05:00:01] Plano gerado: /Users/.../planejamento-diario/2026-06-10/PLANO.md
  Projeto: Projeto Atlas | Time: Time Nova
  Tasks por wave: 5 | Force: false
```

---

### Nível 2: Orquestrador Hermes (NOVO)

Em vez de depender apenas do script shell (que gera uma estrutura genérica),
você pode usar o **próprio agente Orquestrador Hermes** para gerar o plano
com IA — com contexto, tasks inteligentes e dependências reais.

#### Comando básico

```bash
hermes --profile orquestrador run \
  --skills planejamento-diario \
  --prompt "Gere o plano diário de hoje para o Time Nova no Projeto Atlas"
```

#### Prompt completo para gerar plano diário

```bash
hermes --profile orquestrador run \
  --skills planejamento-diario \
  --prompt '<USUARIO>
Gere o plano diário para hoje no Projeto Atlas.

CONTEXTO:
- Time: Nova
- Projeto: Atlas (dashboard de microsserviços)
- Comandante: Alex
- Relatório de ontem: 4/4 tasks concluídas, todas auditadas
- Pendências de ontem: Nenhuma
- Prioridade de hoje: Implementar autenticação 2FA, atualizar documentação da API, corrigir bug de timeout no módulo de relatórios

SAÍDA ESPERADA:
1. Crie a pasta YYYY-MM-DD/ em planejamento-diario/
2. Gere PLANO.md com 3 waves (Manhã/Tarde/Noite)
3. Cada wave com 2-3 tasks contendo: task_ID, descrição, agente, motor, prioridade
4. Crie os arquivos individuais task_01.md, task_02.md, etc.
5. Atualize INDICE.md com as novas tasks

REGRAS:
- Motor padrão: Gemini 3.1 Pro
- DeepSeek PROIBIDO sem autorização do Comandante
- Documentation em pt-BR
- Tasks devem ter dependências claras
</USUARIO>'
```

#### Como agendar no cron

```bash
# No crontab:
0 5 * * * cd /Users/seu-usuario/Dev/agent-ops-workflow && \
  hermes --profile orquestrador run \
    --skills planejamento-diario \
    --prompt "Gere o plano diário de hoje para o Time Nova no Projeto Atlas. Considere o relatório do dia anterior em planejamento-diario/INDICE.md como contexto." \
    >> /Users/seu-usuario/Dev/meu-projeto/planejamento-diario/hermes-plan.log 2>&1
```

#### Vantagens do Nível Hermes vs Shell Script

| Característica | Shell Script | Hermes Agent (IA) |
|----------------|:------------:|:------------------:|
| Geração de estrutura | ✅ Sim | ✅ Sim |
| Tasks inteligentes | ❌ Esqueleto genérico | ✅ Contexto real do projeto |
| Dependências entre tasks | ❌ Não | ✅ Inferidas do relatório anterior |
| Atualização de INDICE.md | ❌ Parcial | ✅ Completa com contadores |
| Criação de task_XX.md individuais | ❌ Não | ✅ Sim, com briefings reais |
| Respeita pendências de ontem | ❌ Não | ✅ Sim, lê do relatório |
| Precisa de template | ✅ Sim | ✅ Sim (mas usa IA para preencher) |
| Velocidade | ✅ Instantâneo | ⚠️ 10-30 segundos |
| Geração sem supervisão | ✅ Segura | ⚠️ Pode alucinar tasks |

**Recomendação:** Use o shell script como fallback diário (cron 05:00) e o
Hermes agent para quando o Comandante Alex quiser um plano mais refinado.

---

### Nível 3: Cron Job Nativo do Hermes (NOVO)

O Hermes Agent possui um sistema nativo de cron jobs. Você pode criar um job
que executa a skill `planejamento-diario` automaticamente todo dia às 05:00.

#### Criar o cron job

```bash
hermes --profile orquestrador cronjob create \
  --name "plano-diario-5am" \
  --schedule "0 5 * * *" \
  --skills planejamento-diario \
  --prompt "Gere o plano diário de hoje para o Time Nova no Projeto Atlas. Use o relatório do dia anterior em planejamento-diario/INDICE.md como contexto. Crie PLANO.md com 3 waves, tasks individuais e atualize o INDICE.md."
```

#### Verificar cron jobs ativos

```bash
# Listar todos os cron jobs
hermes --profile orquestrador cronjob list

# Ver detalhes de um job específico
hermes --profile orquestrador cronjob show plano-diario-5am
```

#### Pausar / Ativar / Remover

```bash
# Pausar (sem remover)
hermes --profile orquestrador cronjob pause plano-diario-5am

# Reativar
hermes --profile orquestrador cronjob resume plano-diario-5am

# Remover permanentemente
hermes --profile orquestrador cronjob delete plano-diario-5am
```

#### ⚠️ Atenção com o cron nativo

Conforme documentado na skill `planejamento-diario`:

1. **Hora local:** O cron usa hora LOCAL da máquina, não UTC.
2. **Geração ≠ Delegação:** O cron gera os arquivos `.md` mas **NÃO delega**
   no Slack. A delegação ainda é manual (ou semi-automática via Fluxo 2).
3. **Plano de recuperação:** Se o dia anterior não executou, o cron pode gerar
   um plano de "recuperação" obsoleto. Sempre verificar e limpar antes de
   prosseguir.

---

## 3. Fluxo 2 — Delegação de Tasks

### Manual (via Slack)

Este é o fluxo documentado em `03-PROTOCOLO-SLACK.md`. O Orquestrador posta
cada task como uma mensagem de nível superior no canal `#agent-ops-nova`,
com `<@USER_ID>` no início e o template completo de delegação.

**Template da mensagem:**

```
<@U0123456789> Tarefa task_01: Corrigir bug de redirecionamento de login

**Motor:** Gemini 3.1 Pro (PADRÃO)
**Prioridade:** 🔴 ALTA — bloqueia task_02
**Arquivo:** planejamento-diario/2026-06-10/task_01.md

**Resumo:**
O redirecionamento de login está enviando usuários para /dashboard em vez de
/home após a autenticação. Corrija a lógica de redirecionamento.

**Instruções principais:**
1. Encontre a constante de redirecionamento em AuthController.php
2. Altere o valor de '/dashboard' para '/home'
3. Teste em staging com curl
4. Execute a suíte completa de testes

**Lembrete de checklist:**
- Verificou correção em staging
- Executou suíte completa de testes
- Preencheu seção de Conclusão em task_01.md
- Committed e deu push

**Restrições:**
- NÃO modifique arquivos de migração de banco de dados
- NÃO altere o middleware de autenticação
- Mexa apenas na constante de URL de redirecionamento
```

---

### Semiautomática (via script shell com webhook Slack)

Você pode criar um script que lê o `PLANO.md` do dia e gera mensagens de
delegação automaticamente via webhook do Slack.

#### Script de exemplo: `delegar-tasks.sh`

```bash
#!/bin/bash
# scripts/delegar-tasks.sh — Delegação semiautomática de tasks para o Slack
# =============================================================================
# Lê PLANO.md, extrai tasks com status ⬜ e envia mensagens de delegação
# via webhook do Slack, uma por task.
#
# Uso: ./scripts/delegar-tasks.sh <diretório-do-projeto> [data YYYY-MM-DD]
# =============================================================================

set -euo pipefail

TARGET_DIR="${1:-.}"
TARGET_DIR="${TARGET_DIR/#\~/$HOME}"
DATA="${2:-$(date +%Y-%m-%d)}"
PLANO="$TARGET_DIR/planejamento-diario/$DATA/PLANO.md"
WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"

if [ ! -f "$PLANO" ]; then
    echo "[ERRO] PLANO.md não encontrado: $PLANO"
    exit 1
fi

if [ -z "$WEBHOOK_URL" ]; then
    echo "[ERRO] Defina SLACK_WEBHOOK_URL como variável de ambiente."
    exit 1
fi

echo "[INFO] Lendo tasks de $PLANO..."

# Extrair linhas de task com status ⬜ (não concluídas)
grep '| task_' "$PLANO" | grep '⬜' | while IFS='|' read -r _ task_id desc agente motor prioridade status _; do
    task_id="$(echo "$task_id" | xargs)"
    desc="$(echo "$desc" | xargs)"
    agente="$(echo "$agente" | xargs)"
    motor="$(echo "$motor" | xargs)"
    prioridade="$(echo "$prioridade" | xargs)"

    echo "[INFO] Delegando $task_id: $desc para $agente..."

    # Montar payload JSON
    payload=$(cat <<JSONEOF
{
    "channel": "${SLACK_HOME_CHANNEL:-C0123456789}",
    "text": "<@${agente}> Tarefa ${task_id}: ${desc}\n\n**Motor:** ${motor} (PADRÃO)\n**Prioridade:** ${prioridade}\n**Arquivo:** planejamento-diario/${DATA}/${task_id}.md\n\n**Resumo:**\n${desc}\n\n**Instruções:**\nConsulte o arquivo da task para instruções completas.\n\n**Lembrete:**\n- Preencha a seção de Conclusão após executar\n- Commit + push antes de reportar\n- Reporte nesta thread quando concluído",
    "unfurl_links": false
}
JSONEOF
)

    # Enviar via webhook
    curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$WEBHOOK_URL"
    echo ""
done

echo "[OK] Delegação concluída."
```

**Como usar:**

```bash
# Configurar webhook
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/T00.../B00.../xxx"
export SLACK_HOME_CHANNEL="C0123456789"

# Delegar tasks do plano de hoje
./scripts/delegar-tasks.sh ~/meu-projeto
```

**Limitações da abordagem semiautomática:**

- Requer mapeamento de nomes de agentes para IDs Slack
- Não valida se o Comandante aprovou o plano
- Mensagens são genéricas (sem instruções detalhadas)
- Não cria threads separadas (usa `text` simples, não `blocks`)

---

### Automática (via Hermes Orquestrador)

O Orquestrador Hermes pode delegar tasks automaticamente lendo o `PLANO.md`
do dia e enviando as mensagens padronizadas no Slack com IA.

#### Comando

```bash
hermes --profile orquestrador run \
  --prompt "Delegue as tasks pendentes do plano de hoje no Projeto Atlas.
    Leia o arquivo planejamento-diario/$(date +%Y-%m-%d)/PLANO.md.
    Para cada task com status ⬜, crie uma mensagem de delegação no Slack
    usando o template padrao com @menção do agente, motor, prioridade e
    instruções.
    Regras:
    - Uma mensagem de nível superior por task (cria threads separadas)
    - ORDEM ABSOLUTA: Motor Gemini 3.1 Pro para todas
    - Inclua o caminho completo do arquivo da task
    - Publique no canal #agent-ops-nova"
```

**Vantagens da automação via Hermes:**

1. Lê o contexto real do `PLANO.md` com IA
2. Gera instruções personalizadas para cada task
3. Resolve nomes de agentes automaticamente (se configurado no AGENTS.md)
4. Cria threads separadas corretamente
5. Pode validar se o plano foi aprovado (Fase 2) antes de delegar

**Quando usar cada nível:**

| Situação | Nível |
|----------|-------|
| Time pequeno (1-3 tasks/dia) | Manual |
| Time médio (4-8 tasks/dia) | Semiautomático (script webhook) |
| Time grande (8+ tasks/dia) | Automático (Hermes) |
| Comandante quer revisar cada delegação | Manual |
| Comandante confia no Orquestrador | Automático |

---

## 4. Fluxo 3 — Execução, Reporte e Commit

Este fluxo é executado pelo **agente designado** para cada task. O agente:

1. Confirma recebimento na thread do Slack
2. Lê o arquivo `task_XX.md`
3. Executa as instruções
4. Preenche o checklist (`[x]`)
5. Preenche a seção Conclusão
6. Faz commit + push
7. Reporta na thread

### Checklist de execução (para o agente)

```markdown
## Checklist

- [ ] Leu a seção "Leitura Obrigatória" (PRD, Blueprint, docs)
- [ ] Leu o arquivo task_XX.md completo
- [ ] Configurou o ambiente/motor necessário
- [ ] Executou cada passo das instruções
- [ ] Testou o resultado (staging, testes unitários)
- [ ] Preencheu a seção Conclusão abaixo
- [ ] Committed (`git add -A && git commit -m "..."`)
- [ ] Deu push (`git push`)
- [ ] Reportou na thread do Slack
```

### Seção Conclusão (a ser preenchida pelo agente)

```markdown
## Conclusão

**Agente:** nova-dev
**Concluído em:** 10/06/2026 14:30
**Motor usado:** Gemini 3.1 Pro
**Hash do commit:** aabbccdd11223344
**Observações:**
Corrigida a constante de URL de redirecionamento em AuthController.php.
O bug era um resíduo da refatoração de roteamento do sprint anterior.
Todos os testes passam (47/47). Nenhum efeito colateral detectado.
```

### Automação de commit (template de mensagem)

```bash
# Commit semântico em português
git add -A
git commit -m "feat: implementa autenticação 2FA no módulo de login"
git push
```

**Padrão de commits semânticos:**

| Prefixo | Significado |
|---------|-------------|
| `feat:` | Nova funcionalidade |
| `fix:` | Correção de bug |
| `docs:` | Documentação |
| `refactor:` | Refatoração |
| `test:` | Testes |
| `chore:` | Manutenção |
| `audit:` | Registro de auditoria |
| `daily:` | Relatório diário / índice |

### Script de validação pós-task

O agente pode executar uma validação rápida antes de reportar:

```bash
#!/bin/bash
# valida-task.sh — Validação rápida antes do reporte
# Uso: ./valida-task.sh ~/meu-projeto task_01

TARGET_DIR="${1:-.}"
TASK="${2:-}"
DATA=$(date +%Y-%m-%d)

if [ -z "$TASK" ]; then
    echo "Uso: $0 <diretório> <task_id>"
    exit 1
fi

TASK_FILE="$TARGET_DIR/planejamento-diario/$DATA/$TASK.md"

echo "=== Validação pós-task ==="
echo ""

# Verificar se task file existe
if [ ! -f "$TASK_FILE" ]; then
    echo "[ERRO] Arquivo $TASK_FILE não encontrado."
    exit 1
fi

# 1. Verificar checkboxes
CHECKBOXES=$(grep -cP '^\s*-\s*\[[ x]\]' "$TASK_FILE" 2>/dev/null || true)
PREENCHIDOS=$(grep -cP '^\s*-\s*\[x\]' "$TASK_FILE" 2>/dev/null || true)
echo "[CHECKBOX] $PREENCHIDOS/$CHECKBOXES preenchidos"

# 2. Verificar seção Conclusão
if grep -q "^## Conclusão" "$TASK_FILE" 2>/dev/null; then
    echo "[CONCLUSÃO] Seção Conclusão encontrada."
    HASH=$(grep "^\\*\\*Hash do commit:\\*\\*" "$TASK_FILE" 2>/dev/null | head -1)
    echo "  $HASH"
else
    echo "[AVISO] Seção Conclusão não encontrada!"
fi

# 3. Verificar commit real
if [ -d "$TARGET_DIR/.git" ]; then
    LAST_COMMIT=$(cd "$TARGET_DIR" && git log --oneline -1 2>/dev/null || true)
    echo "[GIT] Último commit: $LAST_COMMIT"
    
    # Verificar se há push pendente
    AHEAD=$(cd "$TARGET_DIR" && git status 2>/dev/null | grep -c "Your branch is ahead" || true)
    if [ "$AHEAD" -gt 0 ]; then
        echo "[GIT] ⚠️ Push pendente! Execute 'git push' antes de reportar."
    else
        echo "[GIT] ✅ Push em dia."
    fi
fi

echo ""
echo "=== Fim da validação ==="
```

---

## 5. Fluxo 4 — Auditoria e Validação Automática

### Nível Shell: `validate-workflow.sh`

**Arquivo:** `scripts/validate-workflow.sh`

Este script verifica a integridade de toda a estrutura `planejamento-diario/`:

1. Se a estrutura básica existe
2. Se `INDICE.md` existe e está consistente
3. Se os contadores X/Y no INDICE.md batem com as tasks reais
4. Se as pastas de data existem e têm PLANO.md
5. Se as tasks do dia atual têm checkboxes preenchidos
6. Se as tasks têm seção Conclusão
7. Se PLANO.md reflete o status real (task contagem)
8. Se os templates existem na pasta TEMPLATES/
9. Se o cron.log existe

#### Comando básico

```bash
# Validar estrutura do projeto
./scripts/validate-workflow.sh ~/meu-projeto

# Validar com correção automática de inconsistências leves
./scripts/validate-workflow.sh ~/meu-projeto --fix

# Validar com saída detalhada
./scripts/validate-workflow.sh ~/meu-projeto --verbose
```

#### Códigos de saída

| Código | Significado |
|:------:|-------------|
| 0 | Tudo ok (sem warnings, sem erros) |
| 1 | Warnings encontrados (inconsistências, mas estrutura íntegra) |
| 2 | Erro (estrutura ausente ou corrompida) |

#### Exemplo de saída

```
[OK]      Estrutura planejamento-diario/ encontrada.
[OK]      INDICE.md encontrado.
[WARN]    Contador incorreto em '10/06/2026': declarado 0/15, real 3/4
[WARN]    Task task_01: nenhum checkbox preenchido (0/6)
[OK]      3 template(s) encontrado(s) em TEMPLATES/.

╔══════════════════════════════════════════════════════════════╗
║           Auditoria concluída com inconsistências           ║
╚══════════════════════════════════════════════════════════════╝

  Verificações: 9
  Passaram:     5
  Warnings:     2
  Erros:        0
```

#### Comando cron para validação diária

```bash
# Executar validação toda noite às 22:00, com correção automática
0 22 * * * /Users/seu-usuario/Dev/agent-ops-workflow/scripts/validate-workflow.sh \
  /Users/seu-usuario/Dev/meu-projeto --fix \
  >> /Users/seu-usuario/Dev/meu-projeto/planejamento-diario/validate.log 2>&1
```

#### Integração com notificações

Você pode combinar a validação com notificação Slack:

```bash
#!/bin/bash
# ~/scripts/cron-validate-notify.sh
# Wrapper que valida e notifica no Slack

PROJECT="/Users/seu-usuario/Dev/meu-projeto"
VALIDATE_LOG="$PROJECT/planejamento-diario/validate.log"
WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"

# Executar validação
/Users/seu-usuario/Dev/agent-ops-workflow/scripts/validate-workflow.sh "$PROJECT" --fix \
  > "$VALIDATE_LOG" 2>&1
EXIT_CODE=$?

# Se houver warnings ou erros, notificar
if [ $EXIT_CODE -ne 0 ]; then
    RESUMO=$(tail -10 "$VALIDATE_LOG")
    
    if [ -n "$WEBHOOK_URL" ]; then
        curl -s -X POST -H "Content-Type: application/json" \
          -d "{\"channel\":\"${SLACK_HOME_CHANNEL:-C0123456789}\",\"text\":\"⚠️ Validação do workflow reportou inconsistências (código $EXIT_CODE).\n\n\`\`\`$RESUMO\`\`\`\"}" \
          "$WEBHOOK_URL"
    fi
fi

exit $EXIT_CODE
```

---

### Auditoria por Orquestrador Hermes

O Orquestrador pode executar auditoria com IA, verificando commits e
atualizando os índices automaticamente.

#### Comando de auditoria

```bash
hermes --profile orquestrador run \
  --skills execucao-wave-auditoria \
  --prompt '<USUARIO>
Execute a auditoria completa do dia 10/06/2026 no Projeto Atlas.

PASSOS:
1. Leia o PLANO.md do dia
2. Para cada task com status pendente (⬜), verifique se o agente reportou
3. Verifique os commits: git log --oneline e git show para cada hash
4. Verifique se os checkboxes estão preenchidos em cada task_XX.md
5. Se aprovado:
   - Atualize PLANO.md: marque status como ✅
   - Atualize INDICE.md: marque ✅, 👁, adicione hash do commit
   - git add + git commit + git push
6. Se rejeitado:
   - Liste os problemas específicos na thread do Slack
   - Aguarde correção do agente

REGRAS:
- Uma task por thread — toda comunicação na mesma thread
- Atualize IMEDIATAMENTE o INDICE.md após cada auditoria
- ⬜ mantido é falha grave
</USUARIO>'
```

#### Verificação de commits (checklist do auditor)

```bash
# 1. Verificar se o hash existe
git log --oneline -5

# 2. Verificar detalhes do commit
git show aabbccdd --stat

# 3. Verificar diff real
git diff aabbccdd^..aabbccdd

# 4. Verificar se o push foi feito
git branch -r --contains aabbccdd
```

---

### Cron de integridade (completo)

```bash
# Cron diário — 22:00 — validar estrutura e corrigir automaticamente
0 22 * * * /Users/seu-usuario/Dev/agent-ops-workflow/scripts/validate-workflow.sh \
  /Users/seu-usuario/Dev/meu-projeto --fix \
  >> /Users/seu-usuario/Dev/meu-projeto/planejamento-diario/validate.log 2>&1

# Cron semanal — domingo 10:00 — validação completa com verbose
0 10 * * 0 /Users/seu-usuario/Dev/agent-ops-workflow/scripts/validate-workflow.sh \
  /Users/seu-usuario/Dev/meu-projeto --verbose --fix \
  >> /Users/seu-usuario/Dev/meu-projeto/planejamento-diario/validate-semanal.log 2>&1
```

---

## 6. Fluxo 5 — Relatório Consolidado Diário

### Geração automática via script shell

Este script compila o status de todas as tasks do dia, gera um relatório
markdown e publica no Slack via webhook.

#### Script de exemplo: `gerar-relatorio.sh`

```bash
#!/bin/bash
# scripts/gerar-relatorio.sh — Relatório Consolidado Diário
# =============================================================================
# Lê o PLANO.md e INDICE.md do dia, compila status, gera relatório markdown
# e publica no Slack via webhook.
#
# Uso: ./scripts/gerar-relatorio.sh <diretório-do-projeto> [data YYYY-MM-DD]
# =============================================================================

set -euo pipefail

TARGET_DIR="${1:-.}"
TARGET_DIR="${TARGET_DIR/#\~/$HOME}"
DATA="${2:-$(date +%Y-%m-%d)}"
DATA_BR="$(date -d "$DATA" +%d/%m/%Y 2>/dev/null || echo "$DATA")"

PD_DIR="$TARGET_DIR/planejamento-diario"
DIA_DIR="$PD_DIR/$DATA"
PLANO="$DIA_DIR/PLANO.md"
INDICE="$PD_DIR/INDICE.md"
RELATORIO="$DIA_DIR/RELATORIO.md"
WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"

TEAM_NAME="${WORKFLOW_TEAM_NAME:-Time Nova}"

if [ ! -f "$PLANO" ]; then
    echo "[ERRO] PLANO.md não encontrado: $PLANO"
    exit 1
fi

echo "[INFO] Gerando relatório para $DATA_BR..."

# --- Coleta de dados ---

# Total de tasks no PLANO.md
TOTAL_TASKS=$(grep -cP '^\|\s*task_\d+' "$PLANO" 2>/dev/null || echo 0)

# Tasks concluídas (status ✅ no PLANO.md)
CONCLUIDAS=$(grep -cP '^\|\s*task_\d+.*\|\s*✅\s*\|' "$PLANO" 2>/dev/null || echo 0)

# Tasks auditadas (coluna 👁 no INDICE.md)
if [ -f "$INDICE" ]; then
    AUDITADAS=$(grep -cP '^\|\s*task_\d+.*\|.*\|.*\|.*✅\s*\|' "$INDICE" 2>/dev/null || echo 0)
else
    AUDITADAS=0
fi

# Commits do dia (últimos commits)
COMMITS_HOJE=$(cd "$TARGET_DIR" && git log --oneline --since="$(date +%Y-%m-%d)T00:00:00" --until="$(date +%Y-%m-%d)T23:59:59" 2>/dev/null | head -10 || true)

# --- Montar tabela de tasks ---
TASKS_JSON=""
while IFS='|' read -r _ task_id desc agente motor prioridade status _; do
    task_id="$(echo "$task_id" | xargs)"
    desc="$(echo "$desc" | xargs)"
    status="$(echo "$status" | xargs)"
    
    [ -z "$task_id" ] && continue
    
    # Traduzir status
    case "$status" in
        "✅") STATUS_ICON="✅" ;;
        "⬜") STATUS_ICON="⬜" ;;
        *) STATUS_ICON="$status" ;;
    esac
    
    # Procurar hash do commit no INDICE.md
    COMMIT_HASH="—"
    if [ -f "$INDICE" ]; then
        HASH=$(grep "^| $task_id " "$INDICE" 2>/dev/null | awk -F'|' '{print $NF}' | xargs)
        [ -n "$HASH" ] && [ "$HASH" != "—" ] && COMMIT_HASH="$HASH"
    fi
    
    TASKS_JSON+="| $task_id | $desc | $STATUS_ICON | $COMMIT_HASH |"$'\n'
done < <(grep -P '^\|\s*task_\d+' "$PLANO")

# --- Gerar relatório markdown ---
cat > "$RELATORIO" <<RELEOF
# Relatório Diário — $TEAM_NAME

**Data:** $DATA_BR
**Gerado por:** gerar-relatorio.sh
**Total de tasks:** $TOTAL_TASKS | Concluídas: $CONCLUIDAS | Auditadas: $AUDITADAS

---

## Status das Tasks

| Task | Descrição | Status | Commit |
|:----:|-----------|:------:|:------:|
$TASKS_JSON

---

## Resumo

**$CONCLUIDAS/$TOTAL_TASKS** tasks concluídas.
**$AUDITADAS** tasks auditadas.
**$((TOTAL_TASKS - CONCLUIDAS))** tasks pendentes.

**Percentual de conclusão:** $(awk "BEGIN {printf \"%.0f\", ($CONCLUIDAS/$TOTAL_TASKS)*100}")%

---

## Commits do Dia

\`\`\`
$COMMITS_HOJE
\`\`\`

---

## Pendências para Amanhã

- $(grep -cP '⬜' <<< "$TASKS_JSON") tasks não concluídas
- Revisar tasks com status ⬜ no plano de amanhã

---

## Observações

<!-- Preencher manualmente se necessário -->

RELEOF

echo "[OK] Relatório gerado: $RELATORIO"

# --- Publicar no Slack ---
if [ -n "$WEBHOOK_URL" ]; then
    # Versão resumida para o Slack (sem tabela complexa)
    RESUMO="📊 Relatório Diário — $TEAM_NAME — $DATA_BR

*Resumo:* $CONCLUIDAS/$TOTAL_TASKS tasks concluídas. $AUDITADAS auditadas.
*Pendentes:* $((TOTAL_TASKS - CONCLUIDAS)) tasks pendentes.

*Commits:*"
    while IFS= read -r commit; do
        [ -n "$commit" ] && RESUMO+="
• $commit"
    done <<< "$COMMITS_HOJE"
    [ -z "$COMMITS_HOJE" ] && RESUMO+="
• Nenhum commit hoje"

    curl -s -X POST -H "Content-Type: application/json" \
      -d "{\"channel\":\"${SLACK_HOME_CHANNEL:-C0123456789}\",\"text\":\"$RESUMO\",\"unfurl_links\":false}" \
      "$WEBHOOK_URL"
    echo "[OK] Relatório publicado no Slack."
fi

echo "[OK] Relatório concluído."
```

#### Como usar

```bash
# Configurar variáveis
export WORKFLOW_TEAM_NAME="Time Nova"
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/T00.../B00.../xxx"
export SLACK_HOME_CHANNEL="C0123456789"

# Gerar relatório para hoje
./scripts/gerar-relatorio.sh ~/meu-projeto

# Gerar relatório para uma data específica
./scripts/gerar-relatorio.sh ~/meu-projeto 2026-06-10
```

#### Template do relatório gerado

```markdown
# Relatório Diário — Time Nova

**Data:** 10/06/2026
**Gerado por:** gerar-relatorio.sh
**Total de tasks:** 4 | Concluídas: 3 | Auditadas: 2

---

## Status das Tasks

| Task | Descrição | Status | Commit |
|:----:|-----------|:------:|:------:|
| task_01 | Corrigir bug redirect login | ✅ | aabbccdd |
| task_02 | Completar migração API v2 | ✅ | eeff0011 |
| task_03 | Atualizar documentação API | ✅ | 11223344 |
| task_04 | Auditar correção + migração | ⬜ | — |

---

## Resumo

**3/4** tasks concluídas.
**2** tasks auditadas.
**1** tasks pendentes.

**Percentual de conclusão:** 75%

---

## Pendências para Amanhã

- 1 tasks não concluídas
- Revisar tasks com status ⬜ no plano de amanhã
```

#### Cron para geração automática do relatório

```bash
# Gerar relatório às 23:00 todos os dias
0 23 * * * cd /Users/seu-usuario/Dev/agent-ops-workflow && \
  export WORKFLOW_TEAM_NAME="Time Nova" && \
  export SLACK_WEBHOOK_URL="seu-webhook" && \
  export SLACK_HOME_CHANNEL="C0123456789" && \
  ./scripts/gerar-relatorio.sh /Users/seu-usuario/Dev/meu-projeto \
  >> /Users/seu-usuario/Dev/meu-projeto/planejamento-diario/relatorio.log 2>&1
```

---

### Geração via Orquestrador Hermes

O Orquestrador pode gerar um relatório mais inteligente, analisando o
contexto real de cada task.

```bash
hermes --profile orquestrador run \
  --prompt '<USUARIO>
Gere o relatório diário consolidado para o Time Nova no Projeto Atlas, data $(date +%d/%m/%Y).

CONTEXTO:
- Leia planejamento-diario/INDICE.md para status de todas as tasks
- Leia planejamento-diario/$(date +%Y-%m-%d)/PLANO.md para o plano do dia
- Verifique os commits com git log --oneline

SAÍDA ESPERADA:
1. Tabela markdown com todas as tasks, status e commits
2. Resumo numérico (X/Y concluídas, A auditadas)
3. Pendências para amanhã
4. Observações notáveis

REGRAS:
- Salve em planejamento-diario/$(date +%Y-%m-%d)/RELATORIO.md
- Publique no canal #agent-ops-nova
- Faça git add + git commit + git push
</USUARIO>'
```

---

## 7. Fluxo 6 — Sincronização Git e Backup

### Push automático via cron

```bash
# Cron diário — 23:30 — commit + push de todas as alterações do dia
30 23 * * * cd /Users/seu-usuario/Dev/meu-projeto && \
  git add -A && \
  git commit -m "daily: atualizacao $(date +%Y-%m-%d)" --allow-empty && \
  git push \
  >> /Users/seu-usuario/Dev/meu-projeto/planejamento-diario/git-push.log 2>&1
```

#### Script wrapper: `git-push-diario.sh`

```bash
#!/bin/bash
# scripts/git-push-diario.sh — Push automático com mensagem semântica
# =============================================================================
# Uso: ./scripts/git-push-diario.sh <diretório-do-projeto> [mensagem]
# =============================================================================

set -euo pipefail

TARGET_DIR="${1:-.}"
TARGET_DIR="${TARGET_DIR/#\~/$HOME}"
DATA="$(date +%Y-%m-%d)"
DATA_BR="$(date +%d/%m/%Y)"
MENSAGEM="${2:-daily: atualizacao $DATA_BR}"

cd "$TARGET_DIR"

echo "[INFO] Sincronizando $TARGET_DIR..."

# Verificar se é um repositório git
if [ ! -d ".git" ]; then
    echo "[ERRO] $TARGET_DIR não é um repositório git."
    exit 1
fi

# Adicionar tudo
git add -A

# Verificar se há algo para commit
if git diff --cached --quiet; then
    echo "[INFO] Nada para commitar. Pulando."
    exit 0
fi

# Commitar
git commit -m "$MENSAGEM"
echo "[OK] Commit: $(git log --oneline -1)"

# Push
git push
echo "[OK] Push realizado."

# Registrar
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Push: $MENSAGEM" >> "$TARGET_DIR/planejamento-diario/git-push.log"
```

---

### Backup de segurança

#### Backup do diretório `.hermes/`

O diretório `~/.hermes/` contém a configuração de perfis, tokens e skills
do Hermes Agent. É fundamental ter backup.

```bash
#!/bin/bash
# scripts/backup-hermes-config.sh
# =============================================================================
# Backup da configuração do Hermes Agent
# =============================================================================

BACKUP_DIR="$HOME/backups/hermes-config"
DATA="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="$BACKUP_DIR/hermes-config-$DATA.tar.gz"

mkdir -p "$BACKUP_DIR"

if [ -d "$HOME/.hermes" ]; then
    tar -czf "$BACKUP_FILE" -C "$HOME" .hermes
    echo "[OK] Backup criado: $BACKUP_FILE"
    echo "     Tamanho: $(du -h "$BACKUP_FILE" | cut -f1)"
    
    # Manter apenas os 7 backups mais recentes
    ls -t "$BACKUP_DIR"/hermes-config-*.tar.gz 2>/dev/null | tail -n +8 | xargs -r rm
    echo "[INFO] Backups antigos removidos (mantidos 7)."
else
    echo "[ERRO] ~/.hermes/ não encontrado."
    exit 1
fi
```

#### Cron de backup semanal

```bash
# Backup da configuração Hermes todo domingo às 03:00
0 3 * * 0 /Users/seu-usuario/Dev/agent-ops-workflow/scripts/backup-hermes-config.sh \
  >> /Users/seu-usuario/Dev/agent-ops-workflow/planejamento-diario/backup.log 2>&1
```

#### Recomendações de backup

| O que | Frequência | Método |
|-------|:----------:|--------|
| `~/.hermes/config.yaml` | Semanal | Script backup-hermes-config.sh |
| Chaves SSH (`~/.ssh/`) | Mensal | `rotate-key.sh --backup` |
| `planejamento-diario/` | Diário | Git (já versionado) |
| Tokens Slack | A cada rotação | Gerenciador de senhas |
| Skills personalizadas | Semanal | Git (já no repositório) |

---

## 8. Fluxo 7 — Segurança e Manutenção

### Rotação de chaves SSH (`rotate-key.sh`)

**Arquivo:** `scripts/rotate-key.sh`

Este script gera um novo par de chaves SSH ed25519, faz backup da chave
anterior com timestamp e atualiza `~/.ssh/config` se necessário.

#### Comandos

```bash
# Rotacionar chave padrão
./scripts/rotate-key.sh id_minha_chave

# Rotacionar e atualizar configuração para um host específico
./scripts/rotate-key.sh id_empresa --host=github.com

# Rotacionar em diretório personalizado
./scripts/rotate-key.sh id_servidor --dir=~/.ssh/empresa

# Apenas exibir chave pública atual (sem rotacionar)
./scripts/rotate-key.sh --show id_minha_chave

# Pular backup da chave anterior
./scripts/rotate-key.sh id_teste --no-backup
```

#### Frequência recomendada

| Ambiente | Frequência | Motivo |
|----------|:----------:|--------|
| Desenvolvimento local | A cada 6 meses | Segurança básica |
| Produção / servidores | A cada 3 meses | Compliance |
| Após vazamento suspeito | Imediato | Emergência |
| Máquina compartilhada | A cada 1 mês | Risco maior |

#### Exemplo de execução

```bash
$ ./scripts/rotate-key.sh id_nova --host=github.com --comment="Time Nova - $(date +%Y-%m-%d)"

[INFO] Gerando nova chave ed25519: /Users/seu-usuario/.ssh/id_nova

[OK] Backup da chave anterior criado:
[OK]   /Users/seu-usuario/.ssh/id_nova.bak.20260603_140000
[OK]   /Users/seu-usuario/.ssh/id_nova.pub.bak.20260603_140000

[OK] Nova chave gerada com sucesso.
[INFO]   Privada: /Users/seu-usuario/.ssh/id_nova
[INFO]   Pública: /Users/seu-usuario/.ssh/id_nova.pub
[INFO]   Comentário: Time Nova - 2026-06-03

[OK] ~/.ssh/config: IdentityFile atualizado para o host 'github.com'.

╔══════════════════════════════════════════════════════════════╗
║         Chave Pública — Copie para o servidor              ║
╚══════════════════════════════════════════════════════════════╝

ssh-ed25519 AAAAC3... user@hostname

╔══════════════════════════════════════════════════════════════╗
║           Rotação concluída com sucesso!                    ║
╚══════════════════════════════════════════════════════════════╝
```

---

### Limpeza de logs

#### Rotação do cron.log

Sem rotação, os logs podem crescer indefinidamente. Use `logrotate` ou um
script simples:

```bash
#!/bin/bash
# scripts/rotate-logs.sh — Rotação de logs do workflow

LOG_DIR="/Users/seu-usuario/Dev/meu-projeto/planejamento-diario"
RETENTION_DAYS=30

for log in cron.log validate.log relatorio.log git-push.log; do
    LOG_FILE="$LOG_DIR/$log"
    if [ -f "$LOG_FILE" ] && [ "$(stat -f%m "$LOG_FILE" 2>/dev/null || stat -c%Y "$LOG_FILE" 2>/dev/null)" -lt "$(date -d "-$RETENTION_DAYS days" +%s 2>/dev/null || echo 0)" ]; then
        gzip "$LOG_FILE"
        mv "${LOG_FILE}.gz" "${LOG_FILE}.$(date +%Y%m%d).gz"
        echo "[OK] Log rotacionado: $log"
    fi
done

# Limpar arquivos temporários
find "$LOG_DIR" -name "*.tmp" -type f -delete
find "$LOG_DIR" -name "*.bak" -type f -mtime +7 -delete

echo "[OK] Limpeza concluída."
```

#### Cron de limpeza

```bash
# Limpeza semanal de logs (domingo 04:00)
0 4 * * 0 /Users/seu-usuario/Dev/agent-ops-workflow/scripts/rotate-logs.sh
```

---

### Atualização de skills

Manter as skills Hermes atualizadas é essencial para o bom funcionamento.

#### Verificar skills disponíveis

```bash
# Listar skills instaladas
hermes skill_list

# Ver detalhes de uma skill específica
hermes skill_view --name planejamento-diario
```

#### Atualizar skills do repositório

```bash
# Pull do repositório agent-ops-workflow
cd /Users/seu-usuario/Dev/agent-ops-workflow
git pull origin main

# Recarregar skills no Hermes
hermes skill_manage sync --dir /Users/seu-usuario/Dev/agent-ops-workflow/skills
```

#### Adicionar nova skill

```bash
# Carregar skill do diretório de skills
hermes skill_manage add /Users/seu-usuario/Dev/agent-ops-workflow/skills/devops/correcao-fechamento-diario/SKILL.md

# Verificar se foi carregada
hermes skill_list | grep correcao-fechamento-diario
```

---

## 9. Mapa Completo de Automações

Tabela completa de TODOS os comandos de automação do workflow:

| # | O quê | Comando / Script | Quando | Nível | Onde |
|:-:|-------|------------------|:------:|:-----:|------|
| 1 | Setup inicial do workflow | `./scripts/setup-workflow.sh ~/projeto "Time Nova" "Projeto Atlas"` | Uma vez | Shell | Setup |
| 2 | Gerar plano diário (shell) | `./scripts/gerar-plano-diario.sh ~/projeto --tasks=5` | 05:00 | Shell | Cron |
| 3 | Gerar plano diário (Hermes) | `hermes --profile orquestrador run --skills planejamento-diario --prompt "..."` | 05:00 | IA | Cron |
| 4 | Cron job nativo Hermes | `hermes --profile orquestrador cronjob create --name "plano-5am" --schedule "0 5 * * *" --skills planejamento-diario --prompt "..."` | 05:00 | IA | Hermes |
| 5 | Delegar tasks (manual) | Postar `<@USER_ID> Tarefa task_N: ...` no Slack | 08:00 | Manual | Slack |
| 6 | Delegar tasks (script) | `./scripts/delegar-tasks.sh ~/projeto` | 08:00 | Shell | Cron |
| 7 | Delegar tasks (Hermes) | `hermes --profile orquestrador run --prompt "Delegue as tasks pendentes..."` | 08:00 | IA | Hermes |
| 8 | Executar task | Agente executa, preenche checklist + Conclusão | Contínuo | Manual | CLI |
| 9 | Commit + push | `git add -A && git commit -m "..." && git push` | Contínuo | Shell | CLI |
| 10 | Validar integridade | `./scripts/validate-workflow.sh ~/projeto` | 22:00 | Shell | Cron |
| 11 | Validar + corrigir | `./scripts/validate-workflow.sh ~/projeto --fix` | 22:00 | Shell | Cron |
| 12 | Validar com verbose | `./scripts/validate-workflow.sh ~/projeto --verbose` | Sob demanda | Shell | CLI |
| 13 | Auditoria por Orquestrador | `hermes --profile orquestrador run --skills execucao-wave-auditoria --prompt "Audite o dia..."` | 22:00 | IA | Hermes |
| 14 | Relatório diário (script) | `./scripts/gerar-relatorio.sh ~/projeto` | 23:00 | Shell | Cron |
| 15 | Relatório diário (Hermes) | `hermes --profile orquestrador run --prompt "Gere o relatório diário..."` | 23:00 | IA | Hermes |
| 16 | Git push automático | `git add -A && git commit -m "daily: ..." && git push` | 23:30 | Shell | Cron |
| 17 | Backup configuração Hermes | `./scripts/backup-hermes-config.sh` | Semanal (dom 03:00) | Shell | Cron |
| 18 | Rotação de chave SSH | `./scripts/rotate-key.sh id_nova` | Trimestral | Shell | Manual |
| 19 | Rotação de logs | `./scripts/rotate-logs.sh` | Semanal (dom 04:00) | Shell | Cron |
| 20 | Atualizar skills | `hermes skill_manage sync --dir skills/` | Após git pull | Hermes | CLI |
| 21 | Verificar cron jobs | `hermes --profile orquestrador cronjob list` | Sob demanda | Hermes | CLI |
| 22 | Notificação de validação | Wrapper que chama webhook Slack se `validate-workflow.sh` falhar | 22:00 | Shell | Cron |

---

## 10. Checklist de Automação

### Checklist Diário

- [ ] **05:00** — Cron gerou plano diário? Verificar `cron.log`
  - Comando: `tail -5 ~/projeto/planejamento-diario/cron.log`
- [ ] **08:00** — Plano revisado e aprovado pelo Comandante?
- [ ] **08:00-18:00** — Tasks delegadas e em execução?
- [ ] **22:00** — Validação automática rodou? Verificar `validate.log`
  - Comando: `tail -15 ~/projeto/planejamento-diario/validate.log`
- [ ] **23:00** — Relatório gerado e publicado no Slack?
  - Comando: `ls -la ~/projeto/planejamento-diario/$(date +%Y-%m-%d)/RELATORIO.md`
- [ ] **23:30** — Git push automático executado?
  - Comando: `tail -3 ~/projeto/planejamento-diario/git-push.log`

### Checklist Semanal

- [ ] Verificar integridade do `INDICE.md` manualmente
- [ ] Revisar logs de validação da semana
- [ ] Verificar se todos os cron jobs estão ativos: `crontab -l`
- [ ] Backup do `~/.hermes/`
- [ ] Rotacionar logs antigos
- [ ] Revisar skills desatualizadas

### Checklist Mensal

- [ ] Rotação de chave SSH (se devido)
- [ ] Revisar tokens Slack (expiração)
- [ ] Verificar espaço em disco dos logs
- [ ] Atualizar repositório `agent-ops-workflow`: `git pull`
- [ ] Sincronizar skills: `hermes skill_manage sync --dir skills/`
- [ ] Verificar AGENTS.md (membros do time ainda são os mesmos?)

### Consolidado de Cron Jobs

Adicione TODAS estas linhas ao seu crontab:

```bash
# ─── Agent Ops Workflow — Cron Jobs Diários ────────────────────────────────

# 05:00 — Gerar plano diário (shell script)
0 5 * * * cd /Users/seu-usuario/Dev/agent-ops-workflow && \
  WORKFLOW_TEAM_NAME="Time Nova" WORKFLOW_PROJECT_NAME="Projeto Atlas" \
  ./scripts/gerar-plano-diario.sh /Users/seu-usuario/Dev/meu-projeto --tasks=5 \
  >> /Users/seu-usuario/Dev/meu-projeto/planejamento-diario/cron.log 2>&1

# 05:30 — Gerar plano diário via Orquestrador Hermes (opcional, alternativa ao shell)
# 30 5 * * * cd /Users/seu-usuario/Dev/agent-ops-workflow && \
#   hermes --profile orquestrador run \
#     --skills planejamento-diario \
#     --prompt "Gere o plano diario de hoje para o Time Nova no Projeto Atlas" \
#     >> /Users/seu-usuario/Dev/meu-projeto/planejamento-diario/hermes-plan.log 2>&1

# 22:00 — Validar integridade do workflow
0 22 * * * /Users/seu-usuario/Dev/agent-ops-workflow/scripts/validate-workflow.sh \
  /Users/seu-usuario/Dev/meu-projeto --fix \
  >> /Users/seu-usuario/Dev/meu-projeto/planejamento-diario/validate.log 2>&1

# 23:00 — Gerar relatório diário
0 23 * * * cd /Users/seu-usuario/Dev/agent-ops-workflow && \
  WORKFLOW_TEAM_NAME="Time Nova" SLACK_WEBHOOK_URL="seu-webhook" \
  SLACK_HOME_CHANNEL="C0123456789" \
  ./scripts/gerar-relatorio.sh /Users/seu-usuario/Dev/meu-projeto \
  >> /Users/seu-usuario/Dev/meu-projeto/planejamento-diario/relatorio.log 2>&1

# 23:30 — Git push automático
30 23 * * * cd /Users/seu-usuario/Dev/meu-projeto && \
  git add -A && \
  git commit -m "daily: atualizacao $(date +%Y-%m-%d)" --allow-empty && \
  git push \
  >> /Users/seu-usuario/Dev/meu-projeto/planejamento-diario/git-push.log 2>&1

# ─── Cron Jobs Semanais ────────────────────────────────────────────────────

# Domingo 03:00 — Backup da configuração Hermes
0 3 * * 0 /Users/seu-usuario/Dev/agent-ops-workflow/scripts/backup-hermes-config.sh \
  >> /Users/seu-usuario/Dev/meu-projeto/planejamento-diario/backup.log 2>&1

# Domingo 04:00 — Limpeza de logs
0 4 * * 0 /Users/seu-usuario/Dev/agent-ops-workflow/scripts/rotate-logs.sh

# ─── Variáveis de Ambiente do Cron ─────────────────────────────────────────
# Certifique-se de que o PATH inclui os binários necessários
# PATH=/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin
```

### Monitoramento de logs

```bash
# Verificar todos os logs de automação do dia
echo "=== Cron Log ===" && tail -3 ~/projeto/planejamento-diario/cron.log
echo "=== Validate Log ===" && tail -3 ~/projeto/planejamento-diario/validate.log
echo "=== Git Push Log ===" && tail -3 ~/projeto/planejamento-diario/git-push.log
echo "=== Relatório ===" && ls -la ~/projeto/planejamento-diario/$(date +%Y-%m-%d)/RELATORIO.md 2>/dev/null || echo "Sem relatório hoje"
```

### Quick Reference — Comandos Úteis

```bash
# Setup inicial (uma vez)
./scripts/setup-workflow.sh ~/meu-projeto "Time Nova" "Projeto Atlas"

# Gerar plano manualmente
./scripts/gerar-plano-diario.sh ~/meu-projeto

# Validar workflow
./scripts/validate-workflow.sh ~/meu-projeto --fix

# Validar com detalhes
./scripts/validate-workflow.sh ~/meu-projeto --verbose --fix

# Gerar relatório manual
./scripts/gerar-relatorio.sh ~/meu-projeto

# Rotacionar chave SSH
./scripts/rotate-key.sh id_nova

# Ver cron jobs
crontab -l

# Editar cron jobs
crontab -e

# Ver logs
tail -f ~/meu-projeto/planejamento-diario/cron.log
tail -f ~/meu-projeto/planejamento-diario/validate.log

# Hermes: gerar plano com IA
hermes --profile orquestrador run --skills planejamento-diario \
  --prompt "Gere o plano diario de hoje para o Time Nova"

# Hermes: criar cron job nativo
hermes --profile orquestrador cronjob create \
  --name "plano-diario-5am" \
  --schedule "0 5 * * *" \
  --skills planejamento-diario \
  --prompt "Gere o plano diario de hoje"

# Hermes: listar cron jobs
hermes --profile orquestrador cronjob list

# Hermes: auditoria
hermes --profile orquestrador run --skills execucao-wave-auditoria \
  --prompt "Audite o dia de hoje no Projeto Atlas"
```

---

> **Nota final:** A automação no Agent Ops Workflow é dividida em dois
> grandes grupos: **automação operacional** (shell scripts, cron, git) que
> garante a execução previsível e confiável do ciclo diário, e **automação
> inteligente** (Hermes agent, skills, IA) que traz contexto, adaptabilidade
> e tomada de decisão para o fluxo. Use os dois em conjunto — o shell para
> o que é repetitivo e deterministico, o Hermes para o que requer análise
> e julgamento.
