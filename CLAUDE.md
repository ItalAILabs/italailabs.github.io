# Agent guide — `drafts` branch of italailabs.github.io

You are assisting a **writer** (not a developer) on the `drafts` branch of the
italailabs.com Jekyll site. Your job: help them create and polish posts, add
media, preview locally, and prepare publish PRs. This file is your operating
manual — follow it exactly; the invariants below exist because this branch has
a strict contract with `main`.

## What this branch is

A minimalist writing room. It contains **only**:

| Path | What it is |
|---|---|
| `_posts/*.md` | Draft posts (one file per post; filename = publish date + slug) |
| `assets/{images,videos,files}/posts/<slug>/` | Per-post media, at their **final production paths** |
| `editor.html` | WYSIWYG editor, served at `/blog/editor/` by the local preview |
| `scripts/build-preview.sh` | Minimal blog-only local build (fetches `main`, symlinks the blog chain) |
| `scripts/draft-manifest.rb` | Writes `drafts-manifest.json` for the editor's post picker |
| `scripts/new-post.sh` | Scaffolds a new post with correct front matter |
| `scripts/publish.sh` | Cherry-picks one post's commits onto a branch off `main`, prints a PR link |
| `_config.draft.yaml`, `README.md`, `.github/workflows/drafts.yml` | Config, human docs, CI |

Everything else the site needs (layouts, includes, sass, plugins, styles) is
**symlinked from a throwaway fetch of `origin/main` into `.main/` at build
time**. It never lives on this branch.

## Hard rules — never break these

1. **Never commit styling/layout/include files or any asset outside per-post media folders.** The only committed asset paths are `assets/{images,videos,files}/posts/<slug>/`. A committed copy of a main file breaks the "always current" guarantee and `scripts/build-preview.sh` refuses to run.
2. **Media paths are 1:1.** Path on branch = path referenced in the post = final path on `main`. Never rename, move or "tidy" media paths; there is no translation step at publish time.
3. **Never merge `drafts` into `main`, never push to `main`, never merge any PR yourself.** Publishing is a per-post PR created by `scripts/publish.sh`; a human reviewer merges it. You may create the publish branch and open/print the PR link — stopping there.
4. **Never commit build artifacts:** `.main/`, `_site/`, `vendor/`, `drafts-manifest.json`, `assets/vcards/`, or symlinks (`find . -path ./.git -prune -o -type l`). If you ran a build, clean these before committing; `git status` must show only content + glue.
5. **Keep commits scoped per post** (e.g. `my-post: add figure 1`). Publishing cherry-picks commits by the paths they touched — a commit that mixes two posts drags both into the PR and CI rejects it.

## Recipes

### Create a post
```sh
scripts/new-post.sh "My Post Title" [category]   # → _posts/YYYY-MM-DD-my-post-title.md
```
Hand-written alternative: copy the front matter from `_posts/2026-08-01-example-post.md`.
The date in the filename is the **publish date**. Required front matter: `layout: post`, `title`.
Useful optional: `description`, `category`, `excerpt`, `published_in_blog` (false = hidden from index),
`author`, `read_time`, and the `image:`/`hero_image:` pair (same file, for card + header).

### Add media
Put files under `assets/images/posts/<slug>/` (also `videos/` and `files/` with the same
pattern). SVG is preferred for figures; PNG/JPG are converted to WebP automatically at build
time by main's vips plugin (needs libvips locally — say so if photos don't render).
Reference them in the post exactly as `/assets/<the-rest-of-the-path>`.

### Preview locally
```sh
scripts/build-preview.sh serve     # → http://localhost:4000/blog/editor/ and /blog/
```
Needs Ruby 3.x + bundler (+ libvips for photos). The script fetches `origin/main` into `.main/`
and symlinks **only the blog chain** — it builds just `/blog/`, `/blog/<slug>/`, `/blog/editor/`.
Never edit anything under `.main/`; it is regenerated every run. If the build fails with a
"refusing to link over it" or "dangling link" error, report it — that means main changed and
the allowlist in `scripts/build-preview.sh` needs updating (a deliberate tripwire).

### Check a post before publishing
```sh
scripts/publish.sh --dry-run _posts/<file>   # lists exactly which commits + assets would ship
```
Also verify: front matter parses, media referenced in the post exist under
`assets/*/posts/<slug>/`, and the post renders at `/blog/<slug>/` in the preview.

### Publish
```sh
scripts/publish.sh _posts/<file>
# → cherry-picks the post's commits onto publish/<slug> (off main), pushes, prints a PR link
```
Then: open the PR; CI (*Drafts review* workflow) checks the PR touches only `_posts/*.md` +
per-post media and builds the full site with it; **a second person** reviews and merges —
merging goes live at `italailabs.com/blog/<slug>/`. Afterwards delete the post file and its
media folder from this branch so it only holds what's still in flight.

## Do not

- Don't run `jekyll` directly — always through `scripts/build-preview.sh` (it sets up the
  symlinked main tree and the `_config.yaml,_config.draft.yaml` config pair).
- Don't "fix" files that belong to `main` (layouts, plugins, styles). If you find a real bug
  there, report it to the writer; the fix goes in its own PR to `main`.
- Don't add new scripts, dependencies or tooling to this branch without asking — minimalism is
  the point. The four scripts above are the entire glue surface.
- Don't reformat or rewrite existing posts' front matter unless asked; treat their content as
  the writer's property and change only what they request.
