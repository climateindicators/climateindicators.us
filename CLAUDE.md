# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**This file is the only place project rules live.** Do not write rules,
conventions, "hard rules", or general-pattern explanations into comments in
`R/*.R` or into `.qmd` files. Code comments explain the specific line or block
they sit above — why *this* chart splits *this* series, why *this* column is a
factor — and nothing broader. If you find yourself writing a comment that
would apply to more than one file, it belongs here instead.

## Project Overview

This is the source code for the [climateindicators.us](https://climateindicators.us/)
website — an open, reproducible collection of climate indicators for the United
States. The project began as a replication of the EPA's *Climate Change
Indicators*, preserved in the [January 19, 2025 snapshot](https://19january2025snapshot.epa.gov/climate-indicators/view-indicators/index.html).

The site is built with **Quarto** and deployed to **GitHub Pages** (the
`gh-pages` branch) via GitHub Actions.

**This repository is the website and nothing else.** It holds pages, styling,
and the R code that draws the figures. It holds no data.

There is no favicon or social-card image yet. `_quarto.yml` omits `favicon:`
and `image:` on purpose rather than pointing at files that do not exist — add
the assets to `images/` before adding the keys.

## Data Lives in the Indicator Repositories

Every indicator has its own repository under the
[climateindicators](https://github.com/climateindicators) org, which holds the
raw source files (`data-raw/`), the extraction pipeline, the published figure
images, and the clean data (`data/`) — a set of tidy CSVs plus a `meta.yml`
data dictionary. For example:
<https://github.com/climateindicators/cold-related-deaths/tree/main/data>.

**Never copy that data into this repository.** There is no `data/`,
`data-raw/`, or `indicators-src/` directory here, no git submodules, and no
sync step. Pages read the clean data straight off `raw.githubusercontent.com`
at render time, through the helpers in `R/common.R`. Adding a local copy would
create a second version of a number that can drift from the first.

Current indicator repositories:

| Indicator | Repository |
| --- | --- |
| Heat-Related Deaths | `heat-related-deaths` |
| Cold-Related Deaths | `cold-related-deaths` |
| Heat-Related Workplace Deaths | `heat-related-workplace-deaths` |
| Lyme Disease | `lyme-disease` |

Because the data is fetched over the network, rendering requires an internet
connection, and `curl` must stay in `DESCRIPTION` — readr only *suggests* it,
so remote reads fail without it.

## Common Commands

- `quarto render` — render the entire website to `_site/`
- `quarto preview` — start the local dev server (port 5679, per `_quarto.yml`)

## Architecture

### File Structure

```
_quarto.yml              site config: navbar, sidebar, theme, execute defaults
index.qmd                home page
about.qmd                about page
indicators.qmd           listing grid, fed by each indicator's front matter
404.qmd
chunks/                  reusable includes (coming-soon, description)
css/theme.scss           the single theme: scss:defaults palette + scss:rules
images/                  site-level images only (no per-indicator images)
indicators/<slug>.qmd    one page per indicator
R/common.R               helpers every page uses
R/<slug>.R               figures for indicators/<slug>.qmd, one file per page
DESCRIPTION              package dependencies the GitHub Action installs
```

`R/` contains exactly two kinds of file: `common.R`, and one file per page
named for that page's slug. Nothing else — no `figures.R`, no `utils/`, no
build or extraction scripts. Extraction and validation code belongs upstream
in the indicator's own repository.

### R Code Organization

`R/common.R` holds what more than one page needs:

- `indicator_url()` / `indicator_file_url()` — build raw and github.com URLs
- `read_indicator(repo, file)` — fetch and type one clean CSV
- `read_meta(repo)`, `meta_for(repo, file)` — the upstream `meta.yml`
- `figure_caption(repo, file)`, `technical_documentation_link(repo)` — the
  caption block above a figure and the TD link, both read from `meta.yml`
- `theme_indicator()`, `INDICATOR_PALETTE`, `palette_for()`, `label_colours()`,
  `label_order()`, `legend_top()` — chart styling
- `girafe_indicator()` — wrap a ggplot as a ggiraph htmlwidget

Every fetch is cached for the life of the render, so a figure and the table
beneath it cost one request between them.

`R/<slug>.R` holds only what that one page needs, and every file follows the
same shape:

- `REPO` — the indicator repository name
- `INDICATOR_COLOURS` — that page's series keys mapped to palette slots
- `fig_*_plot()` — builds the plain ggplot object
- `fig_*()` — wraps `fig_*_plot()` via `girafe_indicator()`
- `fig_*_table()` — the data frame shown under the figure

Rules for these files:

- **One R environment, always the global one.** Do not call `new.env()`,
  `local()`, or `sys.source()`, do not source anything into a separate
  environment, and do not expose figures as members of an environment — not for
  scoping, and not for caches or lookup tables either (use a named list). A
  page sources `R/common.R` and then its own file; both land in the global
  environment, and that is all the separation needed, because each page sources
  its own file before calling anything from it.
- **Do not prefix names.** `fig_1()`, not `hrd_fig_1()`. Each page loads
  exactly one indicator file, so there is nothing to disambiguate.
- **Colours are keyed by the machine-readable series key from the data, never
  by position.** An index-based lookup can swap two series and still look
  plausible. `INDICATOR_PALETTE` has four validated slots, in role order: blue
  is the baseline series, orange the series most worth the reader's attention,
  aqua a comparison series, magenta a category that is not a peer of the
  others.
- **Never re-derive a published number.** If a page needs a value the upstream
  `data/` does not carry, the fix goes in that indicator's repository, where it
  is tested and reproducible — not inline here, where nothing checks it.

### Page Structure

Each `indicators/<slug>.qmd` sets `execute: eval: true` in its front matter
(the site default is `eval: false`) and opens with:

```r
#| label: setup
#| include: false
source(here::here("R", "common.R"))
source(here::here("R", "<slug>.R"))
```

**Every figure on a page lives in one `## Figures` tabset**, using Quarto's
native `.panel-tabset`, with one tab per figure:

```markdown
## Figures

::::: {.panel-tabset}

### Figure 1

<caption chunk> <figure chunk> <prose> <details: table + downloads>

### Figure 2

...

:::::
```

Two things about that block:

- **The tabset fence is five colons, not three.** Some tabs nest a `:::`
  callout, and Pandoc requires the outer fence to be longer than any fence
  inside it. Five colons everywhere keeps this from breaking the next time a
  callout is added.
- **Tabs are `###`, one level below the `## Figures` heading.** Quarto turns
  them into tab labels and keeps them out of the TOC, which shows a single
  "Figures" entry.

Inside a tab, a figure is a caption chunk, a figure chunk, prose, and a
`<details>` block holding the data table and download links. Download links
point at the indicator repository on github.com — `data/` for the clean CSV,
`data-raw/` for EPA's original file — and figure images that a page displays
inline use `raw.githubusercontent.com`.

Charts render correctly in tabs that start hidden because `girafe_indicator()`
sets `opts_sizing(rescale = TRUE, width = 1)`, which emits a `viewBox`-only SVG
scaled by CSS. A widget that measured its container in JavaScript at init would
come out zero-width in a hidden tab — keep that sizing option.

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

1. Confirm the indicator's own repository exists under the `climateindicators`
   org and publishes `data/*.csv` plus `data/meta.yml` on `main`
2. Create `R/<slug>.R` following the shape described above
3. Create `indicators/<slug>.qmd` with front matter carrying `title`,
   `description`, `categories`, and `execute: eval: true` — the `description`
   and `categories` feed the listing grid on `indicators.qmd`, so they are not
   optional
4. Add a sidebar entry under the appropriate section in `_quarto.yml`
5. Add any new package dependency to `DESCRIPTION`, or the GitHub Action will
   not install it
6. While the page is a stub, include `{{< include ../chunks/coming-soon.qmd >}}`
   rather than writing a one-off placeholder

### Placeholder Content

`chunks/coming-soon.qmd` is the single source for the "coming soon" callout. It
is still included on `index.qmd`, `about.qmd`, and `indicators.qmd`; the four
indicator pages have real content and no longer include it. Edit that file to
change the wording everywhere. As real content lands on a page, drop the
include from that page rather than editing the chunk.

`chunks/description.qmd` is the shared project blurb, included on `index.qmd`
and `about.qmd`.

### R Code Integration

- R chunks are `eval: false` by default (see `execute:` in `_quarto.yml`);
  indicator pages set `eval: true` in their front matter, and any other page
  that needs to run code sets `#| eval: true` on the block

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
- **The weekly `schedule:` trigger** rebuilds and redeploys every Sunday. Now
  that pages fetch their data from the indicator repositories at render time,
  this is what picks up an upstream data update without anyone touching this
  repository.

The `origin` remote uses SSH (`git@github.com:...`) because the local `gh` auth
is configured for the SSH protocol; HTTPS pushes fail with no credentials.
