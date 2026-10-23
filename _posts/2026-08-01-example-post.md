---
layout: post
title: "Example post — how this drafts branch works"
description: "A working example of a blog post on the drafts branch, with a short guide for researchers writing here."
image: "/assets/images/drafts/example-figure.svg"
hero_image: "/assets/images/drafts/example-figure.svg"
category: "Guides"
excerpt: "What this branch is, how to edit and preview posts without installing anything, and how a post gets published to italailabs.com."
published_in_blog: true
author: "ItalAI Research"
post_type: "Guide"
read_time: "3 min read"
---

## This is a draft. It lives on the `drafts` branch, not on the live site.

You are looking at a **local render** of the drafts branch (`scripts/build-preview.sh serve`) —
a minimal blog-only Jekyll build assembled at build time from `main`: only the
files the blog needs (layouts, styles, plugins) are symlinked in, and only the
blog pages are built. Every style, header, footer and card you see is the live
site's: nothing is duplicated or forked.

> **Rule of thumb:** if it looks like italailabs.com, that's because it *is*
> italailabs.com's styling — only the posts in `_posts/` on this branch are new.

## Editing without installing anything

You have three options, all from a browser:

1. **GitHub web editor** — open your file under [`_posts/`](https://github.com/ItalAILabs/italailabs.github.io/tree/drafts/_posts)
   on the `drafts` branch and click *Edit*. There is a **Write / Preview** toggle
   at the top of the box; the preview pane renders markdown.
2. **The WYSIWYG editor** — open [the draft editor](/blog/editor/) from the preview.
   It lists every draft on this branch, lets you edit in what-you-type-is-what-you-see
   mode, and can push your changes back to the branch (with a personal access token).
3. **An LLM** — this file is plain markdown. Copy it into any chat model, ask for
   edits, and paste the result back. Nothing about the format is special.

## The front matter cheat sheet

The block between the `---` lines at the top of the file controls how the post
is displayed. Only `title` is strictly required; everything else is optional:

```yaml
---
layout: post                      # always this
title: "Post title"               # used for the URL and <h1>
description: "One line for search + social cards."
image: "/assets/images/drafts/example-figure.svg"   # og:image for search/social
hero_image: "/assets/images/drafts/example-figure.svg"  # large card + header image
category: "Physical AI"           # shows as a tag on the blog index
excerpt: "Teaser shown in the blog listing."
published_in_blog: true           # false = hidden from the index, still has a URL
author: "Full Name"               # matched against _data/people.yml for the bio card
read_time: "8 min read"
---
```

### Media

Drop media on this branch under `assets/` — the folder you upload to is exactly the path you reference (1:1):

- **SVG figures** (matplotlib exports, diagrams) and **photos**: `assets/images/drafts/your-figure.svg` / `.png` / `.jpg` — the build converts photos to WebP automatically.
- **Videos**: `assets/videos/drafts/demo.mp4` (keep them small).
- **Other files** (PDFs, datasets): `assets/files/drafts/paper.pdf`.

You can also reference an existing live-site image (e.g. `/assets/images/posts/wizard.svg`) — it works on the published post; the local preview only ships this branch's own media.

A raw-HTML block works anywhere in the body — this one is a live example:

<div class="post-stats">
  <div class="stat-card stat-card--blue">
    <div class="stat-number">1</div>
    <div class="stat-label">branch, zero local tooling</div>
  </div>
  <div class="stat-card stat-card--green">
    <div class="stat-number">0</div>
    <div class="stat-label">styling files duplicated from main</div>
  </div>
</div>

## Publishing

When a post is ready, publish it with one command on this branch:

    scripts/publish.sh _posts/2026-08-15-our-new-system.md

It cherry-picks every commit that touched your post file (or an asset it
references) onto a fresh branch off `main`, pushes it, and prints a one-click
link to open the pull request. The **Drafts review** check verifies the PR
contains only your post + media and that the merged site builds. Merge → live
at `italailabs.com/blog/<your-title>/`. Afterwards delete your file (and assets)
from this branch so it doesn't linger here.

*This example post is safe to delete — it exists so you can see exactly what a
draft looks like once rendered.*
