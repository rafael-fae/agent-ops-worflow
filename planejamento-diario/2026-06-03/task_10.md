# Task 10 — Publicar no GitHub + auditoria final consolidada

**Wave:** 4 (Finalização)
**Prioridade:** 🟢
**Ferramenta:** Gemini CLI
**Depende de:** task_09

---

## Contexto

Repositório está pronto localmente. Agora vamos publicar no GitHub e fazer
a auditoria final de todo o projeto — garantindo que está tudo correto,
documentado e funcional.

---

## Instruções

### 1. Criar repositório no GitHub

Usar `gh` CLI (se disponível) ou instruções manuais:

```bash
# Se gh estiver configurado:
gh repo create agent-ops-workflow --public --description \
  "Sistema de planejamento diário multi-agente para Hermes — markdown, Slack, skills e scripts"

# Push
git remote add origin git@github.com:SEU_USUARIO/agent-ops-workflow.git
git branch -M main
git push -u origin main
```

### 2. Configurar repositório no GitHub

- Topics: `hermes-agent`, `hermes-workflow`, `multi-agent`, `ai-agents`, `workflow`, `planejamento`
- Website: (se houver)
- Description: preenchida
- Releases: criar v1.0.0 inicial

### 3. Auditoria final de qualidade

Verificar ponto a ponto:

**Sanitização:**
- [ ] Nenhum arquivo contém "Roshar", "Rafael", "Oeste Gestão", "Dalinar", etc.
- [ ] Todos os placeholders usam formato consistente
- [ ] Comentários de cabeçalho presentes em skills sanitizadas

**Documentação:**
- [ ] README.md completo com quickstart funcional
- [ ] Todas as 6 docs/ estão preenchidas
- [ ] Cross-links funcionam
- [ ] docs/06-REFERENCIA-RAPIDA.md realmente é 1 página

**Templates:**
- [ ] PLANO.md.tpl funcional (alguém consegue preencher)
- [ ] TASK.md.tpl funcional
- [ ] INDICE.md.tpl funcional

**Scripts:**
- [ ] setup-workflow.sh executável (`chmod +x`)
- [ ] gerar-plano-diario.sh executável
- [ ] validate-workflow.sh executável
- [ ] rotate-key.sh executável

**Repositório:**
- [ ] .gitignore correto
- [ ] files/ não está no tracking
- [ ] LICENSE presente (MIT)
- [ ] Estrutura limpa

**Nosso próprio planejamento:**
- [ ] INDICE.md atualizado com commits e status
- [ ] Todas as task_XX.md com checkboxes preenchidos
- [ ] Conclusão preenchida em tasks concluídas
- [ ] PLANO.md atualizado com status finais

### 4. Relatório consolidado

Produzir no terminal:

```markdown
# Auditoria Final — agent-ops-workflow v1.0.0

## Itens verificados: 25/25 ✅

## Estrutura
- skills/: X skills sanitizadas
- docs/: 6 documentos
- templates/: 4 templates
- scripts/: 4 scripts + README

## Veredito
✅ Repositório pronto para publicação.
```

---

## Checklist

- [ ] Repositório criado no GitHub (público)
- [ ] Push realizado com sucesso
- [ ] Topics e descrição configurados
- [ ] Auditoria de sanitização: 0 termos originais encontrados
- [ ] Auditoria de docs: 6/6 documentos completos
- [ ] Auditoria de scripts: todos testados
- [ ] Planejamento-diario finalizado e commitado
- [ ] Release v1.0.0 criada
- [ ] Link enviado para Rafael

---

## Restrições

- Repositório PÚBLICO — sem dados sensíveis
- NENHUMA credencial ou dado do projeto original

---

## Conclusão

`TBD`
