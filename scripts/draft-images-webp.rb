# frozen_string_literal: true
#
# draft-images-webp.rb — generate .webp next to each source image in
# draft-assets/ (the site's responsive-images plugin rewrites every
# .png/.jpg reference to .webp at build time, so the preview needs them).
# SVG files need no conversion. Uses ruby-vips from the Gemfile; skips
# gracefully when libvips is not installed on the build machine.

require "vips"

Dir.glob("assets/images/drafts/**/*.{png,jpg,jpeg}", File::FNM_CASE_INSENSITIVE).each do |src|
  dest = src.sub(/\.(jpe?g)$/i, ".webp")
  if File.exist?(dest) && File.mtime(dest) >= File.mtime(src)
    next # already up to date
  end
  begin
    Vips::Image.new_from_file(src).write_to_file(dest, strip: true, Q: 82)
    puts "webp: #{src} -> #{dest}"
  rescue StandardError => e
    warn "skipping #{src}: #{e.class} #{e.message}"
  end
end
