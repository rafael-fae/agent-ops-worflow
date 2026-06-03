# Regra de Limite de Memória (02/06/2026)

## Contexto

Limite de memória permanente ampliado de 2.200 → 10.000 caracteres para todos os 14 agentes (Mac + OVH).

## Regra

Quando a memória permanente atingir **95%** (9.500/10.000 caracteres):

1. **Parar** a task atual
2. **Reportar** ao {{COMMANDER}}: `⚠️ Memória em 95% (X/10000). Sugestões de consolidação abaixo.`
3. **Listar** entradas candidatas a remoção ou consolidação (mais antigas, menos usadas, redundantes)
4. **Aguardar** decisão do {{COMMANDER}} antes de modificar qualquer entrada

## NUNCA

- Remover entradas sem autorização do {{COMMANDER}}
- Ignorar o alerta e continuar — memória cheia = perda de informações
- Consolidar entradas sem avisar

## Configuração

```yaml
# ~/.hermes/profiles/<agente>/config.yaml
memory:
  memory_enabled: true
  memory_char_limit: 10000
```

## Trade-off

- Limite maior (10K+) = mais contexto persistente, mas ocupa tokens em todo turno
- Limite menor (2K) = enche rápido, perde informações
- 10.000 é o ponto ideal — 5x mais que antes, sem impacto de desempenho
