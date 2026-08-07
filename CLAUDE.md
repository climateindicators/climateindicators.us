# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the source code for the [climateindicators.us](https://climateindicators.us/)
website — an open, reproducible collection of climate indicators for the United
States. The project began as a replication of the EPA's *Climate Change
Indicators*, preserved in the [January 19, 2025 snapshot](https://19january2025snapshot.epa.gov/climate-indicators/view-indicators/index.html).

The site is built with **Quarto** and deployed to **GitHub Pages** (the
`gh-pages` branch) via GitHub Actions.

**Current status: scaffold.** The page structure, theme, and deploy pipeline
are all working, but every page is placeholder content — a shared "coming soon"
callout. There is one indicator (Heat-Related Deaths) and it has no data,
methodology, or charts yet. Expect to be filling pages in, not restructuring.

There is also no favicon or social-card image yet. `_quarto.yml` omits
`favicon:` and `image:` on purpose rather than pointing at files that do not
exist — add the assets to `images/` before adding the keys.

## Common Commands

- `quarto render` — render the entire website to `_site/`
- `quarto preview` — start the local dev server (port 5679, per `_quarto.yml`)

## Architecture

### File Structure



### Styling System

- Quarto's Bootstrap 5 theme system, `cosmo` plus `css/theme.scss`
- **Light theme only — there is deliberately no dark variant.** `theme:` in
  `_quarto.yml` is a single list, not a `light:`/`dark:` map, so Quarto emits
  one CSS bundle and no color-scheme toggle. Do not add `body.quarto-dark`
  rules; they are dead code unless a dark theme is reintroduced.
- **The palette is defined once in a variable block at the top of the
  `scss:defaults` section** (`$accent`, `$ink`, `$panel`, `$rule`, …), lifted
  from [climate.us](https://www.climate.us/). Every tinted rule derives from
  those variables — re-theming means editing that block, not hunting for
  hard-coded hex codes. Keep it that way.
- Because there is only one theme, page-level colors belong in `scss:defaults`
  as Bootstrap variables (`$primary`, `$body-bg`, `$body-color`) rather than as
  `body {}` overrides in `scss:rules`. Setting `$primary: $accent` recolors
  links, focus rings, and active states site-wide — Bootstrap derives
  `$link-color` from `$primary`.
- Key aesthetic notes: near-black (`$ink`) navbar and footer, white page
  background with warm off-white (`$panel`) cards and sidebar, `#2882e6` blue
  accent, Source Sans 3 throughout, squared-off 4px card corners, and
  underlined in-content links (explicitly flattened inside listing cards).
- The Bootstrap navbar brand is hidden above 992px because the site title is
  repeated as the first navbar item; it reappears in the collapsed mobile bar.

Two navbar details that are easy to break:

- **Height** is controlled solely by `$navbar-padding-y`. The bar carries
  `min-height: 0`, so that padding is the only lever — change the variable, not
  the rule.
- **The active-section rule** under the current nav item is an absolutely
  positioned `::after` bar, deliberately *not* a `border-bottom` or an inset
  `box-shadow`. Both of those inherit the link's 6px `border-radius` and make
  the rule visibly bow upward at its ends. It is inset by the link's horizontal
  padding so it tracks the label rather than the wider hover block.

### Navigation

- Navbar left: the site title (`climateindicators.us`, linking home), About,
  Indicators. Right: GitHub and search.
- One docked sidebar, titled "Indicators", that appears on `indicators.qmd` and
  all pages under `indicators/`. Indicators are grouped into sections by theme
  (e.g. "Health").

## Content Development

### Adding an Indicator

1. Create `indicators/<slug>.qmd`
2. Add front matter with `title`, `description`, and `categories` — the
   `description` and `categories` feed the listing grid on `indicators.qmd`, so
   they are not optional
3. Add a sidebar entry under the appropriate section in `_quarto.yml`
4. While the page is a stub, include `{{< include ../chunks/coming-soon.qmd >}}`
   rather than writing a one-off placeholder

### Placeholder Content

`chunks/coming-soon.qmd` is the single source for the "coming soon" callout and
is currently included on **every** page (index, about, indicators, and the one
indicator page). Edit that file to change the wording everywhere. As real
content lands, drop the include from that page rather than editing the chunk.

### R Code Integration

- R chunks are `eval: false` by default (see `execute:` in `_quarto.yml`); set
  `#| eval: true` on blocks that should run
- Shared helpers go in `_common.R`
- New package dependencies must be added to `DESCRIPTION`, or the GitHub Action
  will not install them

## Deployment

`.github/workflows/main.yml` runs on push to `main`, on PRs, and weekly. It sets
up R, installs `DESCRIPTION` dependencies, renders the site, and publishes
`_site/` to the `gh-pages` branch (publish step is skipped for PRs).

**This is already set up and working.** The `gh-pages` branch exists, GitHub
Pages is serving from it at `/ (root)`, and pushes to `main` deploy end to end.
Nothing needs re-initializing.

Two things to be aware of:

- **The custom domain is not attached yet.** Pages currently serves at
  <https://climateindicators.github.io/climateindicators.us/>, but `site-url` in
  `_quarto.yml` claims `https://climateindicators.us`. Relative links are fine
  either way, but `sitemap.xml` and the OpenGraph tags carry the wrong absolute
  host until DNS is pointed at GitHub and the domain is set (which writes a
  `CNAME` file to `gh-pages`; the Quarto publish action preserves it).
- **The weekly `schedule:` trigger** rebuilds and redeploys every Sunday. That
  matters once indicators pull live data; right now it just redeploys static
  content. Remove the `schedule:` block if the noise is unwanted.

The `origin` remote uses SSH (`git@github.com:...`) because the local `gh` auth
is configured for the SSH protocol; HTTPS pushes fail with no credentials.
