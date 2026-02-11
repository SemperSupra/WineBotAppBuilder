#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

wf="${ROOT_DIR}/.github/workflows/release.yml"
[[ -f "${wf}" ]] || { echo "Missing required workflow: .github/workflows/release.yml" >&2; exit 1; }

# Tag policy: release tag + latest
grep -q -- "--tag \"\${image}:\${TAG}\"" "${wf}" || { echo "release.yml must tag images with release tag" >&2; exit 1; }
grep -q -- "--tag \"\${image}:latest\"" "${wf}" || { echo "release.yml must tag images with latest" >&2; exit 1; }

# Label policy: required OCI labels
grep -q 'org.opencontainers.image.source=' "${wf}" || { echo "release.yml missing OCI source label" >&2; exit 1; }
grep -q 'org.opencontainers.image.revision=' "${wf}" || { echo "release.yml missing OCI revision label" >&2; exit 1; }
grep -q 'org.opencontainers.image.version=' "${wf}" || { echo "release.yml missing OCI version label" >&2; exit 1; }

# Digest policy: metadata and digest manifest must be produced
grep -q -- "--metadata-file \"\${metadata_file}\"" "${wf}" || { echo "release.yml must emit build metadata file" >&2; exit 1; }
grep -q 'containerimage.digest' "${wf}" || { echo "release.yml must parse containerimage.digest" >&2; exit 1; }
grep -q 'artifacts/publish-digests.txt' "${wf}" || { echo "release.yml must write artifacts/publish-digests.txt" >&2; exit 1; }
grep -q 'name: release-metadata' "${wf}" || { echo "release.yml must upload publish metadata artifact" >&2; exit 1; }
