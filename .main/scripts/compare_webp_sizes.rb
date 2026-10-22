#!/usr/bin/env ruby
# Compare WebP file sizes against their original JPG/PNG sources

IMAGE_DIR = "assets/images"
EXTS = %w[.jpg .jpeg .png]

def human_size(bytes)
  if bytes < 1024
    "#{bytes}B"
  elsif bytes < 1024 * 1024
    "#{(bytes / 1024.0).round(1)}KB"
  else
    "#{(bytes / (1024.0 * 1024)).round(2)}MB"
  end
end

webp_files = Dir.glob(File.join(IMAGE_DIR, "**", "*.webp"))

if webp_files.empty?
  puts "No WebP files found in #{IMAGE_DIR}"
  exit
end

results = []
total_original = 0
total_webp = 0
missing = []

webp_files.each do |webp_path|
  base = webp_path.sub(/\.webp$/, "")
  
  original = EXTS.map { |ext| "#{base}#{ext}" }.find { |p| File.exist?(p) }
  
  if original
    orig_size = File.size(original)
    webp_size = File.size(webp_path)
    saved = orig_size - webp_size
    percent = (saved.to_f / orig_size * 100).round(1)
    
    results << {
      name: File.basename(webp_path),
      original: human_size(orig_size),
      webp: human_size(webp_size),
      saved: human_size(saved),
      percent: percent
    }
    
    total_original += orig_size
    total_webp += webp_size
  else
    missing << webp_path
  end
end

puts "WebP vs Original Size Comparison"
puts "=" * 80
puts "%-40s %10s %10s %10s %8s" % ["File", "Original", "WebP", "Saved", "Saved%"]
puts "-" * 80

results.sort_by { |r| -r[:percent] }.each do |r|
  puts "%-40s %10s %10s %10s %7.1f%%" % [
    r[:name].length > 40 ? "#{r[:name][0..36]}..." : r[:name],
    r[:original],
    r[:webp],
    r[:saved],
    r[:percent]
  ]
end

puts "=" * 80
total_saved = total_original - total_webp
total_percent = total_original > 0 ? (total_saved.to_f / total_original * 100).round(1) : 0

puts "%-40s %10s %10s %10s %7.1f%%" % [
  "TOTAL (#{results.size} files)",
  human_size(total_original),
  human_size(total_webp),
  human_size(total_saved),
  total_percent
]

if missing.any?
  puts "\nWebP files without originals (#{missing.size}):"
  missing.first(5).each { |p| puts "  - #{p}" }
  puts "  ... and #{missing.size - 5} more" if missing.size > 5
end
