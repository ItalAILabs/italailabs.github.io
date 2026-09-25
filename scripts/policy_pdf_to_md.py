#!/usr/bin/env python3
"""Convert the privacy policy PDF to Markdown with a purely mechanical mapping.

Usage: python3 scripts/policy_pdf_to_md.py <input.pdf> <output.md>

The script runs `pdftotext -layout`, strips zero-width characters, reflows
wrapped lines, and maps structure to markdown:
  - title line            -> # heading
  - "N. Section" lines    -> ## heading
  - standalone subheads   -> ### heading
  - "a."-"e." item lines  -> **bold** on its own line
  - "●" bullets           -> "- " bullets (deeper-indented continuations attach)
  - everything else       -> paragraph text, verbatim

No wording is added, removed, or rephrased.
"""

import re
import subprocess
import sys

FRONTMATTER = """---
title: "Privacy and Cookie Policy"
layout: default
description: "Privacy and Cookie Policy of ItalAI S.R.L., covering the processing of personal data on italailabs.com under GDPR."
---

"""

TITLE = "PRIVACY AND COOKIE POLICY"
SUBHEADS = {
    "What Are Cookies and Tracking Technologies?",
    "Cookie Settings",
    "A. By Purpose",
    "B. By Publisher",
    "C. By Duration",
}

SECTION_RE = re.compile(r"^\s*(\d+)\.\s+")
LETTER_RE = re.compile(r"^\s*([a-e])\.\s+")
BULLET_RE = re.compile(r"^\s*●")


def extract_text(pdf_path: str) -> str:
    out = subprocess.run(
        ["pdftotext", "-layout", pdf_path, "-"],
        capture_output=True, text=True, check=True,
    )
    text = out.stdout.replace("\u200b", "")  # zero-width spaces from the PDF
    return text


def convert(lines):
    blocks = []  # list of (kind, text)
    prev_blank = True
    for raw in lines:
        line = raw.rstrip("\n")
        if not line.strip():
            prev_blank = True
            continue
        stripped = line.strip()
        # Headings/items are standalone lines in the PDF, so they must be
        # preceded by a blank line; otherwise they are wrapped continuations.
        if stripped == TITLE and prev_blank:
            blocks.append(("h1", stripped, prev_blank))
        elif prev_blank and SECTION_RE.match(line):
            blocks.append(("h2", stripped, prev_blank))
        elif prev_blank and stripped in SUBHEADS:
            blocks.append(("h3", stripped, prev_blank))
        elif prev_blank and LETTER_RE.match(line):
            blocks.append(("bold", stripped, prev_blank))
        elif BULLET_RE.match(line):
            blocks.append(("bullet", stripped.lstrip(" ●"), prev_blank))
        else:
            blocks.append(("para", stripped, prev_blank))
        prev_blank = False

    # Reflow: wrapped continuation lines (no blank line before them) merge
    # into the previous block (paragraph or bullet). Lettered-item bodies
    # are NOT blank-line separated from the title in the PDF, so they are
    # left as their own paragraphs and fixed by post-conversion diffs.
    out = []
    for kind, text, broke in blocks:
        if kind == "para" and not broke and out and out[-1][0] in ("para", "bullet"):
            out[-1] = (out[-1][0], out[-1][1] + " " + text)
        else:
            out.append((kind, text))
    return out


def render(blocks):
    md = []
    for kind, text in blocks:
        if kind == "h1":
            md.append(f"\n# {text}\n\n")
        elif kind == "h2":
            md.append(f"\n## {text}\n\n")
        elif kind == "h3":
            md.append(f"\n### {text}\n\n")
        elif kind == "bold":
            md.append(f"\n**{text}**\n")
        elif kind == "bullet":
            md.append(f"- {text}\n")
        else:
            md.append(f"{text}\n\n")
    return "".join(md)


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    text = extract_text(sys.argv[1])
    blocks = convert(text.splitlines())
    with open(sys.argv[2], "w", encoding="utf-8") as f:
        f.write(FRONTMATTER)
        f.write(render(blocks))
        f.write("\n")
    print(f"wrote {sys.argv[2]} from {sys.argv[1]}")


if __name__ == "__main__":
    main()
