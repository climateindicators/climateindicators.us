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

# CONUS state polygons for the Figure 1 basemap. Not indicator data — bundled
# geometry shipped with the maps package, not fetched over the network — so it
# is built here rather than threaded in from the page's setup chunk.
us_states <- function() {
  sf::st_as_sf(maps::map("state", plot = FALSE, fill = TRUE))
}

# NAD83 / Conus Albers (EPSG:5070): the standard equal-area projection for
# CONUS-wide maps (USGS, Census), so state shapes and station spacing read
# correctly instead of the straight-line distortion of unprojected lon/lat.
MAP_CRS <- 5070

# EPA's legend classes, in EPA's own legend order, read from the upstream
# meta.yml rather than retyped here. That order is what fixes the colour ramp
# below, and the `<-20` class is empty in this vintage: EPA draws it in the
# legend regardless, so taking the class list from the data instead would
# silently drop it.
fig_1_classes <- function(meta) {
  s <- meta_for(meta, "growing_degree_days_change_by_station.csv")$series
  stats::setNames(
    vapply(s, function(x) x$label, character(1)),
    vapply(s, function(x) x$key, character(1))
  )
}

# The seven classes are one ordered scale, not seven independent series, so
# they are not a case for series_colours(): that assigns categorical roles,
# and there are seven classes against six palette slots anyway. They ramp
# instead, from the palette's blue through a neutral grey to its orange, so
# the direction of a station's change reads before its label does. Both ends
# and the midpoint come from common.R, so no colour is defined here.
#
# An odd number of classes is what puts the ramp's midpoint on the class that
# straddles zero rather than between two classes. EPA's legend has seven; if a
# future vintage has an even number, the neutral grey would land on a class
# that is entirely positive or entirely negative and quietly mislead.
fig_1_colours <- function(keys) {
  stopifnot(
    "figure 1: EPA's legend no longer has an odd number of classes" =
      length(keys) %% 2L == 1L
  )
  stats::setNames(
    grDevices::colorRampPalette(c(
      INDICATOR_PALETTE[["base"]],
      CHART_GREY[["rule"]],
      INDICATOR_PALETTE[["focus"]]
    ))(length(keys)),
    keys
  )
}

fig_1_plot <- function(d, meta) {
  d <- station_points(d)
  labels <- fig_1_classes(meta)
  stopifnot(
    "figure 1: meta.yml does not describe every legend class in the data" =
      all(d$change_class_key %in% names(labels))
  )

  d$change_class <- factor(
    d$change_class_key,
    levels = names(labels), labels = unname(labels)
  )

  # `drop = FALSE` keeps an empty class's label in the legend but not its
  # swatch: ggplot draws key glyphs from layer data, and a class no station
  # falls into contributes none, leaving a labelled blank. One fully
  # transparent row per empty class gives the key something to draw, and
  # override.aes below puts the colour back in the legend without putting a
  # point on the map.
  phantom <- data.frame(
    longitude    = d$longitude[1],
    latitude     = d$latitude[1],
    value        = d$value[1],
    change_class = factor(
      setdiff(levels(d$change_class), as.character(d$change_class)),
      levels = levels(d$change_class)
    )
  )

  ggplot(d) +
    geom_sf(
      data = us_states(), fill = CHART_GREY[["grid"]],
      colour = CHART_GREY[["rule"]], linewidth = 0.3
    ) +
    # Colour alone isn't enough here: unlike the abandoned longitude-scatter
    # trial, the map's x/y are geographic position, so magnitude has to read
    # through size too, matching EPA's own caption ("color and size of the
    # symbols represent percent change").
    geom_point_interactive(
      aes(
        x = longitude, y = latitude, fill = change_class,
        size = sqrt(abs(value)), data_id = seq_len(nrow(d)),
        tooltip = sprintf(
          "%.4f°N, %.4f°W\n%+.1f%% change, 1948 to 2023\nEPA legend class: %s",
          latitude, abs(longitude), value, as.character(change_class)
        )
      ),
      shape = 21, colour = CHART_GREY[["surface"]], stroke = 0.6
    ) +
    geom_point(
      data = phantom, aes(x = longitude, y = latitude, fill = change_class),
      shape = 21, colour = CHART_GREY[["surface"]], size = 2.4, stroke = 0.6,
      alpha = 0, show.legend = TRUE
    ) +
    scale_fill_manual(
      values = stats::setNames(unname(fig_1_colours(names(labels))), unname(labels)),
      drop   = FALSE
    ) +
    scale_size(range = c(1.3, 6), guide = "none") +
    # `default_crs` tells coord_sf() that geom_point's raw longitude/latitude
    # columns are unprojected WGS84, so both the sf basemap and the station
    # points get projected into MAP_CRS together.
    coord_sf(crs = MAP_CRS, default_crs = 4326, datum = NA) +
    guides(fill = guide_legend(nrow = 1, override.aes = list(alpha = 1, size = 3.2))) +
    theme_void() +
    legend_top()
}

fig_1 <- function(d, meta) girafe_indicator(fig_1_plot(d, meta), height = 4.6)
