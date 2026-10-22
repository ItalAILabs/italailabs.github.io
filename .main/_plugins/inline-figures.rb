# frozen_string_literal: true
#
# _plugins/inline-figures.rb
#
# Build-time figure embeds — image plus optional note as one width-sharing unit:
#
#   {% inline_svg "assets/images/blog/pages/wizard/foo.svg" %}
#   {% inline_svg "assets/images/blog/pages/wizard/foo.svg" "Figure note text." %}
#   {% inline_img "assets/images/blog/pages/wizard/bar.png" "Alt text." %}
#   {% inline_img "assets/images/blog/pages/wizard/bar.png" "Alt text." "Figure note text." %}
#
# Both emit:
#
#   <div class="post-fig">
#     <svg …>…</svg>                                  (or <img src="/…" alt="…">)
#     <p class="table-footnote">Figure note text.</p> (when a note is given)
#   </div>
#
# so the description shares the image's width and they read as one unit.
#
# inline_svg inlines the file into the page DOM (the div wrapper lets kramdown
# pass it through as a raw HTML block), so page CSS can style and theme it —
# e.g. fills using var(--standard-light) follow the site background. Fixed
# width/height on the <svg> root are stripped and an inline-svg class is added
# for responsive sizing. Each SVG must be inlined at most once per page
# (internal ids would clash).
#
module Jekyll
  module InlineFigures
    def self.resolve!(site, path)
      source = File.expand_path(site.source)
      target = File.expand_path(path, source)
      unless target.start_with?(source + File::SEPARATOR) && File.file?(target)
        raise ArgumentError, "no such file under the site source: #{path}"
      end
      target
    end

    def self.wrap(inner, note = nil)
      note = note.to_s.strip
      note_html = note.empty? ? '' : %(
<p class="table-footnote">#{note}</p>)
      %(<div class="post-fig">\n#{inner}#{note_html}\n</div>)
    end
  end

  class InlineSvgTag < Liquid::Tag
    SYNTAX = /\A["']([^"']+)["'](?:\s+"([^"]*)")?\z/

    def initialize(tag_name, markup, parse_context)
      super
      match = SYNTAX.match(markup.to_s.strip)
      raise ArgumentError, 'inline_svg expects a quoted path: {% inline_svg "path/to.svg" %}' unless match

      @path = match[1]
      @note = match[2]
    end

    def render(context)
      target = InlineFigures.resolve!(context.registers[:site], @path)
      raise ArgumentError, "inline_svg: not an SVG file: #{@path}" unless target.end_with?('.svg')

      svg = File.read(target)
      # Drop fixed sizing and tag the root so page CSS can make it responsive.
      svg.sub!(/\A<svg([^>]*)>/) do |root|
        attrs = $1.gsub(/\s+(?:width|height)="[^"]*"/, "")
        attrs += ' class="inline-svg"' unless attrs.include?("class=")
        "<svg#{attrs}>"
      end

      InlineFigures.wrap(svg, @note)
    end
  end

  class InlineImgTag < Liquid::Tag
    SYNTAX = /\A["']([^"']+)["'](?:\s+"([^"]*)")?(?:\s+"([^"]*)")?\z/

    def initialize(tag_name, markup, parse_context)
      super
      match = SYNTAX.match(markup.to_s.strip)
      raise ArgumentError, 'inline_img expects a quoted path and alt: {% inline_img "path/to.png" "Alt text." %}' unless match

      @path = match[1]
      @alt = match[2].to_s
      @note = match[3]
    end

    def render(context)
      InlineFigures.resolve!(context.registers[:site], @path)
      img = %(<img src="/#{@path}" alt="#{@alt}">)
      InlineFigures.wrap(img, @note)
    end
  end
end

Liquid::Template.register_tag("inline_svg", Jekyll::InlineSvgTag)
Liquid::Template.register_tag("inline_img", Jekyll::InlineImgTag)
