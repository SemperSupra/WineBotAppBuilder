#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
wf="${ROOT_DIR}/.github/workflows/release.yml"
retirement="${ROOT_DIR}/RETIREMENT.md"

echo "[policy] verifying release/publication policy..."

# Retirement changes the protected invariant. While WBAB was active, this
# policy proved that credentialed publication happened only through the
# structured release workflow. Once retirement is authoritative, the safer
# invariant is the opposite: no workflow may retain publication authority.
if [[ -f "${retirement}" ]]; then
  grep -qi "feature-frozen" "${retirement}" || {
    echo "POLICY FAILURE: RETIREMENT.md must declare the repository feature-frozen" >&2
    exit 1
  }

  [[ ! -f "${wf}" ]] || {
    echo "POLICY FAILURE: release.yml must be absent while WBAB is retired" >&2
    exit 1
  }

  workflow_dir="${ROOT_DIR}/.github/workflows"

  if grep -R -n -E 'packages:[[:space:]]*write' "${workflow_dir}" --include='*.yml' --include='*.yaml'; then
    echo "POLICY FAILURE: retired WBAB workflows must not retain packages:write authority" >&2
    exit 1
  fi

  if grep -R -n -E 'docker/login-action@|gh[[:space:]]+release[[:space:]]+(create|upload)|--push([[:space:]\\]|$)' \
      "${workflow_dir}" --include='*.yml' --include='*.yaml'; then
    echo "POLICY FAILURE: retired WBAB workflows must not contain release/registry publication steps" >&2
    exit 1
  fi

  echo "OK: retirement publication shutdown policy satisfied"
  exit 0
fi

# Active-project compatibility path retained for historical branches/forks
# without RETIREMENT.md.
check_yq() {
  local query="$1"
  local expected="$2"
  local msg="$3"
  local actual
  actual=$(yq eval "${query}" "${wf}" | tr -d '[:space:]')
  if [[ "${actual}" != "${expected}" ]]; then
    echo "POLICY FAILURE: ${msg} (Expected: ${expected}, Actual: ${actual})" >&2
    exit 1
  fi
}

[[ -f "${wf}" ]] || {
  echo "POLICY FAILURE: active WBAB state requires release.yml" >&2
  exit 1
}

# 1. Structural release authority gates.
check_yq '.on.push.tags[0]' "v*" "release.yml must trigger on v* tags"
check_yq '.on | has("workflow_dispatch")' "true" "release.yml must support manual dispatch"
check_yq '.permissions.contents' "write" "release.yml must have contents:write"
check_yq '.permissions.packages' "write" "release.yml must have packages:write"

# 2. Structured publication ordering and evidence semantics.
release_steps_json="$(yq eval -o=json '.jobs.release.steps' "${wf}")"
RELEASE_STEPS_JSON="${release_steps_json}" python3 - <<'PY'
import json
import os

steps = json.loads(os.environ["RELEASE_STEPS_JSON"])
if not isinstance(steps, list) or not steps:
    raise SystemExit("POLICY FAILURE: release job must contain steps")


def one_index(predicate, description):
    matches = [i for i, step in enumerate(steps) if isinstance(step, dict) and predicate(step)]
    if len(matches) != 1:
        raise SystemExit(
            f"POLICY FAILURE: expected exactly one {description} step, found {len(matches)}"
        )
    return matches[0]


checkout_i = one_index(
    lambda step: step.get("uses") == "actions/checkout@v4",
    "actions/checkout@v4",
)
checkout = steps[checkout_i]
checkout_with = checkout.get("with", {})
if not isinstance(checkout_with, dict) or checkout_with.get("submodules") is not False:
    raise SystemExit("POLICY FAILURE: release checkout must keep submodules disabled")

buildx_i = one_index(
    lambda step: str(step.get("uses", "")).startswith("docker/setup-buildx-action@"),
    "Docker Buildx setup",
)
drycheck_i = one_index(
    lambda step: "scripts/publish/dockerfiles-drycheck.sh" in str(step.get("run", "")),
    "publish Dockerfile dry-check",
)
login_i = one_index(
    lambda step: str(step.get("uses", "")).startswith("docker/login-action@"),
    "registry login",
)
login = steps[login_i]
login_with = login.get("with", {})
if not isinstance(login_with, dict) or login_with.get("registry") != "ghcr.io":
    raise SystemExit("POLICY FAILURE: release registry login must target ghcr.io")

publish_i = one_index(
    lambda step: "docker buildx build" in str(step.get("run", ""))
    and "--push" in str(step.get("run", "")),
    "credentialed image publication",
)
if not (checkout_i < buildx_i < drycheck_i < login_i < publish_i):
    raise SystemExit(
        "POLICY FAILURE: release authority ordering must be "
        "checkout < buildx < dry-check < login < publish"
    )

metadata_i = one_index(
    lambda step: step.get("uses") == "actions/upload-artifact@v4",
    "publish metadata upload",
)
metadata = steps[metadata_i]
metadata_with = metadata.get("with", {})
if not isinstance(metadata_with, dict) or metadata_with.get("path") != "artifacts/**":
    raise SystemExit("POLICY FAILURE: release metadata upload must retain artifacts/**")
if str(metadata.get("if", "")).strip() != "always()":
    raise SystemExit("POLICY FAILURE: release metadata upload must run with always()")
PY

# 3. Docker Image Policy
dockerfiles=(
  "tools/winbuild/Dockerfile"
  "tools/packaging/Dockerfile"
  "tools/signing/Dockerfile"
  "tools/linter/Dockerfile"
)

for df in "${dockerfiles[@]}"; do
  full_path="${ROOT_DIR}/${df}"
  [[ -f "${full_path}" ]] || { echo "POLICY FAILURE: missing ${df}" >&2; exit 1; }
  grep -q "FROM debian:trixie-slim" "${full_path}" || {
    echo "POLICY FAILURE: ${df} must use official debian:trixie-slim base" >&2; exit 1;
  }
done

# 4. Official Image Defaults
runner="${ROOT_DIR}/tools/winebot-smoke.sh"
grep -q "ghcr.io/mark-e-deyoung/winebot" "${runner}" || {
  echo "POLICY FAILURE: winebot-smoke.sh default image must be official" >&2; exit 1;
}

echo "OK: release pipeline structured policies satisfied"
