# Figures for indicators/growing-degree-days.qmd.

REPO <- "growing-degree-days"

# ---- Figure 1: change in growing degree days by station, 1948-2023 -----------

# Upstream holds latitude and longitude as text so the source file's precision
# survives byte for byte, and read_indicator() only coerces `value`, `year` and
# `date`. They become numeric here, once, for the table.
station_points <- function(d) {
  d$latitude  <- as.numeric(d$latitude)
  d$longitude <- as.numeric(d$longitude)
  d
}

# Sorted from the largest increase down, so the fifty stations EPA singles out
# as having gained 20 percent or more are the first thing the table shows.
fig_1_table <- function(d) {
  d <- station_points(d)
  d <- d[order(d$value, decreasing = TRUE), ]
  data.frame(
    Latitude           = sprintf("%.4f°N", d$latitude),
    Longitude          = sprintf("%.4f°W", abs(d$longitude)),
    "Percent change"   = sprintf("%+.2f", d$value),
    "EPA legend class" = d$change_class_label,
    check.names = FALSE, stringsAsFactors = FALSE
  )
}

# Figure 1 has no figure function: the page shows EPA's own published map image,
# vendored in the indicator repository's images/. The 280 station records behind
# it are still read, for the table above and for download.
