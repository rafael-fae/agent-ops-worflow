---
name: dontus-mapeamento-modulos
title: Mapeamento de Módulos do Dontus
description: Procedimento genérico para mapear qualquer módulo do sistema Dontus (Relatórios, Gráficos, Indicativos, etc.), extrair estrutura completa (formulários, tabelas, botões, modais, JS objects, Knockout.js ViewModels, gráficos, KPIs) e salvar em formato padronizado para a Bíblia {{PROJECT_NAME}}.
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Mapeamento de Módulos do Dontus

## Gatilho
- Precisa mapear páginas de qualquer módulo do Dontus para documentar/clonar
- Fazer parte da força-tarefa de mapeamento exaustivo do Dontus (18 módulos, 132 páginas)
- Aplicável a: Relatorios, Graficos, Indicativos, Financeiro, Cadastros, Marketing, etc.

## Arquitetura Geral das Páginas

Todas as páginas do Dontus seguem um padrão consistente:
- **ASP.NET MVC** com layout compartilhado (tema padrão Dontus)
- **Knockout.js MVVM** — ViewModels via `ko.applyBindings`
- **14 modais compartilhados** em toda página: Notificações (4), WhatsApp (4), Detalhes dinâmicos (6)
- **Gráficos:** Chart.js (`<canvas id="chart">`), com tipo configurado dinamicamente no JS
- **Selects são populados dinamicamente** via AJAX (Knockout.js) — HTML estático não tem `<option>` preenchidas

## Procedimento

### 1. Descoberta de Rotas por Módulo

Use o menu principal para descobrir TODAS as rotas de um módulo específico. Varie o filtro por padrão de URL:

```bash
cd /var/www/dontus_app && uv run python3 << 'EOF'
import sys; sys.path.insert(0, '/var/www/dontus_app')
from dontus.client import DontusClient
from bs4 import BeautifulSoup
client = DontusClient('https://sistema.dontus.com.br', '{{DONTUS_CLINICA_ID}}', '{{COMMANDER}}', '{{DONTUS_PASSWORD}}', 1)
client.login()
r = client._session.get('https://sistema.dontus.com.br/', timeout=30)
soup = BeautifulSoup(r.text, 'html.parser')

# Filtro: mude para 'grafico', 'indicativo', 'relatorio', 'financeiro', etc.
for a in soup.find_all('a', href=True):
    href = a['href']
    txt = a.get_text().strip()
    if 'indicativo' in href.lower() or 'Indicativo' in href:
        print(f'{txt:35s} -> {href}')
EOF
```

### 2. Extração HTML Estruturada (Página Única)

Use o script base `{{COMMANDER_HOME}}/hermes-roshar/projetos/{{PROJECT_SLUG}}/scripts/extract_page.py`:
```bash
cd /var/www/dontus_app && uv run python3 {{COMMANDER_HOME}}/hermes-roshar/projetos/{{PROJECT_SLUG}}/scripts/extract_page.py /Graficos/GraficoContasPagas
```

### 3. Extração em Lote (Recomendado para módulos com 5+ páginas)

Para módulos com múltiplas páginas (ex: 10 Gráficos, 15 Indicativos, 26 Relatórios), crie um script de extração em lote que:

1. **Autentica** uma vez via DontusClient
2. **Itera** sobre todas as rotas do módulo
3. **Extrai para cada página:**
   - Cabeçalhos (h1-h4) e título
   - Formulários com campos (labels, inputs, selects, textareas, buttons)
   - Tabelas com colunas
   - Botões de ação
   - **Modais** (título, botões, campos)
   - **JS Objects** (`var src`, `var usuario`, `var clinica`, `var profissionalId`, ViewModel)
   - **Filtros** (inputs de data, selects de filtro)
   - **Gráficos** (canvas Chart.js, outros motores) — se aplicável
   - **KPIs** (indicadores numéricos) — se aplicável
   - **Regras de negócio** (heurísticas por padrão de URL)
   - **Links de navegação** da página
   - Observações (tecnologias detectadas)
4. **Salva** cada página como `PREFIX_Nome.txt`
5. **Gera** `PREFIX_SUMMARY.json` com metadados consolidados

Template do script em lote: `/tmp/extract_all_graficos_indicativos.py` (executado em 26/05/2026) — adaptar o array de rotas e prefixo.

### 4. Detectando Tipos de Gráfico

Para páginas de gráficos/indicativos com Chart.js:
```python
# Procurar por canvas (Chart.js)
canvases = soup.find_all('canvas')
for c in canvases:
    cid = c.get('id', '')
    if cid:
        graph_types.append(f"Canvas#{cid}")

# Procurar por new Chart() no JavaScript
scripts = soup.find_all('script')
for scr in scripts:
    if scr.string and 'new Chart' in scr.string:
        chart_names = re.findall(r"new\s+Chart\s*\(\s*document\.getElementById\s*\(\s*['\"]([^'\"]+)['\"]", scr.string)
        chart_types = re.findall(r"type\s*:\s*['\"](bar|line|pie|doughnut|radar|polarArea|bubble|scatter)['\"]", scr.string, re.I)
```

### 5. Extraindo KPIs (Indicativos)

Para páginas de indicativos, extrair métricas-chave:
```python
# Procurar por elementos com classes de KPI
for el in soup.find_all(class_=lambda c: c and any(k in (c.lower() if c else '') 
    for k in ['kpi', 'indicador', 'metrica', 'metric', 'stat', 'numero', 'valor', 'total', 'card']) if c else False):
    txt = el.get_text().strip()
    if txt and len(txt) < 100:
        kpis.append(txt[:80])

# Procurar por padrões de KPI no texto
kpi_patterns = re.findall(r'(?:Total|Média|Média\s*de|Soma|Quantidade|Percentual|Taxa|Índice)[^<]{0,100}', html_text)
```

### 6. Extração Knockout.js ViewModel

Extrair observables e funções do JS inline:
```python
patterns = {
    'var src': r'var\s+src\s*=\s*({[^;]+})',
    'var usuario': r'var\s+usuario\s*=\s*({[^;]+})',
    'var clinica': r'var\s+clinica\s*=\s*({[^;]+})',
    'var profissionalId': r'var\s+profissionalId\s*=\s*([^;]+)',
    'var idClinica': r'var\s+idClinica\s*=\s*([^;]+)',
    'viewModel': r'(?:self\.|this\.|viewModel\s*=)\s*ko\.observable',
}
```

## Rotas Conhecidas

### Gráficos (10) — prefixo GRAF
```
/Graficos/GraficoContasPagas
/Graficos/GraficoContasRecebidas
/Graficos/GraficoDesistencia
/Graficos/GraficoDocumentacao
/Graficos/GraficoEstoque
/Graficos/GraficoFluxoCaixa
/Graficos/GraficoIndicacao
/Graficos/GraficoOrcamento
/Graficos/GraficoOrigem
/Graficos/GraficoProdutividade
```

### Indicativos (15) — prefixo IND
```
/Indicativo/IndicativoAgendamento
/Indicativo/IndicativoAtendimentoRepeticao
/Indicativo/IndicativoClinica
/Indicativo/IndicativoComparativo
/Indicativo/IndicativoFluxoPaciente
/Indicativo/IndicativoLaboratorio
/Indicativo/IndicativoLIA
/Indicativo/IndicativoMarketing
/Indicativo/IndicativoOrigem
/Indicativo/IndicativoOrto
/Indicativo/IndicativoProcedimento
/Indicativo/IndicativoProfissisonal   # URL original tem typo "Profissisonal"
/Indicativo/IndicativoSMS
/Indicativo/IndicativoTicketMedio
/Indicativo/IndicativoVoucher
```

### Relatórios (26) — prefixo REL
```
/Relatorios/RelatorioAcrescimo
/Relatorios/RelatorioAgendamento
/Relatorios/RelatorioAniversariantes
/Relatorios/RelatorioAtendimento
/Relatorios/RelatorioCaixaDiario
/Relatorios/RelatorioCheque
/Relatorios/RelatorioContaAPagar
/Relatorios/RelatorioContasReceber
/Relatorios/RelatorioContaPaga
/Relatorios/RelatorioContasRecebidas
/Relatorios/RelatorioDesistencia
/Relatorios/RelatorioDocumentacao
/Relatorios/RelatorioEstoque
/Relatorios/RelatorioIndicacao
/Relatorios/RelatorioLaboratorio
/Relatorios/RelatorioOrcamento
/Relatorios/RelatorioOrcamentoProfissional
/Relatorios/RelatorioOrtoNaoPagantes
/Relatorios/RelatorioPacientes
/Relatorios/RelatorioPacientesAusentes
/Relatorios/RelatorioPreAgendamento
/Relatorios/RelatorioProdutividade
/Relatorios/RelatorioServico
/Relatorios/RelatorioSMS
/Relatorios/RelatorioTransferenciaFicha
/Relatorios/RelatorioVendas
```

## Caso Especial: Dashboard (Root URL `/`)

O Dashboard/Home (`GET /`) **não segue** o padrão dos demais módulos. Tem arquitetura única:

### Diferenças Estruturais
- **ViewModel:** `ScreenModel` (não um ViewModel de módulo específico)
- **Objeto `var src`:** 65+ chaves com KPIs consolidados do dia (QtdContasAVencer, QtdLancamentosFuturos, QtdRetornoPendente, etc.)
- **Visibilidade condicional:** 16 flags booleanas `Visible*` controlam quais widgets aparecem (ex: `VisibleValores`, `VisibleFilaEspera`, `VisibleMeta`, `VisiblePesquisas`)
- **Sem gráficos Chart.js** — zero instâncias de `new Chart()`
- **261 bindings KO** — a página mais densa em bindings do sistema inteiro
- **18 widgets visuais** — cards numéricos, tabelas em tempo real, filas, métricas

### KPIs Específicos do Dashboard
| Chave | Tipo | Descrição |
|-------|------|-----------|
| `ContasRecebidas` | num | Valor recebido hoje |
| `ContasPagas` | num | Valor pago hoje |
| `QtdAgendamentos` | num | Agendamentos (amanhã / período) |
| `QtdRetornoPendente` | num | Retornos pendentes |
| `QtdLancamentosFuturos` | num | Lançamentos futuros para baixar |
| `QtdPesquisasNaoVisualizadas` | num | Pesquisas de satisfação pendentes |
| `QtdAniversariantes` | num | Aniversariantes do mês |
| `SaldoWhatsApp` / `SaldoSMS` | num | Saldo de créditos de mensageria |
| `PorcentagemHD` | num | Espaço utilizado em disco |
| `QtdProtesesAndamento/Atrasadas/AEntregar` | num | Gestão de laboratório |

### Menu Principal — 143 Links
O Dashboard é a única página que contém **todo o menu de navegação** do sistema. Use-a para descobrir TODAS as rotas:
```python
for a in soup.find_all('a', href=True):
    href = a['href']
    txt = a.get_text().strip()
    if href and txt and not href.startswith('#') and not href.startswith('javascript'):
        print(f'{txt:40s} -> {href}')
```

### Extração Recomendada do Objeto src
```python
import json, re
scripts = soup.find_all('script')
for scr in scripts:
    if scr.string:
        match = re.search(r'var\s+src\s*=\s*(\{[^;]+\})', scr.string, re.DOTALL)
        if match:
            try:
                src_obj = json.loads(match.group(1))
                json.dump(src_obj, open('DASHBOARD_src.json', 'w'), indent=2)
            except:
                pass
```

## Estrutura de Saída

```
{{COMMANDER_HOME}}/hermes-roshar/projetos/{{PROJECT_SLUG}}/biblia/{modulo}/
├── PREFIX_NomePagina.txt          # Extração detalhada (~3-10KB cada)
└── PREFIX_SUMMARY.json            # Resumo consolidado com metadados
```

Cada arquivo .txt segue este template:
```
## TÍTULO: {page title}
## URL: {full URL}
## Tamanho: {N} bytes | HTTP {status}
## Cabeçalhos: {N}

## Formulários: {N}
  Form #{idx}: action='{action}' method={method} ({campos} campos)
    [LABEL] ...
    [INPUT] type=text name=...
    [SELECT] name=... options=[...]
    [BOTAO] ... | class=...

## Tabelas: {N}
  Tabela #{idx}: {N} colunas, ~{N} linhas
    - Coluna 1
    - Coluna 2

## Botões: {N}
## Modais: {N}
## JS Objects: {N}
## Filtros: {N}
## Gráficos: {N}   (se módulo de gráficos)
## KPIs: {N}       (se módulo de indicativos)
## Regras de Negócio
## Links de Navegação
## Observações
```

## Pitfalls
- **NUNCA usar `execute_code` para código que importa do dontus_app** — o sandbox do Hermes não tem acesso ao virtualenv do uv. Sempre escrever script em arquivo `.py` e executar com `uv run python3 /path/to/script.py`.
- **Sempre usar `uv run`** — o projeto usa uv como gerenciador de pacotes (nunca `python3` direto, nunca `.venv/bin/activate`)
- **Selects vazios no HTML** — são populados via AJAX (Knockout.js observableArray + ko.mapping.fromJS)
- **Tabelas de resultado** são DataTables server-side (AJAX) — estrutura não está no HTML inicial
- **14 modais compartilhados** em toda página: 4 de Notificações, 4 de WhatsApp, 6 de Detalhes — filtrar por ID para focar nos modais específicos do módulo
- **Timeout Dontus**: usar `timeout=45` para requests, o sistema é lento
- **Sessão**: usar `client._session` (privado) — não `client.session`
- **Login**: URL correta é `/Login`, não `/Account/Login`
- **Credenciais**: hardcoded no script por enquanto (senha em texto claro) — `{{DONTUS_PASSWORD}}`
- **Página mais complexa**: LIA (266KB, 41 cabeçalhos, 5 tabelas, 42 modais, 15 KPIs)
- **Dashboard NÃO tem Chart.js** — zero gráficos. É a única página do sistema sem `new Chart()`.

## Verificação de Completeza (Inspeção Final)

Use esta checklist quando for verificar se um mapeamento está 100% completo:

- [ ] Rotas descobertas via crawling do menu principal (não assumir lista fixa)
- [ ] Cada rota retornou HTTP 200
- [ ] Cada rota tem seu arquivo `PREFIX_Nome.txt` individual (~3-10KB)
- [ ] `PREFIX_SUMMARY.json` criado com metadados (total, processadas, data, array de rotas)
- [ ] Knockout.js ViewModel extraído (var src, var usuario, ko.applyBindings)
- [ ] Gráficos Chart.js / canvas detectados (se aplicável)
- [ ] KPIs extraídos (se aplicável)
- [ ] Modais compartilhados identificados vs modais específicos do módulo

### Checklist de Gap Analysis (Força-Tarefa Completa)
- [ ] **Contar arquivos por diretório** — `find {dir} -type f | wc -l` versus o esperado
- [ ] **Cruzar módulos conhecidos** — comparar lista de 18 módulos do Dontus contra diretórios existentes
- [ ] **Verificar diretório raiz** — `/` (Dashboard) é facilmente esquecido; verificar se foi capturado
- [ ] **Verificar agentes** — conferir output de cada agente ({{FRONTEND_ENGINEER}} mapping, {{DEVOPS_ENGINEER}} mapping, {{BACKEND_ENGINEER}} biblia)
- [ ] **Verificar pacientes** — 3 pacientes × 22 abas = 66 arquivos mínimos
- [ ] **Cross-check com sumários** — `summary.json`, `summary_final.json` devem refletir o que foi capturado
