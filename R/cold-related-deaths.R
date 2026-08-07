# Data access and figures for indicators/cold-related-deaths.qmd.
#
# HARD RULE (matches _common.R's scope for the site generally): this file
# reads data/cold-related-deaths/ and nothing else. It never opens
# data-raw/cold-related-deaths/ and never reaches the network.
#
# Canonical source: the git submodule at indicators-src/cold-related-deaths
# (github.com/climateindicators/cold-related-deaths). That repo holds the raw
# source workbook, the extraction pipeline (R/build_data.R), the docx
# narrative extraction (R/gen_narrative.R), and the chart code
# (R/figures.R + _common.R) referenced below. Unlike heat-related-deaths'
# integration, that chart code is NOT copied or renamed here: _common.R and
# R/figures.R are source()'d verbatim from the submodule into an isolated
# environment (CRD_ENV), so this file carries zero duplicated plotting logic.
# The only thing overridden is where the data lives, because both files
# resolve their CSVs via here::here("data", file), which inside this
# multi-indicator project means "this repo's top-level data/", not the
# submodule's own data/. read_indicator() and read_meta() are redefined
# inside CRD_ENV, after sourcing, to point at data/cold-related-deaths/
# instead; every other function (fig_1(), fig_td1(), theme_indicator(),
# INDICATOR_COLOURS, ...) is exactly the submodule's own code.
#
# Sourcing into an isolated environment rather than the global one (as
# heat-related-deaths.R's hrd_-prefixed copy effectively does by renaming)
# means this indicator's unprefixed names (fig_1, read_indicator, ...) can
# never collide with another indicator's, regardless of how Quarto schedules
# R sessions across pages.
#
# TO RESYNC after that repo's data or charts change:
#   git submodule update --remote indicators-src/cold-related-deaths
#   (then re-copy data/*.csv, meta.yml, and the source workbook below)

suppressPackageStartupMessages({
  library(ggplot2)
  library(ggiraph)
})

CRD_SRC_DIR  <- here::here("indicators-src", "cold-related-deaths")
CRD_DATA_DIR <- here::here("data", "cold-related-deaths")

CRD_ENV <- new.env(parent = globalenv())
source(file.path(CRD_SRC_DIR, "_common.R"), local = CRD_ENV)
source(file.path(CRD_SRC_DIR, "R", "figures.R"), local = CRD_ENV)

# Overrides, applied after sourcing so they win: figures.R's fig_1_plot() and
# fig_td1_plot() call read_indicator() unqualified, which R resolves inside
# CRD_ENV (the environment those functions were defined in) at call time, not
# at source time -- so redefining it here is enough, no submodule file edit
# needed.
CRD_ENV$read_indicator <- function(file) {
  d <- readr::read_csv(
    file.path(CRD_DATA_DIR, file),
    col_types = readr::cols(.default = readr::col_character()),
    na = character(), progress = FALSE
  )
  d$value <- suppressWarnings(as.numeric(d$value))
  if ("year" %in% names(d)) d$year <- as.integer(d$year)
  if ("date" %in% names(d)) d$date <- as.Date(d$date)
  d
}
CRD_ENV$read_meta <- function() yaml::read_yaml(file.path(CRD_DATA_DIR, "meta.yml"))

# Thin wrappers, crd_-prefixed to match this site's indicator-page convention
# (hrd_ for heat-related-deaths): the qmd page calls these, not CRD_ENV
# directly, so the submodule's own unprefixed names never leak into the
# page's own R chunks.
crd_meta         <- function() CRD_ENV$read_meta()
crd_meta_for     <- function(file, meta = crd_meta()) CRD_ENV$meta_for(file, meta)
crd_fig_1        <- function() CRD_ENV$fig_1()
crd_fig_1_table  <- function() CRD_ENV$fig_1_table()
crd_fig_td1      <- function() CRD_ENV$fig_td1()
crd_fig_td1_table <- function() CRD_ENV$fig_td1_table()
