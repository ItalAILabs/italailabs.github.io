# Remove empty lines from rendered outputs
module ItalAI
  class RemoveEmptyLines
    def self.strip_empty_lines(str)
      return str unless str.is_a?(String)
      str.lines.reject { |line| line.strip.empty? }.join
    end
  end
end

Jekyll::Hooks.register :pages, :post_render do |page|
  ext = page.respond_to?(:output_ext) ? page.output_ext : File.extname(page.path)
  next unless ext == ".html" || ext == ".xml"
  page.output = ItalAI::RemoveEmptyLines.strip_empty_lines(page.output)
end

Jekyll::Hooks.register :documents, :post_render do |doc|
  ext = doc.respond_to?(:output_ext) ? doc.output_ext : File.extname(doc.path)
  next unless ext == ".html" || ext == ".xml"
  doc.output = ItalAI::RemoveEmptyLines.strip_empty_lines(doc.output)
end
