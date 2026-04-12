# frozen_string_literal: true

require "minitest/autorun"
require "jekyll"
require_relative "../lib/jekyll-markdown-renderer"

class TestMarkdownRenderer < Minitest::Test
  FIXTURES = File.expand_path("fixtures/src", __dir__)
  DEST     = File.expand_path("fixtures/dest", __dir__)

  def setup
    @config = Jekyll.configuration(
      "source"      => FIXTURES,
      "destination"  => DEST,
      "markdown_renderer" => { "enabled" => true, "scope" => "all" }
    )
    @site = Jekyll::Site.new(@config)
    @site.process
  end

  def teardown
    FileUtils.rm_rf(DEST)
  end

  # --- Alongside output paths ---

  def test_post_md_alongside_html
    html = Dir.glob("#{DEST}/**/hello-world.html").first
    md   = Dir.glob("#{DEST}/**/hello-world.md").first
    assert html, "HTML version should exist"
    assert md,   "MD version should exist"
    assert_equal File.dirname(html), File.dirname(md),
      "MD should sit alongside HTML"
  end

  def test_page_md_alongside_html
    assert File.exist?("#{DEST}/about.html"), "About HTML should exist"
    assert File.exist?("#{DEST}/about.md"),   "About MD should exist"
  end

  # --- Front matter ---

  def test_md_output_has_clean_front_matter
    md_path = Dir.glob("#{DEST}/**/hello-world.md").first
    content = File.read(md_path)

    assert content.start_with?("---"), "Should start with front matter"
    refute content.include?("!ruby/object"), "Should not contain Ruby objects"
    assert content.include?("title:"), "Should include title"
  end

  def test_md_output_excludes_jekyll_internals
    md_path = Dir.glob("#{DEST}/**/hello-world.md").first
    content = File.read(md_path)

    refute content.include?("excerpt:"), "Should not include excerpt"
    refute content.include?("collection:"), "Should not include collection"
  end

  # --- Liquid rendering ---

  def test_liquid_is_rendered_in_md_output
    md_path = Dir.glob("#{DEST}/**/hello-world.md").first
    content = File.read(md_path)

    assert content.include?("Welcome to Test Site"),
      "Liquid {{ site.title }} should be resolved"
    refute content.include?("{{ site.title }}"),
      "Raw Liquid tags should not remain"
  end

  # --- Markdown preserved ---

  def test_markdown_is_not_converted_to_html
    md_path = Dir.glob("#{DEST}/**/hello-world.md").first
    content = File.read(md_path)

    assert content.include?("## Subheading"), "Markdown headings should be preserved"
    assert content.include?("**bold**"), "Markdown bold should be preserved"
    assert content.include?("[link](/about)"), "Markdown links should be preserved"
    refute content.include?("<h2>"), "Should not contain HTML heading tags"
    refute content.include?("<strong>"), "Should not contain HTML strong tags"
  end

  # --- Grouped output_dir mode ---

  def test_grouped_mode_puts_files_in_subdirectory
    FileUtils.rm_rf(DEST)
    config = Jekyll.configuration(
      "source"      => FIXTURES,
      "destination"  => DEST,
      "markdown_renderer" => { "enabled" => true, "scope" => "all", "output_dir" => "md" }
    )
    site = Jekyll::Site.new(config)
    site.process

    md_files = Dir.glob("#{DEST}/md/**/*.md")
    assert md_files.any?, "MD files should exist under /md/"
  end

  # --- HTML output unaffected ---

  def test_html_output_is_normal
    html_path = Dir.glob("#{DEST}/**/hello-world.html").first
    content = File.read(html_path)

    assert content.include?("<h2"), "HTML should contain rendered heading"
    assert content.include?("<strong>bold</strong>"), "HTML should contain rendered bold"
  end
end
