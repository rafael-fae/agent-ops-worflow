---
name: dontus-api-endpoints
description: Mapeamento completo dos endpoints da API do Dontus (sistema.dontus.com.br) — endpoints oficiais, alternativos descobertos, e estratégia para obter horários de agendamento que a API principal não retorna.
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Dontus API — Endpoints e Estratégias

## Contexto

O Dontus (SaaS odontológico ASP.NET MVC em `sistema.dontus.com.br`) expõe APIs JSON via `X-Requested-With: XMLHttpRequest` após login com CSRF. O `DontusClient` em `/var/www/dontus_app/dontus/client.py` implementa 5 endpoints principais, mas há outros descobertos via inspeção do JavaScript nas páginas HTML.

**Credenciais**: `config.yaml` em `/var/www/dontus_app/config.yaml`:
- `url_base`: `https://sistema.dontus.com.br`
- `id_dontus`: `{{DONTUS_CLINICA_ID}}`
- `usuario`: `{{COMMANDER}}`
- `id_clinica`: 1

## Problema Crítico: Horários Ausentes

A API `/Agendamento/GetAgendamentos` (usada pelo `get_agenda_dia()`) retorna `ScheduledTime: null` e `DataAtual: "0001-01-01T00:00:00"` para TODOS os agendamentos. Os horários NÃO estão nesse endpoint.

### Solução: `/Paciente/GetAgendamentosPaciente?id={ID_PACIENTE}`

**Endpoint GOLD** — retorna JSON com todos os agendamentos do paciente, INCLUINDO horários:

```
GET /Paciente/GetAgendamentosPaciente?id=346
Headers: X-Requested-With: XMLHttpRequest
```

**Campos relevantes no retorno:**
| Campo | Exemplo | Descrição |
|---|---|---|
| `DataAgendamento` | `"2026-05-21T18:00:00"` | Data e hora ISO 8601 |
| `Horario` | `"18:00"` | Horário separado (string) |
| `Funcionario.Nome` | `"Thaísa Stradiotti"` | Profissional vinculado |
| `DescricaoStatus` | `"AGENDADO"`, `"ATENDIDO"`, `"Confirmado"`, `"CANCELADO"` | Status do agendamento |
| `Tempo` | `60` | Duração em minutos |
| `Observacao` | `"Segunda sessão de raspagem..."` | Notas clínicas |
| `IDEspecialidade` | `11` | ID da especialidade |
| `Especialidade.Descricao` | `"PRÓTESE"` | Nome da especialidade |
| `CodigoConfirmacao` | UUID | Código de confirmação |
| `Color` | `"#3a87ad"` | Cor na agenda |

**Estratégia para obter agenda com horários:**
1. Chamar `GetAgendamentos` para obter lista do dia (com `IDPaciente`)
2. Para cada agendamento, chamar `GetAgendamentosPaciente?id={IDPaciente}`
3. Extrair horário do agendamento cujo `DataAgendamento` corresponde ao dia

**Nota**: `GetAgendamentosPaciente` também funciona via POST.

---

## Endpoints Mapeados

### Endpoints Oficiais (já no DontusClient)

| Método | Endpoint | Params |
|---|---|---|
| `get_pacientes()` | `/DiaPaciente/GetPacientes` | `idClinica` |
| `get_atendimentos(inicio, fim)` | `/DiaPaciente/GetAtendimentos` | `dataAbertura`, `dataFechamento`, `idClinica` |
| `get_pacientes_ausentes(dias)` | `/DiaPaciente/GetPacientesAusentes` | `idClinica`, `dias` |
| `get_agenda_dia(dia)` | `/Agendamento/GetAgendamentos` | `data` (YYYY-MM-DD) |
| `get_orcamentos(status)` | `/Orcamento/GetOrcamentos` | `idClinica`, `status` |

### Endpoints Implementados no Client (TASK-DONTUS-003 + CRUD)

| Endpoint | Método no client | Detalhes |
|---|---|---|
| `GET /Paciente/GetAgendamentosPaciente?id={ID}` | `get_agendamentos_paciente(id)` | **JSON puro** (Content-Type: `application/json`), array com `DataAgendamento` (ISO 8601), `Horario` (HH:MM), `Funcionario.Nome`, `DescricaoStatus`, `Tempo`. Cacheado por id. |
| `GET /Orto/GetPacientesOrto` | `get_pacientes_orto()` | JSON DataTables, 37 pacientes. |
| `POST /Paciente/Save` | `create_paciente(nome, cel)` | Payload mínimo: `{ID:0, Nome, Cel, IDClinica, Status:true}`. Retorna `{ID: int}`. Cadastro rápido sem AbrirLead(). |
| `POST /Agendamento/Save` | `create_agendamento(...)` | Payload: `{agendamento: {ID:0, IDPaciente, IDFuncionario, IDClinica, IDStatus, Tempo, DataAgendamento, Horario, Observacao, ...}}`. Ver estrutura completa no código. |
| `POST /Agendamento/Delete` | `delete_agendamento(id)` | Payload: `{id}`. Remove agendamento. |

**Pitfall — Status:** O Dontus só envia confirmação automática (SMS/WhatsApp) quando status = 1 (AGENDADO). Status 4 (Confirmado) **bloqueia** o envio. Use sempre 1 como padrão para novos agendamentos.

### Endpoints Descobertos (NÃO implementados no client)

| Endpoint | Descrição | Retorno |
|---|---|---|
| `/Paciente/GetAtendimentosPaciente?id={ID}` | Histórico de atendimentos | JSON (confirmado 200, ~10KB) |
| `/Paciente/GetTratamentosPaciente` | Tratamentos vinculados ao paciente | JSON (presente no JS da página) |
| `/Paciente/GetPagamentosPaciente` | Financeiro do paciente | JSON (presente no JS da página) |
| `/Relatorios/RelatorioAgendamento` | Relatório HTML de agenda | HTML (200, ~200KB) |
| `/Indicativo/IndicativoAgendamento` | Indicadores de agendamento | HTML (200, ~177KB) |
| `/CRCInteracao/GetHistoricoInteracoes` | Histórico CRC/WhatsApp | JSON (presente no JS da página) |
| `/Funcionario/GetFuncionarios` | Lista de profissionais | Retorna `{funcionarios: []}` vazio — usar nomes embedded nos agendamentos |

### Profissionais (mapeados via agendamentos)

| ID | Nome |
|---|---|
| 1 | {{COMMANDER}} Faé |
| 2 | Thaísa Stradiotti |

Confirmado em 21/05/2026 via cruzamento de `GetAgendamentos` com `GetAgendamentosPaciente`. Não há outros profissionais com agendamentos ativos. IDs extraídos do campo `IDFuncionario` nos JSONs de agendamento.
| `/Orto/Edit/{id}` | Página de edição ortodôntica | HTML |

### Status de Agendamento

| ID | DescricaoStatus |
|---|---|
| 1 | AGENDADO |
| 3 | CANCELADO |
| 4 | Confirmado |
| 6 | ATENDIDO |

---

## Metodologia de Exploração

### Como descobrir novos endpoints

1. **Usar o `DontusClient` existente** para fazer login e obter sessão autenticada
2. **Acessar páginas HTML** (ex: `/Paciente/Edit/346`, `/Orto`, `/Agendamento`) e extrair chamadas de API do JavaScript:
   ```python
   import re
   apis = re.findall(r'(?:url|action|href)\s*[:=]\s*[\"\\']([^\"\\']*(?:Get|List|Load|Search|Agenda)[^\"\\']*)[\"\\']', html, re.IGNORECASE)
   ```
3. **Testar endpoints** com `X-Requested-With: XMLHttpRequest` (obrigatório para APIs JSON)
4. **Tentar variações** de parâmetros (`id`, `ID`, `idPaciente`, `pacienteId`, `IDPaciente`)

### Pitfalls

- **Navegador**: Servidor OVH é headless (sem Chrome/Chromium). NÃO usar browser tools — usar HTTP direto via `httpx` + sessão do `DontusClient`.
- **Timeout**: O Dontus é lento. Usar `timeout 25`-`30` para comandos. Evitar múltiplas requisições em sequência longa.
- **Sessão**: O atributo é `_session` (privado), não `session`.
- **DataTables**: Alguns endpoints (ex: `/Orto/GetPacientesOrto`) usam formato DataTables (`{draw, iTotalRecords, iTotalDisplayRecords, data: [...]}`), não array puro.
- **`/Account/Login`**: Retorna 404. URL correta é `/Login`.
- **Funcionários**: O endpoint `GetFuncionarios` retorna vazio. Nomes de profissionais vêm embedded nos objetos de agendamento (`Funcionario.Nome`).

### Dependências para exploração

```bash
cd /var/www/dontus_app && uv run python3 -c "..."
```

O `uv run` garante que todas as dependências (`httpx`, `beautifulsoup4`, `xlrd`) estejam disponíveis.

---

## Mapa de Módulos do Dontus (PRD v2 — 25/05/2026)

Crawling exaustivo revelou **18 módulos, 132 páginas, ~25MB de HTML**. A lista de 7 endpoints descobertos é apenas a ponta do iceberg. O sistema completo:

```
 1. 📊 DIA — Dashboard / Home                   1 pag   229 KB
 2. 📅 AGENDAMENTO — Agenda                      1 pag   374 KB
 3. 👤 PACIENTE — Pacientes                      2 pag   303 KB
 4. 🏥 ATENDIMENTO — Fluxo de Atendimento         4 pag   831 KB
 5. 💰 FINANCEIRO — 17 submódulos                19 pag   3,8 MB
 6. 🧾 ORÇAMENTO — Orçamentos                    2 pag   456 KB
 7. 🐂 ORTO — Ortodontia                         1 pag   154 KB
 8. 💬 CRC — Comunicação                         3 pag   520 KB
 9. 📈 GRÁFICOS — 10 dashboards                  10 pag   1,7 MB
10. 📊 INDICATIVOS — 15 dashboards               15 pag   2,9 MB
11. 📋 RELATÓRIOS — 26 relatórios                26 pag   4,9 MB
12. 📢 MARKETING — Campanhas + SMS               4 pag   654 KB
13. 🛡️ SAC — Atendimento ao Consumidor           1 pag   260 KB
14. 🔐 AUDITORIA — Permissões + Auditoria        3 pag   520 KB
15. ⚙️ CONFIGURAÇÃO — Clínica + Usuários         6 pag   858 KB
16. 📦 CADASTROS — 30+ entidades                 31 pag   4,3 MB
17. 📄 DOCUMENTOS — Atestados/Contratos/etc      6 pag   903 KB
18. 🔄 OUTROS — Retorno, Metas, Mensagem         8 pag   1,1 MB
```

### Novos módulos não cobertos antes

| Módulo | Descoberto em | Páginas |
|---|---|---|
| Atendimento (Fila + Painel) | PRD v2 | 4 |
| Gráficos (10 dashboards) | PRD v2 | 10 |
| Marketing (Campanhas + SMS) | PRD v2 | 4 |
| SAC | PRD v2 | 1 |
| Auditoria + Permissões | PRD v2 | 3 |
| Documentos + Assinatura Eletrônica | PRD v2 | 6 |
| NFSe + DontusPay + Voucher | PRD v2 | 5 |

### Páginas de Edição (as mais densas)

| Página | Tamanho | Conteúdo |
|---|---|---|
| `/Paciente/Edit/{id}` | 1.6 MB | 22 formulários (dados pessoais, contato, endereço, documentos, anamnese, financeiro, odontograma, galeria, HOF, etc) |
| `/Orcamento/Edit/{id}` | 1.3 MB | Odontograma interativo, procedimentos por dente, laboratório, parcelamento |
| `/Orto/Edit/{id}` | 734 KB | Tratamento, mensalidades, recorrência, contas |

### Observação sobre o PRD "Bíblia"

O PRD v2 documenta o sistema em nível de páginas e tabelas, mas o {{COMMANDER}} exige **detalhamento campo-a-campo** (cada input, botão, regra). Veja a skill `prd-clone-exhaustivo` para a metodologia completa de documentação exaustiva.

---

## Recomendações para o Lirin

1. ~~**Adicionar ao `DontusClient`**: `get_agendamentos_paciente(id)` e `get_pacientes_orto()`~~ ✅ TASK-DONTUS-003
2. ~~**Comando `agenda`**: Cruzar `GetAgendamentos` + `GetAgendamentosPaciente` para exibir horários~~ ✅ TASK-DONTUS-003
3. **Endpoint composto**: Criar no `dontus_app` um endpoint que faz o loop internamente, reduzindo N+1 chamadas
4. **Cron de manhã**: Agenda do dia com horários + pacientes orto com consulta no dia
