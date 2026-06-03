---
name: deploy-equipe-isolada
description: Checklist de segurança para deploy de nova equipe de agentes Hermes isolada no mesmo servidor OVH, com separação de usuário Linux, credenciais e dados.
category: security
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Deploy de Equipe Hermes Isolada — Checklist de Segurança

## Quando usar
Antes de ativar uma nova equipe de agentes Hermes (ex: noiva, cliente) no mesmo servidor OVH, coexistindo com os Radiantes do {{COMMANDER}}.

## Pré-requisitos (ANTES do deploy)

### Isolamento de SO (P0 — obrigatório)
- [ ] **Criar usuário Linux separado** (ex: `noiva-agent`), home próprio (`/home/noiva-agent/`)
- [ ] **Profile em diretório isolado** com owner do novo user, `chmod 700` no diretório
- [ ] **Sessions com `chmod 600`** — NUNCA 664
- [ ] **.env com `chmod 600` e owner do novo user** — inacessível ao user `{{COMMANDER}}`
- [ ] **PM2 processo rodando como o novo user** (via systemd ou `pm2 start` com user flag)
- [ ] Verificar que o novo user NÃO pertence ao grupo `{{COMMANDER}}`

### Credenciais (P0 — obrigatório)
- [ ] **Tokens NOVOS e independentes** — OpenRouter/OpenCode/WhatsApp/Slack próprios
- [ ] NUNCA armazenar tokens no `ecosystem.config.js` — usar `env_file` do PM2 ou `.env` do profile
- [ ] **Cota/limites separados** — não compartilhar API key que tem rate limit

### Plataformas (P1)
- [ ] **WhatsApp**: Número dedicado, sem acesso a grupos do {{COMMANDER}}
- [ ] **Slack**: Workspace separado ou app diferente com canais isolados
- [ ] **Demais plataformas**: Verificar que Discord/Telegram/etc não compartilham canais

### Hardening (P2)
- [ ] Avaliar remover `terminal` toolset ou configurar `command_allowlist` restrito
- [ ] Restringir `cwd` no `config.yaml` ao diretório do profile
- [ ] `persistent_shell: false` se possível
- [ ] `file_read_max_chars` limitado para evitar dump massivo acidental

## Teste de Isolamento (pós-deploy)

### Teste 1 — Leitura de .env
Como user `{{COMMANDER}}`, tentar ler o .env da nova equipe. Deve falhar com "Permission denied".

### Teste 2 — Leitura de sessions
Como user `{{COMMANDER}}`, tentar ler os JSONL de sessions da nova equipe. Deve falhar.

### Teste 3 — Verificação PM2
Listar processos PM2 e confirmar que o user da nova equipe é diferente de `{{COMMANDER}}`.

### Teste 4 — Cross-terminal
Como agente do {{COMMANDER}} (que tem ferramenta terminal), tentar acessar paths da nova equipe. Deve falhar.

### Teste 5 — Network
Verificar que UFW cobre ambos os usuários e que nenhuma porta nova foi exposta indevidamente.

## Notas

- O problema fundamental resolvido: DAC do Linux (Discretionary Access Control) baseia-se em UID. Com UIDs diferentes, `chmod 600` no `.env` de fato protege.
- Para cliente pagante exigindo isolamento forte, considere containers Docker (N3) ou VMs (N4) em vez de apenas separação de user (N2).
- A correção `chmod 600` nas sessions existentes é recomendada mesmo sem nova equipe — protege contra leitura acidental por group/other.

## Pitfalls de Auditoria (lições do deploy Thaísa, 19/05/2026)

### P1 — Filtro de segurança mascara credenciais no terminal
O output de comandos de leitura automaticamente oculta padrões de credencial, substituindo-os por asteriscos no display. Credenciais REAIS aparecem mascaradas. Isso NAO significa que estao ausentes.

**Sintoma:** leitura de arquivo mostra valor mascarado, mas a credencial esta presente.
**Verificacao correta:** usar dump hexadecimal para confirmar presenca de bytes reais vs asteriscos literais.
**Impacto real:** Este falso-positivo causou horas de retrabalho em 19/05/2026, com multiplos agentes reportando "tokens ausentes" que estavam corretos.

### P2 — Placeholder concatenado a valor real
Arquivo gerado por template tem placeholders. Se o valor real for colado sem remover o placeholder, o resultado e uma concatenacao invalida. **Sempre substitua a linha inteira**, nunca concatene.

### P3 — Dualidade de diretorios no N2
No modelo de usuario Linux separado, existem DOIS conjuntos:
- `/home/<user>/profiles/` — artefatos de deploy (env global, ecosystem, docs)
- `/home/<user>/.hermes/profiles/` — perfis Hermes operacionais (env individual, SOUL, sessions, skills)

**Pitfall:** Verificar env no path errado gera falso "arquivo nao encontrado". O setup automatico cria o perfil em `.hermes/profiles/`. Em 19/05/2026, houve confusao entre os dois paths.

### P4 — Disciplina de Sinal Verde (PEAD)
O checklist de seguranca so e executado COM autorizacao explicita do Comandante. Acoes destrutivas sem Sinal Verde violam o PEAD e causaram incidentes em 19/05/2026:
- Usuario criado sem autorizacao (benigno, mas violacao)
- Arquivo de credenciais corrompido por script de "correcao" que duvidou de informacao confirmada
- Escala de suspeita: agente → {{ORCHESTRATOR}} → {{COMMANDER}}. Nunca agente age unilateralmente.

### P5 — Validacao de nomes contra API oficial
Nomes de escopo ou comando NAO podem ser deduzidos. Todo artefato que referencia API externa deve ser validado contra a documentacao oficial antes de ser emitido. Erro de nomenclatura queima credibilidade e gera retrabalho (ex: escopo Slack inexistente documentado, 19/05/2026).
