# Estratégia de Migração OVH via Cloudflare Tunnel

## Princípio

O Cloudflare Tunnel (`cloudflared`) conecta OUT para a edge da Cloudflare. O túnel é identificado por um UUID (ex: `5f54a07f-b9ce-41bc-a776-2fe4172b6cfd`). As rotas (hostname → origin service) são definidas no Cloudflare Zero Trust dashboard, NÃO no `/etc/cloudflared/config.yml` local.

**Vantagem para migração:** Ambos os servidores (antigo e novo) podem ser autorizados no mesmo túnel. Ao parar o `cloudflared` no antigo e iniciar no novo, o tráfego migra instantaneamente — zero mudança de DNS, zero propagação.

## Sequência de Switch

1. Preparar novo servidor completamente (todos os serviços rodando e respondendo em localhost)
2. Parar `cloudflared` no servidor antigo:
   ```bash
   sudo systemctl stop cloudflared
   ```
3. Iniciar `cloudflared` no servidor novo:
   ```bash
   sudo systemctl start cloudflared
   ```
4. Cloudflare detecta o novo endpoint em segundos
5. Verificar cada subdomínio:
   ```bash
   curl -sI "https://oesteodontologia.com.br" | head -5
   curl -sI "https://dashboard.oesteodontologia.com.br" | head -5
   curl -sI "https://evolution.oesteodontologia.com.br" | head -5
   curl -sI "https://{{BLOG_URL}}" | head -5
   ```

## Rollback

Instantâneo — basta inverter o switch:
```bash
# No novo: sudo systemctl stop cloudflared
# No antigo: sudo systemctl start cloudflared
```

## Requisitos

- O arquivo `/etc/cloudflared/config.yml` deve ser idêntico em ambos os servidores
- O arquivo `/etc/cloudflared/credentials.json` (ou token) deve ser copiado do antigo para o novo
- O tunnel ID no config.yml deve corresponder ao túnel ativo no dashboard
- As rotas NO DASHBOARD devem apontar para serviços que existem no novo servidor nas mesmas portas

## Pitfalls

- **Portas diferentes:** Se um serviço mudar de porta no novo servidor, a rota no dashboard precisa ser atualizada. Isso requer acesso ao Cloudflare Zero Trust dashboard.
- **cloudflared token:** O token de autenticação do túnel (`credentials.json`) é sensível. Copiar via SSH seguro.
- **Dois cloudflared ativos:** Se ambos os servidores rodarem cloudflared com o mesmo tunnel ID simultaneamente, o Cloudflare faz load-balance entre eles. Isso pode causar comportamento intermitente. Para migração limpa, pare o antigo ANTES de iniciar o novo.
- **Cloudflare Access:** Se houver políticas de Access configuradas (ex: SSH), elas continuam funcionando independentemente do servidor de origem.
