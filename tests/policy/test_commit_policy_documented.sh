#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
agents="${ROOT_DIR}/AGENTS.md"
contracts="${ROOT_DIR}/docs/CONTRACTS.md"

grep -qi 'Commit policy: create one git commit per requested implementation change' "${agents}" || {
  echo "AGENTS.md missing commit policy invariant" >&2
  exit 1
}
grep -qi 'one commit per requested implementation change' "${agents}" || {
  echo "AGENTS.md missing commit policy review checklist reference" >&2
  exit 1
}
grep -qi 'Commit policy: one git commit per requested implementation change' "${contracts}" || {
  echo "CONTRACTS.md missing commit policy constraint" >&2
  exit 1
}

echo "OK: commit policy documented"
