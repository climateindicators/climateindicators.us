# Figures for indicators/us-and-global-temperature.qmd.

REPO <- "us-and-global-temperature"

# ---- Figures 1 and 2: CONUS and global temperature anomalies -----------------
#
# Both datasets share one shape (year, series_key, series_label, measure,
# unit, value), so the plot is built once and called with each figure's data.
# Role order: surface is `base`, since UAH and RSS are themselves calibrated
# against it (see the indicator repository's PROVENANCE.md: EPA "shifted the
# entire [satellite] curves vertically" to align their 1979-2023 mean with the
# surface series' own mean). uah/rss are peer measurement methods, `compare`
# and `other`. The long-term trend line is not a measured series at all, so it
# is drawn from CHART_GREY[["rule"]] rather than a palette slot, dashed and
# without point markers -- a smoothly varying fitted line has no per-year
# observation worth a hover target the way surface/uah/rss do.
TEMP_SERIES_KEYS <- c("surface", "uah", "rss")

temp_series_colours <- function(d) {
  cols <- label_colours(d, "series_key", "series_label", TEMP_SERIES_KEYS)
  trend_label <- unique(d$series_label[d$series_key == "trend"])
  c(cols, stats::setNames(CHART_GREY[["rule"]], trend_label))
}

temp_series_linetypes <- function(d) {
  labels <- d$series_label[match(c(TEMP_SERIES_KEYS, "trend"), d$series_key)]
  stats::setNames(c("solid", "solid", "solid", "dashed"), labels)
}

# `tooltip_extra` is a named function(year) -> character, used to add rank
# context to Figure 2's surface-series tooltip; Figure 1 passes NULL, since
# CONUS has no rank series (see data-raw/PROVENANCE.md upstream).
temp_plot <- function(d, tooltip_extra = NULL) {
  main  <- d[d$series_key %in% TEMP_SERIES_KEYS, ]
  trend <- d[d$series_key == "trend", ]

  main$tooltip <- sprintf("%d — %s\n%+.2f°F anomaly (1901-2000 baseline)",
                          main$year, main$series_label, main$value)
  if (!is.null(tooltip_extra)) {
    is_surface <- main$series_key == "surface"
    main$tooltip[is_surface] <- paste0(main$tooltip[is_surface], tooltip_extra(main$year[is_surface]))
  }

  ggplot(main, aes(x = year, y = value, colour = series_label, linetype = series_label)) +
    geom_line_interactive(aes(group = series_label), linewidth = 0.9) +
    geom_point_interactive(
      aes(data_id = paste(series_key, year), tooltip = tooltip),
      size = 1.4
    ) +
    geom_line(
      data = trend,
      aes(x = year, y = value, colour = series_label, linetype = series_label, group = series_label),
      linewidth = 0.7
    ) +
    scale_colour_manual(values = temp_series_colours(d), breaks = names(temp_series_linetypes(d))) +
    scale_linetype_manual(values = temp_series_linetypes(d), breaks = names(temp_series_linetypes(d))) +
    scale_x_continuous(breaks = seq(1900, 2020, 20)) +
    labs(x = NULL, y = "Temperature anomaly (°F, vs. 1901-2000 average)", colour = NULL, linetype = NULL) +
    guides(colour = guide_legend(nrow = 2, byrow = TRUE), linetype = guide_legend(nrow = 2, byrow = TRUE)) +
    theme_indicator() +
    legend_top()
}

temp_table <- function(d) {
  tidyr::pivot_wider(d, id_cols = year, names_from = series_label, values_from = value)
}

# Figure 1: CONUS -------------------------------------------------------------

fig_1_plot  <- function(d) temp_plot(d)
fig_1       <- function(d) girafe_indicator(fig_1_plot(d))
fig_1_table <- function(d) temp_table(d)

# Figure 2: global, with rank folded into the surface tooltip -----------------

fig_2_plot <- function(d) {
  rank_by_year <- stats::setNames(
    d$value[d$series_key == "rank"], d$year[d$series_key == "rank"]
  )
  temp_plot(d, tooltip_extra = function(year) {
    sprintf("\nRank %d of %d (1 = warmest)", rank_by_year[as.character(year)], length(rank_by_year))
  })
}
fig_2       <- function(d) girafe_indicator(fig_2_plot(d))
fig_2_table <- function(d) temp_table(d)

# ---- Figure 3: climate-division rate of temperature change -------------------
#
# EPA's own image, not redrawn: the source data is one rate per climate
# division (see data-raw/PROVENANCE.md upstream), not station points or
# polygon geometry, so there is nothing here for ggplot to place on a map the
# way Figure 1 in growing-degree-days does. No fig_3_plot() or fig_3(); the
# page shows EPA's vendored map image directly and links the tidy per-division
# data as a table and a download.

fig_3_table <- function(d) {
  d <- d[order(d$region, -d$value), ]
  data.frame(
    "Climate division" = d$climate_division_id,
    Region             = d$region,
    "Baseline period"  = d$baseline_period,
    "Rate (°F per century)" = sprintf("%+.3f", d$value),
    check.names = FALSE, stringsAsFactors = FALSE
  )
}
