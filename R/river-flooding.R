# Figures for indicators/river-flooding.qmd.

REPO <- "river-flooding"

# Upstream stores latitude, longitude, and value as text so the source file's
# precision survives byte for byte. read_indicator() only coerces `value`;
# latitude and longitude become numeric here, once.
station_points <- function(d) {
  d$latitude  <- as.numeric(d$latitude)
  d$longitude <- as.numeric(d$longitude)
  d
}

# EPA reports these trend statistics to a handful of decimal places in its own
# prose (e.g. "0.325"); the full, unrounded value stays in the tooltip's
# underlying data and in the table.
fmt <- function(x) sprintf("%.3f", x)

COVERAGE <- "1965-2015"

# CONUS state polygons for the basemap. Not indicator data, but bundled
# geometry shipped with the maps package and not fetched over the network, so
# it is built here rather than threaded in from the page's setup chunk.
us_states <- function() {
  sf::st_as_sf(maps::map("state", plot = FALSE, fill = TRUE))
}

# NAD83 / Conus Albers (EPSG:5070): the standard equal-area projection for
# CONUS-wide maps, so state shapes and station spacing read correctly instead
# of the straight-line distortion of unprojected lon/lat.
MAP_CRS <- 5070

# Unlike most mapped indicators on this site, this one's reference-gauge
# network reaches well outside the Conus Albers projection's area: Alaska,
# Hawaii, and Puerto Rico all have stations. There is no station name or state
# code upstream, only coordinates, so membership is decided by a coordinate
# box rather than by a lookup column.
is_offmap <- function(d) {
  (d$latitude > 50 & d$longitude < -125) |                        # Alaska
    (d$longitude < -152 & d$longitude > -161 & d$latitude < 23) | # Hawaii
    (d$longitude > -68 & d$latitude < 20)                         # Puerto Rico
}

offmap_region <- function(d) {
  ifelse(
    d$latitude > 50 & d$longitude < -125, "Alaska",
    ifelse(d$longitude < -152 & d$longitude > -161 & d$latitude < 23, "Hawaii", "Puerto Rico")
  )
}

conus  <- function(d) d[!is_offmap(d), , drop = FALSE]
offmap <- function(d) d[is_offmap(d), , drop = FALSE]

# Direction reads through colour and shape, mirroring EPA's own up/down
# triangle symbols in Figures 1 and 2: a triangle pointing up where the trend
# increased, down where it decreased. EPA's figure additionally distinguishes
# statistically significant stations with a larger, solid symbol; that
# classification is not in the published data file (see data/meta.yml's note
# on both datasets), so it cannot be reproduced here. Magnitude instead reads
# through size, scaled within each figure so it uses its full size range; the
# real value is in the tooltip and in the table, both unrounded upstream.
direction_colours <- function() {
  stats::setNames(
    c(INDICATOR_PALETTE[["focus"]], INDICATOR_PALETTE[["base"]]),
    c("increase", "decrease")
  )
}
DIRECTION_SHAPES <- c(increase = 24L, decrease = 25L) # filled triangle up / down
DIRECTION_LABELS <- c(increase = "Increase", decrease = "Decrease")

prep <- function(d) {
  d <- station_points(d)
  d$direction <- factor(ifelse(d$value >= 0, "increase", "decrease"),
                        levels = c("increase", "decrease"))
  m <- max(abs(d$value))
  d$rel_mag <- if (m == 0) rep(0, nrow(d)) else abs(d$value) / m
  d
}

station_tooltip <- function(d, unit_label) {
  sprintf(
    "%.4f°N, %.4f°W\n%s, %s\n%s %s",
    d$latitude, abs(d$longitude),
    ifelse(d$value >= 0, "Increase", "Decrease"), COVERAGE,
    fmt(d$value), unit_label
  )
}

station_map_plot <- function(d, unit_label) {
  d <- conus(prep(d))

  ggplot(d) +
    geom_sf(
      data = us_states(), fill = CHART_GREY[["grid"]],
      colour = CHART_GREY[["rule"]], linewidth = 0.3
    ) +
    geom_point_interactive(
      aes(
        x = longitude, y = latitude, fill = direction, shape = direction,
        size = sqrt(rel_mag),
        data_id = paste(round(longitude, 4), round(latitude, 4), sep = "/"),
        tooltip = station_tooltip(d, unit_label)
      ),
      colour = CHART_GREY[["surface"]], stroke = 0.4, alpha = 0.9
    ) +
    scale_fill_manual(values = direction_colours(), labels = DIRECTION_LABELS) +
    scale_shape_manual(values = DIRECTION_SHAPES, labels = DIRECTION_LABELS) +
    scale_size(range = c(1.0, 4.6), guide = "none") +
    # default_crs tells coord_sf() that geom_point's raw longitude/latitude
    # columns are unprojected WGS84, so both the sf basemap and the station
    # points get projected into MAP_CRS together.
    coord_sf(crs = MAP_CRS, default_crs = 4326, datum = NA) +
    guides(
      fill  = guide_legend(nrow = 1, override.aes = list(size = 3.0, alpha = 1)),
      shape = guide_legend(nrow = 1)
    ) +
    theme_void() +
    legend_top()
}

# The stations the Albers panel cannot hold, plotted by trend value along one
# axis and grouped by region along the other, on the same colour, shape, and
# size scale as the map above. Not a second map: at this size an Alaska,
# Hawaii, or Puerto Rico coastline would be a few unreadable pixels, and the
# point of this strip is that these stations are in the indicator and where
# their trend falls, not their precise geography.
station_offmap_plot <- function(d, unit_label) {
  d <- offmap(prep(d))
  d$region <- factor(offmap_region(d), levels = c("Alaska", "Hawaii", "Puerto Rico"))

  ggplot(d, aes(x = value, y = region)) +
    geom_vline(xintercept = 0, colour = CHART_GREY[["rule"]], linewidth = 0.4) +
    geom_point_interactive(
      aes(
        fill = direction, shape = direction, size = sqrt(rel_mag),
        data_id = paste(round(longitude, 4), round(latitude, 4), sep = "/"),
        tooltip = station_tooltip(d, unit_label)
      ),
      colour = CHART_GREY[["surface"]], stroke = 0.4, alpha = 0.9,
      position = position_jitter(height = 0.15, width = 0, seed = 1)
    ) +
    scale_fill_manual(values = direction_colours(), guide = "none") +
    scale_shape_manual(values = DIRECTION_SHAPES, guide = "none") +
    scale_size(range = c(1.0, 4.6), guide = "none") +
    labs(x = unit_label, y = NULL) +
    theme_indicator() +
    theme(panel.grid.major.y = element_line(colour = CHART_GREY[["grid"]], linewidth = 0.4))
}

# Sorted by value ascending, which is also the order EPA's own source file
# uses.
station_map_table <- function(d, unit_label) {
  d <- station_points(d)
  d <- d[order(d$value), ]
  data.frame(
    Latitude  = sprintf("%.5f°N", d$latitude),
    Longitude = sprintf("%.5f°W", abs(d$longitude)),
    Value     = fmt(d$value),
    Unit      = unit_label,
    check.names = FALSE, stringsAsFactors = FALSE
  )
}

# ---- Figure 1: magnitude trend (Mann-Kendall tau per station) ---------------

fig_1_plot        <- function(d) station_map_plot(d, "tau value")
fig_1              <- function(d) girafe_indicator(fig_1_plot(d), height = 5.0)
fig_1_offmap_plot  <- function(d) station_offmap_plot(d, "tau value")
fig_1_offmap       <- function(d) girafe_indicator(fig_1_offmap_plot(d), height = 2.1)
fig_1_table        <- function(d) station_map_table(d, "tau value")

# ---- Figure 2: frequency trend (Poisson regression slope per station) -------

fig_2_plot        <- function(d) station_map_plot(d, "slope value")
fig_2              <- function(d) girafe_indicator(fig_2_plot(d), height = 5.0)
fig_2_offmap_plot  <- function(d) station_offmap_plot(d, "slope value")
fig_2_offmap       <- function(d) girafe_indicator(fig_2_offmap_plot(d), height = 2.1)
fig_2_table        <- function(d) station_map_table(d, "slope value")
