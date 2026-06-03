# Scripts de Automação — Workflow de Planejamento Diário

Esta pasta contém scripts de automação para gerenciar o workflow de
planejamento diário multi-agente. São ferramentas genéricas e reutilizáveis
em qualquer projeto que adote este workflow.

---

## Índice

1. [setup-workflow.sh](#1-setup-workflowsh) — Setup inicial do workflow
2. [gerar-plano-diario.sh](#2-gerar-plano-diariosh) — Geração automática de planos diários (cron)
3. [validate-workflow.sh](#3-validate-workflowsh) — Validação e auditoria do workflow
4. [rotate-key.sh](#4-rotate-keysh) — Rotação de chaves SSH

---

## 1. setup-workflow.sh

**Propósito:** Script de setup inicial que cria toda a estrutura
`planejamento-diario/` no diretório do usuário. Copia templates, gera
`INDICE.md` inicial e cria a pasta do dia atual com `PLANO.md` esqueleto.

**Uso:**

```bash
./scripts/setup-workflow.sh [diretório-alvo] ["Nome do Time"] ["Nome do Projeto"]
```

**Exemplos:**

```bash
# Interativo (pergunta diretório, time, projeto, motores)
./scripts/setup-workflow.sh

# Com argumentos
./scripts/setup-workflow.sh ~/meu-projeto "Time Alfa" "Projeto X"

# Usando variáveis de ambiente
export WORKFLOW_TEAM_NAME="Time Alfa"
export WORKFLOW_PROJECT_NAME="Projeto X"
./scripts/setup-workflow.sh ~/meu-projeto
```

**O que faz:**

1. Cria a pasta `planejamento-diario/` no diretório alvo
2. Copia os templates da pasta `templates/` para `planejamento-diario/TEMPLATES/`
3. Gera `INDICE.md` inicial com o nome do projeto e time
4. Cria pasta do dia atual (`YYYY-MM-DD/`) com `PLANO.md` esqueleto
5. Modo interativo pergunta time, projeto, motores e idioma
6. Fallback para variáveis de ambiente `$WORKFLOW_TEAM_NAME` e `$WORKFLOW_PROJECT_NAME`

**Dependências:** bash >= 4, cp, mkdir, date

---

## 2. gerar-plano-diario.sh

**Propósito:** Script para geração automática do plano diário, ideal para
execução via cron job. Lê o template `PLANO.md`, substitui placeholders e
cria a estrutura do dia com tasks esqueleto.

**Uso:**

```bash
./scripts/gerar-plano-diario.sh <diretório-do-projeto> [opções]
```

**Opções:**

| Opção | Descrição |
|-------|-----------|
| `--tasks=N` | Número de tasks esqueleto por wave (default: 5) |
| `--force, -f` | Sobrescrever se a pasta do dia já existir |
| `--help, -h` | Mostra ajuda |

**Exemplos:**

```bash
# Geração padrão (3 waves, 5 tasks cada = 15 tasks)
./scripts/gerar-plano-diario.sh ~/meu-projeto

# Personalizar número de tasks
./scripts/gerar-plano-diario.sh ~/meu-projeto --tasks=8

# Forçar sobrescrita
./scripts/gerar-plano-diario.sh ~/meu-projeto --force
```

**Configuração de cron (execução diária às 5h):**

```bash
# Editar crontab: crontab -e
0 5 * * * /caminho/scripts/gerar-plano-diario.sh ~/meu-projeto >> ~/meu-projeto/planejamento-diario/cron.log 2>&1
```

**O que faz:**

1. Lê `planejamento-diario/TEMPLATES/PLANO.md` como template
2. Substitui `__DATA__`, `__NOME_DO_PROJETO__`, etc. pela data atual
3. Cria pasta `YYYY-MM-DD/` (ex: `2026-06-03/`)
4. Gera `PLANO.md` com estrutura de 3 waves (Manhã/Tarde/Noite) e tasks vazias
5. Não sobrescreve se a pasta do dia já existir (a menos que `--force`)
6. Registra execução em `planejamento-diario/cron.log`
7. Se o template não existir, gera um plano minimalista

**Dependências:** bash >= 4, cp, mkdir, date, sed

---

## 3. validate-workflow.sh

**Propósito:** Script de validação e auditoria do workflow. Verifica a
integridade da estrutura, consistência do `INDICE.md`, preenchimento de
checkboxes e alinhamento entre `PLANO.md` e os arquivos reais.

**Uso:**

```bash
./scripts/validate-workflow.sh [diretório-do-projeto] [opções]
```

**Opções:**

| Opção | Descrição |
|-------|-----------|
| `--fix, -f` | Tenta corrigir automaticamente inconsistências leves |
| `--verbose, -v` | Exibe detalhes de cada verificação |
| `--help, -h` | Mostra ajuda |

**Exemplos:**

```bash
# Auditoria simples
./scripts/validate-workflow.sh ~/meu-projeto

# Auditoria com correção automática
./scripts/validate-workflow.sh ~/meu-projeto --fix

# Auditoria detalhada
./scripts/validate-workflow.sh ~/meu-projeto --verbose
```

**O que verifica:**

1. **Estrutura básica** — `planejamento-diario/` existe
2. **INDICE.md** — arquivo existe e está acessível
3. **Contadores do INDICE.md** — o contador `X/Y` em cada seção de data
   corresponde à quantidade real de tasks ✅ e total de tasks na tabela
4. **Pastas de data** — existem pastas com formato `YYYY-MM-DD` e cada uma
   contém `PLANO.md`
5. **Checkboxes das tasks** — tasks do dia atual têm checkboxes preenchidos
6. **Seção Conclusão** — tasks têm a seção de Conclusão preenchida
7. **Consistência PLANO.md vs disco** — número de tasks listadas no plano
   corresponde ao número de arquivos `task_*.md` no disco
8. **Templates** — a pasta `TEMPLATES/` existe e contém arquivos
9. **Cron log** — arquivo `cron.log` existe (opcional)

**Exit codes:**

| Código | Significado |
|:------:|-------------|
| 0 | Tudo ok (sem warnings) |
| 1 | Warnings encontrados (inconsistências) |
| 2 | Erro (estrutura ausente ou corrompida) |

**Dependências:** bash >= 4, grep, sed, find, date

---

## 4. rotate-key.sh

**Propósito:** Script genérico de rotação de chaves SSH. Gera um novo par
de chaves ed25519, faz backup automático da chave anterior com timestamp,
atualiza `~/.ssh/config` se solicitado, e exibe a chave pública para copiar
para o servidor.

**Uso:**

```bash
./scripts/rotate-key.sh [nome-da-chave] [opções]
```

**Opções:**

| Opção | Descrição |
|-------|-----------|
| `--dir=PATH` | Diretório das chaves (default: `~/.ssh`) |
| `--host=HOST` | Host no `~/.ssh/config` para atualizar IdentityFile |
| `--comment=COMMENT` | Comentário da chave (default: usuário@hostname-data) |
| `--no-backup` | Pular backup da chave anterior |
| `--show` | Apenas exibe a chave pública atual sem rotacionar |
| `--help, -h` | Mostra ajuda |

**Exemplos:**

```bash
# Rotação básica
./scripts/rotate-key.sh id_empresa

# Rotação com atualização do ~/.ssh/config
./scripts/rotate-key.sh id_github --host=github.com

# Rotação em diretório personalizado
./scripts/rotate-key.sh id_servidor --dir=~/.ssh/empresa

# Apenas exibir chave pública atual
./scripts/rotate-key.sh id_empresa --show
```

**O que faz:**

1. Gera novo par de chaves ed25519 com `ssh-keygen`
2. Faz backup da chave anterior para `nome.bak.YYYYMMDD_HHMMSS`
3. Opcionalmente atualiza `~/.ssh/config` com o novo `IdentityFile`
4. Exibe a chave pública no final para copiar para o servidor
5. Define permissões corretas (600 para privada, 644 para pública)

**Dependências:** bash >= 4, ssh-keygen, chmod

---

## Dependências Comuns

| Ferramenta | Uso | Verificar instalação |
|------------|-----|---------------------|
| bash >= 4 | Todos os scripts | `bash --version` |
| ssh-keygen | rotate-key.sh | `ssh-keygen --help` |
| sed | gerar-plano-diario.sh, validate-workflow.sh | `sed --version` |
| grep | validate-workflow.sh | `grep --version` |
| find | validate-workflow.sh | `find --version` |

Todas as ferramentas acima já vêm instaladas por padrão em macOS e Linux.

---

## Boas Práticas

### Permissões

Todos os scripts devem ter permissão de execução:

```bash
chmod +x scripts/*.sh
```

### Variáveis de Ambiente

Os scripts respeitam as seguintes variáveis de ambiente:

| Variável | Script | Propósito |
|----------|--------|-----------|
| `WORKFLOW_TEAM_NAME` | setup-workflow.sh, gerar-plano-diario.sh | Nome do time |
| `WORKFLOW_PROJECT_NAME` | setup-workflow.sh, gerar-plano-diario.sh | Nome do projeto |

### Error Handling

Todos os scripts usam `set -euo pipefail` para:
- `-e`: abortar ao primeiro erro
- `-u`: tratar variáveis não definidas como erro
- `-o pipefail`: capturar erros em pipes

### Logs

O script `gerar-plano-diario.sh` registra automaticamente em
`planejamento-diario/cron.log`. Para os demais scripts, redirecione a saída
conforme necessário:

```bash
./scripts/validate-workflow.sh ~/meu-projeto >> ~/meu-projeto/planejamento-diario/auditoria.log 2>&1
```

---

## Licença

Este é um projeto de código aberto. Sinta-se livre para adaptar os scripts
à sua realidade.
