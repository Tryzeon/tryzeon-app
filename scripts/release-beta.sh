#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/release-beta.sh [<version>] [--ios | --android]

The version may be given with or without a leading 'v'. When omitted, it
defaults to the next minor version after the highest vX.Y.Z tag on origin
(e.g. v1.22.0 -> 1.23.0).

Examples:
  scripts/release-beta.sh
  scripts/release-beta.sh --ios
  scripts/release-beta.sh v1.2.0
  scripts/release-beta.sh 1.2.0
  scripts/release-beta.sh v1.2.0 --ios
  scripts/release-beta.sh 1.2.0 --android
EOF
}

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI is required." >&2
  exit 1
fi

version=""
platform="all"

for arg in "$@"; do
  case "$arg" in
    --ios | --android)
      if [[ "$platform" != all ]]; then
        usage >&2
        exit 1
      fi
      platform="$arg"
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      if [[ -n "$version" || ! "$arg" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        usage >&2
        exit 1
      fi
      version="${arg#v}"
      ;;
  esac
done

if [[ -z "$version" ]]; then
  git fetch --tags --quiet origin
  latest_tag=$(git tag --list 'v*' --sort=v:refname | grep -Ex 'v[0-9]+\.[0-9]+\.[0-9]+' | tail -n 1 || true)
  if [[ -z "$latest_tag" ]]; then
    echo "Error: no vX.Y.Z tag found; pass the version explicitly" >&2
    exit 1
  fi
  IFS=. read -r major minor _ <<<"${latest_tag#v}"
  version="$major.$((minor + 1)).0"
  echo "Latest tag: $latest_tag -> next version: $version"
fi

current_branch=$(git branch --show-current)
if [[ "$current_branch" != "main" ]]; then
  echo "Error: releases must be run from 'main' (current branch: '$current_branch')" >&2
  exit 1
fi

# Check for unpushed commits
if [[ -n $(git log "origin/$current_branch..HEAD") ]]; then
  echo "Error: You have unpushed commits" >&2
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
esac

# Confirmation prompt
echo "Are you sure you want to release version $version?"
if [[ "$run_ios" == true && "$run_android" == true ]]; then
  echo "Platform: iOS and Android"
elif [[ "$run_ios" == true ]]; then
  echo "Platform: iOS"
elif [[ "$run_android" == true ]]; then
  echo "Platform: Android"
fi
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Release cancelled"
  exit 0
fi

if [[ "$run_ios" == true ]]; then
  gh workflow run beta-ios.yml -f version="$version"
  echo "Triggered iOS beta workflow for version $version"
fi

if [[ "$run_android" == true ]]; then
  gh workflow run beta-android.yml -f version="$version"
  echo "Triggered Android beta workflow for version $version"
fi
