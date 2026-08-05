# Data access and figures for indicators/heat-related-workplace-deaths.qmd.
#
# HARD RULE (matches _common.R's scope for the site generally): this file
# reads data/heat-related-workplace-deaths/ and nothing else. It never opens
# data-raw/heat-related-workplace-deaths/ and never reaches the network.
#
# Canonical source: the git submodule at
# indicators-src/heat-related-workplace-deaths
# (github.com/climateindicators/heat-related-workplace-deaths). That repo holds
# the raw BLS workbooks, the extraction pipeline (R/build_data.R), the docx
# narrative extraction, and the chart code (R/figures.R + _common.R)
# referenced below. Following the cold-related-deaths pattern rather than
# heat-related-deaths' copy-and-rename one: _common.R and R/figures.R are
# source()'d verbatim from the submodule into an isolated environment
# (HRWD_ENV), so this file carries zero duplicated plotting logic. Resyncing
# after an upstream chart change is `git submodule update --remote` plus
# re-copying the data, with no R code here to touch.
#
# Two things are overridden after sourcing, both because the submodule's own
# files resolve paths via here::here(), which inside this multi-indicator
# project means "the hub's root", not the submodule's:
#   1. read_indicator()/read_meta(), so data resolves to
#      data/heat-related-workplace-deaths/ rather than the hub's top-level
#      data/.
#   2. source() during the load itself -- R/figures.R sources its sibling
#      R/utils/pick_chart.R by here::here() path, which would look for a
#      pick_chart.R at the hub root that does not (and should not) exist.
#      See the shim below. cold-related-deaths did not need this; its
#      figures.R has no source() call of its own.
#
# Sourcing into an isolated environment rather than the global one means this
# indicator's unprefixed names (fig_1, read_indicator, ...) can never collide
# with another indicator's, regardless of how Quarto schedules R sessions
# across pages.
#
# TO RESYNC after that repo's data or charts change:
#   git submodule update --remote indicators-src/heat-related-workplace-deaths
#   (then re-copy data/*.csv, meta.yml, and the source workbooks below)

suppressPackageStartupMessages({
  library(ggplot2)
  library(ggiraph)
})

HRWD_SRC_DIR  <- here::here("indicators-src", "heat-related-workplace-deaths")
HRWD_DATA_DIR <- here::here("data", "heat-related-workplace-deaths")

HRWD_ENV <- new.env(parent = globalenv())

# Load-time shim, defined before the sourcing below so that a source() call
# inside a submodule file resolves to this one rather than base::source().
# It re-roots any path that the submodule expressed relative to a project
# root back into the submodule, then loads it into the same isolated
# environment. Removed again once loading is done, so nothing at render time
# sees a redefined source().
HRWD_ENV$source <- function(file, ...) {
  root <- paste0(here::here(), "/")
  rel  <- sub(root, "", gsub("\\\\", "/", file), fixed = TRUE)
  base::source(file.path(HRWD_SRC_DIR, rel), local = HRWD_ENV)
}

source(file.path(HRWD_SRC_DIR, "_common.R"), local = HRWD_ENV)
source(file.path(HRWD_SRC_DIR, "R", "figures.R"), local = HRWD_ENV)

rm("source", envir = HRWD_ENV)

# Overrides, applied after sourcing so they win: figures.R's fig_1_plot() and
# fig_1_table() call read_indicator() unqualified, which R resolves inside
# HRWD_ENV (the environment those functions were defined in) at call time, not
# at source time -- so redefining it here is enough, no submodule file edit
# needed.
HRWD_ENV$read_indicator <- function(file) {
  d <- readr::read_csv(
    file.path(HRWD_DATA_DIR, file),
    col_types = readr::cols(.default = readr::col_character()),
    na = character(), progress = FALSE
  )
  d$value <- suppressWarnings(as.numeric(d$value))
  if ("year" %in% names(d)) d$year <- as.integer(d$year)
  if ("date" %in% names(d)) d$date <- as.Date(d$date)
  d
}
HRWD_ENV$read_meta <- function() yaml::read_yaml(file.path(HRWD_DATA_DIR, "meta.yml"))

# Thin wrappers, hrwd_-prefixed to match this site's indicator-page convention
# (hrd_ for heat-related-deaths, crd_ for cold-related-deaths): the qmd page
# calls these, not HRWD_ENV directly, so the submodule's own unprefixed names
# never leak into the page's own R chunks.
hrwd_meta        <- function() HRWD_ENV$read_meta()
hrwd_meta_for    <- function(file, meta = hrwd_meta()) HRWD_ENV$meta_for(file, meta)
hrwd_fig_1       <- function() HRWD_ENV$fig_1()
hrwd_fig_1_plot  <- function() HRWD_ENV$fig_1_plot()
hrwd_fig_1_table <- function() HRWD_ENV$fig_1_table()

# Example 1 (the county-level outdoor-workers map) deliberately gets no
# wrapper. Upstream it is EPA's own published map image, not a chart function,
# and its county-level CSV is a download rather than a rendered table -- 3,274
# rows, one per county, and no `value` column for read_indicator() to coerce.
# Adding a chart or a table for it here would mean figure code living outside
# the submodule, which is exactly what this integration pattern avoids.
