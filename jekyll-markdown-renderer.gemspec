# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "jekyll-markdown-renderer"
  spec.version       = "0.1.0"
  spec.authors       = ["vjcharles"]
  spec.summary       = "Jekyll plugin that outputs Liquid-rendered Markdown alongside HTML"
  spec.description   = <<~DESC
    Renders Jekyll pages and posts through the Liquid template engine but stops
    before converting Markdown to HTML. Outputs .md files with processed Liquid
    tags and intact front matter - like Rails' respond_to for static sites.
  DESC
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.7.0"

  spec.files = Dir["lib/**/*.rb", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "jekyll", ">= 3.7", "< 5.0"
end
