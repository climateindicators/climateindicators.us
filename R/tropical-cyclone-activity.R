# Figures for indicators/tropical-cyclone-activity.qmd.

REPO <- "tropical-cyclone-activity"

# ---- Figure 1: North Atlantic hurricane counts --------------------------------

# Role order: unadjusted is the raw count everything else is read against;
# adjusted is the corrected series EPA's own Key Points draws attention to;
# reaching_us is a peer count (same unit, smaller subset) shown alongside them.
FIG1_KEYS <- c("unadjusted", "adjusted", "reaching_us")

FIG1_LABELS <- c(
  unadjusted  = "Unadjusted",
  adjusted    = "Adjusted for missing early storms",
  reaching_us = "Reaching the United States"
)

fig_1_plot <- function(d) {
  d$series_label <- FIG1_LABELS[d$series]

  # group is explicit because the tooltip string below is unique per row; left
  # implicit, ggplot infers grouping from every discrete aesthetic in a layer,
  # including tooltip, which would put each point in its own group of one and
  # silently break every line into isolated dots.
  ggplot(d, aes(x = year, y = value, colour = series_label, group = series)) +
    geom_line_interactive(linewidth = 0.9) +
    geom_point_interactive(
      aes(
        data_id = series,
        tooltip = sprintf("%d — %s\n%.1f hurricanes (5-yr smoothed)", year, series_label, value)
      ),
      size = 1.6
    ) +
    scale_colour_manual(
      values = label_colours(d, "series", "series_label", FIG1_KEYS),
      breaks = label_order(d, "series", "series_label", FIG1_KEYS)
    ) +
    guides(colour = guide_legend(nrow = 2, byrow = TRUE)) +
    scale_x_continuous(breaks = seq(1880, 2020, 20)) +
    scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.06))) +
    labs(x = NULL, y = "Number of hurricanes (5-year smoothed average)") +
    theme_indicator() +
    legend_top()
}

fig_1 <- function(d) girafe_indicator(fig_1_plot(d))

fig_1_table <- function(d) {
  w <- tidyr::pivot_wider(
    d[c("year", "series", "value")],
    names_from = "series", values_from = "value"
  )
  w <- w[c("year", FIG1_KEYS)]
  names(w) <- c("Year", unname(FIG1_LABELS[FIG1_KEYS]))
  as.data.frame(w, check.names = FALSE)
}

# ---- Figure 2: Accumulated Cyclone Energy Index --------------------------------

# 100 is EPA's own published baseline, not a value chosen for chart tidiness:
# the ACE Index is defined "on a scale where 100 equals the median value ...
# over a base period from 1951 to 2020" (see narrative.qmd, About the
# Indicator).
ACE_MEDIAN_BASELINE <- 100

fig_2_plot <- function(d) {
  ggplot(d, aes(x = year, y = value)) +
    geom_hline(yintercept = ACE_MEDIAN_BASELINE, colour = CHART_GREY[["rule"]], linetype = "dashed") +
    geom_line_interactive(linewidth = 0.9, colour = INDICATOR_PALETTE[["focus"]]) +
    geom_point_interactive(
      aes(tooltip = sprintf("%d\n%.0f%% of 1951–2020 median", year, value)),
      size = 1.6, colour = INDICATOR_PALETTE[["focus"]]
    ) +
    scale_x_continuous(breaks = seq(1950, 2020, 10)) +
    scale_y_continuous(expand = expansion(mult = c(0.04, 0.06))) +
    labs(x = NULL, y = "ACE Index (% of 1951–2020 median)") +
    theme_indicator()
}

fig_2 <- function(d) girafe_indicator(fig_2_plot(d))

fig_2_table <- function(d) {
  data.frame(
    Year = d$year,
    "ACE Index (% of 1951-2020 median)" = d$value,
    check.names = FALSE
  )
}

# ---- Figure 3: sea surface temperature and Power Dissipation Index ------------

# Two series measured in different units shown for comparison, not two peer
# series in the same unit: small multiples (one panel per series, its own free
# y scale) rather than a dual-axis chart, which would need an arbitrary affine
# rescaling between °F and the PDI's own units to overlay them on one axis.
FIG3_KEYS <- c("sst", "pdi")

FIG3_PANEL_LABELS <- c(
  sst = "Smoothed sea surface temperature (°F)",
  pdi = "Smoothed Power Dissipation Index"
)

fig_3_plot <- function(d) {
  d$panel <- factor(FIG3_PANEL_LABELS[d$series], levels = unname(FIG3_PANEL_LABELS))
  d$series_label <- FIG3_PANEL_LABELS[d$series]

  ggplot(d, aes(x = year, y = value, colour = series_label, group = series)) +
    geom_line_interactive(
      aes(
        data_id = series,
        tooltip = sprintf("%d\n%.2f %s (5-yr smoothed)", year, value, unit)
      ),
      linewidth = 0.9
    ) +
    facet_wrap(~panel, ncol = 1, scales = "free_y") +
    scale_colour_manual(values = label_colours(d, "series", "series_label", FIG3_KEYS), guide = "none") +
    scale_x_continuous(breaks = seq(1950, 2020, 10)) +
    labs(x = NULL, y = NULL) +
    theme_indicator() +
    theme(panel.spacing = unit(1, "lines"))
}

fig_3 <- function(d) girafe_indicator(fig_3_plot(d), height = 5.2)

fig_3_table <- function(d) {
  w <- tidyr::pivot_wider(
    d[c("year", "series", "value")],
    names_from = "series", values_from = "value"
  )
  data.frame(
    Year = w$year,
    "Sea surface temperature (°F)" = w$sst,
    "Power Dissipation Index" = w$pdi,
    check.names = FALSE
  )
}
