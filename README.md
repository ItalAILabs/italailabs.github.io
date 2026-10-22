# Drafts — write blog posts here, no setup required

This branch is the team's **writing room** for italailabs.com blog posts. It
replaces the old `_drafts/` folder on `main`.

- Posts you work on live in [`_posts/`](https://github.com/ItalAILabs/italailabs.github.io/tree/drafts/_posts) — one markdown file per post, multiple drafts at once is fine.
- **Everything else (styling, layouts, assets) is not in this branch.** At build time the site pulls `main` and symlinks it in, so what you render locally always uses exactly the styling that is live. You should never see CSS or layout files appear here — if one does, it's a mistake.
- Nothing on this branch is ever deployed anywhere. It's a local writing environment; the only thing that leaves the branch is a publish PR to `main`.
- When a post is ready, it goes to `main` through a small pull request. Merging *is* publishing.

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

## Start a new post (one PR per post)

1. In the repo UI, create a branch off `drafts` (branch dropdown → **Create new branch**, e.g. `my-new-post`).
2. On that branch add `_posts/YYYY-MM-DD-slug.md` (**Add file → Create new file**). The date is the publish date. Copy the front matter from [the example post](https://github.com/ItalAILabs/italailabs.github.io/blob/drafts/_posts/2026-08-01-example-post.md) and write your body in markdown. Add any media under [`draft-assets/`](https://github.com/ItalAILabs/italailabs.github.io/tree/drafts/draft-assets) if you need it.
3. Open a pull request **to `drafts`**. The **Drafts review** action validates it: front-matter sanity on your post plus a full build of the assembled site (main's live styling + all drafts). Fix anything it flags, then merge.
4. Once merged, run `scripts/build-preview.sh serve` and open http://localhost:4000 — your post is on the blog index.

## Edit an existing draft

Quick fix to something already on `drafts`? You can commit straight to the
branch (no validation runs). New posts should come in through a PR so they get
reviewed and checked.

- **GitHub web editor:** open the file → pencil icon → toggle **Write / Preview** → commit.
- **WYSIWYG:** open `http://localhost:4000/editor/`, pick the post, edit, then *Push to drafts branch* (one-time: paste a fine-grained personal access token with write access to this repo — it's stored only in your browser) or *Copy markdown* and paste into the web editor.
- **LLM:** the file is plain markdown — copy it into any chat model, ask for edits, paste back.

## Media (images, videos, files)

Put media in [`draft-assets/`](https://github.com/ItalAILabs/italailabs.github.io/tree/drafts/draft-assets) on this branch — three folders, one per kind:

| Folder | Served at | Notes |
|---|---|---|
| `images/` | `/assets/images/drafts/<name>` | SVG as-is (preferred for figures); PNG/JPG auto-converted to WebP when you build |
| `videos/` | `/assets/videos/drafts/<name>` | served as-is — keep small (~100 MB GitHub cap); host big videos externally and just link |
| `files/` | `/assets/files/drafts/<name>` | PDFs, datasets, anything else you want to link from a post |

[The folder's own README](https://github.com/ItalAILabs/italailabs.github.io/blob/drafts/draft-assets/README.md) has copy-paste examples. You can also reuse existing site images instead of uploading, e.g. `/assets/images/posts/wizard.svg`.

## Publish a post

A publish PR must contain **only** your post file (plus its `draft-assets/` images) — the *Validate draft PR* check enforces this, so it's impossible to accidentally ship half-finished drafts or branch plumbing.

**Easiest (browser only):**
1. Open your post file on the `drafts` branch → **Raw** (or `</>` button) → copy everything.
2. Switch to `main` in the repo UI → `_posts/` → **Add file → Create new file** with the *same filename* → paste.
3. Commit directly to `main` if you have write access, or open a PR from that point (compare `main…your-branch`).

**Or one command** (any machine with git + push access):

```sh
git checkout drafts && git pull
scripts/publish.sh _posts/2026-08-15-our-new-system.md draft-assets/fig1.svg
# → creates publish/2026-08-15-our-new-system from main with just those files,
#   pushes it, and prints a one-click "Open pull request" link.
```

After the PR merges: delete your file (and images) from this branch so it only holds what's still in flight.

## What is *not* allowed on this branch

- Copying styling, layouts, includes or assets from `main` into this branch. They're symlinked at build time; a committed copy would drift and break the "always current" guarantee (the build script refuses to run if it finds one).
- Merging the whole `drafts` branch into `main`. Publishing is always per-post via a small PR.
