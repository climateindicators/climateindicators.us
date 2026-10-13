# Figures for indicators/sea-level.qmd.

REPO <- "sea-level"

# Bottom to top, so the largest rise sits at the top of the chart; ties broken
# by name so the order is stable across renders.
station_levels <- function(d) {
  d$label[order(d$value, d$label)]
}

with_label <- function(d) {
  d$label <- paste0(d$station, ", ", d$state)
  d
}

# ---- Figure 2: relative sea level change at 72 tide gauges, 1960-2023 --------

FIG2_KEYS <- c("Fell", "Rose")

# One row per station rather than EPA's map: the stations run from Kwajalein to
# Bermuda, and the Mid-Atlantic gauges would overlap on a map at this size.
fig_2_plot <- function(d) {
  d <- with_label(d)
  d$label     <- factor(d$label, levels = station_levels(d))
  d$direction <- factor(ifelse(d$value < 0, "Fell", "Rose"), levels = FIG2_KEYS)

  ggplot(d, aes(y = label)) +
    geom_vline(xintercept = 0, colour = CHART_GREY[["rule"]], linewidth = 0.5) +
    geom_segment(
      aes(x = 0, xend = value, yend = label, colour = direction),
      linewidth = 0.6
    ) +
    geom_point_interactive(
      aes(
        x = value, colour = direction, data_id = label,
        tooltip = sprintf("%s\n%+.2f inches, 1960–2023", label, value)
      ),
      size = 2.2
    ) +
    scale_colour_manual(
      values = series_colours(FIG2_KEYS),
      labels = c(Fell = "Sea level fell relative to land",
                 Rose = "Sea level rose relative to land")
    ) +
    labs(x = "Relative sea level change, 1960–2023 (inches)", y = NULL) +
    theme_indicator() +
    theme(
      panel.grid.major.x = element_line(colour = CHART_GREY[["grid"]], linewidth = 0.4),
      panel.grid.major.y = element_blank(),
      axis.text.y        = element_text(size = rel(0.62))
    ) +
    legend_top()
}

fig_2 <- function(d) girafe_indicator(fig_2_plot(d), height = 13)

# Sorted like the chart, largest rise first.
fig_2_table <- function(d) {
  d <- with_label(d)
  d <- d[match(rev(station_levels(d)), d$label), ]
  data.frame(
    Station   = d$station,
    State     = d$state,
    Latitude  = sprintf("%s°N", d$lat),
    # Kwajalein and Wake Island lie east of the antimeridian.
    Longitude = ifelse(startsWith(d$long, "-"),
                       sprintf("%s°W", sub("^-", "", d$long)),
                       sprintf("%s°E", d$long)),
    `Relative sea level change, 1960–2023 (inches)` = d$value,
    check.names = FALSE
  )
}
