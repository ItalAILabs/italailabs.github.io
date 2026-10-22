# frozen_string_literal: true
#
# draft-manifest.rb — write _site/drafts-manifest.json listing the drafts on
# THIS branch (real files in _posts/, i.e. not symlinks to main's posts).
# editor.html uses it to populate its post picker without any API calls.

require "json"

files = Dir.glob("_posts/*.md").reject { |f| File.symlink?(f) }.sort

posts = files.map do |f|
  raw  = File.read(f)
  fm   = (raw[/\A---\n(.*?)\n---/m, 1]) || ""
  line = fm.each_line.find { |l| l =~ /\Atitle:\s*/ }
  title = line.to_s.sub(/\Atitle:\s*/, "").strip.gsub(/\A["']|["']\z/, "")
  {
    "file"  => File.basename(f),
    "title" => (title.empty? ? File.basename(f, ".md") : title)
  }
end

File.write("_site/drafts-manifest.json", JSON.pretty_generate("branch" => "drafts", "posts" => posts))
puts "==> wrote _site/drafts-manifest.json (#{posts.size} draft(s))"
