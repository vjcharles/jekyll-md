# frozen_string_literal: true

module JekyllMarkdownRenderer
  # A synthetic Jekyll::Page that holds the Liquid-rendered Markdown content.
  # It bypasses the Markdown→HTML converter by declaring its own converter
  # that passes content through unchanged.
  class MarkdownPage < Jekyll::Page
    def initialize(site, source_doc, output_dir, config)
      @site = site
      @base = site.source
      @config = config

      if output_dir
        # Grouped mode: all .md files land in a subdirectory
        @dir  = output_dir
        @name = build_filename(source_doc)
      else
        # Alongside mode: .md sits next to the .html at the same path
        url = source_doc.url.to_s
        @dir  = File.dirname(url).sub(%r{^/}, "")
        @name = File.basename(url, File.extname(url)) + ".md"
      end

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
end
