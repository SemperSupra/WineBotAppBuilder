#!/usr/bin/env bash
# Internal script executed INSIDE the linter container.
set -euo pipefail

# Fix "dubious ownership" in container mounts
git config --global --add safe.directory /workspace

# Move to workspace to run git ls-files correctly
cd /workspace

# Ensure we can run git even if the workspace is just a directory mount without a .git
# (Though in CI it should be a real git repo)
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "WARN: Not inside a git work tree. Using find instead of git ls-files."
  # shellcheck disable=SC2016
  SH_FILES=$(find . -name "*.sh" -not -path "./tools/WineBot/*")
  # shellcheck disable=SC2016
  DOCKER_FILES=$(find . -name "Dockerfile" -not -path "./tools/WineBot/*")
else
  SH_FILES=$(git ls-files '*.sh' | grep -v "^tools/WineBot/")
  DOCKER_FILES=$(git ls-files '**/Dockerfile' | grep -v "^tools/WineBot/")
fi

echo "[lint] shellcheck (project-owned scripts)"
# shellcheck disable=SC2086
if [[ -n "${SH_FILES}" ]]; then
  shellcheck -x ${SH_FILES}
else
  echo "  (no .sh files found)"
fi

echo "[lint] ruff (project-owned python)"
ruff check --exclude tools/WineBot .

echo "[lint] mypy (static type checking)"
mypy --ignore-missing-imports --explicit-package-bases --exclude tools/WineBot .

echo "[lint] hadolint (project-owned dockerfiles)"
# shellcheck disable=SC2086
if [[ -n "${DOCKER_FILES}" ]]; then
  hadolint --ignore DL3008 ${DOCKER_FILES}
else
  echo "  (no Dockerfiles found)"
fi

echo "[lint] trivy (project-owned security fs scan)"
trivy fs --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 --skip-dirs tools/WineBot .

echo "[lint] trivy (SBOM generation)"
mkdir -p /workspace/agent-sandbox/state
trivy fs --format cyclonedx --output /workspace/agent-sandbox/state/sbom-repo.cdx.json --skip-dirs tools/WineBot .

echo "[lint] executable bits"
# Ensure key scripts are executable
must_exec=(tools/compose.sh tools/winbuild-build.sh tools/package-nsis.sh tools/sign-dev.sh tools/winebot-smoke.sh tools/winebot-trust-dev-cert.sh tools/wbab tools/wbabd scripts/lint.sh scripts/bootstrap-submodule.sh scripts/signing/dev-cert.sh)
for f in "${must_exec[@]}"; do
  # Check relative to current dir (workspace)
  if [[ -f "${f}" && ! -x "${f}" ]]; then
    echo "ERROR: ${f} must be executable" >&2
    exit 1
  fi
done

echo "[lint] SUCCESS"
