# Drafts — write blog posts here, no setup required

This branch is the team's **writing room** for italailabs.com blog posts. It
replaces the old `_drafts/` folder on `main`.

- Posts you work on live in [`_posts/`](https://github.com/ItalAILabs/italailabs.github.io/tree/drafts/_posts) — one markdown file per post, multiple drafts at once is fine.
- **Everything else (styling, layouts, assets) is not in this branch.** At build time the site pulls `main` and symlinks it in, so what you render locally always uses exactly the styling that is live. You should never see CSS or layout files appear here — if one does, it's a mistake.
- Nothing on this branch is ever deployed anywhere. It's a local writing environment; the only thing that leaves the branch is a publish PR to `main`.
- When a post is ready, it goes to `main` as a pull request of **the commits that built it** (cherry-picked). Merging *is* publishing.

## Seeing your post (one command, local)

```sh
scripts/build-preview.sh serve     # → http://localhost:4000 with live reload
```

Needs only Ruby 3.x + bundler — that's the whole toolchain. The script fetches
`main`, symlinks it in, and serves the full site with your drafts merged in:
exactly what will render on italailabs.com when you publish.

The **WYSIWYG editor** lives at `http://localhost:4000/editor/` off that same
local server: pick a draft, edit what-you-type-is-what-you-see, then *Copy
markdown* (paste into the GitHub web editor) or *Push to drafts branch*
(one-time: paste a fine-grained personal access token with write access to this
repo — stored only in your browser).

## Start a new post

1. On the `drafts` branch add `_posts/YYYY-MM-DD-slug.md` — in the repo UI: switch to `drafts` → `_posts/` → **Add file → Create new file** (or locally). The date is the publish date. Copy the front matter from [the example post](https://github.com/ItalAILabs/italailabs.github.io/blob/drafts/_posts/2026-08-01-example-post.md) and write your body in markdown.
2. Add any media under `assets/{images,videos,files}/drafts/` — that folder is exactly the path you'll reference in the post.
3. Commit to `drafts`. Keep commits scoped to your own post and its assets (e.g. “my-post: add figure 1”) — publishing cherry-picks commits, so scope is what keeps your PR clean.
4. See it: `scripts/build-preview.sh serve` → http://localhost:4000 — the full site with your post in it, exactly as it will render live.

## Edit an existing draft

Just commit to `drafts` (web editor or locally) and re-run the local preview.

- **GitHub web editor:** open the file → pencil icon → toggle **Write / Preview** → commit.
- **WYSIWYG:** open `http://localhost:4000/editor/`, pick the post, edit, then *Push to drafts branch* (one-time: paste a fine-grained personal access token with write access to this repo — it's stored only in your browser) or *Copy markdown* and paste into the web editor.
- **LLM:** the file is plain markdown — copy it into any chat model, ask for edits, paste back.

## Media (images, videos, files)

Put media on this branch under [`assets/`](https://github.com/ItalAILabs/italailabs.github.io/tree/drafts/assets) — the folder you upload to **is** the path the post references and the path it lives at on `main` (1:1, no translation):

| Upload to | Reference in your post as | Notes |
|---|---|---|
| `assets/images/drafts/<name>` | `/assets/images/drafts/<name>` | SVG as-is (preferred for figures); PNG/JPG auto-converted to WebP when you build |
| `assets/videos/drafts/<name>` | `/assets/videos/drafts/<name>` | served as-is — keep small (~100 MB GitHub cap); host big videos externally and just link |
| `assets/files/drafts/<name>` | `/assets/files/drafts/<name>` | PDFs, datasets, anything else you want to link from a post |

Examples: `![Figure 1](/assets/images/drafts/fig1.svg)` · `<video src="/assets/videos/drafts/demo.mp4" controls></video>` · `[Paper (PDF)](/assets/files/drafts/paper.pdf)`. You can also reuse existing site images instead of uploading, e.g. `/assets/images/posts/wizard.svg`.

## Publish a post

Publishing cherry-picks **the commits that built your post** onto a branch off `main` and opens a PR with exactly those — nothing else from the shared branch rides along. A commit is in scope if it touched your post file or an asset it references under `assets/{images,videos,files}/drafts/`.

**One command** (on this branch, any machine with git + push access):

```sh
scripts/publish.sh _posts/2026-08-15-our-new-system.md
# → lists the commits, cherry-picks them onto publish/2026-08-15-our-new-system
#   (off main), pushes, and prints a one-click "Open pull request" link.
# Add --dry-run to preview the commit list without creating anything.
```

**By hand:** the same thing manually —

```sh
git checkout -b publish/our-new-system origin/main
git cherry-pick <the commits that touched your post + its assets>
git push -u origin publish/our-new-system
```

The **Drafts review** check on the PR verifies it only touches `_posts/*.md` and draft media, and that the merged site builds. Merge → live at `italailabs.com/blog/<title>/`. Afterwards delete your post file (and assets) from this branch so it only holds what's still in flight.

## What is *not* allowed on this branch

- Copying styling, layouts, includes or assets from `main` into this branch (the only asset paths that live here are `assets/{images,videos,files}/drafts/`). Everything else is symlinked at build time; a committed copy would drift and break the "always current" guarantee (the build script refuses to run if it finds one).
- Merging the whole `drafts` branch into `main`. Publishing is always per-post via a small PR.
