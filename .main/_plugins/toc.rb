# frozen_string_literal: true
#
# _plugins/toc.rb
#
# Build-time ToC generator: `{{ content | toc }}`
#
# Renders a nested <ul> table of contents from the h2–h4 headings of the
# rendered post content (kramdown assigns the heading ids). Lets the layout
# place the ToC anywhere (sticky rail, <details> dropdown) with zero
# client-side JavaScript.
#
# Heading promotion: when the post opens with a single leading h2 (the
# article's intro subtitle, e.g. WIZARD) followed by h3 sections, that h2
# is rendered as a non-numbered .toc-title line and the h3s are promoted
# to the numbered top level — so the ToC's main sections are the ones a
# reader actually navigates by. Posts with multiple h2s keep the plain
# h2→h3→h4 mapping.
#
module Jekyll
  module TocFilter
    HEADING = /<h([2-4])(?:\s[^>]*?id="([^"]+)")?[^>]*>(.*?)<\/h\1>/m

    # Returns nested ToC HTML for the given rendered-content string.
    def toc(html)
      headings = html.to_s.scan(HEADING).map do |lvl, id, text|
        next if id.nil?

        # Strip decorative annotations (e.g. section time estimates) before
        # dropping the remaining markup, so ToC labels stay clean titles.
        { level: lvl.to_i, id: id, label: text.gsub(/<span class="section-time"[^>]*>.*?<\/span>/m, "").gsub(/<[^>]+>/, "").strip }
      end.compact
      return "" if headings.empty?

      out = +""
      body = headings
      if headings.length > 1 &&
           headings.first[:level] == 2 &&
           headings.count { |h| h[:level] == 2 } == 1 &&
           headings[1][:level] == 3
        title = headings.first
        out << %(<div class="toc-title"><a href="\##{title[:id]}">#{title[:label]}</a></div>)
        body = headings[1..]
      end
      # Top level = the shallowest heading in the body (h2 normally, h3
      # when the leading h2 was promoted to a title line). target is
      # 0-based depth; depth -1 is the virtual root above the top <ol>.
      top_level = body.map { |h| h[:level] }.min
      depth = -1
      li_open = false
      body.each do |h|
        target = h[:level] - top_level
        if target > depth
          (target - depth).times do |i|
            # top level renders as <ol>; nested levels as <ul>
            out << (depth + i + 1 == 0 ? "<ol>" : "<ul>") << "<li>"
          end
          depth = target
          li_open = true # last emitted <li> is this heading's li
        elsif target < depth
          # close each deeper level (li + ul), then the li at target level
          out << "</li></ul>" * (depth - target) + "</li>"
          depth = target
          li_open = false
        elsif li_open
          out << "</li>"
          li_open = false
        end
        out << "<li>" unless li_open
        li_open = true
        out << %(<a href="\##{h[:id]}">#{h[:label]}</a>)
      end
      # close last heading's li; for each ancestor level close ul then that
      # level's li; close the top ol
      out << "</li>" + ("</ul></li>" * depth) + "</ol>"
      out
    end
  end
end

Liquid::Template.register_filter(Jekyll::TocFilter)
