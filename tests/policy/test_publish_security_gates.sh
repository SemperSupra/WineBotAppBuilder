#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

wf="${ROOT_DIR}/.github/workflows/release.yml"
[[ -f "${wf}" ]] || { echo "Missing required workflow: .github/workflows/release.yml" >&2; exit 1; }

# Release trigger policy: must trigger on push tags v*
grep -qE '^\s*push:' "${wf}" || {
  echo "release.yml must keep push trigger contract" >&2
  exit 1
}
grep -qE 'tags:' "${wf}" || {
  echo "release.yml must restrict push trigger to tags" >&2
  exit 1
}
grep -qE "'v\*'" "${wf}" || {
  echo "release.yml must keep v* tag pattern contract" >&2
  exit 1
}

grep -q 'uses: actions/checkout@v4' "${wf}" || {
  echo "release.yml must pin checkout action version: actions/checkout@v4" >&2
  exit 1
}
grep -q 'submodules: false' "${wf}" || {
  echo "release.yml checkout step must keep submodules: false" >&2
  exit 1
}
grep -qE '^\s*permissions:' "${wf}" || {
  echo "release.yml must declare explicit workflow permissions" >&2
  exit 1
}
grep -qE '^\s*contents:\s*write' "${wf}" || {
  echo "release.yml permissions must allow contents: write (for release creation)" >&2
  exit 1
}
grep -qE '^\s*packages:\s*write' "${wf}" || {
  echo "release.yml permissions must keep packages: write" >&2
  exit 1
}

# Hardening gate: hadolint for all three Dockerfiles
grep -q 'hadolint/hadolint-action@v3.3.0' "${wf}" || { echo "release.yml missing hadolint hardening gate" >&2; exit 1; }
grep -q 'tools/winbuild/Dockerfile' "${wf}" || { echo "release.yml missing winbuild Dockerfile lint reference" >&2; exit 1; }
grep -q 'tools/packaging/Dockerfile' "${wf}" || { echo "release.yml missing packaging Dockerfile lint reference" >&2; exit 1; }
grep -q 'tools/signing/Dockerfile' "${wf}" || { echo "release.yml missing signing Dockerfile lint reference" >&2; exit 1; }
hadolint_pin_count="$(grep -c 'uses: hadolint/hadolint-action@v3.3.0' "${wf}")"
[[ "${hadolint_pin_count}" == "3" ]] || {
  echo "release.yml must pin hadolint action to v3.3.0 for all three lint steps" >&2
  exit 1
}

# Security gate: Trivy with blocking exit code for HIGH/CRITICAL
grep -q 'aquasecurity/trivy-action@0.29.0' "${wf}" || { echo "release.yml missing trivy security gate" >&2; exit 1; }
trivy_pin_count="$(grep -c 'uses: aquasecurity/trivy-action@0.29.0' "${wf}")"
[[ "${trivy_pin_count}" == "2" ]] || {
  echo "release.yml must pin trivy action to 0.29.0 for both security and SBOM steps" >&2
  exit 1
}
grep -q 'severity: CRITICAL,HIGH' "${wf}" || { echo "release.yml must scan CRITICAL,HIGH vulnerabilities" >&2; exit 1; }
grep -q "exit-code: '1'" "${wf}" || { echo "release.yml must block on trivy vulnerabilities" >&2; exit 1; }

# SBOM contract: build step + explicit CycloneDX report output
grep -q -- '--sbom=true' "${wf}" || { echo "release.yml must build with sbom generation enabled" >&2; exit 1; }
grep -q 'format: cyclonedx' "${wf}" || { echo "release.yml must generate CycloneDX SBOM report" >&2; exit 1; }
grep -q 'artifacts/sbom-repo.cdx.json' "${wf}" || { echo "release.yml missing SBOM output artifact path" >&2; exit 1; }

# Local/CI parity contract: publish workflow must reuse local dry-check helper.
grep -q 'scripts/publish/dockerfiles-drycheck.sh' "${wf}" || {
  echo "release.yml must reference scripts/publish/dockerfiles-drycheck.sh for local/CI parity" >&2
  exit 1
}
grep -q 'name: Dry-check publish Dockerfiles (local/CI parity)' "${wf}" || {
  echo "release.yml must keep dry-check step name stable: Dry-check publish Dockerfiles (local/CI parity)" >&2
  exit 1
}
awk '
  /name: Dry-check publish Dockerfiles \(local\/CI parity\)/ {
    while (getline) {
      if ($0 ~ /^[[:space:]]*-[[:space:]]name:/) break
      if ($0 ~ /set -euo pipefail/) found_failfast=1
      if ($0 ~ /scripts\/publish\/dockerfiles-drycheck\.sh/) { found=1; break }
    }
  }
  END { exit(found && found_failfast ? 0 : 1) }
' "${wf}" || {
  echo "release.yml dry-check step must keep fail-fast + scripts/publish/dockerfiles-drycheck.sh adjacent to its step block" >&2
  exit 1
}
grep -q 'name: Set up Docker Buildx' "${wf}" || {
  echo "release.yml must keep buildx step name stable: Set up Docker Buildx" >&2
  exit 1
}
grep -q 'uses: docker/setup-buildx-action@v3' "${wf}" || {
  echo "release.yml must pin buildx setup action version: docker/setup-buildx-action@v3" >&2
  exit 1
}
awk '
  /name: Set up Docker Buildx/ {
    while (getline) {
      if ($0 ~ /^[[:space:]]*-[[:space:]]name:/) break
      if ($0 ~ /uses:[[:space:]]docker\/setup-buildx-action@v3/) { found=1; break }
    }
  }
  END { exit(found ? 0 : 1) }
' "${wf}" || {
  echo "release.yml buildx step must keep docker/setup-buildx-action@v3 adjacent to its step block" >&2
  exit 1
}
grep -q 'name: Log in to GHCR' "${wf}" || {
  echo "release.yml must keep GHCR login step name stable: Log in to GHCR" >&2
  exit 1
}
awk '
  /name: Log in to GHCR/ {
    while (getline) {
      if ($0 ~ /^[[:space:]]*-[[:space:]]name:/) break
      if ($0 ~ /uses:[[:space:]]docker\/login-action@v3/) { found=1; break }
    }
  }
  END { exit(found ? 0 : 1) }
' "${wf}" || {
  echo "release.yml login step must keep docker/login-action@v3 adjacent to its step block" >&2
  exit 1
}
awk '
  /name: Log in to GHCR/ {
    in_login=1
    next
  }
  in_login {
    if ($0 ~ /^[[:space:]]*-[[:space:]]name:/) {
      in_login=0
    } else {
      if ($0 ~ /registry:[[:space:]]ghcr\.io/) found_registry=1
      if ($0 ~ /username:[[:space:]]\$\{\{ github\.actor \}\}/) found_user=1
      if ($0 ~ /password:[[:space:]]\$\{\{ secrets\.GITHUB_TOKEN \}\}/) found_token=1
    }
  }
  END { exit(found_registry && found_user && found_token ? 0 : 1) }
' "${wf}" || {
  echo "release.yml login step must keep registry/username/password fields in the same step block" >&2
  exit 1
}
grep -q 'name: Publish images' "${wf}" || {
  echo "release.yml must keep publish step name stable: Publish images" >&2
  exit 1
}
awk '
  /name: Publish images/ {
    while (getline) {
      if ($0 ~ /^[[:space:]]*-[[:space:]]name:/) break
      if ($0 ~ /set -euo pipefail/) found_failfast=1
      if ($0 ~ /publish_if_exists\(\)/) in_fn=1
      if (in_fn && $0 ~ /local dockerfile="\$1"/) found_arg_dockerfile=1
      if (in_fn && $0 ~ /local image_name="\$2"/) found_arg_image_name=1
      if (in_fn && $0 ~ /\[\[ ! -f "\$\{dockerfile\}" \]\]/) found_missing_guard=1
      if (in_fn && $0 ~ /SKIP: missing/) found_skip_message=1
      if (in_fn && $0 ~ /return 0/) found_skip_return=1
      if (in_fn && $0 ~ /\[\[ -z "\$\{digest\}" \]\]/) found_digest_guard=1
      if (in_fn && $0 ~ /ERROR: missing container digest/) found_digest_error=1
      if (in_fn && $0 ~ /exit 1/) found_digest_exit=1
      if (in_fn && $0 ~ /digest="\$\(jq -r / && $0 ~ /containerimage\.digest/ && $0 ~ /\$\{metadata_file\}/) found_digest_assign=1
      if (in_fn && $0 ~ /jq -r/ && $0 ~ /containerimage\.digest/ && $0 ~ /\$\{metadata_file\}/) found_digest_jq=1
      if (in_fn && $0 ~ /^\s*\}/) in_fn=0
      if ($0 ~ /OWNER:[[:space:]]\$\{\{ github\.repository_owner \}\}/) found_owner=1
      if ($0 ~ /TAG:[[:space:]]\$\{\{ github\.ref_name \}\}/) found_tag=1
      if ($0 ~ /REPO:[[:space:]]\$\{\{ github\.repository \}\}/) found_repo=1
      if ($0 ~ /SHA:[[:space:]]\$\{\{ github\.sha \}\}/) found_sha=1
      if ($0 ~ /mkdir -p artifacts/) found_artifacts_mkdir=1
      if ($0 ~ /: > artifacts\/publish-digests\.txt/) found_artifacts_manifest_init=1
      if ($0 ~ /owner_lc=.*tr.*\[:upper:\].*\[:lower:\]/) found_owner_lc=1
      if ($0 ~ /local image="ghcr\.io\/\$\{owner_lc\}\/\$\{image_name\}"/) found_image_path=1
      if ($0 ~ /local metadata_file="artifacts\/\$\{image_name\}\.metadata\.json"/) found_metadata_path=1
      if ($0 ~ /echo "Publishing \$\{image\}:\$\{TAG\}"/) found_publish_announce=1
      if ($0 ~ /org\.opencontainers\.image\.source=https:\/\/github\.com\/\$\{REPO\}/) found_label_source=1
      if ($0 ~ /org\.opencontainers\.image\.revision=\$\{SHA\}/) found_label_revision=1
      if ($0 ~ /org\.opencontainers\.image\.version=\$\{TAG\}/) found_label_version=1
      if ($0 ~ /org\.opencontainers\.image\.title=\$\{image_name\}/) found_label_title=1
      if ($0 ~ /publish_if_exists "tools\/winbuild\/Dockerfile" "winebotappbuilder-winbuild"/) found_publish_winbuild=1
      if ($0 ~ /publish_if_exists "tools\/packaging\/Dockerfile" "winebotappbuilder-packager"/) found_publish_packager=1
      if ($0 ~ /publish_if_exists "tools\/signing\/Dockerfile" "winebotappbuilder-signer"/) found_publish_signer=1
      if ($0 ~ /docker buildx build/) found_buildx=1
      if ($0 ~ /--file "\$\{dockerfile\}"/) found_build_file=1
      if ($0 ~ /--tag "\$\{image\}:\$\{TAG\}"/) found_tag_release=1
      if ($0 ~ /--tag "\$\{image\}:latest"/) found_tag_latest=1
      if ($0 ~ /--push/) found_push=1
      if ($0 ~ /--provenance=true/) found_provenance=1
      if ($0 ~ /--sbom=true/) found_sbom=1
      if ($0 ~ /--metadata-file "\$\{metadata_file\}"/) found_meta_file=1
      if ($0 ~ /^[[:space:]]*\.$/) found_build_context=1
      if ($0 ~ /containerimage\.digest/) found_digest_parse=1
      if ($0 ~ /artifacts\/publish-digests\.txt/) found_digest_out=1
      if ($0 ~ /echo "\$\{image\}:\$\{TAG\}@\$\{digest\}" >> artifacts\/publish-digests\.txt/) found_digest_manifest_format=1
    }
  }
  END {
    if (found_owner && found_tag && found_repo && found_sha &&
        found_artifacts_mkdir && found_artifacts_manifest_init &&
        found_owner_lc && found_image_path && found_metadata_path && found_publish_announce &&
        found_label_source && found_label_revision && found_label_version && found_label_title &&
        found_publish_winbuild && found_publish_packager && found_publish_signer &&
        found_arg_dockerfile && found_arg_image_name &&
        found_missing_guard && found_skip_message && found_skip_return &&
        found_digest_guard && found_digest_error && found_digest_exit && found_digest_assign && found_digest_jq &&
        found_failfast &&
        found_buildx && found_build_file && found_tag_release && found_tag_latest && found_push &&
        found_provenance && found_sbom && found_meta_file && found_build_context && found_digest_parse &&
        found_digest_out && found_digest_manifest_format) {
      exit 0
    }
    exit 1
  }
' "${wf}" || {
  echo "release.yml publish step must keep env contract + build/push + metadata digest handling within its step block" >&2
  exit 1
}
awk '
  /name: Publish images/ { in_publish=1; next }
  in_publish && /^[[:space:]]*-[[:space:]]name:/ { in_publish=0 }
  in_publish && /publish_if_exists\(\)/ && !def_line { def_line=NR }
  in_publish && /publish_if_exists "tools\/winbuild\/Dockerfile" "winebotappbuilder-winbuild"/ && !winbuild_call { winbuild_call=NR }
  in_publish && /publish_if_exists "tools\/packaging\/Dockerfile" "winebotappbuilder-packager"/ && !packager_call { packager_call=NR }
  in_publish && /publish_if_exists "tools\/signing\/Dockerfile" "winebotappbuilder-signer"/ && !signer_call { signer_call=NR }
  in_publish && /publish_if_exists "tools\/(winbuild|packaging|signing)\/Dockerfile"/ && !call_line { call_line=NR }
  END {
    if (!def_line || !call_line || def_line >= call_line) exit 1
    if (!winbuild_call || !packager_call || !signer_call) exit 1
    if (!(winbuild_call < packager_call && packager_call < signer_call)) exit 1
  }
' "${wf}" || {
  echo "release.yml must define publish_if_exists() before invoking tool Dockerfile mappings and keep mapping order winbuild->packaging->signing" >&2
  exit 1
}
grep -q 'uses: actions/upload-artifact@v4' "${wf}" || {
  echo "release.yml must pin upload action version: actions/upload-artifact@v4" >&2
  exit 1
}
grep -q 'name: Upload publish metadata' "${wf}" || {
  echo "release.yml must keep upload step name stable: Upload publish metadata" >&2
  exit 1
}
awk '
  /name: Upload publish metadata/ {
    while (getline) {
      if ($0 ~ /^[[:space:]]*-[[:space:]]name:/) break
      if ($0 ~ /uses:[[:space:]]actions\/upload-artifact@v4/) { found=1; break }
    }
  }
  END { exit(found ? 0 : 1) }
' "${wf}" || {
  echo "release.yml upload step must keep actions/upload-artifact@v4 adjacent to its step block" >&2
  exit 1
}
awk '
  /name: Upload publish metadata/ {
    while (getline) {
      if ($0 ~ /^[[:space:]]*-[[:space:]]name:/) break
      if ($0 ~ /if:[[:space:]]always\(\)/) { found=1; break }
    }
  }
  END { exit(found ? 0 : 1) }
' "${wf}" || {
  echo "release.yml upload step must keep if: always() inside its step block" >&2
  exit 1
}
grep -q 'name: release-metadata' "${wf}" || {
  echo "release.yml must keep publish metadata artifact name: release-metadata" >&2
  exit 1
}
grep -q 'path: artifacts/\*\*' "${wf}" || {
  echo "release.yml must keep publish metadata artifact path: artifacts/**" >&2
  exit 1
}
grep -q 'if-no-files-found: warn' "${wf}" || {
  echo "release.yml must keep publish metadata artifact no-files policy: warn" >&2
  exit 1
}
awk '
  /name: Upload publish metadata/ {
    in_upload=1
    next
  }
  in_upload {
    if ($0 ~ /^[[:space:]]*-[[:space:]]name:/) {
      in_upload=0
    } else {
      if ($0 ~ /name:[[:space:]]release-metadata/) found_name=1
      if ($0 ~ /path:[[:space:]]artifacts\/\*\*/) found_path=1
      if ($0 ~ /if-no-files-found:[[:space:]]warn/) found_warn=1
    }
  }
  END { exit(found_name && found_path && found_warn ? 0 : 1) }
' "${wf}" || {
  echo "release.yml upload step must keep artifact name/path/if-no-files-found within the same step block" >&2
  exit 1
}

# Ordering contract: dry-check step must run before publish/push step.
awk '
  /name: Set up Docker Buildx/ { buildx=NR }
  /name: Dry-check publish Dockerfiles \(local\/CI parity\)/ { drycheck=NR }
  /name: Log in to GHCR/ { login=NR }
  /name: Publish images/ { publish=NR }
  END {
    if (!buildx || !drycheck || !login || !publish) exit 1
    if (buildx >= drycheck) exit 1
    if (drycheck >= login) exit 1
    if (login >= publish) exit 1
  }
' "${wf}" || {
  echo "release.yml must keep step order buildx < dry-check < GHCR login < publish-images" >&2
  exit 1
}