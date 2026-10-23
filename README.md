# Drafts — write blog posts here, no setup required

This branch is the team's **writing room** for italailabs.com blog posts. It
replaces the old `_drafts/` folder on `main`.

- Posts you work on live in [`_posts/`](https://github.com/ItalAILabs/italailabs.github.io/tree/drafts/_posts) — one markdown file per post, multiple drafts at once is fine.
- **Everything else (styling, layouts, assets) is not in this branch.** At build time the script pulls `main` and symlinks in only the files the blog needs (layouts, includes, styles, plugins), so what you render locally always uses exactly the styling that is live. You should never see CSS or layout files appear here — if one does, it's a mistake.
- Nothing on this branch is ever deployed anywhere. It's a local writing environment; the only thing that leaves the branch is a publish PR to `main`.
- When a post is ready, it goes to `main` as a pull request of **the commits that built it** (cherry-picked). Merging *is* publishing.
- **Working with a coding agent?** Point it at [`CLAUDE.md`](CLAUDE.md) — that file teaches any agent the branch's rules and commands.

## Pick it up in 60 seconds

```sh
git clone -b drafts git@github.com:ItalAILabs/italailabs.github.io.git && cd italailabs.github.io
scripts/build-preview.sh serve
```

Open **http://localhost:4000/blog/editor/** — pick a draft (or hit *New draft*),
edit what-you-type-is-what-you-see, then *Push to drafts branch*. That's the whole loop.

- No Ruby on your machine? Skip straight to editing on GitHub: [`_posts/`](https://github.com/ItalAILabs/italailabs.github.io/tree/drafts/_posts) → pencil icon. Posts are plain markdown; [the example post](https://github.com/ItalAILabs/italailabs.github.io/blob/drafts/_posts/2026-08-01-example-post.md) is the reference.
- Starting a new post locally? `scripts/new-post.sh "My Post Title"` writes the file with all front matter done for you.
- Post finished? `scripts/publish.sh _posts/<your-file>` → open the printed PR link → ask a second person to review and merge. Merging *is* publishing.

## Seeing your post (one command, local)

```sh
scripts/build-preview.sh serve     # → http://localhost:4000 with live reload
```

Needs only Ruby 3.x + bundler — that's the whole toolchain (plus libvips if
your drafts contain PNG/JPG photos: `sudo apt-get install libvips-dev` or
`brew install vips` — SVG figures work without it). The script fetches `main`,
symlinks in only what the blog needs, and serves a **minimal blog-only preview**:
`/blog/` with your drafts, each post at `/blog/<slug>/`, and the editor. Only
the blog pages are built — no homepage, no projects, none of main's other
images — so it starts in seconds.

The **WYSIWYG editor** lives at `http://localhost:4000/blog/editor/` off that
same local server: pick a draft, edit what-you-type-is-what-you-see, then *Copy
markdown* (paste into the GitHub web editor) or *Push to drafts branch*
(one-time: paste a fine-grained personal access token with write access to this
repo — stored only in your browser).

## Start a new post

1. **Locally:** `scripts/new-post.sh "My Post Title" [category]` — creates `_posts/YYYY-MM-DD-my-post-title.md` with all front matter filled in (the date is the publish date). **On GitHub:** switch to `drafts` → `_posts/` → **Add file → Create new file**, copying the front matter from [the example post](https://github.com/ItalAILabs/italailabs.github.io/blob/drafts/_posts/2026-08-01-example-post.md).
2. Add any media under `assets/{images,videos,files}/posts/<slug>/` (`<slug>` = your filename without the date) — that folder is exactly the path you'll reference in the post, and where it will live on the live site.
3. Commit to `drafts`. Keep commits scoped to your own post and its assets (e.g. “my-post: add figure 1”) — publishing cherry-picks commits, so scope is what keeps your PR clean.
4. See it: `scripts/build-preview.sh serve` → http://localhost:4000/blog/ — the blog with your post on it, styled exactly like the live site.

## Edit an existing draft

Just commit to `drafts` (web editor or locally) and re-run the local preview.

- **GitHub web editor:** open the file → pencil icon → toggle **Write / Preview** → commit.
- **WYSIWYG:** open `http://localhost:4000/blog/editor/`, pick the post, edit, then *Push to drafts branch* (one-time: paste a fine-grained personal access token with write access to this repo — it's stored only in your browser) or *Copy markdown* and paste into the web editor.
- **LLM / coding agent:** the file is plain markdown — copy it into any chat model, ask for edits, paste back. For a coding agent working in the repo (Claude Code, Codex, …), open the branch and point it at [`CLAUDE.md`](CLAUDE.md) — it knows the rules and every command.

## Media (images, videos, files)

Put media on this branch under [`assets/`](https://github.com/ItalAILabs/italailabs.github.io/tree/drafts/assets), in a folder per post — `<slug>` is your filename without the date prefix. The folder you upload to **is** the path the post references and the path it lives at on `main` (1:1, no translation):

| Upload to | Reference in your post as | Notes |
|---|---|---|
| `assets/images/posts/<slug>/<name>` | `/assets/images/posts/<slug>/<name>` | SVG as-is (preferred for figures); PNG/JPG auto-converted to WebP when you build, exactly like main's CI |
| `assets/videos/posts/<slug>/<name>` | `/assets/videos/posts/<slug>/<name>` | served as-is — keep small (~100 MB GitHub cap); host big videos externally and just link |
| `assets/files/posts/<slug>/<name>` | `/assets/files/posts/<slug>/<name>` | PDFs, datasets, anything else you want to link from a post |

Examples: `![Figure 1](/assets/images/posts/my-post/fig1.svg)` · `<video src="/assets/videos/posts/my-post/demo.mp4" controls></video>` · `[Paper (PDF)](/assets/files/posts/my-post/paper.pdf)`. You can also reference an existing live-site image (e.g. `/assets/images/posts/wizard.svg`) — it works on the published post; the local preview only ships this branch's own media.

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

- Copying styling, layouts, includes or assets from `main` into this branch (the only asset paths that live here are per-post media folders, `assets/{images,videos,files}/posts/<slug>/`). Everything else is symlinked at build time; a committed copy would drift and break the "always current" guarantee (the build script refuses to run if it finds one).
- Merging the whole `drafts` branch into `main`. Publishing is always per-post via a small PR.
