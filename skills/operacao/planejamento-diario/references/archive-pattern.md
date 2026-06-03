# Archive {{GIT_OPS}} — Código Não Autorizado

**Estabelecido:** 31/05/2026  
**Contexto:** {{PROJECT_NAME}} — agentes implementaram código durante fase de planejamento

## Quando usar

Quando código foi implementado sem autorização explícita do {{COMMANDER}} durante fase de planejamento.

## Procedimento

1. **Auditar**: listar todos os arquivos .py, classificar como autorizado vs não autorizado
2. **Criar diretório**: `apps/_archive/` e subdiretórios conforme necessário
3. **Mover com git**: `git mv apps/modulo apps/_archive/modulo` (preserva histórico)
4. **Documentar**: criar `docs/planejamento/ARCHIVE-<DATA>.md` com:
   - Lista do que foi arquivado
   - Motivo (código sem autorização)
   - Gap previsto para reimplementação na Fase 2
   - Referência à auditoria completa
5. **Commit**: mensagem clara referenciando o documento de archive

## Exemplo ({{PROJECT_NAME}}, 31/05/2026)

```bash
mkdir -p apps/_archive/agenda
git mv apps/crc apps/_archive/crc
git mv apps/financeiro apps/_archive/financeiro
git mv apps/orcamento apps/_archive/orcamento
git mv apps/agenda/statemachine.py apps/_archive/agenda/
git mv apps/agenda/signals.py apps/_archive/agenda/
git mv apps/agenda/exceptions.py apps/_archive/agenda/
```

Resultado: 19 arquivos em `_archive/`, 40 arquivos autorizados preservados.

## Regras

- Sempre usar `git mv` (preserva blame/log)
- Documentar no mesmo commit
- Não apagar — arquivar (pode ser útil como referência)
- Atualizar `docs/INDEX.md` com o novo diretório `_archive/`
