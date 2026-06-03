# GitHub Device Flow — Non-Interactive Token Auth

## When to Use

When `gh auth refresh` fails in non-interactive environments (no TTY, no browser auto-open, agent sessions), use the OAuth Device Flow directly. This gives you a `user_code` that can be authorized from any browser.

## The Technique

### 1. Request Device Code

```python
import urllib.request, urllib.parse, json

data = urllib.parse.urlencode({
    "client_id": "178c6fc778ccc68e1d6a",  # GitHub CLI's public client_id
    "scope": "admin:public_key,gist,read:org,repo,workflow"
}).encode()

req = urllib.request.Request(
    "https://github.com/login/device/code",
    data=data,
    headers={"Accept": "application/json", "Content-Type": "application/x-www-form-urlencoded"},
    method="POST"
)

with urllib.request.urlopen(req) as resp:
    result = json.loads(resp.read())
    # result['user_code'] — code to enter in browser (e.g., 'C5A5-763D')
    # result['verification_uri'] — URL to open (https://github.com/login/device)
    # result['device_code'] — use this for polling
    # result['expires_in'] — seconds until expiry (typically 899 = ~15 min)
    # result['interval'] — polling interval in seconds (typically 5)
```

### 2. Authorize in Browser

Open `verification_uri` in any browser where you're logged into GitHub. Enter the `user_code` and click Authorize.

### 3. Poll for Access Token

```python
import time

token_data = urllib.parse.urlencode({
    "client_id": "178c6fc778ccc68e1d6a",
    "device_code": device_code,
    "grant_type": "urn:ietf:params:oauth:grant-type:device_code"
}).encode()

while True:
    req = urllib.request.Request(
        "https://github.com/login/oauth/access_token",
        data=token_data,
        headers={"Accept": "application/json", "Content-Type": "application/x-www-form-urlencoded"},
        method="POST"
    )
    with urllib.request.urlopen(req) as resp:
        token_result = json.loads(resp.read())
    
    if "access_token" in token_result:
        print("Token obtained.")
        break
    elif token_result.get("error") == "authorization_pending":
        time.sleep(interval)
    else:
        raise Exception(f"Auth failed: {token_result}")
```

### 4. Update gh with New Token

```bash
echo "NEW_TOKEN" | gh auth login --with-token
```

Or inject directly into git remote:
```bash
git remote set-url origin "https://oauth2:NEW_TOKEN@github.com/USER/REPO.git"
```

## Pitfalls

- The `client_id` `178c6fc778ccc68e1d6a` is GitHub CLI's — it works for device flow but the resulting token is scoped to `gh`. For programmatic use, register your own OAuth App.
- If the browser where you authorize is NOT logged into GitHub, you'll need credentials. The device flow doesn't bypass login — it only decouples authorization from the requesting machine.
- Token obtained via device flow replaces the existing `gh` token. Back up the old one if needed: `gh auth token > ~/.gh_token_backup`.
