# Sistema de Memória Operacional — DIARIO.md + ESTADO-DA-EQUIPE.md

> Guia completo, didático e aprofundado sobre o sistema de memória operacional
> para agentes de IA multi-agente: o problema, a solução, a descoberta do
> system_prompt, e o passo a passo de implementação.

---

## Sumário

1. [O Problema — Por que criamos este sistema?](#1-o-problema-por-que-criamos-este-sistema)
2. [A Solução — O que criamos?](#2-a-solução-o-que-criamos)
3. [Estrutura de Diretórios — Como organizamos?](#3-estrutura-de-diretórios-como-organizamos)
4. [O DIARIO.md — Diário de Bordo Pessoal](#4-o-diariond-md-diário-de-bordo-pessoal)
5. [O ESTADO-DA-EQUIPE.md — Quadro Compartilhado](#5-o-estado-da-equipemd-quadro-compartilhado)
6. [A Descoberta Crítica: System Prompt vs AGENTS.md](#6-a-descoberta-crítica-system-prompt-vs-agentsmd)
7. [As 3 Camadas de Enforce](#7-as-3-camadas-de-enforce)
8. [Como Implementar — Passo a Passo](#8-como-implementar-passo-a-passo)
9. [Benefícios Comprovados](#9-benefícios-comprovados)
10. [Referências](#10-referências)

---

## 1. O Problema — Por que criamos este sistema?

### Agentes de IA não têm memória entre sessões

Esta é a verdade fundamental que motivou tudo. Um agente de IA (como um Hermes
Agent baseado em LLM) **não tem memória intrínseca entre sessões**. Cada vez
que você inicia uma conversa com ele, o contexto começa do zero:

```
Sessão 1 (08:00):
  Humano: "Agente, comece a task_01. Estamos refatorando o módulo X."
  Agente: "Entendi! Vou refatorar o módulo X agora."
  [Agente trabalha, faz commit, encerra]

  ─── FIM DA SESSÃO 1 ───
         ↓
  TODO O CONTEXTO É PERDIDO
         ↓

Sessão 2 (14:00):
  Humano: "Agente, continue a task_01."
  Agente: "Qual task_01? O que é módulo X? Não sei do que você está falando."
```

Isso acontece porque o modelo de linguagem **não persiste estado**. Cada
chamada de API é independente. O que o agente "sabe" é apenas o que está no
contexto da conversa atual.

### Cada sessão começa do zero

Sem um sistema de memória operacional, o agente:

- **Não lembra** quais tarefas já executou
- **Não sabe** qual é o estado atual do projeto
- **Não conhece** decisões tomadas em sessões anteriores
- **Não diferencia** tasks concluídas de tasks pendentes

### Múltiplos agentes podem atropelar trabalho uns dos outros

Em uma equipe multi-agente (orquestrador + vários especialistas), o problema
é amplificado:

```
Agente A (manhã):
  "Vou implementar a feature X no arquivo main.py"

Agente B (tarde) ← NÃO SABE que A já fez isso:
  "Vou implementar a feature X no arquivo main.py"

RESULTADO: Trabalho duplicado, conflitos de merge, retrabalho.
```

### Sem visibilidade do que está acontecendo agora

O humano (comandante) não tem um painel único mostrando:

- Quem está trabalhando em quê?
- Quais tarefas estão bloqueadas?
- O que já foi concluído hoje?
- Onde estão os gargalos?

### Histórico: instruções enterradas em documentos enormes

Antes deste sistema, as regras operacionais estavam:

| Onde | Tamanho | Problema |
|------|---------|----------|
| `AGENTS.md` | ~11K chars | Enterrado no meio de regras de separação de docs e checklist pré-commit |
| Skills | ~29K chars totais | Difícil de encontrar e lembrar — o modelo ignora o que não está priorizado |

O resultado: **os agentes simplesmente ignoravam as regras**. Não por má
vontade, mas porque o modelo não conseguia priorizar instruções enterradas em
meio a dezenas de milhares de caracteres de contexto.

---

## 2. A Solução — O que criamos?

Criamos um **Sistema de Memória Operacional** com três componentes principais:

### DIARIO.md — Diário de Bordo Pessoal

Cada agente tem seu próprio arquivo `DIARIO.md` no diretório do seu perfil
Hermes. É o "caderno de anotações" do agente — ele registra:

- Quando começou a trabalhar
- Em qual task está
- O que fez (comandos, commits, decisões)
- Quando pausou ou concluiu
- Observações e aprendizado

### ESTADO-DA-EQUIPE.md — Quadro Compartilhado

Arquivo único, mantido **apenas pelo orquestrador**, que funciona como um
painel central de controle. Mostra:

- Status de cada agente (Online/Ocupado/Pendente)
- Tarefas ativas com seus responsáveis
- Tarefas bloqueadas e motivo
- Decisões e alertas do dia

### Protocolo de Check-in / Check-out

Um conjunto de regras que todo agente DEVE seguir:

1. **Leia o ESTADO-DA-EQUIPE.md** antes de qualquer ação
2. **Atualize seu DIARIO.md** ao iniciar, pausar ou concluir uma task
3. **Atualize o ESTADO-DA-EQUIPE.md** (se for o orquestrador) ao mudar status
4. **Nunca** comece uma task sem verificar se outro agente já está nela

---

## 3. Estrutura de Diretórios — Como organizamos?

Os arquivos operacionais ficam dentro do diretório de cada perfil Hermes, em
uma subpasta `operacional/`:

```
~/.hermes/profiles/
│
├── orquestrador/          ← Perfil do agente orquestrador
│   ├── config.yaml
│   ├── SOUL.md
│   ├── AGENTS.md
│   ├── skills/
│   └── operacional/       ← PASTA DE MEMÓRIA OPERACIONAL
│       ├── DIARIO.md          ← Diário pessoal do orquestrador
│       └── ESTADO-DA-EQUIPE.md  ← Painel compartilhado (SÓ AQUI!)
│
├── agente1/               ← Perfil do primeiro especialista
│   ├── config.yaml
│   ├── SOUL.md
│   ├── AGENTS.md
│   └── operacional/
│       └── DIARIO.md          ← Diário pessoal (NÃO tem ESTADO-DA-EQUIPE)
│
├── agente2/               ← Perfil do segundo especialista
│   ├── config.yaml
│   └── operacional/
│       └── DIARIO.md
│
└── agente3/               ← Perfil do terceiro especialista
    └── operacional/
        └── DIARIO.md
```

### Por que essa estrutura?

- **Cada agente tem seu DIARIO.md** porque cada um precisa registrar suas
  próprias atividades. Se todos escrevessem no mesmo arquivo, haveria conflitos
  de escrita concorrente.

- **Só o orquestrador tem ESTADO-DA-EQUIPE.md** porque ele é o ponto central
  de coordenação. Se cada agente pudesse alterar o estado da equipe, um poderia
  sobrescrever a alteração do outro. O orquestrador é o "gatekeeper" do estado.

- **Dentro de `operacional/`** para manter separado dos arquivos de
  configuração do perfil (config.yaml, SOUL.md, etc.) e facilitar backup,
  sincronização e auditoria.

- **Dentro de `~/.hermes/profiles/`** (não no diretório do projeto) porque
  a memória operacional pertence ao **agente**, não ao projeto. Um agente pode
  trabalhar em múltiplos projetos e precisa da mesma memória em todos.

---

## 4. O DIARIO.md — Diário de Bordo Pessoal

### Template Explicado Campo a Campo

```markdown
# Diário de Operação — {NOME_DO_AGENTE}

## Registro de Atividades Diárias

| Data       | Wave/Turno | ID da Task | Atividades / Commits                     | Status |
|------------|------------|------------|------------------------------------------|--------|
| DD/MM/AAAA | Manhã/Tarde/Noite | task_XX | Descrição do que fez + hash do commit | ⬜/🟢/✅ |
```

**Explicação de cada campo:**

| Campo | O que é | Exemplo | Obrigatório? |
|-------|---------|---------|:------------:|
| **Data** | Data no formato DD/MM/AAAA | `06/06/2026` | Sim |
| **Wave/Turno** | Período do dia (manhã, tarde, noite) ou wave do plano | `Manhã (Wave 1)` | Sim |
| **ID da Task** | Identificador da task conforme PLANO.md | `task_03` | Sim |
| **Atividades/Commits** | Descrição concisa do que foi feito + hash do commit | `Corrige rota de login. Commit: a1b2c3d` | Sim |
| **Status** | Estado atual da task | ⬜ = Pendente, 🟢 = Em andamento, ✅ = Concluída | Sim |

### Exemplo Real de Entrada preenchida

```markdown
# Diário de Operação — agente1

## Registro de Atividades Diárias

| Data       | Wave/Turno | ID da Task | Atividades / Commits                     | Status |
|------------|------------|------------|------------------------------------------|--------|
| 06/06/2026 | Manhã (W1) | task_01    | Início: correção de rota de login.       | 🟢     |
| 06/06/2026 | Manhã (W1) | task_01    | Rota corrigida em AuthController.php.    | ✅     |
|            |            |            | Commit: a1b2c3d4e5f6. Testes: 47/47.    |        |
| 06/06/2026 | Tarde (W2) | task_03    | Início: refatorar módulo de relatórios.  | 🟢     |
| 06/06/2026 | Tarde (W2) | task_03    | Estrutura refatorada. Aguardando review. | 🟢     |

## Observações
- task_01 teve um bug inesperado no middleware de autenticação.
  Foi necessário debug extra de 30 min.
- task_03 depende de aprovação do modelo de dados (task_02).
```

### Quando Atualizar

O agente DEVE atualizar o DIARIO.md nestes momentos:

```
┌─────────────────────────────────────────────────────────┐
│                   INÍCIO DA SESSÃO                       │
│  • Leia o DIARIO.md (para saber onde parou)             │
│  • Leia o ESTADO-DA-EQUIPE.md (para saber o contexto)   │
│  • Adicione uma linha no DIARIO: "Início da sessão"     │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                   AO INICIAR UMA TASK                    │
│  • Adicione no DIARIO:                                   │
│    | DATA | WAVE | task_XX | Início: descrição | 🟢     │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                   AO CONCLUIR UMA TASK                   │
│  • Adicione no DIARIO:                                   │
│    | DATA | WAVE | task_XX | O que fez + commit | ✅    │
│  • Atualize o ESTADO-DA-EQUIPE.md (se orquestrador)     │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                   AO PAUSAR UMA TASK                     │
│  • Adicione no DIARIO:                                   │
│    | DATA | WAVE | task_XX | Pausado: motivo | 🟢       │
│  • Atualize o ESTADO-DA-EQUIPE.md (se orquestrador)     │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                   FIM DA SESSÃO                          │
│  • Verifique se o DIARIO reflete o estado atual         │
│  • Adicione observações se necessário                   │
└─────────────────────────────────────────────────────────┘
```

### O Que Registrar (Regra de Ouro)

Registre **tudo que outro agente (ou você no futuro) precisaria saber**:

- **Horário de início/fim** de cada atividade
- **Hash do commit** associado a cada conclusão
- **Decisões técnicas** importantes (por que escolheu X em vez de Y)
- **Problemas encontrados** e como foram resolvidos
- **Dependências** entre tasks (task_03 depende de task_01)
- **Observações** que possam ajudar na próxima sessão

### Quando NÃO atualizar

- Não precisa registrar cada comando individual
- Não precisa copiar o código inteiro — apenas o resumo e o hash
- Não precisa atualizar para tarefas de leitura/análise (mas registre que leu)

---

## 5. O ESTADO-DA-EQUIPE.md — Quadro Compartilhado

### Template Explicado

```markdown
# Estado da Equipe — Controle Global

**Orquestrador:** {NOME_DO_ORQUESTRADOR}
**Timezone:** {FUSO_HORARIO}

## Painel de Agentes

| Agente      | Tipo          | Status Operacional | Última Atividade |
|-------------|---------------|--------------------|------------------|
| orquestrador| Orquestrador  | [Ativo]            | Iniciou task_01  |
| agente1     | Especialista  | [Em Execução 🟢]  | task_03 — 80%    |
| agente2     | Especialista  | [Aguardando 🟡]   | task_04 — pronto |
| agente3     | Especialista  | [Bloqueado 🔴]    | Aguarda API key  |

## Controle de Tasks do Dia

| Task ID | Descrição              | Responsável  | Wave | Status     | Commit Hash |
|---------|------------------------|--------------|------|------------|-------------|
| task_01 | Corrigir rota login    | agente1      | W1   | ✅         | a1b2c3d     |
| task_02 | Modelo de relatórios   | agente2      | W1   | 🟢         | —           |
| task_03 | Refatorar relatórios   | agente1      | W2   | 🟢         | —           |
| task_04 | Testes de integração   | agente3      | W2   | 🟡         | —           |

## Tarefas Bloqueadas

| Task | Responsável | Motivo do Bloqueio | Desbloqueio |
|------|-------------|--------------------|-------------|
| task_04 | agente3 | Aguardando chave de API externa | Solicitar ao comandante |

## Decisões do Dia

- 06/06 — Definido que task_03 só começa após task_01 + task_02
- 06/06 — Decidido usar DuckDB em vez de PostgreSQL para relatórios

## Alertas

- ⚠️ agente3 aguardando autorização para nova chave de API
```

### Os 4 Estados

| Estado | Símbolo | Significado | Quando usar |
|--------|:-------:|-------------|-------------|
| Em Execução | 🟢 | Agente está trabalhando ativamente nesta task | Ao iniciar uma task |
| Aguardando | 🟡 | Agente concluiu mas aguarda algo (review, dependência) | Ao concluir mas com blocker externo |
| Bloqueado | 🔴 | Não consegue avançar — precisa de intervenção | Quando algo externo impede o progresso |
| Concluída | ✅ | Task finalizada e auditada | Após auditoria bem-sucedida |

### Quem Mantém o ESTADO-DA-EQUIPE.md

**Regra absoluta: apenas o orquestrador altera este arquivo.**

```
Por quê? Imagine 3 agentes tentando alterar o mesmo arquivo simultaneamente:
   agente1 escreve: "task_01 🟢" (no meio do arquivo)
   agente2 escreve: "task_02 ✅" (no meio do arquivo)
   agente3 escreve: "task_03 🔴" (no meio do arquivo)

RESULTADO: O último que escrever SOBRESCREVE os outros.
           Dados perdidos. Estado inconsistente.
```

O fluxo correto é:

```
agente1: "Task_01 concluída! Commit: a1b2c3d"
    │
    ▼
orquestrador: Lê a mensagem, verifica, ATUALIZA o ESTADO-DA-EQUIPE.md
    │
    ▼
orquestrador: task_01 marcada como ✅ no ESTADO-DA-EQUIPE.md
    │
    ▼
agente2: Lê ESTADO-DA-EQUIPE.md, vê que task_01 ✅, inicia task_02
```

### Como Fazer Check-in e Check-out

**CHECK-IN** (ao começar a trabalhar):

1. Leia o `ESTADO-DA-EQUIPE.md` para ver se não há conflitos
2. Se for o orquestrador: altere seu status para `🟢` e adicione a task
3. Se for agente comum: apenas atualize seu `DIARIO.md`

```
Exemplo de check-in (orquestrador atualiza):
| agente1 | Especialista | [Em Execução 🟢] | task_03 — iniciado |
```

**CHECK-OUT** (ao terminar ou pausar):

1. Se for o orquestrador: altere o status para ✅ ou 🟡
2. Adicione o hash do commit no ESTADO-DA-EQUIPE.md
3. Atualize seu `DIARIO.md` com o resumo do que fez

```
Exemplo de check-out (orquestrador atualiza):
| task_01 | Corrigir rota login | agente1 | W1 | ✅ | a1b2c3d |
```

---

## 6. A Descoberta Crítica: System Prompt vs AGENTS.md

Esta é a descoberta mais importante de todo o sistema. Foi o "momento eureka"
que transformou um sistema que não funcionava em um sistema que funciona.

### A Diferença Fundamental

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│  system_prompt  ≠  AGENTS.md  ≠  Skills                            │
│                                                                     │
│  Eles são carregados em momentos diferentes e com FORÇAS diferentes │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

#### system_prompt (config.yaml)

- **O que é:** A definição do "eu" do agente. É a primeira mensagem do sistema.
- **Quando é carregado:** No início de CADA conversa, antes de qualquer input.
- **Força:** MÁXIMA. O modelo vê isso PRIMEIRO e com maior peso de atenção.
- **Onde fica:** Dentro do `config.yaml` do perfil Hermes.
- **Tamanho típico:** 200-500 caracteres.

```yaml
# ANTES da descoberta — system_prompt genérico (fraca):
system_prompt: "Você é o Radiante agente1. Fale em pt-BR."
```

```yaml
# DEPOIS da descoberta — system_prompt com protocolo (forte):
system_prompt: "Você é o Radiante agente1.
  Fale em pt-BR.

  ### PROTOCOLO DIARIO — OBRIGATÓRIO
  Você TEM dois arquivos operacionais que DEVE usar em TODA sessão:
  1. DIARIO.md (seu diário pessoal): LEIA no início, ATUALIZE ao concluir/pausar.
  2. ESTADO-DA-EQUIPE.md (memória coletiva): LEIA antes de QUALQUER ação."
```

#### AGENTS.md

- **O que é:** Um documento markdown com regras operacionais, menções do Slack,
  mapas de equipe, etc.
- **Quando é carregado:** Como contexto adicional, junto com outros arquivos.
- **Força:** MÉDIA. O modelo lê, mas pode ignorar se o system_prompt não
  referenciar explicitamente.
- **Onde fica:** No diretório do perfil Hermes.
- **Tamanho típico:** 5K-15K caracteres.

#### Skills

- **O que é:** Módulos de habilidade com procedimentos passo a passo.
- **Quando é carregado:** Quando invocado pelo nome ou por trigger.
- **Força:** BOA (quando carregado), mas pode ser esquecido se não for triggerado.
- **Onde fica:** Em `skills/` no diretório do perfil.
- **Tamanho típico:** 2K-5K caracteres cada, ~29K totais.

### O Problema do AGENTS.md de 11K Caracteres

Antes da descoberta, as regras do DIARIO estavam enterradas no AGENTS.md:

```
AGENTS.md (~11.000 caracteres):
─────────────────────────────────
  Linha 1-50:   Menções reais do Slack (IDs de usuário)
  Linha 51-120:  Regras de separação de documentos
  Linha 121-180: Checklist pré-commit
  Linha 181-220: <— AQUI ESTAVA A REGRA DO DIARIO (enterrada!)
  Linha 221-350: Instruções de commit e push
  ...

RESULTADO: O modelo NÃO PRIORIZAVA a regra do DIARIO.
           Ela era apenas mais 1 entre 11.000 caracteres de instrução.
```

O modelo de linguagem funciona com **atenção**. Quanto mais texto, mais o
modelo precisa "decidir" o que é importante. Regras enterradas no meio de
documentos grandes são **sistematicamente ignoradas** porque:

1. O **início** do contexto recebe mais peso (primacy effect)
2. O **final** do contexto recebe menos peso (recency effect)
3. O **meio** do contexto é onde a atenção mais cai

As regras do DIARIO estavam no **meio** de um AGENTS.md de 11K chars.
Resultado: ninguém as seguia.

### Por que o System Prompt é o Único Lugar Confiável

O system_prompt é:

1. **A PRIMEIRA coisa que o modelo vê** — primacy effect máximo
2. **O mais curto** — 200-500 chars contra 11K-29K dos outros documentos
3. **Definido no config.yaml** — não precisa ser "encontrado" entre skills
4. **Referenciado pelo próprio modelo** — o modelo "sabe quem é" pelo prompt

```
Visualização da hierarquia de atenção do modelo:
─────────────────────────────────────────────────

  system_prompt  ←  ATENÇÃO MÁXIMA (primeiro, mais curto, define o "eu")
       ↓
    AGENTS.md   ←  ATENÇÃO MÉDIA (referenciado pelo system_prompt)
       ↓
     Skills     ←  ATENÇÃO BOA (carregado sob demanda)
       ↓
   Contexto     ←  ATENÇÃO VARIÁVEL (depende do tamanho e posição)
```

### A Correção: Injetar o Protocolo no System Prompt

A solução foi **adicionar o protocolo operacional diretamente no system_prompt**
de cada perfil, com **caminhos ABSOLUTOS**.

#### Template do system_prompt com o protocolo

```yaml
system_prompt: "Você é {NOME_DO_AGENTE}.
  Fale em pt-BR.

  ### PROTOCOLO DIARIO — OBRIGATÓRIO

  Você TEM dois arquivos operacionais que DEVE usar em TODA sessão:

  1. DIARIO.md (seu diário pessoal)
     Local: /Users/seu-usuario/.hermes/profiles/{NOME_DO_AGENTE}/operacional/DIARIO.md
     LEIA no início de cada sessão
     ATUALIZE ao concluir/pausar uma task

  2. ESTADO-DA-EQUIPE.md (memória coletiva)
     Local: /Users/seu-usuario/.hermes/profiles/orquestrador/operacional/ESTADO-DA-EQUIPE.md
     LEIA antes de QUALQUER ação
     ATUALIZE ao iniciar/concluir/pausar (apenas se for o orquestrador)

  REGRA ABSOLUTA: Se você NÃO leu o ESTADO-DA-EQUIPE antes de agir,
  você pode estar atropelando outro agente. Sempre leia primeiro.
"
```

### ⚠️ A IMPORTÂNCIA de Usar Caminhos ABSOLUTOS

Isso merece destaque porque foi uma das causas raiz do sistema não funcionar.

#### O que acontece com caminhos relativos

```yaml
# ERRADO — caminho relativo:
system_prompt: "... LEIA operacional/DIARIO.md..."
```

Cada agente resolve caminhos relativos a partir do **project dir** (o diretório
de trabalho configurado em `cwd` no config.yaml), que normalmente é algo como
`/Users/usuario/Dev/meu-projeto/`. O resultado:

```
Agente tenta abrir: /Users/usuario/Dev/meu-projeto/operacional/DIARIO.md
Mas o arquivo está em: /Users/usuario/.hermes/profiles/agente1/operacional/DIARIO.md

RESULTADO: Arquivo não encontrado. Agente desiste. Protocolo ignorado.
```

#### O que acontece com `~/` (tilde)

```yaml
# ERRADO — tilde não expandido:
system_prompt: "... LEIA ~/.hermes/profiles/agente1/operacional/DIARIO.md..."
```

O tilde (`~/`) é uma convenção do **shell**, não do sistema de arquivos. O
Hermes Agent (ou qualquer ferramenta em Python) pode ou não expandir o tilde
dependendo de como implementa a leitura de arquivos. Muitas vezes, o modelo
tenta `open('~/.hermes/...')` que literalmente procura uma pasta chamada `~`.

```
Agente tenta abrir: ~/.hermes/profiles/agente1/operacional/DIARIO.md
O sistema vê: literalmente "~" como nome de pasta

RESULTADO: FileNotFoundError. Agente desiste.
```

#### O formato CORRETO

```yaml
# CERTO — caminho absoluto completo:
system_prompt: "... LEIA /Users/seu-usuario/.hermes/profiles/agente1/operacional/DIARIO.md..."
```

Sempre use o caminho completo, começando de `/`. Não confie em tilde, nem em
caminhos relativos, nem em variáveis de ambiente.

---

## 7. As 3 Camadas de Enforce

O sistema de memória operacional funciona em 3 camadas, cada uma com uma força
diferente de "convencimento" do modelo:

```
                    FORÇA
                      │
                      ▲
                      │
                ┌─────┴──────┐
                │             │
         ┌──────┴──────┐     │
         │  System     │  MÁXIMA  ← Definição do "eu"
         │  Prompt     │     │     O modelo lê PRIMEIRO
         └──────┬──────┘     │
                │            │
         ┌──────┴──────┐     │
         │  AGENTS.md  │  MÉDIA   ← Regras operacionais
         │             │     │     O modelo lê como contexto
         └──────┬──────┘     │
                │            │
         ┌──────┴──────┐     │
         │  MEMORY.md  │  BOA     ← Memória entre sessões
         │  (Hermes)   │     │     Persistência automática
         └─────────────┘     │
                      │
                      ▼
                    TEMPO
```

### Tabela Comparativa

| Camada | O que é | Quando é carregada | Força | Tamanho típico | Confiabilidade |
|--------|---------|-------------------|:-----:|:--------------:|:--------------:|
| **System Prompt** | Definição do "eu" do agente | Início de toda sessão | Máxima | 200-500 chars | 95%+ |
| **AGENTS.md** | Regras operacionais, menções, mapa da equipe | No startup, como contexto adicional | Média | 5K-15K chars | 60-70% |
| **MEMORY.md** | Memória persistente automática do Hermes | Via ferramenta `memory` do Hermes | Boa | Variável | 70-80% |

### Camada 1: System Prompt (Força Máxima)

**O que é:** A primeira mensagem que o modelo recebe. Define quem ele é, como
deve agir e quais são suas prioridades absolutas.

**Força:** Máxima — porque:
- É o **primeiro** token no contexto (primacy effect)
- É **curto** e direto (200-500 chars)
- Define a **identidade** do agente ("Você é X...")
- O modelo não precisa "escolher" entre ler isso ou não — é parte do setup

**Como configurar:**
```yaml
# Em ~/.hermes/profiles/{agente}/config.yaml
agent:
  system_prompt: "Você é o agente1. Fale em pt-BR.

### PROTOCOLO DIARIO — OBRIGATÓRIO
Você TEM dois arquivos operacionais...

1. DIARIO.md
   Local: /Users/usuario/.hermes/profiles/agente1/operacional/DIARIO.md
   LEIA no início, ATUALIZE ao concluir/pausar.

2. ESTADO-DA-EQUIPE.md
   Local: /Users/usuario/.hermes/profiles/orquestrador/operacional/ESTADO-DA-EQUIPE.md
   LEIA antes de qualquer ação."
```

**Nunca confie apenas nela para tudo** — o system_prompt é forte mas limitado
em tamanho. Use para o protocolo essencial (o "o quê" e "quando"), e deixe os
detalhes (o "como") para o AGENTS.md e Skills.

### Camada 2: AGENTS.md (Força Média)

**O que é:** Documento markdown com regras operacionais detalhadas, menções
do Slack, hierarquia da equipe, etc.

**Força:** Média — porque:
- É carregado como contexto adicional, não como definição do "eu"
- Pode ser grande (>10K chars), o que dilui a atenção
- O modelo pode "esquecer" de consultá-lo se o system_prompt não referenciar

**Como usar efetivamente:**
```markdown
# AGENTS.md — Meu Agente

## Regras Operacionais (referenciadas pelo system_prompt)

### DIARIO.md — Detalhes de Preenchimento
- Use formato de tabela: | Data | Wave | Task | Atividade | Status |
- Status possíveis: ⬜ Pendente, 🟢 Em andamento, ✅ Concluída
- Sempre inclua hash do commit em atividades concluídas

### ESTADO-DA-EQUIPE.md — Como Atualizar
- Apenas o ORQUESTRADOR altera este arquivo
- Ao check-in: mude status para 🟢
- Ao check-out: mude para ✅ ou 🟡

### Menções Reais do Slack
- Orquestrador: <@U1234567890>
- agente1: <@U0987654321>
```

### Camada 3: MEMORY.md (Força Boa)

**O que é:** O Hermes Agent tem um sistema de memória interno (tool `memory`)
que persiste informações-chave entre sessões automaticamente.

**Força:** Boa — porque:
- É persistente entre sessões (não precisa ser recriado)
- O modelo pode consultar e atualizar via ferramenta dedicada
- Mas depende do modelo **lembrar de usar** a ferramenta memory

**Como usar:**
```
O Hermes Agent automaticamente salva memórias usando a tool "memory".
O arquivo MEMORY.md fica em ~/.hermes/profiles/{agente}/memories/MEMORY.md
e é gerenciado pelo próprio sistema, não manualmente.
```

---

## 8. Como Implementar — Passo a Passo

Siga estas 7 etapas para implementar o Sistema de Memória Operacional no seu time.

### Etapa 1: Criar o Diretório `operacional/` para Cada Agente

```bash
# Para CADA agente do seu time, crie a pasta operacional:
mkdir -p ~/.hermes/profiles/orquestrador/operacional
mkdir -p ~/.hermes/profiles/agente1/operacional
mkdir -p ~/.hermes/profiles/agente2/operacional
mkdir -p ~/.hermes/profiles/agente3/operacional
```

### Etapa 2: Criar o DIARIO.md com o Template

Crie o arquivo `DIARIO.md` dentro de `operacional/` para cada agente:

```bash
# Template para cada agente
cat > ~/.hermes/profiles/orquestrador/operacional/DIARIO.md << 'TEMPLATE'
# Diário de Operação — orquestrador

## Registro de Atividades Diárias

| Data | Wave/Turno | ID da Task | Atividades / Commits | Status |
|------|------------|------------|----------------------|--------|
|      |            |            |                      | ⬜/🟢/✅ |
TEMPLATE

# Repita para cada agente, trocando o nome
```

### Etapa 3: Criar o ESTADO-DA-EQUIPE.md (Apenas Orquestrador)

```bash
cat > ~/.hermes/profiles/orquestrador/operacional/ESTADO-DA-EQUIPE.md << 'TEMPLATE'
# Estado da Equipe — Controle Global

**Orquestrador:** orquestrador
**Timezone:** America/Campo_Grande

## Painel de Agentes

| Agente | Tipo | Status Operacional | Última Atividade |
|--------|------|--------------------|------------------|
| orquestrador | Orquestrador | [Ativo] | — |
| agente1 | Especialista | [Pendente] | — |
| agente2 | Especialista | [Pendente] | — |

## Controle de Tasks do Dia

| Task ID | Descrição | Responsável | Wave | Status | Commit Hash |
|---------|-----------|-------------|------|--------|-------------|
| | | | | ⬜/🟢/✅ | |

## Tarefas Bloqueadas

| Task | Responsável | Motivo do Bloqueio | Desbloqueio |
|------|-------------|--------------------|-------------|

## Decisões do Dia

## Alertas
TEMPLATE
```

### Etapa 4: Injetar o Protocolo no System Prompt de CADA Perfil

Esta é a etapa mais crítica. Você precisa adicionar o protocolo DIARIO no
`system_prompt` de cada config.yaml.

#### Identifique o formato de escape YAML de cada perfil

Cada perfil pode ter um formato diferente para o system_prompt. Verifique:

```bash
for p in orquestrador agente1 agente2 agente3; do
  echo "=== $p ==="
  grep "system_prompt:" ~/.hermes/profiles/$p/config.yaml | head -1
done
```

Os formatos comuns são:

| Formato | Aparência | Como identificar |
|---------|-----------|-----------------|
| Multilinha | `system_prompt: \|` + linhas indentadas | Usa pipe seguido de linhas |
| Barra simples | `system_prompt: "texto\\n"` | `\n` dentro das aspas |
| Barra dupla | `system_prompt: "texto\\\\n"` | `\\n` dentro das aspas |
| Continuation | `system_prompt: "texto\\\n  \\ continuação"` | `\` no final das linhas |

#### Adicione o protocolo (exemplo para formato multilinha)

```yaml
# ANTES:
agent:
  system_prompt: |
    Você é o agente1. Fale em pt-BR.

# DEPOIS:
agent:
  system_prompt: |
    Você é o agente1. Fale em pt-BR.

    ### PROTOCOLO DIARIO — OBRIGATÓRIO

    Você TEM dois arquivos operacionais que DEVE usar em TODA sessão:

    1. DIARIO.md (seu diário pessoal)
       Local: /Users/seu-usuario/.hermes/profiles/agente1/operacional/DIARIO.md
       LEIA no início de cada sessão
       ATUALIZE ao concluir/pausar uma task

    2. ESTADO-DA-EQUIPE.md (memória coletiva)
       Local: /Users/seu-usuario/.hermes/profiles/orquestrador/operacional/ESTADO-DA-EQUIPE.md
       LEIA antes de QUALQUER ação
       ATUALIZE ao iniciar/concluir/pausar (apenas se for o orquestrador)

    REGRA ABSOLUTA: leia o ESTADO-DA-EQUIPE antes de agir.
```

### Etapa 5: Configurar o Timezone

Timezone vazio ou ausente faz o Hermes usar UTC, resultando em horários
errados nos registros do DIARIO.

```bash
# Verificar timezone atual de cada perfil
grep "timezone:" ~/.hermes/profiles/*/config.yaml

# Se vazio ou ausente, configure para seu fuso local:
# Para Mato Grosso do Sul (UTC-4, sem horário de verão):
sed -i '' 's/timezone: .*/timezone: America\/Campo_Grande/' \
  ~/.hermes/profiles/*/config.yaml

# Para São Paulo (UTC-3, com horário de verão):
sed -i '' 's/timezone: .*/timezone: America\/Sao_Paulo/' \
  ~/.hermes/profiles/*/config.yaml

# Se a chave não existir, adicione manualmente no config.yaml
# dentro da seção agent:
#   timezone: America/Campo_Grande
```

### Etapa 6: Reiniciar os Gateways

Mudanças no system_prompt e timezone só entram em vigor após reiniciar o
gateway do Hermes:

```bash
# Para CADA perfil:
hermes --profile orquestrador gateway run --replace
hermes --profile agente1 gateway run --replace
hermes --profile agente2 gateway run --replace
hermes --profile agente3 gateway run --replace

# Ou em um loop:
for p in orquestrador agente1 agente2 agente3; do
  echo "Reiniciando gateway do $p..."
  hermes --profile $p gateway run --replace 2>/dev/null
done
```

### Etapa 7: Verificar

```bash
# 1. Verificar se o protocolo está no system_prompt
echo "=== Verificação PROTOCOLO DIARIO ==="
for p in orquestrador agente1 agente2 agente3; do
  if grep -q "PROTOCOLO DIARIO" ~/.hermes/profiles/$p/config.yaml; then
    echo "$p: ✅ OK"
  else
    echo "$p: ❌ AUSENTE"
  fi
done

# 2. Verificar timezone
echo ""
echo "=== Verificação TIMEZONE ==="
grep "timezone:" ~/.hermes/profiles/*/config.yaml

# 3. Verificar DIARIOs existem
echo ""
echo "=== Verificação DIARIO.md ==="
for p in orquestrador agente1 agente2 agente3; do
  if [ -f ~/.hermes/profiles/$p/operacional/DIARIO.md ]; then
    lines=$(wc -l < ~/.hermes/profiles/$p/operacional/DIARIO.md)
    echo "$p: ✅ DIARIO.md existe ($lines linhas)"
  else
    echo "$p: ❌ DIARIO.md não encontrado"
  fi
done

# 4. Verificar ESTADO-DA-EQUIPE.md (apenas orquestrador)
echo ""
echo "=== Verificação ESTADO-DA-EQUIPE.md ==="
if [ -f ~/.hermes/profiles/orquestrador/operacional/ESTADO-DA-EQUIPE.md ]; then
  echo "orquestrador: ✅ ESTADO-DA-EQUIPE.md existe"
else
  echo "orquestrador: ❌ ESTADO-DA-EQUIPE.md não encontrado"
fi

# 5. Verificar gateways rodando
echo ""
echo "=== Gateways ativos ==="
ps aux | grep "hermes.*gateway" | grep -v grep
```

---

## 9. Benefícios Comprovados

### Antes da Correção do System Prompt

Os agentes **tentavam** seguir o protocolo mas falhavam porque:

1. **Caminhos relativos/errados** — tentavam abrir arquivos que não existiam
2. **System_prompt sem menção ao DIARIO** — o modelo não priorizava a regra
3. **Timezone UTC** — registravam horários errados, gerando confusão

Exemplo do que acontecia:

```
Agente (antes da correção):
  "Vou registrar no DIARIO.md conforme o protocolo...
   Local: operacional/DIARIO.md
   Tentando abrir: /Users/usuario/Dev/projeto/operacional/DIARIO.md
   ERRO: Arquivo não encontrado. Pulando registro."

RESULTADO: DIARIO ficava VAZIO. Protocolo não funcionava.
```

### Depois da Correção do System Prompt

Os agentes passaram a seguir o protocolo corretamente:

```
Agente (depois da correção):
  "Vou registrar no DIARIO.md conforme o protocolo...
   Local: /Users/usuario/.hermes/profiles/agente1/operacional/DIARIO.md
   ✓ Arquivo encontrado! Registrando entrada..."

RESULTADO: DIARIO preenchido. ESTADO-DA-EQUIPE atualizado. Time sincronizado.
```

### Dados de Uso

| Métrica | Antes | Depois | Melhoria |
|---------|:-----:|:------:|:--------:|
| DIARIOs preenchidos | 0/6 | 4/6+ | ∞ |
| ESTADO-DA-EQUIPE atualizado | Nunca | Regularmente | ∞ |
| Agentes consultando estado antes de agir | Raramente | Sempre | Significativa |
| Conflitos entre agentes | Frequentes | Raros | Redução drástica |
| Tempo perdido com retrabalho | Alto | Mínimo | Redução de ~70% |

### Por que Funciona

1. **O protocolo está no system_prompt** — o modelo vê primeiro, é curto, define
   seu comportamento essencial
2. **Caminhos absolutos** — o modelo encontra os arquivos sem erro
3. **Timezone correto** — os horários nos registros são confiáveis
4. **3 camadas de enforce** — system_prompt (máxima) + AGENTS.md (média) +
   MEMORY.md (boa) se reforçam mutuamente
5. **Responsabilidade clara** — orquestrador mantém ESTADO-DA-EQUIPE, cada
   agente mantém seu DIARIO

---

## 10. Referências

### Documentos Relacionados

| Documento | O que contém | Localização |
|-----------|-------------|-------------|
| Guia de Configuração Inicial | Setup completo de perfis Hermes | `docs/01-CONFIGURACAO-INICIAL.md` |
| Ciclo Diário | 6 fases do workflow operacional | `docs/02-CICLO-DIARIO.md` |
| Gestão de Contexto Operacional | Skill de manutenção do contexto | `skills/operacao/gestao-contexto-operacional/SKILL.md` |
| Lições Operacionais 06/06/2026 | Diagnóstico completo dos problemas | `skills/.../references/licoes-06-06-2026.md` |

### Comandos Rápidos

```bash
# Verificar se o protocolo está ativo em todos os perfis
grep "PROTOCOLO DIARIO" ~/.hermes/profiles/*/config.yaml

# Verificar DIARIOs
for p in orquestrador agente1 agente2; do
  wc -l ~/.hermes/profiles/$p/operacional/DIARIO.md
done

# Reiniciar todos os gateways
for p in orquestrador agente1 agente2; do
  hermes --profile $p gateway run --replace
done

# Diagnóstico de timezone
grep "timezone:" ~/.hermes/profiles/*/config.yaml

# Diagnóstico de gateway
cat ~/.hermes/profiles/orquestrador/gateway.pid
ps aux | grep hermes | grep -v grep
```

### Perguntas Frequentes

**P: E se o agente se recusar a seguir o protocolo?**
R: Verifique se o PROTOCOLO DIARIO está no system_prompt (Etapa 7). Se estiver,
o problema pode ser o tamanho do contexto — tente encurtar o restante do
system_prompt para dar mais peso ao protocolo.

**P: Um agente especialista pode ler o ESTADO-DA-EQUIPE.md?**
R: Sim! Ele DEVE ler. Mas ele NÃO DEVE alterar. Só o orquestrador escreve
no ESTADO-DA-EQUIPE.md. Se um especialista tentar alterar, o orquestrador
irá corrigir na próxima auditoria.

**P: E se dois orquestradorers alterarem o ESTADO-DA-EQUIPE ao mesmo tempo?**
R: Isso não deve acontecer — só existe UM orquestrador. Se você tem múltiplos
times, cada time tem seu próprio orquestrador e seu próprio ESTADO-DA-EQUIPE.md.

**P: Preciso criar o DIARIO.md manualmente para cada agente?**
R: Sim, na primeira vez. Depois, o próprio agente mantém o arquivo
automaticamente seguindo o protocolo do system_prompt.

**P: O que acontece se o DIARIO.md ficar muito grande?**
R: Faça uma compactação: mova o conteúdo antigo para um arquivo de archive
(`operacional/archive/DIARIO-AAAA-MM-DD.md`) e mantenha apenas os registros
recentes no DIARIO.md principal.

---

> **Resumo:** O Sistema de Memória Operacional resolve o problema fundamental
> da falta de memória entre sessões de agentes de IA. A chave do sucesso foi
> descobrir que o **system_prompt** (não o AGENTS.md nem as skills) é o único
> lugar onde regras operacionais críticas são efetivamente seguidas pelo modelo.
> Com DIARIO.md pessoal, ESTADO-DA-EQUIPE.md compartilhado, caminhos absolutos
> e timezone configurado, o time multi-agente opera de forma coordenada,
> auditável e sem retrabalho.
