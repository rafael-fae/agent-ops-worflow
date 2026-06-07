# Verificação Cruzada de Relatórios entre Agentes

> Protocolo para quando um agente reporta existência/conteúdo de arquivos que conflitam com a realidade em disco ou no git remote.

## Gatilho

Dois ou mais agentes reportam estados contraditórios sobre a existência de arquivos no vault/repositório. Um agente afirma que arquivos existem com N linhas e conteúdo específico; verificação independente mostra que não existem.

## Causa Raiz

Agentes em ambientes diferentes (Mac vs OVH) podem ver filesystems diferentes. Mas o **git remote é a verdade única**. Se um arquivo não aparece em `git ls-tree -r` em nenhuma branch, ele não existe de forma versionada — independentemente do que um agente reporte.

## Protocolo de Verificação (3 Camadas)

### Camada 1: Filesystem Local

```bash
ls -la /path/to/file.md
find /path/to/repo -name "arquivo.md"
```

### Camada 2: Git Remote (TODAS as branches)

```bash
git fetch origin
for branch in develop main wave/YYYY-MM-DD-*; do
  echo "=== $branch ==="
  git ls-tree -r origin/$branch --name-only | grep -i "arquivo"
done
```

### Camada 3: Cross-Environment (se aplicável)

```bash
ssh user@ovh-server "ls -la /path/to/file.md"
```

## Protocolo de Resolução (Fabricação Confirmada)

Quando as 3 camadas retornam vazio e o agente insiste que o arquivo existe com detalhes específicos (contagem de linhas, tabelas de conteúdo):

### Passo 1: Confrontar com evidências

Apresentar a tabela de verificação:

| Verificação | Resultado |
|-------------|-----------|
| `ls -la` (local) | :x: Não existe |
| `git ls-tree origin/develop` | :x: Zero matches |
| `git ls-tree origin/wave/...` | :x: Zero matches |
| `git ls-tree origin/main` | :x: Zero matches |
| `find` (filesystem) | :x: Vazio |

### Passo 2: Oferecer duas opções (sem acusação)

**Opção A)** Os arquivos existem no teu filesystem mas não foram commitados.
→ `git add` + `git commit` + `git push` IMEDIATAMENTE.

**Opção B)** O relatório foi fabricado (alucinação).
→ Assumir o erro. Gerar o artefato real agora. Commit. Push.

### Passo 3: Manter agentes dependentes em stand-by

Agentes que dependem do artefato ausente NÃO devem prosseguir. Instrução explícita: "stand-by mantido. Bloqueio confirmado. Não execute nada."

## Regra de Ouro

> **Tolerância zero a dados fabricados.** Se um agente reporta `wc -l` ou conteúdo específico de um arquivo que não existe em git, isso é uma violação grave. O corretivo é imediato.

## Exemplo Real 1: Falsa Fabricação — Orquestrador Errou o Repositório (31/05/2026)

{{AUDITOR}} reportou que `docs/INDEX.md` (427 linhas) e `docs/refinamentos/auditorias/AUDITORIA-CONSISTENCIA-POS-REORG.md` (184 linhas) existiam, com tabelas detalhadas de broken links e órfãos. {{ORCHESTRATOR}} verificou `ls -la` no vault Obsidian (`~/Dev/obsidian/`) e `git ls-tree` no repo obsidian — ambos vazios. Acusou {{AUDITOR}} de fabricação.

**Erro:** Os arquivos estavam em `{{PROJECT_SLUG}}/docs/` (fonte ativa), não no vault Obsidian (histórico read-only). A DOC ARCHITECTURE define dois repositórios distintos. A {{AUDITOR}} estava CORRETA — os arquivos existiam exatamente onde deveriam, com as contagens reportadas. O erro foi do orquestrador, que verificou no repo errado.

**Lição:** Antes de acusar fabricação, verificar TODOS os repositórios onde o arquivo pode estar. A hierarquia é: `{{PROJECT_SLUG}}/docs/` (ativo) → `obsidian/` (histórico). Verificar o repo ativo PRIMEIRO.

## Exemplo Real 2: Fabricação Confirmada (arquivo hipotético)

Se um agente reporta um arquivo que não existe em NENHUM repositório (nem `{{PROJECT_SLUG}}/`, nem `obsidian/`, nem git remote de nenhum dos dois), aí sim o diagnóstico de fabricação se aplica. Seguir o Protocolo de Resolução.
