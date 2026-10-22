#!/usr/bin/env bash
#
# publish.sh — prepare a publish PR for one draft post (power-user path).
#
# Creates a branch `publish/<slug>` from the tip of main containing ONLY the
# given post file (plus any extra files you pass, e.g. its images), pushes
# it, and prints a link that opens the pull request against main in one
# click. The "Validate draft PR" check on the PR makes sure only post files
# and draft images are included.
#
# Usage:
#   scripts/publish.sh <post file> [extra files...]
#   e.g. scripts/publish.sh _posts/2026-08-01-my-post.md draft-assets/fig1.svg
#
# Extra files under draft-assets/ are placed on main at assets/images/drafts/
# (main's CI turns them into .webp automatically).
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

REPO="ItalAILabs/italailabs.github.io"
file="${1:?usage: scripts/publish.sh <post file in _posts/> [extra files...]}"
shift || true

file="${file#_posts/}"; file="${file#/}"
[ -f "_posts/$file" ] || { echo "no such draft: _posts/$file" >&2; exit 1; }

slug="$(basename "$file" .md)"
branch="publish/$slug"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# Stash everything the PR should contain, then switch to a clean main.
cp "_posts/$file" "$tmpdir/post.md"
for extra in "$@"; do
  [ -f "$extra" ] || { echo "no such file: $extra" >&2; exit 1; }
  cp "$extra" "$tmpdir/$(basename "$extra")"
done

# Drop any build-time symlinks from a local preview so the switch is clean.
find . -maxdepth 1 -type l -exec rm -f {} +

git fetch --quiet --depth=1 origin main
git switch -C "$branch" origin/main

cp "$tmpdir/post.md" "_posts/$file"
for extra in "$@"; do
  base="$(basename "$extra")"
  case "$extra" in
    draft-assets/*)
      mkdir -p assets/images/drafts
      cp "$tmpdir/$base" "assets/images/drafts/$base"
      ;;
    *)
      # any other path is mirrored as-is onto main
      mkdir -p "$(dirname "$extra")"
      cp "$tmpdir/$base" "$extra"
      ;;
  esac
done

git add "_posts/$file" "$@" 2>/dev/null || git add .
git commit -m "Publish: $slug"

git push -u origin "$branch"

echo ""
echo "Branch pushed. Open the pull request here (one click):"
echo "  https://github.com/${REPO}/compare/main...${branch}?expand=1"
echo ""
echo "After it merges, delete _posts/$file from the drafts branch."
