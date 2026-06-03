# Task 01 — Mapear skills existentes + copiar para files/skills/raw/

**Wave:** 1 (Mapeamento)
**Prioridade:** 🔴
**Ferramenta:** Gemini CLI
**Depende de:** —

---

## Contexto

Temos skills Hermes armazenadas em `~/.hermes/profiles/dalinar/skills/`. Elas contêm
referências específicas ao time Roshar (Dalinar, Navani, Kaladin, etc.), ao projeto
Oeste Gestão, e ao Rafael. Precisamos copiá-las para a pasta `files/` para trabalhar
as versões sanitizadas sem tocar nos originais.

---

## Instruções

1. Listar todas as skills disponíveis:
   ```
   ls -la ~/.hermes/profiles/dalinar/skills/*/
   ```

2. Para cada skill, copiar a pasta completa para:
   ```
   agent-ops-workflow/files/skills/raw/<NOME-DA-SKILL>/
   ```
   Incluindo SKILL.md, references/, templates/, scripts/, assets/

3. Ao final, verificar:
   ```
   tree agent-ops-workflow/files/skills/raw/ -L 3
   ```

4. Criar um arquivo `MANIFEST.md` em `files/skills/` listando:
   - Nome de cada skill
   - Categoria (operacao, devops, security)
   - Número de arquivos
   - Observações (ex: "contém refs a Oeste Gestão")

---

## Checklist

- [ ] Todas as skills listadas e copiadas
- [ ] Estrutura de diretórios preservada (SKILL.md + subpastas)
- [ ] MANIFEST.md criado com inventário completo
- [ ] NENHUM arquivo original foi modificado
- [ ] Copiado para agent-ops-workflow/files/skills/raw/

---

## Arquivos relevantes

| Origem | Destino |
|--------|---------|
| ~/.hermes/profiles/dalinar/skills/*/ | files/skills/raw/*/ |

---

## Restrições

- NUNCA modificar arquivos em ~/.hermes/profiles/dalinar/skills/ (originais)
- Apenas cópia + listagem — sem edição
- files/ NÃO será commitada no final

---

## Conclusão

`TBD`
