# Lazy Load Images Plugin
# Automatically adds loading="lazy" to all <img> tags in markdown content

Jekyll::Hooks.register [:posts, :pages, :documents], :post_render do |doc|
  # Only process HTML output
  next unless doc.output_ext == ".html"
  
  # Add loading="lazy" to all img tags that don't already have it
  doc.output = doc.output.gsub(/<img(?![^>]*\sloading=)([^>]*)>/) do |match|
    attributes = $1
    
    # Don't add lazy to images that explicitly set loading, have data-no-lazy, or have fetchpriority (LCP images)
    next match if attributes.include?('data-no-lazy') || attributes.include?('fetchpriority')
    
    # Add loading="lazy" before the closing >
    "<img#{attributes} loading=\"lazy\">"
  end
end
