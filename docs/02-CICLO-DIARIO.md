# Guia do Ciclo Diário — Agent Ops Workflow

> Guia completo das 6 fases do ciclo diário de planejamento e execução.
> Este é o coração do workflow — o ritmo que mantém sua equipe multi-agente
> coordenada, auditada e produzindo todos os dias.

---

## Sumário

1. [Visão Geral](#visão-geral)
2. [Diagrama de Fluxo ASCII](#diagrama-de-fluxo-ascii)
3. [Fase 1: PLANEJAR](#fase-1-planejar)
4. [Fase 2: APROVAR](#fase-2-aprovar)
5. [Fase 3: DELEGAR](#fase-3-delegar)
6. [Fase 4: EXECUTAR](#fase-4-executar)
7. [Fase 5: AUDITAR](#fase-5-auditar)
8. [Fase 6: REPORTAR](#fase-6-reportar)
9. [Exemplo Completo de um Dia — Time Nova](#exemplo-completo-de-um-dia--time-nova)
10. [Regras de Thread](#regras-de-thread)
11. [Procedimentos de Recuperação de Erros](#procedimentos-de-recuperação-de-erros)
12. [Template de Relatório Diário](#template-de-relatório-diário)

---

## Visão Geral

O Agent Ops Workflow segue um ciclo estrito de 6 fases que se repete a cada
dia útil. Cada fase tem um dono claro, uma saída definida e uma etapa de
verificação antes da próxima fase começar.

**A regra de ouro:** Nunca pule fases. Nunca comece uma fase a menos que a
anterior esteja completa e verificada. Planeje antes de aprovar, aprove antes
de delegar, delegue antes de executar, execute antes de auditar, audite antes
de reportar.

### Atores

| Função | Quem | Responsabilidade |
|--------|------|------------------|
| Comandante | Humano (líder do time, product owner) | Revisa plano, dá sinal verde final |
| Orquestrador | Agente líder (perfil Hermes) | Cria plano, delega, audita, reporta |
| Agente | Qualquer agente Hermes com tarefa atribuída | Executa tarefa designada, reporta de volta |
| Auditor | Agente designado para verificação cruzada | Verifica trabalho, checa commits, aprova |

Em equipes pequenas, o orquestrador e o auditor podem ser o mesmo agente em
diferentes pontos do ciclo. Em equipes maiores, são funções separadas.

---

## Diagrama de Fluxo ASCII

```
                                  ┌──────────────┐
                                  │  COMANDANTE  │
                                  │  (HUMANO)    │
                                  └──────┬───────┘
                                         │
                                    ╔════╧════╗
                                    ║ FASE 1  ║
                                    ║ PLANEJAR║
                                    ╚════╤════╝
                                         │
                                         ▼
                                    ╔════╧════╗
                                    ║ FASE 2  ║
                                    ║ APROVAR ║
                                    ╚════╤════╝
                                         │
                                    ╔════╧════╗
                                    ║ FASE 3  ║
                                    ║ DELEGAR ║
                                    ╚════╤════╝
                                         │
                           ┌─────────────┼──────────────┐
                           │             │              │
                           ▼             ▼              ▼
                     ┌──────────┐ ┌──────────┐  ┌──────────┐
                     │ AGENTE A │ │ AGENTE B │  │ AGENTE C │
                     │(EXECUTAR)│ │(EXECUTAR)│  │(EXECUTAR)│
                     └────┬─────┘ └────┬─────┘  └────┬─────┘
                          │            │              │
                          └────────────┼──────────────┘
                                       ▼
                                  ╔════╧════╗
                                  ║ FASE 5  ║
                                  ║ AUDITAR ║  ← Verificação por agente diferente
                                  ╚════╤════╝
                                       │
                                  ╔════╧════╗
                                  ║ FASE 6  ║
                                  ║ REPORTAR║
                                  ╚════╤════╝
                                       │
                                       ▼
                              ┌─────────────────┐
                              │   PRÓXIMO DIA   │
                              │  (volta à F1)   │
                              └─────────────────┘
```

### O Que Flui Entre as Fases

```
FASE 1 ──→ PLANO.md + arquivos task_XX.md + entradas INDICE.md
FASE 2 ──→ plano_aprovado (aprovação verbal no Slack)
FASE 3 ──→ thread Slack por tarefa com @menção + instruções
FASE 4 ──→ checkboxes preenchidos + seção Conclusao + hash do commit
FASE 5 ──→ INDICE.md + PLANO.md atualizados com selos de auditoria
FASE 6 ──→ tabela consolidada + mensagem de relatório + commit git
```

---

## Fase 1: PLANEJAR

**Dono:** Orquestrador (agente Hermes)
**Entrada:** Relatório do dia anterior, prioridades de hoje (do Comandante)
**Saída:** `PLANO.md`, arquivos `task_XX.md`, `INDICE.md` atualizado

### O que o Orquestrador Faz

1. **Lê o relatório do dia anterior.** Verifica o que foi concluído, o que
   ficou pendente e o que o Comandante sinalizou para acompanhamento.

2. **Revisa o INDICE.md.** O índice mostra o estado atual de todas as tarefas
   de todos os dias. É o ponto de partida para o plano de hoje.

3. **Determina as waves de hoje.** Um dia típico tem 3 waves (manhã, tarde,
   noite), mas você pode ter mais ou menos dependendo da capacidade da sua
   equipe e da complexidade do trabalho.

4. **Define tarefas para cada wave.** Cada tarefa deve ter:
   - Uma descrição clara e testável
   - Um agente designado (ex.: `nova-dev`)
   - Um motor designado (ex.: `Gemini CLI`)
   - Uma prioridade (🔴 alta / 🟡 média / 🟢 baixa)
   - Dependências (quais tarefas devem vir primeiro)

5. **Cria o arquivo PLANO.md** para o dia em
   `planejamento-diario/YYYY-MM-DD/PLANO.md`.

6. **Cria arquivos de tarefa individuais** (`task_01.md`, `task_02.md`, etc.)
   usando o template TASK.md. Cada arquivo contém:
   - Leitura obrigatória (links, docs, referências)
   - Contexto explicando por que a tarefa existe
   - Instruções detalhadas e numeradas
   - Um checklist de itens binários (feito/não feito)
   - Restrições (motor obrigatório, arquivos proibidos)
   - Uma seção de Conclusão (a ser preenchida pelo agente depois)

7. **Atualiza o INDICE.md** com as tarefas do novo dia. Adiciona uma nova
   seção em `## DD/MM/YYYY — X/Y` listando todas as tarefas com status ⬜.

### A Estrutura do PLANO.md

```
# Plano Diário — Nome do Projeto

**Criado por:** Orquestrador / Time Nova
**Data:** DD/MM/YYYY
**Propósito:** [Breve resumo do dia]

---

## Recursos

| Recurso  | Localização      | Propósito |
|----------|------------------|-----------|
| Repo     | ~/projeto        | Código    |

---

## Resumo

[2-3 frases sobre os objetivos do dia]

---

## Waves

### Wave 1 — Manhã 🔴

| Tarefa  | Descrição         | Agente   | Motor  | Prioridade | Status |
|:-------:|-------------------|----------|--------|:----------:|:------:|
| task_01 | Corrigir bug login| nova-dev | Gemini | 🔴         | ⬜     |

**Objetivo:** Todas as tarefas da manhã concluídas.

---

### Wave 2 — Tarde 🟡

---

## Dependências

```
Wave 1 (Manhã)
  task_01 → task_02

Wave 2 (Tarde)
  task_03 depende de task_01
```

---

## Regras de Execução

1. **Motor padrão:** Gemini CLI
2. ...
```

### Dicas de Planejamento

- **Uma tarefa = uma responsabilidade.** Se uma tarefa tem múltiplas saídas
  não relacionadas, divida-a em tarefas separadas.
- **Marque dependências claramente.** Se task_03 precisa que task_01 seja
  feita primeiro, diga isso na seção de Dependências e no cabeçalho da task_03.
- **Waves paralelas são permitidas.** A Wave 2 pode começar assim que as
  tarefas bloqueantes da Wave 1 forem concluídas, mesmo que a Wave 1 tenha
  tarefas não bloqueantes não iniciadas.
- **Nunca planeje mais do que a equipe pode executar.** Uma boa regra é
  2-3 tarefas por wave, 3 waves por dia = 6-9 tarefas no máximo.

---

## Fase 2: APROVAR

**Dono:** Comandante (humano)
**Entrada:** `PLANO.md` compartilhado no Slack (ou revisado via arquivo)
**Saída:** Aprovação verbal (ou rejeição com comentários)

### O que o Comandante Faz

1. **Lê o PLANO.md.** Revisa cada tarefa, sua descrição, seu agente
   designado, seu motor e sua prioridade.

2. **Verifica dependências.** Estão precisas? Tarefas bloqueadas vão
   atrasar o dia?

3. **Verifica atribuições de motor.** O modelo certo está atribuído a cada
   tarefa? O padrão é Gemini 3.1 Pro para todas as tarefas de código, mas
   algumas podem precisar de Opus 4.7 (UI/design, auditorias complexas) ou
   outro motor.

4. **Aprova ou rejeita.** Envie uma mensagem no canal de operações:

```
✅ Plano aprovado. Pode prosseguir com a delegação.
```

Ou, se mudanças forem necessárias:

```
⚠️ Plano precisa de revisão: task_03 deve usar Opus, não Gemini.
   A prioridade da task_05 deve ser 🟢, não 🟡. Corrija e reenvie.
```

### A Regra de Ouro da Aprovação

**Nunca implemente sem o sinal verde.** A Fase 3 não deve começar até que
a Fase 2 esteja completa. Se o orquestrador começar a delegar antes da
aprovação, é uma violação de protocolo.

### O que Acontece Durante a Rejeição

1. O orquestrador revisa o plano conforme os comentários do Comandante
2. O orquestrador publica o `PLANO.md` atualizado ou um diff
3. O Comandante re-revisa e aprova
4. Só então a Fase 3 começa

---

## Fase 3: DELEGAR

**Dono:** Orquestrador
**Entrada:** `PLANO.md` aprovado
**Saída:** Uma thread Slack por tarefa com @menção + instruções

### O que o Orquestrador Faz

1. **Abre o canal de operações** (ex.: `#agent-ops-nova`).

2. **Para cada tarefa, cria uma mensagem de nível superior** (não uma
   resposta em thread) com:
   - A @menção do agente no início da mensagem
   - O ID e título da tarefa
   - Um breve resumo da tarefa
   - A obrigação do motor (qual modelo usar)
   - Quaisquer restrições críticas
   - Um link para o arquivo da tarefa ou uma cópia das instruções principais

3. **Cada tarefa tem sua PRÓPRIA mensagem de nível superior** — nunca
   combine múltiplas tarefas em uma mensagem. Isso cria threads separadas
   automaticamente.

4. **Aguarda confirmação.** O agente mencionado deve responder com
   "Recebido" ou começar a trabalhar. Se não houver resposta em um tempo
   razoável, verifique a conectividade do agente.

### Template de Mensagem de Delegação

```
<@U0123456789> Tarefa task_01: Corrigir bug de redirecionamento de login

**Motor:** Gemini 3.1 Pro (PADRÃO — use este)
**Prioridade:** 🔴 ALTA — bloqueia task_02
**Arquivo:** planejamento-diario/YYYY-MM-DD/task_01.md

**Resumo:**
O redirecionamento de login está enviando usuários para /dashboard em vez de
/home após a autenticação. Corrija a lógica de redirecionamento no
controller de autenticação.

**Lembrete de checklist:**
- Verificar correção em staging antes de reportar
- Preencher a seção de Conclusão em task_01.md
- Commitar e dar push antes de reportar de volta

**Restrições:**
- NÃO modifique arquivos de migração de banco de dados
- NÃO altere o middleware de autenticação
- Mexa apenas na constante de URL de redirecionamento
```

### Formato de Obrigação de Motor

Toda mensagem de delegação DEVE incluir uma diretiva clara de motor. Use um
destes formatos:

```
**Motor:** Gemini 3.1 Pro (PADRÃO)
**Motor:** Opus 4.7 (OBRIGATÓRIO — tarefa de UI/visão)
**Motor:** OpenCode Go (apenas exploração)
**Motor:** DeepSeek V4 Pro (PROIBIDO sem ordem do Comandante)
```

O prefixo "ORDEM ABSOLUTA" é usado para atribuições de motor inegociáveis:

```
**ORDEM ABSOLUTA — Motor:** Gemini 3.1 Pro.
NÃO troque. Se atingir limites de taxa, divida em subtarefas.
```

---

## Fase 4: EXECUTAR

**Dono:** Cada agente designado
**Entrada:** Mensagem de delegação no Slack + arquivo `task_XX.md`
**Saída:** Tarefa concluída com checklist preenchido, seção de Conclusão, commit

### O que o Agente Faz

1. **Confirma a tarefa** respondendo na thread:
   ```
   Recebido. Iniciando task_01 agora.
   ```

2. **Lê o arquivo da tarefa.** Abra `planejamento-diario/YYYY-MM-DD/task_XX.md`
   e leia as seções de Leitura Obrigatória, Contexto, Instruções, Checklist e
   Restrições.

3. **Lê os documentos referenciados.** Se a tarefa exigir leitura de um PRD,
   blueprint ou doc de API, leia-os primeiro. Não comece a codificar antes de
   entender o contexto.

4. **Executa as instruções passo a passo.** Marque checkboxes conforme avança:
   ```
   - [x] Identificou a constante de redirecionamento no controller de auth
   - [x] Alterou a URL de redirecionamento de /dashboard para /home
   - [x] Testou em ambiente de staging
   - [x] Verificou que não há efeitos colaterais em outras rotas
   ```

5. **Preenche a seção de Conclusão** no arquivo da tarefa:
   ```markdown
   ## Conclusao

   **Agente:** nova-dev
   **Concluído em:** DD/MM/YYYY HH:MM
   **Motor usado:** Gemini 3.1 Pro
   **Hash do commit:** abc1234def5678
   **Observações:**
   Corrigida a constante de URL de redirecionamento em AuthController.php.
   O bug era um resíduo da refatoração de roteamento do sprint anterior.
   Todos os testes passam (47/47). Nenhum efeito colateral detectado.
   ```

6. **Commits e push:**
   ```bash
   git add -A
   git commit -m "fix: corrige redirecionamento de login para /home"
   git push
   ```

7. **Reporta de volta na thread do Slack:**
   ```
   ✅ Task_01 concluída.
   Commit: abc1234def5678
   Testes: 47/47 passando
   Observações: Corrigida URL de redirecionamento em AuthController.php.
   Pronto para auditoria.
   ```

### Regras de Execução

- **Sempre commit antes de reportar.** Uma tarefa sem hash de commit não está
  concluída. Se não houver nada para commit (ex.: tarefa de pesquisa), note
  isso explicitamente.
- **Um agente por tarefa.** Se você não é o agente designado, não toque na
  tarefa.
- **Conformidade com motor é obrigatória.** Não troque de motor a menos que o
  Comandante autorize explicitamente.
- **Divida se emperrar.** Se atingir limites de taxa do motor (ex.:
  RESOURCE_EXHAUSTED), divida a tarefa em subtarefas menores em vez de trocar
  de modelo. Se ainda falhar após dividir, pare e reporte ao orquestrador.
- **Não tome ação corretiva sem aprovação.** Se você cometer um erro, reporte
  e espere. Não reverta, delete ou corrija sem o sinal verde do Comandante.

---

## Fase 5: AUDITAR

**Dono:** Orquestrador (ou agente auditor designado)
**Entrada:** Relatório de conclusão do agente (thread Slack + commit)
**Saída:** Status de tarefa verificado no `INDICE.md` + `PLANO.md`

### O que o Auditor Faz

1. **Verifica o commit.** Confirme se o hash do commit existe:
   ```bash
   git log --oneline -5
   git show abc1234 --stat
   ```

2. **Revisa as alterações.** Leia o diff para verificar se o trabalho está correto:
   ```bash
   git diff abc1234^..abc1234
   ```

3. **Lê o arquivo da tarefa.** Abra o `task_XX.md` concluído e verifique:
   - Todos os checkboxes estão preenchidos? (Nenhum [ ] deixado sem marcar)
   - A seção de Conclusão está preenchida com observações significativas?
   - As restrições foram respeitadas? (Nenhum arquivo proibido foi tocado)

4. **Verifica os itens do checklist** inspecionando o código/arquivos reais.

5. **Se aprovado:**

   a. Atualiza `PLANO.md` — marca o status da tarefa como ✅
   b. Atualiza `INDICE.md` — marca ✅ e 👁, adiciona o hash do commit
   c. Responde na thread do Slack:
      ```
      ✅ Auditoria aprovada para task_01.
      Commit abc1234 verificado. Todos os checkboxes preenchidos.
      Restrições respeitadas. INDICE.md atualizado.
      ```

6. **Se rejeitado:**

   a. Responde na thread do Slack com problemas específicos:
      ```
      ⚠️ Auditoria reprovada para task_01:
      - Item #3 do checklist (teste em staging) não preenchido
      - Hash do commit ausente na seção de Conclusão
      Por favor, corrija e reenvie.
      ```
   b. O agente corrige os problemas e publica novamente
   c. Re-auditoria acontece na mesma thread (sem novas threads)

### Checklist de Auditoria

```
[ ] Hash do commit existe e é válido (git log --oneline)
[ ] Diff está correto e completo
[ ] Todos os checkboxes no arquivo da tarefa estão preenchidos ([x])
[ ] Seção de Conclusão tem conteúdo significativo
[ ] Restrições foram respeitadas
[ ] Nenhum arquivo proibido foi modificado
[ ] Arquivo da tarefa foi commitado (não apenas o código)
```

---

## Fase 6: REPORTAR

**Dono:** Orquestrador
**Entrada:** Todas as tarefas auditadas
**Saída:** Relatório consolidado + commit git

### O que o Orquestrador Faz

1. **Compila resultados de todas as tarefas.** Para cada tarefa:
   - ID e descrição da tarefa
   - Status (✅ / ⚠️ / ❌)
   - Hash do commit
   - Observações principais

2. **Publica um relatório consolidado** no canal de operações:

```
📊 Relatório Diário — Time Nova — DD/MM/YYYY

| Tarefa   | Descrição             | Status | Commit    |
|----------|-----------------------|--------|-----------|
| task_01  | Corrigir redirect login| ✅     | abc1234   |
| task_02  | Atualizar docs API    | ✅     | def5678   |
| task_03  | Refatorar módulo auth | ⚠️     | ghi9012   |
| task_04  | Adicionar testes unit | ❌     | —         |

**Resumo:** 2/4 tarefas concluídas. 1 auditada. 1 falhou (veja thread).
**Pendente:** task_04 bloqueada por dependência upstream.
**Próximos passos:** Reavaliar task_04 no plano de amanhã.
```

3. **Atualiza o INDICE.md** com os contadores finais X/Y e seção de progresso.

4. **Commits tudo:**
   ```bash
   git add -A
   git commit -m "daily: relatório para DD/MM/YYYY — X/Y tarefas concluídas"
   git push
   ```

5. **Prepara handoff para o próximo dia.** Documente quaisquer itens
   pendentes e bloqueadores na mensagem do relatório para que o plano do
   próximo dia comece com contexto completo.

---

## Exemplo Completo de um Dia — Time Nova

Vamos percorrer um dia completo para o Time Nova usando um projeto
fictício chamado "Projeto Atlas."

### Cenário

- **Projeto:** Atlas — Um dashboard de microsserviços
- **Equipe:** Time Nova (Comandante: Sarah, Orquestrador: @nova-orch, Agentes:
  @nova-dev, @nova-audit)
- **Data:** 2026-06-10

### Fase 1: PLANEJAR (08:00)

@nova-orch cria o plano com base no relatório de ontem. Ontem tinha 3 itens
pendentes: um bug de login, uma migração de API incompleta e uma lacuna de
documentação.

```
# Plano Diário — Projeto Atlas

**Criado por:** nova-orch / Time Nova
**Data:** 10/06/2026
**Propósito:** Resolver bug de redirecionamento de login, finalizar migração API, corrigir docs

## Waves

### Wave 1 — Manhã 🔴

| Tarefa   | Descrição                         | Agente    | Motor   | Prio | Status |
|----------|-----------------------------------|-----------|---------|:----:|:------:|
| task_01  | Corrigir bug de redirect login    | nova-dev  | Gemini  | 🔴   | ⬜     |
| task_02  | Completar migração API v2         | nova-dev  | Gemini  | 🔴   | ⬜     |

### Wave 2 — Tarde 🟡

| Tarefa   | Descrição                        | Agente      | Motor | Prio | Status |
|----------|----------------------------------|-------------|-------|:----:|:------:|
| task_03  | Atualizar documentação da API    | nova-audit  | Opus  | 🟡   | ⬜     |
| task_04  | Auditar correção login + migração| nova-audit  | Opus  | 🟡   | ⬜     |

## Dependências

task_02 depende de task_01 (migração assume que login funciona)
task_04 depende de task_01 + task_02
task_03 é independente
```

@nova-orch cria `task_01.md` a `task_04.md` e atualiza INDICE.md com 4 novas tarefas.

### Fase 2: APROVAR (08:15)

@nova-orch publica o plano em `#agent-ops-nova`:

```
📋 Plano diário para 10/06/2026 pronto para revisão:
4 tarefas em 2 waves.

Wave 1 (🔴 Manhã):
- task_01: Corrigir bug de redirect login (nova-dev, Gemini)
- task_02: Completar migração API v2 (nova-dev, Gemini)

Wave 2 (🟡 Tarde):
- task_03: Atualizar documentação da API (nova-audit, Opus)
- task_04: Auditar correção login + migração (nova-audit, Opus)

Dependências: task_02 → task_01, task_04 → task_01 + task_02
```

**Sarah (Comandante):**
```
✅ Plano aprovado. Boas prioridades. Pode prosseguir.
```

### Fase 3: DELEGAR (08:20)

@nova-orch publica 4 mensagens de nível superior no canal, uma por tarefa:

```
<@U0123456789> Tarefa task_01: Corrigir bug de redirecionamento de login

**Motor:** Gemini 3.1 Pro (PADRÃO)
**Prioridade:** 🔴 ALTA
**Arquivo:** planejamento-diario/2026-06-10/task_01.md
...

<@U9876543210> Tarefa task_02: Completar migração API v2
...

<@U5555555555> Tarefa task_03: Atualizar documentação da API
...

<@U5555555555> Tarefa task_04: Auditar correção login + migração
...
```

Cada mensagem cria uma thread separada automaticamente.

### Fase 4: EXECUTAR (08:30 em diante)

Na thread da task_01:
```
nova-dev: Recebido. Iniciando task_01 agora.
nova-dev: ✅ Task_01 concluída.
  Commit: aabbccdd
  Testes: 47/47 passando
  Observações: Corrigida URL de redirecionamento em AuthController.php.
  Pronto para auditoria.
```

Na thread da task_02:
```
nova-dev: Iniciando task_02.
nova-dev: ✅ Task_02 concluída.
  Commit: eeff0011
  Migração executada com sucesso. Sem perda de dados.
  Pronto para auditoria.
```

Enquanto isso, task_03 (documentação) roda em paralelo já que não tem
dependências:
```
nova-audit: Recebida task_03. Iniciando atualização de docs.
nova-audit: ✅ Task_03 concluída.
  Commit: 11223344
  Todos os endpoints da API documentados. Notas de migração adicionadas.
  Pronto para auditoria (ou pular — nenhum código alterado).
```

### Fase 5: AUDITAR (após a execução)

@nova-orch audita task_01:
```
Verificando commit aabbccdd...
Diff parece correto. Constante de redirecionamento alterada de /dashboard para /home.
Checklist completo. Restrições respeitadas.

✅ Auditoria aprovada para task_01.
Commitando registro de auditoria.
```

@nova-orch atualiza INDICE.md:
```
## 10/06/2026 — 1/4

| Tarefa   | Descrição                    | Wave | ✅ | 👁 | Commit    |
|----------|------------------------------|:----:|---|---|-----------|
| task_01  | Corrigir bug redirect login  | 1    | ✅ | ✅ | aabbccdd  |
| task_02  | Completar migração API v2    | 1    | ⬜ | ⬜ | —         |
| task_03  | Atualizar documentação API   | 2    | ⬜ | ⬜ | —         |
| task_04  | Auditar correção + migração  | 2    | ⬜ | ⬜ | —         |
```

Auditoria continua para task_02 e task_03.

### Fase 6: REPORTAR (fim do dia)

```
📊 Relatório Diário — Time Nova — 10/06/2026

| Tarefa   | Descrição                    | Status | Commit    |
|----------|------------------------------|--------|-----------|
| task_01  | Corrigir bug redirect login  | ✅ 👁  | aabbccdd  |
| task_02  | Completar migração API v2    | ✅ 👁  | eeff0011  |
| task_03  | Atualizar documentação API   | ✅ 👁  | 11223344  |
| task_04  | Auditar correção + migração  | ✅ 👁  | —         |

**Resumo:** 4/4 tarefas concluídas. 4/4 auditadas. 0 bloqueadores.
**Pendente para amanhã:** Nenhum. Sprint no prazo.

**Contadores finais:** INDICE.md: 4/4 ✅, 4/4 👁
**Commits:** 3 novos commits enviados.
```

Git push final e o dia está concluído. O plano de amanhã começa a partir deste relatório.

---

## Regras de Thread

A disciplina de thread é crítica para manter o workflow legível e
auditável. Violações causam confusão, perda de contexto e comunicações
perdidas.

### Regra 1: Uma Tarefa = Uma Thread

Cada mensagem de delegação é uma postagem de nível superior. Toda resposta
sobre aquela tarefa vai **naquela** thread. Nunca crie uma nova thread para
a mesma tarefa, mesmo para correções, re-auditorias ou complementos.

```
✅ Correto:

@nova-dev task_01: Corrigir bug login   ← postagem nível superior
├── nova-dev: Recebido                   ← resposta na thread
├── nova-dev: Commit abc123...           ← resposta na thread
├── nova-orch: Auditoria aprovada        ← resposta na thread
└── nova-dev: Obrigado                   ← resposta na thread

❌ Errado:

@nova-dev task_01: Corrigir bug login   ← postagem nível superior
nova-dev: Recebido                        ← no canal (não na thread!)
nova-dev: Commit abc123...                ← no canal (não na thread!)
nova-orch: @nova-dev favor auditar        ← nova postagem nível superior (errado!)
```

### Regra 2: Apenas o Orquestrador Publica Fora das Threads

O orquestrador é o único papel que publica mensagens de nível superior no
canal de operações. Agentes sempre respondem dentro de sua thread designada.
O Comandante também pode publicar mensagens de nível superior (aprovações,
lockdowns, diretivas).

### Regra 3: Sem Tabelas em Mensagens de Delegação

Caracteres pipe (`|`) quebram o parser de menção do Slack quando usados
dentro de uma mensagem de delegação. Use texto simples ou marcadores em vez
de tabelas ao instruir um agente.

```
❌ Errado:
| Campo | Valor |
|-------|-------|
| Motor | Gemini |

✅ Correto:
**Motor:** Gemini
```

### Regra 4: Threads São a Fonte da Verdade

Toda decisão, esclarecimento e atualização de status sobre uma tarefa vive em
sua thread. Não discuta tarefas em DMs, em outros canais ou em threads
separadas. Se alguém precisar consultar uma tarefa depois, olha a thread.

---

## Procedimentos de Recuperação de Erros

Apesar da estrutura rigorosa, as coisas podem dar errado. Aqui está o
playbook para cada modo de falha.

### Agente Reporta Hash de Commit Falso

**Sintoma:** Agente diz "Commit abc123" mas `git log` não mostra tal commit.

**Procedimento:**
1. O auditor responde na thread: "⚠️ Commit abc123 não encontrado no git log."
2. O agente verifica e faz um novo commit.
3. O agente publica o hash correto na mesma thread.
4. O auditor re-verifica.

**Prevenção:** Sempre execute `git log --oneline -1` antes de reportar.

### Thread Quebrada (Agente Responde no Canal)

**Sintoma:** Um agente publica fora de sua thread, bagunçando o canal.

**Procedimento:**
1. O orquestrador publica: "⚠️ @agente, por favor responda em sua thread:
   https://link-para-thread"
2. O orquestrador deleta a mensagem no lugar errado (se possível) ou a ignora.
3. Nenhuma nova thread é criada.

### Falha de Motor (Limite de Taxa / Exaurido)

**Sintoma:** Agente recebe RESOURCE_EXHAUSTED ou erro similar do motor.

**Procedimento:**
1. O agente reporta o erro na thread.
2. O agente divide a tarefa em subtarefas menores e continua com o mesmo motor.
3. Se falhar novamente, o agente para e reporta.
4. O orquestrador decide se espera, reassigna ou escala.

**Nunca troque de motor** sem aprovação do Comandante.

### Lockdown (Sinal Vermelho)

**Sintoma:** Comandante publica "LOCKDOWN" ou "sinal vermelho" no canal.

**Procedimento:** Veja [03-PROTOCOLO-SLACK.md](03-PROTOCOLO-SLACK.md) para o
protocolo completo de lockdown. Em resumo:
1. Todos os agentes congelam imediatamente.
2. Sem novas ações, commits ou mensagens.
3. Aguarde o sinal "LOCKDOWN LIFTED" do Comandante.
4. Retome de onde parou, reporte qualquer trabalho parcial.

### Plano Precisa de Revisão no Meio do Dia

**Sintoma:** O Comandante percebe que a prioridade de uma tarefa mudou, ou um
bloqueador surgiu.

**Procedimento:**
1. O Comandante publica a revisão no canal.
2. O orquestrador atualiza PLANO.md e informa os agentes afetados em suas
   threads.
3. Tarefas já concluídas não são reabertas a menos que a revisão exija
   retrabalho.
4. Novas tarefas recebem novas mensagens de delegação e novas threads.

### Agente Não Responsivo

**Sintoma:** Um agente não confirma uma mensagem de delegação dentro de
15 minutos.

**Procedimento:**
1. O orquestrador verifica se a instância Hermes do agente está rodando.
2. Se o agente estiver inativo, o orquestrador reassigna a tarefa para outro
   agente ou escala para o Comandante.
3. A thread original é atualizada com a nota de reassignação.

---

## Template de Relatório Diário

Use este template para o relatório da Fase 6. Publique no canal de operações
e commit na sua pasta diária para arquivamento.

```markdown
📊 Relatório Diário — {{NOME_DO_TIME}} — {{DATA}}

| Tarefa   | Descrição                       | Status | Commit    |
|----------|---------------------------------|--------|-----------|
| task_01  | {{DESCRICAO_CURTA}}             | {{✅/⚠️/❌}} | {{HASH}} |
| task_02  | {{DESCRICAO_CURTA}}             | {{✅/⚠️/❌}} | {{HASH}} |
| ...      | ...                             | ...    | ...       |

**Resumo:**
{{X}}/{{Y}} tarefas concluídas. {{A}} auditadas. {{B}} falharam.
{{C}} bloqueadores restantes.

**Itens pendentes para amanhã:**
- {{ITEM_1}}
- {{ITEM_2}}

**Contadores finais:** INDICE.md: {{X}}/{{Y}} ✅, {{A}}/{{Y}} 👁
**Commits:** {{N}} novos commits enviados hoje.

**Observações notáveis:**
- {{OBSERVACAO_1}}
- {{OBSERVACAO_2}}
```

---

## Resumo — As 6 Regras de Ouro do Ciclo

1. **Nunca pule fases.** Planejar → Aprovar → Delegar → Executar → Auditar →
   Reportar. Nessa ordem.

2. **Nunca delegue sem aprovação.** A Fase 3 não pode começar até que a Fase 2
   esteja completa.

3. **Uma tarefa = uma thread.** Cada tarefa tem sua própria mensagem de nível
   superior e sua própria thread. Sem exceções.

4. **Sempre commit antes de reportar.** Uma tarefa sem hash de commit não está
   concluída. Verifique com `git log`.

5. **⬜ mantido é falha grave — atualize IMEDIATAMENTE após cada auditoria.**
   INDICE.md e PLANO.md DEVEM ser atualizados no mesmo momento da auditoria:
   - ✅ na task (concluída)
   - 👁 na task (auditada)
   - Hash do commit na coluna Commit
   - Contador X/Y recalculado
   - **Nunca acumule atualizações. Nunca deixe ⬜ depois de auditado.**

6. **Nunca tome ação corretiva sem o sinal verde do Comandante.**
   Cometeu um erro? Reporte e espere.
