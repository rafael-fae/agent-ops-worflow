# Protocolo Slack — Agent Ops Workflow

> O guia completo para comunicação de agentes via Slack. Abrange hierarquia
> de mensagens, formato de @menção, templates de delegação, regra do silêncio,
> protocolo de lockdown e solução de problemas.

---

## Sumário

1. [Por que Slack?](#por-que-slack)
2. [Estrutura de Canais](#estrutura-de-canais)
3. [Hierarquia de Mensagens: Canal vs. Thread](#hierarquia-de-mensagens-canal-vs-thread)
4. [O Formato de @Menção](#o-formato-de-menção)
5. [Template de Delegação](#template-de-delegação)
6. [Protocolo de Resposta do Agente](#protocolo-de-resposta-do-agente)
7. [A Regra do Silêncio](#a-regra-do-silêncio)
8. [Protocolo de Lockdown](#protocolo-de-lockdown)
9. [Melhores Práticas](#melhores-práticas)
10. [Solução de Problemas](#solução-de-problemas)
11. [Tabelas de Referência](#tabelas-de-referência)

---

## Por que Slack?

O Slack fornece três recursos que o tornam a camada de comunicação ideal para
operações multi-agente:

1. **Threads** — Cada tarefa tem uma conversa isolada que não polui o canal
   principal. Todo o histórico sobre uma tarefa vive em um só lugar.

2. **@menções** — Despacho direto para um agente específico. Apenas o agente
   mencionado responde (regra do silêncio). Sem conversa cruzada.

3. **Persistência** — Toda mensagem, decisão e atualização de status é
   permanentemente registrada e pesquisável. Nenhum contexto é perdido entre
   sessões.

Sistemas de chat alternativos (Discord, Teams, Matrix) podem funcionar se
suportarem threads e @menções, mas o Slack é a implementação de referência
para a qual este protocolo foi projetado.

---

## Estrutura de Canais

### Canal Único de Operações

A configuração mais simples usa um canal dedicado para toda a comunicação de
agentes.

```
Canal: #agent-ops-nova
Propósito: Planejamento diário, delegação de tarefas, atualizações de status, relatórios

Participantes:
- Comandante (humano)    — lê planos, aprova, emite diretivas
- Orquestrador           — publica planos, delega, audita, reporta
- Agente A               — executa tarefas, reporta em threads
- Agente B               — executa tarefas, reporta em threads
- Agente C (auditor)     — verifica tarefas concluídas
```

Todas as mensagens de nível superior neste canal vêm do Comandante ou do
Orquestrador. Agentes respondem dentro das threads.

### Configuração Multicanal (Avançada)

Para equipes maiores, você pode usar múltiplos canais:

| Canal | Propósito |
|-------|-----------|
| `#agent-ops-nova` | Planejamento diário, aprovações, relatórios |
| `#nova-execucao` | Mensagens de delegação e threads de execução |
| `#nova-auditoria` | Relatórios de auditoria e verificações cruzadas |
| `#nova-alertas` | Sinais de lockdown, erros críticos |

As regras do protocolo são as mesmas entre os canais. Cada canal tem seu
próprio espaço de thread — não poste entre canais para a mesma tarefa.

### Convenção de Nomenclatura de Canais

```
#agent-ops-{nomedotime}        — Canal principal de operações
#agent-ops-{nomedotime}-exec   — Canal de execução (se separado)
#agent-ops-{nomedotime}-audit  — Canal de auditoria (se separado)
#agent-ops-{nomedotime}-alert  — Alertas e lockdowns
```

O ID do canal (ex.: `C0123456789`) é referenciado na configuração do Hermes
como `home_channel`. Todos os agentes devem ser convidados para os canais em
que operam.

---

## Hierarquia de Mensagens: Canal vs. Thread

Entender a distinção entre mensagens de canal e respostas em thread é o
conceito mais importante neste protocolo.

### Regras

| Contexto | Quem Pode Postar | Exemplo |
|----------|------------------|---------|
| Nível superior (canal) | Apenas Comandante, Orquestrador | Plano, delegação, relatório, lockdown |
| Resposta em thread | Qualquer agente na thread | Atualização de status, relatório de commit |
| DM | Nunca para comunicação de tarefas | Escalação apenas (Comandante) |

### Mensagens de Nível Superior

Estes são os únicos tipos de mensagens que aparecem na visualização principal do canal:

1. **Anúncio de plano:** Orquestrador publica o resumo do PLANO.md diário
2. **Aprovação:** Comandante aprova ou rejeita o plano
3. **Delegação:** Orquestrador atribui tarefas (uma por mensagem)
4. **Diretiva:** Comandante dá uma instrução para toda a equipe
5. **Relatório:** Orquestrador publica o resumo do fim do dia
6. **Lockdown:** Comandante aciona congelamento de emergência
7. **Verificação de status:** Orquestrador pede status geral da equipe

### Respostas em Thread

Estas pertencem dentro da thread de uma tarefa específica:

1. **Confirmação:** Agente confirma recebimento da tarefa
2. **Atualização de progresso:** Agente reporta checkpoints no meio da tarefa
3. **Relatório de conclusão:** Agente marca tarefa como concluída com hash do commit
4. **Resultado de auditoria:** Auditor aprova ou reprova a tarefa
5. **Esclarecimento:** Qualquer participante pergunta ou responde sobre a tarefa
6. **Correção:** Agente corrige problemas e reenvia para auditoria
7. **Re-auditoria:** Auditor re-verifica após correções

### O Que Nunca Pertence a uma Thread

- Uma nova delegação de tarefa (isso é uma nova mensagem de nível superior)
- Um tópico completamente não relacionado
- Uma diretiva global ou lockdown

---

## O Formato de @Menção

### Por que `<@USER_ID>` é Obrigatório

O Slack suporta duas formas de mencionar um usuário:

1. **Nome de exibição** — `@nova-dev` (legível por humanos, muda se o nome mudar)
2. **ID do usuário** — `<@U0123456789>` (permanente, nunca muda)

**Você DEVE usar o formato de ID do usuário.** Eis o porquê:

- Nomes de exibição podem mudar. Se alguém renomear `@nova-dev` para `@nova-engineer`,
  todas as suas mensagens históricas quebram — a @menção não resolve mais.
- O Hermes e outros agentes automatizados analisam o ID do Usuário da mensagem. Se
  o nome de exibição for usado, o parser pode não saber para qual agente rotear.
- A API do Slack resolve `<@U0123456789>` para o usuário em qualquer contexto. O
  nome de exibição `<@nova-dev>` só funciona se o usuário estiver atualmente no
  canal.

### Como Encontrar IDs de Usuário

**Método 1: Interface do Slack**
1. Clique na foto de perfil do usuário
2. Clique em **More** (três pontos)
3. Selecione **Copy member ID**
4. O ID se parece com `U0123456789`

**Método 2: API do Slack**
```bash
# Use o endpoint users.list da API
curl -H "Authorization: Bearer *** \
  https://slack.com/api/users.list \
  | jq '.members[] | {name: .name, id: .id}'
```

**Método 3: Contexto da mensagem**
1. Clique com o botão direito em qualquer mensagem do usuário
2. Selecione **Copy link**
3. O link contém o ID do usuário: `.../pU0123456789_...`
4. Extraia o `U` + 9-11 dígitos

### O Formato na Prática

```
✅ Correto:
<@U0123456789> Tarefa task_01: Corrigir bug de redirecionamento de login

❌ Errado:
@nova-dev Tarefa task_01: Corrigir bug de redirecionamento de login
```

### Documente Seus IDs de Usuário

Crie um arquivo `AGENTS.md` na raiz do seu projeto:

```markdown
# Registro de Agentes — Time Nova

| Função       | Nome Slack | ID do Slack         | Motor Padrão        |
|--------------|------------|---------------------|---------------------|
| Orquestrador | nova-orch  | <@U0123456789>      | Gemini 3.1 Pro      |
| Agente Dev   | nova-dev   | <@U9876543210>      | Gemini 3.1 Pro      |
| Agente Auditor| nova-audit| <@U5555555555>      | Opus 4.7            |
| Comandante   | sarah      | <@U0000000001>      | Humano              |
```

Mantenha este arquivo atualizado sempre que houver mudanças na equipe.

---

## Template de Delegação

Toda mensagem de delegação de tarefa segue um template estrito. Isso garante
consistência, capacidade de análise e completude.

### O Template Exato

```
<@USER_ID> Tarefa TASK_ID: TITULO_DA_TAREFA

**Motor:** NOME_DO_MOTOR (NIVEL_DE_OBRIGACAO)
**Prioridade:** NIVEL_DE_PRIORIDADE
**Arquivo:** planejamento-diario/DATA/ARQUIVO_DA_TAREFA

**Resumo:**
DESCRICAO_BREVE

**Instruções principais:**
1. INSTRUCAO_1
2. INSTRUCAO_2

**Lembrete de checklist:**
- ITEM_DO_CHECKLIST_1
- ITEM_DO_CHECKLIST_2

**Restrições:**
- RESTRICAO_1
- RESTRICAO_2
```

### Níveis de Obrigação

| Nível | Sintaxe | Significado |
|-------|---------|-------------|
| PADRÃO | `**Motor:** Gemini 3.1 Pro (PADRÃO)` | Use este motor a menos que falhe |
| OBRIGATÓRIO | `**Motor:** Opus 4.7 (OBRIGATÓRIO)` | Este motor é obrigatório. Sem alternativas. |
| PROIBIDO | `**Motor:** DeepSeek (PROIBIDO)` | NÃO use este motor sem ordem do Comandante |
| ABSOLUTO | `**ORDEM ABSOLUTA — Motor:** Gemini` | Inegociável. Divida em subtarefas se falhar. |

### Exemplos de Delegação

**Exemplo 1: Tarefa de Código Padrão**

```
<@U9876543210> Tarefa task_01: Corrigir bug de redirecionamento de login

**Motor:** Gemini 3.1 Pro (PADRÃO)
**Prioridade:** 🔴 ALTA — Bloqueia task_02
**Arquivo:** planejamento-diario/2026-06-10/task_01.md

**Resumo:**
O redirecionamento de login está enviando usuários para /dashboard em vez de
/home após a autenticação. Corrija a constante de URL de redirecionamento.

**Instruções principais:**
1. Encontre a constante de redirecionamento em AuthController.php
2. Altere o valor de '/dashboard' para '/home'
3. Teste em staging com curl
4. Execute a suíte completa de testes

**Lembrete de checklist:**
- Verificou correção em staging
- Executou suíte completa de testes
- Preencheu seção de Conclusão em task_01.md
- Committed e deu push

**Restrições:**
- NÃO modifique arquivos de migração de banco de dados
- NÃO altere o middleware de autenticação
- Mexa apenas na constante de URL de redirecionamento
```

**Exemplo 2: Tarefa de Auditoria**

```
<@U5555555555> Tarefa task_04: Auditar correção de login

**Motor:** Opus 4.7 (OBRIGATÓRIO — auditoria requer análise profunda)
**Prioridade:** 🟡 MÉDIA
**Arquivo:** planejamento-diario/2026-06-10/task_04.md

**Resumo:**
Auditar task_01 (correção de redirect login) e task_02 (migração API).
Verificar commits, conferir diffs, confirmar restrições respeitadas.

**Instruções principais:**
1. git log --oneline para encontrar commits
2. git show cada commit para revisar alterações
3. Ler cada arquivo de tarefa para completude do checklist
4. Atualizar PLANO.md e INDICE.md após cada verificação

**Restrições:**
- Não modifique o código que está auditando
- Publique resultados de auditoria nas threads originais das tarefas
```

**Exemplo 3: Tarefa de Documentação (Sem Código)**

```
<@U9876543210> Tarefa task_03: Atualizar documentação da API

**Motor:** Gemini 3.1 Pro (PADRÃO)
**Prioridade:** 🟢 BAIXA
**Arquivo:** planejamento-diario/2026-06-10/task_03.md

**Resumo:**
A migração da API v2 alterou 3 URLs de endpoints. Atualize a
documentação da API para refletir os novos endpoints.

**Instruções principais:**
1. Leia a documentação atual da API
2. Cruze com o código migrado
3. Atualize URLs e exemplos de requisição/resposta
4. Marque endpoints alterados com tag "(v2)"

**Restrições:**
- Não altere código — apenas arquivos de documentação
- Mantenha a mesma estrutura markdown
```

### O que NÃO Incluir em Mensagens de Delegação

1. **Tabelas** — Caracteres pipe (`|`) quebram o parser de menção. Use
   marcadores ou texto em negrito.

2. **Blocos de código longos** — Referencie o arquivo da tarefa para instruções
   completas. Mantenha a mensagem de delegação como um resumo.

3. **Múltiplas tarefas em uma mensagem** — Cada tarefa tem sua própria mensagem
   de nível superior. Nunca combine task_01 e task_02 em uma única postagem.

4. **Contexto não relacionado** — Mantenha-se na tarefa. Contexto histórico vai
   no arquivo da tarefa, não na mensagem do Slack.

---

## Protocolo de Resposta do Agente

### Confirmação

Quando um agente recebe uma delegação, ele deve confirmar dentro da thread:

```
Recebido. Iniciando task_01 agora.
```

Se o agente não puder começar imediatamente (ex.: aguardando uma dependência):

```
Recebido. Task_01 está bloqueada por task_02. Vou começar assim que
task_02 estiver concluída.
```

### Atualizações de Progresso

Para tarefas longas, atualizações periódicas são úteis:

```
Atualização de progresso da task_01 (30 min decorridos):
- Encontrou a constante de redirecionamento
- Alterou URL, testando agora
- Previsão de conclusão: 15 min
```

### Relatório de Conclusão

```
✅ Task_01 concluída.
Commit: aabbccdd11223344
Testes: 47/47 passando
Observações: Corrigida URL de redirecionamento em AuthController.php.
Pronto para auditoria.
```

O relatório de conclusão deve incluir:
- ✅ (checkmark) + ID da tarefa
- Hash do commit (verificado com `git log --oneline`)
- Resultados de testes ou evidência de verificação
- Observações sobre o que foi feito
- "Pronto para auditoria" (handoff)

### Relatório de Erro

```
⚠️ Task_01 travou.
Motor retornou RESOURCE_EXHAUSTED no passo 3.
Dividi a tarefa em subtarefas mas encontrei o mesmo erro.
Parando e aguardando instruções.

Trabalho parcial commitado no commit: 99bbaa00 (não completo).
```

### Resultado de Auditoria

Aprovado:
```
✅ Auditoria aprovada para task_01.
Commit aabbccdd verificado.
- Correção de login correta (URL de redirecionamento alterada)
- Todos os testes passam (47/47)
- Checklist completo (6/6)
- Restrições respeitadas
INDICE.md atualizado.
```

Reprovado:
```
⚠️ Auditoria reprovada para task_01.
Problemas encontrados:
- Item #3 do checklist (teste em staging) não preenchido
- Seção de Conclusão sem hash do commit
Por favor, corrija e reenvie nesta thread.
```

---

## A Regra do Silêncio

**Definição:** Apenas o agente que é @mencionado em uma mensagem responde
àquela mensagem. Todos os outros agentes permanecem em silêncio.

### Por que é Importante

Em um canal multi-agente, múltiplos agentes veem todas as mensagens. Sem a
regra do silêncio, você tem:

- **Conversa cruzada:** Agente B responde a uma tarefa destinada ao Agente A
- **Confusão:** Dois agentes executam a mesma tarefa em paralelo
- **Ruído:** Respostas irrelevantes poluem a thread
- **Perda de contexto:** A thread se torna ilegível

### Como Funciona

1. O orquestrador publica: `<@U0123456789> Tarefa task_01: ...`
2. Apenas o usuário com ID `U0123456789` responde naquela thread.
3. Todos os outros agentes (incluindo orquestrador, até ser necessário) ficam
   em silêncio.
4. Após o agente reportar conclusão, o orquestrador pode responder para auditoria.

### Exceções

A regra do silêncio tem três exceções:

1. **O Comandante** pode sempre postar em qualquer lugar, a qualquer momento.
   Sua autoridade sobrepõe a regra do silêncio.

2. **O Orquestrador** pode responder em qualquer thread para:
   - Esclarecer instruções
   - Conduzir auditorias
   - Fornecer atualizações de status

3. **Lockdown** — Durante um lockdown, NINGUÉM posta nada exceto o Comandante.

### Exemplo Prático

```
Canal: #agent-ops-nova

orquestrador: <@U9876543210> Tarefa task_01: Corrigir bug de redirect
              login. [Motor: Gemini...]
              ↑ Apenas nova-dev (U9876543210) responde

nova-dev: Recebido. Iniciando.               ← OK (nova-dev)
nova-audit: Posso ajudar se precisar.        ← VIOLAÇÃO (regra do silêncio)
nova-orch: @nova-audit favor manter silêncio ← Aviso
nova-dev: ✅ Concluído. Commit: aabbccdd     ← OK
nova-audit: Bom trabalho!                    ← VIOLAÇÃO (regra do silêncio)
nova-orch: ✅ Auditoria aprovada.            ← OK (orquestrador)
```

---

## Protocolo de Lockdown

O protocolo de lockdown é o freio de emergência para toda a operação. Quando
acionado, TODA a atividade do agente para imediatamente.

### Frases de Acionamento

O Comandante inicia o lockdown publicando uma destas frases exatas como uma
mensagem de nível superior no canal de operações:

```
LOCKDOWN
sinal vermelho
RED SIGNAL
```

Estas são insensíveis a maiúsculas/minúsculas mas devem ser exatas. Variações
como "lockdown por favor" ou "sinal amarelo" não são reconhecidas.

### O que Acontece Durante o Lockdown

1. **Todos os agentes congelam imediatamente.** Abandone o que estiver fazendo.
2. **Sem novas ações.** Não comece novas tarefas, não continue as atuais,
   não commite, não faça push.
3. **Sem novas mensagens.** Não poste nada em nenhum canal ou thread.
4. **Trabalho parcial permanece como está.** Não reverta ou delete trabalho parcial.
5. **Aguarde o sinal de liberação.** Apenas o Comandante pode suspender o lockdown.

### O que o Comandante Faz Durante o Lockdown

1. Publica o sinal de lockdown
2. Resolve o problema (violação de segurança, direção errada, crise externa)
3. Publica a mensagem de liberação:

```
LOCKDOWN LIFTED
sinal verde
GREEN SIGNAL
```

4. Opcionalmente publica uma diretiva explicando o que aconteceu e quais mudanças

### Retomando Após o Lockdown

1. Todos os agentes reportam seu estado em suas threads de tarefa:
   ```
   Status antes do lockdown: Passo 3 de 6 completo. Commit parcial em
   99bbaa00 (não enviado). Retomando do passo 4.
   ```
2. O orquestrador avalia se alguma tarefa precisa ser reassignada ou
   descartada.
3. Operações normais são retomadas.

### Exemplo de Fluxo de Lockdown

```
sarah: LOCKDOWN                          ← Sinal de emergência
nova-dev: (congela imediatamente)        ← Nenhuma mensagem necessária
nova-audit: (congela imediatamente)      ← Nenhuma mensagem necessária
nova-orch: (congela)                     ← Nenhuma mensagem necessária

... 10 minutos passam ...

sarah: LOCKDOWN LIFTED                   ← Liberação
sarah: Problema de segurança resolvido.
       Por favor, verifiquem suas threads para
       quaisquer tarefas que tocaram o módulo
       de autenticação. Retomem operações normais.

nova-dev: Status antes do lockdown:      ← OK
  task_01 concluída, task_02 no passo 2.
nova-audit: Status antes do lockdown:    ← OK
  auditoria task_04 em andamento, sem resultados parciais.
nova-orch: Retomando auditorias.         ← OK
```

### O que NÃO é Lockdown

Estes NÃO são sinais de lockdown:

- "Alguém pode pausar um momento?" (esclarecimento, não lockdown)
- "Segura aí, deixa eu verificar algo" (não lockdown)
- "Parem o que estão fazendo" (deve usar a palavra-chave exata "LOCKDOWN")

Se o Comandante quer dizer lockdown, ele usará a palavra-chave exata. Qualquer
outra coisa é uma conversa normal.

---

## Melhores Práticas

### 1. Sem Threads Duplicadas

Se uma tarefa precisa de re-auditoria ou correção, use a **thread existente**.
Não crie uma nova mensagem de nível superior.

```
✅ Correto: Responder na thread original
❌ Errado: "@agente Tarefa task_01 re-auditoria" (nova mensagem nível superior)
```

### 2. Checkboxes Antes de Reportar

Antes de publicar um relatório de conclusão, verifique se todos os itens do
checklist no arquivo da tarefa estão preenchidos (`[x]`). Uma tarefa com
checkboxes vazios não está completa.

```
# O que o orquestrador verifica durante a auditoria:
[ ] Todos os checkboxes preenchidos em task_XX.md
[ ] Nenhum [ ] deixado sem marcar
[ ] Seção de Conclusão tem agente, data, motor, commit, observações
```

### 3. Use Links de Thread para Referência

Ao se referir a uma conversa anterior, use o link da thread do Slack:

```
Veja a discussão na thread task_01: https://... (não "lembra quando...")
```

### 4. Uma Menção por Mensagem

Nunca @mencione múltiplos agentes em uma única mensagem de delegação. Cada
tarefa tem um dono. Se uma tarefa precisar de colaboração, deve ser dividida
em subtarefas.

```
✅ Correto:
<@U0123456789> Tarefa task_01: ...
<@U9876543210> Tarefa task_02: ...

❌ Errado:
<@U0123456789> <@U9876543210> Tarefa task_01: ... (quem é o dono?)
```

### 5. Sem DMs para Comunicação de Tarefas

Tudo sobre uma tarefa vai em sua thread. Não envie DM para agentes sobre
tarefas. Se o Comandante precisar escalar, ele envia DM ao orquestrador, que
então atualiza a thread.

### 6. Reações como Sinais

Use reações emoji para sinalização leve:

| Reação | Significado |
|--------|-------------|
| ✅ | Tarefa concluída / aprovada |
| 👁 | Auditado / sendo revisado |
| ⬜ | Pendente / não iniciado |
| 🚨 | Erro / precisa de atenção |
| 🔒 | Lockdown ativo |
| 🔓 | Lockdown suspenso |

Reações não substituem comunicação escrita. Use-as como complemento às
mensagens de texto.

### 7. Arquivar Dias Concluídos

Ao final de cada dia, o orquestrador deve fixar a mensagem do relatório diário
no canal para referência fácil. Threads antigas podem ser arquivadas ou
deixadas como estão, já que o Slack preserva o histórico de threads.

### 8. Mantenha AGENTS.md Atualizado

Sempre que um membro da equipe mudar seu nome de exibição no Slack ou sair da
equipe, atualize `AGENTS.md` imediatamente. Rostos de agentes desatualizados
fazem a delegação falhar silenciosamente.

---

## Solução de Problemas

### Problemas Comuns e Correções

| Problema | Causa | Correção |
|----------|-------|----------|
| Agente não responde à @menção | Agente não está no canal | `/invite @nome-do-agente` |
| @menção aparece como texto simples | Usando nome de exibição em vez de ID do usuário | Use formato `<@U...>` |
| Mensagem não aparece na thread | Publicada como nova mensagem em vez de resposta | Clique "Reply in thread" antes de postar |
| Bot retorna erro `not_in_channel` | Bot não foi convidado ao canal de operações | Convide o bot para o canal |
| Erro `invalid_auth` | Token expirado ou revogado | Gere novo token no painel Slack API |
| Erro `missing_scope` | Bot não tem permissão necessária | Adicione escopo nas configurações do app, reinstale |
| Caracteres pipe quebram parser de menção | Usando tabelas na mensagem de delegação | Use marcadores ou texto em negrito em vez de tabelas |
| Agente errado responde à delegação | Múltiplos agentes mencionados ou regra do silêncio violada | Use `<@USER_ID>` para exatamente um agente |
| Histórico de thread perdido após reinstalação | App reinstalado com novas credenciais | Mantenha o mesmo ID do app entre reinstalações |
| Palavra-chave de lockdown não reconhecida | Erro de digitação ou frase alternativa | Use frase exata: LOCKDOWN / sinal vermelho |

### Etapas de Depuração

**Problema: Agente não responde**

1. Verifique se o agente está no canal:
   ```bash
   curl -H "Authorization: Bearer *** \
     https://slack.com/api/conversations.members?channel=C0123456789
   ```
2. Verifique se a instância Hermes do agente está rodando
3. Verifique se o ID do Usuário na @menção corresponde à configuração do agente
4. Verifique os logs do app Slack em api.slack.com/apps → Your App → Logs

**Problema: Mensagens não estão sendo roteadas corretamente**

1. Verifique se o token bot tem escopo `chat:write`
2. Verifique se `thread_ts` está incluído em mensagens de resposta
3. Verifique se o ID do home_channel na configuração Hermes corresponde ao ID
   real do canal

**Problema: Lockdown não está funcionando**

1. Verifique se o Comandante está usando a palavra-chave exata: `LOCKDOWN`
2. Verifique se todos os agentes têm a palavra-chave de lockdown em suas
   instruções de prompt/sistema
3. Execute um teste de lockdown durante um período não crítico para testar o fluxo

### Recuperação de Erros Comuns

**Publiquei uma delegação na thread errada.**
```
orquestrador: (percebe o erro)
orquestrador: ⚠️ Thread errada. Movendo para a correta.
orquestrador: Deleta a mensagem no lugar errado (se dentro da janela de edição)
orquestrador: Publica a delegação no local correto
```

**Um agente postou no canal em vez de em uma thread.**
```
orquestrador: ⚠️ @agente, por favor responda em sua thread:
              https://link-para-thread-da-tarefa
orquestrador: (deleta mensagem no lugar errado se possível)
agente: (republica na thread correta)
```

**O Comandante acionou lockdown acidentalmente.**
```
sarah: LOCKDOWN  ← ops
sarah: LOCKDOWN LIFTED — falso alarme, desculpe.
       Retomem operações normais.
```

---

## Tabelas de Referência

### Referência Completa de Tipos de Mensagem

| Tipo de Mensagem | Quem Publica | Onde | Exemplo |
|------------------|-------------|------|---------|
| Anúncio de plano | Orquestrador | Nível superior canal | 📋 Plano diário para DD/MM/YYYY... |
| Aprovação de plano | Comandante | Nível superior canal | ✅ Plano aprovado. Pode prosseguir. |
| Rejeição de plano | Comandante | Nível superior canal | ⚠️ Plano precisa de revisão: ... |
| Delegação de tarefa | Orquestrador | Nível superior canal | <@U...> Tarefa task_01: ... |
| Confirmação de tarefa | Agente designado | Resposta na thread | Recebido. Iniciando agora. |
| Progresso da tarefa | Agente designado | Resposta na thread | Progresso: passo 3 de 6 concluído. |
| Conclusão da tarefa | Agente designado | Resposta na thread | ✅ Task_01 concluída. Commit:... |
| Auditoria aprovada | Orquestrador/auditor | Resposta na thread | ✅ Auditoria aprovada para task_01. |
| Auditoria reprovada | Orquestrador/auditor | Resposta na thread | ⚠️ Auditoria reprovada: ... |
| Relatório diário | Orquestrador | Nível superior canal | 📊 Relatório Diário — DD/MM/YYYY |
| Lockdown | Comandante | Nível superior canal | LOCKDOWN |
| Lockdown suspenso | Comandante | Nível superior canal | LOCKDOWN LIFTED |
| Diretiva | Comandante | Nível superior canal | 📢 Atenção equipe: ... |
| Esclarecimento | Qualquer participante | Resposta na thread | Dúvida sobre o passo 2... |

### Referência de Escopos do Slack

| Escopo | Obrigatório Para | Usado Em |
|--------|-----------------|----------|
| `channels:history` | Ler histórico do canal | Encontrar threads, contexto de auditoria |
| `channels:read` | Visualizar informações do canal | Associação ao canal, busca de ID |
| `chat:write` | Enviar mensagens | Delegação, relatórios, tudo |
| `reactions:read` | Ler reações emoji | Detecção de sinais |
| `users:read` | Ler informações do usuário | Resolver @menções, busca de ID |

### Tipos de Token

| Tipo de Token | Prefixo | Onde Encontrar | Propósito |
|---------------|---------|----------------|-----------|
| Token Bot | `xoxb-` | Página OAuth & Permissions | Autenticação do bot |
| Token App (Socket) | `xapp-` | Basic Information → App-Level Tokens | Conexão Socket Mode |

### Formato de IDs

| Formato de ID | Exemplo | Como Obter |
|---------------|---------|------------|
| ID do Usuário | `U0123456789` | Perfil → More → Copy member ID |
| ID do Canal | `C0123456789` | URL do canal: /archives/C0123456789 |
| ID do Time/Workspace | `T0123456789` | URL do workspace: app.slack.com/client/T... |

### Diagrama de Fluxo de Comunicação

```
┌─────────────────────────────────────────────────────────────┐
│                   #agent-ops-nova (Canal)                     │
├─────────────────────────────────────────────────────────────┤
│ Mensagens de nível superior:                                 │
│                                                              │
│ orquestrador: 📋 Plano diário para 10/06/2026...            │
│ sarah:        ✅ Plano aprovado. Pode prosseguir.            │
│                                                              │
│ orquestrador: <@U9876543210> Tarefa task_01: Corrigir bug   │ ← Thread A
│ orquestrador: <@U5555555555> Tarefa task_04: Auditar correção│ ← Thread B
│                                                              │
│ nova-dev:     ✅ Task_01 concluída. Commit: aabbccdd         │ ← Na Thread A
│ nova-orch:    ✅ Auditoria aprovada.                         │ ← Na Thread A
│                                                              │
│ orquestrador: 📊 Relatório Diário — 10/06/2026...            │
└─────────────────────────────────────────────────────────────┘

Thread A (task_01):
├── nova-dev: Recebido. Iniciando.
├── nova-dev: ✅ Concluído. Commit: aabbccdd
├── nova-orch: ✅ Auditoria aprovada.
└── nova-dev: Obrigado.

Thread B (task_04):
├── nova-audit: Recebido. Iniciando auditoria.
├── nova-audit: ✅ task_01 auditada (aprovada).
├── nova-audit: ✅ task_02 auditada (aprovada).
└── nova-orch: Confirmado. INDICE.md atualizado.
```

---

## Resumo — Mandamentos do Protocolo

1. **Sempre use `<@USER_ID>`** — nunca nomes de exibição.
2. **Uma tarefa = uma mensagem de nível superior** = uma thread.
3. **Se não for @mencionado, fique em silêncio** — regra do silêncio é absoluta.
4. **Apenas o orquestrador publica mensagens de nível superior** (mais o Comandante).
5. **Sem tabelas em mensagens de delegação** — caracteres pipe quebram menções.
6. **Verifique checkboxes antes de reportar** — auditores verificarão.
7. **Nunca use DM para comunicação de tarefas** — pertence à thread.
8. **LOCKDOWN congela tudo** — palavra-chave exata, inegociável.
9. **Lockdown só é suspenso pelo Comandante** — com "LOCKDOWN LIFTED" exato.
10. **AGENTS.md é a fonte da verdade** — mantenha-o atualizado.
