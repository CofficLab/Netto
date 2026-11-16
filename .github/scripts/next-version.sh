#!/bin/bash
#
# Decide the next MARKETING_VERSION from Conventional Commits since the
# latest v* tag:
#   - breaking change              -> major
#   - feat / feat(scope)           -> minor
#   - everything else (fix, etc.)  -> patch
#
# A MARKETING_VERSION raised manually ahead of the latest tag is kept as-is.
# Prints the version on stdout and diagnostics on stderr.
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

project_file="$(find "$repo_root" -type f -name "project.xcproj" | head -n 1)"
if [[ -z "$project_file" ]]; then
  echo "project.xcproj not found" >&2
  exit 1
fi

current_version="$(grep -Eo '"MARKETING_VERSION": "[0-9]+\.[0-9]+\.[0-9]+"' "$project_file" \
  | head -n 1 | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+')"
if [[ -z "$current_version" ]]; then
  echo "MARKETING_VERSION not found in $project_file" >&2
  exit 1
fi

last_tag="$(git tag -l 'v*' | sort -V | tail -n 1 || true)"
last_version="${last_tag#v}"
last_version="${last_version:-0.0.0}"

base_version="$(printf '%s\n%s\n' "$last_version" "$current_version" | sort -V | tail -n 1)"

# MARKETING_VERSION is an explicit decision: if the repository is already
# ahead of the latest release tag, do not bump it a second time.
if [[ "$current_version" != "$last_version" && "$base_version" == "$current_version" ]]; then
  echo "using repository version $current_version (latest tag v$last_version)" >&2
  echo "$current_version"
  exit 0
fi

if [[ -n "$last_tag" ]] && git rev-parse -q --verify "refs/tags/$last_tag" >/dev/null; then
  range="$last_tag..HEAD"
else
  range="HEAD"
fi

subjects="$(git log "$range" --no-merges --pretty=format:%s 2>/dev/null || true)"
messages="$(git log "$range" --no-merges --pretty=format:%B 2>/dev/null || true)"

increment=patch
if printf '%s\n' "$messages" | grep -qE '(BREAKING[ -]CHANGE)|(^[a-zA-Z]+(\([^)]*\))?!:)'; then
  increment=major
elif printf '%s\n' "$subjects" | grep -qE '^feat(\([^)]*\))?:'; then
  increment=minor
fi

IFS='.' read -r major minor patch <<<"$base_version"
major="${major:-0}"
minor="${minor:-0}"
patch="${patch:-0}"

case "$increment" in
  major) echo "$((major + 1)).0.0" ;;
  minor) echo "$major.$((minor + 1)).0" ;;
  *) echo "$major.$minor.$((patch + 1))" ;;
esac

echo "bump: $increment (base $base_version, tag ${last_tag:-none})" >&2
