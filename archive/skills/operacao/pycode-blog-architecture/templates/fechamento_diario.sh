#!/bin/bash
# fechamento_diario.sh — Executado via PM2 cron (55 22 * * *)
# Pipeline: sintetiza → aguarda persistência → rotaciona → restart blog
#
# Adaptar paths conforme o ambiente:
#   Servidor novo: {{COMMANDER_HOME}}fae/...
#   Servidor antigo: {{COMMANDER_HOME}}/...

echo ">>> Iniciando Fechamento Diário do Cérebro Pycode..."

DATA_HOJE=$(TZ=America/Sao_Paulo date +%d-%m-%Y)
DIR_HISTORICO="{{COMMANDER_HOME}}fae/projects/pycode-cerebro/data/historico"

# 0. Reset do buffer cumulativo (grupo.txt) — prevenção de intoxicação
if [ -f "$DIR_HISTORICO/grupo.txt" ]; then
    truncate -s 0 "$DIR_HISTORICO/grupo.txt"
    echo ">>> grupo.txt resetado."
fi

# 1. PRIMEIRO: Sintetiza o conteúdo do dia (hoje.md ainda tem os dados reais)
echo ">>> Sintetizando mensagens do dia..."
cd {{COMMANDER_HOME}}fae/projects/pycode-cerebro/scripts
python3 {{COMMANDER_HOME}}fae/projects/pycode-cerebro/scripts/sintetizador.py

# 2. Aguarda 5 minutos para garantir que a síntese foi concluída e os arquivos escritos
echo ">>> Aguardando 5 minutos para garantir persistência..."
sleep 300

# 3. SÓ DEPOIS: Rotaciona o arquivo do dia (backup + novo hoje.md vazio)
if [ -s "$DIR_HISTORICO/hoje.md" ]; then
    mv "$DIR_HISTORICO/hoje.md" "$DIR_HISTORICO/grupo_$DATA_HOJE.md"
    touch "$DIR_HISTORICO/hoje.md"
    echo "Arquivo rotacionado para grupo_$DATA_HOJE.md"
else
    echo "Nenhuma mensagem capturada hoje."
fi

# 4. Restart do blog para cache-busting (Express, não Quartz)
echo ">>> Reiniciando PyCode Blog..."
pm2 restart pycode-blog

echo ">>> Fechamento concluído com sucesso!"
