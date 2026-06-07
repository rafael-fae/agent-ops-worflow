# Recursos Dontus — Guia de Consulta para Implementação

## Acesso ao Dontus Ao Vivo

| Campo | Valor |
|---|---|
| URL | `https://sistema.dontus.com.br` |
| ID Dontus | `{{DONTUS_CLINICA_ID}}` |
| Usuário | `{{COMMANDER}}` |
| Senha | `{{DONTUS_PASSWORD}}` |
| ID Clínica | `1` (Oeste Odontologia — São Gabriel do Oeste/MS) |

**Regra máxima:** APENAS CONSULTA. NUNCA modificar dados no Dontus ao vivo.

## DontusClient (API Python)

Local: OVH `/var/www/dontus_app/dontus/client.py` (690 linhas)

```python
import sys
sys.path.insert(0, "/var/www/dontus_app")
from dontus.client import DontusClient

client = DontusClient("https://sistema.dontus.com.br", "{{DONTUS_CLINICA_ID}}", "{{COMMANDER}}", "{{DONTUS_PASSWORD}}", 1)
client.login()
# 13 endpoints implementados + 21+ descobertos
```

## Obsidian Vault (Engenharia Reversa)

Local: `~/Dev/obsidian/10_Projects/{{PROJECT_SLUG}}/` (40 arquivos .md)

**⚠️ READ ONLY.** Nunca modificar. Para documentação ativa, usar `{{PROJECT_PATH}}/docs/`.

Conteúdo: modelos de dados, regras de negócio, mapeamento de telas, fluxos de usuário — tudo extraído do Dontus real.

## Quando usar cada fonte

| Dúvida | Fonte |
|---|---|
| Modelos, campos, regras de negócio | Obsidian vault + `docs/prd/modulos/` |
| UI, fluxos visuais, comportamento | Dontus ao vivo (navegador) |
| Validações, formatos, endpoints | DontusClient (API) |
| Cores, labels, posição de botões | Dontus ao vivo (inspecionar) |

## Uso em Delegações ({{COMMANDER}} 02/06/2026)

Ao delegar tasks que envolvam consulta ao Dontus, incluir na mensagem de delegação:
1. URL: https://sistema.dontus.com.br
2. Credenciais: {{COMMANDER}} / {{DONTUS_PASSWORD}} / {{DONTUS_CLINICA_ID}}
3. Proibição explícita: NUNCA modificar dados
4. Escopo: qual módulo/perfil navegar (ex: Admin, Dentista, Financeiro)
5. DontusClient via {{OVH_SSH_COMMAND}} (se relevante)
