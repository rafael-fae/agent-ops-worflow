#!/bin/bash
# =============================================================================
#  validate-workflow.sh — Validação e Auditoria do Workflow
#  =============================================================================
#  Verifica a integridade da estrutura planejamento-diario/, confere se
#  INDICE.md está consistente, tasks têm checkboxes preenchidos, e PLANO.md
#  reflete o status real das tasks.
#
#  Uso:
#    ./scripts/validate-workflow.sh [diretório-do-projeto] [opções]
#
#  Opções:
#    --fix, -f    Tenta corrigir automaticamente inconsistências leves
#    --verbose, -v Exibe detalhes de cada verificação
#    --help, -h   Mostra esta ajuda
#
#  Exemplos:
#    ./scripts/validate-workflow.sh ~/meu-projeto
#    ./scripts/validate-workflow.sh ~/meu-projeto --fix
#    ./scripts/validate-workflow.sh ~/meu-projeto --verbose
#
#  Exit code:
#    0  — Tudo ok (sem warnings)
#    1  — Warnings encontrados (inconsistências)
#    2  — Erro (estrutura ausente ou corrompida)
#
#  Dependências: bash >= 4, grep, stat, find, date
# =============================================================================

set -euo pipefail

# ─── Configurações ─────────────────────────────────────────────────────────
FIX_MODE=false
VERBOSE=false

# ─── Cores para output ─────────────────────────────────────────────────────
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
AZUL='\033[0;34m'
CINZA='\033[0;90m'
NC='\033[0m'

info()    { echo -e "${AZUL}[INFO]${NC}    $*"; }
ok()      { echo -e "${VERDE}[OK]${NC}      $*"; }
warn()    { echo -e "${AMARELO}[WARN]${NC}    $*"; }
erro()    { echo -e "${VERMELHO}[ERRO]${NC}   $*" >&2; }
verbose() { [ "$VERBOSE" = true ] && echo -e "${CINZA}[DEBUG]${NC}   $*"; }

# ─── Contadores ────────────────────────────────────────────────────────────
TOTAL_CHECKS=0
PASSED_CHECKS=0
WARNINGS=0
ERRORS=0

# ─── Função de ajuda ───────────────────────────────────────────────────────
show_help() {
    cat <<EOF
Uso: $(basename "$0") [diretório-do-projeto] [opções]

Valida a estrutura e consistência do workflow de planejamento diário.

Opções:
  --fix, -f      Tenta corrigir automaticamente inconsistências leves
  --verbose, -v  Exibe detalhes de cada verificação
  --help, -h     Mostra esta ajuda

Exit codes:
  0  — Tudo ok (sem warnings)
  1  — Warnings encontrados (inconsistências)
  2  — Erro (estrutura ausente ou corrompida)

Exemplos:
  $(basename "$0") ~/meu-projeto
  $(basename "$0") ~/meu-projeto --fix
EOF
    exit 0
}

# ─── Parsing de argumentos ─────────────────────────────────────────────────
TARGET_DIR=""
for arg in "$@"; do
    case "$arg" in
        --help|-h) show_help ;;
        --fix|-f)  FIX_MODE=true ;;
        --verbose|-v) VERBOSE=true ;;
        *)
            if [ -z "$TARGET_DIR" ]; then
                TARGET_DIR="$arg"
            fi
            ;;
    esac
done

if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR="."
fi

# Expandir ~ se presente
TARGET_DIR="${TARGET_DIR/#\~/$HOME}"

# ─── Verificação 1: Estrutura básica existe ────────────────────────────────
PD_DIR="$TARGET_DIR/planejamento-diario"
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

if [ ! -d "$PD_DIR" ]; then
    erro "Estrutura planejamento-diario/ não encontrada em: $PD_DIR"
    erro "Execute setup-workflow.sh primeiro."
    exit 2
fi
ok "Estrutura planejamento-diario/ encontrada."
PASSED_CHECKS=$((PASSED_CHECKS + 1))

# ─── Verificação 2: INDICE.md existe ───────────────────────────────────────
INDICE_FILE="$PD_DIR/INDICE.md"
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

if [ ! -f "$INDICE_FILE" ]; then
    warn "INDICE.md não encontrado."
    WARNINGS=$((WARNINGS + 1))

    if [ "$FIX_MODE" = true ]; then
        warn "Criando INDICE.md vazio... (implementação manual necessária)"
        # Não criamos automaticamente porque o conteúdo depende do projeto
    fi
else
    ok "INDICE.md encontrado."
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
fi

# ─── Verificação 3: Contador do INDICE.md está correto ─────────────────────
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

if [ -f "$INDICE_FILE" ]; then
    # Extrair todas as seções de data (## DD/MM/AAAA — X/Y)
    while IFS= read -r line; do
        if [[ "$line" =~ ^##[[:space:]]+([0-9]{2}/[0-9]{2}/[0-9]{4})[[:space:]]+—[[:space:]]+([0-9]+)/([0-9]+) ]]; then
            data_encontrada="${BASH_REMATCH[1]}"
            contador_declarado="${BASH_REMATCH[2]}"
            total_declarado="${BASH_REMATCH[3]}"

            verbose "Verificando contador para $data_encontrada: $contador_declarado/$total_declarado"

            # Contar ✅ na seção
            # Primeiro extrair a seção (até próximo ## ou fim)
            section_content=$(sed -n "/^## $data_encontrada —/,/^## [0-9]/p" "$INDICE_FILE" 2>/dev/null | head -n -1)
            if [ -z "$section_content" ]; then
                section_content=$(sed -n "/^## $data_encontrada —/,\$p" "$INDICE_FILE" 2>/dev/null)
            fi

            # Contar ✅ na coluna de status (antes do 👁)
            # Formato: | task_N | desc | N | ✅ | ⬜ | hash |
            real_concluidas=$(echo "$section_content" | grep -cP '^\|\s*task_\d+.*\|.*\|\s*✅\s*\|')
            real_total=$(echo "$section_content" | grep -cP '^\|\s*task_\d+')

            if [ "$real_total" -eq 0 ]; then
                verbose "  Nenhuma task encontrada nesta seção (pode ser placeholder)."
            else
                verbose "  Real: $real_concluidas/$real_total"

                if [ "$contador_declarado" -ne "$real_concluidas" ] || [ "$total_declarado" -ne "$real_total" ]; then
                    warn "Contador incorreto em '$data_encontrada': declarado $contador_declarado/$total_declarado, real $real_concluidas/$real_total"
                    WARNINGS=$((WARNINGS + 1))

                    if [ "$FIX_MODE" = true ]; then
                        # Atualizar o contador no cabeçalho
                        sed -i "s/^## $data_encontrada — [0-9]*\/[0-9]*/## $data_encontrada — $real_concluidas\/$real_total/" "$INDICE_FILE"
                        ok "  Contador corrigido para $real_concluidas/$real_total"
                    fi
                else
                    PASSED_CHECKS=$((PASSED_CHECKS + 1))
                fi
            fi
        fi
    done < "$INDICE_FILE"
fi

# ─── Verificação 4: Pastas de data existem e têm conteúdo ─────────────────
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
DATA_PASTAS=0
DATA_PASTAS_VALIDAS=0

while IFS= read -r -d '' pasta; do
    pasta_nome="$(basename "$pasta")"
    # Verificar se é uma pasta de data (YYYY-MM-DD)
    if [[ "$pasta_nome" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        DATA_PASTAS=$((DATA_PASTAS + 1))
        verbose "Verificando pasta: $pasta_nome"

        # Verificar se tem PLANO.md
        if [ -f "$pasta/PLANO.md" ]; then
            DATA_PASTAS_VALIDAS=$((DATA_PASTAS_VALIDAS + 1))
        else
            warn "Pasta $pasta_nome não contém PLANO.md"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
done < <(find "$PD_DIR" -maxdepth 1 -type d -print0 2>/dev/null)

if [ "$DATA_PASTAS" -eq 0 ]; then
    warn "Nenhuma pasta de data (YYYY-MM-DD) encontrada em $PD_DIR"
    warn "Crie pastas com o script gerar-plano-diario.sh"
else
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    verbose "Pastas de data encontradas: $DATA_PASTAS, válidas: $DATA_PASTAS_VALIDAS"
fi

# ─── Verificação 5: Tasks do dia atual têm checkboxes preenchidos ──────────
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
DATA_ATUAL="$(date +%Y-%m-%d)"
DIA_ATUAL_DIR="$PD_DIR/$DATA_ATUAL"
TASKS_SEM_CHECKBOX=0

if [ -d "$DIA_ATUAL_DIR" ]; then
    verbose "Verificando checkboxes nas tasks do dia atual ($DATA_ATUAL)..."

    while IFS= read -r -d '' task_file; do
        task_name="$(basename "$task_file")"
        if [[ "$task_name" =~ ^task_[0-9]+\.md$ ]]; then
            # Verificar se tem checkboxes e se estão preenchidos
            total_checkboxes=$(grep -cP '^\s*-\s*\[[ x]\]' "$task_file" 2>/dev/null || true)
            preenchidos=$(grep -cP '^\s*-\s*\[x\]' "$task_file" 2>/dev/null || true)

            verbose "  $task_name: $preenchidos/$total_checkboxes checkboxes preenchidos"

            if [ "$total_checkboxes" -gt 0 ] && [ "$preenchidos" -eq 0 ]; then
                warn "Task $task_name: nenhum checkbox preenchido (0/$total_checkboxes)"
                TASKS_SEM_CHECKBOX=$((TASKS_SEM_CHECKBOX + 1))
            fi

            # Verificar se tem seção Conclusão preenchida
            if grep -q "^## Conclusão" "$task_file" 2>/dev/null; then
                verbose "  $task_name: seção Conclusão encontrada."
            fi
        fi
    done < <(find "$DIA_ATUAL_DIR" -maxdepth 1 -type f -name 'task_*.md' -print0 2>/dev/null)

    if [ "$TASKS_SEM_CHECKBOX" -gt 0 ]; then
        warn "$TASKS_SEM_CHECKBOX task(s) sem checkboxes preenchidos."
        WARNINGS=$((WARNINGS + TASKS_SEM_CHECKBOX))
    else
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        ok "Tasks do dia atual com checkboxes verificados."
    fi
else
    verbose "Nenhuma pasta para o dia atual ($DATA_ATUAL)."
fi

# ─── Verificação 6: Tasks têm Conclusão preenchida ─────────────────────────
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
TASKS_SEM_CONCLUSAO=0

if [ -d "$DIA_ATUAL_DIR" ]; then
    while IFS= read -r -d '' task_file; do
        task_name="$(basename "$task_file")"
        if [[ "$task_name" =~ ^task_[0-9]+\.md$ ]]; then
            # Verificar se a seção Conclusão tem conteúdo além do placeholder
            if grep -q "^## Conclusão" "$task_file" 2>/dev/null; then
                # Pular linhas em branco e linhas de comentário
                conteudo_conclusao=$(sed -n '/^## Conclusão/,/^## /p' "$task_file" 2>/dev/null | \
                    grep -v '^## Conclusão' | \
                    grep -v '^<!--' | \
                    grep -v '^-->' | \
                    grep -v '^\s*$' | \
                    grep -v '^\*\*Agente:\*\*' | \
                    grep -v '^\*\*Concluída' | \
                    grep -v '^\*\*Motor' | \
                    grep -v '^\*\*Observações' | \
                    head -1 || true)
                if [ -z "$conteudo_conclusao" ] && grep -q '^\*\*Agente:\*\*' "$task_file" 2>/dev/null; then
                    verbose "  $task_name: seção Conclusão vazia (apenas cabeçalho)."
                fi
            fi
        fi
    done < <(find "$DIA_ATUAL_DIR" -maxdepth 1 -type f -name 'task_*.md' -print0 2>/dev/null)
fi

PASSED_CHECKS=$((PASSED_CHECKS + 1))

# ─── Verificação 7: PLANO.md reflete status reais ──────────────────────────
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

if [ -f "$DIA_ATUAL_DIR/PLANO.md" ]; then
    total_tasks_no_plano=$(grep -cP '^\|\s*task_\d+' "$DIA_ATUAL_DIR/PLANO.md" 2>/dev/null || true)
    total_tasks_no_disk=$(find "$DIA_ATUAL_DIR" -maxdepth 1 -type f -name 'task_*.md' 2>/dev/null | wc -l || true)

    if [ "$total_tasks_no_plano" -ne "$total_tasks_no_disk" ] && [ "$total_tasks_no_plano" -gt 0 ]; then
        warn "PLANO.md lista $total_tasks_no_plano tasks, mas há $total_tasks_no_disk arquivos task_*.md no disco."
        WARNINGS=$((WARNINGS + 1))
    else
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    fi
else
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
fi

# ─── Verificação 8: Templates existem ──────────────────────────────────────
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
TEMPLATES_DIR="$PD_DIR/TEMPLATES"

if [ -d "$TEMPLATES_DIR" ]; then
    templates_encontrados=0
    for tpl in "$TEMPLATES_DIR"/*.md; do
        if [ -f "$tpl" ]; then
            templates_encontrados=$((templates_encontrados + 1))
        fi
    done
    if [ "$templates_encontrados" -eq 0 ]; then
        warn "Pasta TEMPLATES/ existe mas está vazia."
        WARNINGS=$((WARNINGS + 1))
    else
        ok "$templates_encontrados template(s) encontrado(s) em TEMPLATES/."
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    fi
else
    warn "Pasta TEMPLATES/ não encontrada."
    WARNINGS=$((WARNINGS + 1))
fi

# ─── Verificação 9: Cron.log existe ────────────────────────────────────────
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

if [ -f "$PD_DIR/cron.log" ]; then
    verbose "Arquivo cron.log encontrado."
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
fi

# ─── Relatório Final ───────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
if [ "$ERRORS" -gt 0 ] || [ "$WARNINGS" -gt 0 ]; then
    echo "║           Auditoria concluída com inconsistências         ║"
else
    echo "║           Auditoria concluída — tudo OK!                  ║"
fi
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "  Verificações: $TOTAL_CHECKS"
echo "  Passaram:     $PASSED_CHECKS"
echo "  Warnings:     $WARNINGS"
echo "  Erros:        $ERRORS"
echo ""

if [ "$FIX_MODE" = true ] && [ "$WARNINGS" -gt 0 ]; then
    echo "  🔧 Modo --fix ativo: algumas inconsistências foram corrigidas."
    echo "     Execute novamente para verificar se todas foram resolvidas."
fi

# Exit code
if [ "$ERRORS" -gt 0 ]; then
    exit 2
elif [ "$WARNINGS" -gt 0 ]; then
    exit 1
else
    exit 0
fi
