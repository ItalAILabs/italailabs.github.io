# Drafts — write blog posts here

This branch is the team's writing room for [italailabs.com](https://italailabs.com) blog posts.
You don't need to be a programmer: everything can be done from a browser, and there's an optional
local preview that shows your post exactly as it will appear on the live site.

**The one thing to remember:** nothing here goes live by itself. Your work stays on this branch
until a pull request to `main` is reviewed by a second person and merged. Merging *is* publishing.

## The loop

1. **Write** — your post is one markdown file in [`_posts/`](https://github.com/ItalAILabs/italailabs.github.io/tree/drafts/_posts).
2. **Look at it** *(optional)* — a local preview with a what-you-type-is-what-you-see editor.
3. **Publish** — one command creates a pull request; someone else reviews and merges; the post goes live.

## 1 · Write your post

### From a browser (no install)

1. On this branch, open [`_posts/`](https://github.com/ItalAILabs/italailabs.github.io/tree/drafts/_posts) → **Add file** → **Create new file**.
2. Name it `YYYY-MM-DD-short-name.md` — the date is when you want the post to publish (e.g. `2026-11-03-our-new-system.md`).
3. Copy the top block from [the example post](https://github.com/ItalAILabs/italailabs.github.io/blob/drafts/_posts/2026-08-01-example-post.md) — the lines between the two `---` — and write your text below it. That block is called *front matter*; it sets the title, teaser, author and so on, and the example post explains each line.
4. Commit. Repeat as often as you like — commits here are just saves.

### With the local editor (recommended)

One-time setup: install [Ruby](https://www.ruby-lang.org/en/install/) (plus `libvips` if your posts contain photos). Then, from a copy of this branch:

```sh
scripts/build-preview.sh serve
```

Open **http://localhost:4000/blog/editor/** — pick a draft or hit *New draft*, edit what-you-type-is-what-you-see, then *Save locally*: your file is written straight into the `_posts/` folder of this copy and the preview updates by itself. No token, no GitHub round-trip. (A *Push to GitHub* button is there too, if you ever want to commit from the browser — that one does need a personal access token.) The same server shows the blog itself at **http://localhost:4000/blog/**.

The preview builds only the blog and pulls the live site's styling automatically, so what you see is exactly what will render on italailabs.com — it starts in seconds and nothing is uploaded anywhere.

Prefer to skip the front matter entirely? `scripts/new-post.sh "My Post Title"` writes the file for you.

## 2 · Add pictures, videos, files

Put them in a folder per post — replace `<slug>` with your filename without the date:

| You upload to | You reference in the post as |
|---|---|
| `assets/images/posts/<slug>/figure.svg` | `/assets/images/posts/<slug>/figure.svg` |
| `assets/videos/posts/<slug>/demo.mp4` | `/assets/videos/posts/<slug>/demo.mp4` |
| `assets/files/posts/<slug>/paper.pdf` | `/assets/files/posts/<slug>/paper.pdf` |

The folder you upload to **is** the final address on the live site — no renaming, no moving.
SVG is best for figures; photos (PNG/JPG) are converted automatically when the site builds.
Keep videos small (GitHub's ~100 MB limit) or host them elsewhere and just link.
You can also reference an existing live-site image (e.g. `/assets/images/posts/wizard.svg`) — it works on the published post.

## 3 · Publish your post

When you're happy with it:

```sh
scripts/publish.sh _posts/2026-11-03-our-new-system.md
```

This creates a pull request containing **only your post and its media** — nothing else on this branch — and prints a link to open it. Then:

1. Open the link and ask a second person to review it.
2. They check it, approve, and merge — the post goes live at `italailabs.com/blog/…`.
3. Delete your file (and media folder) from this branch; it lives on `main` now.

Two tips: keep your commits about one post at a time (“my-post: add figure 1”) — that's what keeps the pull request clean. And if you'd rather not run the command, any colleague (or a coding agent, below) can do the same thing for you.

## With LLM help (optional)

- **Any chat model:** posts are plain markdown. Paste your file into a chat, ask for edits, paste the result back.
- **A coding agent** (Claude Code, Codex, …): open this branch in its terminal and point it at [`CLAUDE.md`](CLAUDE.md) — that file is its operating manual: the rules of this branch and every command above.

## Why this branch looks so empty

On purpose. Styling, layouts and site assets are **not** stored here — the preview pulls them from `main` automatically, so they're always exactly what's live. The only files that belong on this branch are posts, per-post media, and the small tools in `scripts/`. If you ever see a CSS file or a copy of a page appear here, something went wrong — tell us.

And this branch is never merged as a whole: publishing is always one post at a time, through a reviewed pull request.
