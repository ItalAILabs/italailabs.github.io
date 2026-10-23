#!/usr/bin/env bash
#
# build-preview.sh — build the drafts-branch preview site.
#
# This branch deliberately contains only content (draft posts in _posts/, draft
# media under assets/{images,videos,files}/drafts/) plus this glue. Everything
# else — layouts, includes, sass, the rest of the asset tree, data, config,
# plugins — is fetched from main at build time into .main/ and linked in with
# relative symlinks 1:1 by path, so what you render always uses exactly the
# styling that is live on italailabs.com. Nothing is duplicated in this branch;
# .main/ and .genassets/ are throwaway materializations (gitignored) rebuilt
# from scratch on every run.
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
#
# OWNED = fully branch-owned (never merged with main).
# PARTIAL = branch-owned dirs that merge 1:1 with main's tree: whatever main
# has under them that this branch doesn't gets symlinked in, so a file at
# assets/images/drafts/fig.svg on this branch is the same path on main.
OWNED=" .github .gitignore _posts scripts README.md editor.html _config.draft.yaml assets "
PARTIAL=" assets "

link_into() { # $1 = relative dir under the root ("assets", "assets/images", ...)
  local rel="$1" item name slashes prefix="" i
  slashes="${rel//[^\/]/}"; for ((i = 0; i <= ${#slashes}; i++)); do prefix="../$prefix"; done
  for item in "$MAIN_DIR/$rel"/* "$MAIN_DIR/$rel"/.[!.]*; do
    [ -e "$item" ] || continue
    name="$(basename "$item")"
    if [ -d "$item" ] && [ -d "$ROOT/$rel/$name" ]; then
      link_into "$rel/$name"            # both sides have this dir → recurse
    elif [ ! -e "$ROOT/$rel/$name" ] && [ ! -L "$ROOT/$rel/$name" ]; then
      ln -s "${prefix}.main/$rel/$name" "$ROOT/$rel/$name"
    fi                                   # branch file wins (re-runs included)
  done
}

for item in "$MAIN_DIR"/* "$MAIN_DIR"/.[!.]*; do
  [ -e "$item" ] || continue
  name="$(basename "$item")"
  case "$OWNED" in *" $name "*)
    case "$PARTIAL" in *" $name ")
      [ -d "$item" ] && [ -d "$ROOT/$name" ] && link_into "$name"
    ;; esac
    continue ;;
  esac
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

# Draft media already sits at its final, 1:1 path on this branch:
#   assets/images/drafts/*  -> /assets/images/drafts/*   (+ auto .webp)
#   assets/videos/drafts/*  -> /assets/videos/drafts/*
#   assets/files/drafts/*   -> /assets/files/drafts/*
# Generate .webp next to each photo (the site's responsive-images plugin
# rewrites every .png/.jpg reference to .webp at build time).
if [ -d assets/images/drafts ]; then
  bundle check >/dev/null 2>&1 || bundle install --quiet
  bundle exec ruby scripts/draft-images-webp.rb || echo "!! webp generation unavailable — photos may not render in preview"
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
