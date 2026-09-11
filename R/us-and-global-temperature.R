# Figures for indicators/us-and-global-temperature.qmd.

REPO <- "us-and-global-temperature"

# ---- Figures 1 and 2: CONUS and global temperature anomalies -----------------
#
# Both datasets share one shape (year, series_key, series_label, value).
# Figure 1 carries a "five_yr_avg" series that Figure 2's source workbook does
# not have (see the indicator repository's data-raw/PROVENANCE.md), so the
# plot below adapts to whichever series_keys are actually present rather than
# assuming a fixed set. Roles are fixed by key, not by position, so a series
# draws in the same colour on both pages regardless of which other series
# happen to be present: annual is `base`, the smoothed multi-year average
# (Figure 1 only) is `focus`, and the two satellite records are `compare` and
# `other`, peer measurement methods read alongside the surface series. The
# linear trend is not a measured series at all, so it draws from
# CHART_GREY[["rule"]] rather than a palette slot, dashed and without point
# markers, matching how a fitted line (no per-year observation) differs from
# every other series here.
TEMP_ROLES <- c(
  annual        = "base",
  five_yr_avg   = "focus",
  satellite_uah = "compare",
  satellite_rss = "other"
)

temp_series_colours <- function(d) {
  present <- unique(d$series_key[d$series_key != "linear_trend"])
  key_label <- unique(d[c("series_key", "series_label")])
  cols <- stats::setNames(
    unname(INDICATOR_PALETTE[TEMP_ROLES[present]]),
    key_label$series_label[match(present, key_label$series_key)]
  )
  trend_label <- unique(d$series_label[d$series_key == "linear_trend"])
  if (length(trend_label)) cols <- c(cols, stats::setNames(CHART_GREY[["rule"]], trend_label))
  cols
}

temp_plot <- function(d) {
  main  <- d[d$series_key != "linear_trend", ]
  trend <- d[d$series_key == "linear_trend", ]
  cols  <- temp_series_colours(d)
  order <- names(cols)

  # The smoothed multi-year average (Figure 1 only) is the headline curve, so
  # it draws bold with no point markers; every other measured series draws
  # thinner, with points a reader can hover for the exact annual value.
  main$is_smoothed <- main$series_key == "five_yr_avg"
  main$tooltip <- sprintf(
    "%d — %s\n%+.2f°F anomaly (1901-2000 baseline)",
    main$year, main$series_label, main$value
  )

  ggplot(main, aes(x = year, y = value, colour = series_label, group = series_label)) +
    geom_line_interactive(aes(linewidth = is_smoothed), show.legend = FALSE) +
    geom_point_interactive(
      data = main[!main$is_smoothed, ],
      aes(data_id = paste(series_key, year), tooltip = tooltip),
      size = 1.4
    ) +
    geom_line(
      data = trend,
      aes(x = year, y = value, colour = series_label, group = series_label),
      linewidth = 0.7, linetype = "dashed"
    ) +
    scale_linewidth_manual(values = c(`FALSE` = 0.7, `TRUE` = 1.1)) +
    scale_colour_manual(values = cols, breaks = order) +
    scale_x_continuous(breaks = seq(1900, 2020, 20)) +
    labs(x = NULL, y = "Temperature anomaly (°F, vs. 1901-2000 average)", colour = NULL) +
    guides(colour = guide_legend(nrow = 2, byrow = TRUE, override.aes = list(linewidth = 1))) +
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

# Figure 2: global -------------------------------------------------------------

fig_2_plot  <- function(d) temp_plot(d)
fig_2       <- function(d) girafe_indicator(fig_2_plot(d))
fig_2_table <- function(d) temp_table(d)

# ---- Figure 3: climate-division rate of temperature change -------------------
#
# EPA's own published figure is a choropleth map; the tidy data behind it is
# one rate per climate division, with no station points or division boundary
# geometry to draw on a map with here. A strip plot of every division's rate,
# split by which baseline period it uses (the contiguous 48 states use
# 1901-2000, Alaska's 12 divisions use 1925-2000, per the narrative), shows
# the same "some places warmed more than others" story the map tells, without
# a state or region lookup this indicator's source data does not carry.
BASELINE_LABELS <- c(`1901-2000` = "Contiguous 48 states", `1925-2000` = "Alaska")

fig_3_plot <- function(d) {
  d$baseline_label <- factor(
    unname(BASELINE_LABELS[d$baseline]),
    levels = unname(BASELINE_LABELS[c("1901-2000", "1925-2000")])
  )
  cols <- stats::setNames(
    c(INDICATOR_PALETTE[["base"]], INDICATOR_PALETTE[["compare"]]),
    levels(d$baseline_label)
  )

  ggplot(d, aes(x = value, y = baseline_label, colour = baseline_label)) +
    geom_vline(xintercept = 0, colour = CHART_GREY[["rule"]], linewidth = 0.4) +
    geom_jitter_interactive(
      aes(
        data_id = climate_division,
        tooltip = sprintf("Climate division %s\n%+.2f°F per century", climate_division, value)
      ),
      height = 0.2, size = 1.6, alpha = 0.7
    ) +
    scale_colour_manual(values = cols) +
    labs(x = "Rate of temperature change (°F per century)", y = NULL) +
    theme_indicator() +
    theme(legend.position = "none")
}

fig_3       <- function(d) girafe_indicator(fig_3_plot(d), height = 3)

fig_3_table <- function(d) {
  d <- d[order(d$baseline, -as.numeric(d$value)), ]
  data.frame(
    "Climate division"      = d$climate_division,
    "Baseline period"       = d$baseline,
    "Rate (°F per century)" = sprintf("%+.3f", as.numeric(d$value)),
    check.names = FALSE, stringsAsFactors = FALSE
  )
}
