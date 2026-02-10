# Daemon Deploy Profile (Internal/Private)

This profile maps internal PKI helper outputs to `wbabd serve` TLS/mTLS runtime env vars.

## 1. Bootstrap Internal PKI
Generate CA/server/client material:

```bash
scripts/security/daemon-pki.sh init
```

Default output dir:
- `.wbab/daemon-pki`

Override output dir:

```bash
WBABD_PKI_DIR=/path/to/pki scripts/security/daemon-pki.sh init
```

Expected files:
- `ca.crt.pem`
- `ca.key.pem`
- `server.crt.pem`
- `server.key.pem`
- `client.crt.pem`
- `client.key.pem`

## 2. Start `wbabd serve` with TLS+mTLS
Minimum internal/private secure profile:

```bash
WBABD_AUTH_MODE=token \
WBABD_API_TOKEN_FILE=.wbab/daemon-token.txt \
WBABD_TLS_CERT_FILE=.wbab/daemon-pki/server.crt.pem \
WBABD_TLS_KEY_FILE=.wbab/daemon-pki/server.key.pem \
WBABD_TLS_CLIENT_CA_FILE=.wbab/daemon-pki/ca.crt.pem \
WBABD_HTTP_MAX_BODY_BYTES=1048576 \
WBABD_HTTP_REQUEST_TIMEOUT_SECS=15 \
WBABD_PREFLIGHT_AUDIT_WINDOW=50 \
tools/wbabd serve --host 127.0.0.1 --port 8787
```

Environment mapping summary:
- `WBABD_TLS_CERT_FILE` -> server cert (`server.crt.pem`)
- `WBABD_TLS_KEY_FILE` -> server private key (`server.key.pem`)
- `WBABD_TLS_CLIENT_CA_FILE` -> client trust CA (`ca.crt.pem`) for mTLS
- `WBABD_API_TOKEN_FILE` -> bearer token file used with `Authorization: Bearer ...`

## 3. Rotate Certificates
Rotate CA/server/client material:

```bash
scripts/security/daemon-pki.sh rotate
```

Notes:
- previous material is moved to `backup-<timestamp>` under `WBABD_PKI_DIR`
- after rotation, restart daemon with updated files
- redistribute new client cert/key and CA to authorized clients

## 4. Export / Import Material
Export:

```bash
scripts/security/daemon-pki.sh export /secure/transfer/location
```

Import:

```bash
scripts/security/daemon-pki.sh import /secure/transfer/location
```

## 5. Operational Checklist
- Keep daemon bound to loopback/private interface only.
- Store token and private keys in restricted paths (`chmod 600`).
- Use both bearer token and mTLS in production-like internal deployments.
- Rotate certs on a defined cadence and after any key compromise suspicion.

## 6. `systemd` Runtime Example
Example unit (`/etc/systemd/system/wbabd.service`):

```ini
[Unit]
Description=WBAB Daemon (private TLS/mTLS)
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/wbab
Environment=WBABD_AUTH_MODE=token
Environment=WBABD_API_TOKEN_FILE=/etc/wbabd/token.txt
Environment=WBABD_TLS_CERT_FILE=/etc/wbabd/pki/server.crt.pem
Environment=WBABD_TLS_KEY_FILE=/etc/wbabd/pki/server.key.pem
Environment=WBABD_TLS_CLIENT_CA_FILE=/etc/wbabd/pki/ca.crt.pem
Environment=WBABD_HTTP_MAX_BODY_BYTES=1048576
Environment=WBABD_HTTP_REQUEST_TIMEOUT_SECS=15
Environment=WBABD_PREFLIGHT_AUDIT_WINDOW=50
ExecStartPre=/opt/wbab/scripts/security/daemon-preflight.sh serve
ExecStart=/opt/wbab/tools/wbabd serve --preflight --host 127.0.0.1 --port 8787
Restart=on-failure
RestartSec=3
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/wbab/.wbab

[Install]
WantedBy=multi-user.target
```

Activate:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now wbabd.service
```

## 7. Containerized Private-Network Example
Example `docker run`:

```bash
docker run --rm \
  --name wbabd \
  --network bridge \
  -p 127.0.0.1:8787:8787 \
  -v "$PWD:/workspace:ro" \
  -v "$PWD/.wbab:/workspace/.wbab" \
  -v "$PWD/.wbab/daemon-pki:/run/wbabd/pki:ro" \
  -v "$PWD/.wbab/daemon-token.txt:/run/wbabd/token.txt:ro" \
  -e WBABD_AUTH_MODE=token \
  -e WBABD_API_TOKEN_FILE=/run/wbabd/token.txt \
  -e WBABD_TLS_CERT_FILE=/run/wbabd/pki/server.crt.pem \
  -e WBABD_TLS_KEY_FILE=/run/wbabd/pki/server.key.pem \
  -e WBABD_TLS_CLIENT_CA_FILE=/run/wbabd/pki/ca.crt.pem \
  -e WBABD_HTTP_MAX_BODY_BYTES=1048576 \
  -e WBABD_HTTP_REQUEST_TIMEOUT_SECS=15 \
  -e WBABD_PREFLIGHT_AUDIT_WINDOW=50 \
  ghcr.io/sempersupra/winebotappbuilder-winbuild:latest \
  /workspace/tools/wbabd serve --preflight --host 0.0.0.0 --port 8787
```

Optional preflight before container launch:

```bash
set -a
source .wbab/wbabd.container.env
set +a
bash scripts/security/daemon-preflight.sh serve
```

Notes:
- Keep published port bound to loopback (`127.0.0.1:8787:8787`) for private host-only access.
- Use read-only mounts for cert/token paths.
- If running behind an internal reverse proxy, keep proxy and daemon on the same private network.

## 8. Zero-Downtime Cert/Token Rotation Playbook
Goal: rotate cert/token material while keeping service availability.

### 8.1 Prepare New Material (staging paths)
1. Generate new cert set in staging dir:

```bash
WBABD_PKI_DIR=.wbab/daemon-pki-next scripts/security/daemon-pki.sh init
```

2. Create new token file in staging path:

```bash
umask 077
openssl rand -hex 32 > .wbab/daemon-token-next.txt
```

3. Distribute new client cert/key + new token to callers before cutover.

### 8.2 `systemd` Rolling Restart (single-node)
1. Update environment file or unit env paths to point at staged material:
- `WBABD_TLS_CERT_FILE=.wbab/daemon-pki-next/server.crt.pem`
- `WBABD_TLS_KEY_FILE=.wbab/daemon-pki-next/server.key.pem`
- `WBABD_TLS_CLIENT_CA_FILE=.wbab/daemon-pki-next/ca.crt.pem`
- `WBABD_API_TOKEN_FILE=.wbab/daemon-token-next.txt`

2. Reload unit definition:

```bash
sudo systemctl daemon-reload
```

3. Restart daemon:

```bash
sudo systemctl restart wbabd.service
```

4. Health validation:

```bash
curl --silent --show-error --fail \
  --cacert .wbab/daemon-pki-next/ca.crt.pem \
  --cert .wbab/daemon-pki-next/client.crt.pem \
  --key .wbab/daemon-pki-next/client.key.pem \
  -H "Authorization: Bearer $(cat .wbab/daemon-token-next.txt)" \
  https://127.0.0.1:8787/health
```

5. Promote new material to active paths and archive old material after validation.

### 8.3 Containerized Blue/Green Swap (recommended)
1. Start new container (`wbabd-next`) on alternate local port with staged material:

```bash
docker run -d \
  --name wbabd-next \
  --network bridge \
  -p 127.0.0.1:8788:8787 \
  -v "$PWD:/workspace:ro" \
  -v "$PWD/.wbab:/workspace/.wbab" \
  -v "$PWD/.wbab/daemon-pki-next:/run/wbabd/pki:ro" \
  -v "$PWD/.wbab/daemon-token-next.txt:/run/wbabd/token.txt:ro" \
  -e WBABD_AUTH_MODE=token \
  -e WBABD_API_TOKEN_FILE=/run/wbabd/token.txt \
  -e WBABD_TLS_CERT_FILE=/run/wbabd/pki/server.crt.pem \
  -e WBABD_TLS_KEY_FILE=/run/wbabd/pki/server.key.pem \
  -e WBABD_TLS_CLIENT_CA_FILE=/run/wbabd/pki/ca.crt.pem \
  ghcr.io/sempersupra/winebotappbuilder-winbuild:latest \
  /workspace/tools/wbabd serve --preflight --host 0.0.0.0 --port 8787
```

2. Validate `wbabd-next` health/auth.
3. Switch traffic (proxy or local port mapping) from old instance to new instance.
4. Stop and remove old container after cutover:

```bash
docker stop wbabd && docker rm wbabd
docker rename wbabd-next wbabd
```

### 8.4 Rollback
If validation fails:
1. revert env/path references to previous cert/token set
2. restart previous service/container
3. keep failed rotated assets for forensic inspection

## 9. Machine-Readable Automation Templates
Use these checked-in templates for automation/bootstrap scripts:

- `deploy/daemon/wbabd.systemd.env.example`
- `deploy/daemon/wbabd.container.env.example`
- `deploy/daemon/authz-policy.example.json`

Quick start:

```bash
cp deploy/daemon/wbabd.systemd.env.example /etc/wbabd/wbabd.env
cp deploy/daemon/authz-policy.example.json /etc/wbabd/authz-policy.json
```

```bash
cp deploy/daemon/wbabd.container.env.example .wbab/wbabd.container.env
cp deploy/daemon/authz-policy.example.json .wbab/authz-policy.json
```

Notes:
- Keep generated copies out of git (`.env`, live token files, live key paths).
- Treat templates as defaults; override paths per host/container runtime.
- For diagnostics-only principals, include `preflight_status` and `preflight_trend` in `verbs[]`.

Example diagnostics principal snippet:

```json
{
  "principals": {
    "readonly-ops": {
      "verbs": ["health", "status", "preflight_status", "preflight_trend", "plan"]
    }
  }
}
```

## 10. Startup Diagnostics
After preflight or startup attempts, inspect persisted diagnostics:

```bash
cat .wbab/preflight-status.json
```

```bash
cat .wbab/preflight-counters.json
```

Trend summary helper:

```bash
scripts/security/preflight-trend-report.sh --window 25
```

## 11. Operator Runbook Checks
Use these checks after startup/restart/rotation:

1. Preflight status is healthy:

```bash
tools/wbabd api '{"op":"preflight_status"}'
```

2. Trend window has no recent failures (example: 25-event window):

```bash
tools/wbabd api '{"op":"preflight_trend","window":25}'
```

3. HTTP endpoint parity for remote diagnostics:

```bash
curl --silent --show-error --fail \
  --cacert .wbab/daemon-pki/ca.crt.pem \
  --cert .wbab/daemon-pki/client.crt.pem \
  --key .wbab/daemon-pki/client.key.pem \
  -H "Authorization: Bearer $(cat .wbab/daemon-token.txt)" \
  'https://127.0.0.1:8787/preflight-trend?window=25'
```

If using a dedicated diagnostics principal over HTTP, pass it explicitly:

```bash
curl --silent --show-error --fail \
  --cacert .wbab/daemon-pki/ca.crt.pem \
  --cert .wbab/daemon-pki/client.crt.pem \
  --key .wbab/daemon-pki/client.key.pem \
  -H "X-WBABD-Principal: readonly-ops" \
  -H "Authorization: Bearer $(cat .wbab/daemon-token.txt)" \
  'https://127.0.0.1:8787/preflight-trend?window=25'
```

4. Optional threshold gate for operator policy:

```bash
WBABD_PREFLIGHT_TREND_WINDOW=25 \
WBABD_PREFLIGHT_TREND_MIN_SUCCESS_RATE_PCT=95 \
WBABD_PREFLIGHT_TREND_MAX_RECENT_FAILED=0 \
WBABD_PREFLIGHT_TREND_REQUIRE_EVENTS=1 \
scripts/security/preflight-trend-threshold-check.sh
```

### 11.4 Threshold Profile Quick Reference
Use these baseline profiles, then tune for your environment.

| Profile | `WBABD_PREFLIGHT_TREND_WINDOW` | `WBABD_PREFLIGHT_TREND_MIN_SUCCESS_RATE_PCT` | `WBABD_PREFLIGHT_TREND_MAX_RECENT_FAILED` | `WBABD_PREFLIGHT_TREND_REQUIRE_EVENTS` | When to use |
|---|---:|---:|---:|---:|---|
| `strict` | `50` | `99` | `0` | `1` | production-like steady-state with low tolerance for drift |
| `balanced` | `25` | `95` | `1` | `1` | default internal environments with moderate noise |
| `permissive` | `10` | `80` | `3` | `0` | early bring-up, migration windows, or noisy test environments |

### 11.5 `systemd` Health Integration (Optional)
Use a periodic timer to fail-fast on trend regressions.

Example service (`/etc/systemd/system/wbabd-trend-health.service`):

```ini
[Unit]
Description=WBAB Daemon Preflight Trend Health Check
After=wbabd.service

[Service]
Type=oneshot
WorkingDirectory=/opt/wbab
Environment=WBABD_PREFLIGHT_TREND_WINDOW=25
Environment=WBABD_PREFLIGHT_TREND_MIN_SUCCESS_RATE_PCT=95
Environment=WBABD_PREFLIGHT_TREND_MAX_RECENT_FAILED=0
Environment=WBABD_PREFLIGHT_TREND_REQUIRE_EVENTS=1
ExecStart=/opt/wbab/scripts/security/preflight-trend-threshold-check.sh
```

Example timer (`/etc/systemd/system/wbabd-trend-health.timer`):

```ini
[Unit]
Description=Run WBAB trend health check every 5 minutes

[Timer]
OnBootSec=2m
OnUnitActiveSec=5m
Unit=wbabd-trend-health.service

[Install]
WantedBy=timers.target
```

Enable:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now wbabd-trend-health.timer
```

### 11.6 Container Healthcheck Integration (Optional)
Example `docker run` healthcheck wiring:

```bash
docker run -d \
  --name wbabd \
  --network bridge \
  -p 127.0.0.1:8787:8787 \
  -v "$PWD:/workspace:ro" \
  -v "$PWD/.wbab:/workspace/.wbab" \
  -e WBABD_PREFLIGHT_TREND_WINDOW=25 \
  -e WBABD_PREFLIGHT_TREND_MIN_SUCCESS_RATE_PCT=95 \
  -e WBABD_PREFLIGHT_TREND_MAX_RECENT_FAILED=0 \
  -e WBABD_PREFLIGHT_TREND_REQUIRE_EVENTS=1 \
  --health-cmd 'WBABD_BIN=/workspace/tools/wbabd /workspace/scripts/security/preflight-trend-threshold-check.sh' \
  --health-interval 5m \
  --health-timeout 20s \
  --health-retries 2 \
  ghcr.io/sempersupra/winebotappbuilder-winbuild:latest \
  /workspace/tools/wbabd serve --preflight --host 0.0.0.0 --port 8787
```

### 11.7 Threshold Gate Troubleshooting
Common failure signatures and quick remediation:

1. `ERROR: no recent preflight events observed in window=<N>`
- Cause: gate requires events (`WBABD_PREFLIGHT_TREND_REQUIRE_EVENTS=1`) but none exist yet.
- Actions: run a preflight cycle (`tools/wbabd serve --preflight`), or temporarily set `WBABD_PREFLIGHT_TREND_REQUIRE_EVENTS=0` during initial bring-up.

2. `ERROR: recent preflight failed count <X> exceeds threshold <Y>`
- Cause: too many failed `command.preflight` events in the selected window.
- Actions: inspect `tools/wbabd api '{"op":"preflight_status"}'`, fix auth/TLS/authz config, then rerun preflight and re-check trend.

3. `ERROR: recent preflight success rate <R>% below threshold <T>%`
- Cause: recent preflight reliability below configured policy.
- Actions: increase `WBABD_PREFLIGHT_TREND_WINDOW` to smooth noise, or lower `WBABD_PREFLIGHT_TREND_MIN_SUCCESS_RATE_PCT` only if risk acceptance is documented.

4. `ERROR: preflight_trend status is not ok`
- Cause: daemon trend API failed (invalid inputs/env or missing daemon context).
- Actions: verify `tools/wbabd api '{"op":"preflight_trend","window":25}'` returns `status=ok`, validate `WBABD_PREFLIGHT_AUDIT_WINDOW`, and ensure `.wbab/audit-log.jsonl` is readable.

Via local API adapter:

```bash
tools/wbabd api '{"op":"preflight_status"}'
```

```bash
tools/wbabd api '{"op":"preflight_trend","window":25}'
```

Via HTTP adapter:

```bash
curl --silent --show-error --fail \
  --cacert .wbab/daemon-pki/ca.crt.pem \
  --cert .wbab/daemon-pki/client.crt.pem \
  --key .wbab/daemon-pki/client.key.pem \
  -H "Authorization: Bearer $(cat .wbab/daemon-token.txt)" \
  https://127.0.0.1:8787/preflight-status
```

```bash
curl --silent --show-error --fail \
  --cacert .wbab/daemon-pki/ca.crt.pem \
  --cert .wbab/daemon-pki/client.crt.pem \
  --key .wbab/daemon-pki/client.key.pem \
  -H "Authorization: Bearer $(cat .wbab/daemon-token.txt)" \
  'https://127.0.0.1:8787/preflight-trend?window=25'
```
