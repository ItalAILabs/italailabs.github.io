# frozen_string_literal: true
require 'json'
require 'jekyll/utils'

module Jekyll
  class InsightsManifestGenerator < Generator
    safe true
    priority :low

    def generate(site)
      Jekyll.logger.info "InsightsManifest:", "🚀 Starting generation"

      cfg = site.config.fetch('insights_manifest', {})
      per_page = (cfg['per_page'] || 12).to_i
      output_dir = cfg['output_dir'] || 'assets/data/insights'
      include_per_category = cfg.key?('per_category') ? cfg['per_category'] : true
      emit_ndjson = cfg.key?('ndjson') ? cfg['ndjson'] : true

      Jekyll.logger.info "InsightsManifest:", "Configuration:"
      Jekyll.logger.info "InsightsManifest:", "  - per_page: #{per_page}"
      Jekyll.logger.info "InsightsManifest:", "  - output_dir: #{output_dir}"
      Jekyll.logger.info "InsightsManifest:", "  - per_category: #{include_per_category}"
      Jekyll.logger.info "InsightsManifest:", "  - emit_ndjson: #{emit_ndjson}"

      all_posts = site.posts.docs
      Jekyll.logger.info "InsightsManifest:", "📝 Total posts in site: #{all_posts.size}"

      posts = all_posts.select { |doc| doc.data['published_in_blog'] != false }
      Jekyll.logger.info "InsightsManifest:", "✅ Posts after filter: #{posts.size}"

      if posts.empty?
        Jekyll.logger.warn "InsightsManifest:", "⚠️  No posts found! Check 'published_in_blog' filter"
        return
      end

      posts.sort_by! { |doc| [(doc.data['date'] || doc.date || Time.at(0)), (doc.data['part'] || 0).to_i] }
      posts.reverse!

      write_manifests(site, posts, output_dir, per_page, 'insights', emit_ndjson)

      return unless include_per_category

      grouped = group_by_category(posts)
      Jekyll.logger.info "InsightsManifest:", "📂 Found #{grouped.size} categories"

      grouped.each do |slug, docs|
        Jekyll.logger.info "InsightsManifest:", "  - Category '#{slug}': #{docs.size} posts"
        write_manifests(site, docs, File.join(output_dir, 'categories'), per_page, "category-#{slug}", emit_ndjson, category: slug)
      end

      Jekyll.logger.info "InsightsManifest:", "✨ Generation complete!"
    end

    private

    def group_by_category(posts)
      grouped = Hash.new { |h, k| h[k] = [] }
      posts.each do |doc|
        cats = Array(doc.data['categories'])
        cats = Array(doc.data['category']) if cats.empty? && doc.data['category']
        cats.each do |cat|
          slug = Jekyll::Utils.slugify(cat.to_s)
          grouped[slug] << doc
        end
      end
      grouped
    end

    def write_manifests(site, docs, out_dir, per_page, base_name, emit_ndjson, extra_meta = {})
      return if docs.empty?

      chunks = docs.each_slice(per_page).to_a
      total_pages = chunks.size

      Jekyll.logger.info "InsightsManifest:", "📄 Writing #{total_pages} page(s) for '#{base_name}'"

      chunks.each_with_index do |chunk, idx|
        page_num = idx + 1
        next_path = page_num < total_pages ? manifest_path(out_dir, base_name, page_num + 1) : nil

        payload = {
          'page' => page_num,
          'per_page' => per_page,
          'total_pages' => total_pages,
          'total_items' => docs.size,
          'next_page_path' => next_path,
          'items' => chunk.map { |doc| serialize_post(doc) }
        }.merge(extra_meta)

        json_file = "#{base_name}-page#{page_num}.json"
        write_json(site, out_dir, json_file, payload)
        Jekyll.logger.info "InsightsManifest:", "  ✓ Created #{File.join(out_dir, json_file)}"

        if emit_ndjson
          ndjson_file = "#{base_name}-page#{page_num}.ndjson"
          write_ndjson(site, out_dir, ndjson_file, payload)
          Jekyll.logger.info "InsightsManifest:", "  ✓ Created #{File.join(out_dir, ndjson_file)}"
        end
      end
    end

    def manifest_path(out_dir, base_name, page_num)
      File.join('/', out_dir, "#{base_name}-page#{page_num}.json")
    end

    def serialize_post(doc)
      excerpt = doc.data['excerpt'] || doc.data['description'] || doc.content
      excerpt = strip_html_basic(excerpt.to_s)
      excerpt = excerpt.gsub(/\s+/, ' ').strip[0, 240]
      Jekyll.logger.debug "Date: #{(doc.data['date'] || doc.date)}"
      {
        'url' => doc.url,
        'title' => doc.data['title'],
        'excerpt' => excerpt,
        'hero_image' => doc.data['hero_image'],
        'date' => (doc.data['date'] || doc.date),
        'categories' => doc.data['categories'] || Array(doc.data['category']),
        'series' => doc.data['series'],
        'part' => doc.data['part']
      }
    end

    def strip_html_basic(str)
      str.gsub(%r{<[^>]+>}, ' ')
    end

    def write_json(site, dir, filename, payload)
      page = Jekyll::PageWithoutAFile.new(site, site.source, dir, filename)
      page.content = JSON.pretty_generate(payload)
      page.data['layout'] = nil
      Jekyll.logger.debug "InsightsManifest:", "    Adding page: #{page.url} (#{page.class})"
      site.pages << page
    end

    def write_ndjson(site, dir, filename, payload)
      meta = payload.reject { |k, _| k == 'items' }
      lines = [meta.merge('type' => 'meta').to_json]
      payload.fetch('items', []).each do |item|
        lines << item.merge('type' => 'item').to_json
      end

      page = Jekyll::PageWithoutAFile.new(site, site.source, dir, filename)
      page.content = lines.join("\n") + "\n"
      page.data['layout'] = nil
      Jekyll.logger.debug "InsightsManifest:", "    Adding page: #{page.url} (#{page.class})"
      site.pages << page
    end
  end
end