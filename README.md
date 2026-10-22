# Drafts — write blog posts here, no setup required

This branch is the team's **writing room** for italailabs.com blog posts. It
replaces the old `_drafts/` folder on `main`.

- Posts you work on live in [`_posts/`](https://github.com/ItalAILabs/italailabs.github.io/tree/drafts/_posts) — one markdown file per post, multiple drafts at once is fine.
- **Everything else (styling, layouts, assets) is not in this branch.** At build time the site pulls `main` and symlinks it in, so the preview always uses exactly the styling that is live. You should never see CSS or layout files appear here — if one does, it's a mistake.
- When a post is ready, it goes to `main` through a small pull request. Merging *is* publishing.

## The two links you need

| Link | What it is |
|---|---|
| **Preview** (Vercel URL — see the latest deployment in the [Actions tab](https://github.com/ItalAILabs/italailabs.github.io/actions) or ask for it) | The full site with your drafts rendered. Updates a few minutes after every push to this branch. |
| **Draft editor** (preview URL + `/editor/`) | WYSIWYG markdown editor: pick a draft, edit what-you-see, push back to the branch. |

## Start a new post

1. In the repo UI switch to the `drafts` branch → `_posts/` → **Add file → Create new file**.
   (Or download a template from the [editor page](https://github.com/ItalAILabs/italailabs.github.io/blob/drafts/editor.html).)
2. Name it `YYYY-MM-DD-slug.md`, e.g. `2026-08-15-our-new-system.md`. The date is the publish date.
3. Copy the front matter from [the example post](https://github.com/ItalAILabs/italailabs.github.io/blob/drafts/_posts/2026-08-01-example-post.md) and write your body in markdown.
4. Commit to `drafts`. Wait a couple of minutes, open the preview, find your post on the blog index.

## Edit an existing draft

- **GitHub web editor:** open the file → pencil icon → toggle **Write / Preview** → commit.
- **WYSIWYG:** open `/editor/` on the preview, pick the post, edit, then *Push to drafts branch* (one-time: paste a fine-grained personal access token with write access to this repo — it's stored only in your browser) or *Copy markdown* and paste into the web editor.
- **LLM:** the file is plain markdown — copy it into any chat model, ask for edits, paste back.

## Images

Put them in [`draft-assets/`](https://github.com/ItalAILabs/italailabs.github.io/tree/drafts/draft-assets) on this branch (Add file → upload). Reference them as `/assets/images/drafts/<name>`:

- SVG works as-is (preferred for figures — export from matplotlib etc.).
- PNG/JPG are converted to WebP automatically when the preview builds.

You can also reuse existing site images, e.g. `/assets/images/posts/wizard.svg`.

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

After the PR merges: delete your file (and images) from this branch so the preview reflects what's still in flight.

## Local preview (optional, for anyone who wants it)

One command, no other setup — same materialize-and-link build as CI:

```sh
ruby -v   # needs Ruby 3.x + bundler (that's all)
scripts/build-preview.sh serve
# → http://localhost:4000 with live reload
```

## What is *not* allowed on this branch

- Copying styling, layouts, includes or assets from `main` into this branch. They're symlinked at build time; a committed copy would drift and break the "always current" guarantee (the build script refuses to run if it finds one).
- Merging the whole `drafts` branch into `main`. Publishing is always per-post via a small PR.
