#!/usr/bin/env bash
# Internal script executed INSIDE the linter container.
set -euo pipefail

# Fix "dubious ownership" in container mounts
git config --global --add safe.directory /workspace
git config --global --add safe.directory /workspace/workspace

# Move to workspace to run git ls-files correctly
cd /workspace/workspace

echo "[lint] shellcheck (project-owned scripts)"
# shellcheck disable=SC2046
shellcheck -x $(git ls-files '*.sh' | grep -v "^tools/WineBot/")

echo "[lint] ruff (project-owned python)"
ruff check --exclude tools/WineBot .

echo "[lint] hadolint (project-owned dockerfiles)"
# shellcheck disable=SC2046
hadolint --ignore DL3008 $(git ls-files '**/Dockerfile' | grep -v "^tools/WineBot/")

echo "[lint] trivy (project-owned security fs scan)"
trivy fs --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 --skip-dirs tools/WineBot .

echo "[lint] trivy (SBOM generation)"
mkdir -p /workspace/agent-sandbox/state
trivy fs --format cyclonedx --output /workspace/agent-sandbox/state/sbom-repo.cdx.json --skip-dirs tools/WineBot .

echo "[lint] executable bits"
# Ensure key scripts are executable
must_exec=(tools/compose.sh tools/winbuild-build.sh tools/package-nsis.sh tools/sign-dev.sh tools/winebot-smoke.sh tools/winebot-trust-dev-cert.sh tools/wbab tools/wbabd scripts/lint.sh scripts/bootstrap-submodule.sh scripts/signing/dev-cert.sh)
for f in "${must_exec[@]}"; do
  if [[ -f "${f}" && ! -x "${f}" ]]; then
    echo "ERROR: ${f} must be executable" >&2
    exit 1
  fi
done

echo "[lint] SUCCESS"
