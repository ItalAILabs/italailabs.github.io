# ItalAI

## Project Overview
ItalAI is a Jekyll-based static site. This project uses YAML files for structured data and supports blogging via Markdown posts.

---

## YAML Data Files (in `_data/`)
- **capabilities.yml**: Used in `work.html` — lists the core capabilities or features of ItalAI.
- **people.yml**: Used in `about.html` — contains information about team members or contributors.
- **principles.yml**: Used in `index.html` — outlines the guiding principles or values of the project.
- **revolution_cards.yml**: Used in `index.html` — defines content for "revolution cards" shown on the homepage.
- **roadmap_vision_cards.yml**: Used in `roadmap.html` — contains vision and roadmap items for the project.

These files are used to populate various sections of the site. Edit them to update content without changing HTML.

---

## Creating a Blog Post

```yaml
---
title: "Your Post Title"
categories: 
  - catagory1
  - catagory2
---
```

The "mamba" series has already been ported as an example—see the `_posts/` directory for reference.

---

## SEO and Meta Descriptions
Each blog post and root HTML page can set its own meta description for SEO purposes using the front matter `description` field:

```yaml
---
title: "Your Post Title"
description: "A short summary for SEO."
---
```

SEO Regex Check: used to search for a tags that go no where.
```regex
<a\s+(?![^>]*href)[^>]*>
```

The default meta description is set in `_config.yaml`.
No per-page descriptions have been written; all pages currently use the default unless you add a `description` field to the post's front matter or the HTML page.

---

## Plugins (`_plugins/`)
This project uses several custom Jekyll plugins:

- **webp_converter.rb**: Ensures the published site only allows WebP images. This plugin is essential for enforcing WebP-only image usage in production.
- **vips_webp_generator.rb**: Generates WebP images locally using the ruby-vips library. Note: This plugin will fail on GitHub Actions (deployment) due to Ruby version/library issues. The typical error is:
  > [vips-webp] ruby-vips not available: Could not open library 'vips.so.42': vips.so.42: cannot open shared object file: No such file or directory.
  
  This is not currently fixed and is ignored for deployment.
- **insights_manifest.rb**: Handles manifest generation for insights content.
- **lazy_load_images.rb**: Ensures images are set to lazy load (adds the `loading="lazy"` attribute to img tags).
- **remove_empty_lines.rb**: Cleans up empty lines in generated HTML, for client load performance.

---

## Running Locally
1. **Install Ruby** (version 3.3.8 recommended).
2. Run `bundle install` to install dependencies.
3. Start the development server:
  ```sh
  bundle exec jekyll serve --host 0.0.0.0 --port 4000 --livereload
  ```
  The `--livereload` flag enables fast development by automatically recompiling files when they change (after you save the file). This is especially useful for writing blog posts or editing content, as you get quick visual updates in your browser without needing to restart the server.
4. Visit [http://localhost:4000](http://localhost:4000) in your browser.

---


---

## Additional Notes & Best Practices

- **Image formats:** Only WebP images are published in the final site. Legacy raster assets (JPG, PNG, etc.) are excluded by `_config.yaml`.
- **SEO:** Meta descriptions are set via front matter or `_config.yaml`.
- **Plugin configuration:** See `_config.yaml` for plugin and manifest options.
- **Dynamic insights/blogs:** The insights manifest plugin enables paginated, filterable blog/insight loading on the frontend.
- **Performance:** Plugins like `remove_empty_lines.rb` and `lazy_load_images.rb` are used to optimize client load and rendering.
- **Development:** Use `--livereload` for a fast feedback loop. Save files to trigger reloads.
- **Deployment:** Some plugins (notably `vips_webp_generator.rb`) may not work on GitHub Actions due to system library constraints. This does not affect the published site, as only WebP assets are shipped.

For more, see the [Jekyll documentation](https://jekyllrb.com/docs/).



Dark Mode (?)

--dark-green: #32b692;          /* Keep the same - works well on dark */
--dark-green-alt: #1a4d3d;      /* Darker, muted alternative */
--dark-light: #2C2C2C;          /* Your dark-alt becomes the base */
--dark-light-alt: #3d3d3d;      /* Slightly lighter for contrast */
--dark-dark: #F6F4EC;           /* Your light becomes text color */
--dark-dark-alt: #D9CBB5;       /* Softer text for less emphasis */
--dark-red: #ff6b61;            /* Slightly brighter, easier to see */
--dark-blue: #8b9dff;           /* Lightened for better contrast */
--dark-disabled: #404040;       /* Darker disabled state */