# frozen_string_literal: true

module JekyllMarkdownRenderer
  # A converter that does nothing — passes Markdown through as-is.
  class PassthroughConverter < Jekyll::Converter
    safe true
    priority :lowest

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
