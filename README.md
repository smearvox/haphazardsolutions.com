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

## Previewing locally (Docker — nothing installs on your machine)

The site runs in a container; gems live in a Docker volume (`hs-bundle`), so
nothing lands on the host. Matches the GitHub Pages build (Jekyll 3.10 /
github-pages gem).

First-time setup — install gems into the volume:
```sh
docker run --rm -v "D:/dev/hs:/site" -w /site -v hs-bundle:/usr/local/bundle \
  ruby:3.1 bundle install
```

Start the live server (auto-rebuilds on save):
```sh
docker run -d --name hs-jekyll -v "D:/dev/hs:/site" -w /site \
  -v hs-bundle:/usr/local/bundle -p 4000:4000 \
  ruby:3.1 bundle exec jekyll serve --host 0.0.0.0 --force_polling
```
→ http://localhost:4000

Everyday controls:
```sh
docker stop hs-jekyll     # pause
docker start hs-jekyll    # resume (gems stay cached in the volume)
docker logs -f hs-jekyll  # watch build output
docker rm -f hs-jekyll    # remove container; volume + source untouched
```

## Custom domain & email

- DNS is configured at the domain registrar (see the setup notes).
- For a professional `you@haphazardsolutions.com` address, add an email
  service (e.g. Google Workspace, Fastmail, or Zoho) — separate from hosting.
