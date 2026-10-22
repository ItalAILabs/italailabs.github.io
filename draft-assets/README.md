# draft-assets — media for draft posts

Three folders, one per kind of media. When you build locally
(`scripts/build-preview.sh serve`) each folder is served from the matching
`drafts/` subfolder of the site's asset tree:

| Put it here | Reference it in your post as | Notes |
|---|---|---|
| `images/<name>` | `/assets/images/drafts/<name>` | SVG works as-is (preferred for figures — export from matplotlib etc.); PNG/JPG are converted to WebP automatically at build time |
| `videos/<name>` | `/assets/videos/drafts/<name>` | served as-is; keep files small (GitHub caps uploads around 100 MB) — for big videos, host them elsewhere and just link |
| `files/<name>` | `/assets/files/drafts/<name>` | PDFs, datasets, anything else you want to link from a post |

Examples:

```md
![Figure 1](/assets/images/drafts/fig1.svg)

<video src="/assets/videos/drafts/demo.mp4" controls width="100%"></video>

[Full paper (PDF)](/assets/files/drafts/paper.pdf)
```

You can also reuse any existing site image instead of uploading, e.g.
`/assets/images/posts/wizard.svg`.

When you publish a post, include its media files — `scripts/publish.sh` copies
them to the right place on `main` automatically (and the publish check allows
exactly these paths).
