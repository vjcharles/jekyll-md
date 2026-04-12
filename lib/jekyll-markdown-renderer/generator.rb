# frozen_string_literal: true

module JekyllMarkdownRenderer
  # Generates .md output files alongside the normal HTML build.
  class Generator < Jekyll::Generator
    safe true
    priority :lowest # Run after other generators so all data is populated

    def generate(site)
      config = site.config.fetch("markdown_renderer", {})
      return unless config.fetch("enabled", true)

      scope      = config.fetch("scope", "all")
      output_dir = config.fetch("output_dir", "md")

      documents = collect_documents(site, scope)

      Jekyll.logger.info "MarkdownRenderer:", "Processing #{documents.size} document(s) → /#{output_dir}/"

      documents.each do |doc|
        md_page = MarkdownPage.new(site, doc, output_dir, config)
        site.pages << md_page
      end
    end

    private

    def collect_documents(site, scope)
      case scope
      when "posts"
        markdown_docs(site.posts.docs)
      when "pages"
        markdown_pages(site.pages)
      when "tagged"
        tagged_docs(site)
      else # "all"
        markdown_docs(site.posts.docs) + markdown_pages(site.pages)
      end
    end

    def markdown_docs(docs)
      docs.select { |d| markdown_ext?(d.data.fetch("ext", d.extname)) }
    end

    def markdown_pages(pages)
      pages.select { |p| markdown_ext?(p.ext || File.extname(p.name)) }
    end

    def tagged_docs(site)
      all = site.posts.docs + site.pages
      all.select { |d| d.data["markdown_output"] == true }
    end

    def markdown_ext?(ext)
      %w[.md .markdown .mkd .mkdn].include?(ext.to_s.downcase)
    end
  end
end
