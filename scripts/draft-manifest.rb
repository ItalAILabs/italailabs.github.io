# frozen_string_literal: true
#
# draft-manifest.rb — write drafts-manifest.json (source root) listing the
# drafts on THIS branch (real files in _posts/, i.e. not symlinks to main's
# posts). Jekyll copies it into _site/ as a static file on every build, so
# editor.html can read it from both `jekyll build` and `jekyll serve`.
#
# Each entry carries the post's real preview URL, computed exactly like
# Jekyll's UrlDrop#title does for the /blog/:title/ permalink: the `slug:`
# front-matter field if present, else the filename without its date prefix.

require "json"
require "jekyll" # for Jekyll::Utils.slugify (same version as the build)

files = Dir.glob("_posts/*.md").reject { |f| File.symlink?(f) }.sort

posts = files.map do |f|
  raw  = File.read(f)
  fm   = (raw[/\A---\n(.*?)\n---/m, 1]) || ""
  get  = ->(key) { (fm.each_line.find { |l| l =~ /\A#{key}:\s*/ } || "").sub(/\A#{key}:\s*/, "").strip.gsub(/\A["']|["']\z/, "") }

  base = File.basename(f, ".md").sub(/\A\d{4}-\d{2}-\d{2}-/, "")
  slug = get.call("slug").empty? ? base : get.call("slug")
  {
    "file"  => File.basename(f),
    "title" => (get.call("title").empty? ? File.basename(f, ".md") : get.call("title")),
    "url"   => "/blog/" + Jekyll::Utils.slugify(slug, mode: "pretty", cased: true) + "/"
  }
end

File.write("drafts-manifest.json", JSON.pretty_generate("branch" => "drafts", "posts" => posts))
puts "==> wrote drafts-manifest.json (#{posts.size} draft(s))"
