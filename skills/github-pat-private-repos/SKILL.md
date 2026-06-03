---
name: github-pat-private-repos
description: Configurar GitHub Personal Access Token (fine-grained) para clonar e dar push em repositórios privados. Cobre extração segura do token, clone com oauth2, e troubleshooting de permissões.
category: devops
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# GitHub PAT — Clone e Push em Repositórios Privados

## Contexto

GitHub fine-grained PATs (`github_pat_*`) precisam de autorização explícita por repositório. Sem isso, operações retornam 403 ou 404 (GitHub oculta existência de repositórios privados).

## Token Fine-Grained — Permissões Necessárias

1. Acessar https://github.com/settings/tokens
2. Editar o token → **Repository access** → "Only select repositories"
3. Adicionar o repositório alvo (ex: `{{COMMANDER}}-fae/obsidian`)
4. Permissions:
   - **Contents** (Read & Write) — clone, push, commit
   - **Workflows** (Read & Write) — necessário para criar/alterar arquivos em `.github/workflows/`

Alternativa: marcar "All repositories" para acesso irrestrito.

## Token OAuth Clássico — Escopos Necessários

Para tokens OAuth clássicos (`gho_*`), os escopos mínimos são:
- `repo` — acesso a repositórios privados
- `workflow` — criar/atualizar arquivos `.github/workflows/`

**Sem o escopo `workflow`**, qualquer push que contenha arquivos em `.github/workflows/` é rejeitado com:
```
! [remote rejected] branch → branch
  (refusing to allow an OAuth App to create or update workflow
   `.github/workflows/ci.yml` without `workflow` scope)
```

Para adicionar o escopo: `gh auth refresh -h github.com -s workflow` e autorizar no browser.

## Clone com Token

```bash
# Formato correto para fine-grained PAT
git clone https://oauth2:TOKEN@github.com/USER/REPO.git
```

O prefixo `oauth2:` é obrigatório para fine-grained tokens. Tokens clássicos (`ghp_*`) usam o token diretamente como senha.

## Extração Segura do Token

O terminal Hermes mascara tokens. Usar Python para extrair do `.env`:

```python
with open("{{COMMANDER_HERMES_PATH}}/.env", "r") as f:
    for line in f:
        if line.startswith("{{ORCHESTRATOR_UPPER}}_GITHUB_PERSONAL_ACCESS_TOKEN="):
            token = line.strip().split("=", 1)[1]
            break
```

## Configurar Git Remote com Token

```bash
cd {{COMMANDER_HOME}}/projects/REPO
git remote set-url origin "https://oauth2:TOKEN@github.com/USER/REPO.git"
git config user.name "Agent Name"
git config user.email "agent@pycode.cerebro"
```

## Verificar Acesso

```bash
# API retorna 200 se tem acesso, 404 se não
curl -s -H "Authorization: Bearer TOKEN" \
  "https://api.github.com/repos/USER/REPO"
```

**Pitfall**: GitHub retorna 404 (não 403) para repositórios privados que o token não tem acesso — é uma medida de segurança para não revelar existência do repo.

**Pitfall (workflow scope):** O GitHub **também bloqueia a API REST** para criação de arquivos em `.github/workflows/` sem o escopo `workflow`. Não é só o Git — a Contents API retorna 404 ao tentar `PUT /repos/{owner}/{repo}/contents/.github/workflows/ci.yml` sem o escopo. A proteção é na camada de autorização, independente do protocolo.

## Troubleshooting

| Sintoma | Causa | Solução |
|---------|-------|---------|
| `fatal: could not read Username` | Clone sem token em repo privado | Usar `https://oauth2:TOKEN@github.com/...` |
| `403: Write access not granted` | Token sem permissão Contents:Write | Adicionar permissão em github.com/settings/tokens |
| `refusing to allow an OAuth App to create or update workflow` | Token OAuth clássico sem escopo `workflow` | `gh auth refresh -h github.com -s workflow` |
| `404` na API | Token sem acesso ao repo OU repo não existe | Verificar "Only select repositories" nas configs do token |
| API `404` ao criar `.github/workflows/*` | Token sem escopo `workflow` (mesmo com `push: true`) | Adicionar escopo `workflow` ou usar fine-grained PAT com Workflows:Write |
| Token começa com `***` no shell | Terminal masking | Extrair via Python `open()` direto |

## Device Flow (Non-Interactive Auth)
