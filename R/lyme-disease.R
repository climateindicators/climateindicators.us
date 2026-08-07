# Data access and figures for indicators/lyme-disease.qmd.
#
# HARD RULE (matches _common.R's scope for the site generally): this file
# reads data/lyme-disease/ and nothing else. It never opens
# data-raw/lyme-disease/ and never reaches the network.
#
# Canonical source: the git submodule at indicators-src/lyme-disease
# (github.com/climateindicators/lyme-disease). That repo holds EPA's published
# per-figure CSVs, the extraction pipeline (R/build_data.R), the page generator
# (R/gen_page.R, which reads the archived docx), and the chart code
# (R/figures.R + _common.R) referenced below. Following the
# cold-related-deaths / heat-related-workplace-deaths pattern rather than
# heat-related-deaths' copy-and-rename one: _common.R and R/figures.R are
# source()'d verbatim from the submodule into an isolated environment
# (LYME_ENV), so this file carries zero duplicated plotting logic. Resyncing
# after an upstream chart change is `git submodule update --remote` plus
# re-copying the data, with no R code here to touch.
#
# Two things are overridden after sourcing, both because the submodule's own
# files resolve paths via here::here(), which inside this multi-indicator
# project means "the hub's root", not the submodule's:
#   1. read_indicator()/read_meta(), so data resolves to data/lyme-disease/
#      rather than the hub's top-level data/.
#   2. source() during the load itself -- R/figures.R sources its sibling
#      R/utils/pick_chart.R by here::here() path (fig_1_plot() asserts the
#      chart selector's verdict before drawing), which would look for a
#      pick_chart.R at the hub root that does not (and should not) exist.
#      See the shim below. Same case as heat-related-workplace-deaths;
#      cold-related-deaths did not need it, its figures.R has no source() call.
#
# Sourcing into an isolated environment rather than the global one means this
# indicator's unprefixed names (fig_1, read_indicator, ...) can never collide
# with another indicator's, regardless of how Quarto schedules R sessions
# across pages.
#
# TO RESYNC after that repo's data or charts change:
#   git submodule update --remote indicators-src/lyme-disease
#   (then re-copy data/*.csv, meta.yml, and the source CSVs below)

suppressPackageStartupMessages({
  library(ggplot2)
  library(ggiraph)
})

LYME_SRC_DIR  <- here::here("indicators-src", "lyme-disease")
LYME_DATA_DIR <- here::here("data", "lyme-disease")

LYME_ENV <- new.env(parent = globalenv())

# Load-time shim, defined before the sourcing below so that a source() call
# inside a submodule file resolves to this one rather than base::source().
# It re-roots any path that the submodule expressed relative to a project
# root back into the submodule, then loads it into the same isolated
# environment. Removed again once loading is done, so nothing at render time
# sees a redefined source().
LYME_ENV$source <- function(file, ...) {
  root <- paste0(here::here(), "/")
  rel  <- sub(root, "", gsub("\\\\", "/", file), fixed = TRUE)
  base::source(file.path(LYME_SRC_DIR, rel), local = LYME_ENV)
}

source(file.path(LYME_SRC_DIR, "_common.R"), local = LYME_ENV)
source(file.path(LYME_SRC_DIR, "R", "figures.R"), local = LYME_ENV)

rm("source", envir = LYME_ENV)

# Overrides, applied after sourcing so they win: figures.R's fig_1_plot() and
# fig_1_table() call read_indicator() unqualified, which R resolves inside
# LYME_ENV (the environment those functions were defined in) at call time, not
# at source time -- so redefining it here is enough, no submodule file edit
# needed.
LYME_ENV$read_indicator <- function(file) {
  d <- readr::read_csv(
    file.path(LYME_DATA_DIR, file),
    col_types = readr::cols(.default = readr::col_character()),
    na = character(), progress = FALSE
  )
  d$value <- suppressWarnings(as.numeric(d$value))
  if ("year" %in% names(d)) d$year <- as.integer(d$year)
  if ("date" %in% names(d)) d$date <- as.Date(d$date)
  d
}
LYME_ENV$read_meta <- function() yaml::read_yaml(file.path(LYME_DATA_DIR, "meta.yml"))

# Thin wrappers, ld_-prefixed to match this site's indicator-page convention
# (hrd_ for heat-related-deaths, crd_ for cold-related-deaths, hrwd_ for
# heat-related-workplace-deaths): the qmd page calls these, not LYME_ENV
# directly, so the submodule's own unprefixed names never leak into the page's
# own R chunks.
ld_meta        <- function() LYME_ENV$read_meta()
ld_meta_for    <- function(file, meta = ld_meta()) LYME_ENV$meta_for(file, meta)
ld_fig_1       <- function() LYME_ENV$fig_1()
ld_fig_1_plot  <- function() LYME_ENV$fig_1_plot()
ld_fig_1_table <- function() LYME_ENV$fig_1_table()
ld_fig_2       <- function() LYME_ENV$fig_2()
ld_fig_2_plot  <- function() LYME_ENV$fig_2_plot()
ld_fig_2_table <- function() LYME_ENV$fig_2_table()

# Figure 3 (the 1996-vs-2022 dot maps) gets no wrapper: EPA published the
# images and no data at all, so there is nothing upstream to chart and nothing
# to download but the image itself. It is the only figure on this page that
# falls back to a static image, and the only kind of figure that should.
#
# Note Figure 2 IS charted even though EPA draws it as a choropleth -- see the
# submodule's R/figures.R header for why a ranked bar chart of all 51
# jurisdictions carries more than EPA's map does. EPA's map is still linked
# from the page as a PNG download.
#
# If Figure 3 ever gets a chart it gets written upstream and picked up by a
# resync; chart code must not appear in this file.
