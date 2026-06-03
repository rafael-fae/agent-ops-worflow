---
name: gemini-vision-analysis
description: Analisar prints/screenshots —优先使用 auxiliary.vision com Kimi K2.5 (built-in, zero custo), fallback para Gemini 2.5 Flash.
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Análise de Imagens (Prints/Screenshots)

Duas estratégias, em ordem de preferência:

## 1. SOLUÇÃO PREFERIDA — auxiliary.vision com Kimi K2.5 (via OpenCode Go)

**Descoberta crítica (26/05/2026):** DeepSeek V4 Flash/Pro no provider `opencode-go` **não aceita** `image_url` (erro `unknown variant 'image_url', expected 'text'`). Porém, **Kimi K2.5 e K2.6 no MESMO provider** suportam visão nativamente.

**UPDATE 26/05/2026 (sessão massiva de 153+ imagens):** Kimi K2.5 retornou `401 Invalid API key` consistentemente. {{BACKEND_ENGINEER}} confirmou chave inválida. **A solução comprovada e recomendada como PRIMÁRIA** é o fallback Gemini 2.5 Flash via `gemini_vision.py`, que processou **156 imagens com 100% de sucesso (0 falhas) em 25.6 minutos** com 3 workers paralelos. Kimi K2.5 deve ser tratado como configuração futura, não como solução atual.

### Configuração

No `config.yaml` do agente:

```yaml
auxiliary:
  vision:
    provider: opencode-go      # mesmo provider principal — sem API key extra
    model: kimi-k2.5            # modelo com visão comprovada
    base_url: https://opencode.ai/zen/go/v1
    api_key: ''                 # vazio — herda credencial do provider
    timeout: 120
    download_timeout: 30
```

**Vantagens:**
- ✅ Zero custo extra (usa mesma API key do OpenCode Go)
- ✅ Automático — gateway roteia imagens para Kimi K2.5
- ✅ Transparente — `vision_analyze` funciona sem alteração no fluxo
- ✅ Configurado em todos os 5 agentes ({{ORCHESTRATOR}}, {{BACKEND_ENGINEER}}, {{FRONTEND_ENGINEER}}, {{AUDITOR}}, {{DEVOPS_ENGINEER}})

### ⚠️ Troubleshooting — Kimi K2.5 returning 401

**Observado (26/05/2026):** {{BACKEND_ENGINEER}} reportou `401 Invalid API key` ao tentar usar Kimi 2.5. Causa provável: chave não propagada aos profiles ou chave inválida no provedor.

**Ação imediata quando Kimi falhar:**
1. **Fallback automático** para Gemini 2.5 Flash via `gemini_vision.py` — não bloquear o fluxo
2. Reportar a {{COMMANDER}} que a chave Kimi precisa verificação no provedor OpenCode Go

**Regra:** nunca travar processamento por falha de API key. Fallback imediato.

### Testes comprovados

| Modelo | Visão | Resultado |
|---|---|---|
| `deepseek-v4-flash` | ❌ | `unknown variant 'image_url'` |
| `deepseek-v4-pro` | ❌ | Mesmo erro |
| `kimi-k2.5` | ✅ | Descreveu print do Dontus em detalhes |
| `kimi-k2.6` | ✅ | Funciona |
| `minimax-m2.7` | ⚠️ | Aceita formato mas não enxerga |

### Como usar

Basta enviar a imagem no Slack — o gateway automaticamente roteia para o Kimi K2.5 via `auxiliary.vision`. O agente usa `vision_analyze()` ou recebe a imagem diretamente.

## 2. FALLBACK — Gemini 2.5 Flash (via script Python)

Use quando `auxiliary.vision` não estiver configurado ou o Kimi K2.5 não atender.

### Script

`~/.hermes/profiles/dalinar/scripts/gemini_vision.py`

## ⚠️ Regra de Uso da API Key Gemini ({{COMMANDER}}, 29/05/2026)

**Não usar a `GEMINI_API_KEY` do servidor OVH.** A chave original está em `{{COMMANDER_HERMES_PATH}}/profiles/dalinar/.env` no servidor OVH — não está nos profiles Mac locais. {{COMMANDER}} permite:
1. **Gemini CLI** (autentica via OAuth de browser, sem API key) — funciona quando ele digita `gemini` no terminal
2. **API direta com chave própria do Mac** — não usar a chave do OVH

O Gemini CLI usa OAuth e está disponível no ambiente shell interativo do {{COMMANDER}} (provavelmente via mise: `/Users/{{COMMANDER}}fae/.local/share/mise/installs/node/24.13.1/bin/gemini`). Não funciona em processos background — apenas foreground com `GEMINI_CLI_TRUST_WORKSPACE=true`.

**Resumo:** os agentes podem continuar usando Gemini via API direta ou CLI, desde que a chave NÃO seja a do OVH. Se a chave não estiver disponível localmente, usar apenas deepseek-v4-pro como fallback.

## Uso via execute_code

```python
from hermes_tools import terminal
import json

result = terminal("python3 ~/.hermes/profiles/dalinar/scripts/gemini_vision.py /caminho/da/imagem.png 'Sua pergunta sobre a imagem'")
data = json.loads(result["output"])
if data["success"]:
    print(data["analysis"])
else:
    print(f"ERRO: {data['error']}")
```

## Uso via terminal direto

```bash
python3 ~/.hermes/profiles/dalinar/scripts/gemini_vision.py /tmp/print.png "Descreva os elementos desta tela"
```

## Output

JSON com:
- `success` (bool)
- `analysis` (str) — texto da análise
- `error` (str | null)

## Dependências

- `google-genai>=2.6.0` (instalado via `pip3 install google-genai --break-system-packages`)
- `GEMINI_API_KEY` no `.env` do profile

## Fluxo quando {{COMMANDER}} envia print

1. Receber imagem via MEDIA: path no Slack
2. Chamar script Gemini Vision para analisar
3. Extrair informações relevantes (texto, elementos, layout)
4. Delegar para agente correto com contexto visual traduzido

## Processamento em Lote — Múltiplas Imagens (testado com 115+ prints em sessão única, e 153 em lote paralelo)

**Duas estratégias comprovadas:**

### Estratégia A — Paralela via batch_vision.py (RECOMENDADA para lotes de 10-200 imagens)

Para lotes grandes (10-200 imagens), use o script `batch_vision.py` que gerencia workers paralelos com progress tracking:

**Script:** `~/.hermes/profiles/dalinar/scripts/batch_vision.py`

```python
from hermes_tools import terminal

# Iniciar processamento em lote com 3 workers paralelos
result = terminal(
    "cd ~/.hermes/profiles/dalinar/scripts && python3 batch_vision.py",
    background=True,
    notify_on_complete=True,
    timeout=3600
)
```

**Comportamento:**
- 3 workers ThreadPoolExecutor paralelos
- Timeout de 45s por imagem
- Resultados salvos em `~/.hermes/profiles/dalinar/cache/vision_results/<imagem>.json`
- Auto-exclui imagens já processadas
- Progress tracking: taxa (img/min), ETA, contagem sucesso/falha
- **Testado:** 156 imagens processadas em 25.6 minutos com 3 workers paralelos — **100% sucesso, 0 falhas**. ETA real para 150+ imagens: ~25-30min.

### Estratégia B — Paralela manual (RECOMENDADA para lotes de 3-10 imagens)

Usar `terminal(background=true, notify_on_complete=true)` — executa análises em paralelo. Cada processo roda independentemente.

```python
from hermes_tools import terminal, process

sessions = []
for img in imagens[:5]:  # máximo 5 paralelos
    result = terminal(
        f"python3 ~/.hermes/profiles/dalinar/scripts/gemini_vision.py {img} 'Pergunta'",
        background=True,
        notify_on_complete=True,
        timeout=90
    )
    sessions.append(result["session_id"])
for sid in sessions:
    process(action="wait", session_id=sid, timeout=90)
```

✅ Testado com 3 imagens em paralelo ~30s.
⚠️ Limite prático: 3-5 paralelos.

### Estratégia C — Sequencial (para confirmação manual)

Para verificar visualmente cada resultado, processar uma por uma:

```bash
python3 ~/.hermes/profiles/dalinar/scripts/gemini_vision.py /path/img.png "Pergunta"
```

**Processamento de 115+ imagens ao longo de várias rodadas (durante sessão única de ~3h):**
- {{COMMANDER}} enviou 115+ prints em ~12 lotes de 9-10 imagens ao longo de uma sessão
- A cada lote: apresentar tabela markdown com #, Tela, URL, Descobertas
- Ao final de todos os lotes: gerar **Balanço Final** com tabela sumarizando todos os lotes acumulados
- **Contador acumulado**: atualizar a cada lote (ex: "Balanço Final — 80 Prints Analisadas") com contagem total crescente

### Padrão de resposta para grande volume (115+ imagens)

```markdown
## Análise das [Ordem] 10 Prints

| # | Tela | URL | Descobertas |
|:-:|------|:----:|-------------|
| **1** | **Nome** | `/url` | ⭐ descoberta principal | descoberta2 |

...

## 🏆 Balanço Final — [Total] Prints Analisadas com Gemini 2.5 Flash

| Lote | Qtd | Temas |
|:----:|:---:|-------|
| **1** | 10 | tema1, tema2 |
| **2** | 10 | tema3, tema4 |
| | **[Total]** | **~[XX]% de cobertura visual** |
```

### Regra crítica: processamento estritamente sequencial

⚠️ **Nunca enviar comandos paralelos para batches de imagens.** O terminal tool interrompe comandos paralelos (exit code 130). Sempre processar as imagens em chamadas TERMINAL únicas e sequenciais:

```
✅ Correto: 5 terminais em paralelo com 1 imagem cada → aguardar resultados → outro bloco de 5
❌ Incorreto: 10 terminais em paralelo com 1 imagem cada (interrupções garantidas)
```

### Formato de apresentação dos resultados

**Após cada sub-lote de 5:**
```
**X/10 analisadas.** Resumo rápido:

**1/10:** Nome da Tela (`/URL`) — descoberta principal
**2/10:** ...
```

**Após lote completo (10):**
```
## Análise das [Ordem] 10 Prints

| # | Tela | URL | Descobertas |
|:-:|------|:----:|-------------|
| **1** | **Nome** | `/url` | descobertas principais |
```

**Após TODOS os lotes (Balanço Final):**
```
## 🎯 Balanço Final — X Prints Analisadas

| Lote | Qtd | Temas |
|:----:|:---:|-------|
| **1** | 10 | tema1, tema2 |
| **2** | 10 | tema3, tema4 |
```

### Prompt recomendado para prints de sistema (testado 50+ vezes)

```
"Descreva detalhadamente esta tela do [SISTEMA]. 
Qual o nome, URL, campos, botões, abas, tabelas, modais? 
Inclua labels, opções e detalhes de interface."
```

Este prompt produz análise rica e estruturada, incluindo:
- Nome da página (via título + URL)
- Listagem de todos os campos visíveis com labels
- Opções de dropdown/select
- Botões e ações disponíveis
- Modais e sub-abas carregados
- Tabelas com colunas e dados de exemplo
- Status de campos (obrigatórios em vermelho, desabilitados)

### Limitações conhecidas de prints de sistemas web

1. **Sub-abas com hash (#) na URL não mudam a URL principal** — ex: `/Clinica/Edit/1#agenda` mostra a mesma URL `/Clinica/Edit/1` no navegador. A URL real da sub-aba só aparece ao passar mouse sobre o link (barra de status do navegador).
2. **Conteúdo carregado via AJAX/KO** — o print pode mostrar uma área vazia se o conteúdo for carregado dinamicamente após o clique. Nestes casos, pedir para {{COMMANDER}} descrever ou enviar print com o modal aberto.
3. **Modais sobrepostos** — prints com modal aberto obscurecem o fundo. Analisar o modal primeiro, depois descrever o que está visível do fundo.

### Padrões de sistema ERP/odontológico identificados (Dontus — 115+ prints)

Ao analisar prints do Dontus (115+ prints, ~99% de cobertura), estes padrões se repetem:
- **Listagem → Botão "Criar" → Modal/Formulário simples**: cadastros como Motivo, Bandeira, CentroCusto seguem este padrão com 3-5 campos
- **Página de edição com abas laterais**: ex: Clinica/Edit/1 tem 16 sub-abas; Paciente/Edit/346 tem 17 sub-abas; Funcionario/Edit/1 tem 4 sub-abas
- **Tabela com colunas fixas**: DESCRIÇÃO, STATUS (check verde), EDITAR (ícone lápis) — presente em ~90% dos cadastros
- **Filtros no topo da tabela**: Status (dropdown), Busca (texto), Exibir (registros por página)
- **8 status de agenda**: Agendado (azul), Atendido (preto), Cancelado (roxo), Confirmado (verde), Encaixe (laranja), Faltou (vermelho), Remarcado (amarelo), Bloqueio (lilás)

### Multi-tenant Architecture Discovery

**Descoberta crítica durante a engenharia reversa do Dontus:**

O Dontus usa **database-per-tenant** (cada "ID Dontus" = um banco PostgreSQL separado), NÃO shared-db com tenant_id em todo lugar.

```
ID Dontus {{DONTUS_CLINICA_ID}} (Oeste)
└── Banco: oeste_gestao_{{DONTUS_CLINICA_ID}}
    ├── Clínica A (Matriz)
    ├── Clínica B (Filial)
    ├── Profissionais (compartilhados entre clínicas — N:N)
    ├── Procedimentos (compartilhados — globais no tenant)
    └── Modelos de Documentos (compartilhados)
```

**Implicações arquiteturais:**
- `clinica_id` NÃO é FK de isolamento — é FK organizacional dentro do mesmo banco
- Procedimento, Grupo, Especialidade são **globais dentro do tenant** (sem clinica FK)
- Profissional ↔ Clínica é **N:N** (não FK única)
- Zero middleware de tenant no Django
- 1 Docker Compose por ID Dontus
- Lookup tables (FormaPagamento, Motivo, etc.) são compartilhadas naturalmente dentro do banco

## Output

`auxiliary.vision` (Kimi K2.5) ou `gemini-2.5-flash` — ambos rápidos e baratos, suficientes para UI/screenshots.

## Fluxo quando modelo principal não suporta vision

1. **Passo 0 — Tentar auxiliary.vision**: Se `auxiliary.vision` estiver configurado com Kimi K2.5, testar. Se retornar 401 (chave inválida), ir direto ao Fallback.
2. **Passo 1 (fallback principal)**: Usar `gemini_vision.py` com Gemini 2.5 Flash — **funcionou comprovadamente** em todos os testes.
3. Script auto-detecta GEMINI_API_KEY do .env
4. Processar imagens:
   - Lotes de 3-10 imagens: paralelo via terminal(background)
   - Lotes de 10-200 imagens: `batch_vision.py` com 3 workers (recomendado)
5. Cada imagem leva ~15-30s (imagens de 250KB-900KB). 150 imagens ~30-40min com 3 workers.

## vision_analyze com auxiliary.vision configurado

Com `auxiliary.vision` configurado para um modelo com visão, o comando `vision_analyze()` funciona normalmente — o Hermes Gateway roteia automaticamente a imagem para o modelo de visão configurado.

**Nota (26/05/2026):** Kimi K2.5 foi testado e retornou 401 (chave inválida). O fallback Gemini 2.5 Flash (`gemini_vision.py`) foi validado com 153+ imagens processadas com sucesso.

## Dica: salvar análises como documentação

Após analisar prints de um sistema (ex: Dontus), salvar as descrições em arquivos markdown no projeto (ex: `docs/vision/CLINICA_EDIT_1_ANALYSIS.md`). Isso cria referência permanente para a equipe, evitando reprocessamento.

## Estratégia de Fallback — Playwright ao vivo quando visão falha

**Cenário:** Kimi K2.5 retorna 401 e Gemini 2.5 Flash não está disponível ou não atende.

**Estratégia comprovada (26/05/2026, Onda 4):** Em vez de travar processamento de imagens, {{BACKEND_ENGINEER}} pivotou para **navegação Playwright no site ao vivo** e extraiu **22 páginas de cadastros diretamente** — incluindo modais JS que prints não capturam.

### Quando usar cada abordagem

| Situação | Abordagem |
|----------|-----------|
| Imagens disponíveis, visão funcional | `batch_vision.py` (recomendado) |
| Imagens disponíveis, visão falhou | **Playwright — navegar site ao vivo** (não esperar) |
| Ambos funcionando | Processar imagens + Playwright em paralelo |
| Precisa de modais/sub-abas JS | **Playwright é superior** — clica em "Novo", navega abas |

### Como executar o Playwright fallback

1. Obter credenciais de acesso ({{COMMANDER}} pode autorizar direto)
2. Navegar Dontus com Playwright em modo leitura
3. Foco em: cadastros de 3-5 campos, modais "Novo", sub-abas condicionais
4. Salvar HTMLs e documentar resultados

**Testado:** 22 páginas extraídas em ~2h, incluindo Bandeira, CentroCusto, AnamnesePerguntas, Especialidade, FormaPagamento, etc.

## Auditoria de Cobertura Multi-Agente (Padrão Consolidado)

**Descoberta e validação (26/05/2026):** Ter 3 agentes auditarem independentemente a cobertura da engenharia reversa produz estimativas mais confiáveis e revela vieses.

### O Padrão

```
{{COMMANDER}} solicita auditoria final
  → {{ORCHESTRATOR}} delega para 3 agentes independentemente
  → Cada agente produz relatório com % de cobertura
  → {{ORCHESTRATOR}} consolida os 3 números + encontra a verdade
  → Se TODOS concordam (ex: "RE suficiente"), decisão é segura
```

### Agentes e seus papéis na auditoria

| Agente | Foco | Entregável |
|--------|------|-----------|
| **{{AUDITOR}}** | Dashboard consolidado — visão geral, % por módulo | `DASHBOARD-FINAL.md` |
| **{{BACKEND_ENGINEER}}** | Auditoria técnica — Playwright, extrações reais, lacunas | `RELATORIO-COBERTURA-FINAL.md` |
| **{{FRONTEND_ENGINEER}}** | Documentação e UI — vault, wikilinks, naming | `RELATORIO-EXECUTIVO.md` |

### Regras da consolidação

1. Cada agente produz **sem consultar os outros** — vieses independentes
2. {{ORCHESTRATOR}} **NÃO suaviza** os números — apresenta as 3 visões lado a lado
3. Se houver divergência >10% entre agentes, investigar a causa
4. A recomendação final leva em conta o **consenso**, não a média
5. Documentar explicitamente: "Agente X disse Y%, Agente Z disse W%"

### Exemplo real (26/05/2026, Dontus):
| Relator | Cobertura | Voto |
|---------|:---------:|:----:|
| {{AUDITOR}} | ~90% | RE suficiente |
| {{BACKEND_ENGINEER}} | ~85% | RE suficiente |
| {{FRONTEND_ENGINEER}} | ~75% funcional / ~90% UI | RE suficiente |
| **Consenso** | **85-90%** | **✅ Eng reversa suficiente para arquitetura** |

### Gatilho para auditoria multi-agente
- {{COMMANDER}} pede "auditoria final" ou "quão completo está?"
- Antes de decidir entre "RE suficiente" vs "mais 1 wave"
- Após processamento de lote grande de imagens (50+)
- Quando cobertura estimada passa de 80% (rendimentos decrescentes)

## Gestão de equipe durante processamento de imagens

**REGRA ABSOLUTA — validada por {{COMMANDER}} com correções em tempo real:**

Quando {{COMMANDER}} envia prints e menciona apenas {{ORCHESTRATOR}} ``:
- Outros agentes ({{BACKEND_ENGINEER}}, {{DEVOPS_ENGINEER}}, {{FRONTEND_ENGINEER}}, {{AUDITOR}}) devem ficar em **standby absoluto** — **NÃO RESPONDEM, NÃO COMENTAM, NÃO AGEM**
- Se algum agente responder sem ser mencionado, **{{COMMANDER}} corrige imediatamente** — e o erro deve ser reconhecido sem justificativas
- Apenas {{ORCHESTRATOR}} processa as imagens e consolida os resultados
- Ao final, {{ORCHESTRATOR}} pode delegar ações específicas mencionando os agentes com `<@USER_ID>`
- **Nem "ciente", nem "noted", nem "standby"** — o time só fala quando mencionado
- {{GIT_OPS}}: nunca responde a {{COMMANDER}} quando a mensagem é endereçada a {{ORCHESTRATOR}} — fica em standby silencioso

**Fluxo correto quando {{COMMANDER}} envia prints:**
1. {{COMMANDER}} envia imagens → menciona apenas {{ORCHESTRATOR}}
2. {{ORCHESTRATOR}} processa as imagens (silenciosamente)
3. {{ORCHESTRATOR}} apresenta resultados consolidados
4. {{ORCHESTRATOR}} pergunta a {{COMMANDER}} qual o próximo passo
5. Se {{COMMANDER}} autorizar, {{ORCHESTRATOR}} menciona agentes específicos para ações
