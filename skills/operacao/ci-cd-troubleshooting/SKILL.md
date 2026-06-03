---
name: ci-cd-troubleshooting
description: Diagnóstico e correção de falhas em pipelines CI/CD (GitHub Actions, Django, Python). Cobre Ruff, pytest, Bandit, setuptools, secrets, e service containers.
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# CI/CD Troubleshooting

## Trigger

Quando um workflow de CI/CD falha no GitHub Actions — seja lint, teste, segurança, ou build — e precisa de diagnóstico iterativo até passar verde.

## Workflow de Diagnóstico

1. **Ler o log do job** via `gh api repos/{owner}/{repo}/actions/jobs/{job_id}/logs`
2. **Identificar o erro raiz** — grep por `error`, `Traceback`, `ModuleNotFoundError`, `exit code`
3. **Corrigir no código local**, commitar, push
4. **Monitorar** via `gh api repos/{owner}/{repo}/actions/runs/{run_id}/jobs`
5. **Repetir** até todos os jobs passarem

## Comandos Úteis

```bash
# Listar runs recentes
gh api repos/OWNER/REPO/actions/runs --jq '.workflow_runs[:3] | .[] | {name, status, conclusion}'

# Ver jobs de um run
gh api repos/OWNER/REPO/actions/runs/RUN_ID/jobs --jq '.jobs[] | {name, conclusion}'

# Baixar log de um job
gh api repos/OWNER/REPO/actions/jobs/JOB_ID/logs | grep -i 'error\|traceback'
```

## Referências

- `references/django-github-actions.md` — Pitfalls específicos de Django no GitHub Actions (setuptools flat-layout, Fernet, pytest exit 5, Ruff em código legado, Bandit, PostgreSQL service container)

## Pitfalls Gerais

- **Token sem escopo `workflow`**: push de `.github/workflows/` rejeitado. Ver `github-pat-private-repos` para solução.
- **`continue-on-error: true` não torna workflow verde**: o job ainda é marcado como failure. Usar `|| true` no comando para suprimir exit code.
- **Node.js 20 deprecation warning**: actions/checkout@v4 e setup-python@v5 usam Node 20. Ignorar por enquanto (deprecation em Set/2026).
