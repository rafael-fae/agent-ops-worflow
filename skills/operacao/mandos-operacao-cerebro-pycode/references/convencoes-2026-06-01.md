# Convenções Operacionais — 01/06/2026

## Delegação

- **CRIAR tasks ≠ DELEGAR tasks.** {{COMMANDER}} pode pedir apenas para criar os arquivos task_XX.md sem delegar.
- **1 task por vez.** Delegar múltiplas só com autorização explícita.
- **Fluxo:** cria task → {{COMMANDER}} autoriza → {{ORCHESTRATOR}} delega → agente conclui → próximo.

## Canal

- Equipe Mac: `{{SLACK_CHANNEL_TEAM}}` (<#{{SLACK_CHANNEL_TEAM_ID}}>)
- NUNCA usar `{{SLACK_CHANNEL_OVH}}` (é da Sociedade do Anel/OVH)

## Thread

- **CADA task = UMA thread.** Primeira mensagem abre a thread. TODAS as mensagens subsequentes (sinal verde, atualizações, leitura, conclusão) são RESPOSTAS nela.
- **NUNCA enviar múltiplas mensagens separadas para a mesma task.** 3 mensagens = 3 threads = caos.

## Git

- Branch padrão: `develop`
- SEMPRE: `git checkout develop` antes de começar
- SEMPRE: commit + push + hash no report
- `git log -- <file>` é a prova de que a task foi concluída

## Motor

| Prioridade | Motor | Comando |
|---|---|---|
| 1º | Gemini CLI | `gemini -m "gemini-3.1-pro-preview"` |
| 2º | DeepSeek V4 Pro | SÓ com autorização explícita do {{COMMANDER}} |

## Dontus (Referência Viva)

- URL: `sistema.dontus.com.br` / Usuário: `{{COMMANDER}}` / Senha: `{{DONTUS_PASSWORD}}`
- Doc: `docs/referencias/ACESSO-DONTUS.md`
- Usar para verificação visual de UI/fluxos durante implementação

## Ambiente

- Mac = desenvolvimento (`{{PROJECT_PATH}}`)
- OVH = testes/produção (`{{OVH_SSH_COMMAND}}`, IP 142.4.215.215)
- Cloudflare Tunnel: `gestao.oesteodontologia.com.br` → `localhost:8000`
- {{ORCHESTRATOR}} faz `git pull` na OVH após cada task concluída

## Docker

- `docker-compose.yml` `command:` SOBRESCREVE Dockerfile CMD
- Sempre verificar ambos quando container não inicia
