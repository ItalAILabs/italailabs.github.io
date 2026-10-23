#!/usr/bin/env bash
#
# new-post.sh — scaffold a new draft post with correct front matter.
#
# Usage:
#   scripts/new-post.sh "Our New System"            # category defaults to Research
#   scripts/new-post.sh "Our New System" "Physical AI"
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

title="${1:?usage: scripts/new-post.sh \"Post title\" [category]}"
category="${2:-Research}"
date="$(date +%F)"
slug="$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
file="_posts/${date}-${slug}.md"

if [ -e "$file" ]; then
  echo "already exists: $file (edit that one)" >&2
  exit 1
fi

cat > "$file" <<EOF
---
layout: post
title: "${title}"
description: "One-line summary shown in search and social cards."
category: "${category}"
excerpt: "A short teaser for the blog index (one or two sentences)."
published_in_blog: true
author: "Your Name"
read_time: "5 min read"
# Once you have a figure, add both lines pointing at the same file in
# assets/images/posts/${slug}/ (the build converts photos to WebP automatically):
# image: "/assets/images/posts/${slug}/figure.svg"
# hero_image: "/assets/images/posts/${slug}/figure.svg"
---

## Intro

Write here. Standard markdown — headings, lists, quotes, code blocks, links.
Figures live in \`assets/images/posts/${slug}/\` and are referenced as
\`/assets/images/posts/${slug}/<name>\`.
EOF

echo "==> created $file"
echo ""
echo "Next:"
echo "  1. Open it (GitHub web editor, or scripts/build-preview.sh serve → /blog/editor/)"
echo "  2. Add media under assets/images/posts/${slug}/ if you have figures"
echo "  3. Commit to drafts — when done: scripts/publish.sh $file"
