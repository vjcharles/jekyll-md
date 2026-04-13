# jekyll-md

A Jekyll plugin that outputs `.md` files with Liquid templates rendered but Markdown left intact.

Your post at `/blog/2026/04/11/my-post.html` gets a sibling at `/blog/2026/04/11/my-post.md` — same content, Liquid resolved, Markdown preserved.

## Install

Add to your `Gemfile`:

```ruby
group :jekyll_plugins do
  gem "jekyll-md"
end
```

Then `bundle install`.

Or copy `markdown_renderer.rb` into your `_plugins/` directory.

## Configure

Add to `_config.yml`:

```yaml
markdown_renderer:
  enabled: true
  scope: "all"        # "all" | "posts" | "pages" | "tagged"
```

By default, `.md` files are placed alongside their `.html` counterparts. To group them in a subdirectory instead:

```yaml
markdown_renderer:
  output_dir: "md"    # all .md files land in _site/md/
```

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `enabled` | `true` | Master switch |
| `scope` | `"all"` | Which docs get `.md` output: `all`, `posts`, `pages`, or `tagged` |
| `output_dir` | none | Set to group `.md` files in a subdirectory (e.g. `"md"`) |
| `preserve_front_matter` | `true` | Include YAML front matter in output |
| `front_matter_fields` | all | List of front matter keys to keep (omit to keep all) |

### Per-page opt-in

With `scope: "tagged"`, only pages with `markdown_output: true` in their front matter get `.md` output.

## How it works

Jekyll's pipeline: Front Matter → Liquid → Markdown → HTML → Layouts.

This plugin intercepts after Liquid rendering but before Markdown-to-HTML conversion. It creates a synthetic page with a passthrough converter that writes the result as `.md`.

## License

MIT
