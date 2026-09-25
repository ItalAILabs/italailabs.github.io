# ItalAI

Jekyll static site for [italailabs.com](https://italailabs.com) (ItalAI S.R.L.).
Pushes to `main` build and deploy automatically via GitHub Actions to GitHub Pages.

Pages: `/` · `/about` · `/blog` · `/contact` · `/partnership` · `/projects` · `/research` · `/policy` · `/404`

---

## Content data (`_data/`)

Structured content is edited in YAML, not HTML:

| File | Used by |
|---|---|
| `people.yml` | `/about` team section, post author lookup, vCard generation |
| `principles.yml` | `/about` principles section |
| `partners.yml` | partners bar (homepage + `/about`) |
| `publications.yml` | `/research` — publication cards, filterable by domain |
| `revolution-cards.yml` | homepage "revolution" cards |
| `vision-cards.yml` | homepage roadmap/vision cards |

## Blog posts (`_posts/`)

```yaml
---
layout: post
title: "Your Post Title"
description: "Short SEO summary shown in meta tags and listings."
category: "Architectures"
excerpt: "One-line teaser for the blog listing."
image: "/assets/images/blog/cards/your-card.svg"
hero_image: "/assets/images/blog/cards/your-card.svg"
series: mamba        # optional — series grouping
part: 2              # optional — position within the series
published_in_blog: true
author: "Full Name"  # must match a person in _data/people.yml
---
```

The mamba series (3 posts) is the reference implementation. `/blog` is
filterable and paginated — the listing data is generated at build time by
`_plugins/insights-manifest.rb` (see `blogs_manifest` in `_config.yaml`).

## SEO

- Each page/post sets its own `description` front matter; the default lives
  in `_config.yaml`. `jekyll-seo-tag` and `jekyll-sitemap` handle the rest.
- To find anchor tags with no destination:

  ```regex
  <a\s+(?![^>]*href)[^>]*>
  ```

## Plugins (`_plugins/`)

| Plugin | Job |
|---|---|
| `responsive-images.rb` | Adds `srcset`/`sizes` to `<img>` tags (WebP + responsive sizes) |
| `vips-webp-generator.rb` | Generates WebP (400/800/1200/1600, q78) from source JPG/PNG via libvips |
| `webp-converter.rb` | Rewrites `.jpg`/`.jpeg`/`.png` references to `.webp` in CSS/JSON/NDJSON output |
| `insights-manifest.rb` | Builds the blog manifest for the filterable `/blog` page |
| `projects-manifest.rb` | Same for `/projects` |
| `lazy-load-images.rb` | Adds `loading="lazy"` to img tags |
| `remove-empty-lines.rb` | Strips blank lines from rendered output |
| `vcard.rb` | Generates `.vcf` files from `people.yml` into `assets/vcards/` |

## Images

- Source images (JPG/PNG) live in `assets/images/` and are **published
  alongside** their WebP — browsers pick via `srcset`. The commented
  `exclude:` lines in `_config.yaml` would flip this to WebP-only.
- WebP is generated at build time: locally by the Jekyll plugin, in CI by
  the same script run in CLI mode. The `generated-assets` branch holds the
  committed WebP set plus `manifest.sha256`; CI diffs changed images against
  it and skips generation entirely when no images changed. Re-seed the
  branch after image changes to restore the fast path (CI still works
  without it — it just regenerates everything).
- KaTeX is lazy-loaded from jsDelivr (v0.18.9) only on pages containing
  `.kdmath` / `.math-block` (`assets/js/katex-loader.js`).

## Running locally

1. Ruby 3.3+ (CI uses 3.3) and `bundle install`.
2. For WebP generation, install libvips (`apt install libvips42` on
   Debian/Ubuntu). Without it the build logs a warning and continues using
   the committed WebP.
3. Always run through Bundler (plain `jekyll` hits gem activation
   conflicts):

   ```sh
   bundle exec jekyll serve --host 0.0.0.0 --port 4000 --livereload
   ```

   `--livereload` recompiles on save — useful for posts and content edits.
4. Visit <http://localhost:4000>.

## Analytics & consent (GDPR)

- Google Analytics 4 (`G-70VK7F6E5Q`) is **opt-in** via Consent Mode v2:
  all consent signals default to denied in `_layouts/default.html` and are
  granted only after the visitor accepts.
- The banner (`_includes/consent-banner.html` + `assets/js/consent.js`)
  stores the choice in `localStorage` (`italai_consent`) for 30 days and
  re-asks on expiry; Escape declines.
- First-party UTM capture (`assets/js/utm.js`) runs only with an active
  accept choice; tags expire after 30 days and feed only the contact form's
  hidden inputs.
- That's the full tracking inventory.

## Security

- Reporting policy: `SECURITY.md` (repo root) — report a vulnerability to
  `research@italailabs.com`, never a public issue.
- `/.well-known/security.txt` (in `.well-known/`, included in the build via
  `_config.yaml`) points to it.
- CI runs with `contents: read` + Pages deployment permissions only;
  third-party actions are SHA-pinned.

## Deployment

`.github/workflows/jekyll.yml`: build (Jekyll + WebP overlay) → deploy via
the GitHub Pages actions. Normal runs skip WebP generation when no images
changed; runs touching `assets/images/` regenerate the changed ones in the
runner before deploy.

## Scripts (`scripts/`)

- `policy_pdf_to_md.py` — one-off mechanical converter that produced
  `policy.md` from the 2026 privacy PDF (on the `backup-main-20260520`
  branch); re-run it to re-verify the word-for-word conversion.
- `compare_webp_sizes.rb` — WebP size comparison utility.
