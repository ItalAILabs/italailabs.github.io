# frozen_string_literal: true
require 'json'

module Jekyll
  class ProjectsManifestGenerator < Generator
    safe true
    priority :low

    def generate(site)
      Jekyll.logger.info "ProjectsManifest:", "🚀 Starting generation"

      cfg = site.config.fetch('projects_manifest', {})
      per_page = (cfg['per_page'] || 12).to_i
      output_dir = cfg['output_dir'] || 'assets/data/projects'
      emit_ndjson = cfg.key?('ndjson') ? cfg['ndjson'] : true

      docs = site.collections.key?('projects') ? site.collections['projects'].docs : []
      Jekyll.logger.info "ProjectsManifest:", "📝 Total projects: #{docs.size}"

      return if docs.empty?

      # Computed here (generate phase, before render) since a doc's raw
      # `content` becomes unreliable to read from Liquid once rendering
      # starts converting it in place. Stash the result on doc.data so
      # layouts/includes can just check `page.has_writeup` / `project.has_writeup`.
      docs.each do |doc|
        doc.data['has_writeup'] = doc.content.to_s.gsub(/<[^>]+>/, '').strip.length.positive?
      end

      docs = docs.sort_by { |doc| doc.data['date'] || Time.at(0) }.reverse

      write_manifests(site, docs, output_dir, per_page, 'projects', emit_ndjson)

      Jekyll.logger.info "ProjectsManifest:", "✨ Generation complete!"
    end

    private

    def write_manifests(site, docs, out_dir, per_page, base_name, emit_ndjson)
      chunks = docs.each_slice(per_page).to_a
      total_pages = chunks.size

      chunks.each_with_index do |chunk, idx|
        page_num = idx + 1
        next_path = page_num < total_pages ? manifest_path(out_dir, base_name, page_num + 1) : nil

        payload = {
          'page' => page_num,
          'per_page' => per_page,
          'total_pages' => total_pages,
          'total_items' => docs.size,
          'next_page_path' => next_path,
          'items' => chunk.map { |doc| serialize_project(doc) }
        }

        json_file = "#{base_name}-page#{page_num}.json"
        write_json(site, out_dir, json_file, payload)
        Jekyll.logger.info "ProjectsManifest:", "  ✓ Created #{File.join(out_dir, json_file)}"

        next unless emit_ndjson

        ndjson_file = "#{base_name}-page#{page_num}.ndjson"
        write_ndjson(site, out_dir, ndjson_file, payload)
        Jekyll.logger.info "ProjectsManifest:", "  ✓ Created #{File.join(out_dir, ndjson_file)}"
      end
    end

    def manifest_path(out_dir, base_name, page_num)
      File.join('/', out_dir, "#{base_name}-page#{page_num}.json")
    end

    def serialize_project(doc)
      {
        'url' => doc.url,
        'title' => doc.data['title'],
        'tag' => doc.data['tag'],
        'category' => doc.data['category'],
        'excerpt' => doc.data['excerpt'],
        'video' => doc.data['video'],
        'video_zoom' => doc.data['video_zoom'],
        'stats' => doc.data['stats'],
        'external_url' => doc.data['external_url'],
        'cta_label' => doc.data['cta_label'],
        'has_writeup' => doc.data['has_writeup'],
        'date' => doc.data['date']
      }
    end

    def write_json(site, dir, filename, payload)
      page = Jekyll::PageWithoutAFile.new(site, site.source, dir, filename)
      page.content = JSON.pretty_generate(payload)
      page.data['layout'] = nil
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
      site.pages << page
    end
  end
end
