#!/usr/bin/env python3
# draft-save-server.py — tiny localhost helper for the WYSIWYG editor.
#
# Serves raw draft markdown straight from _posts/ and accepts saves back into
# it, so the editor reads and writes your LOCAL checkout (no GitHub
# round-trip). Binds to 127.0.0.1 only; started automatically by
# `scripts/build-preview.sh serve` (port: DRAFT_SAVE_PORT, default 4001).
#
#   GET  /ping            -> "ok"
#   GET  /src/<file>      -> raw markdown of _posts/<file>
#   POST /save            -> {"file": "...", "content": "..."} writes _posts/<file>
#   GET  /files/<slug>    -> {"files": [{"type", "name", "path"}, ...]}
#   POST /upload          -> multipart fields "slug" and one "file"; stores per-post media
#
# Post filenames must match YYYY-MM-DD-*.md. Media slugs are path-safe; uploads
# are stored only under assets/{images,videos,files}/posts/<slug>/.

import json
import os
import re
from email.parser import BytesParser
from email.policy import default
from http.server import BaseHTTPRequestHandler, HTTPServer

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
POSTS = os.path.join(ROOT, "_posts")
ASSETS = os.path.join(ROOT, "assets")
NAME_RE = re.compile(r"^\d{4}-\d{2}-\d{2}-.+\.md$")
SLUG_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
MEDIA_TYPES = ("images", "videos", "files")
IMAGE_EXTENSIONS = {".svg", ".png", ".jpg", ".jpeg", ".gif", ".webp", ".avif", ".bmp"}
VIDEO_EXTENSIONS = {".mp4", ".webm", ".mov", ".m4v", ".ogv"}
MAX_UPLOAD_BYTES = 500 * 1024 * 1024  # uploads are read fully into memory; keep them bounded


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, body=b"", ctype="application/octet-stream"):
        self.send_response(code)
        origin = self.headers.get("Origin", "")
        if re.fullmatch(r"http://(?:localhost|127\.0\.0\.1):\d+", origin):
            self.send_header("Access-Control-Allow-Origin", origin)
            self.send_header("Vary", "Origin")
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        origin = self.headers.get("Origin", "")
        if not re.fullmatch(r"http://(?:localhost|127\.0\.0\.1):\d+", origin):
            return self._send(403, b"local origin required", "text/plain")
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", origin)
        self.send_header("Vary", "Origin")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Access-Control-Max-Age", "600")
        self.send_header("Content-Length", "0")
        self.end_headers()

    def do_GET(self):
        if self.path == "/ping":
            return self._send(200, b"ok", "text/plain")
        if self.path.startswith("/src/"):
            name = os.path.basename(self.path[len("/src/"):])
            if not NAME_RE.match(name):
                return self._send(400, b"bad filename", "text/plain")
            path = os.path.join(POSTS, name)
            if not os.path.isfile(path):
                return self._send(404, b"not found", "text/plain")
            with open(path, "rb") as f:
                return self._send(200, f.read(), "text/markdown")
        if self.path.startswith("/files/"):
            slug = self.path[len("/files/"):]
            if not SLUG_RE.fullmatch(slug):
                return self._send(400, b"bad slug", "text/plain")
            files = []
            for media_type in MEDIA_TYPES:
                folder = os.path.join(ASSETS, media_type, "posts", slug)
                if not os.path.isdir(folder):
                    continue
                for name in sorted(os.listdir(folder)):
                    path = os.path.join(folder, name)
                    if os.path.isfile(path):
                        files.append({
                            "type": media_type,
                            "name": name,
                            "path": "assets/{}/posts/{}/{}".format(media_type, slug, name),
                        })
            body = json.dumps({"files": files}).encode("utf-8")
            return self._send(200, body, "application/json")
        return self._send(404)

    def do_POST(self):
        if self.path == "/upload":
            return self._upload()
        if self.path != "/save":
            return self._send(404)
        try:
            length = int(self.headers.get("Content-Length", 0))
            data = json.loads(self.rfile.read(length))
            name = os.path.basename(str(data.get("file", "")))
            content = data.get("content")
        except Exception:
            return self._send(400, b"bad request", "text/plain")
        if not NAME_RE.match(name) or not isinstance(content, str):
            return self._send(400, b"file must look like YYYY-MM-DD-slug.md", "text/plain")
        with open(os.path.join(POSTS, name), "w") as f:
            f.write(content)
        return self._send(200, json.dumps({"saved": name}).encode(), "application/json")

    def _upload(self):
        try:
            length = int(self.headers.get("Content-Length", 0))
            if length <= 0:
                return self._send(400, b"one non-empty file is required", "text/plain")
            if length > MAX_UPLOAD_BYTES:
                return self._send(413, b"file too large (500 MB max)", "text/plain")
            content_type = self.headers.get("Content-Type", "")
            if not content_type.lower().startswith("multipart/form-data"):
                return self._send(400, b"expected multipart/form-data", "text/plain")
            message = BytesParser(policy=default).parsebytes(
                ("Content-Type: {}\r\nMIME-Version: 1.0\r\n\r\n".format(content_type).encode("ascii")
                 + self.rfile.read(length))
            )
            slugs = []
            uploads = []
            for part in message.iter_parts():
                field_name = part.get_param("name", header="content-disposition")
                if field_name == "slug" and not part.get_filename():
                    slugs.append(part.get_content().strip())
                elif field_name == "file" and part.get_filename():
                    uploads.append(part)
        except Exception:
            return self._send(400, b"bad multipart request", "text/plain")

        if len(slugs) != 1 or len(uploads) != 1:
            return self._send(400, b"provide one slug and exactly one file", "text/plain")
        slug = slugs[0]
        part = uploads[0]
        if not SLUG_RE.fullmatch(slug):
            return self._send(400, b"bad slug", "text/plain")

        original_name = part.get_filename() or ""
        if "/" in original_name or "\\" in original_name or original_name in (".", ".."):
            return self._send(400, b"file paths are not allowed", "text/plain")
        name = re.sub(r"\s+", "-", original_name)
        name = re.sub(r"[^A-Za-z0-9._-]", "", name)
        name = name.strip(".-")
        if not name or name in (".", ".."):
            return self._send(400, b"filename has no safe characters", "text/plain")

        extension = os.path.splitext(name)[1].lower()
        if extension in IMAGE_EXTENSIONS:
            media_type = "images"
        elif extension in VIDEO_EXTENSIONS:
            media_type = "videos"
        else:
            media_type = "files"
        folder = os.path.join(ASSETS, media_type, "posts", slug)
        os.makedirs(folder, exist_ok=True)
        destination = os.path.join(folder, name)
        if os.path.exists(destination):
            return self._send(409, b"a file with that name already exists", "text/plain")
        content = part.get_payload(decode=True) or b""
        if not content:
            return self._send(400, b"empty files cannot be uploaded", "text/plain")
        with open(destination, "wb") as uploaded:
            uploaded.write(content)
        result = {
            "saved": name,
            "type": media_type,
            "path": "assets/{}/posts/{}/{}".format(media_type, slug, name),
        }
        return self._send(201, json.dumps(result).encode("utf-8"), "application/json")

    def log_message(self, *args):  # keep the terminal quiet
        pass


if __name__ == "__main__":
    port = int(os.environ.get("DRAFT_SAVE_PORT", "4001"))
    HTTPServer(("127.0.0.1", port), Handler).serve_forever()
