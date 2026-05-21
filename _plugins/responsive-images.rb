# Responsive Images Plugin
# Automatically adds srcset and sizes attributes to <img> tags
# Works on GitHub Pages (no external dependencies)
#
# Usage: Just use regular <img> tags in your HTML/Markdown:
#   <img src="/assets/images/blog/my-image.jpg" alt="Description">
#
# The plugin will automatically:
# 1. Convert .jpg/.jpeg/.png to .webp
# 2. Add srcset with all available responsive sizes
# 3. Add appropriate sizes attribute

module ItalAI
  class ResponsiveImages
    SIZES = [400, 800, 1200, 1600].freeze
    
    def self.process(site, doc)
      return unless [".html"].include?(doc.output_ext)
      return if doc.output.nil? || doc.output.empty?
      
      # Match img tags with jpg/jpeg/png/webp extensions (exclude gif)
      doc.output = doc.output.gsub(/<img\s+([^>]*?)src=["']([^"']+\.(jpe?g|png|webp))["']([^>]*?)>/i) do
        attributes_before = $1
        src_path = $2
        ext = $3
        attributes_after = $4
        
        # Convert to WebP if not already
        webp_src = src_path.sub(/\.(jpe?g|png|webp)\z/i, '.webp')
        
        # Generate srcset if responsive versions exist
        srcset = build_srcset(site, src_path)
        sizes = determine_sizes(src_path, attributes_before + attributes_after)
        
        # Build the new img tag
        img_attrs = "#{attributes_before}src=\"#{webp_src}\""
        img_attrs += " srcset=\"#{srcset}\"" unless srcset.empty?
        img_attrs += " sizes=\"#{sizes}\"" unless sizes.empty? || srcset.empty?
        img_attrs += attributes_after
        
        "<img #{img_attrs}>"
      end
    end
    
    def self.build_srcset(site, src_path)
      # Remove leading slash and convert to filesystem path
      rel_path = src_path.sub(%r{^/}, '')
      base_path = File.join(site.source, rel_path).sub(/\.(jpe?g|png|webp)\z/i, '')
      
      # Check which responsive sizes exist
      available_sizes = SIZES.select do |width|
        File.exist?("#{base_path}-#{width}w.webp")
      end
      
      return "" if available_sizes.empty?
      
      # Build srcset
      web_base = src_path.sub(/\.(jpe?g|png|webp)\z/i, '')
      available_sizes.map do |width|
        "#{web_base}-#{width}w.webp #{width}w"
      end.join(", ")
    end
    
    def self.determine_sizes(src_path, attributes)
      # Use 100vw by default and let CSS handle the actual sizing
      # This ensures the browser has all sizes available and CSS controls display
      "100vw"
    end
  end
end

# Process all pages, posts, and documents after rendering
Jekyll::Hooks.register [:pages, :posts, :documents], :post_render do |doc|
  ItalAI::ResponsiveImages.process(doc.site, doc)
end

Jekyll::Hooks.register :site, :post_write do |site|
  puts "\n✨ Responsive Images: Automatically added srcset to image tags"
end
