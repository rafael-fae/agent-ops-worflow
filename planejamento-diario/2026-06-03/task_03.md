# Task 03 — Sanitizar skills — remover refs específicas

**Wave:** 2 (Sanitização)
**Prioridade:** 🔴
**Ferramenta:** Gemini CLI
**Depende de:** task_01

---

## Contexto

As skills copiadas em `files/skills/raw/` contêm referências ao time **Roshar**
(Dalinar, Navani, Kaladin, Shallan, Jasnah, Pattern), ao projeto **Oeste Gestão**,
e ao **Rafael**. Precisamos criar versões sanitizadas em `files/skills/sanitized/`.

---

## Instruções

### 1. Criar diretório de saída

```
mkdir -p agent-ops-workflow/files/skills/sanitized/
```

### 2. Para cada skill em raw/, criar cópia sanitizada em sanitized/

Substituições obrigatórias:

| Termo original | Substituir por |
|----------------|----------------|
| Roshar | {{TEAM_NAME}} |
| Dalinar | {{ORCHESTRATOR}} |
| Navani | {{BACKEND_ENGINEER}} |
| Kaladin | {{DEVOPS_ENGINEER}} |
| Shallan | {{FRONTEND_ENGINEER}} |
| Jasnah | {{AUDITOR}} |
| Pattern | {{GIT_OPS}} |
| Oeste Gestão | {{PROJECT_NAME}} |
| Rafael | {{COMMANDER}} |
| Rafael Fae | {{COMMANDER_NAME}} |
| oeste-gestao | {{PROJECT_SLUG}} |
| ~/Dev/oeste-gestao | {{PROJECT_PATH}} |
| pycode.rafaelfae.com.br | {{BLOG_URL}} |
| rafael@... (emails) | {{CONTACT_EMAIL}} |
| BBmqCzkuy72YHkb!pr4g | {{DONTUS_PASSWORD}} |
| 230257 | {{DONTUS_CLINICA_ID}} |
| U0B7EHB5VJL e outros IDs | {{SLACK_ID_ORCHESTRATOR}} etc. |
| C0B6DUQGJSX | {{SLACK_CHANNEL_MAC}} |
| #operacao-mac | {{SLACK_CHANNEL_TEAM}} |
| #sala-de-guerra | {{SLACK_CHANNEL_WAR_ROOM}} |

### 3. Regras de sanitização

- Manter a estrutura e lógica dos documentos
- Placeholders usam `{{NOME}}` (formato Mustache/django template)
- Incluir comentário no topo de cada arquivo:
  ```markdown
  <!--
  Arquivo sanitizado para agent-ops-workflow.
  Substitua os placeholders {{...}} pelos valores do seu time.
  Veja docs/SETUP.md para instruções.
  -->
  ```
- NÃO traduzir conteúdo (manter pt-BR)
- NÃO modificar a estrutura das skills

### 4. Verificação

Ao final, verificar que não sobrou nenhum termo original:
```
grep -rn "Roshar\|Rafael\|Dalinar\|Navani\|Kaladin\|Shallan\|Jasnah\|Pattern\|Oeste Gestão\|oeste-gestao" \
  agent-ops-workflow/files/skills/sanitized/ || echo "OK — nenhum termo original encontrado"
```

---

## Checklist

- [ ] Diretório sanitized/ criado
- [ ] Cada skill raw/ → sanitized/ com substituições
- [ ] Placeholders usam formato {{NOME}} consistente
- [ ] Comentário de cabeçalho adicionado em cada arquivo
- [ ] grep de verificação não encontrou termos originais
- [ ] MANIFEST.md atualizado com caminho sanitized/

---

## Restrições

- NÃO modificar raw/ — raw é a fonte original imutável
- NÃO traduzir conteúdo
- NÃO inventar placeholders — usar apenas os listados

---

## Arquivos relevantes

- files/skills/raw/* → fonte
- files/skills/sanitized/* → destino

---

## Conclusão

`TBD`
