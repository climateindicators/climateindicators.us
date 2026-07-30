# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the source code for the [climateindicators.us](https://climateindicators.us/)
website — an open, reproducible collection of climate indicators for the United
States. The project began as a replication of the EPA's *Climate Change
Indicators*, preserved in the [January 19, 2025 snapshot](https://19january2025snapshot.epa.gov/climate-indicators/view-indicators/index.html).

The site is built with **Quarto** and deployed to **GitHub Pages** (the
`gh-pages` branch) via GitHub Actions.

## Common Commands

- `quarto render` — render the entire website to `_site/`
- `quarto preview` — start the local dev server (port 5679, per `_quarto.yml`)

## Architecture

### File Structure

- **_quarto.yml** — main Quarto config: website structure, navbar, sidebar, theme, render options
- **index.qmd** — home page (hero + navigation pills)
- **about.qmd** — project background, data sources, authors, license, citation
- **indicators.qmd** — grid listing of every page in `indicators/`
- **indicators/*.qmd** — one page per indicator
- **chunks/** — reusable content snippets pulled in via `{{< include >}}`; excluded from rendering by the `"!chunks/"` entry in `project: render:`
- **css/theme.scss** — custom theme layered on flatly (light) / darkly (dark)
- **images/** — static assets
- **_common.R** — shared R helper functions
- **DESCRIPTION** — R dependencies, used by the GitHub Action's `remotes::install_deps()`
- **_site/** — generated output (git-ignored)

### Styling System

- Quarto's Bootstrap 5 theme system, light/dark via `flatly`/`darkly`
- All custom styling lives in `css/theme.scss`
- **The palette is driven by a single `$accent` SCSS variable** (plus
  `$accent-dark` for pressed states). Re-theming the site means changing those
  two values, not hunting for hard-coded hex codes. Keep it that way.
- Body background is cream in light mode, navy in dark mode; the docked sidebar
  keeps its own `background: light` panel so it stays visually distinct.

### Navigation

- Navbar: Home, About, Indicators (left); GitHub (right)
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

One-time repo setup:

1. Create an empty `gh-pages` branch:
   ```sh
   git checkout --orphan gh-pages
   git rm -rf .
   git commit --allow-empty -m "Initial gh-pages commit"
   git push origin gh-pages
   git checkout main
   ```
2. In repo Settings → Pages, set the source to the `gh-pages` branch, `/ (root)`
3. Add the custom domain `climateindicators.us` (this writes a `CNAME` file to
   `gh-pages`, which the Quarto publish action preserves)
