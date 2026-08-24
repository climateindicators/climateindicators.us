# Figures for indicators/high-and-low-temperatures.qmd.

REPO <- "high-and-low-temperatures"

# Upstream holds every value as text so the source file's precision survives
# byte for byte, and read_indicator() only coerces `value`, `year` and `date`.
# These are the extra columns this page needs as numbers.
numeric_cols <- function(d, cols) {
  for (nm in cols) if (nm %in% names(d)) d[[nm]] <- as.numeric(d[[nm]])
  d
}

area_series   <- function(d) numeric_cols(d, "value_smoothed")
station_points <- function(d) numeric_cols(d, c("latitude", "longitude"))

# Upstream stores the land-area and record-share series as a fraction of 1,
# which is EPA's own convention even though its unit line reads "Percent". The
# multiplication happens only in axis labels and tooltips, never in the data.
pct <- function(x, digits = 0) sprintf(paste0("%.", digits, "f%%"), x * 100)

# ---- Figures 1 and 2: area of the contiguous 48 states ----------------------

# Both figures draw a thin line per year with a thick nine-year binomial
# smoothing on top, which is EPA's own presentation.
area_plot <- function(d, colours, breaks, y_title, tip_what) {
  d <- area_series(d)

  ggplot(d, aes(x = year, colour = series_label)) +
    geom_line(aes(y = value, group = series_label), linewidth = 0.4, alpha = 0.55) +
    geom_line_interactive(
      aes(y = value_smoothed, group = series_label, data_id = series_key,
          tooltip = paste0(series_label, ", nine-year average")),
      linewidth = 1.5
    ) +
    geom_point_interactive(
      aes(y = value, data_id = paste(series_key, year),
          tooltip = sprintf("%d — %s\n%s of land area %s\nnine-year average %s",
                            year, series_label, pct(value, 1), tip_what,
                            pct(value_smoothed, 1))),
      size = 1.1
    ) +
    scale_colour_manual(values = colours, breaks = breaks) +
    scale_x_continuous(breaks = seq(1910, 2020, 20)) +
    scale_y_continuous(
      limits = c(0, NA), expand = expansion(mult = c(0, 0.06)),
      labels = scales::label_percent()
    ) +
    labs(x = NULL, y = y_title) +
    theme_indicator() +
    legend_top()
}

# Role order: highs are the baseline the reader reads lows against, and EPA's
# own Key Points single out the lows as having risen faster, so lows take the
# focus slot.
FIG1_KEYS <- c("hot_highs", "hot_lows")

fig_1_plot <- function(d) {
  area_plot(
    d,
    colours  = label_colours(d, "series_key", "series_label", FIG1_KEYS),
    breaks   = label_order(d, "series_key", "series_label", FIG1_KEYS),
    y_title  = "Land area with unusually hot summer temperatures",
    tip_what = "unusually hot"
  )
}

fig_1 <- function(d) girafe_indicator(fig_1_plot(d))

# Figure 2 does not use series_colours(): the default role order would put the
# focus slot's orange on "unusually cold daily lows", drawing the coldest series
# on the page in the warmest colour the palette has. The two cold series take
# the blue and plum slots instead, which keeps this figure reading cold against
# Figure 1's warm one in the adjacent tab, and happens to be the pairing EPA
# used. Both colours still come from INDICATOR_PALETTE by name.
fig_2_colours <- function(d) {
  keys <- c("cold_highs", "cold_lows")
  stats::setNames(
    unname(INDICATOR_PALETTE[c("base", "other")]),
    d$series_label[match(keys, d$series_key)]
  )
}

fig_2_plot <- function(d) {
  area_plot(
    d,
    colours  = fig_2_colours(d),
    breaks   = label_order(d, "series_key", "series_label",
                           c("cold_highs", "cold_lows")),
    y_title  = "Land area with unusually cold winter temperatures",
    tip_what = "unusually cold"
  )
}

fig_2 <- function(d) girafe_indicator(fig_2_plot(d))

# One row per year, one column per series, annual value beside its smoothing.
area_table <- function(d) {
  d <- area_series(d)
  wide <- tidyr::pivot_wider(
    d,
    id_cols     = year,
    names_from  = series_label,
    values_from = c(value, value_smoothed),
    names_glue  = "{series_label}{ifelse(.value == 'value', '', ' (nine-year average)')}"
  )
  wide <- wide[order(wide$year), ]
  out <- data.frame(Year = wide$year, check.names = FALSE)
  for (nm in setdiff(names(wide), "year")) out[[nm]] <- pct(wide[[nm]], 1)
  out
}

fig_1_table <- area_table
fig_2_table <- area_table

# ---- Figures 3 and 4: change in unusually hot and cold days by station ------

# CONUS state polygons for the map basemaps. Not indicator data, but bundled
# geometry shipped with the maps package and not fetched over the network, so
# it is built here rather than threaded in from the page's setup chunk.
us_states <- function() {
  sf::st_as_sf(maps::map("state", plot = FALSE, fill = TRUE))
}

# NAD83 / Conus Albers (EPSG:5070): the standard equal-area projection for
# CONUS-wide maps, so state shapes and station spacing read correctly instead
# of the straight-line distortion of unprojected lon/lat.
MAP_CRS <- 5070

TREND_LEVELS <- c("increase", "decrease", "none")

# A warm colour means the station warmed, in both maps. Which direction that is
# depends on what is being counted: for Figure 3's unusually hot days it is an
# increase, for Figure 4's unusually cold days it is a decrease. Colouring both
# maps by direction alone would draw a station losing cold days in the same
# colour as one gaining them. EPA's captions make the same inversion, using red
# for more hot days in Figure 3 and for fewer cold days in Figure 4.
#
# `none` is not "no change": upstream sets a coefficient to zero when its
# regression is not significant at the 90 percent level, so these are stations
# with no trend that can be distinguished from noise. They take a grey from
# CHART_GREY rather than a palette slot, because they are not a data series.
trend_colours <- function(warming) {
  stopifnot("warming must be one of increase or decrease" =
              warming %in% c("increase", "decrease"))
  cooling <- setdiff(c("increase", "decrease"), warming)
  stats::setNames(
    c(INDICATOR_PALETTE[["focus"]], INDICATOR_PALETTE[["base"]],
      CHART_GREY[["rule"]]),
    c(warming, cooling, "none")
  )
}

# Direction also reads through shape, matching EPA's own upward and downward
# pointing symbols, so the maps survive being read in greyscale or by a reader
# who cannot separate the two hues. 24 and 25 are the fillable triangles.
TREND_SHAPES <- c(increase = 24, decrease = 25, none = 21)

station_map_plot <- function(d, warming, labels, tip_units) {
  d <- station_points(d)
  d$trend <- factor(d$trend, levels = TREND_LEVELS)

  colours <- trend_colours(warming)
  ggplot(d) +
    geom_sf(
      data = us_states(), fill = CHART_GREY[["grid"]],
      colour = CHART_GREY[["rule"]], linewidth = 0.3
    ) +
    # Size carries magnitude as well as colour, because on a map the x and y
    # channels are already spent on position. sqrt keeps a station with ten
    # times the change from drawing ten times the area.
    geom_point_interactive(
      aes(
        x = longitude, y = latitude, fill = trend, shape = trend,
        size = sqrt(abs(value)), data_id = station_id,
        tooltip = sprintf("%s (%s)\n%.4f°N, %.4f°W\n%s",
                          station_id, state, latitude, abs(longitude),
                          ifelse(trend == "none",
                                 "No trend distinguishable from noise",
                                 sprintf("%+.1f %s", value, tip_units)))
      ),
      colour = CHART_GREY[["surface"]], stroke = 0.4, alpha = 0.9
    ) +
    scale_fill_manual(values = colours, labels = labels, drop = FALSE) +
    scale_shape_manual(values = TREND_SHAPES, labels = labels, drop = FALSE) +
    scale_size(range = c(1.1, 5.5), guide = "none") +
    # `default_crs` tells coord_sf() that geom_point's raw longitude/latitude
    # columns are unprojected WGS84, so both the sf basemap and the station
    # points get projected into MAP_CRS together.
    coord_sf(crs = MAP_CRS, default_crs = 4326, datum = NA) +
    # fill and shape carry the same breaks and labels, so ggplot merges them
    # into one legend. Overriding the key size on both would be the same
    # override applied twice, which ggplot warns about and ignores.
    guides(fill = guide_legend(nrow = 1, override.aes = list(size = 3.2, alpha = 1))) +
    theme_void() +
    legend_top()
}

FIG3_LABELS <- c(increase = "More unusually hot days",
                 decrease = "Fewer unusually hot days",
                 none     = "No significant trend")

FIG4_LABELS <- c(increase = "More unusually cold days",
                 decrease = "Fewer unusually cold days",
                 none     = "No significant trend")

fig_3_plot <- function(d) {
  station_map_plot(d, warming = "increase", labels = FIG3_LABELS,
                   tip_units = "days per year hotter than the 95th percentile")
}

fig_4_plot <- function(d) {
  station_map_plot(d, warming = "decrease", labels = FIG4_LABELS,
                   tip_units = "days per year colder than the 5th percentile")
}

fig_3 <- function(d) girafe_indicator(fig_3_plot(d), height = 4.6)
fig_4 <- function(d) girafe_indicator(fig_4_plot(d), height = 4.6)

station_table <- function(d, labels, change_col) {
  d <- station_points(d)
  d <- d[order(d$value, decreasing = TRUE), ]
  out <- data.frame(
    Station   = d$station_id,
    State     = d$state,
    Latitude  = sprintf("%.4f°N", d$latitude),
    Longitude = sprintf("%.4f°W", abs(d$longitude)),
    check.names = FALSE, stringsAsFactors = FALSE
  )
  out[[change_col]] <- sprintf("%+.2f", d$value)
  out$Trend <- unname(labels[as.character(d$trend)])
  out
}

fig_3_table <- function(d) {
  station_table(d, FIG3_LABELS, "Change in days per year")
}
fig_4_table <- function(d) {
  station_table(d, FIG4_LABELS, "Change in days per year")
}

# ---- Figure 5: record daily highs and lows by decade ------------------------

DECADE_LEVELS <- c("1950s", "1960s", "1970s", "1980s", "1990s", "2000s")

# Colour role order puts record lows in the base slot and record highs in the
# focus slot, so the warm colour lands on the highs and EPA's point (highs have
# come to outnumber lows) is what the eye picks up. The legend still reads highs
# first, so the two vectors differ.
FIG5_COLOUR_KEYS <- c("record_lows", "record_highs")
FIG5_LEGEND_KEYS <- c("record_highs", "record_lows")

fig_5_plot <- function(d) {
  d$decade <- factor(d$decade, levels = DECADE_LEVELS)

  ggplot(d, aes(x = decade, y = value, fill = series_label)) +
    geom_col_interactive(
      aes(data_id = paste(decade, series_key),
          tooltip = sprintf("%s — %s\n%s of daily records",
                            decade, series_label, pct(abs(value), 2))),
      width = 0.7
    ) +
    # Record lows are stored negative, which is EPA's own convention for this
    # diverging bar chart, so the axis is labelled by magnitude.
    geom_hline(yintercept = 0, colour = CHART_GREY[["text"]], linewidth = 0.4) +
    scale_fill_manual(
      values = label_colours(d, "series_key", "series_label", FIG5_COLOUR_KEYS),
      breaks = label_order(d, "series_key", "series_label", FIG5_LEGEND_KEYS)
    ) +
    scale_y_continuous(
      limits = c(-1, 1),
      breaks = seq(-1, 1, 0.25),
      labels = function(x) scales::label_percent()(abs(x))
    ) +
    labs(x = NULL, y = "Share of daily temperature records") +
    theme_indicator() +
    legend_top() +
    # The zero line is the reference here, so the horizontal gridlines the
    # default theme suppresses on x are what the eye needs on y instead.
    theme(panel.grid.major.y = element_line(colour = CHART_GREY[["grid"]],
                                            linewidth = 0.4))
}

fig_5 <- function(d) girafe_indicator(fig_5_plot(d), height = 3.8)

fig_5_table <- function(d) {
  d$decade <- factor(d$decade, levels = DECADE_LEVELS)
  wide <- tidyr::pivot_wider(d, id_cols = decade, names_from = series_label,
                             values_from = value)
  wide <- wide[order(wide$decade), ]
  out <- data.frame(Decade = as.character(wide$decade), check.names = FALSE)
  for (nm in setdiff(names(wide), "decade")) out[[nm]] <- pct(abs(wide[[nm]]), 2)
  out
}
