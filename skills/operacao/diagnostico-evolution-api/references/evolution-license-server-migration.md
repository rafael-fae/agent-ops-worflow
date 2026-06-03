# Evolution API — License Re-activation After Server Migration

## Symptom
After migrating PostgreSQL data to a new server, `fetchInstances` returns:
```json
{"error":"service not activated","code":"LICENSE_REQUIRED",...}
```
Even though the database was copied intact and the license was active on the old server.

## Root Cause
The Evolution API `instance_id` is derived from a machine fingerprint. A new server produces a different `instance_id`, which invalidates the existing license. The migrated database contains the old license key, which is rejected.

## Solution
1. Route the domain to the new server (Cloudflare Tunnel switch)
2. Access `https://evolution.oesteodontologia.com.br/manager/login`
3. Log in with Google to re-activate the license
4. **Instances must be recreated** — the new `instance_id` also invalidates existing WhatsApp instances

## Post-Activation Verification
```bash
curl -s -H "apikey: <KEY>" -H "Host: evolution.oesteodontologia.com.br" \
  http://127.0.0.1:80/instance/fetchInstances
# Expected: [] (empty array = license active, but instances lost)
# If still LICENSE_REQUIRED: activation failed or domain not routed to new server
```

## Critical Timing
The `/manager/login` page only works when the domain resolves to the NEW server. This means:
1. Cloudflare Tunnel MUST be switched to new server first
2. Then activate license
3. Then recreate WhatsApp instances

During the gap between switch and activation, the Evolution API returns LICENSE_REQUIRED for all endpoints except `/manager/login`.
