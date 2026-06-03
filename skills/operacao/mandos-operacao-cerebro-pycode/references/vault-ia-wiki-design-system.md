# IA Wiki — Design System Workflow (Vault Reference)

## Localização no Vault

```
~/Dev/obsidian/20_Areas/Software Engeneering/Python/Pycode/IA Wiki/
```

## Documentos Relevantes

| Documento | Conteúdo |
|-----------|----------|
| `00_IA Wiki.md` | Índice principal. Seção "Design system, extração de referências e construção de interfaces" |
| `Como extrair Design System de uma página de referência.md` | Pipeline completo: encontrar referência → baixar → prompt de extração → validar → usar no fluxo |
| `Spec-Driven Development com IA - o workflow completo.md` | Fluxo: prompt refinado → PRD → start template → Design System extraído → sprint executor → feature planner |
| `imersao-bootstrap — Conteúdo completo.md` | Bootstrap cria `design_system/design-system.html` automaticamente |

## Fluxo de Trabalho com Design System

1. **{{COMMANDER}} escolhe uma referência visual** (URL de página/sistema que ele gosta visualmente)
2. **Extração com IA**: o prompt de extração analisa a referência e gera tokens (cores, tipografia, spacing, componentes)
3. **Artefato**: `design_system/design-system.html` — fonte única de verdade visual
4. **{{FRONTEND_ENGINEER}}-mac + Opus** usam esse arquivo como contrato visual para todo o frontend

## Regra ({{COMMANDER}}, 29/05/2026)

- O sistema NÃO deve ser cópia visual do Dontus — identidade própria
- {{FRONTEND_ENGINEER}}-mac SEMPRE usa Claude Opus para frontend, em etapas menores
- Aguardar {{COMMANDER}} enviar a referência de design system
