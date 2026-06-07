# Instrução para o Agente: Instalar Agent Ops Workflow

> **Arquivo de instrução para agentes Hermes.**
> O usuário vai pedir para você ler este arquivo e executar os passos abaixo.
> Siga cada passo na ordem. Reporte o progresso ao usuário.

---

## Missão

Instalar e configurar o **Agent Ops Workflow** — sistema de planejamento diário multi-agente — no perfil do orquestrador e nos agentes da equipe.

---

## Passo 1: Identificar o Repositório

O repositório `agent-ops-workflow` foi clonado pelo usuário. Descubra onde:

```bash
# Descobrir localização
find ~/Dev ~/projects ~/Documentos -name "agent-ops-workflow" -type d 2>/dev/null | head -5
# OU pergunte ao usuário onde ele clonou
```

O caminho típico é `~/Dev/agent-ops-workflow/` ou `~/projects/agent-ops-workflow/`.

## Passo 2: Ler a Estrutura do Repositório

```bash
ls -la /caminho/agent-ops-workflow/
ls /caminho/agent-ops-workflow/skills/*/*/
ls /caminho/agent-ops-workflow/scripts/
```

Confirme que existem: `skills/`, `scripts/`, `docs/`, `templates/`, `planejamento-diario/`.

## Passo 3: Identificar o Perfil do Orquestrador

Descubra qual perfil Hermes será o orquestrador:

```bash
ls ~/.hermes/profiles/
```

Pergunte ao usuário qual perfil será o orquestrador (ex: `dalinar`, `orquestrador`, `admin`). Se não houver nenhum, crie um:

```bash
mkdir -p ~/.hermes/profiles/orquestrador/
```

## Passo 4: Instalar Skills no Perfil do Orquestrador

Copie TODAS as skills do repositório para o perfil do orquestrador:

```bash
REPO=/caminho/agent-ops-workflow
PERFIL=~/.hermes/profiles/orquestrador

# Criar diretório de skills se não existir
mkdir -p "$PERFIL/skills"

# Copiar skills (mantendo estrutura de categorias)
cp -r "$REPO/skills/"* "$PERFIL/skills/"

# Verificar instalação
ls -d "$PERFIL/skills/"*/*/
echo "Skills instaladas: $(ls -d "$PERFIL/skills/"*/*/ | wc -l)"
```

## Passo 5: Criar Estrutura planejamento-diario/

Crie a estrutura de planejamento diário no diretório do projeto do usuário:

```bash
# Perguntar ao usuário: qual o diretório do projeto?
# Exemplo: ~/Dev/meu-projeto/

PROJETO=/caminho/do/projeto

# Criar estrutura
mkdir -p "$PROJETO/planejamento-diario"

# Copiar templates
cp "$REPO/templates/PLANO.md.tpl" "$PROJETO/planejamento-diario/TEMPLATE_PLANO.md"
cp "$REPO/templates/TASK.md.tpl" "$PROJETO/planejamento-diario/TEMPLATE_TASK.md"

# Criar INDICE.md inicial
cat > "$PROJETO/planejamento-diario/INDICE.md" << 'EOF'
# Índice de Tasks

**Tasks planejadas:** 0
**Tasks concluídas:** 0
**Tasks auditadas:** 0

| Task | Agente | Descrição | SP | ✅ | 👁 | Commit |
|:----:|--------|-----------|:--:|:--:|:--:|:------:|
EOF

# Criar diretório do dia atual
DATA_ATUAL=$(date +%Y-%m-%d)
mkdir -p "$PROJETO/planejamento-diario/$DATA_ATUAL"

# Criar PLANO.md inicial
cat > "$PROJETO/planejamento-diario/$DATA_ATUAL/PLANO.md" << PLANOEOF
# Plano Diário — $DATA_ATUAL

**Aprovado por:** Líder
**Status:** 0/0 concluídas

## 📋 TAREFAS DO DIA

(Sem tasks planejadas ainda)
PLANOEOF

echo "Estrutura planejamento-diario criada em $PROJETO/planejamento-diario/"
```

## Passo 6: Criar Sistema de Memória Operacional

### 6.1 Criar DIARIO.md para o orquestrador

```bash
mkdir -p "$PERFIL/operacional"

cat > "$PERFIL/operacional/DIARIO.md" << 'EOF'
# Diário de Bordo — [NOME DO ORQUESTRADOR]

**Propósito:** Registrar o que fiz em cada sessão.

**Atualizado por:** [nome] (após cada ação relevante)

---

## 📋 TAREFAS EM ANDAMENTO

| Task | Agente | Status | Última ação |
|:----:|--------|--------|-------------|
| — | — | — | — |

## 📝 LOG CRONOLÓGICO

### $(date +%Y-%m-%d)

*Início das operações.*

---

## REGRAS DE USO

1. LEIA este diário no início de cada sessão
2. ATUALIZE ao concluir/pausar uma task
3. CONSULTE ESTADO-DA-EQUIPE antes de agir
4. ATUALIZE ESTADO-DA-EQUIPE ao iniciar/concluir
EOF
```

### 6.2 Criar DIARIO.md para cada agente

Para cada agente na equipe, criar DIARIO.md no perfil correspondente.

```bash
# Exemplo para agente1
mkdir -p ~/.hermes/profiles/agente1/operacional/
cp "$PERFIL/operacional/DIARIO.md" ~/.hermes/profiles/agente1/operacional/DIARIO.md
sed -i '' 's/NOME DO ORQUESTRADOR/agente1/' ~/.hermes/profiles/agente1/operacional/DIARIO.md
```

### 6.3 Criar ESTADO-DA-EQUIPE.md (APENAS no orquestrador)

```bash
cat > "$PERFIL/operacional/ESTADO-DA-EQUIPE.md" << 'EOF'
# Estado da Equipe — Memória Coletiva em Tempo Real

**Atualizado:** $(date '+%Y-%m-%d %H:%M')

---

## 🟢 EM EXECUÇÃO

| Task | Agente | Início | Descrição |
|:----:|--------|:------:|-----------|
| — | — | — | — |

## 🟡 AGUARDANDO

| Task | Agente | Desde | Motivo |
|:----:|--------|:-----:|--------|

## 🔴 BLOQUEADO

| Task | Agente | Bloqueio |
|:----:|--------|----------|

## ✅ CONCLUÍDAS

| Task | Agente | Conclusão | Commit |
|:----:|--------|:---------:|:------:|
| — | — | — | — |
EOF
```

## Passo 7: Injetar PROTOCOLO DIARIO no system_prompt

### 7.1 Encontrar o system_prompt no config.yaml

```bash
grep "system_prompt:" "$PERFIL/config.yaml"
```

### 7.2 Adicionar o protocolo

Edite o `config.yaml` do orquestrador e de CADA AGENTE para incluir o PROTOCOLO DIARIO no final do `system_prompt`, ANTES do fechamento `\n"`.

Adicione este texto:

```yaml
\n\n### PROTOCOLO DIARIO + ESTADO-DA-EQUIPE (OBRIGATÓRIO)\nAntes de QUALQUER ação:\n1. LEIA /caminho/ABSOLUTO/para/ESTADO-DA-EQUIPE.md\n2. LEIA /caminho/ABSOLUTO/para/DIARIO.md\n3. Faça check-in (🟢 EM EXECUÇÃO)\nAo concluir:\n4. Atualize DIARIO.md com resultado + hash\n5. Faça check-out (✅ CONCLUÍDAS)\n⚠️ Ignorar este protocolo causa retrabalho e confusão na equipe.
```

⚠️ **Use caminhos ABSOLUTOS** (ex: `/Users/seunome/.hermes/profiles/orquestrador/operacional/DIARIO.md`).

### 7.3 Script Python para injeção automática

Se preferir, use este script Python para injetar o protocolo:

```python
import re

config_path = "/caminho/absoluto/.hermes/profiles/orquestrador/config.yaml"
with open(config_path, 'r') as f:
    content = f.read()

protocolo = (
    '\\n\\n### PROTOCOLO DIARIO + ESTADO-DA-EQUIPE (OBRIGATÓRIO)\\n'
    'Antes de QUALQUER ação:\\n'
    '1. LEIA /caminho/absoluto/para/ESTADO-DA-EQUIPE.md\\n'
    '2. LEIA /caminho/absoluto/para/DIARIO.md\\n'
    '3. Faça check-in (🟢 EM EXECUÇÃO)\\n'
    'Ao concluir:\\n'
    '4. Atualize DIARIO.md com resultado + hash\\n'
    '5. Faça check-out (✅ CONCLUÍDAS)\\n'
    '⚠️ Ignorar causa retrabalho e confusão na equipe.'
)

# Encontrar o final do system_prompt e inserir
old = 'Fale em pt-BR.\\n"'
new = 'Fale em pt-BR.' + protocolo + '\\n"'

if old in content:
    content = content.replace(old, new, 1)
    with open(config_path, 'w') as f:
        f.write(content)
    print("Protocolo injetado com sucesso!")
else:
    print("Pattern não encontrado — verifique o formato do system_prompt")
```

## Passo 8: Configurar Timezone

```bash
# Verificar timezone atual
grep "timezone:" "$PERFIL/config.yaml"

# Configurar (exemplo: America/Sao_Paulo)
# Se a chave existir:
sed -i '' 's/timezone: .*/timezone: America\/Sao_Paulo/' "$PERFIL/config.yaml"

# Se a chave não existir, adicionar:
echo "timezone: America/Sao_Paulo" >> "$PERFIL/config.yaml"

# Repetir para cada agente
for perfil in ~/.hermes/profiles/*/; do
  if [ -f "$perfil/config.yaml" ]; then
    if grep -q "timezone:" "$perfil/config.yaml"; then
      sed -i '' 's/timezone: .*/timezone: America\/Sao_Paulo/' "$perfil/config.yaml"
    else
      echo "timezone: America/Sao_Paulo" >> "$perfil/config.yaml"
    fi
    echo "Timezone configurado em $perfil"
  fi
done
```

## Passo 9: Copiar Scripts Auxiliares

```bash
mkdir -p "$PROJETO/scripts"
cp "$REPO/scripts/setup.sh" "$PROJETO/scripts/"
cp "$REPO/scripts/gerar-plano-diario.sh" "$PROJETO/scripts/"
cp "$REPO/scripts/validate-workflow.sh" "$PROJETO/scripts/"
chmod +x "$PROJETO/scripts/"*.sh
echo "Scripts copiados para $PROJETO/scripts/"
```

## Passo 10: Verificar Instalação

Execute o script de validação:

```bash
bash "$PROJETO/scripts/validate-workflow.sh"
```

OU verifique manualmente:

- [ ] Skills instaladas no perfil do orquestrador
- [ ] `planejamento-diario/INDICE.md` existe
- [ ] `planejamento-diario/TEMPLATE_PLANO.md` existe
- [ ] `planejamento-diario/TEMPLATE_TASK.md` existe
- [ ] `operacional/DIARIO.md` existe no orquestrador
- [ ] `operacional/DIARIO.md` existe para cada agente
- [ ] `operacional/ESTADO-DA-EQUIPE.md` existe no orquestrador
- [ ] `timezone` configurado em todos os perfis
- [ ] PROTOCOLO DIARIO no system_prompt de todos os perfis
- [ ] Scripts copiados para o projeto

## Passo 11: Iniciar Gateway (Opcional)

```bash
# Iniciar gateway do orquestrador
hermes --profile orquestrador gateway run --replace

# Iniciar gateway de cada agente
hermes --profile agente1 gateway run --replace
```

---

## Conclusão

Após executar todos os passos, reporte ao usuário:

```
✅ Agent Ops Workflow instalado com sucesso!

Estrutura criada:
- Skills: N skills instaladas
- planejamento-diario/ com INDICE.md + templates
- DIARIO.md para orquestrador + N agentes
- ESTADO-DA-EQUIPE.md compartilhado
- Timezone configurado
- PROTOCOLO DIARIO no system_prompt de todos
- Scripts auxiliares copiados

Próximos passos:
1. Configurar Slack (se desejado) — veja docs/09-SLACK-AGENT-SETUP.md
2. Criar primeira task — veja docs/06-REFERENCIA-RAPIDA.md
3. Iniciar ciclo diário — veja docs/02-CICLO-DIARIO.md
```
