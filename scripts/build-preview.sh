#!/usr/bin/env bash
#
# build-preview.sh — build a MINIMAL, blog-only preview of the drafts branch.
#
# Instead of assembling and building the whole site, this links in from main
# only the files needed to render:
#   /blog/          (the blog index)
#   /blog/<slug>/   (the draft posts on this branch)
#   /blog/editor/   (the WYSIWYG editor, branch-owned)
# Everything is a relative symlink into .main/ — a throwaway materialization of
# origin/main fetched at build time (gitignored) — so the preview always uses
# exactly the styling that is live on italailabs.com. Nothing is duplicated in
# this branch; only _posts/, assets/{images,videos,files}/drafts/ and this glue
# are committed here.
#
# Usage:
#   scripts/build-preview.sh          # build once into _site/ (+ draft manifest)
#   scripts/build-preview.sh serve    # live-reload server on http://localhost:4000
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAIN_DIR="$ROOT/.main"
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

# ------------------------------------------------- link the blog chain only
# linkfile <dest> <main-src>: symlink .main/<main-src> at <dest> with a relative
# target. Refuses if a real branch file would shadow it; fails clearly if main
# no longer has the file (allowlist drift).
linkfile() {
  local dest="$1" src=".main/$2" dir depth prefix i
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    # A real file/dir where a symlink to main belongs. Two cases:
    #  - git tracks files underneath: this branch is shadowing live-site
    #    assets — refuse loudly (the original tripwire).
    #  - git tracks nothing there: build leftover (e.g. generated WebP that
    #    got materialized through a dangling link; *.webp is git-ignored so
    #    it never shows in git status) — safe to remove and re-link.
    if [ -z "$(git ls-files -- "$dest" | head -1)" ]; then
      echo "!! '$dest' is an untracked build leftover — removing it and re-linking from main" >&2
      rm -rf -- "$dest"
    else
      echo "!! '$dest' exists on this branch but must be linked from main — remove the committed copy (styling files must not live here):" >&2
      git ls-files -- "$dest" | head -5 >&2
      exit 1
    fi
  fi
  dir="$(dirname "$dest")"
  if [ "$dir" = "." ]; then depth=0; else depth=$(awk -F/ '{print NF}' <<<"$dir"); fi
  prefix=""
  for ((i = 1; i <= depth; i++)); do prefix="../$prefix"; done
  ln -sfn "${prefix}${src}" "$dest"
}

# Whole directories (small, text-only): linking them whole keeps the preview
# working when main adds an include/partial/data file to the blog chain.
for p in _config.yaml Gemfile Gemfile.lock blog.html \
         _layouts _includes _sass _data; do
  linkfile "$p" "$p"
done

# Plugins: only what the blog chain runs. (projects-manifest and vcard are for
# the projects/ and /about/<person>/ pages, which this preview does not build.)
mkdir -p _plugins
for p in insights-manifest toc inline-figures responsive-images \
         webp-converter vips-webp-generator lazy-load-images remove-empty-lines; do
  linkfile "_plugins/$p.rb" "_plugins/$p.rb"
done

# Assets: only what the blog index, post pages and header/footer reference.
mkdir -p assets/css assets/images/posts
linkfile assets/css/blog.scss   assets/css/blog.scss
linkfile assets/css/post.scss   assets/css/post.scss
linkfile assets/js              assets/js
linkfile assets/fontawesome     assets/fontawesome
linkfile assets/favicon.svg     assets/favicon.svg
linkfile assets/logo.svg        assets/logo.svg
linkfile assets/logo.png        assets/logo.png
# blog-card fallback for posts without a hero image (main's only "shared" image)
linkfile assets/images/posts/coming.svg  assets/images/posts/coming.svg
# author avatars referenced by the post layout via _data/people.yml
linkfile assets/images/people    assets/images/people

# Sanity: every link we just created must resolve (allowlist drift → fail loud).
dangling=""
while IFS= read -r l; do
  [ -e "$l" ] || dangling="$dangling $l"
done < <(find . -path ./.git -prune -o -type l -print)
if [ -n "$dangling" ]; then
  echo "!! these links point at files main no longer has — update the allowlist in scripts/build-preview.sh:" >&2
  echo "$dangling" >&2
  exit 1
fi

# Refuse if this branch has committed any asset outside per-post media
# folders — such a file would silently shadow a live site asset in preview.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  stray_assets="$(git ls-files assets | grep -vE '^assets/(images|videos|files)/posts/' || true)"
  if [ -n "$stray_assets" ]; then
    echo "!! branch-committed files under assets/ outside assets/{images,videos,files}/posts/<slug>/ (they would shadow live site assets):" >&2
    echo "$stray_assets" >&2
    exit 1
  fi
fi

# Draft media sits at its FINAL production path on this branch:
#   assets/images/posts/<slug>/*  -> /assets/images/posts/<slug>/*
#   assets/videos/posts/<slug>/*  -> /assets/videos/posts/<slug>/*
#   assets/files/posts/<slug>/*   -> /assets/files/posts/<slug>/*
# (<slug> = the post filename without its date prefix.) The build derives
# everything else from these sources exactly like main's CI does: photos are
# converted to .webp and responsive sizes by main's vips-webp-generator plugin
# during the Jekyll build (it scans assets/images, which here contains only
# draft media) — libvips must be installed locally for that (see README).

# ----------------------------------------------------------------------- build
if ! bundle check >/dev/null 2>&1; then
  # Fresh clones have no writable system gem dir by default — install into a
  # project-local (gitignored) path instead.
  export BUNDLE_PATH="${BUNDLE_PATH:-$ROOT/vendor/bundle}"
  bundle install --quiet
fi

# The branch-owned _plugins/draft-local.rb hook publishes the editor's data
# (raw drafts at /drafts-src/ + drafts-manifest.json) into _site on every
# build and every `jekyll serve` rebuild.

if [ "$MODE" = "serve" ]; then
  # Local save server for the WYSIWYG editor: reads/writes _posts/ on this
  # checkout (127.0.0.1 only), so editing works without any GitHub round-trip.
  export DRAFT_SAVE_PORT="${DRAFT_SAVE_PORT:-$(( ${PORT:-4000} + 1 ))}"
  python3 scripts/draft-save-server.py &
  SAVE_PID=$!
  echo ""
  echo "==> editor:  http://localhost:${PORT:-4000}/blog/editor/   (WYSIWYG — saves to your local checkout)"
  echo "==> blog:    http://localhost:${PORT:-4000}/blog/"
  bundle exec jekyll serve --config _config.yaml,_config.draft.yaml --livereload --port "${PORT:-4000}"
  kill "$SAVE_PID" 2>/dev/null || true
fi

bundle exec jekyll build --config _config.yaml,_config.draft.yaml

echo "==> preview built into _site/ (blog only)"
