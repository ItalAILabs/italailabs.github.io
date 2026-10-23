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
#
# Filenames must match YYYY-MM-DD-*.md; nothing else is written.

import json
import os
import re
from http.server import BaseHTTPRequestHandler, HTTPServer

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
POSTS = os.path.join(ROOT, "_posts")
NAME_RE = re.compile(r"^\d{4}-\d{2}-\d{2}-.+\.md$")


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, body=b"", ctype="application/octet-stream"):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

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
        return self._send(404)

    def do_POST(self):
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

    def log_message(self, *args):  # keep the terminal quiet
        pass


if __name__ == "__main__":
    port = int(os.environ.get("DRAFT_SAVE_PORT", "4001"))
    HTTPServer(("127.0.0.1", port), Handler).serve_forever()
