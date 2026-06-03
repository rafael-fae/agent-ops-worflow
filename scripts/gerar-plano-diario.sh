#!/bin/bash
# =============================================================================
#  gerar-plano-diario.sh — Geração Automática de Plano Diário (Cron Job)
#  =============================================================================
#  Lê PLANO.md.tpl, substitui placeholders pela data atual, cria a pasta
#  YYYY-MM-DD/ e gera um PLANO.md com estrutura vazia (waves editáveis).
#
#  Uso:
#    ./scripts/gerar-plano-diario.sh <diretório-do-projeto> [opções]
#
#  Opções:
#    --tasks=N     Número de tasks esqueleto por wave (default: 5)
#    --force, -f   Sobrescrever se a pasta do dia já existir
#    --help, -h    Mostra esta ajuda
#
#  Exemplos:
#    ./scripts/gerar-plano-diario.sh ~/meu-projeto
#    ./scripts/gerar-plano-diario.sh ~/meu-projeto --tasks=8
#    ./scripts/gerar-plano-diario.sh ~/meu-projeto --force
#
#  Cron (execução diária às 5h):
#    0 5 * * * /caminho/scripts/gerar-plano-diario.sh ~/meu-projeto >> ~/meu-projeto/planejamento-diario/cron.log 2>&1
#
#  Variáveis de ambiente:
#    WORKFLOW_TEAM_NAME     — nome do time para o plano
#    WORKFLOW_PROJECT_NAME  — nome do projeto para o plano
#
#  Dependências: bash >= 4, cp, mkdir, date, openssl (opcional para --tasks)
# =============================================================================

set -euo pipefail

# ─── Configurações padrão ──────────────────────────────────────────────────
TASKS_POR_WAVE=5
FORCE_MODE=false

# ─── Cores para output ─────────────────────────────────────────────────────
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
AZUL='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${AZUL}[INFO]${NC}  $*"; }
ok()    { echo -e "${VERDE}[OK]${NC}    $*"; }
warn()  { echo -e "${AMARELO}[WARN]${NC}  $*"; }
erro()  { echo -e "${VERMELHO}[ERRO]${NC} $*" >&2; }

# ─── Função de ajuda ───────────────────────────────────────────────────────
show_help() {
    cat <<EOF
Uso: $(basename "$0") <diretório-do-projeto> [opções]

Gera automaticamente o plano diário (PLANO.md) para a data atual dentro da
estrutura planejamento-diario/ do projeto.

Opções:
  --tasks=N     Número de tasks esqueleto por wave (default: 5)
  --force, -f   Sobrescrever se a pasta do dia já existir
  --help, -h    Mostra esta ajuda

Exemplos:
  $(basename "$0") ~/meu-projeto
  $(basename "$0") ~/meu-projeto --tasks=8
  $(basename "$0") ~/meu-projeto --force

Variáveis de ambiente:
  WORKFLOW_TEAM_NAME     nome do time
  WORKFLOW_PROJECT_NAME  nome do projeto

Para cron:
  0 5 * * * $(basename "$0") ~/meu-projeto >> ~/meu-projeto/planejamento-diario/cron.log 2>&1
EOF
    exit 0
}

# ─── Parsing de argumentos ─────────────────────────────────────────────────
if [ $# -eq 0 ]; then
    erro "Diretório do projeto é obrigatório."
    echo ""
    show_help
fi

TARGET_DIR=""
for arg in "$@"; do
    case "$arg" in
        --help|-h)
            show_help
            ;;
        --tasks=*)
            TASKS_POR_WAVE="${arg#*=}"
            if ! [[ "$TASKS_POR_WAVE" =~ ^[0-9]+$ ]] || [ "$TASKS_POR_WAVE" -lt 1 ]; then
                erro "--tasks deve ser um número positivo. Usando default (5)."
                TASKS_POR_WAVE=5
            fi
            ;;
        --force|-f)
            FORCE_MODE=true
            ;;
        *)
            if [ -z "$TARGET_DIR" ]; then
                TARGET_DIR="$arg"
            fi
            ;;
    esac
done

if [ -z "$TARGET_DIR" ]; then
    erro "Diretório do projeto é obrigatório."
    show_help
fi

# Expandir ~ se presente
TARGET_DIR="${TARGET_DIR/#\~/$HOME}"

# ─── Validar diretório do projeto ──────────────────────────────────────────
if [ ! -d "$TARGET_DIR" ]; then
    erro "Diretório não encontrado: $TARGET_DIR"
    exit 1
fi

PD_DIR="$TARGET_DIR/planejamento-diario"
TEMPLATES_DIR="$PD_DIR/TEMPLATES"
CRON_LOG="$PD_DIR/cron.log"

if [ ! -d "$TEMPLATES_DIR" ]; then
    erro "Pasta de templates não encontrada em: $TEMPLATES_DIR"
    erro "Execute setup-workflow.sh primeiro para criar a estrutura."
    exit 1
fi

# ─── Data atual ────────────────────────────────────────────────────────────
DATA_ATUAL="$(date +%Y-%m-%d)"
DATA_BR="$(date +%d/%m/%Y)"
DIA_DIR="$PD_DIR/$DATA_ATUAL"

# ─── Verificar se a pasta do dia já existe ─────────────────────────────────
if [ -d "$DIA_DIR" ] && [ "$FORCE_MODE" = false ]; then
    warn "Pasta do dia já existe: $DIA_DIR"
    warn "Use --force para sobrescrever."
    exit 0
fi

if [ -d "$DIA_DIR" ] && [ "$FORCE_MODE" = true ]; then
    warn "Sobrescrevendo pasta existente: $DIA_DIR"
    rm -rf "$DIA_DIR"
fi

# ─── Criar pasta do dia ────────────────────────────────────────────────────
mkdir -p "$DIA_DIR"
ok "Pasta criada: $DIA_DIR"

# ─── Ler configurações do INDICE.md (se existir) ──────────────────────────
TEAM_NAME="${WORKFLOW_TEAM_NAME:-Time Padrão}"
PROJECT_NAME="${WORKFLOW_PROJECT_NAME:-Projeto Padrão}"

if [ -f "$PD_DIR/INDICE.md" ]; then
    # Tentar extrair nome do projeto do INDICE.md
    extracted_project=$(grep -m1 "^# Índice de Planejamento — " "$PD_DIR/INDICE.md" 2>/dev/null | sed 's/^# Índice de Planejamento — //')
    [ -n "$extracted_project" ] && PROJECT_NAME="$extracted_project"
fi

# ─── Verificar se template PLANO.md existe ─────────────────────────────────
PLANO_TPL="$TEMPLATES_DIR/PLANO.md"
if [ ! -f "$PLANO_TPL" ]; then
    warn "Template PLANO.md não encontrado em $PLANO_TPL"
    warn "Criando plano minimalista sem template."
    PLANO_TPL=""
fi

# ─── Gerar PLANO.md ────────────────────────────────────────────────────────
PLANO_FILE="$DIA_DIR/PLANO.md"

if [ -n "$PLANO_TPL" ] && [ -f "$PLANO_TPL" ]; then
    # Usar template como base
    cp "$PLANO_TPL" "$PLANO_FILE"

    # Substituir placeholders no template
    # Usar sed com delimitador alternativo (#) para evitar conflito com /
    sed -i \
        -e "s#__DATA__#$DATA_BR#g" \
        -e "s#__NOME_DO_PROJETO__#$PROJECT_NAME#g" \
        -e "s#__NOME_DO_TIME__#$TEAM_NAME#g" \
        -e "s#__COMANDANTE__#Comandante#g" \
        "$PLANO_FILE"

    ok "PLANO.md gerado a partir do template."
else
    # Criar PLANO.md minimalista
    cat > "$PLANO_FILE" <<PLANOEOF
# Plano de Execução — $PROJECT_NAME

**Criado por:** gerar-plano-diario.sh / $TEAM_NAME
**Data:** $DATA_BR
**Propósito:** Planejamento diário automático

---

## 📚 RECURSOS DO PROJETO

| Recurso | Local | Propósito |
|---------|-------|-----------|
| Repositório | $(basename "$TARGET_DIR") | Código fonte |
| Índice | planejamento-diario/INDICE.md | Acompanhamento |

---

## Resumo

Plano gerado automaticamente para o dia $DATA_BR.

---

## Waves

### Wave 1 — Manhã 🔴

| Task | Descrição | Agente | Motor | Prioridade | Status |
|:----:|-----------|:------:|:-----:|:----------:|:------:|
PLANOEOF

    # Adicionar tasks esqueleto na Wave 1
    for i in $(seq 1 "$TASKS_POR_WAVE"); do
        printf "| task_%02d | — | — | — | 🔴 | ⬜ |\n" "$i" >> "$PLANO_FILE"
    done

    cat >> "$PLANO_FILE" <<PLANOEOF2

**Objetivo:** Tasks da manhã executadas.

---

### Wave 2 — Tarde 🟡

| Task | Descrição | Agente | Motor | Prioridade | Status |
|:----:|-----------|:------:|:-----:|:----------:|:------:|
PLANOEOF2

    for i in $(seq $((TASKS_POR_WAVE + 1)) $((TASKS_POR_WAVE * 2))); do
        printf "| task_%02d | — | — | — | 🟡 | ⬜ |\n" "$i" >> "$PLANO_FILE"
    done

    cat >> "$PLANO_FILE" <<PLANOEOF3
**Objetivo:** Tasks da tarde executadas.

---

### Wave 3 — Noite 🟢

| Task | Descrição | Agente | Motor | Prioridade | Status |
|:----:|-----------|:------:|:-----:|:----------:|:------:|
PLANOEOF3

    for i in $(seq $((TASKS_POR_WAVE * 2 + 1)) $((TASKS_POR_WAVE * 3))); do
        printf "| task_%02d | — | — | — | 🟢 | ⬜ |\n" "$i" >> "$PLANO_FILE"
    done

    cat >> "$PLANO_FILE" <<PLANOEOF4

**Objetivo:** Tasks da noite executadas.

---

## ⚠️ REGRAS DA EXECUÇÃO

1. **Motor padrão:** Gemini CLI
2. **NUNCA modificar arquivos originais**
3. **Commit semântico** Commits descritivos

---

## Ao final do dia

- [ ] 0/$((TASKS_POR_WAVE * 3)) tasks concluídas e auditadas
- [ ] INDICE.md atualizado com status do dia
- [ ] Todos os commits feitos e push realizado
PLANOEOF4

    ok "PLANO.md gerado (modo minimalista, $((TASKS_POR_WAVE * 3)) tasks esqueleto)."
fi

# ─── Registrar no cron.log ─────────────────────────────────────────────────
{
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Plano gerado: $DIA_DIR/PLANO.md"
    echo "  Projeto: $PROJECT_NAME | Time: $TEAM_NAME"
    echo "  Tasks por wave: $TASKS_POR_WAVE | Force: $FORCE_MODE"
} >> "$CRON_LOG"

# ─── Log de saída ──────────────────────────────────────────────────────────
info "Plano diário gerado com sucesso:"
info "  Local: $PLANO_FILE"
info "  Data: $DATA_BR"
info "  Tasks por wave: $TASKS_POR_WAVE"

if [ "$FORCE_MODE" = false ]; then
    info "  Dica: Use --force para sobrescrever planos existentes."
fi
