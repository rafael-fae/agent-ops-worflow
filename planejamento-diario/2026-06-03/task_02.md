# Task 02 — Mapear scripts, templates, assets → files/

**Wave:** 1 (Mapeamento)
**Prioridade:** 🔴
**Ferramenta:** Gemini CLI
**Depende de:** —

---

## Contexto

Além das skills, temos scripts de automação, templates de documentos e assets
visuais espalhados pelos skills. Precisamos copiar tudo para `files/` para
sanitização posterior.

---

## Instruções

### 1. Scripts

Copiar todos os scripts encontrados nas skills para:
```
agent-ops-workflow/files/scripts/raw/
```

Fontes possíveis:
- `~/.hermes/profiles/dalinar/skills/*/scripts/*`
- `~/.hermes/profiles/dalinar/scripts/*` (se existir)

### 2. Templates

Copiar todos os templates encontrados nas skills para:
```
agent-ops-workflow/files/templates/raw/
```

Fontes:
- `~/.hermes/profiles/dalinar/skills/*/templates/*`

### 3. Assets

Copiar assets (CSS, HTML, imagens) se houver nas skills para:
```
agent-ops-workflow/files/assets/raw/
```

### 4. Manifesto

Criar `files/MANIFEST-GERAL.md` com:

```markdown
# Manifesto Geral — agent-ops-workflow

## Scripts encontrados
| # | Nome | Origem | Tipo | Descrição |
|---|------|--------|------|-----------|
| 1 | rotate-key.sh | skill/planejamento-diario | Shell | Rotação de chaves SSH |

## Templates encontrados
| # | Nome | Origem | Descrição |
|---|------|--------|-----------|
| 1 | PLANO.md | skill/planejamento-diario | Template de plano diário |

## Assets encontrados
| # | Nome | Origem | Tipo |
|---|------|--------|------|
...
```
              
---

## Checklist

- [x] Scripts copiados para files/scripts/raw/
- [x] Templates copiados para files/templates/raw/
- [x] Assets copiados para files/assets/raw/
- [x] MANIFEST-GERAL.md criado com inventário
- [x] NENHUM arquivo original modificado

---

## Restrições

- NUNCA modificar arquivos originais
- Apenas cópia + inventário — sem edição

---

## Conclusão

**Agente:** Dalinar (via subagentes)
**Concluída em:** 03/06/2026 ~10:00
**Motor utilizado:** Gemini CLI + deepseek-v4-flash (subagentes)
**Observações:** 
- Scripts: 4 encontrados (3 .sh, 1 .py) — rotate-key, hermes-agent, e outros
- Templates: 8 encontrados (PLANO.md, TEMPLATE_TASK.md, etc.)
- References: 108 arquivos (107 .md + 1 .json) de diversas skills
- Assets: 0 — nenhuma skill possui pasta assets/
- MANIFEST-GERAL.md criado em files/MANIFEST-GERAL.md com inventário completo
- 2 conflitos de nome resolvidos: docker-pitfalls.md e ovh-security-hardening.md (prefixados com skill de origem)
