# frozen_string_literal: true

module JekyllMarkdownRenderer
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
