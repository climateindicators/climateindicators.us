# Helpers shared by every page. Each indicator .qmd sources this first, then
# its own R/<slug>.R.

suppressPackageStartupMessages({
  library(ggplot2)
  library(ggiraph)
})

# ---- Reading data from the indicator repositories ----------------------------

INDICATOR_ORG <- "climateindicators"

#' Build a raw.githubusercontent.com URL for a file in an indicator repository.
indicator_url <- function(repo, path) {
  sprintf(
    "https://raw.githubusercontent.com/%s/%s/main/%s",
    INDICATOR_ORG, repo, path
  )
}

#' Build a github.com URL for a file in an indicator repository, for links a
#' reader clicks (the raw host serves binaries as octet-stream).
indicator_file_url <- function(repo, path) {
  sprintf(
    "https://github.com/%s/%s/blob/main/%s",
    INDICATOR_ORG, repo, utils::URLencode(path)
  )
}

# One fetch per URL per render. read_indicator() is called once for a figure
# and again for the table under it, and every page reads meta.yml several times
# for its captions. A plain named list in the global environment, keyed by URL.
.indicator_cache <- list()

.fetch <- function(url, read) {
  if (!is.null(.indicator_cache[[url]])) return(.indicator_cache[[url]])
  value <- read(url)
  .indicator_cache[[url]] <<- value
  value
}

#' Read one of an indicator repository's generated datasets.
#'
#' Values are stored as text upstream so the source file's precision survives
#' byte for byte. This is where they become numeric, once, for plotting. Rows
#' carrying a suppression flag get NA, which is what makes a chart draw a gap
#' instead of a zero.
read_indicator <- function(repo, file) {
  .fetch(indicator_url(repo, file.path("data", file)), function(url) {
    d <- readr::read_csv(
      url,
      col_types = readr::cols(.default = readr::col_character()),
      na = character(), progress = FALSE
    )
    d$value <- suppressWarnings(as.numeric(d$value))
    if ("year" %in% names(d)) d$year <- as.integer(d$year)
    if ("date" %in% names(d)) d$date <- as.Date(d$date)
    d
  })
}

#' Read an indicator repository's data dictionary.
read_meta <- function(repo) {
  .fetch(indicator_url(repo, "data/meta.yml"), yaml::read_yaml)
}

#' Pull one dataset's entry out of meta.yml by filename.
meta_for <- function(repo, file) {
  hit <- Filter(function(d) identical(d$file, file), read_meta(repo)$datasets)
  if (length(hit) != 1L) stop("No meta.yml entry for ", file, call. = FALSE)
  hit[[1]]
}

#' The bold title and source line printed above a figure, from meta.yml.
figure_caption <- function(repo, file) {
  m <- meta_for(repo, file)
  knitr::asis_output(sprintf(
    "**%s**\n\nData source: %s <br> Web update: %s\n",
    m$figure_title, m$data_source, m$web_update
  ))
}

#' The link to an indicator's technical documentation PDF, from meta.yml.
technical_documentation_link <- function(repo) {
  knitr::asis_output(sprintf(
    "- [Download related technical information (PDF)](%s)\n",
    read_meta(repo)$indicator$technical_documentation
  ))
}

# ---- Chart styling -----------------------------------------------------------

# Font family is left as the theme default: SVG text metrics are resolved at
# build time, so pinning a family that is not installed everywhere makes the
# same chart render differently on a different machine.
theme_indicator <- function(base_size = 13) {
  theme_minimal(base_size = base_size) %+replace%
    theme(
      panel.grid.minor   = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_line(colour = "#dcdcd7", linewidth = 0.4),
      axis.title         = element_text(colour = "#464646", size = rel(0.9)),
      axis.text          = element_text(colour = "#464646"),
      axis.line.x        = element_line(colour = "#464646", linewidth = 0.4),
      plot.title         = element_blank(),   # the caption block carries the title
      plot.margin        = margin(4, 4, 4, 4),
      strip.text         = element_text(colour = "#1e1e1e", face = "bold",
                                        hjust = 0, size = rel(0.95)),
      legend.position    = "none"             # each figure sets its own legend
    )
}

# The categorical palette, in slot order: blue, orange, aqua, magenta.
INDICATOR_PALETTE <- c("#2a78d6", "#eb6834", "#1baf7a", "#d14fa8")

#' Assign a page's series keys to palette slots, in order.
#'
#' Errors on more keys than slots rather than recycling: an unmapped series
#' would otherwise draw in ggplot's missing-value grey with no warning.
palette_for <- function(keys) {
  if (length(keys) > length(INDICATOR_PALETTE)) {
    stop(
      "INDICATOR_PALETTE has ", length(INDICATOR_PALETTE), " slots but ",
      length(keys), " series keys were given.",
      call. = FALSE
    )
  }
  stats::setNames(INDICATOR_PALETTE[seq_along(keys)], keys)
}

#' Map a data frame's label column to a page's INDICATOR_COLOURS, and to a
#' legend order, both driven by an explicit key order rather than alphabetising
#' the label text (ggplot's default for a character aesthetic).
label_colours <- function(d, key_col, label_col, order, colours = INDICATOR_COLOURS) {
  missing <- setdiff(order, names(colours))
  if (length(missing)) {
    stop(
      "No INDICATOR_COLOURS entry for series key(s): ",
      paste(sQuote(missing), collapse = ", "),
      call. = FALSE
    )
  }
  lab <- d[[label_col]][match(order, d[[key_col]])]
  stats::setNames(unname(colours[order]), lab)
}

label_order <- function(d, key_col, label_col, order) {
  d[[label_col]][match(order, d[[key_col]])]
}

legend_top <- function() {
  theme(
    legend.position      = "top",
    legend.title         = element_blank(),
    legend.justification = "left",
    legend.margin        = margin(0, 0, 6, 0),
    legend.text          = element_text(size = rel(0.85)),
    legend.key.width     = unit(1.4, "lines")
  )
}

# ---- Interactive output ------------------------------------------------------

GIRAFE_OPTS <- list(
  opts_hover(css = "stroke-width:3.5;"),
  opts_hover_inv(css = "opacity:0.3;"),
  opts_tooltip(css = paste(
    "background:#1e1e1e;color:#fff;padding:6px 10px;border-radius:4px;",
    "font-family:sans-serif;font-size:12px;max-width:320px;"
  )),
  opts_toolbar(saveaspng = FALSE),
  opts_sizing(rescale = TRUE, width = 1)
)

#' Wrap a ggplot as a girafe htmlwidget: build-time SVG, hover tooltips, no CDN
#' dependency.
girafe_indicator <- function(p, height = 4.2) {
  ggiraph::girafe(
    ggobj = p, width_svg = 8, height_svg = height,
    options = GIRAFE_OPTS
  )
}

# ---- Misc --------------------------------------------------------------------

print_chunk <- function(url) {
  cat(readLines(url), sep = '\n')
}
