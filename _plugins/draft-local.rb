# frozen_string_literal: true
#
# draft-local.rb — branch-owned Jekyll hook (drafts branch only).
#
# After every build/rebuild, publishes into _site/:
#   drafts-src/<file>        the RAW markdown of each draft on this branch
#   drafts-manifest.json     file/title/url per draft for the editor's picker
#
# This is what lets the WYSIWYG editor (served by `jekyll serve`) work against
# the local checkout: it reads raw drafts from /drafts-src/ and gets a fresh
# manifest on every rebuild — no GitHub round-trip.
#
# The URL rule mirrors Jekyll's UrlDrop#title for the /blog/:title/ permalink:
# the `slug:` front-matter field if present, else the filename without date.

require "fileutils"

Jekyll::Hooks.register :site, :post_write do |site|
  posts_dir = File.join(site.source, "_posts")
  next unless Dir.exist?(posts_dir)

  src_out = File.join(site.dest, "drafts-src")
  FileUtils.mkdir_p(src_out)

  posts = []
  site.posts.docs.each do |doc|
    raw_path = doc.path.start_with?("/") ? doc.path : File.join(site.source, doc.path)
    next unless File.file?(raw_path) && !File.symlink?(raw_path)

    name = File.basename(doc.path)
    FileUtils.cp(raw_path, File.join(src_out, name))

    base = name.sub(/\A\d{4}-\d{2}-\d{2}-/, "").sub(/\.md\z/, "")
    slug = doc.data["slug"].to_s.empty? ? base : doc.data["slug"].to_s
    posts << {
      "file"  => name,
      "title" => (doc.data["title"].to_s.empty? ? base : doc.data["title"].to_s),
      "url"   => "/blog/" + Jekyll::Utils.slugify(slug, mode: "pretty", cased: true) + "/"
    }
  end

  File.write(
    File.join(site.dest, "drafts-manifest.json"),
    JSON.pretty_generate("branch" => "drafts", "posts" => posts.sort_by { |p| p["file"] })
  )
end
