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

- [ ] Scripts copiados para files/scripts/raw/
- [ ] Templates copiados para files/templates/raw/
- [ ] Assets copiados para files/assets/raw/
- [ ] MANIFEST-GERAL.md criado com inventário
- [ ] NENHUM arquivo original modificado

---

## Restrições

- NUNCA modificar arquivos originais
- Apenas cópia + inventário — sem edição

---

## Conclusão

`TBD`
