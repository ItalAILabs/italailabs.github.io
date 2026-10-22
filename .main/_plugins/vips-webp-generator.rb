# Vips WebP generator
# Converts JPG and PNG under assets/images to WebP during Jekyll build using libvips.
# Generates multiple responsive sizes for automatic srcset usage.
#
# Entry points:
#   - Normal Jekyll build: scans assets/images for all source images (local dev)
#   - WEBP_MANIFEST env var: reads a newline-delimited list of relative paths to process (CI)
module ItalAI
  class VipsWebpGenerator
    IMAGE_EXTS = %w[.jpg .jpeg .png].freeze
    # Generate these widths for responsive images
    SIZES = [400, 800, 1200, 1600].freeze
    QUALITY = 78  # Reduced for better compression
    EFFORT = 6    # Increased for better compression
    SAVE_OPTIONS = { Q: QUALITY, effort: EFFORT, strip: true }.freeze

    # Sidecar meta file stores the source image width so freshness checks
    # never need to open the image via libvips (which is the main build-time
    # cost when all outputs are already up to date).
    META_SUFFIX = ".webp.meta".freeze

    def self.run(site)
      require "vips"
      require "parallel"
    rescue LoadError => e
      warn "[vips-webp] Missing dependencies: #{e.message}"
      warn "[vips-webp] Skipping WebP generation."
      return
    else
      image_dir = File.join(site.source, "assets", "images")
      return unless Dir.exist?(image_dir)
      @force_regen = ENV["WEBP_FORCE_REGEN"] == "1"

      paths = if ENV["WEBP_MANIFEST"]
        load_from_manifest(site)
      else
        scan_source_images(site)
      end

      return if paths.empty?

      @path_locks_mutex = Mutex.new
      @path_locks = {}

      log_info "Found #{paths.size} source images to process"

      worker_count = ENV.fetch("WEBP_WORKERS", Parallel.processor_count).to_i
      worker_count = 1 if worker_count < 1
      Parallel.each_with_index(paths, in_threads: worker_count) do |path, index|
        Thread.current[:webp_worker_id] = (index % worker_count) + 1
        generate_responsive_images(path)
      end
    end

    # ---------------------------------------------------------------------------
    # Entry points
    # ---------------------------------------------------------------------------

    # CI path: read a manifest of relative paths written by the detect step.
    # Each line is a path relative to the site source, e.g:
    #   assets/images/hero.png
    #   assets/images/team/alice.png
    # Lines that are empty, missing on disk, or not a recognised image type are skipped.
    def self.load_from_manifest(site)
      manifest_path = ENV["WEBP_MANIFEST"]
      unless File.exist?(manifest_path)
        raise "[vips-webp] WEBP_MANIFEST was set but file not found: #{manifest_path}"
      end

      paths = File.readlines(manifest_path, chomp: true)
        .map(&:strip)
        .reject(&:empty?)
        .map { |rel| File.join(site.source, rel) }
        .select { |p| File.exist?(p) && IMAGE_EXTS.include?(File.extname(p).downcase) }

      log_info "Manifest loaded: #{paths.size} image(s) to process"
      paths
    end

    # Local dev path: scan the full image directory.
    def self.scan_source_images(site)
      image_dir = File.join(site.source, "assets", "images")
      all_paths = Dir.glob(File.join(image_dir, "**", "*"), File::FNM_CASEFOLD).select do |path|
        IMAGE_EXTS.include?(File.extname(path).downcase) && !(File.basename(path) =~ /-\d+w\.webp$/i)
      end
      sources_by_base = {}
      all_paths.each do |path|
        base_path = path.sub(/\.(jpe?g|png)\z/i, "")
        sources_by_base[base_path] ||= path
      end
      sources_by_base.values
    end

    # ---------------------------------------------------------------------------
    # Image processing
    # ---------------------------------------------------------------------------

    def self.generate_responsive_images(path)
      base_path = path.sub(/\.(jpe?g|png)\z/i, "")
      with_path_lock(base_path) do
        begin
          source_mtime = File.mtime(path)

          unless @force_regen
            cleanup_zero_outputs(base_path)
            cached_width = read_meta_width(base_path, source_mtime)
            if cached_width
              if outputs_fresh?(base_path, source_mtime, cached_width)
                log_info "✓ #{File.basename(path)} (fresh outputs)"
                return
              end
            end
          end

          image = Vips::Image.new_from_file(path, access: :random)
          image = image.autorot if image.respond_to?(:autorot)
          original_width = image.width

          cleanup_stale_responsive_images(base_path, original_width)

          base_webp_path = "#{base_path}.webp"
          image.webpsave(base_webp_path, **SAVE_OPTIONS)
          if File.size?(base_webp_path)
            log_info "#{File.basename(path)} -> #{File.basename(base_webp_path)}"
          else
            File.delete(base_webp_path) if File.exist?(base_webp_path)
            log_warn "failed to generate #{File.basename(base_webp_path)} - file is empty"
            return
          end

          SIZES.each do |width|
            next if width > original_width

            webp_path = "#{base_path}-#{width}w.webp"
            resized = image.thumbnail_image(width)
            resized.webpsave(webp_path, **SAVE_OPTIONS)

            if File.size?(webp_path)
              log_info "#{File.basename(path)} -> #{File.basename(webp_path)}"
            else
              File.delete(webp_path) if File.exist?(webp_path)
              log_warn "failed to generate #{File.basename(webp_path)} - file is empty"
            end
          end

          write_meta(base_path, original_width)

        rescue StandardError => e
          log_warn "failed on #{path}: #{e.message}"
        end
      end
    end

    # ---------------------------------------------------------------------------
    # Meta file helpers
    # ---------------------------------------------------------------------------

    def self.write_meta(base_path, width)
      File.write("#{base_path}#{META_SUFFIX}", width.to_s)
    rescue StandardError => e
      log_warn "failed to write meta for #{File.basename(base_path)}: #{e.message}"
    end

    def self.read_meta_width(base_path, source_mtime)
      meta_path = "#{base_path}#{META_SUFFIX}"
      return nil unless File.exist?(meta_path)
      return nil if File.mtime(meta_path) < source_mtime

      width = Integer(File.read(meta_path).strip)
      width > 0 ? width : nil
    rescue ArgumentError, TypeError
      File.delete("#{base_path}#{META_SUFFIX}") rescue nil
      nil
    rescue StandardError
      nil
    end

    # ---------------------------------------------------------------------------
    # Freshness and cleanup helpers
    # ---------------------------------------------------------------------------

    def self.with_path_lock(base_path)
      lock = @path_locks_mutex.synchronize do
        @path_locks[base_path] ||= Mutex.new
      end
      lock.synchronize { yield }
    end

    def self.base_output_fresh?(base_path, source_mtime)
      base_webp_path = "#{base_path}.webp"
      if File.exist?(base_webp_path) && !File.size?(base_webp_path)
        File.delete(base_webp_path)
        return false
      end
      return false unless File.size?(base_webp_path)
      File.mtime(base_webp_path) >= source_mtime
    rescue StandardError
      false
    end

    def self.outputs_fresh?(base_path, source_mtime, original_width)
      base_webp_path = "#{base_path}.webp"
      if File.exist?(base_webp_path) && !File.size?(base_webp_path)
        File.delete(base_webp_path)
        return false
      end
      return false unless File.size?(base_webp_path)
      return false if File.mtime(base_webp_path) < source_mtime

      expected_sizes = SIZES.select { |w| w <= original_width }
      expected_sizes.each do |width|
        webp_path = "#{base_path}-#{width}w.webp"
        if File.exist?(webp_path) && !File.size?(webp_path)
          File.delete(webp_path)
          return false
        end
        return false unless File.size?(webp_path)
        return false if File.mtime(webp_path) < source_mtime
      end
      true
    rescue StandardError => e
      log_warn "failed to check freshness for #{File.basename(base_path)}: #{e.message}"
      false
    end

    def self.cleanup_zero_outputs(base_path)
      paths = ["#{base_path}.webp"]
      SIZES.each { |width| paths << "#{base_path}-#{width}w.webp" }
      paths.each do |webp_path|
        next unless File.exist?(webp_path)
        next if File.size?(webp_path)
        File.delete(webp_path)
        log_info "removed empty #{File.basename(webp_path)}"
      end
    rescue StandardError => e
      log_warn "failed to clean empty outputs for #{File.basename(base_path)}: #{e.message}"
    end

    def self.cleanup_stale_responsive_images(base_path, original_width)
      expected_sizes = SIZES.select { |w| w <= original_width }
      dir = File.dirname(base_path)
      base_name = File.basename(base_path)
      pattern = File.join(dir, "#{base_name}-[0-9]*w.webp")

      Dir.glob(pattern).each do |webp_path|
        basename_pattern = /\A#{Regexp.escape(base_name)}-(\d+)w\.webp\z/i
        match = basename_pattern.match(File.basename(webp_path))
        next unless match
        width = match[1].to_i
        next if expected_sizes.include?(width)
        File.delete(webp_path)
        log_info "removed stale #{File.basename(webp_path)}"
      end
    rescue StandardError => e
      log_warn "failed to clean stale images for #{File.basename(base_path)}: #{e.message}"
    end

    # ---------------------------------------------------------------------------
    # Logging
    # ---------------------------------------------------------------------------

    def self.log_info(message)
      worker = Thread.current[:webp_worker_id]
      prefix = worker ? "[worker-#{worker}]" : ""
      puts "[vips-webp]#{prefix} #{message}"
    end

    def self.log_warn(message)
      worker = Thread.current[:webp_worker_id]
      prefix = worker ? "[worker-#{worker}]" : ""
      warn "[vips-webp]#{prefix} #{message}"
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  require "ostruct"

  source_dir = ARGV[0] || Dir.pwd

  site = OpenStruct.new(source: File.expand_path(source_dir))

  puts "[vips-webp] Running in CLI mode"
  puts "[vips-webp] Source: #{site.source}"

  ItalAI::VipsWebpGenerator.run(site)
end

if defined?(Jekyll)
  if ENV["GITHUB_ACTIONS"] == "true"
    puts "[vips-webp] Skipping Jekyll hook in GitHub Actions"
  else
    Jekyll::Hooks.register :site, :after_init do |site|
      ItalAI::VipsWebpGenerator.run(site)
    end
  end
end