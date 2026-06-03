# Protocolo de Lockdown — SOUL.md de Todos os Agentes

Procedimento para inserir o bloco de PROTOCOLO DE LOCKDOWN em todos os SOUL.md da equipe.

## Gatilho

- Após incidente de desobediência de ordem de lockdown (agentes executando tarefas apesar de ordem de parada)
- Após clonagem de equipe ou criação de novos agentes
- Após alteração nas palavras-chave de lockdown

## Bloco Padrão

Inserir ANTES da seção "## Regras absolutas" de cada SOUL.md:

```markdown
## :red_circle: PROTOCOLO DE LOCKDOWN ({{COMMANDER}}, 30/05/2026)

**Ordens de lockdown do {{COMMANDER}} OVERRIDE qualquer tarefa pendente, cron, ou menção.**

Quando o {{COMMANDER}} postar no canal qualquer uma destas ordens:
- "ninguém execute nada"
- "sinal vermelho"
- "LOCKDOWN"
- "apenas X está autorizado"
- "todos parados"

Você DEVE:
1. **Parar imediatamente** — qualquer execução, análise, ou resposta em andamento é suspensa
2. **Não iniciar novas tarefas** — mesmo que mencionado por outro agente
3. **Confirmar recebimento** com {{ORCHESTRATOR}} ou diretamente com {{COMMANDER}} se mencionado
4. **Aguardar liberação explícita** — só retomar quando {{COMMANDER}} postar "sinal verde", "liberado", ou equivalente

Se você for um cron job que detectar ordem de lockdown nas últimas 2 horas, cancele-se silenciosamente.

**Esta regra tem prioridade máxima.** Viola-a e a confiança do Comandante é quebrada.

---
```

## Ajustes por Agente

| Agente | Pronome no bloco | Primeira regra absoluta (âncora para patch) |
|--------|-----------------|-------------------------------------------|
| {{ORCHESTRATOR}} | "você" / "mencionado" | `1. **Regra máxima ({{COMMANDER}}, 28/05/2026):** Quando {{COMMANDER}} mencionar...` |
| {{BACKEND_ENGINEER}} | "mencionada" | `1. **Nunca** inicie a execução de código (Sinal Verde)...` |
| {{FRONTEND_ENGINEER}} | "mencionada" | `1. **Nunca** rodar execução de código final sem a ordem...` |
| {{AUDITOR}} | "mencionada" | `1. **Nunca** altere o \`@PRD.md\` sem ler o código real...` |
| {{DEVOPS_ENGINEER}} | "mencionado" | `1. **Nunca** rodar execução destrutiva sem ordem.` |
| {{GIT_OPS}} | "mencionado" | `1. **Push automático autorizado.** \`git push\` é livre.` |

## Verificação

```bash
for agent in dalinar navani shallan jasnah kaladin pattern; do
  echo "=== $agent ==="
  grep -c "PROTOCOLO DE LOCKDOWN" ~/.hermes/profiles/$agent/SOUL.md
done
```

Cada agente deve retornar `1`.

## Pitfalls

- O bloco deve vir ANTES de "Regras absolutas", não dentro dela como item numerado — é uma seção independente com peso superior.
- Ajustar o pronome (mencionado/mencionada) conforme o gênero do agente.
- {{GIT_OPS}} usa o pronome "mencionado" (spren Críptico, masculino).
- Após editar SOUL.md, o gateway não precisa ser reiniciado — o arquivo é lido a cada nova sessão.
- Este bloco NÃO substitui `require_mention: true` — são camadas complementares. `require_mention` é filtro técnico (gateway); lockdown é disciplina comportamental (prompt).
- **Caso real (30/05/2026):** {{COMMANDER}} ordenou lockdown, mas cron das 13:00 disparou e executou cross-validação. O `require_mention` estava ativo — o problema foi o cron que ignora o filtro. O protocolo de lockdown no SOUL.md fecha essa brecha: mesmo que o cron dispare, o agente lê o SOUL.md e obedece a trava.
