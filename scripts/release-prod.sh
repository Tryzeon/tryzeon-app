#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/release-prod.sh <version>

Tags the commit this version's beta builds were made from and pushes the tag,
which triggers the release-ios / release-android / release-github workflows.

The release lanes promote the build that is already on TestFlight and the Play
internal track, so run scripts/release-beta.sh for this version first. Both
platforms must have a successful beta built from the same commit.

The version may be given with or without a leading 'v'.

Examples:
  scripts/release-prod.sh v1.2.0
  scripts/release-prod.sh 1.2.0
EOF
}

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI is required." >&2
  exit 1
fi

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

if [[ ! "$1" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must be a semantic version, for example v1.2.0 or 1.2.0" >&2
  exit 1
fi

version="${1#v}"
tag="v$version"

if [[ -n $(git ls-remote --tags origin "refs/tags/$tag") ]]; then
  echo "Error: tag $tag already exists on origin" >&2
  exit 1
fi

beta_commit() {
  local workflow="$1" run_name="$2"
  gh run list \
    --workflow "$workflow" \
    --branch main \
    --status success \
    --limit 100 \
    --json displayTitle,headSha \
    --jq "map(select(.displayTitle == \"$run_name\")) | first | .headSha // empty"
}

ios_commit=$(beta_commit beta-ios.yml "Beta - iOS $version")
android_commit=$(beta_commit beta-android.yml "Beta - Android $version")

if [[ -z "$ios_commit" || -z "$android_commit" ]]; then
  [[ -z "$ios_commit" ]] && echo "Error: no successful iOS beta found for $version" >&2
  [[ -z "$android_commit" ]] && echo "Error: no successful Android beta found for $version" >&2
  echo "Run scripts/release-beta.sh $version first." >&2
  exit 1
fi

if [[ "$ios_commit" != "$android_commit" ]]; then
  echo "Error: the latest $version betas were built from different commits" >&2
  echo "  iOS:     $ios_commit" >&2
  echo "  Android: $android_commit" >&2
  echo "Rebuild one platform with scripts/release-beta.sh $version --ios|--android so both match." >&2
  exit 1
fi

commit="$ios_commit"
git fetch --quiet origin main

echo "Are you sure you want to release $tag to production?"
echo "Beta commit: $(git log -1 --pretty='%h (%s)' "$commit")"
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Release cancelled"
  exit 0
fi

git tag -a "$tag" "$commit" -m "Release $tag"
git push origin "$tag"

echo "Pushed tag $tag — release workflows triggered"
