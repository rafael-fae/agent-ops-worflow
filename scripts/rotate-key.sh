#!/bin/bash
# =============================================================================
#  rotate-key.sh — Rotação Genérica de Chaves SSH
#  =============================================================================
#  Gera um novo par de chaves SSH (ed25519), faz backup da chave anterior
#  com timestamp, atualiza ~/.ssh/config se necessário, e exibe a chave
#  pública para copiar para o servidor de destino.
#
#  Uso:
#    ./scripts/rotate-key.sh [nome-da-chave] [opções]
#
#  Opções:
#    --dir=PATH        Diretório onde salvar as chaves (default: ~/.ssh)
#    --host=HOST       Hostname no ~/.ssh/config para atualizar (opcional)
#    --comment=COMMENT Comentário da chave (default: email ou hostname)
#    --no-backup       Não fazer backup da chave anterior
#    --show            Apenas exibe a chave pública atual sem rotacionar
#    --help, -h        Mostra esta ajuda
#
#  Exemplos:
#    ./scripts/rotate-key.sh id_minha_chave
#    ./scripts/rotate-key.sh id_empresa --host=github.com
#    ./scripts/rotate-key.sh id_servidor --dir=~/.ssh/empresa
#    ./scripts/rotate-key.sh --show  (mostra chave pública atual)
#
#  Dependências: bash >= 4, ssh-keygen, chmod
# =============================================================================

set -euo pipefail

# ─── Cores para output ─────────────────────────────────────────────────────
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
AZUL='\033[0;34m'
NC='\033[0m'

info()   { echo -e "${AZUL}[INFO]${NC}   $*"; }
ok()     { echo -e "${VERDE}[OK]${NC}     $*"; }
warn()   { echo -e "${AMARELO}[WARN]${NC}   $*"; }
erro()   { echo -e "${VERMELHO}[ERRO]${NC}  $*" >&2; }

# ─── Configurações padrão ──────────────────────────────────────────────────
SSH_DIR="$HOME/.ssh"
KEY_NAME=""
HOST=""
COMMENT=""
NO_BACKUP=false
SHOW_ONLY=false

# ─── Função de ajuda ───────────────────────────────────────────────────────
show_help() {
    cat <<EOF
Uso: $(basename "$0") [nome-da-chave] [opções]

Gera um novo par de chaves SSH ed25519, faz backup da anterior (com timestamp)
e opcionalmente atualiza ~/.ssh/config.

Opções:
  --dir=PATH        Diretório das chaves (default: ~/.ssh)
  --host=HOST       Host no ~/.ssh/config para atualizar IdentityFile
  --comment=COMMENT Comentário da chave (default: \$USER@\$HOSTNAME)
  --no-backup       Pular backup da chave anterior
  --show            Apenas exibe a chave pública atual
  --help, -h        Mostra esta ajuda

Exemplos:
  $(basename "$0") id_empresa
  $(basename "$0") id_empresa --host=github.com
  $(basename "$0") id_servidor --dir=~/.ssh/empresa
  $(basename "$0") --show

Dependências: ssh-keygen, chmod
EOF
    exit 0
}

# ─── Parsing de argumentos ─────────────────────────────────────────────────
for arg in "$@"; do
    case "$arg" in
        --help|-h)
            show_help
            ;;
        --show)
            SHOW_ONLY=true
            ;;
        --no-backup)
            NO_BACKUP=true
            ;;
        --dir=*)
            SSH_DIR="${arg#*=}"
            SSH_DIR="${SSH_DIR/#\~/$HOME}"
            ;;
        --host=*)
            HOST="${arg#*=}"
            ;;
        --comment=*)
            COMMENT="${arg#*=}"
            ;;
        *)
            if [ -z "$KEY_NAME" ]; then
                KEY_NAME="$arg"
            fi
            ;;
    esac
done

# Expandir ~ no diretório SSH
SSH_DIR="${SSH_DIR/#\~/$HOME}"

# ─── Modo --show: apenas exibir chave pública atual ────────────────────────
if [ "$SHOW_ONLY" = true ]; then
    if [ -z "$KEY_NAME" ]; then
        erro "Informe o nome da chave para exibir."
        erro "Uso: $(basename "$0") --show <nome-da-chave>"
        exit 1
    fi

    PUB_KEY="$SSH_DIR/${KEY_NAME}.pub"

    if [ ! -f "$PUB_KEY" ]; then
        erro "Chave pública não encontrada: $PUB_KEY"
        exit 1
    fi

    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              Chave Pública SSH                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    cat "$PUB_KEY"
    echo ""
    info "Chave: $PUB_KEY"
    exit 0
fi

# ─── Validar nome da chave ────────────────────────────────────────────────
if [ -z "$KEY_NAME" ]; then
    erro "Nome da chave é obrigatório."
    echo ""
    show_help
fi

# ─── Criar diretório SSH se não existir ────────────────────────────────────
if [ ! -d "$SSH_DIR" ]; then
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    info "Diretório SSH criado: $SSH_DIR"
fi

PRIV_KEY="$SSH_DIR/$KEY_NAME"
PUB_KEY="${PRIV_KEY}.pub"

# ─── Comentário padrão ─────────────────────────────────────────────────────
if [ -z "$COMMENT" ]; then
    COMMENT="${USER:-user}@${HOSTNAME:-localhost}-$(date +%Y%m%d)"
fi

# ─── Backup da chave anterior ──────────────────────────────────────────────
if [ -f "$PRIV_KEY" ] && [ "$NO_BACKUP" = false ]; then
    TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
    BACKUP_PRIV="${PRIV_KEY}.bak.${TIMESTAMP}"
    BACKUP_PUB="${PUB_KEY}.bak.${TIMESTAMP}"

    cp "$PRIV_KEY" "$BACKUP_PRIV"
    [ -f "$PUB_KEY" ] && cp "$PUB_KEY" "$BACKUP_PUB"

    chmod 600 "$BACKUP_PRIV"
    [ -f "$BACKUP_PUB" ] && chmod 644 "$BACKUP_PUB"

    ok "Backup da chave anterior criado:"
    ok "  $BACKUP_PRIV"
    [ -f "$BACKUP_PUB" ] && ok "  $BACKUP_PUB"
fi

# ─── Gerar nova chave ed25519 ──────────────────────────────────────────────
info "Gerando nova chave ed25519: $PRIV_KEY"

# Remove arquivos existentes para evitar prompt do ssh-keygen
[ -f "$PRIV_KEY" ] && rm -f "$PRIV_KEY"
[ -f "$PUB_KEY" ] && rm -f "$PUB_KEY"

ssh-keygen -t ed25519 -f "$PRIV_KEY" -C "$COMMENT" -N "" > /dev/null 2>&1

if [ $? -ne 0 ]; then
    erro "Falha ao gerar a chave SSH."
    exit 1
fi

chmod 600 "$PRIV_KEY"
chmod 644 "$PUB_KEY"

ok "Nova chave gerada com sucesso."
info "  Privada: $PRIV_KEY"
info "  Pública: $PUB_KEY"
info "  Comentário: $COMMENT"

# ─── Atualizar ~/.ssh/config se --host foi fornecido ───────────────────────
if [ -n "$HOST" ]; then
    SSH_CONFIG="$SSH_DIR/config"

    # Criar config se não existir
    if [ ! -f "$SSH_CONFIG" ]; then
        touch "$SSH_CONFIG"
        chmod 600 "$SSH_CONFIG"
    fi

    # Verificar se o host já existe no config
    if grep -q "^Host $HOST$" "$SSH_CONFIG" 2>/dev/null; then
        # Host encontrado: atualizar IdentityFile
        # Usar sed para substituir a linha IdentityFile existente ou adicionar após Host
        if grep -A5 "^Host $HOST$" "$SSH_CONFIG" | grep -q "IdentityFile"; then
            # Já tem IdentityFile — substituir
            sed -i "/^Host $HOST$/,/^Host /s|IdentityFile .*|IdentityFile $PRIV_KEY|" "$SSH_CONFIG"
            ok "~/$SSH_DIR/config: IdentityFile atualizado para o host '$HOST'."
        else
            # Não tem IdentityFile — adicionar após a linha Host
            sed -i "/^Host $HOST$/a\\    IdentityFile $PRIV_KEY" "$SSH_CONFIG"
            ok "~/$SSH_DIR/config: IdentityFile adicionado para o host '$HOST'."
        fi
    else
        # Host não encontrado — adicionar ao final
        {
            echo ""
            echo "Host $HOST"
            echo "    IdentityFile $PRIV_KEY"
        } >> "$SSH_CONFIG"
        ok "~/$SSH_DIR/config: entrada para host '$HOST' adicionada."
    fi

    # Garantir permissões corretas
    chmod 600 "$SSH_CONFIG"
fi

# ─── Exibir chave pública ──────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         Chave Pública — Copie para o servidor              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
cat "$PUB_KEY"
echo ""

# ─── Resumo ────────────────────────────────────────────────────────────────
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           Rotação concluída com sucesso!                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "  Chave:        $KEY_NAME"
echo "  Algoritmo:    ed25519"
echo "  Comentário:   $COMMENT"
echo "  Pasta:        $SSH_DIR"
echo ""

if [ -n "$HOST" ]; then
    echo "  Config atualizada para host: $HOST"
fi

info "Para usar a nova chave, adicione a chave pública acima ao servidor:"
info "  ssh-copy-id -i $PUB_KEY usuario@servidor"
echo ""
info "Ou copie manualmente e cole em ~/.ssh/authorized_keys no servidor."
