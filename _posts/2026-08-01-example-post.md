---
layout: post
title: "Example post — how this drafts branch works"
description: "A working example of a blog post on the drafts branch, with a short guide for researchers writing here."
image: "/assets/images/posts/wizard.svg"
category: "Guides"
excerpt: "What this branch is, how to edit and preview posts without installing anything, and how a post gets published to italailabs.com."
published_in_blog: true
author: "ItalAI Research"
post_type: "Guide"
read_time: "3 min read"
---

## This is a draft. It lives on the `drafts` branch, not on the live site.

You are looking at the **preview** of the drafts branch — the same Jekyll build
as the real site, assembled at build time from `main` plus whatever posts are
being worked on here. Every style, header, footer and card you see is the live
site's, pulled in as symlinks at build time: nothing is duplicated or forked.

> **Rule of thumb:** if it looks like italailabs.com, that's because it *is*
> italailabs.com's styling — only the posts in `_posts/` on this branch are new.

## Editing without installing anything

You have three options, all from a browser:

1. **GitHub web editor** — open your file under [`_posts/`](https://github.com/ItalAILabs/italailabs.github.io/tree/drafts/_posts)
   on the `drafts` branch and click *Edit*. There is a **Write / Preview** toggle
   at the top of the box; the preview pane renders markdown.
2. **The WYSIWYG editor** — open [the draft editor](/editor.html) from the preview.
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
image: "/assets/images/posts/foo.svg"   # hero image (see below)
category: "Physical AI"           # shows as a tag on the blog index
excerpt: "Teaser shown in the blog listing."
published_in_blog: true           # false = hidden from the index, still has a URL
author: "Full Name"               # matched against _data/people.yml for the bio card
read_time: "8 min read"
---
```

### Images

- **SVG figures** (matplotlib exports, diagrams): drop them in `draft-assets/` on
  this branch and reference `/assets/images/drafts/your-figure.svg`.
- **Photos**: put the original `.png`/`.jpg` in `draft-assets/` too; the preview
  build converts it to WebP automatically.
- You can also reuse any existing site image, e.g. `/assets/images/posts/wizard.svg`.

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

When a post is ready:

1. Open a **publish pull request** that adds *only* your `_posts/…` file (and any
   `draft-assets/` images) to `main`. The easiest way is the compare link:
   [`github.com/ItalAILabs/italailabs.github.io/compare/main…your-branch`](https://github.com/ItalAILabs/italailabs.github.io/compare/main...drafts).
2. The **Validate draft PR** check builds the site with your post and confirms
   nothing else changed.
3. Merge → the post goes live at `italailabs.com/blog/<your-title>/`.
4. Delete your file from the `drafts` branch so it doesn't linger here.

*This example post is safe to delete — it exists so you can see exactly what a
draft looks like once rendered.*
