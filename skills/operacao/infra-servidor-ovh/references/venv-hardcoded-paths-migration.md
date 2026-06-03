# Python .venv — Hardcoded Paths After Migration

## Problem
When a Python `.venv` directory is rsynced from one server to another with a different
`$HOME` path (e.g., `{{COMMANDER_HOME}}/` → `{{COMMANDER_HOME}}fae/`), the venv appears to work
interactively but fails when spawned by PM2 or systemd.

## Root Cause
The venv's `bin/activate` script embeds the full path:
```bash
VIRTUAL_ENV='{{COMMANDER_HOME}}/projects/pycode-cerebro/scripts/.venv'
```

While interactive shells resolve the venv correctly via the `activate` script, process
managers (PM2, systemd) may not propagate `VIRTUAL_ENV`, causing the Python interpreter
to look for packages in the wrong location.

## Symptom
```python
ModuleNotFoundError: No module named 'fastapi'
```
...even though `pip list` shows fastapi installed in the venv.

## Solution: Recreate the venv on the new server

```bash
rm -rf .venv
uv venv --python 3.12
source .venv/bin/activate
uv sync  # or uv pip install <packages>
```

This creates a venv with paths rooted at the new `$HOME`.

## Alternative: Fix the activate script in-place
```bash
sed -i 's|{{COMMANDER_HOME}}/|{{COMMANDER_HOME}}fae/|g' .venv/bin/activate
sed -i 's|{{COMMANDER_HOME}}/|{{COMMANDER_HOME}}fae/|g' .venv/pyvenv.cfg
```
Less reliable — prefer full recreation with `uv venv`.

## Detection
```bash
source .venv/bin/activate
echo $VIRTUAL_ENV
# If this shows the OLD user's home path, the venv is broken
```
