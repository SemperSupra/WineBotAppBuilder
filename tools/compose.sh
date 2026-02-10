#!/usr/bin/env bash
set -euo pipefail

if docker compose version >/dev/null 2>&1; then
  exec docker compose "$@"
elif command -v docker-compose >/dev/null 2>&1; then
  exec docker-compose "$@"
else
  echo "ERROR: neither 'docker compose' (v2) nor 'docker-compose' (v1) is available." >&2
  exit 1
fi
