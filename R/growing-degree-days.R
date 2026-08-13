# Figures for indicators/growing-degree-days.qmd.

REPO <- "growing-degree-days"

# The one value every station is read against: no change between 1948 and 2023.
BASELINE <- 0

# ---- Figure 1: change in growing degree days by station, 1948-2023 -----------

# Upstream holds latitude and longitude as text so the source file's precision
# survives byte for byte, and read_indicator() only coerces `value`, `year` and
# `date`. They become numeric here, once, for both the chart and the table.
station_points <- function(d) {
  d$latitude  <- as.numeric(d$latitude)
  d$longitude <- as.numeric(d$longitude)
  d
}

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

# The seven classes are one ordered scale, not seven independent series, so they
# are not a case for series_colours(): that assigns categorical roles, and there
# are seven classes against six palette slots anyway. They ramp instead, from
# the palette's blue through a neutral grey to its orange, so the direction of a
# station's change reads before its label does. Both ends and the midpoint come
# from common.R, so no colour is defined here.
#
# An odd number of classes is what puts the ramp's midpoint on the class that
# straddles zero rather than between two classes. EPA's legend has seven; if a
# future vintage has an even number, the neutral grey would land on a class that
# is entirely positive or entirely negative and quietly mislead.
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

# *_plot() builds the plain ggplot object; fig_*() wraps it for the page. The
# split exists so a plot can be ggsave()'d for a static check without pulling
# in the htmlwidget machinery.
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
  # falls into contributes none, leaving a labelled blank. One fully transparent
  # row per empty class gives the key something to draw, and override.aes below
  # puts the colour back in the legend without putting a point on the panel.
  phantom <- data.frame(
    longitude    = d$longitude[1],
    value        = d$value[1],
    change_class = factor(
      setdiff(levels(d$change_class), as.character(d$change_class)),
      levels = levels(d$change_class)
    )
  )

  ggplot(d, aes(x = longitude, y = value)) +
    geom_hline(yintercept = BASELINE, colour = CHART_GREY[["rule"]], linewidth = 0.4) +
    # Stations sit close together in the East, so markers are filled with the
    # class colour and ringed in the surface colour to stay countable where they
    # overlap. Size is deliberately constant: EPA's map scales the symbol by
    # magnitude because its axes are geographic, but here the y axis already
    # carries magnitude, and re-encoding it would add no information.
    geom_point_interactive(
      aes(
        fill = change_class, data_id = seq_len(nrow(d)),
        tooltip = sprintf(
          "%.4f°N, %.4f°W\n%+.1f%% change, 1948 to 2023\nEPA legend class: %s",
          latitude, abs(longitude), value, as.character(change_class)
        )
      ),
      shape = 21, colour = CHART_GREY[["surface"]], size = 2.4, stroke = 0.6
    ) +
    geom_point(
      data = phantom, aes(fill = change_class),
      shape = 21, colour = CHART_GREY[["surface"]], size = 2.4, stroke = 0.6,
      alpha = 0, show.legend = TRUE
    ) +
    scale_fill_manual(
      values = stats::setNames(unname(fig_1_colours(names(labels))), unname(labels)),
      drop   = FALSE
    ) +
    guides(fill = guide_legend(nrow = 1, override.aes = list(alpha = 1, size = 3.2))) +
    scale_x_continuous(labels = function(x) paste0(abs(x), "°W")) +
    scale_y_continuous(
      labels = function(y) ifelse(y == BASELINE, "0%", sprintf("%+g%%", y))
    ) +
    labs(
      x = "Station longitude",
      y = "Change in growing degree days, 1948 to 2023"
    ) +
    theme_indicator() +
    legend_top() +
    theme(
      # theme_indicator() drops the vertical gridlines because its x axis is
      # normally time. Longitude is continuous here and a reader placing a
      # station east or west needs them back.
      panel.grid.major.x = element_line(colour = CHART_GREY[["grid"]], linewidth = 0.4)
    )
}

fig_1 <- function(d, meta) girafe_indicator(fig_1_plot(d, meta), height = 4.8)

# Sorted from the largest increase down, so the fifty stations EPA singles out
# as having gained 20 percent or more are the first thing the table shows.
fig_1_table <- function(d) {
  d <- station_points(d)
  d <- d[order(d$value, decreasing = TRUE), ]
  data.frame(
    Latitude              = sprintf("%.4f°N", d$latitude),
    Longitude             = sprintf("%.4f°W", abs(d$longitude)),
    "Percent change"      = sprintf("%+.2f", d$value),
    "EPA legend class"    = d$change_class_label,
    check.names = FALSE, stringsAsFactors = FALSE
  )
}
