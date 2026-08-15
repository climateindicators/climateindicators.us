# Figures for indicators/ragweed-pollen-season.qmd.

REPO <- "ragweed-pollen-season"

# ---- Figure 1: change in ragweed pollen season length by station, 1995-2015 --

# Upstream holds latitude and longitude as text so the source file's precision
# survives byte for byte, and read_indicator() only coerces `value`. It
# becomes numeric here, once.
station_points <- function(d) {
  d$latitude  <- as.numeric(d$latitude)
  d$longitude <- as.numeric(d$longitude)
  d
}

# Several of EPA's own city names carry a trailing comma or extra space baked
# into the source text itself (e.g. "Austin/Georgetown,"); see the indicator
# repository's data-raw/PROVENANCE.md. The upstream CSV keeps that verbatim on
# purpose. This page is free to clean it up for display, the way it also adds
# degree symbols to bare latitude/longitude numbers, without touching the
# underlying data or the downloadable file.
display_city <- function(city) sub(",\\s*$", "", city)

# Sorted from the largest increase down, so Kansas City (the station with the
# single biggest change) is the first thing the table shows, and the one
# station with a shorter season (Austin/Georgetown) is the last.
fig_1_table <- function(d) {
  d <- station_points(d)
  d <- d[order(d$value, decreasing = TRUE), ]
  data.frame(
    City             = display_city(d$city),
    "State/Province" = d$state_province,
    Latitude         = sprintf("%.4f°N", d$latitude),
    Longitude        = sprintf("%.4f°W", abs(d$longitude)),
    "Change (days)"  = sprintf("%+.1f", d$value),
    check.names = FALSE, stringsAsFactors = FALSE
  )
}

# CONUS-only station points (growing-degree-days' us_states()) do not cover
# this figure: two of the 11 stations are in Manitoba and Saskatchewan. `maps`
# ships no built-in Canadian province layer, so this draws country outlines
# only, not state/province boundaries.
north_america <- function() {
  sf::st_as_sf(maps::map("world", region = c("USA", "Canada"), plot = FALSE, fill = TRUE))
}

# North America Albers Equal Area Conic (ESRI:102008): unlike growing-degree-
# days' EPSG:5070, which is defined for the CONUS only and would badly distort
# the Canadian stations, this projection's own usage area explicitly covers
# both the United States and all Canadian provinces.
MAP_CRS <- "ESRI:102008"

# Not a published multi-class legend (contrast growing-degree-days' seven EPA
# classes, read from meta.yml): EPA draws exactly two categories here, fixed
# by the sign of `value` itself ("Red circles represent a longer pollen
# season; the blue circle represents a shorter season" — EPA's own figure
# caption). There is nothing to look up.
fig_1_plot <- function(d) {
  d <- station_points(d)
  d$direction_key <- ifelse(d$value > 0, "longer", "shorter")
  d$direction_label <- ifelse(
    d$direction_key == "longer", "Longer pollen season", "Shorter pollen season"
  )

  # Colour role order and legend order deliberately differ: "longer" gets the
  # `focus` slot because it is the story EPA's Key Points lead with (10 of 11
  # stations), but it is also listed first in the legend for the same reason,
  # which role order alone would not guarantee.
  role_order   <- c("shorter", "longer")
  legend_order <- c("longer", "shorter")

  ggplot(d) +
    geom_sf(
      data = north_america(), fill = CHART_GREY[["grid"]],
      colour = CHART_GREY[["rule"]], linewidth = 0.3
    ) +
    # Colour alone isn't enough: EPA's own caption says size carries magnitude
    # too ("Larger circles indicate larger changes").
    geom_point_interactive(
      aes(
        x = longitude, y = latitude, fill = direction_label,
        size = sqrt(abs(value)), data_id = seq_len(nrow(d)),
        tooltip = sprintf(
          "%s, %s\n%+.1f days, 1995 to 2015 (%s)",
          display_city(city), state_province, value, tolower(direction_label)
        )
      ),
      shape = 21, colour = CHART_GREY[["surface"]], stroke = 0.6
    ) +
    scale_fill_manual(
      values = label_colours(d, "direction_key", "direction_label", role_order),
      breaks = label_order(d, "direction_key", "direction_label", legend_order)
    ) +
    scale_size(range = c(2.4, 7), guide = "none") +
    # `default_crs` tells coord_sf() that geom_point's raw longitude/latitude
    # columns are unprojected WGS84, so both the basemap and the station
    # points get projected into MAP_CRS together.
    coord_sf(crs = MAP_CRS, default_crs = 4326, datum = NA) +
    guides(fill = guide_legend(nrow = 1, override.aes = list(size = 3.2))) +
    theme_void() +
    legend_top()
}

fig_1 <- function(d) girafe_indicator(fig_1_plot(d), height = 4.6)
