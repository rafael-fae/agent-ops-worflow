# CLI Tools Usage {{GIT_OPS}}s — Claude Opus, Gemini 3.1 Pro, OpenCode

Discovered during {{PROJECT_NAME}} planning session (28-29 May 2026).

## Claude Code (`~/.local/bin/claude`)

### Non-Interactive Mode
```bash
# {{GIT_OPS}}: pipe prompt file, capture output
cat prompt.md | ~/.local/bin/claude --print --dangerously-skip-permissions --effort max --max-budget-usd 5

# This writes the output DIRECTLY via Claude's file tool (not to stdout).
# The file is saved at the path Claude chooses, usually docs/<name>.md in cwd.
# The stdout redirect (> file) only captures the summary line.
```

### Critical Flags
| Flag | Purpose |
|------|---------|
| `--print` | Non-interactive (required for headless) |
| `--dangerously-skip-permissions` | Allows file writes and tool execution without confirmation |
| `--effort max` | Maximum quality |
| `--max-budget-usd N` | Spending cap per call ($3-5 typical) |

### Bash Backtick Trap
```bash
# ❌ FAILS — backticks inside -p are interpreted by bash shell
~/.local/bin/claude -p "Use \`\`\`python blocks\`\`\`" --print
# bash sees backticks and tries to execute "python blocks" as a command

# ✅ WORKS — write prompt to file and pipe
cat prompt.md | ~/.local/bin/claude --print --dangerously-skip-permissions

# ✅ ALSO WORKS — avoid backticks entirely in prompt
~/.local/bin/claude -p "Use code blocks with indentation"
```

### Output Behavior
- With `--dangerously-skip-permissions`: Claude WRITES files directly to disk (e.g., `docs/ODONTOGRAMA-INTERATIVO.md`). Stdout only gets a one-line summary.
- **Your stdout redirect (`> output.md`) is a fallback**, not the primary output channel.
- To get content in a specific file, either: (a) name it in the prompt, (b) let Claude decide where to save, or (c) use `cat prompt.md | claude --print > capture.md` and accept that Claude's file is the rich version.

## Gemini CLI (`/Users/{{COMMANDER}}fae/.local/share/mise/installs/node/24.13.1/bin/gemini`)

### Non-Interactive Mode
```bash
# {{GIT_OPS}}: foreground with generous timeout
GEMINI_CLI_TRUST_WORKSPACE=true gemini -m "gemini-3.1-pro-preview" -p "PROMPT" > output.md
```

### Critical Flags
| Flag | Purpose |
|------|---------|
| `-m "model-name"` | Model selection |
| `-p "PROMPT"` | Prompt text |
| `GEMINI_CLI_TRUST_WORKSPACE=true` | Required for non-interactive (bypass trusted-folder check) |

### Available Models (on this API key)
| Model | Status |
|-------|--------|
| `gemini-3.1-pro-preview` | ✅ Works (2M context) |
| `gemini-3.1-flash-preview` | ❌ 404 Not Found (name incorrect or unavailable) |
| `gemini-2.0-flash` | ❌ Not Found |
| `gemini-2.5-flash-preview` | ❌ Not Found |

### Output Behavior
- Gemini writes to STDOUT normally (unlike Claude which saves files)
- **Background mode (`background=true`) does NOT flush stdout** — file stays 0 bytes until process fully completes, but may never complete
- **Foreground mode with `timeout=300`** is required
- The file is available atomically when the process exits

## OpenCode CLI (`opencode run`)

- Primarily designed for interactive/TUI use
- `opencode run "prompt"` enters interactive mode on the Mac
- Non-interactive usage not yet reliable via CLI flags
- Default model: `glm-5.1` (z.ai configured)

## Summary: When to Use Which

| Task | Tool | Why |
|------|------|-----|
| Broad architectural review | Gemini 3.1 Pro | 2M context, fast generation |
| Deep code-level detail | Claude Opus | Higher quality, writes files directly |
| Refinement of existing plans | Gemini 3.1 Pro | Good balance of speed and quality |
| Deep-dive on single topic | Claude Opus | Best for complex technical docs |
| Quick research/summaries | Gemini 3.1 Pro | Faster, cheaper |
