require 'yaml'
require 'fileutils'
require 'digest'

module ItalAI
  class PeopleParser
    # Reads the YAML and returns the raw content of team array
    def self.parse(yml_path)
      unless File.exist?(yml_path)
        Jekyll.logger.warn "PeopleParser:", "people.yml not found at #{yml_path}"
        return []
      end

      raw = YAML.load_file(yml_path)

      unless raw.is_a?(Hash) && raw['team'].is_a?(Array)
        Jekyll.logger.warn "PeopleParser:", "Malformed people.yml: expected top-level 'team' array"
        return []
      end

      # Return the raw array of people, exactly as in YAML
      raw['team']
    end
  end

  class VCardGenerator
    def self.run(site)
      people = ItalAI::PeopleParser.parse(File.join(site.source, "_data", "people.yml"))

      vcf_dir  = File.join(site.source, "assets", "vcards")
      FileUtils.mkdir_p(vcf_dir)
      Jekyll.logger.info "vCardGenerator:", "VCF directory: #{vcf_dir} (exists? #{Dir.exist?(vcf_dir)})"

      people.each do |person|
        Jekyll.logger.debug "vCardGenerator:", "Processing person: #{person.inspect}"

        next unless (person['phone'].to_s.strip != "") || (person['email'].to_s.strip != "")

        slug = person['name'].downcase.strip.gsub(/[^\w\s-]/, '').gsub(/\s+/, '-')
        Jekyll.logger.info "vCardGenerator:", "Generating vCard for #{person['name']} -> #{slug}.vcf"

        # Build vCard content
        vcard_content = build_vcard(person)

        # Write file only if missing or changed (diff check)
        vcf_path = File.join(vcf_dir, "#{slug}.vcf")
        write_vcf_safe(vcf_path, vcard_content)

        # Add person page in memory
        site.pages << PersonPage.new(site, person, slug)
        Jekyll.logger.debug "vCardGenerator:", "Page added: /about/#{slug}/index.html"
      end
    end

    def self.write_vcf_safe(vcf_path, content)
      # Compute hash of new content
      new_hash = Digest::SHA256.hexdigest(content)
      existing_hash = File.exist?(vcf_path) ? Digest::SHA256.file(vcf_path).hexdigest : nil

      if new_hash != existing_hash
        File.open(vcf_path, "w") { |f| f.write(content) }
        Jekyll.logger.info "vCardGenerator:", "VCF written/updated: #{vcf_path}"
      else
        Jekyll.logger.debug "vCardGenerator:", "VCF unchanged, skipping: #{vcf_path}"
      end
    end

    def self.build_vcard(person)
      tz = person['timezone'].to_s.strip.empty? ? 'Europe/Rome' : person['timezone'] # default to Rome if not specified
      lines = []
      lines << "BEGIN:VCARD"
      lines << "VERSION:3.0"
      lines << "FN:#{person['name']}"
      lines << "ORG:ItalAI S.R.L."
      lines << "TITLE:#{person['role']}" if person['role'] && !person['role'].to_s.strip.empty?
      lines << "TEL;TYPE=CELL:#{person['phone']}" if person['phone'] && !person['phone'].to_s.strip.empty?
      lines << "EMAIL;TYPE=WORK:#{person['email']}" if person['email'] && !person['email'].to_s.strip.empty?
      lines << "TZ:#{tz}"

      if person['links'].is_a?(Hash)
        person['links'].each do |type, url|
          next if url.nil? || url.to_s.strip.empty?
          Jekyll.logger.info "vCardGenerator:", "Adding link to vCard: #{type} -> #{url}"
          if type.downcase == "url"
            lines << "URL:#{url}"
          else # Assume it's a social media link
            lines << "X-SOCIALPROFILE;TYPE=#{type.upcase}:#{url}"
          end
        end
      end

      lines << "END:VCARD"
      lines.join("\r\n")
    end
  end

  class PersonPage < Jekyll::Page
    def initialize(site, person, slug)
      @site = site
      @base = site.source
      @dir  = File.join("about", slug)
      @name = "index.html"

      self.process(@name)
      self.read_yaml(File.join(@base, "_layouts"), "vcard.html")

      self.data["title"]  = person["name"]
      self.data["person"] = person
      self.data["vcard"]  = "/assets/vcards/#{slug}.vcf"
    end
  end
end

# --- Generate VCFs and pages safely ---
Jekyll::Hooks.register :site, :post_read do |site|
  Jekyll.logger.info "vCardGenerator:", "Starting VCard generation..."
  ItalAI::VCardGenerator.run(site)
end

# --- Debug: check that site.pages has the /about pages after write ---
Jekyll::Hooks.register :site, :post_write do |site|
  # Locate all generated VCF files in _site
  vcard_dir = File.join(site.dest, "assets", "vcards")
  vcard_files = Dir.exist?(vcard_dir) ? Dir.entries(vcard_dir).select { |f| f.end_with?('.vcf') } : []
  expected_dirs = vcard_files.map { |f| File.join("/about", File.basename(f, ".vcf"), "/") }  # get slugs from filenames

  # Check each expected /about/<slug> exists in site.pages
  missing_pages = expected_dirs.reject do |expected_dir|
    site.pages.any? do |p|
      p.dir == expected_dir
    end
  end

  Jekyll.logger.info "vCardGenerator:", "Found #{vcard_files.size} VCF files in _site/assets/vcards"
  if missing_pages.empty?
    Jekyll.logger.info "vCardGenerator:", "All VCFs have corresponding /about pages registered in site.pages"
  else
    Jekyll.logger.warn "vCardGenerator:", "Missing /about pages for VCFs: #{missing_pages.join(', ')}"
  end
end