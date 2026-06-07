---
name: macos-privacy-permissions
title: Permissões de Privacidade macOS para Agentes
description: Configura e diagnostica permissões de privacidade no macOS (acesso a disco, câmera, microfone, acessibilidade, automação) necessárias para agentes Hermes que interagem com o sistema.
category: operacao
---

<!--
Arquivo criado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
-->

# Permissões de Privacidade macOS para Agentes

## Gatilho

- Primeira execução de um agente Hermes no macOS
- Comandos de terminal falham com "Permission denied" sem motivo aparente
- Scripts de automação (cron, launchd) não conseguem acessar arquivos
- Agente não consegue usar ferramentas como OpenCode, Claude Code ou Gemini CLI

---

## Pré-requisitos

- macOS 14+ (Sonoma/Sequoia)
- Acesso de administrador (sudo) para conceder permissões
- Terminal.app ou iTerm2 como aplicativo de terminal

---

## Procedimento Passo a Passo

### 1. Diagnóstico de Permissões

Execute o diagnóstico para identificar permissões faltantes:

```bash
# Verificar permissões de disco total (Full Disk Access)
sqlite3 ~/Library/Application\\ Support/com.apple.TCC/TCC.db \\
  "SELECT client, service, auth_value FROM access WHERE service LIKE 'kTCCService%'" \\
  2>/dev/null || echo "Sem acesso ao banco TCC (pode ser necessário SIP desabilitado)"

# Verificar acesso a pastas protegidas
ls ~/Desktop/ 2>&1 | head -1
ls ~/Downloads/ 2>&1 | head -1
ls ~/Documents/ 2>&1 | head -1

# Verificar acesso a arquivos de outros aplicativos
cat ~/Library/Preferences/com.apple.Terminal.plist 2>&1 | head -3
```

### 2. Permissões Essenciais para Agentes

Abra **System Settings > Privacy & Security** e configure:

#### Acesso Total ao Disco (Full Disk Access)
```
Aplicativos necessários:
- Terminal (ou iTerm2)
- /usr/libexec/sshd-keygen-wrapper (se usar SSH)
- Qualquer IDE que o agente use (VS Code, Cursor, etc.)
```

**Por que:** Agentes precisam ler/escrever arquivos em ~/Library, ~/Desktop, e outras pastas protegidas.

#### Acessibilidade (Accessibility)
```
Aplicativos necessários:
- Terminal (ou iTerm2)
- OpenCode CLI (se usado via atalhos de teclado)
```

**Por que:** Necessário para controle de interface via AppleScript ou atalhos.

#### Automação (Automation)
```
Permitir que Terminal controle:
- System Events
- Finder
- Qualquer aplicativo que o agente automatize
```

**Por que:** Permite que scripts do agente controlem outros aplicativos via AppleScript/JXA.

#### Arquivos e Pastas (Files and Folders)
```
- Terminal → ~/Desktop, ~/Downloads, ~/Documents
- Terminal → ~/Dev (ou diretório de trabalho do agente)
```

**Por que:** Acesso granular a pastas específicas sem precisar de Full Disk Access.

### 3. Concessão via Linha de Comando (macOS 14+)

```bash
# NOTA: A partir do macOS 14, a Apple restringiu a concessão via TCC direto.
# Use a UI de System Settings como método primário.

# Método alternativo (requer SIP desabilitado):
# sudo tccutil reset All com.apple.Terminal
# sudo tccutil reset AppleEvents com.apple.Terminal
```

### 4. Script de Verificação Pós-Configuração

```bash
#!/bin/bash
# check-mac-permissions.sh — Verifica permissões do agente no macOS

echo "=== Diagnóstico de Permissões macOS ==="

# Teste 1: Acesso a pastas do usuário
echo ""
echo "[1] Acesso a pastas protegidas:"
for dir in ~/Desktop ~/Downloads ~/Documents ~/Library; do
  if ls "$dir" &>/dev/null 2>&1; then
    echo "  ✅ $dir"
  else
    echo "  ❌ $dir — SEM ACESSO"
  fi
done

# Teste 2: Acesso a .hermes
echo ""
echo "[2] Acesso a diretório Hermes:"
if [ -d ~/.hermes ]; then
  if ls ~/.hermes &>/dev/null 2>&1; then
    echo "  ✅ ~/.hermes"
  else
    echo "  ❌ ~/.hermes — SEM ACESSO (Full Disk Access?)"
  fi
else
  echo "  ⚠️ ~/.hermes não encontrado"
fi

# Teste 3: Acesso a processo
echo ""
echo "[3] Acesso a lista de processos:"
if ps aux &>/dev/null 2>&1; then
  echo "  ✅ ps aux"
else
  echo "  ❌ ps aux — SEM ACESSO (Accessibility?)"
fi

# Teste 4: AppleScript (Automação)
echo ""
echo "[4] AppleScript (Automação):"
if osascript -e 'tell application "Finder" to get name of every process' &>/dev/null 2>&1; then
  echo "  ✅ AppleScript: Finder acessível"
else
  echo "  ❌ AppleScript: Finder NÃO acessível (Automation?)"
fi

echo ""
echo "=== Diagnóstico concluído ==="
```

### 5. Solução de Problemas Comuns

| Problema | Causa Provável | Solução |
|----------|---------------|---------|
| `Operation not permitted` ao ler arquivo | Full Disk Access ausente | Adicione Terminal em System Settings > Privacy > Full Disk Access |
| AppleScript retorna erro -1743 | Automação não permitida | Adicione Terminal em System Settings > Privacy > Automation |
| cron/launchd não consegue acessar Home | cron não tem TCC permissão | Use `launchctl` ou migre para `~/.launchd/` |
| `open` command falha silenciosamente | Files and Folders restrito | Conceda permissão específica para a pasta |

---

## Verificação

- [ ] Terminal tem Full Disk Access
- [ ] Terminal tem Accessibility (se necessário)
- [ ] Automation: Terminal pode controlar System Events e Finder
- [ ] Files and Folders: diretório de trabalho do agente está liberado
- [ ] Script de diagnóstico não reporta erros
- [ ] Agente consegue ler/escrever em todas as pastas do projeto

---

## Armadilhas

- **SIP vs TCC:** Mesmo com SIP desabilitado, o TCC ainda pode bloquear acesso
- **Reboot necessário:** Algumas permissões (especialmente Full Disk Access) só fazem efeito após restart do Terminal
- **VS Code vs Terminal:** Permissões são por aplicativo — conceder ao Terminal não cobre o VS Code
- **Atualizações do macOS:** Atualizações do sistema podem resetar permissões — verifique após cada update
- **Múltiplos Terminais:** iTerm2 e Terminal.app têm permissões separadas

---

## Referências

- `~/Library/Application Support/com.apple.TCC/TCC.db` — Banco de dados de permissões
- `man tccutil` — Ferramenta de linha de comando TCC
- `system_profiler SPHardwareDataType` — Verificar status SIP
