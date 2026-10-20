# ItalAI

Jekyll static site for [italailabs.com](https://italailabs.com) (ItalAI S.R.L.).
Pushes to `main` build and deploy automatically via GitHub Actions to GitHub Pages.

Pages: `/` · `/about` · `/blog` · `/contact` · `/partnership` · `/projects` · `/research` · `/policy` · `/404`

Generated at build time: post pages at `/blog/<title>/`, project detail
pages under `/projects/` (from the `_projects/` collection), and one vCard
page per team member at `/about/<person>/` (from `people.yml` via
`_plugins/vcard.rb`).

---

## Content data (`_data/`)

Structured content is edited in YAML, not HTML:

| File | Used by |
|---|---|
| `people.yml` | `/about` team section, post author lookup, vCard generation |
| `principles.yml` | `/about` principles section |
| `partners.yml` | partners bar (homepage + `/about`) |
| `publications.yml` | `/research` — publication cards, filterable by domain |

## Blog posts (`_posts/`)

```yaml
---
layout: post
title: "Your Post Title"
description: "Short SEO summary shown in meta tags and listings."
category: "Foundations"
excerpt: "One-line teaser for the blog listing."
image: "/assets/images/posts/your-card.svg"
hero_image: "/assets/images/posts/your-card.svg"
series: mamba        # optional — series grouping
part: 2              # optional — position within the series
published_in_blog: true
author: "Full Name"  # must match a person in _data/people.yml
author_role: "Role, Organisation"   # optional per-post override of the people.yml role
institution: "Sapienza"             # optional
author_bio: "One-line credentials"  # optional per-post override (wins over people.yml)
post_type: "Explainer"              # optional badge
read_time: "6 min read"
paper_links:                        # optional — link chips under the title
  - label: "Paper · arXiv"
    url: "https://arxiv.org/abs/..."
---
```

The mamba series (3 posts) is the reference implementation; WIZARD
(`2026-10-20-wizard.md`) is the reference for inline figures and the ToC.
`/blog` is filterable and paginated — the listing data is generated at build
time by `_plugins/insights-manifest.rb` (see `blogs_manifest` in
`_config.yaml`).

**Authoring tools:** `{% raw %}{% inline_svg "path.svg" ["note"] %}{% endraw %}` and
`{% raw %}{% inline_img "path.png" "alt" ["note"] %}{% endraw %}` embed an image plus optional
caption as one width-sharing unit (`_plugins/inline-figures.rb`);
`{{ content | toc }}` renders a nested ToC from h2–h4 with no client JS
(`_plugins/toc.rb`).

**Dates and publishing:** the filename date is the post's publish date.
Jekyll excludes future-dated posts from builds (no `future: true` in
`_config.yaml`), so a future-dated post goes live at the **next build after
its date** — i.e. the next push to `main`, not automatically on the date
itself. `_drafts/` is never built; `jekyll serve` renders files there
locally at `/drafts/<slug>/` for preview only.

## Stylesheets

Per-page CSS: `_layouts/default.html` loads `/assets/css/<page>.css`, chosen
from the page URL (`post` / `project` / `vcard` / `404` for generated pages,
otherwise the filename). Each entry `assets/css/<page>.scss` `@use`s shared
partials from `_sass/`; critical above-the-fold CSS is inlined via
`_includes/critical.scss`. Adding a page means adding both the `.html` and
its `.scss` entry.

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
| `vcard.rb` | Generates `.vcf` files from `people.yml` into `assets/vcards/` + `/about/<person>/` pages |
| `inline-figures.rb` | `{% inline_svg %}` / `{% inline_img %}` — image + caption as one unit |
| `toc.rb` | `{{ content \| toc }}` filter — nested ToC from h2–h4, no JS |

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
   Debian/Ubuntu; CI uses `libvips-dev`). Without it **no WebPs exist on
disk** — they're gitignored and the committed set lives only on the
   `generated-assets` branch, which CI overlays. Since
   `responsive-images.rb` rewrites every `img src` to `.webp`, a local
   preview without libvips will 404 all images.
3. Always run through Bundler (plain `jekyll` hits gem activation
   conflicts):

   ```sh
   bundle exec jekyll serve --host 0.0.0.0 --port 4000 --livereload
   ```

   `--livereload` recompiles on save — useful for posts and content edits.
4. Visit <http://localhost:4000>.
5. Drafts in `_drafts/` are served (never built) at `/drafts/<slug>/`
   while `jekyll serve` runs — local preview only.

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
  `ruby/setup-ruby` is SHA-pinned, the GitHub-certified actions are pinned
  to major-version tags.

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
