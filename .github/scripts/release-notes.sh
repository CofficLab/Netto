#!/bin/bash
#
# Build release notes from the commits between a previous tag and HEAD.
#
# Usage: release-notes.sh <previous-tag|""> <new-version>
# Prints Markdown on stdout.
set -euo pipefail

repository="$(git rev-parse --show-toplevel)"
cd "$repository"

previous_tag="${1:-}"
version="${2:-}"
if [[ -z "$version" ]]; then
  echo "usage: release-notes.sh <previous-tag|''> <new-version>" >&2
  exit 1
fi

current_tag="v$version"
repo_slug="${GITHUB_REPOSITORY:-CofficLab/Netpause}"

if [[ -n "$previous_tag" ]]; then
  range="$previous_tag..HEAD"
  compare_url="https://github.com/$repo_slug/compare/$previous_tag...$current_tag"
else
  range="HEAD"
  compare_url=""
fi

commits="$(git log "$range" --no-merges --pretty=format:%s 2>/dev/null \
  | grep -Ev '^(ci|chore|build|style|test|docs)(\(|:)|^🎨|^👷|^Merge ' \
  | sed '/^[[:space:]]*$/d' \
  | sort -u || true)"

section() {
  local title="$1" pattern="$2" excluded="$3" items
  items="$(printf '%s\n' "$commits" | grep -E "$pattern" | grep -Ev "$excluded" || true)"
  [[ -n "$items" ]] || return 0
  printf '### %s\n\n' "$title"
  printf '%s\n' "$items" | sed 's/^/- /'
  printf '\n'
}

printf '## What'"'"'s Changed\n\n'

if [[ -n "$previous_tag" ]]; then
  printf 'Changes since `%s`.\n\n' "$previous_tag"
else
  printf 'Initial release.\n\n'
fi

section "Breaking Changes" '^[a-zA-Z]+(\([^)]*\))?!:' '^$'
section "Features" '^feat(\([^)]*\))?:' '^$'
section "Fixes" '^fix(\([^)]*\))?:' '^$'
section "Performance" '^perf(\([^)]*\))?:' '^$'
section "Other Changes" '.' '^(feat|fix|perf)(\([^)]*\))?:|^[a-zA-Z]+(\([^)]*\))?!:'

if ! printf '%s\n' "$commits" | grep -q .; then
  printf -- '- Maintenance and stability improvements\n\n'
fi

if [[ -n "$compare_url" ]]; then
  printf '**Full Changelog**: %s\n' "$compare_url"
fi
