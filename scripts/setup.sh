#!/bin/bash
# =============================================================================
# setup.sh — Automatização da Configuração da Equipe Roshar Multi-Agente
# =============================================================================
# Script interativo para provisionamento completo da Equipe Roshar.
#
# Uso:
#   ./scripts/setup.sh [--dry-run]
# =============================================================================

set -euo pipefail

# ─── Cores para Output ────────────────────────────────────────────────────────
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
AZUL='\033[0;34m'
NC='\033[0m' # Sem cor

# ─── Funções de Log ───────────────────────────────────────────────────────────
info()  { echo -e "${AZUL}[INFO]${NC}  $*"; }
ok()    { echo -e "${VERDE}[OK]${NC}    $*"; }
warn()  { echo -e "${AMARELO}[WARN]${NC}  $*"; }
erro()  { echo -e "${VERMELHO}[ERRO]${NC} $*" >&2; }

# ─── Trap para Interrupções (Ctrl+C) ──────────────────────────────────────────
trap 'echo -e "\n${VERMELHO}[ERRO]${NC} Operação cancelada pelo usuário."; exit 1' INT TERM

# ─── Variáveis Globais ────────────────────────────────────────────────────────
DRY_RUN=false
ORCHESTRATOR="dalinar"
AGENT_LIST_INPUT="navani,shallan,jasnah,kaladin,pattern"
PROJECT_DIR=""
TIMEZONE="America/Campo_Grande"
SLACK_HOME_CHANNEL=""
SLACK_BOT_TOKEN=""
SLACK_APP_TOKEN=""
OPENCODE_GO_API_KEY=""
GITHUB_TOKEN=""

# ─── Parsing de Argumentos ────────────────────────────────────────────────────
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            ;;
    esac
done

if [ "$DRY_RUN" = true ]; then
    echo -e "${AMARELO}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${AMARELO}║                  MODO DRY-RUN ATIVADO                        ║${NC}"
    echo -e "${AMARELO}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
fi

# ─── Auxiliares de Arquivos ───────────────────────────────────────────────────
make_dir() {
    local dir="$1"
    if [ "$DRY_RUN" = true ]; then
        info "[DRY-RUN] Criaria diretório: $dir"
    else
        mkdir -p "$dir"
    fi
}

write_file() {
    local file="$1"
    local content="$2"
    if [ "$DRY_RUN" = true ]; then
        info "[DRY-RUN] Criaria arquivo: $file"
    else
        mkdir -p "$(dirname "$file")"
        echo "$content" > "$file"
    fi
}

show_progress() {
    local msg="$1"
    echo -n -e "${AMARELO}[...]${NC} ${msg}"
    sleep 0.1
    echo -e "\r${VERDE}[OK]${NC}  ${msg}"
}

# ─── FASES DO SCRIPT ──────────────────────────────────────────────────────────

# PHASE 1: Team Definition
phase_1_team_definition() {
    echo -e "\n${AZUL}=================================================================${NC}"
    echo -e "${AZUL}            FASE 1: Definição da Equipe Roshar                   ${NC}"
    echo -e "${AZUL}=================================================================${NC}"

    # Orquestrador
    read -r -p "Nome do orquestrador [dalinar]: " input_orch
    ORCHESTRATOR=${input_orch:-$ORCHESTRATOR}

    # Outros agentes
    read -r -p "Nomes dos outros agentes (separados por vírgula) [navani,shallan,jasnah,kaladin,pattern]: " input_agents
    AGENT_LIST_INPUT=${input_agents:-$AGENT_LIST_INPUT}

    # Diretório do projeto
    local default_proj_dir="$HOME/Dev/meu-projeto"
    read -r -p "Diretório do projeto [$default_proj_dir]: " input_proj_dir
    PROJECT_DIR=${input_proj_dir:-$default_proj_dir}
    PROJECT_DIR="${PROJECT_DIR/#\~/$HOME}"

    # Timezone
    read -r -p "Timezone do time [America/Campo_Grande]: " input_tz
    TIMEZONE=${input_tz:-$TIMEZONE}

    # Slack Integration (Optional)
    echo ""
    read -r -p "Deseja configurar Slack para os agentes agora? [s/N]: " input_slack
    if [[ "$input_slack" =~ ^[Ss]$ ]]; then
        read -r -p "Slack Home Channel ID (ex: C0B6DUQGJSX): " SLACK_HOME_CHANNEL
        read -r -p "Slack Bot Token (xoxb-...): " SLACK_BOT_TOKEN
        read -r -p "Slack App Token (xapp-...): " SLACK_APP_TOKEN
    fi

    # API Keys
    echo ""
    read -r -p "OpenCode API Key (opcional): " OPENCODE_GO_API_KEY
    read -r -p "GitHub Token / PAT (opcional): " GITHUB_TOKEN

    # Parse dos agentes em array
    IFS=',' read -ra ADDS <<< "$AGENT_LIST_INPUT"
    ALL_AGENTS=("$ORCHESTRATOR")
    for a in "${ADDS[@]}"; do
        ALL_AGENTS+=("$(echo "$a" | xargs)")
    done

    ok "Configurações da fase 1 recebidas com sucesso!"
}

# PHASE 2: Profile Creation
phase_2_profile_creation() {
    echo -e "\n${AZUL}=================================================================${NC}"
    echo -e "${AZUL}            FASE 2: Criação dos Perfis de Agentes                ${NC}"
    echo -e "${AZUL}=================================================================${NC}"

    for agent in "${ALL_AGENTS[@]}"; do
        local profile_dir="$HOME/.hermes/profiles/$agent"
        show_progress "Provisionando perfil para o agente: $agent"

        # Criar diretórios
        make_dir "$profile_dir"
        make_dir "$profile_dir/operacional"
        make_dir "$profile_dir/skills"
        make_dir "$profile_dir/sessions"
        make_dir "$profile_dir/memories"
        make_dir "$profile_dir/logs"

        # Configurar Prompt do Sistema
        local system_prompt="Você é o agente '$agent' da Equipe Roshar.
Sua personalidade está definida em: $profile_dir/SOUL.md
Sua identidade e papel de autoridade estão em: $profile_dir/IDENTITY.md
O protocolo de operação do time está em: $profile_dir/TEAM.md
O mapa completo dos outros agentes está em: $profile_dir/AGENTS.md

PROTOCOLO OPERACIONAL OBRIGATÓRIO (PROTOCOLO DIARIO):
1. SILENCE PROTOCOL: Quando o comandante humano mencionar um agente específico no canal ou thread, APENAS esse agente responde. Os demais devem permanecer em silêncio absoluto.
2. MENTION PROTOCOL: Toda a comunicação agente->agente no Slack deve usar menções reais no formato <@USER_ID>.
3. DIARIO PROTOCOL: A cada ciclo de trabalho, você DEVE registrar seu progresso operacional no arquivo absoluto: $profile_dir/operacional/DIARIO.md
4. THREAD PROTOCOL: Toda a discussão de uma tarefa deve ocorrer estritamente na thread aberta para ela."

        # config.yaml
        local config_yaml="model:
  default: deepseek-v4-flash
  provider: opencode-go
  base_url: https://opencode.ai/zen/go/v1
  api_mode: chat_completions
providers: {}
fallback_providers: []
credential_pool_strategies: {}
toolsets:
- hermes-cli
- web
- browser
- terminal
- file
- skills
- memory
- session_search
- todo
- delegation
- messaging
- cronjob
- clarify
- vision
agent:
  max_turns: 90
  gateway_timeout: 1800
  restart_drain_timeout: 60
  service_tier: ''
  tool_use_enforcement: auto
  gateway_timeout_warning: 600
  gateway_notify_interval: 600
  system_prompt: |
$(echo "$system_prompt" | sed 's/^/    /')
approvals:
  mode: auto
  timeout: 60
  auto_approve_patterns:
  - \"python* -c \\\"import ast*\"
  - \"python* -c \\\"import py_compile*\"
  - \"python* -c \\\"import os*\"
  - \"python* -c \\\"print*\"
  - \"git log*\"
  - \"git show*\"
  - \"git status*\"
  - \"git diff*\"
  - \"git branch*\"
  - \"cat *\"
  - \"head *\"
  - \"tail *\"
  - \"wc *\"
  - \"find *\"
  - \"grep *\"
  - \"ls *\"
  - \"mkdir *\"
  - \"pwd*\"
  - \"echo*\"
  - \"which*\"
  - \"file *\"
  - \"stat *\"
  - \"python* -m py_compile*\"
  - \"git add*\"
  - \"git commit*\"
  - \"git push*\"
  - \"python manage.py check*\"
  - \"python manage.py showmigrations*\"
  - \"python manage.py sqlmigrate*\"
  timezone: '$TIMEZONE'"

        write_file "$profile_dir/config.yaml" "$config_yaml"

        # .env
        local env_content="# .env para $agent
SLACK_BOT_TOKEN='${SLACK_BOT_TOKEN:-PLACEholder_slack_bot_token}'
SLACK_APP_TOKEN='${SLACK_APP_TOKEN:-PLACEholder_slack_app_token}'
SLACK_HOME_CHANNEL='${SLACK_HOME_CHANNEL:-PLACEholder_slack_home_channel}'
SLACK_REQUIRE_MENTION=true
OPENCODE_GO_API_KEY='${OPENCODE_GO_API_KEY:-PLACEholder_opencode_go_api_key}'
GITHUB_TOKEN='${GITHUB_TOKEN:-PLACEholder_github_token}'"

        write_file "$profile_dir/.env" "$env_content"

        # AGENTS.md
        local agents_md="# AGENTS.md — Registro de Agentes

Este arquivo lista os agentes e define os protocolos de comunicação do time.

## Lista de Agentes do Time

| Nome do Agente | Tipo | Perfil do Hermes |
|----------------|------|------------------|
| $ORCHESTRATOR | Orquestrador | ~/.hermes/profiles/$ORCHESTRATOR |"

        for a in "${ALL_AGENTS[@]}"; do
            if [ "$a" != "$ORCHESTRATOR" ]; then
                agents_md="$agents_md
| $a | Agente | ~/.hermes/profiles/$a |"
            fi
        done

        agents_md="$agents_md

## Protocolos Operacionais

### 1. Silence Protocol
Quando o Comandante (humano) menciona um agente específico em um canal ou thread, APENAS o agente mencionado pode responder. Todos os outros agentes devem permanecer em silêncio absoluto.

### 2. Mention Protocol
Toda a comunicação agente-para-agente deve usar menções reais do Slack no formato \`<@USER_ID>\`. Menções puramente textuais são proibidas.

### 3. DIARIO+ESTADO Protocol
Cada agente deve manter seu próprio diário operacional atualizado em seu perfil local em \`operacional/DIARIO.md\` no final de cada onda.
O orquestrador deve atualizar o estado global da equipe em \`operacional/ESTADO-DA-EQUIPE.md\`.

### 4. Thread Protocol
Toda a discussão técnica, planejamento e reporte de progresso de uma tarefa deve ocorrer estritamente na thread aberta para aquela tarefa."

        write_file "$profile_dir/AGENTS.md" "$agents_md"

        # SOUL.md & IDENTITY.md
        if [ "$agent" = "$ORCHESTRATOR" ]; then
            # Orchestrator
            local soul_md="# SOUL.md — $agent (Orquestrador)

Você é o Orquestrador estratégico da Equipe Roshar.
Sua postura é firme, direta e focada em resultados.
Você analisa as demandas do Comandante humano e as delega com precisão aos especialistas."

            local identity_md="# IDENTITY.md — $agent

## Papel
Orquestrador e estrategista do time.

## Autoridade
- Decompor demandas em tarefas específicas.
- Delegar tarefas aos especialistas do time.
- Auditar entregas finais.
- Aprovar encerramento de tarefas."
        else
            # Specialist agent
            local soul_md="# SOUL.md — $agent (Especialista)

Você é um agente especialista e executor de alta performance.
Sua comunicação é estritamente técnica, precisa e focada em resolver as tarefas delegadas pelo Orquestrador."

            local identity_md="# IDENTITY.md — $agent

## Papel
Especialista executor no time.

## Autoridade
- Analisar e diagnosticar tarefas atribuídas a você.
- Propor planos de execução na thread da tarefa.
- Escrever código e executar testes.
- Reportar progresso e commits realizados."
        fi

        write_file "$profile_dir/SOUL.md" "$soul_md"
        write_file "$profile_dir/IDENTITY.md" "$identity_md"

        # TEAM.md
        local team_md="# TEAM.md — Protocolo da Equipe Roshar

Este documento descreve as regras de hierarquia e fluxos operacionais do time de agentes.

## Hierarquia e Funções
- **Comandante (Humano)**: Define metas, prioridades e concede o Sinal Verde.
- **Orquestrador ($ORCHESTRATOR)**: Decompõe e delega tarefas, gerencia o estado do time.
- **Membros do Time**: Executam tarefas delegadas em suas threads específicas.

## Fluxo de Trabalho
1. Planejamento do dia em \`planejamento-diario/\`.
2. Delegação de tarefas via Slack/Terminal.
3. Criação do plano e diagnóstico pelo executor na thread.
4. Sinal Verde do Comandante.
5. Execução, testes, auditoria e commit.
6. Atualização do \`DIARIO.md\` e do \`ESTADO-DA-EQUIPE.md\`."

        write_file "$profile_dir/TEAM.md" "$team_md"

        # operacional/DIARIO.md
        local diario_md="# Diário de Operação — $agent

## Registro de Atividades Diárias

| Data | Wave/Turno | ID da Task | Atividades / Commits | Status |
|------|------------|------------|----------------------|--------|
|      |            |            |                      | ⬜/🔴/✅ |"

        write_file "$profile_dir/operacional/DIARIO.md" "$diario_md"
    done

    ok "Criação de perfis concluída!"
}

# PHASE 3: Shared Files (Orchestrator only)
phase_3_shared_files() {
    echo -e "\n${AZUL}=================================================================${NC}"
    echo -e "${AZUL}            FASE 3: Arquivos Compartilhados e Orquestração       ${NC}"
    echo -e "${AZUL}=================================================================${NC}"

    local orch_dir="$HOME/.hermes/profiles/$ORCHESTRATOR"
    show_progress "Configurando arquivos exclusivos do orquestrador: $ORCHESTRATOR"

    # ESTADO-DA-EQUIPE.md
    local estado_md="# Estado da Equipe — Controle Global

**Orquestrador:** $ORCHESTRATOR
**Timezone:** $TIMEZONE

## Painel de Agentes

| Agente | Tipo | Status Operacional | Última Atividade |
|--------|------|--------------------|------------------|
| $ORCHESTRATOR | Orquestrador | [Ativo] | |"

    for a in "${ALL_AGENTS[@]}"; do
        if [ "$a" != "$ORCHESTRATOR" ]; then
            estado_md="$estado_md
| $a | Especialista | [Pendente] | |"
        fi
    done

    estado_md="$estado_md

## Controle de Tasks do Dia

| Task ID | Descrição | Responsável | Wave | Status | Commit Hash |
|---------|-----------|-------------|------|--------|-------------|
| | | | | ⬜/🔴/✅ | |

## Bloqueios Ativos e Notas
- Nenhum bloqueio registrado."

    write_file "$orch_dir/operacional/ESTADO-DA-EQUIPE.md" "$estado_md"

    # Copiar 15 essential skills
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local repo_root
    repo_root="$(cd "$script_dir/.." && pwd)"

    if [ -d "$repo_root/skills" ]; then
        show_progress "Copiando as 15 skills essenciais do repositório..."
        make_dir "$orch_dir/skills"
        if [ "$DRY_RUN" = true ]; then
            info "[DRY-RUN] Copiaria skills de $repo_root/skills para $orch_dir/skills/"
        else
            find "$repo_root/skills" -name "SKILL.md" | while read -r skill_file; do
                local skill_dir
                skill_dir=$(dirname "$skill_file")
                local skill_name
                skill_name=$(basename "$skill_dir")
                cp -R "$skill_dir" "$orch_dir/skills/"
                ok "Skill instalada: $skill_name"
            done
        fi
    else
        warn "Diretório de skills não encontrado no repositório ($repo_root/skills). Pulando cópia."
    fi

    # Criar estrutura planejamento-diario no diretório do projeto
    show_progress "Criando estrutura de planejamento diário no projeto..."
    local pd_dir="$PROJECT_DIR/planejamento-diario"
    make_dir "$pd_dir"

    # Copiar ou criar INDICE.md
    if [ -f "$repo_root/templates/INDICE.md.tpl" ]; then
        if [ "$DRY_RUN" = true ]; then
            info "[DRY-RUN] Copiaria INDICE.md de templates/INDICE.md.tpl"
        else
            cp "$repo_root/templates/INDICE.md.tpl" "$pd_dir/INDICE.md"
        fi
    else
        local default_indice="# Índice de Planejamento Diário

## Controle de Execução

| Data | Tarefa | Descrição | Wave | Status | Commit |
|------|--------|-----------|------|--------|--------|
| | | | | ⬜/✅ | |"
        write_file "$pd_dir/INDICE.md" "$default_indice"
    fi

    # Copiar ou criar TEMPLATE_PLANO.md
    if [ -f "$repo_root/templates/PLANO.md.tpl" ]; then
        if [ "$DRY_RUN" = true ]; then
            info "[DRY-RUN] Copiaria TEMPLATE_PLANO.md de templates/PLANO.md.tpl"
        else
            cp "$repo_root/templates/PLANO.md.tpl" "$pd_dir/TEMPLATE_PLANO.md"
        fi
    else
        local default_plano="# Plano Diário — __DATE__

## Waves

### Wave 1
| Task | Descrição | Agente | Prioridade | Status |
|------|-----------|--------|------------|--------|"
        write_file "$pd_dir/TEMPLATE_PLANO.md" "$default_plano"
    fi

    # Copiar ou criar TEMPLATE_TASK.md
    if [ -f "$repo_root/templates/TASK.md.tpl" ]; then
        if [ "$DRY_RUN" = true ]; then
            info "[DRY-RUN] Copiaria TEMPLATE_TASK.md de templates/TASK.md.tpl"
        else
            cp "$repo_root/templates/TASK.md.tpl" "$pd_dir/TEMPLATE_TASK.md"
        fi
    else
        local default_task="# Task: __TASK_ID__

## Descrição
__DESCRIPTION__"
        write_file "$pd_dir/TEMPLATE_TASK.md" "$default_task"
    fi

    ok "Arquivos compartilhados configurados!"
}

# PHASE 4: Timezone and Config
phase_4_timezone_and_config() {
    echo -e "\n${AZUL}=================================================================${NC}"
    echo -e "${AZUL}            FASE 4: Ajustes de Timezone e Permissões             ${NC}"
    echo -e "${AZUL}=================================================================${NC}"

    show_progress "Ajustando timezone '$TIMEZONE' em todas as configurações..."
    for agent in "${ALL_AGENTS[@]}"; do
        local profile_dir="$HOME/.hermes/profiles/$agent"
        if [ "$DRY_RUN" = true ]; then
            info "[DRY-RUN] Atualizaria timezone em $profile_dir/config.yaml"
        else
            if [ -f "$profile_dir/config.yaml" ]; then
                sed -i '' "s/timezone: .*/timezone: '$TIMEZONE'/g" "$profile_dir/config.yaml" 2>/dev/null || \
                sed -i "s/timezone: .*/timezone: '$TIMEZONE'/g" "$profile_dir/config.yaml"
            fi
        fi
    done

    echo ""
    read -r -p "Deseja verificar e corrigir permissões do macOS TCC (Full Disk Access)? [S/n]: " input_tcc
    input_tcc=${input_tcc:-S}
    if [[ "$input_tcc" =~ ^[Ss]$ ]]; then
        info "Abrindo painel de Privacidade e Segurança do macOS (Acesso Total ao Disco)..."
        if [ "$DRY_RUN" = false ]; then
            open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
        fi
        
        echo "=== Diagnóstico de Permissões macOS ==="
        for dir in ~/Desktop ~/Downloads ~/Documents ~/Library; do
            if ls "$dir" &>/dev/null 2>&1; then
                echo -e "  ${VERDE}✅${NC} $dir - Acesso Permitido"
            else
                echo -e "  ${VERMELHO}❌${NC} $dir - SEM ACESSO"
            fi
        done
        
        if ps aux &>/dev/null 2>&1; then
            echo -e "  ${VERDE}✅${NC} Lista de Processos - Permitido"
        else
            echo -e "  ${VERMELHO}❌${NC} Lista de Processos - SEM ACESSO"
        fi
        
        if osascript -e 'tell application "Finder" to get name of every process' &>/dev/null 2>&1; then
            echo -e "  ${VERDE}✅${NC} AppleScript Finder - Permitido"
        else
            echo -e "  ${VERMELHO}❌${NC} AppleScript Finder - SEM ACESSO"
        fi
    fi

    ok "Ajustes de timezone e permissões finalizados."
}

# PHASE 5: Gateway Launch
phase_5_gateway_launch() {
    echo -e "\n${AZUL}=================================================================${NC}"
    echo -e "${AZUL}            FASE 5: Inicialização dos Gateways                   ${NC}"
    echo -e "${AZUL}=================================================================${NC}"

    read -r -p "Deseja iniciar os gateways do Hermes para todos os agentes agora? [s/N]: " input_launch
    input_launch=${input_launch:-N}
    if [[ "$input_launch" =~ ^[Ss]$ ]]; then
        local hermes_bin
        hermes_bin=$(which hermes 2>/dev/null || echo "/Users/rafaelfae/Dev/Hermes/.venv/bin/hermes")
        
        for agent in "${ALL_AGENTS[@]}"; do
            local profile_dir="$HOME/.hermes/profiles/$agent"
            if [ "$DRY_RUN" = true ]; then
                info "[DRY-RUN] Iniciaria o gateway em background para o agente $agent"
            else
                rm -f "$profile_dir/gateway.pid"
                rm -f "$profile_dir/gateway.lock"
                
                nohup "$hermes_bin" --profile "$agent" gateway run > "$profile_dir/logs/gateway.log" 2>&1 &
                ok "Gateway do agente '$agent' iniciado em background."
            fi
        done
    fi

    echo ""
    info "Para checar o status dos gateways executando:"
    echo -e "  ${AMARELO}ps aux | grep hermes${NC}"
    echo "Para acompanhar os logs de cada agente:"
    for agent in "${ALL_AGENTS[@]}"; do
        echo "  tail -f ~/.hermes/profiles/$agent/logs/gateway.log"
    done
}

# PHASE 6: Validation
phase_6_validation() {
    echo -e "\n${AZUL}=================================================================${NC}"
    echo -e "${AZUL}            FASE 6: Validação do Setup                           ${NC}"
    echo -e "${AZUL}=================================================================${NC}"

    local valid=true

    # 1. Cada perfil com config.yaml, AGENTS.md, DIARIO.md
    for agent in "${ALL_AGENTS[@]}"; do
        local profile_dir="$HOME/.hermes/profiles/$agent"
        
        if [ -f "$profile_dir/config.yaml" ]; then
            echo -e " [${VERDE}OK${NC}] $agent: config.yaml está presente"
        else
            echo -e " [${VERMELHO}FALHA${NC}] $agent: config.yaml ausente"
            valid=false
        fi
        
        if [ -f "$profile_dir/AGENTS.md" ]; then
            echo -e " [${VERDE}OK${NC}] $agent: AGENTS.md está presente"
        else
            echo -e " [${VERMELHO}FALHA${NC}] $agent: AGENTS.md ausente"
            valid=false
        fi
        
        if [ -f "$profile_dir/operacional/DIARIO.md" ]; then
            echo -e " [${VERDE}OK${NC}] $agent: operacional/DIARIO.md está presente"
        else
            echo -e " [${VERMELHO}FALHA${NC}] $agent: operacional/DIARIO.md ausente"
            valid=false
        fi
    done

    # 2. ESTADO-DA-EQUIPE.md exists
    local orch_dir="$HOME/.hermes/profiles/$ORCHESTRATOR"
    if [ -f "$orch_dir/operacional/ESTADO-DA-EQUIPE.md" ]; then
        echo -e " [${VERDE}OK${NC}] Orquestrador: ESTADO-DA-EQUIPE.md está presente"
    else
        echo -e " [${VERMELHO}FALHA${NC}] Orquestrador: ESTADO-DA-EQUIPE.md ausente"
        valid=false
    fi

    # 3. Timezone set correctly
    local tz_check=true
    for agent in "${ALL_AGENTS[@]}"; do
        local profile_dir="$HOME/.hermes/profiles/$agent"
        if [ -f "$profile_dir/config.yaml" ]; then
            if ! grep -q "timezone: '$TIMEZONE'" "$profile_dir/config.yaml"; then
                tz_check=false
            fi
        else
            tz_check=false
        fi
    done

    if [ "$tz_check" = true ]; then
        echo -e " [${VERDE}OK${NC}] Timezone '$TIMEZONE' configurado em todos os perfis"
    else
        echo -e " [${VERMELHO}FALHA${NC}] Timezone configurado incorretamente em algum perfil"
        valid=false
    fi

    # 4. Skills instaladas
    local skills_count=0
    if [ -d "$orch_dir/skills" ]; then
        skills_count=$(find "$orch_dir/skills" -name "SKILL.md" | wc -l | xargs)
    fi
    if [ "$skills_count" -ge 15 ]; then
        echo -e " [${VERDE}OK${NC}] Skills instaladas com sucesso no orquestrador ($skills_count)"
    else
        echo -e " [${VERMELHO}FALHA${NC}] Algumas skills essenciais não foram copiadas ($skills_count de 15)"
        valid=false
    fi

    # 5. Planejamento-diario structure
    local pd_dir="$PROJECT_DIR/planejamento-diario"
    if [ -d "$pd_dir" ] && \
       [ -f "$pd_dir/INDICE.md" ] && \
       [ -f "$pd_dir/TEMPLATE_PLANO.md" ] && \
       [ -f "$pd_dir/TEMPLATE_TASK.md" ]; then
        echo -e " [${VERDE}OK${NC}] Estrutura planejamento-diario/ validada no projeto"
    else
        echo -e " [${VERMELHO}FALHA${NC}] Estrutura planejamento-diario/ inválida ou incompleta no projeto"
        valid=false
    fi

    echo ""
    if [ "$valid" = true ]; then
        ok "O time multi-agente Roshar está configurado e validado com sucesso!"
    else
        warn "O setup possui inconsistências. Por favor, verifique as falhas acima."
    fi
}

# ─── Execução Principal ───────────────────────────────────────────────────────
main() {
    phase_1_team_definition
    phase_2_profile_creation
    phase_3_shared_files
    phase_4_timezone_and_config
    phase_5_gateway_launch
    phase_6_validation
}

main
