#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/release-beta.sh <version> [--ios | --android]

Examples:
  scripts/release-beta.sh 1.2.0
  scripts/release-beta.sh 1.2.0 --ios
  scripts/release-beta.sh 1.2.0 --android
EOF
}

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI is required." >&2
  exit 1
fi

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage >&2
  exit 1
fi

version="$1"
platform="${2:-all}"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must be semantic, for example 1.2.0" >&2
  exit 1
fi

run_ios=false
run_android=false

case "$platform" in
  all)
    run_ios=true
    run_android=true
    ;;
  --ios)
    run_ios=true
    ;;
  --android)
    run_android=true
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac

if [[ "$run_ios" == true ]]; then
  gh workflow run beta_ios.yml -f version="$version"
  echo "Triggered iOS beta workflow for version $version"
fi

if [[ "$run_android" == true ]]; then
  gh workflow run beta_android.yml -f version="$version"
  echo "Triggered Android beta workflow for version $version"
fi
