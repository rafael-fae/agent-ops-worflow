<!--
==============================================================================
  TASK.md.tpl — Template Genérico de Tarefa Individual
  ============================================================================
  Este é o template para criar uma tarefa dentro de um plano diário.
  Copie para planejamento-diario/__DATA__/task_NN.md e preencha.

  Como usar:
    1. Determine o número sequencial da tarefa (ex.: task_01.md)
    2. Copie este template como task_NN.md
    3. Substitua __PLACEHOLDERS__ pelos valores reais
    4. Escreva instruções claras e verificáveis
    5. Ao finalizar, atualize a seção "Conclusão"

  Boas práticas:
    - Uma tarefa = uma responsabilidade clara e testável
    - Contexto deve explicar o PORQUÊ, não apenas o QUE
    - Instruções devem ser numeradas e específicas
    - Checklist deve conter itens binários (sim/não, feito/não feito)
==============================================================================
-->

# Tarefa __NUMERO__ — __TITULO_DA_TASK__

<!--
  Cabeçalho: identifica a tarefa dentro do plano do dia.
-->
**Onda:** __WAVE__ (__NOME_DA_WAVE__)
**Prioridade:** __PRIORIDADE__ (🔴 = alta, 🟡 = média, 🟢 = baixa)
**Agente designado:** __AGENTE__
**Motor:** __MOTOR__ (ex.: Gemini CLI, Claude Code, OpenAI API)
**Depende de:** __DEPENDE_DE__ (ex.: task_01, task_02 — ou "—" se raiz)

---

<!-- =====================================================================
  SEÇÃO: LEITURAS OBRIGATÓRIAS
  Links, documentos ou referências que o agente DEVE ler antes de começar.
  Deixe vazio se não houver, ou preencha com links relevantes.
===================================================================== -->
## Leituras Obrigatórias

<!--
  Exemplos (remova ou adapte):
  - [Documentação da API de Pagamento](https://docs.exemplo.com/api/pagamentos)
  - [Issue #42 no GitHub](https://github.com/equipe/projeto/issues/42)
  - [Guia de estilo do projeto](https://docs.exemplo.com/guia-estilo)
  - Commit de referência: abc1234
-->
- __LEITURA_1__
- __LEITURA_2__

---

<!-- =====================================================================
  SEÇÃO: CONTEXTO
  Explique por que esta tarefa existe. Que problema ela resolve?
  Qual é o cenário atual? O que acontece se não for feita?
  Contexto é o que permite ao agente tomar decisões autônomas.
===================================================================== -->
## Contexto

__CONTEXTO_DA_TASK__

Explique aqui:
- Qual é o problema ou oportunidade
- O que foi feito antes (se aplicável)
- Por que esta tarefa é necessária AGORA
- O que esperar ao final

<!--
  Exemplo:
  "O endpoint /api/usuarios está retornando 500 para requisições com
  parâmetros especiais. Isso foi reportado por 3 clientes hoje cedo.
  Precisamos corrigir antes do próximo deploy às 15:00."
-->

---

<!-- =====================================================================
  SEÇÃO: INSTRUÇÕES
  Numeradas e específicas. Cada instrução deve ser uma ação verificável.
  Inclua comandos, caminhos de arquivos e exemplos de código quando possível.
===================================================================== -->
## Instruções

<!--
  Instruções numeradas em markdown. Exemplo:

  1. Acesse o ambiente:
     ```bash
     ssh usuario@servidor
     cd /var/www/projeto
     ```

  2. Verifique os logs:
     ```bash
     tail -100 logs/error.log | grep "500"
     ```

  3. Identifique a causa raiz:
     - Verifique os parâmetros que disparam o erro
     - Valide a validação no controller

  4. Aplique a correção seguindo os padrões de código do projeto

  5. Teste:
     ```bash
     curl -X POST https://staging.exemplo.com/api/usuarios \
       -H "Content-Type: application/json" \
       -d '{"param":"teste"}'
     ```

  6. Commit:
     ```bash
     git add -A
     git commit -m "corrige erro 500 no endpoint /api/usuarios"
     git push
     ```
-->

### 1. __INSTRUCAO_1_TITULO__

__INSTRUCAO_1_DETALHES__

```bash
__COMANDO_1__
```

### 2. __INSTRUCAO_2_TITULO__

__INSTRUCAO_2_DETALHES__

```bash
__COMANDO_2__
```

### 3. __INSTRUCAO_3_TITULO__

__INSTRUCAO_3_DETALHES__

```bash
__COMANDO_3__
```

### 4. __INSTRUCAO_4_TITULO__

__INSTRUCAO_4_DETALHES__

```bash
__COMANDO_4__
```

_Adicione mais instruções conforme necessário._

---

<!-- =====================================================================
  SEÇÃO: CHECKLIST
  Itens binários que o agente deve marcar ao concluir.
  Use [ ] para pendente e [x] para concluído.
  Recomendado: 5-8 itens por tarefa.
===================================================================== -->
## Checklist

- [ ] __CHECKLIST_1__
- [ ] __CHECKLIST_2__
- [ ] __CHECKLIST_3__
- [ ] __CHECKLIST_4__
- [ ] __CHECKLIST_5__
- [ ] __CHECKLIST_6__
- [ ] __CHECKLIST_7__
- [ ] __CHECKLIST_8__

<!--
  Exemplo de itens de checklist:
  - [x] Código compilou sem erros
  - [ ] Testes unitários passaram (cobertura > 80%)
  - [ ] Logs não mostram novos erros
  - [ ] PR revisado por pelo menos um colega
  - [ ] Documentação atualizada
  - [ ] NENHUM arquivo de produção foi afetado
  - [ ] Commits seguem a convenção de commit semântico da equipe
-->

---

<!-- =====================================================================
  SEÇÃO: RESTRIÇÕES
  Regras específicas para esta tarefa. O que é proibido? Qual motor usar?
  Quais arquivos NÃO podem ser tocados?
===================================================================== -->
## Restrições

- __RESTRICAO_1__
- __RESTRICAO_2__
- __RESTRICAO_3__

<!--
  Exemplos:
  - Motor OBRIGATÓRIO: Gemini CLI (não use Claude para esta tarefa)
  - NUNCA modifique arquivos em config/production/
  - NÃO commite credenciais ou tokens
  - PROIBIDO fazer deploy sem aprovação
  - NÃO altere a interface pública da API
-->

---

<!-- =====================================================================
  SEÇÃO: ARQUIVOS RELEVANTES
  Tabela com arquivos que o agente precisa conhecer para executar a tarefa.
  Pode incluir origem e destino, ou apenas caminhos de interesse.
===================================================================== -->
## Arquivos Relevantes

| Arquivo | Localização | Propósito |
|---------|-------------|-----------|
<!--
  Exemplos:
  | src/controllers/UserController.ts | Código fonte | Controller que precisa ser alterado |
  | tests/unit/UserController.test.ts | Testes | Onde escrever os testes |
  | config/database.ts | Configuração | String de conexão (não modifique!) |
  | docs/API.md | Documentação | Atualizar se a interface mudar |
-->
| __ARQUIVO_1__ | __LOCAL_ARQUIVO_1__ | __PROPOSITO_ARQUIVO_1__ |
| __ARQUIVO_2__ | __LOCAL_ARQUIVO_2__ | __PROPOSITO_ARQUIVO_2__ |
| __ARQUIVO_3__ | __LOCAL_ARQUIVO_3__ | __PROPOSITO_ARQUIVO_3__ |

---

<!-- =====================================================================
  SEÇÃO: CONCLUSÃO
  Preenchida pelo agente ao concluir a tarefa.
  Mantenha o formato abaixo — serve para auditoria e documentação.
===================================================================== -->
## Conclusão

**Agente:** __AGENTE__
**Concluído em:** __DATA__ ~__HORARIO__
**Motor utilizado:** __MOTOR_UTILIZADO__
**Observações:**

__OBSERVACOES__

<!--
  Exemplo de observações:
  "Tarefa concluída com sucesso. O bug estava na validação do parâmetro 'email'
  que não aceitava caracteres especiais. Corrigido no commit abc1234.
  Testes passaram: 42/42. Logs limpos."
-->
