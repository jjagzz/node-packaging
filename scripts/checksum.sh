#!/usr/bin/env bash
# Usage: ./scripts/checksum.sh generate | verify
# Generates or verifies SHA256 checksums for artifacts in dist/
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$ROOT/dist"
MODE="${1:-}"

[[ "$MODE" =~ ^(generate|verify)$ ]] || { echo "Usage: $0 generate|verify"; exit 2; }
[[ -d "$DIST" ]] || { echo "dist/ not found - build the artifact first"; exit 2; }

cd "$DIST"   # run inside dist/ so the checksum file stores plain filenames

case "$MODE" in
  generate)
    shopt -s nullglob
    files=(*.tgz release-bundle-*.tar.gz)
    [[ ${#files[@]} -gt 0 ]] || { echo "No artifacts found in dist/"; exit 2; }
    sha256sum "${files[@]}" > checksum.sha256
    echo "Generated dist/checksum.sha256:"
    cat checksum.sha256
    ;;
  verify)
    [[ -f checksum.sha256 ]] || { echo "dist/checksum.sha256 not found - run generate first"; exit 2; }
    sha256sum -c checksum.sha256
    ;;
esac
