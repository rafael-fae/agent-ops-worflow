# Multi-Cadeira Resource Scheduling — Exemplo Real (29/05/2026)

## Contexto

{{COMMANDER}} solicitou diferencial sobre o Dontus: agendamento odontológico com suporte a **2 cadeiras simultâneas** (2 salas no consultório Oeste). O Dontus não modela cadeiras como recurso — apenas `Profissional + Data/Hora`.

## Arquitetura Produzida ({{BACKEND_ENGINEER}} + {{FRONTEND_ENGINEER}})

### Modelo de Dados

```python
class Sala(models.Model):
    clinica = models.ForeignKey(Clinica, on_delete=models.CASCADE)
    nome = models.CharField(max_length=50)       # "Sala 1", "Sala 2"
    ativo = models.BooleanField(default=True)

class Cadeira(models.Model):
    sala = models.ForeignKey(Sala, on_delete=models.CASCADE, related_name='cadeiras')
    nome = models.CharField(max_length=50)       # "Cadeira A", "Cadeira Principal"
    ativo = models.BooleanField(default=True)

class Agendamento(models.Model):
    # campos existentes (patient, professional, date, time, duration, status)
    cadeira = models.ForeignKey(Cadeira, null=True, blank=True, on_delete=models.PROTECT)
```

### Constraints de Conflito

| # | Regra | Bloqueio |
|---|-------|:--------:|
| 1 | Mesma cadeira + horário sobreposto | BLOQUEADO |
| 2 | Mesmo profissional + horário sobreposto | BLOQUEADO |
| 3 | Cadeira ocupada → indisponível no drag | Visual |

### UX ({{FRONTEND_ENGINEER}})

- **FullCalendar resourceTimeline** — suporte nativo a `editable: true` + `eventDrop`
- 2 colunas por profissional (Cadeira 1 | Cadeira 2) por dia
- Drag-and-drop entre colunas = reagendamento com troca de recurso
- Bloqueio de horário como `event` com `display: background` (visualmente distinto)
- Validação inline de conflito no frontend (antes do backend)

### Casos de Uso Validados

| Cenário | Funciona? | Lógica |
|---------|:---------:|--------|
| {{COMMANDER}} Cadeira 1 + Thaísa Cadeira 2, mesmo horário | ✅ | Profissionais diferentes, cadeiras diferentes |
| {{COMMANDER}} 9-10h C1 + {{COMMANDER}} 9:30-10:30h C2 | ❌ | Mesmo profissional em 2 lugares |
| {{COMMANDER}} 9-10h C1 + Thaísa 9-10h C1 | ❌ | Mesma cadeira ocupada |
| {{COMMANDER}} 9-11h Sala 1 (longo) + Thaísa Cadeira 2 | ✅ | Recursos independentes |

## Lições para o Modo 3 (Second-Pass Review)

1. **{{BACKEND_ENGINEER}} (Arquitetura) e {{FRONTEND_ENGINEER}} (UI) trabalharam em paralelo** — a arquiteta definiu constraints lógicas, a designer validou viabilidade de UI. Sem sobreposição, sem conflito.
2. **FullCalendar resourceTimeline** foi a ponte entre backend e frontend — a {{FRONTEND_ENGINEER}} identificou que o modelo Sala→Cadeira→Agendamento casa nativamente com o plugin de resource scheduling.
3. **Validação dos casos de uso reais do consultório** — a {{BACKEND_ENGINEER}} testou 4 cenários concretos contra as constraints, eliminando ambiguidade.
4. **Orquestrador ({{ORCHESTRATOR}}) apenas consolidou** — não precisou entrar na discussão técnica. O padrão de delegar para especialistas funcionou.
