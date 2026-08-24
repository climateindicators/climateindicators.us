# Figures for indicators/heat-waves.qmd.

REPO <- "heat-waves"

# The four characteristics in EPA's own order, which is also the palette role
# order: base, focus, compare, other. They are four separate measures rather
# than peers read against one another, so the order carries no ranking.
SERIES_KEYS <- c("frequency", "duration", "season", "intensity")

# Upstream stores every value as text so the source file's precision survives
# byte for byte. EPA's own Key Points quote these to one or two decimals, and a
# chart label showing 1.949738461 would be noise, so display rounds to two
# places. The underlying data is never rounded; only what a reader sees is.
fmt <- function(x) sprintf("%.2f", x)

# ---- Figure 1: heat wave characteristics by decade ---------------------------

# *_plot() builds the plain ggplot object; fig_*() wraps it for the page. The
# split exists so a plot can be ggsave()'d for a static check without pulling
# in the htmlwidget machinery.

# Decade order comes from decade_start, not from sorting the "1960s" labels:
# string order happens to agree here, but it would not if the record ever
# reached the 2100s.
decade_factor <- function(d) {
  lv <- unique(d$decade[order(as.integer(d$decade_start))])
  factor(d$decade, levels = lv)
}

series_factor <- function(d) {
  factor(d$series_key, levels = SERIES_KEYS,
         labels = d$series_label[match(SERIES_KEYS, d$series_key)])
}

fig_1_plot <- function(d) {
  d$decade <- decade_factor(d)
  d$panel  <- series_factor(d)

  ggplot(d, aes(x = decade, y = value, fill = series_key)) +
    geom_col_interactive(
      aes(
        data_id = paste(series_key, decade, sep = "/"),
        # The unit is carried verbatim from upstream rather than retyped, so a
        # tooltip cannot claim a unit the data does not have.
        tooltip = sprintf("%s, %s\n%s %s", series_label, decade, fmt(value), unit)
      ),
      width = 0.72
    ) +
    scale_fill_manual(values = series_colours(SERIES_KEYS), guide = "none") +
    # Free y because the four measures share no scale: the season is tens of
    # days while intensity is a couple of degrees.
    facet_wrap(~ panel, nrow = 2, scales = "free_y") +
    scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.08))) +
    labs(x = NULL, y = NULL) +
    theme_indicator() +
    # Without this the second row's strip label sits hard against the first
    # row's panel and reads as if it belonged to the chart above it.
    theme(panel.spacing.y = unit(1.1, "lines"))
}

fig_1 <- function(d) girafe_indicator(fig_1_plot(d), height = 4.6)

fig_1_table <- function(d) {
  w <- tidyr::pivot_wider(d, id_cols = decade, names_from = series_label,
                          values_from = value)
  out <- data.frame(Decade = w$decade, check.names = FALSE)
  for (nm in setdiff(names(w), "decade")) out[[nm]] <- fmt(w[[nm]])
  out
}

# ---- Figure 2: change in each characteristic by city, 1961-2023 ---------------

# Upstream holds latitude and longitude as text so the source file's precision
# survives byte for byte, and read_indicator() only coerces `value`, `year` and
# `date`. They become numeric here, once.
station_points <- function(d) {
  d$latitude  <- as.numeric(d$latitude)
  d$longitude <- as.numeric(d$longitude)
  d
}

# CONUS state polygons for the basemap. Not indicator data, but bundled geometry
# shipped with the maps package and not fetched over the network, so it is built
# here rather than threaded in from the page's setup chunk.
us_states <- function() {
  sf::st_as_sf(maps::map("state", plot = FALSE, fill = TRUE))
}

# NAD83 / Conus Albers (EPSG:5070): the standard equal-area projection for
# CONUS-wide maps, so state shapes and station spacing read correctly instead of
# the straight-line distortion of unprojected lon/lat.
MAP_CRS <- 5070

# Two of EPA's 50 cities sit outside the projection's area: Honolulu and San
# Juan. Conus Albers would fling both far off the panel, so they are split out
# and drawn by fig_2_offmap() on the same colour and size scale rather than
# dropped. Membership is decided by the state code upstream derives from the
# station code, not by a coordinate box, so a future non-CONUS city is handled
# by adding it here rather than by silently landing in the sea.
OFF_MAP_STATES <- c("HI", "PR")

conus <- function(d) d[!d$state %in% OFF_MAP_STATES, , drop = FALSE]
offmap <- function(d) d[d$state %in% OFF_MAP_STATES, , drop = FALSE]

# Direction reads through colour, magnitude through size. A warm colour means
# the characteristic increased, which for every one of the four means hotter:
# more heat waves, longer ones, a longer season, a hotter one.
direction_colours <- function() {
  stats::setNames(
    c(INDICATOR_PALETTE[["focus"]], INDICATOR_PALETTE[["base"]]),
    c("increase", "decrease")
  )
}

DIRECTION_LABELS <- c(increase = "Increase", decrease = "Decrease")

# The four characteristics span very different ranges (frequency reaches 15,
# intensity 1.6), and one ggplot carries one size scale. Magnitude is therefore
# scaled within each characteristic before it becomes a radius, so every panel
# uses its full size range. This is a display quantity, not a published number:
# the real value is in the tooltip and in the table, both unrounded upstream.
prep_2 <- function(d) {
  d <- station_points(d)
  # Explicit level order, so the legend reads increase first. Left to a bare
  # character column ggplot would sort alphabetically and lead with the
  # direction only a handful of cities took.
  d$direction <- factor(ifelse(d$value >= 0, "increase", "decrease"),
                        levels = c("increase", "decrease"))
  d$rel_mag <- ave(abs(d$value), d$series_key, FUN = function(x) {
    m <- max(x)
    if (m == 0) rep(0, length(x)) else x / m
  })
  d$panel <- series_factor(d)
  d
}

fig_2_plot <- function(d) {
  d <- conus(prep_2(d))

  ggplot(d) +
    geom_sf(
      data = us_states(), fill = CHART_GREY[["grid"]],
      colour = CHART_GREY[["rule"]], linewidth = 0.3
    ) +
    geom_point_interactive(
      aes(
        x = longitude, y = latitude, fill = direction,
        size = sqrt(rel_mag), data_id = paste(station, series_key, sep = "/"),
        tooltip = sprintf(
          "%s, %s\n%s change in %s, 1961 to 2023\n%s %s",
          city, state, ifelse(value >= 0, "increase", "decrease"),
          tolower(series_label), fmt(value), unit
        )
      ),
      shape = 21, colour = CHART_GREY[["surface"]], stroke = 0.4, alpha = 0.9
    ) +
    scale_fill_manual(values = direction_colours(), labels = DIRECTION_LABELS) +
    scale_size(range = c(1.1, 5.2), guide = "none") +
    facet_wrap(~ panel, nrow = 2) +
    # `default_crs` tells coord_sf() that geom_point's raw longitude/latitude
    # columns are unprojected WGS84, so both the sf basemap and the station
    # points get projected into MAP_CRS together.
    coord_sf(crs = MAP_CRS, default_crs = 4326, datum = NA) +
    guides(fill = guide_legend(nrow = 1, override.aes = list(size = 3.2, alpha = 1))) +
    theme_void() +
    legend_top() +
    theme(strip.text = element_text(colour = CHART_GREY[["ink"]], face = "bold",
                                    hjust = 0, size = rel(0.95)))
}

fig_2 <- function(d) girafe_indicator(fig_2_plot(d), height = 5.2)

# The two cities the Albers panel cannot hold, on the same colour and size scale
# as the map above it. Drawn as a plain strip rather than a second map: at this
# size a Hawaii or Puerto Rico coastline would be a few unreadable pixels, and
# the point of the strip is that these cities are in the indicator, not where
# they are.
fig_2_offmap_plot <- function(d) {
  d <- offmap(prep_2(d))
  d$place <- factor(paste0(d$city, ", ", d$state))

  ggplot(d, aes(x = panel, y = place)) +
    geom_point_interactive(
      aes(
        fill = direction, size = sqrt(rel_mag),
        data_id = paste(station, series_key, sep = "/"),
        tooltip = sprintf(
          "%s, %s\n%s change in %s, 1961 to 2023\n%s %s",
          city, state, ifelse(value >= 0, "increase", "decrease"),
          tolower(series_label), fmt(value), unit
        )
      ),
      shape = 21, colour = CHART_GREY[["surface"]], stroke = 0.4, alpha = 0.9
    ) +
    scale_fill_manual(values = direction_colours(), guide = "none") +
    scale_size(range = c(1.1, 5.2), guide = "none") +
    scale_x_discrete(position = "top") +
    labs(x = NULL, y = NULL) +
    theme_indicator() +
    theme(panel.grid.major.y = element_line(colour = CHART_GREY[["grid"]],
                                            linewidth = 0.4))
}

fig_2_offmap <- function(d) girafe_indicator(fig_2_offmap_plot(d), height = 1.5)

# Sorted by the largest frequency increase down, so the cities where heat waves
# became most common read first.
fig_2_table <- function(d) {
  d <- station_points(d)
  w <- tidyr::pivot_wider(d, id_cols = c(city, state, latitude, longitude),
                          names_from = series_label, values_from = value)
  w <- w[order(w[["Frequency"]], decreasing = TRUE), ]
  out <- data.frame(
    City      = w$city,
    State     = w$state,
    Latitude  = sprintf("%.2f°N", w$latitude),
    Longitude = sprintf("%.2f°W", abs(w$longitude)),
    check.names = FALSE, stringsAsFactors = FALSE
  )
  for (nm in c("Frequency", "Duration", "Season length", "Intensity")) {
    out[[nm]] <- sprintf("%+.2f", w[[nm]])
  }
  out
}

# ---- Figure 3: U.S. Annual Heat Wave Index, 1895-2021 ------------------------

fig_3_plot <- function(d) {
  ggplot(d, aes(x = year, y = value)) +
    geom_col_interactive(
      aes(
        data_id = year,
        tooltip = sprintf("%d\nHeat wave index: %s", year, fmt(value))
      ),
      fill = INDICATOR_PALETTE[["focus"]], width = 0.8
    ) +
    scale_x_continuous(breaks = seq(1900, 2020, 20)) +
    scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.06))) +
    labs(x = NULL, y = "U.S. Annual Heat Wave Index") +
    theme_indicator()
}

fig_3 <- function(d) girafe_indicator(fig_3_plot(d))

fig_3_table <- function(d) {
  data.frame(Year = d$year, "Heat wave index" = fmt(d$value), check.names = FALSE)
}
