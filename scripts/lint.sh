#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[lint] shellcheck"
if command -v shellcheck >/dev/null 2>&1; then
  mapfile -t files < <(cd "${ROOT_DIR}" && git ls-files '*.sh' 2>/dev/null)
  if [[ "${#files[@]}" -gt 0 ]]; then
    (
      cd "${ROOT_DIR}"
      shellcheck -x "${files[@]}"
    )
  else
    echo "  (no .sh files tracked by git yet)"
  fi
else
  echo "  shellcheck not installed; skipping (CI installs it)."
fi

echo "[lint] executable bits"
# Ensure key scripts are executable
must_exec=(tools/compose.sh tools/winbuild-build.sh tools/package-nsis.sh tools/sign-dev.sh tools/winebot-smoke.sh tools/winebot-trust-dev-cert.sh tools/wbab tools/wbabd scripts/lint.sh scripts/bootstrap-submodule.sh scripts/signing/dev-cert.sh)
for f in "${must_exec[@]}"; do
  if [[ -f "${ROOT_DIR}/${f}" && ! -x "${ROOT_DIR}/${f}" ]]; then
    echo "ERROR: ${f} must be executable" >&2
    exit 1
  fi
done

echo "[lint] done"
