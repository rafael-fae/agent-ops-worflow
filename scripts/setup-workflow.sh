#!/bin/bash
# =============================================================================
#  setup-workflow.sh — Script de Setup Inicial do Workflow
#  =============================================================================
#  Cria a estrutura planejamento-diario/ no diretório do usuário, copia
#  templates, gera INDICE.md inicial e pasta do dia atual com PLANO.md
#  esqueleto.
#
#  Uso:
#    ./scripts/setup-workflow.sh [diretório-alvo] ["Nome do Time"] ["Nome do Projeto"]
#
#  Exemplo:
#    ./scripts/setup-workflow.sh ~/meu-projeto "Meu Time" "Meu Projeto"
#
#  Variáveis de ambiente (fallback):
#    WORKFLOW_TEAM_NAME     — nome do time
#    WORKFLOW_PROJECT_NAME  — nome do projeto
#
#  Dependências: bash >= 4, cp, mkdir, date
# =============================================================================

set -euo pipefail

# ─── Cores para output ─────────────────────────────────────────────────────
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
AZUL='\033[0;34m'
NC='\033[0m' # sem cor

info()  { echo -e "${AZUL}[INFO]${NC}  $*"; }
ok()    { echo -e "${VERDE}[OK]${NC}    $*"; }
warn()  { echo -e "${AMARELO}[WARN]${NC}  $*"; }
erro()  { echo -e "${VERMELHO}[ERRO]${NC} $*" >&2; }

# ─── Função de limpeza em caso de erro ─────────────────────────────────────
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        erro "Script interrompido com código $exit_code."
        [ -n "${TARGET_DIR:-}" ] && [ -d "$TARGET_DIR/planejamento-diario" ] && \
            warn "A pasta $TARGET_DIR/planejamento-diario/ pode estar incompleta."
    fi
    exit $exit_code
}
trap cleanup EXIT

# ─── Função de ajuda ───────────────────────────────────────────────────────
show_help() {
    cat <<EOF
Uso: $(basename "$0") [diretório-alvo] ["Nome do Time"] ["Nome do Projeto"]

Cria a estrutura planejamento-diario/ no diretório-alvo com:
  - Pasta TEMPLATES/ com os templates
  - INDICE.md inicial
  - Pasta do dia atual com PLANO.md esqueleto

Se nenhum argumento for passado, o script opera interativamente.

Variáveis de ambiente:
  WORKFLOW_TEAM_NAME     fallback para nome do time
  WORKFLOW_PROJECT_NAME  fallback para nome do projeto

Exemplos:
  $(basename "$0") ~/meu-projeto "Time Alfa" "Projeto X"
  WORKFLOW_TEAM_NAME="Time A" $(basename "$0") ~/projeto
EOF
    exit 0
}

# ─── Parsing de argumentos ─────────────────────────────────────────────────
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    show_help
fi

# ─── Descobrir diretório raiz dos templates ─────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$PROJECT_ROOT/templates"

if [ ! -d "$TEMPLATES_DIR" ]; then
    erro "Pasta de templates não encontrada em: $TEMPLATES_DIR"
    erro "Execute este script a partir da raiz do projeto agent-ops-workflow."
    exit 1
fi

# ─── Definir diretório alvo ────────────────────────────────────────────────
if [ -n "${1:-}" ]; then
    TARGET_DIR="$1"
else
    # Modo interativo: perguntar diretório alvo
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║       Setup do Workflow de Planejamento Diário             ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    read -r -p "Diretório do projeto (ex: ~/meu-projeto): " TARGET_DIR
    TARGET_DIR="${TARGET_DIR/#\~/$HOME}"
fi

# Expandir ~ se presente
TARGET_DIR="${TARGET_DIR/#\~/$HOME}"

# Validar diretório alvo
if [ ! -d "$TARGET_DIR" ]; then
    warn "Diretório '$TARGET_DIR' não existe."
    read -r -p "Criar diretório? [S/n] " criar_dir
    if [ "$criar_dir" != "n" ] && [ "$criar_dir" != "N" ]; then
        mkdir -p "$TARGET_DIR"
        ok "Diretório criado: $TARGET_DIR"
    else
        erro "Diretório alvo é obrigatório. Abortando."
        exit 1
    fi
fi

# ─── Definir time e projeto ────────────────────────────────────────────────
TEAM_NAME="${2:-${WORKFLOW_TEAM_NAME:-}}"
PROJECT_NAME="${3:-${WORKFLOW_PROJECT_NAME:-}}"

# Modo interativo se não foram passados como argumento
if [ -z "$TEAM_NAME" ]; then
    read -r -p "Nome do time (ex: Time Alfa): " TEAM_NAME
    TEAM_NAME="${TEAM_NAME:-Time Padrão}"
fi

if [ -z "$PROJECT_NAME" ]; then
    read -r -p "Nome do projeto (ex: Projeto X): " PROJECT_NAME
    PROJECT_NAME="${PROJECT_NAME:-Projeto Padrão}"
fi

# ─── Perguntar motores ─────────────────────────────────────────────────────
MOTOR_PADRAO="Gemini CLI"
read -r -p "Motor padrão [Gemini CLI]: " motor_input
MOTOR_PADRAO="${motor_input:-$MOTOR_PADRAO}"

MOTORES_ADICIONAIS="Claude Code, OpenAI API, DeepSeek"
read -r -p "Outros motores (separados por vírgula) [Claude Code, OpenAI API, DeepSeek]: " motores_input
MOTORES_ADICIONAIS="${motores_input:-$MOTORES_ADICIONAIS}"

IDIOMA="pt-BR"
read -r -p "Idioma da documentação [pt-BR]: " idioma_input
IDIOMA="${idioma_input:-$IDIOMA}"

DATA_ATUAL="$(date +%Y-%m-%d)"
DATA_BR="$(date +%d/%m/%Y)"

info "Configuração:"
info "  Time:       $TEAM_NAME"
info "  Projeto:    $PROJECT_NAME"
info "  Motor:      $MOTOR_PADRAO"
info "  Motores:    $MOTORES_ADICIONAIS"
info "  Idioma:     $IDIOMA"
info "  Alvo:       $TARGET_DIR"
echo ""

# ─── 1. Criar estrutura de pastas ──────────────────────────────────────────
PD_DIR="$TARGET_DIR/planejamento-diario"
TEMPLATES_TARGET="$PD_DIR/TEMPLATES"
DIA_DIR="$PD_DIR/$DATA_ATUAL"

mkdir -p "$TEMPLATES_TARGET"
mkdir -p "$DIA_DIR"
ok "Estrutura de pastas criada em $PD_DIR"

# ─── 2. Copiar templates ──────────────────────────────────────────────────
for tpl in "$TEMPLATES_DIR"/*.tpl; do
    tpl_name="$(basename "$tpl")"
    target_name="${tpl_name%.tpl}"
    cp "$tpl" "$TEMPLATES_TARGET/$target_name"
    ok "Template copiado: $target_name"
done

# ─── 3. Criar INDICE.md inicial ────────────────────────────────────────────
INDICE_FILE="$PD_DIR/INDICE.md"

cat > "$INDICE_FILE" <<INDICEEOF
# Índice de Planejamento — $PROJECT_NAME

> **Propósito:** Este índice documenta o planejamento e progresso do projeto
> $PROJECT_NAME — um sistema de planejamento diário multi-agente.
>
> **Legenda:** ✅ = concluído | 👁 = auditado | ⬜ = pendente
>
> **Meta:** Este arquivo é o TERMÔMETRO do workflow — ele mostra a saúde da execução.

---

## $DATA_BR — 0/0

| Task | Descrição | Wave | ✅ | 👁 | Commit |
|------|-----------|:----:|---|---|--------|

*Nenhuma task cadastrada ainda. Use o workflow para adicionar tasks.*

---

## Progresso

| Wave | Tasks | Status |
|:----:|:-----:|:------:|
| **Total** | **0** | **0/0** |

---

## Como atualizar este índice

1. **Adicionar novo dia:** adicione uma seção "## DD/MM/AAAA — X/Y"
2. **Marcar task concluída:** troque ⬜ por ✅ na coluna ✅ e adicione o hash do commit
3. **Marcar task auditada:** troque ⬜ por ✅ na coluna 👁
4. **Atualizar contador do cabeçalho:** conte quantos ✅ existem na coluna ✅
5. **Commite as alterações:** \`git add -A && git commit -m "índice: atualiza progresso" && git push\`

> O índice SÓ é útil se estiver atualizado. Reserve 2 minutos ao final de cada
> wave para refletir o progresso real.
INDICEEOF
ok "INDICE.md criado"

# ─── 4. Criar PLANO.md para o dia atual ────────────────────────────────────
PLANO_FILE="$DIA_DIR/PLANO.md"

cat > "$PLANO_FILE" <<PLANOEOF
# Plano de Execução — $PROJECT_NAME

**Criado por:** setup-workflow.sh / $TEAM_NAME
**Data:** $DATA_BR
**Propósito:** Início do workflow de planejamento diário
**Workflow:** Este plano segue o workflow de planejamento diário documentado no repositório.

---

## 📚 RECURSOS DO PROJETO

| Recurso | Local | Propósito |
|---------|-------|-----------|
| Repositório principal | $(basename "$TARGET_DIR") | Código fonte |
| Templates | planejamento-diario/TEMPLATES/ | Modelos de plano e task |
| Índice geral | planejamento-diario/INDICE.md | Acompanhamento de progresso |

---

## Resumo

Primeiro dia de operação do workflow de planejamento diário para a equipe
$TEAM_NAME. Hoje vamos configurar o ambiente e definir as primeiras tasks.

---

## Waves

### Wave 1 — Setup e Configuração (Manhã) 🔴

| Task | Descrição | Agente | Motor | Prioridade | Status |
|:----:|-----------|:------:|:-----:|:----------:|:------:|
| task_01 | Configurar ambiente e revisar documentação | — | $MOTOR_PADRAO | 🔴 | ⬜ |
| task_02 | Definir primeiras tasks do projeto | — | $MOTOR_PADRAO | 🔴 | ⬜ |

**Objetivo:** Ambiente configurado e primeiras tasks definidas.

---

### Wave 2 — Execução (Tarde) 🟡

| Task | Descrição | Agente | Motor | Prioridade | Status |
|:----:|-----------|:------:|:-----:|:----------:|:------:|
| task_03 | Executar tasks do planejamento | — | $MOTOR_PADRAO | 🟡 | ⬜ |

**Objetivo:** Tasks executadas e registradas.

---

## ⚠️ REGRAS DA EXECUÇÃO

1. **Motor padrão:** $MOTOR_PADRAO
2. **NUNCA modificar arquivos originais** — trabalhe sempre em cópias ou branches
3. **Independência:** O projeto deve ser auto-contido
4. **Didático:** Cada arquivo DEVE ser comentado e explicado
5. **Idioma:** Documentação em $IDIOMA
6. **Commit semântico:** Commits descritivos no idioma escolhido

---

## Ao final do dia

- [ ] 0/0 tasks concluídas e auditadas
- [ ] INDICE.md atualizado com status do dia
- [ ] Todos os commits feitos e push realizado

---

## Métricas-alvo

| Métrica | Meta | Realizado |
|---------|:----:|:---------:|
| Tasks concluídas | 0 | 0 |
PLANOEOF
ok "PLANO.md criado em $DIA_DIR"

# ─── Sumário final ─────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║               Setup concluído com sucesso!                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "  Time:     $TEAM_NAME"
echo "  Projeto:  $PROJECT_NAME"
echo "  Local:    $PD_DIR"
echo ""
echo "  Estrutura criada:"
echo "    $PD_DIR/"
echo "    ├── INDICE.md"
echo "    ├── TEMPLATES/"
echo "    │   ├── PLANO.md"
echo "    │   ├── TASK.md"
echo "    │   ├── INDICE.md"
echo "    │   └── README-WORKFLOW.md"
echo "    └── $DATA_ATUAL/"
echo "        └── PLANO.md"
echo ""
echo "  Próximos passos:"
echo "    1. Revise o PLANO.md em $DIA_DIR/PLANO.md"
echo "    2. Preencha as seções com suas tasks reais"
echo "    3. Crie tasks individuais (task_01.md, task_02.md, ...)"
echo "    4. Atualize o INDICE.md com as tasks do dia"
echo ""
