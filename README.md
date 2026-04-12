# Jekyll Markdown Renderer

Outputs `.md` files with **Liquid templates rendered** but **Markdown left intact** — like Rails' `respond_to` for static sites.

## The Problem

Jekyll's pipeline: Front Matter → Liquid → Markdown→HTML → Layouts. There's no built-in way to get the output after Liquid processing but *before* HTML conversion. This plugin gives you that.

## Use Cases

- **API-style content delivery** — serve the same post as HTML (for browsers) and Markdown (for readers, RSS, CMS imports)
- **Content syndication** — export rendered Markdown to other platforms
- **Markdown-native readers** — provide downloadable `.md` versions of posts
- **Static site migration** — render Liquid includes/variables but keep Markdown for import into another system

## Install

### Option A: Drop-in plugin

Copy `_plugins/markdown_renderer.rb` into your Jekyll site's `_plugins/` directory. Done.

### Option B: As a gem

Add to your `Gemfile`:

```ruby
group :jekyll_plugins do
  gem "jekyll-markdown-renderer", path: "/path/to/this/repo"
end
```

## Configure

Add to `_config.yml`:

```yaml
markdown_renderer:
  enabled: true
  scope: "all"           # "all" | "posts" | "pages" | "tagged"
  output_dir: "md"       # Files land in _site/md/
  strip_layouts: true     # Don't wrap in HTML layouts
  preserve_front_matter: true
  front_matter_fields:    # Omit to keep all fields
    - title
    - date
    - tags
    - categories
    - description
```

### Scopes

| Scope    | What gets a `.md` output                               |
|----------|--------------------------------------------------------|
| `all`    | Every Markdown page and post                           |
| `posts`  | Only `_posts`                                          |
| `pages`  | Only standalone Markdown pages                         |
| `tagged` | Only docs with `markdown_output: true` in front matter |

## Example

Given this source file:

```markdown
---
title: "Hello World"
date: 2025-01-15
tags: [intro, jekyll]
---

Welcome to {{ site.title }}! This post has {{ site.posts.size }} siblings.

{% for tag in page.tags %}
- Tagged: {{ tag }}
{% endfor %}

## What's Next

Check out the [about page]({{ "/about" | relative_url }}).
```

The plugin outputs `_site/md/hello-world.md`:

```markdown
---
title: Hello World
date: '2025-01-15'
tags:
- intro
- jekyll
---

Welcome to My Cool Blog! This post has 12 siblings.

- Tagged: intro
- Tagged: jekyll

## What's Next

Check out the [about page](/about).
```

Liquid tags are resolved. Markdown stays as Markdown.

## Per-Page Opt-In

If you use `scope: "tagged"`, add this to any page's front matter:

```yaml
---
title: "My Post"
markdown_output: true
---
```

Only tagged pages will get `.md` output.

## How It Works

1. A **Generator** runs after Jekyll reads the site, collecting eligible documents
2. For each document, it renders the raw content through **Liquid** (resolving `{{ }}` and `{% %}`)
3. It creates a synthetic **Page** with a **passthrough converter** that skips Markdown→HTML
4. Jekyll writes the result as a `.md` file in your output directory

The key trick is overriding `converters` on the synthetic page to return a no-op converter, so Jekyll's normal pipeline writes the file without touching the Markdown.

## License

MIT
