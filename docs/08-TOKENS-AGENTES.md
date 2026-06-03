# Configuração de Tokens GitHub para Agentes Hermes

> Guia completo e detalhado sobre como configurar tokens de acesso GitHub
> (Personal Access Tokens) para times multi-agente do Hermes Agent.
> Cada agente do time precisa de seu **próprio token** para que os commits
> sejam atribuídos corretamente, o rastro de auditoria seja claro e as
> permissões sejam granulares.

---

## Sumário

1. [Por que cada agente precisa de seu próprio token](#1-por-que-cada-agente-precisa-de-seu-próprio-token)
2. [Estrutura do Time Nova (exemplo)](#2-estrutura-do-time-nova-exemplo)
3. [Tipos de Token e Permissões](#3-tipos-de-token-e-permissões)
4. [Passo a Passo — Criando um PAT Fine-Grained para um Agente](#4-passo-a-passo--criando-um-pat-fine-grained-para-um-agente)
5. [Configurando o Token no Hermes](#5-configurando-o-token-no-hermes)
6. [Abordagem Recomendada para Times Multi-Agente](#6-abordagem-recomendada-para-times-multi-agente)
7. [Boas Práticas de Segurança](#7-boas-práticas-de-segurança)
8. [Troubleshooting](#8-troubleshooting)
9. [Exemplo Completo de Configuração](#9-exemplo-completo-de-configuração)
10. [Referência Rápida de Comandos](#10-referência-rápida-de-comandos)

---

## 1. Por que cada agente precisa de seu próprio token

Em um time multi-agente do Hermes, vários agentes de IA podem estar
trabalhando simultaneamente no mesmo repositório. Cada agente precisa
de **seu próprio token GitHub** pelos seguintes motivos:

- **Atribuição correta de commits** — o autor do commit no git será o
  agente que executou a tarefa, não um usuário genérico "bot". Isso
  preserva o rastro de auditoria no histórico do repositório.

- **Rastro de auditoria claro** — com tokens individuais, é possível
  identificar exatamente qual agente fez o quê, tanto pelo nome nos
  commits quanto pelos logs de API do GitHub.

- **Permissões granulares** — um agente de Frontend não precisa de
  acesso ao repositório de infraestrutura. Cada token pode (e deve)
  ser limitado aos repositórios que aquele agente específico precisa.

- **Rotação e revogação seletiva** — se um agente for desativado ou
  comprometido, revoga-se apenas o token daquele agente, sem afetar
  os demais.

- **Branch protection compatível** — commits de agentes diferentes
  aparecem como autores distintos, respeitando regras de branch
  protection que exigem revisão por pares ou autores específicos.

---

## 2. Estrutura do Time Nova (exemplo)

O **Time Nova** é um time multi-agente fictício com 6 papéis. Cada papel
tem seu próprio agente Hermes, seu próprio token GitHub e seu próprio
conjunto de repositórios acessíveis.

| Papel | Nome do Agente | O que comita | Repositórios típicos |
|-------|---------------|--------------|---------------------|
| **Orquestrador** | `nova-orch` | Planos diários (`PLANO.md`), relatórios de auditoria, índices | `agent-ops-workflow` |
| **Backend Engineer** | `nova-backend` | Código backend (APIs, modelos, migrações) | `api`, `core-lib`, `worker` |
| **Frontend Engineer** | `nova-frontend` | Código frontend/UI (componentes, estilos, páginas) | `webapp`, `design-system` |
| **DevOps Engineer** | `nova-devops` | Infraestrutura como código, configs de deploy | `infra`, `k8s-configs`, `terraform` |
| **Auditor** | `nova-auditor` | Relatórios de auditoria, validações, documentação | `agent-ops-workflow`, `docs` |
| **GitOps** | `nova-gitops` | CI/CD, vault, documentação técnica, merge | `ci-cd`, `vault-config`, `docs` |

Cada agente opera de forma independente, com seu próprio ambiente
Hermes, seu perfil e seu token. O Orquestrador coordena a delegação
de tarefas, mas cada agente executa seus próprios commits.

---

## 3. Tipos de Token e Permissões

### 3.1 Fine-Grained PAT vs Classic PAT

O GitHub oferece dois tipos de Personal Access Token:

| Característica | Fine-Grained PAT | Classic PAT |
|----------------|:----------------:|:-----------:|
| **Prefixo** | `github_pat_` | `ghp_` |
| **Permissões por repositório** | Sim (granular) | Não (tudo ou nada) |
| **Escopo reduzido** | Sim | Escopos amplos (`repo`, `workflow`) |
| **Expiração obrigatória** | Sim | Opcional |
| **Aprovação organizacional** | Necessária em orgs | Não |
| **Criação** | `github.com/settings/tokens?type=beta` | `github.com/settings/tokens` |

**Recomendação:** Use **sempre fine-grained PAT** para agentes. Eles
permitem restringir o acesso exatamente aos repositórios que o agente
precisa, com as permissões mínimas necessárias.

### 3.2 Permissões Necessárias

Para que um agente Hermes consiga clonar repositórios, fazer commits,
abrir pull requests e verificar status de CI, as seguintes permissões
são necessárias no fine-grained PAT:

| Permissão | Nível | Motivo |
|-----------|-------|--------|
| **Contents** | Read and Write | Clonar, fazer commit, push |
| **Metadata** | Read-only (obrigatório) | GitHub exige para qualquer token |
| **Pull requests** | Read and Write | Abrir e comentar PRs |
| **Actions** | Read | Verificar status de workflows |
| **Commit statuses** | Read | Verificar status de checks |

Para agentes que precisam modificar workflows do GitHub Actions (arquivos
em `.github/workflows/`), adicione também:

| Permissão | Nível | Motivo |
|-----------|-------|--------|
| **Workflows** | Read and Write | Criar/alterar arquivos de workflow |

### 3.3 Organização vs Conta Pessoal

- **Conta pessoal:** O token é vinculado ao seu usuário GitHub. Os
  repositórios acessíveis são aqueles que sua conta tem acesso.
  Apropriado para projetos pessoais ou times pequenos.

- **Organização:** O token precisa ser **aprovado pela organização**
  antes de poder acessar repositórios da org. A organização pode
  definir políticas de restrição para fine-grained tokens (ex:
  exigir aprovação para cada repositório).

> **Nota para orgs:** Ao criar um fine-grained PAT para acesso a
> repositórios de uma organização, um owner da organização precisa
> aprovar o token. O token só funcionará após a aprovação.

---

## 4. Passo a Passo — Criando um PAT Fine-Grained para um Agente

Siga estas etapas para criar um token para um agente do Time Nova.

### 4.1 Acessar a página de tokens

1. Faça login no GitHub
2. Acesse **Settings** (ícone de engrenagem no canto superior direito)
3. No menu lateral esquerdo, clique em **Developer settings**
4. Clique em **Personal access tokens**
5. Clique em **Fine-grained tokens**
6. Clique no botão **Generate new token**

> **Link direto:** https://github.com/settings/tokens?type=beta

### 4.2 Preencher os dados do token

| Campo | Valor | Exemplo |
|-------|-------|---------|
| **Token name** | Nome descritivo do agente | `hermes-agent-nova-backend` |
| **Expiration** | Custom (90 dias recomendado) | 90 days |
| **Description** | (opcional) Descrição do propósito | Token para o agente Nova Backend |

### 4.3 Configurar acesso a repositórios

Em **Repository access**, escolha:

- **Only select repositories** — selecione apenas os repositórios que
  este agente precisa acessar

  Para o `nova-backend`, por exemplo: `api`, `core-lib`, `worker`.

- **All repositories** — apenas se o agente realmente precisa de acesso
  a todos os repositórios (não recomendado por segurança).

### 4.4 Configurar permissões

Em **Permissions**, selecione **Repository permissions** e configure:

```
Contents:         Read and write
Metadata:         Read-only        (já vem marcado)
Pull requests:    Read and write   (se o agente abrir PRs)
Actions:          Read             (para ver CI status)
Commit statuses:  Read             (para ver status de checks)
Workflows:        Read and write   (apenas se mexe em .github/workflows/)
```

### 4.5 Gerar e copiar o token

1. Clique em **Generate token**
2. **Copie o token imediatamente!** O GitHub mostra o token apenas uma vez
3. Armazene em local seguro (gerenciador de senhas ou arquivo `.env`
   protegido)
4. Se perder o token, não é possível recuperá-lo — será necessário
   gerar um novo

> ⚠️ **Importante:** O token gerado começa com `github_pat_` e tem
> cerca de 80 caracteres alfanuméricos. Nunca compartilhe este token
> ou o commite em repositórios.

---

## 5. Configurando o Token no Hermes

Existem várias formas de configurar o token para uso com git e Hermes.
Abaixo estão as 4 opções mais comuns, da mais recomendada para a menos.

### 5.1 Opção A: Variável de Ambiente (`GITHUB_TOKEN`)

**Recomendada para agentes Hermes.** Defina uma variável de ambiente
no perfil do agente ou no shell profile.

```bash
# No arquivo ~/.hermes/profiles/nova-backend/config.yaml
# ou no ~/.zshrc (para uso global)

export GITHUB_TOKEN_NOVA_BACKEND="github_pat_xxxxxxxxxxxxxxxxxxxx"
```

Depois, no script de git do agente, use o token:

```bash
# Configurar o remote com o token
git remote set-url origin \
  "https://oauth2:${GITHUB_TOKEN_NOVA_BACKEND}@github.com/team-nova/api.git"
```

> **Nota sobre o prefixo `oauth2:`:** Para fine-grained PAT, o prefixo
> `oauth2:` é **obrigatório** na URL. Para classic PAT (`ghp_*`), use
> o token diretamente como senha.

### 5.2 Opção B: Arquivo `~/.netrc`

O `.netrc` permite que o git autentique automaticamente sem expor o
token em URLs.

```bash
# ~/.netrc
machine github.com
  login oauth2
  password github_pat_xxxxxxxxxxxxxxxxxxxx
```

Proteja o arquivo com permissões restritas:

```bash
chmod 600 ~/.netrc
```

Para usar com fine-grained PAT, o login **deve ser** `oauth2`. Para
classic PAT, use seu nome de usuário GitHub.

### 5.3 Opção C: Git Credential Helper

Configure o git para usar um credential helper que armazena o token.

```bash
# Configurar credential helper (uma vez)
git config --global credential.helper osxkeychain  # macOS
# ou
git config --global credential.helper cache        # Linux (cache em memória)

# Na primeira operação git, forneça o token como senha
# Username: oauth2 (para fine-grained) ou seu user (para classic)
# Password: github_pat_xxxxxxxxxxxxxxxxxxxx
```

### 5.4 Opção D: SSH Deploy Key (alternativa)

Para ambientes onde PAT não é viável, é possível usar chaves SSH.

```bash
# Gerar chave SSH específica para o agente
ssh-keygen -t ed25519 -C "nova-backend@teamnova.dev" -f ~/.ssh/nova-backend

# Adicionar ao ssh-agent
ssh-add ~/.ssh/nova-backend

# Configurar host no ~/.ssh/config
cat >> ~/.ssh/config << 'EOF'
Host github.com-nova-backend
  HostName github.com
  IdentityFile ~/.ssh/nova-backend
EOF

# Adicionar a chave pública no GitHub:
# Settings → SSH and GPG keys → New SSH key
# Título: "nova-backend"
# Key: (conteúdo de ~/.ssh/nova-backend.pub)

# Usar remote SSH
git remote set-url origin "git@github.com-nova-backend:team-nova/api.git"
```

> ⚠️ **Limitação:** Deploy keys têm acesso a **apenas um repositório**
> cada. Para múltiplos repositórios, é preciso adicionar a mesma chave
> em cada um deles.

---

## 6. Abordagem Recomendada para Times Multi-Agente

O Time Nova usa a seguinte abordagem, que combina simplicidade e
segurança:

### 6.1 Estrutura de Perfis

Cada agente tem seu próprio diretório de perfil Hermes:

```
~/.hermes/profiles/
├── nova-orch/
│   ├── config.yaml
│   └── .env
├── nova-backend/
│   ├── config.yaml
│   └── .env
├── nova-frontend/
│   ├── config.yaml
│   └── .env
├── nova-devops/
│   ├── config.yaml
│   └── .env
├── nova-auditor/
│   ├── config.yaml
│   └── .env
└── nova-gitops/
    ├── config.yaml
    └── .env
```

### 6.2 Configuração YAML

Cada `config.yaml` contém a configuração git do agente:

```yaml
# ~/.hermes/profiles/nova-backend/config.yaml
git:
  user_name: "Nova Backend"
  user_email: "nova-backend@teamnova.dev"
  token_env_var: "GITHUB_TOKEN_NOVA_BACKEND"
```

### 6.3 Armazenamento do Token

O token propriamente dito fica no arquivo `.env` do perfil:

```bash
# ~/.hermes/profiles/nova-backend/.env
GITHUB_TOKEN_NOVA_BACKEND="github_pat_xxxxxxxxxxxxxxxxxxxx"
```

Este arquivo **nunca é commitado** (incluso no `.gitignore` global).

### 6.4 Automação de Configuração

Sempre que um agente é iniciado, ele executa:

```bash
# Carregar token do perfil ativo
source ~/.hermes/active-profile/.env

# Configurar identidade git
export GIT_AUTHOR_NAME="${HERMES_AGENT_NAME}"
export GIT_AUTHOR_EMAIL="${HERMES_AGENT_EMAIL}"
export GIT_COMMITTER_NAME="${HERMES_AGENT_NAME}"
export GIT_COMMITTER_EMAIL="${HERMES_AGENT_EMAIL}"

# Configurar remote com token
git config user.name "${GIT_AUTHOR_NAME}"
git config user.email "${GIT_AUTHOR_EMAIL}"
```

### 6.5 Script de Inicialização do Agente

Um script único gerencia a ativação do perfil correto:

```bash
#!/bin/bash
# ~/.hermes/scripts/activate-agent.sh
# Uso: activate-agent.sh nova-backend

PROFILE_NAME="$1"
PROFILE_DIR="$HOME/.hermes/profiles/${PROFILE_NAME}"

if [ ! -d "$PROFILE_DIR" ]; then
  echo "Erro: Perfil '${PROFILE_NAME}' não encontrado."
  exit 1
fi

# Ativar o perfil
ln -sfn "$PROFILE_DIR" "$HOME/.hermes/active-profile"
source "$PROFILE_DIR/.env"

echo "Perfil ativado: ${PROFILE_NAME}"
echo "Git user: $(git config user.name 2>/dev/null || echo 'não configurado')"
```

---

## 7. Boas Práticas de Segurança

### 7.1 Nunca Commitar Tokens

- Adicione `.env` e `*.env` ao `.gitignore` **global**:
  ```bash
  git config --global core.excludesFile ~/.gitignore
  echo ".env" >> ~/.gitignore
  echo "*.env" >> ~/.gitignore
  ```
- Use `gitleaks` ou `trufflehog` para varrer o repositório em busca
  de tokens acidentalmente commitados
- Se um token for commitado, **revoque-o imediatamente** no GitHub e
  gere um novo

### 7.2 Rotacionar Tokens a Cada 90 Dias

- Defina a expiração para **90 days** ao criar o token
- Configure um lembrete no calendário ou automatize com script:
  ```bash
  # Exemplo de script de rotação
  # 1. Gerar novo token via API do GitHub
  # 2. Atualizar o .env do perfil
  # 3. Testar o novo token
  # 4. Revogar o token antigo
  ```

### 7.3 Usar Fine-Grained Tokens (nunca Classic)

- Fine-grained tokens têm permissões **por repositório**
- Classic tokens têm escopos amplos como `repo` (todos os repositórios
  que o usuário acessa)
- Uma organização pode **bloquear classic tokens** nas suas políticas
  de segurança

### 7.4 Mínimo Privilégio

Cada agente deve ter acesso **apenas** aos repositórios que precisa:

| Agente | Repositórios |
|--------|-------------|
| `nova-orch` | `agent-ops-workflow` |
| `nova-backend` | `api`, `core-lib` |
| `nova-frontend` | `webapp`, `design-system` |
| `nova-devops` | `infra`, `k8s-configs`, `terraform` |
| `nova-auditor` | `agent-ops-workflow`, `docs` |
| `nova-gitops` | `ci-cd`, `vault-config`, `docs` |

### 7.5 Revogar Tokens de Agentes Desativados

Quando um agente é desativado:

1. Acesse https://github.com/settings/tokens?type=beta
2. Encontre o token do agente
3. Clique em **Delete** (ícone de lixeira)
4. Confirme a revogação
5. Remova o perfil do agente de `~/.hermes/profiles/`

### 7.6 Monitoramento

- Ative **alertas de segurança** no GitHub para detectar vazamentos
- Monitore os logs de acesso da API do GitHub para identificar usos
  suspeitos de tokens
- Configure notificações no Slack para novos tokens criados na
  organização

---

## 8. Troubleshooting

### 8.1 "Permission denied" — Token incorreto ou expirado

```
remote: Permission to team-nova/api.git denied to oauth2.
fatal: unable to access 'https://github.com/team-nova/api.git/':
  The requested URL returned error: 403
```

**Causas possíveis:**
- Token expirado (fine-grained tokens têm data de expiração)
- Token foi revogado
- Token não tem acesso ao repositório específico
- Token é de uma organização e ainda não foi aprovado

**Soluções:**
```bash
# Verificar se o token está carregado
echo ${GITHUB_TOKEN_NOVA_BACKEND:0:10}  # mostra os primeiros 10 chars

# Verificar acesso via API
curl -s -H "Authorization: Bearer ${GITHUB_TOKEN_NOVA_BACKEND}" \
  "https://api.github.com/repos/team-nova/api" | head -5

# Se retornar 404, o token não tem acesso ao repositório
# Se retornar 401, o token está expirado ou inválido
```

### 8.2 Push rejeitado — Branch Protection

```
! [remote rejected] main -> main (protected branch hook declined)
error: failed to push some refs to 'https://github.com/team-nova/api.git'
```

**Causas:**
- O branch tem proteção que exige pull request
- O branch exige status checks antes de merge
- O agente não tem permissão para fazer push direto no branch protegido

**Soluções:**
```bash
# Opção 1: Criar um branch de feature e abrir PR
git checkout -b feat/nova-backend/implementacao
git push origin feat/nova-backend/implementacao
gh pr create --title "Implementação" --body "PR automático do Nova Backend"

# Opção 2: Adicionar o agente como exceção no branch protection
# GitHub → Repo → Settings → Branches → Edit rule → "Allow bypass"
```

### 8.3 Token não encontrado — Variável de ambiente não carregada

```
fatal: could not read Username for 'https://github.com': terminal prompts disabled
```

**Causas:**
- O `.env` do perfil não foi carregado (`source` não executado)
- A variável de ambiente tem nome diferente do esperado
- O shell profile (`.zshrc`, `.bashrc`) não inclui o source

**Soluções:**
```bash
# Verificar se a variável existe
env | grep GITHUB_TOKEN

# Carregar manualmente
source ~/.hermes/profiles/nova-backend/.env

# Verificar qual variável o config.yaml espera
grep token_env_var ~/.hermes/profiles/nova-backend/config.yaml
```

### 8.4 Erro "Workflow scope" em Classic PAT

```
! [remote rejected] main -> main
  (refusing to allow an OAuth App to create or update workflow
   `.github/workflows/ci.yml` without `workflow` scope)
```

**Causa:** O Classic PAT não tem o escopo `workflow`.

**Solução:** Adicione o escopo via GitHub CLI:
```bash
gh auth refresh -h github.com -s workflow
```

Ou migre para fine-grained PAT com a permissão **Workflows: Read and write**.

### 8.5 Tabela Resumo de Erros

| Sintoma | Causa Provável | Solução |
|---------|---------------|---------|
| `403: Permission denied` | Token expirado ou sem acesso | Verificar expiração e permissões do token |
| `404: Not Found` na API | Token sem acesso ao repo | Adicionar repo em "Only select repositories" |
| Push recusado em branch protegido | Branch protection rules | Criar feature branch + PR |
| `could not read Username` | Token não carregado | `source ~/.hermes/profiles/AGENTE/.env` |
| `workflow scope` | Classic PAT sem escopo workflow | `gh auth refresh -s workflow` ou migrar para fine-grained |
| Token aparece como `***` no terminal | Terminal masking do Hermes | Extrair via Python: `open(".env").read()` |

---

## 9. Exemplo Completo de Configuração

### 9.1 Agente "nova-dev" (DevOps Engineer)

**Passo 1:** Criar o token no GitHub

```
Nome:         hermes-agent-nova-dev
Expiração:    90 days
Repositórios: infra, k8s-configs, terraform
Permissões:
  Contents:       Read and write
  Metadata:       Read-only
  Pull requests:  Read and write
  Actions:        Read
  Commit statuses: Read
  Workflows:      Read and write
```

**Passo 2:** Configurar o perfil Hermes

```bash
# Criar diretório do perfil
mkdir -p ~/.hermes/profiles/nova-dev
```

```yaml
# ~/.hermes/profiles/nova-dev/config.yaml
name: "nova-dev"
description: "DevOps Engineer do Time Nova"

git:
  user_name: "Nova Dev"
  user_email: "nova-dev@teamnova.dev"
  token_env_var: "GITHUB_TOKEN_NOVA_DEV"

repos:
  - infra
  - k8s-configs
  - terraform
```

```bash
# ~/.hermes/profiles/nova-dev/.env
GITHUB_TOKEN_NOVA_DEV="github_pat_xxxxxxxxxxxxxxxxxxxx"
```

**Passo 3:** Configurar o shell profile

```bash
# ~/.zshrc (ou ~/.bashrc)
export GITHUB_TOKEN_NOVA_DEV="github_pat_xxxxxxxxxxxxxxxxxxxx"

# Conveniência: alias para ativar o perfil
alias activate-nova-dev="source ~/.hermes/profiles/nova-dev/.env && \
  git config user.name 'Nova Dev' && \
  git config user.email 'nova-dev@teamnova.dev'"
```

**Passo 4:** Testar a configuração

```bash
activate-nova-dev

# Verificar identidade git
git config user.name     # Deve retornar "Nova Dev"
git config user.email    # Deve retornar "nova-dev@teamnova.dev"

# Verificar acesso ao repositório
curl -s -H "Authorization: Bearer ${GITHUB_TOKEN_NOVA_DEV}" \
  "https://api.github.com/repos/team-nova/infra" | \
  python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('full_name','SEM ACESSO'))"

# Fazer um commit de teste (dentro do repositório)
cd ~/projects/infra
echo "# Configuração gerada pelo Nova Dev" >> README.md
git add README.md
git commit -m "docs(infra): adiciona nota de configuração do Nova Dev"
git push origin main
```

### 9.2 Configuração do Orquestrador (Commander Alex)

O orquestrador do Time Nova, **Commander Alex**, tem um token com
acesso apenas ao repositório `agent-ops-workflow`:

```yaml
# ~/.hermes/profiles/nova-orch/config.yaml
name: "nova-orch"
description: "Orquestrador do Time Nova — planejamento e auditoria"

git:
  user_name: "Commander Alex"
  user_email: "commander.alex@teamnova.dev"
  token_env_var: "GITHUB_TOKEN_NOVA_ORCH"

repos:
  - agent-ops-workflow
```

---

## 10. Referência Rápida de Comandos

### Criar e configurar token

| Ação | Comando / Link |
|------|---------------|
| Criar token fine-grained | https://github.com/settings/tokens?type=beta |
| Ver tokens existentes | https://github.com/settings/tokens |
| Verificar acesso à API | `curl -H "Authorization: Bearer \$TOKEN" https://api.github.com/repos/OWNER/REPO` |

### Configurar git com token

```bash
# URL com token (fine-grained)
git remote set-url origin "https://oauth2:${TOKEN}@github.com/OWNER/REPO.git"

# URL com token (classic)
git remote set-url origin "https://${TOKEN}@github.com/OWNER/REPO.git"

# Configurar identidade
git config user.name "Nome do Agente"
git config user.email "agente@dominio.com"
```

### Gerenciamento de tokens

```bash
# Ver expiração dos tokens (via API)
curl -s -H "Authorization: Bearer ${GH_TOKEN}" \
  "https://api.github.com/user/personal_access_tokens"

# Revogar token (via GitHub CLI)
gh auth logout

# Testar se o token tem acesso ao repositório
curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer ${TOKEN}" \
  "https://api.github.com/repos/OWNER/REPO"
# 200 = OK, 404 = sem acesso, 401 = inválido
```

### Segurança

```bash
# Verificar se há tokens no repositório
git secrets --scan
# ou
gitleaks detect --source .

# .gitignore global
git config --global core.excludesFile ~/.gitignore_global
echo ".env" >> ~/.gitignore_global
```

---

> **Documento mantido pelo Time Nova — agent-ops-workflow**
>
> Versão: 1.0
> Última atualização: Junho 2026
>
> Próximo documento: [09-SEGURANCA.md](09-SEGURANCA.md)
