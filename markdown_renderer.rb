# frozen_string_literal: true

#
# Jekyll Markdown Renderer
#
# Outputs .md files with front matter intact and Liquid templates rendered,
# but WITHOUT converting Markdown to HTML. Think of it like Rails'
# respond_to { |f| f.html; f.md } — same content, different format.
#
# Usage:
#   1. Drop this file into your _plugins/ directory
#   2. Configure in _config.yml (see below)
#   3. Optionally add `markdown_output: true` to individual page/post front matter
#
# _config.yml options:
#
#   markdown_renderer:
#     enabled: true            # Master switch (default: true)
#     scope: "all"             # "all", "posts", "pages", or "tagged"
#                              #   - "all"    → every markdown document
#                              #   - "posts"  → only _posts
#                              #   - "pages"  → only standalone pages
#                              #   - "tagged" → only docs with `markdown_output: true` in front matter
#     output_dir: "md"         # Output subdirectory (default: "md")
#     strip_layouts: true      # Remove layout wrappers from output (default: true)
#     preserve_front_matter: true  # Include YAML front matter in output (default: true)
#     front_matter_fields:     # Which front matter keys to keep (default: all)
#       - title
#       - date
#       - tags
#       - categories
#       - description
#

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

  # A synthetic Jekyll::Page that holds the Liquid-rendered Markdown content.
  # It bypasses the Markdown→HTML converter by declaring its own converter
  # that passes content through unchanged.
  class MarkdownPage < Jekyll::Page
    def initialize(site, source_doc, output_dir, config)
      @site = site
      @base = site.source
      @dir  = output_dir
      @name = build_filename(source_doc)
      @config = config

      @output_front_matter = build_front_matter(source_doc, config)
      self.content = render_liquid(source_doc)

      # Keep self.data minimal — no title, no layout — so themes don't
      # pick up synthetic pages in nav, sitemaps, feeds, etc.
      self.data = { "layout" => nil, "sitemap" => false }

      process(@name)
    end

    # Override output_ext so Jekyll writes a .md file, not .html
    def output_ext
      ".md"
    end

    # Override the converters so Markdown is NOT converted to HTML.
    # We return a passthrough converter instead.
    def converters
      [PassthroughConverter.new(@site.config)]
    end

    # Build the final file content: optional front matter + rendered markdown
    def output
      if @config.fetch("preserve_front_matter", true) && !@output_front_matter.empty?
        front = @output_front_matter.to_yaml.strip + "\n---\n\n"
        front + (self.content || "")
      else
        self.content || ""
      end
    end

    private

    def build_filename(source_doc)
      if source_doc.respond_to?(:slug)
        # It's a Document (post, collection item)
        "#{source_doc.data['slug'] || source_doc.slug}.md"
      else
        # It's a Page
        File.basename(source_doc.name, File.extname(source_doc.name)) + ".md"
      end
    end

    def build_front_matter(source_doc, config)
      raw = source_doc.data.dup

      # Remove Jekyll internals that don't belong in output
      %w[ext output layout excerpt content next previous collection].each { |k| raw.delete(k) }

      allowed = config["front_matter_fields"]
      if allowed.is_a?(Array) && !allowed.empty?
        raw.select! { |k, _| allowed.include?(k) }
      else
        # Only keep YAML-safe values — reject complex Ruby objects
        raw.select! { |_k, v| yaml_safe?(v) }
      end

      raw
    end

    def data_for_front_matter
      (@output_front_matter || {}).reject { |k, v| v.nil? || %w[output permalink].include?(k) }
    end

    def yaml_safe?(value)
      case value
      when String, Integer, Float, TrueClass, FalseClass, NilClass
        true
      when Time, Date
        true
      when Array
        value.all? { |v| yaml_safe?(v) }
      when Hash
        value.all? { |_k, v| yaml_safe?(v) }
      else
        false
      end
    end

    def render_liquid(source_doc)
      raw_content = source_doc.content.to_s.dup

      # Build a Liquid template and render it with the site's payload
      payload = site.site_payload
      payload["page"] = source_doc.data.merge("content" => raw_content)

      info = {
        registers: { site: site, page: payload["page"] },
        filters: [Jekyll::Filters]
      }

      begin
        template = Liquid::Template.parse(raw_content)
        template.render!(payload, info)
      rescue Liquid::Error => e
        Jekyll.logger.warn "MarkdownRenderer:", "Liquid error in #{source_doc.relative_path}: #{e.message}"
        raw_content # Fall back to unrendered content
      end
    end
  end

  # A converter that does nothing — passes Markdown through as-is.
  # Plain class (not a Jekyll::Converter subclass) so Jekyll doesn't
  # auto-register it globally and interfere with other pages' converter chains.
  class PassthroughConverter
    def initialize(_config = {}); end

    def matches(_ext)
      true
    end

    def output_ext(_ext)
      ".md"
    end

    def convert(content)
      content
    end
  end
end
