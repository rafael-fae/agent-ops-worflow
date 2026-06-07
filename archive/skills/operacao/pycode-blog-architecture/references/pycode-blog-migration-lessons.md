# Migração PyCode Blog — Lições Aprendidas (30-31/05/2026)

## Dados Históricos

Na migração OVH antigo → novo, o diretório `data/historico/` (808 KB, 20 arquivos `grupo_*.md`) NÃO foi copiado. O servidor novo tinha apenas `hoje.md` atual.

**Sintoma:** Blog aparecia "vazio" — sem resumos de dias anteriores, página inicial sem conteúdo.

**Correção:** Copiar todo o diretório `data/historico/` do servidor antigo.

```bash
# Do servidor novo, puxar do antigo
rsync -avz {{COMMANDER}}@IP_ANTIGO:{{COMMANDER_HOME}}/projects/pycode-cerebro/data/historico/ \
  {{COMMANDER_HOME}}fae/projects/pycode-cerebro/data/historico/
```

## Scripts de Automação

### fechamento_diario.sh + sintetizador.py

Estavam rodando no servidor antigo via **PM2 cron** (`55 22 * * *`). Na migração:

1. **PM2 cron NÃO funciona com processo `stopped`** — o cron só dispara se o processo estiver `online`. Após executar uma vez, o script termina e o PM2 marca como `stopped`, e o cron não dispara novamente.

2. **Solução:** Migrar do PM2 cron para **crontab do sistema**:

```bash
# crontab -e
55 22 * * * {{COMMANDER_HOME}}fae/projects/pycode-cerebro/scripts/fechamento_diario.sh \
  >> {{COMMANDER_HOME}}fae/.pm2/logs/fechamento-pycode-out.log 2>&1
```

3. **Adaptações necessárias nos scripts:**
   - Paths: `{{COMMANDER}}` → `{{COMMANDER}}fae`
   - `.env` source: {{ORCHESTRATOR}} (Mac) não existe na OVH → usar `.env` do Aragorn
   - Modelo: `deepseek-v4-pro` → configurável
   - Deploy: `npx quartz build` → `pm2 restart pycode-blog` (Express, não Quartz)
   - Venv: remover `source activate` (usar Python do sistema)

### Dependências Python

```bash
sudo apt install -y python3-dotenv python3-requests
```

## Checklist de Verificação Pós-Migração

- [ ] `data/historico/` copiado com todos os `grupo_*.md`
- [ ] `hoje.md` contém mensagens do dia atual
- [ ] `sintetizador.py` adaptado (paths, .env, modelo)
- [ ] `fechamento_diario.sh` adaptado e no crontab
- [ ] Dependências Python instaladas (dotenv, requests)
- [ ] Blog renderiza: `curl -s http://127.0.0.1:8080/`
- [ ] Posts API retorna dados: `curl -s http://127.0.0.1:8080/api/posts`
- [ ] Cache-busting: versão no `base.ejs` incrementada

## Referências

- `pycode-blog-architecture` skill — arquitetura completa
- `infra-servidor-ovh` skill — servidores e migração
