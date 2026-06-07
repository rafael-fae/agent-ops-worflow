#!/bin/bash
# =============================================================================
#  archive-skills.sh — Move skills para archive/ seguindo a lista oficial
#  =============================================================================
#  Executar da raiz do repositório: ./scripts/archive-skills.sh
# =============================================================================
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo "$(dirname "$0")/..")"

SKILLS_BASE="skills"
ARCHIVE_BASE="archive/skills"

# Lista oficial de 33 skills para arquivar (conforme task)
SKILLS_TO_ARCHIVE=(
  # devops (4 existentes)
  "devops/correcao-fechamento-diario"
  "devops/css-production-cache-debug"
  "devops/evolution-v2.4-upgrade-meta-integration"
  "devops/gemini-chunked-generation"
  # operacao (18 existentes)
  "operacao/hermes-whatsapp-native"
  "operacao/pycode-blog-architecture"
  "operacao/quartz-build-troubleshooting"
  "operacao/dontus-api-endpoints"
  "operacao/dontus-relatorios-mapeamento"
  "operacao/equipe-m4-clone-local"
  "operacao/clone-build-orchestration"
  "operacao/multi-tenant-discovery-re"
  "operacao/re-audit-consolidation"
  "operacao/gemini-vault-fusion"
  "operacao/gemini-vision-analysis"
  "operacao/ovh-server-migration"
  "operacao/server-migration-ovh"
  "operacao/troubleshoot-m4-ovh-sync"
  "operacao/upgrade-evolution-api"
  "operacao/docs-governance-organization"
  "operacao/diagnostico-evolution-api"
  "operacao/infra-servidor-ovh"
  # security (2 existentes)
  "security/auditoria-supply-chain"
  "security/deploy-equipe-isolada"
  # top-level (5 existentes)
  "m4-mac-team-clone-sync"
  "meta-webhook-receiver-setup"
  "git-vault-agent-pattern"
  "prd-clone-exhaustivo"
  "multi-team-hermes-architecture"
  # planned — não existem ainda, criamos placeholder
  "django-migration-recovery"
  "avaliacao-tecnologica-multi-agente"
  "agent-memory-snapshot"
  "cache-markdown-banco"
)

MOVED=0
NOT_FOUND=0

for skill in "${SKILLS_TO_ARCHIVE[@]}"; do
  SRC="$SKILLS_BASE/$skill"
  # Determinar categoria: se tem "/", extrai categoria; senão é top-level
  if [[ "$skill" == */* ]]; then
    CATEGORY="${skill%%/*}"
    SKILL_NAME="${skill#*/}"
    DEST_DIR="$ARCHIVE_BASE/$CATEGORY/$SKILL_NAME"
  else
    CATEGORY=""
    SKILL_NAME="$skill"
    DEST_DIR="$ARCHIVE_BASE/$SKILL_NAME"
  fi

  if [ -d "$SRC" ]; then
    mkdir -p "$(dirname "$DEST_DIR")"
    mv "$SRC" "$DEST_DIR"
    echo "[MOVED]  $skill -> $DEST_DIR"
    ((MOVED++))
  else
    # Criar placeholder para skills planejadas
    mkdir -p "$DEST_DIR"
    cat > "$DEST_DIR/PLACEHOLDER.md" <<EOF
# ${SKILL_NAME} — Skill Planejada

> Esta skill foi listada para arquivamento mas ainda não existe no repositório.
> Placeholder criado em $(date +%Y-%m-%d) durante reorganização.

## Status
- [ ] Pendente de criação
- [ ] Aguardando definição de escopo
EOF
    echo "[PLACEHOLDER] $skill -> $DEST_DIR (criado placeholder)"
    ((NOT_FOUND++))
  fi
done

echo ""
echo "=== Resumo ==="
echo "  Skills movidas:  $MOVED"
echo "  Placeholders:    $NOT_FOUND"
echo "  Total:           $((MOVED + NOT_FOUND))"
echo ""
echo "Agora remova os diretórios vazios de skills/:"
echo "  find skills/ -type d -empty -delete"
