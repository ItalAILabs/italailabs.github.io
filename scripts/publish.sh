#!/usr/bin/env bash
#
# publish.sh — prepare a publish PR for one draft post by cherry-picking the
# commits that built it onto a fresh branch off main.
#
# A commit is included if it (on this branch, not on main) touched either
#   - the given post file, or
#   - an asset the post references under assets/{images,videos,files}/drafts/
# so the PR contains exactly that post's history — nothing else from the
# branch rides along.
#
# Usage:
#   scripts/publish.sh <post file>            # create + push publish/<slug>, print PR link
#   scripts/publish.sh --dry-run <post file>  # just list what would be cherry-picked
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

REPO="ItalAILabs/italailabs.github.io"
DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && { DRY_RUN=1; shift; }

file="${1:?usage: scripts/publish.sh [--dry-run] <post file in _posts/>}"
file="${file#_posts/}"; file="${file#/}"
[ -f "_posts/$file" ] || { echo "no such draft: _posts/$file" >&2; exit 1; }

slug="$(basename "$file" .md)"
branch="publish/$slug"

# Refresh main first so the commit range below is accurate.
if [ "$(git rev-parse --is-shallow-repository)" = "true" ]; then
  git fetch --quiet --unshallow origin
else
  git fetch --quiet origin main
fi

# The post's assets = everything it references at its 1:1 paths.
assets="$(grep -oE '/assets/(images|videos|files)/posts/[A-Za-z0-9._/-]+' "_posts/$file" | sort -u || true)"
paths=("_posts/$file")
while IFS= read -r a; do [ -n "$a" ] && paths+=("${a#/}"); done <<< "$assets"

# Warn about referenced assets that should exist on this branch (inside the
# post's own media folder) but do not — usually a filename with spaces or
# special characters the reference regex truncated. References outside the
# post's folder are assumed to be intentional reuse of live-site assets.
post_slug="$(basename "$file" .md)"
post_slug="${post_slug#[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-}"
for a in "${paths[@]:1}"; do
  case "$a" in
    assets/*/posts/"$post_slug"/*)
      [ -e "$a" ] || echo "!! referenced asset not found on this branch: $a — check the post's reference (spaces and special characters in media filenames are unsupported)" ;;
  esac
done

commits="$(git log --reverse --format=%H origin/main..HEAD -- "${paths[@]}")"
if [ -z "$commits" ]; then
  echo "no commits on this branch (not on main) touch _posts/$file or its assets" >&2
  exit 1
fi

echo "Commits that would be cherry-picked onto main:"
git log --oneline origin/main..HEAD -- "${paths[@]}" | sed 's/^/  /'

# Pre-flight: warn if any of those commits also touch other files — they would
# ride along in the PR and the publish check on main will reject it.
touched="$(for c in $commits; do git show --name-only --format= "$c"; done | sort -u)"
stray="$(echo "$touched" | sed '/^[[:space:]]*$/d' | grep -vxF -f <(printf '%s\n' "${paths[@]}") || true)"
if [ -n "$stray" ]; then
  echo ""
  echo "!! warning: these commits also touch files outside the post + its assets:"
  echo "$stray" | sed 's/^/   /'
  echo "   They would be included in the PR and the publish check will reject it."
  echo "   Re-scope those commits on this branch before publishing."
fi

[ "$DRY_RUN" = 1 ] && { echo ""; echo "(dry run — nothing created)"; exit 0; }

# Drop local build symlinks so the branch switch is clean (NUL-delimited:
# paths may contain spaces).
find . -path ./.git -prune -o -type l -print0 2>/dev/null | xargs -0 -r rm -f --

git switch -C "$branch" origin/main

# shellcheck disable=SC2086
if ! git cherry-pick $commits; then
  echo ""
  echo "Cherry-pick conflict. Resolve the files, then:" >&2
  echo "  git cherry-pick --continue && git push -u origin $branch" >&2
  exit 1
fi

git push -u origin "$branch"

echo ""
echo "Branch pushed. Open the pull request here (one click):"
echo "  https://github.com/${REPO}/compare/main...${branch}?expand=1"
echo ""
echo "After it merges, delete _posts/$file and its assets from this branch."
