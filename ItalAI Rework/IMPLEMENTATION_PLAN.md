# ItalAI Site Rework — CSS/Visual Implementation

## Context

The `ItalAI Rework/` folder contains 10 Claude "design canvas" mockups (`.dc.html` files) representing an approved visual redesign of the ItalAI Labs marketing site. The production site is a Jekyll + Liquid + SCSS static site (deployed to `italailabs.com` via GitHub Pages). The goal of this pass is to carry the new visual language — colors, typography, spacing, layout patterns — into the production SCSS/Liquid, **without** rebuilding the site's existing data-driven architecture (`_data/*.yml` loops, includes, JS behaviors) unless a specific new pattern genuinely requires new markup.

**Scope for this pass**: the 6 pages that already exist in production — Home (`index.html`), About (`about.html`), What We Do (`work.html`), What's Next (`roadmap.html`), Insights (`insights.html`), and Insight Article (`_layouts/post.html`) — plus the shared header/footer.

**Explicitly out of scope (Phase 2, not built now)**: the mockups also include Careers, a standalone Contact page, a Projects listing, and a WIZARD project detail page. Verified across the local `main` checkout, every remote branch (`dev`, `dev2`, `old`, `master`, `backup-main-20260520`, `completion`), the live production site (`/contact`, `/careers`, `/projects`, `/wizard` all 404 live), full-text content search, and the GitHub account (only one repo) that none of these exist today, under any name, anywhere. Older branches did have a `contact.html` and a `research.html` + per-project detail page pattern (`research/halo.html`, `research/prego.html`) before the current redesign consolidated that into the footer contact form and the `/work` capabilities accordion — that precedent was intentionally retired, and "Careers" never existed on any branch. Building these 4 as dedicated pages is real new structure, not a CSS change, so it's called out here as a documented follow-up rather than folded into this pass.

**Interactive behavior**: existing interactive mechanisms are **preserved and reskinned**, not replaced with the mockup's static desktop-only versions — the mockups don't address mobile, and several of these exist specifically for mobile (e.g. the Owl Carousel partner-logo swap). This applies to: the About page values carousel + mobile partner-logo carousel, the What We Do capabilities accordion, and the Insights filter/pagination/load-more JS.

**Accent color**: adopted the mockup's Periwinkle `#6b6cf5` as the new `--standard-blue`.

**WIZARD link**: Home's "Find Out More" stays pointed at the external `https://fascetta.github.io/WIZARD/` until a Phase 2 internal project page exists.

## Design tokens (do first — everything else builds on this)

Update in **two places that must stay in sync** (both currently duplicate the same `:root` block): `_sass/_globals.scss` and `_includes/critical.scss`.

| Token | Old | New |
|---|---|---|
| `--standard-dark` | `#0D0221` | `#0c0717` |
| `--standard-light` | `#F6F4EC` | `#f4f1e6` |
| `--standard-blue` | `#6a7cff` | `#6b6cf5` |
| `--standard-green` | `#32b692` | `#29b485` |
| `--standard-red` | `#e4453a` | `#E63A1E` |

New tokens added: `--standard-green-bright: #2fcb92`, `--standard-blue-soft: #9b9cf7`, `--accent-family: "Spectral", serif`.

Font loading in `_layouts/default.html` extended to pull JetBrains Mono `400;500;700;800` (+ italics), DM Sans `400;500;600;700` (+ italics), and Spectral `400;500;600` italic `500`, combined into a single Google Fonts request, still async-preloaded.

## Shared components

**Header**: translucent blurred dark bar (`rgba(12,7,23,0.92)` + `backdrop-filter: blur`), plain-color nav links (no pill bg), outlined-pill CTA that fills with accent on hover. Pure CSS, markup unchanged.

**Footer**: existing contact-info/contact-form section restyled to new tokens. Added a new 3-column sitemap link band (Company / Research / Connect) above the existing grid — the one genuinely new bit of footer markup, reusing `site.social.*` already in `_config.yaml`. No links to Phase-2-only pages yet.

**Buttons/labels**: token-value updates only in `_components.scss`, no new classes.

## Per-page approach

**Home**: hero reflowed into a 2-column split (copy left, media right). "What We Do" cards restyled from color blocks into numbered hover-rows (content already matched mockup 1:1: Frontier Research / Applied Intelligence / Global Network). "Why Now" sticky-scroll with JS intersection tracking implemented. Partner wordmark bar added. Project/WIZARD stats section implemented. In-action video demo grid implemented. Insights preview rail implemented.

**Note on flowmap-hero.js**: The plan originally referenced preserving a `flowmap-hero.js` WebGL canvas interaction in the hero. This file was never tracked in git and does not exist in the repository. The hero currently renders a static background image (`hero-hands.webp`) via the `main-hero-media-fallback` class. The mockup's `image-slot` component is a design-canvas-only placeholder mechanism. If a WebGL hero interaction is desired in the future, it would be a new feature build, not a reskin.

**About**, **What We Do**, **What's Next**, **Insights** + **Insight Article**: not yet started. See per-page notes in the original plan discussion — each maps closely 1:1 in content to its mockup counterpart (principles.yml/people.yml/capabilities.yml/vision-cards.yml all already match), so this is primarily a token + layout-pattern restyle (reusing the sticky-label two-column intro pattern across About/What We Do/What's Next), not new data plumbing.

## Non-goals for this pass

- No new pages (Careers, Contact, Projects, WIZARD detail) — Phase 2.
- No changes to `_layouts/vcard.html` / `_sass/_vcard.scss`.
- No removal of existing JS-driven interactivity (carousels, accordion, filters).
- `assets/css/styles.scss` (legacy unused catch-all bundle) — left alone.

## Known issues found & fixed during implementation

- **Stale hardcoded hex colors**: swept `_index.scss`, `_blogs.scss`, `_components.scss`, `_work.scss`, `_insights.scss`, and `_includes/loading-screen.html` (an inline `style=` attribute, which would have silently overridden the token change via specificity) for hardcoded old-palette hex values not using the CSS custom properties, replaced with `var(--standard-*)`.
- **`--accent-family` token and Spectral font missing**: the plan specifies adding `--accent-family: "Spectral", serif` and loading the Spectral font via Google Fonts. These were not implemented. Fixed by adding the token to both `_globals.scss` and `critical.scss`, and extending the Google Fonts request in `_layouts/default.html`.
- Reverted an incidental `Gemfile.lock` platform/bundler-version churn caused by running `bundle install` locally to get a working build environment (this machine's Ruby 3.1.2 can't satisfy the committed lockfile's pinned bundler 4.0.3, which needs Ruby ≥3.2 — likely CI runs a newer Ruby) — not a real project change, kept out of the diff.

## Verification

- `bundle exec jekyll build` after every change — must be clean, no Liquid/Sass errors.
- Dev server (`bundle exec jekyll serve`) + curl/structural checks against rendered HTML and compiled CSS (no browser tooling available in this environment — a real visual/browser check by a human is still needed before shipping).
- Check `_globals.scss` and `critical.scss` token values stay identical.
- Click through all interactive elements per page once each page is restyled: mobile hamburger nav, About values-carousel + partner Owl Carousel, What We Do accordion, Insights filter + load-more, post prev/next nav, contact form submission.

## Audit status (post-implementation check)

### Completed
- [x] Design tokens updated in `_globals.scss` and `critical.scss` (all 5 color changes + 2 new tokens)
- [x] `--accent-family: "Spectral", serif` token added to both token files
- [x] Spectral font added to Google Fonts request in `_layouts/default.html`
- [x] Header restyled: translucent blur, plain nav links, outlined-pill CTA
- [x] Footer sitemap band added (3 columns: Company / Research / Connect)
- [x] Footer contact section restyled with new tokens
- [x] Home hero: 2-column split layout (copy left, media right)
- [x] Home "What We Do": numbered hover-rows (01/02/03)
- [x] Home "Why Now": sticky-scroll with JS intersection tracking
- [x] Home partners bar: wordmark bar with partner logos
- [x] Home WIZARD section: stats cards with token colors
- [x] Home "In Action": 4-column video demo grid
- [x] Home insights preview: horizontal rail with insight cards
- [x] Stale hardcoded hex colors swept from all SCSS and HTML files
- [x] Non-goals verified: vcard untouched, styles.scss untouched, JS interactivity preserved

### Remaining (other pages — Phase 1 continuation)
- [ ] About page visual restyle (layout patterns, spacing, font adjustments)
- [ ] What We Do page visual restyle (sticky-label pattern, accordion refinements)
- [x] What's Next / Roadmap page visual restyle — hero, hero hero/intro, and CTA were already done from a prior pass; this pass replaced the leftover sticky-cover-scroll "vision cards" (old pre-rework interaction, not part of the mockup) with a flat alternating image/text row list matching the mockup's 01–05 layout. Per explicit user direction, the "Looking Ahead" intro was folded into the same row list as its first (image-less) entry so the whole section — intro included — shares one continuous alternating rhythm instead of being a separate component. `assets/js/vision-cards.js` (scroll-cover JS, no longer used) removed.
- [ ] Insights page visual restyle
- [ ] Insight Article / Post layout visual restyle
- [ ] Browser visual QA across all breakpoints (requires human check)
