# Haphazard Solutions — website

The source for [haphazardsolutions.com](https://haphazardsolutions.com), a
[Jekyll](https://jekyllrb.com/) site hosted on **GitHub Pages**.

## How it's structured

```
_config.yml          Site-wide settings (title, nav, email, URL)
CNAME                Custom domain (haphazardsolutions.com) — don't delete
index.html           Home page
services.html        Services page
about.html           About page
_layouts/default.html   The HTML shell every page uses
_includes/           Reusable header & footer
assets/css/style.css    All styling (edit :root variables to re-theme)
assets/favicon.svg   Browser tab icon
```

## Editing content

- **Text & pages:** edit the `.html` files. The content lives below the
  `---` front-matter block at the top of each file.
- **Navigation:** edit the `nav:` list in `_config.yml`.
- **Colors / branding:** edit the variables in `:root` at the top of
  `assets/css/style.css`.
- Look for `TODO` comments — those mark the spots to personalize.

Every push to the `main` branch automatically rebuilds and republishes the
site (usually live within a minute).

## Previewing locally (optional)

You don't need this to publish, but it gives a fast edit loop. Requires Ruby:

```sh
gem install bundler
bundle install
bundle exec jekyll serve   # → http://localhost:4000
```

## Custom domain & email

- DNS is configured at the domain registrar (see the setup notes).
- For a professional `you@haphazardsolutions.com` address, add an email
  service (e.g. Google Workspace, Fastmail, or Zoho) — separate from hosting.
