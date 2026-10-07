# Figures for indicators/sea-surface-temperature.qmd.

REPO <- "sea-surface-temperature"

# Figure 1's values are anomalies against EPA's 1971-2000 baseline, so zero is a
# real reference line, not just a spot on the axis.
BASELINE <- 0

# ---- Figure 1: average global sea surface temperature, 1880-2023 -------------

# The shaded band is the 95% confidence interval; the line is the annual
# anomaly. Upstream stores them as three `series` values.
fig_1_plot <- function(d) {
  w <- tidyr::pivot_wider(d, id_cols = year, names_from = series, values_from = value)
  col <- INDICATOR_PALETTE[["base"]]

  ggplot(w, aes(x = year)) +
    geom_hline(yintercept = BASELINE, colour = CHART_GREY[["rule"]], linewidth = 0.4) +
    geom_ribbon(aes(ymin = lower_95, ymax = upper_95), fill = col, alpha = 0.25) +
    geom_line(aes(y = anomaly), colour = col, linewidth = 0.7) +
    geom_point_interactive(
      aes(
        y = anomaly, data_id = year,
        tooltip = sprintf("%d\nAnomaly: %+.2f°F\n95%% interval: %+.2f to %+.2f°F",
                          year, anomaly, lower_95, upper_95)
      ),
      colour = col, size = 0.9
    ) +
    scale_x_continuous(breaks = seq(1880, 2020, 20)) +
    labs(x = NULL, y = "Temperature anomaly (°F, vs. 1971-2000 average)") +
    theme_indicator()
}

fig_1 <- function(d) girafe_indicator(fig_1_plot(d))

fig_1_table <- function(d) {
  w <- tidyr::pivot_wider(d, id_cols = year, names_from = series, values_from = value)
  data.frame(
    Year                  = w$year,
    `Anomaly (°F)`        = w$anomaly,
    `Lower 95% bound (°F)` = w$lower_95,
    `Upper 95% bound (°F)` = w$upper_95,
    check.names = FALSE
  )
}

# ---- Figure 2: change in sea surface temperature, 1901-2022 ------------------

# Land polygons for the basemap. Not indicator data, but bundled geometry
# shipped with the maps package and not fetched over the network, so it is
# built here rather than threaded in from the page's setup chunk.
world_land <- function() ggplot2::map_data("world")

fmt_lat <- function(x) sprintf("%.1f°%s", abs(x), ifelse(x < 0, "S", "N"))
fmt_lon <- function(x) sprintf("%.1f°%s", abs(x), ifelse(x < 0, "W", "E"))

# Grid cells EPA leaves white (too little data for a trend) are simply absent
# upstream, so the ocean background shows through them the same way. Land is
# drawn over the cells, as on EPA's map, so coastal cells read as ocean only.
# The colour midpoint is pinned at zero rather than centred on the range: most
# cells warmed, and the few that cooled should still read as cooling.
fig_2_plot <- function(d) {
  d$lat <- as.numeric(d$lat)
  d$lon <- as.numeric(d$lon)

  ggplot() +
    geom_tile_interactive(
      data = d,
      aes(
        x = lon, y = lat, fill = value, data_id = paste(lat, lon),
        tooltip = sprintf("%s, %s\n%+.2f°F", fmt_lat(lat), fmt_lon(lon), value)
      ),
      width = 5, height = 5
    ) +
    geom_polygon(
      data = world_land(), aes(x = long, y = lat, group = group),
      fill = CHART_GREY[["grid"]], colour = CHART_GREY[["rule"]], linewidth = 0.1
    ) +
    scale_fill_gradient2(
      low = INDICATOR_PALETTE[["base"]], mid = CHART_GREY[["surface"]],
      high = INDICATOR_PALETTE[["focus"]], midpoint = 0,
      labels = function(x) sprintf("%+g°F", x),
      guide = guide_colourbar(barwidth = unit(10, "lines"), barheight = unit(0.5, "lines"))
    ) +
    coord_fixed(xlim = c(-180, 180), ylim = c(-90, 90), expand = FALSE) +
    labs(fill = "Change in temperature, 1901-2022") +
    theme_void() +
    theme(
      legend.position = "top",
      legend.title    = element_text(size = rel(0.8), colour = CHART_GREY[["text"]]),
      legend.text     = element_text(size = rel(0.7), colour = CHART_GREY[["text"]]),
      panel.border    = element_rect(fill = NA, colour = CHART_GREY[["rule"]], linewidth = 0.3)
    )
}

fig_2 <- function(d) girafe_indicator(fig_2_plot(d), height = 4.6)

# North to south, then west to east, the order a reader scans the map.
fig_2_table <- function(d) {
  d$lat <- as.numeric(d$lat)
  d$lon <- as.numeric(d$lon)
  d <- d[order(-d$lat, d$lon), ]
  data.frame(
    Latitude      = fmt_lat(d$lat),
    Longitude     = fmt_lon(d$lon),
    `Change (°F)` = sprintf("%+.2f", d$value),
    check.names = FALSE
  )
}
