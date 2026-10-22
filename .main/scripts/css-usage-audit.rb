#!/usr/bin/env ruby
# frozen_string_literal: true
#
# css-usage-audit.rb — find unused CSS rules in a built Jekyll site.
#
# Usage:
#   bundle exec ruby scripts/css-usage-audit.rb [--site-dir _site] [--json] [--fail]
#
# How it works:
#   1. Scans every HTML page in the built site and records which CSS files
#      it links (<link rel="stylesheet">) plus any inline <style> blocks.
#   2. Parses each CSS file into rules (selectors + bodies), tracking
#      @media/@supports context and collecting @keyframes names.
#   3. A rule is "used" if, on at least one page that links its CSS file,
#      every class/id/tag token in the selector appears in that page's HTML.
#      (Conservative heuristic: it can under-report, never over-report.)
#   4. Reports unused rules grouped by file, with estimated byte savings,
#      plus @keyframes that are defined but never referenced.
#
# Exit codes: 0 = clean or audit-only, 1 = unused rules found (with --fail).

require "json"
require "fileutils"

SITE_DIR = ARGV.include?("--site-dir") ? ARGV[ARGV.index("--site-dir") + 1] : "_site"
JSON_OUT = ARGV.include?("--json")
FAIL_ON_UNUSED = ARGV.include?("--fail")

# ---------------------------------------------------------------------------
# HTML side: collect pages, linked CSS, inline styles, and token inventories
# ---------------------------------------------------------------------------

def html_tokens(html)
  classes = Set.new
  ids = Set.new
  tags = Set.new
  html.scan(/class=["']([^"']*)["']/i).flatten.each { |v| v.split(/\s+/).each { |c| classes << c.downcase unless c.empty? } }
  html.scan(/id=["']([^"']*)["']/i).flatten.each { |v| ids << v.downcase unless v.empty? }
  html.scan(/<([a-z][a-z0-9]*)/i).each { |(t)| tags << t.downcase }
  [classes, ids, tags]
end

def parse_pages(site_dir)
  pages = []
  Dir.glob(File.join(site_dir, "**", "*.html")).sort.each do |path|
    html = File.read(path)
    rel = "/" + path.sub(%r{\A#{Regexp.escape(site_dir)}/?}, "")
    linked = html.scan(/<link[^>]*rel=["']stylesheet["'][^>]*>/i).map do |tag|
      (tag.match(/href=["']([^"']+)["']/i) || [])[1]
    end.compact.select { |h| h.start_with?("/assets/css/") && !h.include?("fontawesome") }
    inline = html.scan(/<style[^>]*>(.*?)<\/style>/im).flatten
    classes, ids, tags = html_tokens(html)
    pages << {
      url: rel, file: path, linked_css: linked.uniq, inline_styles: inline,
      classes: classes, ids: ids, tags: tags
    }
  end
  pages
end

# ---------------------------------------------------------------------------
# CSS side: tiny rule parser (flat + @media/@supports nesting, @keyframes)
# ---------------------------------------------------------------------------

def parse_css(css_text)
  css_text = css_text.gsub(/\/\*.*?\*\//m, "") # strip comments
  rules = []       # {selector:, body:, context:}
  keyframes = []   # names defined
  i = 0
  len = css_text.length
  context_stack = []

  while i < len
    ch = css_text[i]
    if ch == "{"
      # find the prelude between the previous "}" or start and this "{"
      prelude_start = ((css_text[0...i].rindex("}") || -1) + 1)
      prelude = css_text[prelude_start...i].strip
      # find matching close brace
      depth = 1
      j = i + 1
      while j < len && depth > 0
        case css_text[j]
        when "{" then depth += 1
        when "}" then depth -= 1
        end
        j += 1
      end
      inner = css_text[(i + 1)...(j - 1)]
      if prelude.start_with?("@keyframes") || prelude.start_with?("@-webkit-keyframes")
        name = prelude.split(/\s+/)[1]
        keyframes << name if name
        i = j
        next
      elsif prelude.start_with?("@font-face")
        i = j
        next
      elsif prelude.start_with?("@media") || prelude.start_with?("@supports")
        context_stack.push(prelude)
        # parse inner rules with this context, then pop
        sub_rules, sub_kf = parse_css(inner)
        keyframes.concat(sub_kf)
        sub_rules.each { |r| r[:context] = (r[:context] ? [r[:context], prelude] : [prelude]) }
        rules.concat(sub_rules)
        context_stack.pop
        i = j
        next
      else
        # normal rule: selector { body }  (inner may contain nested at-rules? no — flat CSS)
        prelude.split(",").map(&:strip).reject(&:empty?).each do |sel|
          rules << { selector: sel, body: inner.strip, context: context_stack.empty? ? nil : context_stack.dup }
        end
        i = j
      end
    else
      i += 1
    end
  end
  [rules, keyframes]
end

# Extract checkable tokens from a selector. Returns nil if the selector is
# trivially present (e.g. "body", "*") or unverifiable (attribute selectors).
def selector_tokens(selector)
  sel = selector.gsub(/::?[a-z-]+(\([^)]*\))?/, " ") # strip pseudo-class/element
  sel = sel.sub(/\[[^\]]*\]/, "@attr")               # attribute selector -> unverifiable
  return :unverifiable if sel.include?("@attr")
  classes = sel.scan(/\.([a-zA-Z][\w-]*)/).flatten.map(&:downcase)
  ids = sel.scan(/#([\w-]+)/).flatten.map(&:downcase)
  tags = sel.gsub(/[.#][\w-]+/, " ").scan(/\b([a-z][a-z0-9]*)\b/).flatten.map(&:downcase)
  return :trivial if classes.empty? && ids.empty? && tags.empty?
  { classes: classes, ids: ids, tags: tags }
end

def selector_used?(tokens, page, dynamic = Set.new)
  case tokens
  when :trivial then true
  when :unverifiable then nil # don't count either way
  else
    tokens[:classes].all? { |c| page[:classes].include?(c) || dynamic.include?(c) } &&
      tokens[:ids].all? { |id| page[:ids].include?(id) } &&
      tokens[:tags].all? { |t| page[:tags].include?(t) }
  end
end

# ---------------------------------------------------------------------------
# Dynamic classes: class names the site's JS toggles at runtime (invisible to
# static HTML). Collected from external JS files and inline <script> blocks.
# ---------------------------------------------------------------------------

def dynamic_classes(site_dir)
  texts = Dir.glob(File.join(site_dir, "assets", "js", "*.js")).map { |f| File.read(f) }
  texts += Dir.glob(File.join(site_dir, "**", "*.html")).flat_map do |f|
    File.read(f).scan(/<script[^>]*>(.*?)<\/script>/im).flatten
  end
  classes = Set.new
  texts.each do |js|
    consts = {}
    js.scan(/(?:const|let|var)\s+([A-Za-z_$][\w$]*)\s*=\s*(\[[^\]]*\])/).each do |name, arr|
      consts[name] = arr.scan(/"([^"]*)"|'([^']*)'/).flatten.compact
    end
    js.scan(/classList\.(?:add|remove|toggle|contains)\(([^)]*)\)/).each do |(args)|
      args.split(",").each do |a|
        a = a.strip.sub(/^\.\./, "")
        if a =~ /^"([^"]*)"$/ || a =~ /^'([^']*)'$/
          classes << Regexp.last_match(1)
        elsif consts.key?(a)
          classes.merge(consts[a])
        end
      end
    end
  end
  classes
end

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

require "set"

pages = parse_pages(SITE_DIR)
abort "No HTML pages found in #{SITE_DIR} — run a Jekyll build first." if pages.empty?
dynamic = dynamic_classes(SITE_DIR)

css_files = pages.flat_map { |p| p[:linked_css] }.uniq.sort
results = []
keyframe_defs = {}   # name => file
animation_refs = Set.new

pages.each do |page|
  page[:inline_styles].each do |css|
    rules, kf = parse_css(css)
    rules.each do |rule|
      tokens = selector_tokens(rule[:selector])
      next if tokens == :unverifiable
      used = selector_used?(tokens, page, dynamic)
      results << { file: "#{page[:url]} (inline)", url: page[:url], selector: rule[:selector],
                   context: rule[:context]&.join(" "), size: rule[:selector].length + rule[:body].length,
                   used: used, tokens: tokens }
    end
    kf.each { |name| keyframe_defs[name] ||= "#{page[:url]} (inline)" }
  end
end

css_files.each do |href|
  path = File.join(SITE_DIR, href.sub(%r{\A/}, ""))
  next unless File.exist?(path)
  css = File.read(path)
  rules, kf = parse_css(css)
  linking_pages = pages.select { |p| p[:linked_css].include?(href) }
  rules.each do |rule|
    tokens = selector_tokens(rule[:selector])
    next if tokens == :unverifiable
    used = linking_pages.any? { |p| selector_used?(tokens, p, dynamic) }
    results << { file: href, url: nil, selector: rule[:selector],
                 context: rule[:context]&.join(" "), size: rule[:selector].length + rule[:body].length,
                 used: used, tokens: tokens, pages_linked: linking_pages.size }
  end
  kf.each { |name| keyframe_defs[name] ||= href }
end

# collect animation-name references from all CSS (inline + files)
(all_css_text = css_files.map { |h| File.read(File.join(SITE_DIR, h.sub(%r{\A/}, ""))) rescue "" } +
 pages.flat_map { |p| p[:inline_styles] }).each do |css|
  animation_refs.merge(css.scan(/animation(?:-name)?\s*:\s*([^;}]+)/).flatten.flat_map { |v| v.split(",").map { |x| x.strip.downcase } }.reject(&:empty?))
end

truly_unused = results.select { |r| r[:used] == false }
unverifiable_count = results.count { |r| r[:used] == nil }

# Split unused rules into:
#   dead        — selector matches no page on the whole site (safe to delete)
#   contextual  — unused only on the pages linking that file, but used elsewhere
all_pages = pages
dead_rules = truly_unused.select { |r| !all_pages.any? { |p| selector_used?(r[:tokens], p, dynamic) } }
contextual_rules = truly_unused - dead_rules

total_bytes = results.sum { |r| r[:size] || 0 }
dead_bytes = dead_rules.sum { |r| r[:size] }
unused_kf = keyframe_defs.reject { |name, _| animation_refs.include?(name) }

if JSON_OUT
  puts JSON.pretty_generate(
    pages_scanned: pages.size, css_files: css_files.size, rules_checked: results.size,
    dead_rules: dead_rules.size, contextual_unused: contextual_rules.size,
    unverifiable_skipped: unverifiable_count, dead_bytes: dead_bytes, total_bytes: total_bytes,
    unused_keyframes: unused_kf.to_h,
    dead: dead_rules.map { |r| { file: r[:file], selector: r[:selector], context: r[:context], bytes: r[:size] } },
    contextual: contextual_rules.map { |r| { file: r[:file], selector: r[:selector], context: r[:context], bytes: r[:size] } }
  )
else
  puts "CSS Usage Audit — #{SITE_DIR}"
  puts "Pages scanned: #{pages.size} | CSS files: #{css_files.size} | Rules checked: #{results.size}"
  puts
  pct = total_bytes > 0 ? (dead_bytes.to_f / total_bytes * 100).round(1) : 0
  puts format("DEAD SITE-WIDE: %d rule(s), ~%.1f KB of %.1f KB (%.1f%%)%s", dead_rules.size, dead_bytes / 1024.0, total_bytes / 1024.0, pct,
              unverifiable_count > 0 ? "  (#{unverifiable_count} rule(s) skipped: attribute selectors)" : "")
  puts format("CONTEXTUAL UNUSED: %d rule(s) — unused on their file's pages but used elsewhere (entry-slimming candidates)", contextual_rules.size)
  puts

  unless dead_rules.empty?
    puts "=== DEAD SITE-WIDE (safe to delete) ==="
    # group identical selector+context across files
    grouped = dead_rules.group_by { |r| [r[:selector], r[:context]] }
    grouped.sort_by { |_, rs| -rs.sum { |r| r[:size] } }.each do |(sel, ctx), rs|
      n = rs.sum { |r| r[:size] }
      files = rs.map { |r| r[:file] }.uniq
      puts format("%7d B  %s%s   [%d file(s): %s]", n, sel, ctx ? "  [#{ctx}]" : "", files.size, files.join(", "))
    end
    puts
  end

  unless contextual_rules.empty?
    puts "=== CONTEXTUAL UNUSED (per-file; consider trimming entry imports) ==="
    by_file = contextual_rules.group_by { |r| r[:file] }
    by_file.each do |file, rules|
      n = rules.sum { |r| r[:size] }
      puts format("%-40s %d rule(s), ~%.1f KB", file, rules.size, n / 1024.0)
      rules.sort_by { |r| -r[:size] }.first(15).each do |r|
        ctx = r[:context] ? "  [#{r[:context]}]" : ""
        puts format("  %7d B  %s%s", r[:size], r[:selector], ctx)
      end
      puts format("  ... and %d more", rules.size - 15) if rules.size > 15
      puts
    end
  end

  unless unused_kf.empty?
    puts "UNUSED @keyframes (defined, never referenced by any animation):"
    unused_kf.each { |name, file| puts format("  %-24s defined in %s", name, file) }
    puts
  end

  if dead_rules.empty? && contextual_rules.empty? && unused_kf.empty?
    puts "No unused rules found."
  end
end

exit(FAIL_ON_UNUSED && !dead_rules.empty? ? 1 : 0)
