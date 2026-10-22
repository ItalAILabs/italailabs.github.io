#!/usr/bin/env bash
#
# build-preview.sh — build the drafts-branch preview site.
#
# This branch deliberately contains only content (draft posts in _posts/,
# draft images in draft-assets/) plus this glue. Everything else — layouts,
# includes, sass, assets, data, config, plugins — is fetched from main at
# build time into .main/ and linked into the repo root with relative
# symlinks, so the preview always renders with exactly the styling that is
# live on italailabs.com. Nothing is duplicated in this branch; .main/ and
# .genassets/ are throwaway materializations (gitignored) rebuilt from
# scratch on every run.
#
# Usage:
#   scripts/build-preview.sh          # build once into _site/ (+ draft manifest)
#   scripts/build-preview.sh serve    # live-reload server on http://localhost:4000
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAIN_DIR="$ROOT/.main"
GEN_DIR="$ROOT/.genassets"
REPO="ItalAILabs/italailabs.github.io"   # only used for the tarball fallback
MODE="${1:-build}"

cd "$ROOT"
export TZ="${TZ:-Europe/Rome}"            # match main's CI so dates line up
export JEKYLL_ENV="${JEKYLL_ENV:-production}"

# ---------------------------------------------------------------- materialize
fetch_ref() { # $1 = branch name, $2 = destination dir
  local ref="$1" dest="$2"
  rm -rf "$dest"; mkdir -p "$dest"
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
     && git fetch --quiet --depth=1 origin "refs/heads/${ref}:refs/remotes/origin/${ref}" 2>/dev/null; then
    git archive "origin/${ref}" | tar -x -C "$dest"
    echo "==> ${ref} @ $(git rev-parse --short "origin/${ref}")"
  else
    curl -fsSL "https://codeload.github.com/${REPO}/tar.gz/refs/heads/${ref}" | tar -xz -C "$dest"
    echo "==> ${ref} (codeload tarball)"
  fi
}

fetch_ref main "$MAIN_DIR"
# generated-assets holds the .webp images that main's CI overlays before
# building; without them, published post/author images would 404 in preview.
fetch_ref generated-assets "$GEN_DIR" \
  || { rm -rf "$GEN_DIR"; echo "!! generated-assets unavailable — some images will be missing"; }

# ------------------------------------------- link main's tree into the build root
# Files/dirs this branch owns are left untouched; everything else from main
# becomes a relative symlink so Jekyll sees one complete site. (Jekyll runs
# with safe: false, which it needs for these symlinks — see _config.yaml.)
OWNED=" .github .gitignore _posts scripts README.md editor.html _config.draft.yaml draft-assets "

for item in "$MAIN_DIR"/* "$MAIN_DIR"/.[!.]*; do
  [ -e "$item" ] || continue
  name="$(basename "$item")"
  case "$OWNED" in *" $name "*) continue ;; esac
  if [ -L "$ROOT/$name" ]; then
    # Idempotent re-runs: keep our own link, replace stale ones.
    [ "$(readlink "$ROOT/$name")" = ".main/$name" ] && continue
    rm "$ROOT/$name"
  elif [ -e "$ROOT/$name" ]; then
    echo "!! '$name' already exists in the branch tree — refusing to link over it (styling files must not be committed here)" >&2
    exit 1
  fi
  ln -s ".main/$name" "$ROOT/$name"
done

# main's CI overlays generated .webp images on top of assets before building;
# do the same (writes through the symlink into our throwaway .main copy).
if [ -d "$GEN_DIR/assets/images" ]; then
  while IFS= read -r f; do
    rel="${f#./}"
    mkdir -p "assets/images/$(dirname "$rel")"
    cp "$GEN_DIR/assets/images/$f" "assets/images/$rel"
  done < <(cd "$GEN_DIR/assets/images" && find . -name '*.webp')
fi

# Draft images: serve from /assets/images/drafts/ and generate .webp versions
# (the site's responsive-images plugin rewrites every .png/.jpg reference to
# .webp at build time). SVG needs no conversion.
if [ -d draft-assets ]; then
  bundle check >/dev/null 2>&1 || bundle install --quiet
  bundle exec ruby scripts/draft-images-webp.rb || echo "!! webp generation unavailable — photos may not render in preview"
  mkdir -p assets/images/drafts
  cp -r draft-assets/. assets/images/drafts/
fi

# ------------------------------------------------- merge posts (drafts + main)
# _posts/ on this branch holds only drafts; link in main's published posts so
# the preview shows every draft in the context of the live blog. A file that
# exists on both sides (a post being reworked) resolves to THIS branch's copy.
mkdir -p _posts
for post in "$MAIN_DIR"/_posts/*.md; do
  [ -e "$post" ] || continue
  name="$(basename "$post")"
  [ -e "_posts/$name" ] && continue
  ln -s "../.main/_posts/$name" "_posts/$name"
done

# ----------------------------------------------------------------------- build
bundle check >/dev/null 2>&1 || bundle install --quiet

if [ "$MODE" = "serve" ]; then
  exec bundle exec jekyll serve --config _config.yaml,_config.draft.yaml --livereload --port "${PORT:-4000}"
fi

bundle exec jekyll build --config _config.yaml,_config.draft.yaml

# Draft manifest consumed by editor.html (this branch's drafts only).
bundle exec ruby scripts/draft-manifest.rb

echo "==> preview built into _site/"
