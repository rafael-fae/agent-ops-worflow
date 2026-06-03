# Gerenciamento de Toolsets nos Agentes

Procedimento para adicionar, remover, ou auditar toolsets nos `config.yaml` de todos os agentes simultaneamente.

## Gatilho

- {{COMMANDER}} solicita ativação/desativação de um toolset para todos os agentes
- Novo toolset disponível que precisa ser propagado
- Auditoria de quais agentes têm acesso a determinado toolset

## Toolsets Disponíveis (Hermes)

| Toolset | Descrição |
|---------|-----------|
| `hermes-cli` | Ferramentas CLI do Hermes |
| `web` | Browser tools (navigate, click, snapshot) |
| `search` | DuckDuckGo web search |
| `browser` | Browser interaction |
| `terminal` | Shell, processos, scripts |
| `file` | read_file, write_file, search_files, patch |
| `skills` | skill_view, skills_list, skill_manage |
| `memory` | Memória persistente |
| `session_search` | Busca em sessões passadas |
| `todo` | Lista de tarefas |
| `delegation` | delegate_task (subagentes) |
| `messaging` | send_message |
| `cronjob` | Jobs agendados |
| `clarify` | Perguntas ao usuário |
| `vision` | vision_analyze, video_analyze |

## Auditoria — Qual agent tem qual toolset?

```bash
for agent in dalinar navani shallan jasnah kaladin pattern; do
  echo "=== $agent ==="
  grep -A20 '^toolsets:' ~/.hermes/profiles/$agent/config.yaml | grep '^  - ' | head -15
  echo
done
```

## Adicionar Toolset a Todos os Agentes

### Passo 1: Verificar estado atual

Antes de adicionar, confirmar se o toolset já existe em cada agente:

```bash
for agent in dalinar navani shallan jasnah kaladin pattern; do
  printf "%-10s: " $agent
  grep -c "^- $TOOLSET$" ~/.hermes/profiles/$agent/config.yaml 2>/dev/null || echo "0"
done
```

### Passo 2: Verificar seção toolsets existe

Agentes clonados ou com config mínimo (ex: {{GIT_OPS}}) podem não ter seção `toolsets:`:

```bash
for agent in dalinar navani shallan jasnah kaladin pattern; do
  printf "%-10s: " $agent
  grep -c '^toolsets:' ~/.hermes/profiles/$agent/config.yaml 2>/dev/null || echo "MISSING"
done
```

### Passo 3: Adicionar via patch (agentes com toolsets existente)

Usar `patch` com `mode='replace'` — inserir o toolset em posição lógica na lista (ex: `search` entre `web` e `browser`):

```
old: "- web\n- browser"
new: "- web\n- search\n- browser"
```

Aplicar em cada agente individualmente (5 chamadas paralelas de patch).

### Passo 4: Criar seção toolsets completa (agente sem toolsets)

Para agentes sem seção `toolsets:` (ex: {{GIT_OPS}}), usar patch para inserir após `agent:` e antes da próxima seção (ex: `memory:`):

```yaml
agent:
  max_turns: 30
  ...
  
toolsets:
- hermes-cli
- web
- search
- browser
- terminal
- file
- skills
- memory
- session_search
- todo
- delegation
- messaging
- cronjob
- clarify
- vision

memory:
  ...
```

### Passo 5: Reiniciar gateways

```bash
for agent in dalinar navani shallan jasnah kaladin pattern; do
  launchctl kickstart -k gui/$(id -u)/com.{{COMMANDER}}.hermes.$agent
  sleep 1
done
```

### Passo 6: Verificar aplicação

```bash
# Confirmar toolset no config
for agent in dalinar navani shallan jasnah kaladin pattern; do
  grep -n "^- $TOOLSET$" ~/.hermes/profiles/$agent/config.yaml
done

# Confirmar gateways rodando
ps aux | grep 'hermes.*gateway run' | grep -v grep | wc -l
# Esperado: 6
```

## Pitfalls

- **`session_search` ≠ `search`**: `session_search` é busca em sessões passadas (auxiliary tool). `search` é DuckDuckGo web search. Não confundir.
- **Agentes sem seção `toolsets:`**: {{GIT_OPS}} historicamente não tinha toolsets. É necessário criá-la do zero antes de adicionar qualquer toolset.
- **Gateway precisa reiniciar**: Config changes no `config.yaml` só têm efeito após reinicialização do gateway. `launchctl kickstart -k` é o método.
- **{{ORCHESTRATOR}} pode ter múltiplas instâncias**: Se houver PID duplicado, o `--replace` flag resolve. Verificar com `ps aux | grep dalinar`.
- **`search` toolset usa DuckDuckGo**: Não requer API key. Funciona out-of-the-box.

## Caso Real (30/05/2026)

{{COMMANDER}} ordenou "ative para todos os agentes o serviço de busca da duck duck go". Procedimento executado:

1. Auditoria: {{ORCHESTRATOR}} já tinha `web` mas nenhum agente tinha `search`
2. {{GIT_OPS}} não tinha seção `toolsets:` — criada do zero
3. {{ORCHESTRATOR}}, {{BACKEND_ENGINEER}}, {{FRONTEND_ENGINEER}}, {{AUDITOR}}, {{DEVOPS_ENGINEER}}: `search` adicionado entre `web` e `browser`
4. Gateways reiniciados via `launchctl kickstart`
5. Verificação: 6/6 agentes com `search` ativo, 6/6 gateways running
