#!/usr/bin/env python3
"""OpenCode Go API Key Fallback — testa chave ativa, swap automático se 429."""
import os, sys, json, time, urllib.request, urllib.error

ENV_FILE = os.environ.get("HERMES_ENV_FILE", "{{COMMANDER_HOME}}/hermes-roshar/profiles/dalinar/.env")
STATUS_FILE = os.environ.get("HERMES_STATUS_FILE", "{{COMMANDER_HOME}}/hermes-roshar/profiles/dalinar/.opencode_status.json")
HEALTH_URL = "https://opencode.ai/zen/go/v1/models"
TIMEOUT = 10

def load_env(path):
    if not os.path.exists(path): return {}
    env = {}
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line: continue
            k, _, v = line.partition("=")
            env[k.strip()] = v.strip()
    return env

def test_key(ak):
    if not ak or ak == "***": return False
    try:
        req = urllib.request.Request(HEALTH_URL, headers={"Authorization": f"Bearer {ak}"}, method="GET")
        with urllib.request.urlopen(req, timeout=TIMEOUT) as r: return r.status == 200
    except urllib.error.HTTPError as e:
        return False if e.code == 429 else False
    except: return False

def swap_to_key2():
    env = load_env(ENV_FILE)
    k2 = env.get("OPENCODE_GO_API_KEY_2") or os.environ.get("OPENCODE_GO_API_KEY_2", "")
    if not k2 or k2 == "***": return False
    with open(ENV_FILE) as f: content = f.read()
    lines = content.split("\n")
    nl, sw = [], False
    for line in lines:
        s = line.strip()
        if s.startswith("OPENCODE_GO_API_KEY=") and not s.startswith("OPENCODE_GO_API_KEY_2"):
            nl.append(f"OPENCODE_GO_API_KEY={k2}"); sw = True
        else: nl.append(line)
    if sw:
        with open(ENV_FILE, "w") as f: f.write("\n".join(nl))
        return True
    return False

def check():
    env = load_env(ENV_FILE)
    k1 = os.environ.get("OPENCODE_GO_API_KEY") or env.get("OPENCODE_GO_API_KEY")
    k2 = os.environ.get("OPENCODE_GO_API_KEY_2") or env.get("OPENCODE_GO_API_KEY_2")
    status = {}
    if os.path.exists(STATUS_FILE):
        try:
            with open(STATUS_FILE) as f: status = json.load(f)
        except: status = {}
    if status.get("locked"): return None, None
    if test_key(k1) if k1 else False: return "OPENCODE_GO_API_KEY", k1
    swap_to_key2()
    env = load_env(ENV_FILE)
    k2 = os.environ.get("OPENCODE_GO_API_KEY_2") or env.get("OPENCODE_GO_API_KEY_2")
    if test_key(k2) if k2 else False: return "OPENCODE_GO_API_KEY_2", k2
    status["locked"] = True; status["locked_at"] = time.time()
    os.makedirs(os.path.dirname(STATUS_FILE), exist_ok=True)
    with open(STATUS_FILE, "w") as f: json.dump(status, f, indent=2)
    return None, None

if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "check"
    if cmd == "check":
        k, v = check()
        print(f"ACTIVE_KEY={k}" if k else "NO_ACTIVE_KEY")
        sys.exit(0 if k else 1)
    elif cmd == "unlock":
        if os.path.exists(STATUS_FILE): os.remove(STATUS_FILE); print("Unlocked.")
        else: print("Not locked.")
    else: print(f"Usage: check|unlock"); sys.exit(1)
