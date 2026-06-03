# Task 09 — Estruturar repositório final (sem files/)

**Wave:** 4 (Finalização)
**Prioridade:** 🟢
**Ferramenta:** Gemini CLI
**Depende de:** task_06, task_07, task_08

---

## Contexto

Neste ponto temos:
- `files/` com material bruto e sanitizado (NÃO vai pro repositório final)
- `templates/` com os .tpl
- `scripts/` com automações
- `docs/` com documentação
- `README.md` na raiz

Precisamos organizar a estrutura FINAL do repositório, removendo `files/`,
adicionando `.gitignore`, e garantindo que tudo está coeso.

---

## Instruções

### 1. Estrutura final desejada

```
agent-ops-workflow/
├── README.md
├── LICENSE (MIT)
├── .gitignore
├── .github/
│   └── FUNDING.yml (opcional)
├── docs/
│   ├── 01-SETUP-INICIAL.md
│   ├── 02-CICLO-DIARIO.md
│   ├── 03-PROTOCOLO-SLACK.md
│   ├── 04-GUIA-SKILLS.md
│   ├── 05-ADAPTACAO.md
│   └── 06-REFERENCIA-RAPIDA.md
├── templates/
│   ├── PLANO.md.tpl
│   ├── TASK.md.tpl
│   ├── INDICE.md.tpl
│   └── README-WORKFLOW.md.tpl
├── skills/
│   └── <skills sanitizadas organizadas por categoria>
├── scripts/
│   ├── setup-workflow.sh
│   ├── gerar-plano-diario.sh
│   ├── validate-workflow.sh
│   ├── rotate-key.sh
│   └── README.md (instruções dos scripts)
├── assets/
│   └── (apenas se houver algo útil e genérico)
└── planejamento-diario/    ← NOSSO PRÓPRIO PLANO (prova viva)
    ├── INDICE.md
    ├── 2026-06-03/
    │   ├── PLANO.md
    │   ├── task_01.md
    │   └── ...
    └── TEMPLATE_PLANO.md (cópia do template)
```

### 2. Ações

- Mover `templates/` da raiz para a raiz (já está)
- Mover skills sanitizadas de `files/skills/sanitized/` para `skills/`
- Remover `files/` completamente
- Criar `.gitignore`:
  ```
  # agent-ops-workflow .gitignore
  files/          ← nunca commitado
  .env
  *.local
  ```

### 3. Verificações

- Estrutura final simétrica e limpa
- Nenhum arquivo raw em skills/ (só sanitizados)
- README.md reflete estrutura real
- Todos os links internos funcionam

### 4. Commit inicial (local, ainda não publicado)

```bash
cd ~/Dev/agent-ops-workflow
git init
git add .
git status  # verificar se files/ NÃO aparece
```

---

## Checklist

- [ ] files/ removido completamente
- [ ] skills/ populado com skills sanitizadas
- [ ] .gitignore criado (exclui files/, .env, *.local)
- [ ] Estrutura igual ao planejado
- [ ] `git status` confirma que files/ não está sendo trackeado
- [ ] README.md atualizado com estrutura real
- [ ] Licença MIT adicionada

---

## Restrições

- NENHUM arquivo raw — apenas conteúdo sanitizado
- NENHUMA referência a Roshar/Oeste Gestão na estrutura final

---

## Conclusão

`TBD`
