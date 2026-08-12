# Figures for indicators/residential-energy-use.qmd.

REPO <- "residential-energy-use"

# Each dataset mixes two units in one long file (per-capita energy use and
# degree days), the same shape as heat-related-deaths' Chicago example. A
# dual-axis chart is not used (house style avoids it); instead each unit gets
# its own stacked facet with a free y-scale, exactly as fig_example_plot() in
# R/heat-related-deaths.R does. Each panel here holds exactly one series, so
# unlike that example no colour legend is needed -- the facet strip alone
# names the line.

# ---- Figure 1: summer electricity use and cooling degree days, annual -------

FIG1_PANEL_LABELS <- c(
  "kWh/person"  = "Summer electricity use per capita (kWh/person)",
  "degree days" = "Summer cooling degree days"
)

fig_1_plot <- function(d) {
  d$panel <- factor(FIG1_PANEL_LABELS[d$unit], levels = unname(FIG1_PANEL_LABELS))
  # focus: the indicator's own measure, the reason the page exists. base: the
  # reference series EPA plots alongside it, not a peer to be compared by
  # colour since each lives in its own panel.
  fill <- c(electricity_use_per_capita = INDICATOR_PALETTE[["focus"]], cdd = INDICATOR_PALETTE[["base"]])

  ggplot(d, aes(x = year, y = value, colour = measure_key, group = measure_key)) +
    geom_line_interactive(
      aes(data_id = measure_key, tooltip = sprintf("%d\n%s: %.1f %s", year, measure_label, value, unit)),
      linewidth = 0.9
    ) +
    facet_wrap(~panel, ncol = 1, scales = "free_y") +
    scale_colour_manual(values = fill, guide = "none") +
    scale_x_continuous(breaks = seq(1975, 2020, 5)) +
    scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.06))) +
    labs(x = NULL, y = NULL) +
    theme_indicator()
}

fig_1 <- function(d) girafe_indicator(fig_1_plot(d), height = 5.2)

fig_1_table <- function(d) {
  tidyr::pivot_wider(d, id_cols = year, names_from = measure_label, values_from = value)
}

# ---- Figure 2: winter natural gas use and heating degree days, annual -------

FIG2_PANEL_LABELS <- c(
  "cubic feet/person" = "Winter natural gas use per capita (cubic feet/person)",
  "degree days"        = "Winter heating degree days"
)

fig_2_plot <- function(d) {
  d$panel <- factor(FIG2_PANEL_LABELS[d$unit], levels = unname(FIG2_PANEL_LABELS))
  fill <- c(natural_gas_use_per_capita = INDICATOR_PALETTE[["focus"]], hdd = INDICATOR_PALETTE[["base"]])

  ggplot(d, aes(x = year, y = value, colour = measure_key, group = measure_key)) +
    geom_line_interactive(
      aes(data_id = measure_key, tooltip = sprintf("%d\n%s: %.1f %s", year, measure_label, value, unit)),
      linewidth = 0.9
    ) +
    facet_wrap(~panel, ncol = 1, scales = "free_y") +
    scale_colour_manual(values = fill, guide = "none") +
    scale_x_continuous(breaks = seq(1975, 2020, 5)) +
    scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.06))) +
    labs(x = NULL, y = NULL) +
    theme_indicator()
}

fig_2 <- function(d) girafe_indicator(fig_2_plot(d), height = 5.2)

fig_2_table <- function(d) {
  tidyr::pivot_wider(d, id_cols = year, names_from = measure_label, values_from = value)
}

# ---- Figure TD-1: electricity use vs. cooling degree days, monthly ----------
#
# Not on EPA's published page (see the indicator repository's
# data-raw/PROVENANCE.md). EPA's own title, "Comparison of ... and ...",
# names this as a scatter of the two monthly measures against each other,
# not a time series -- and a time series would be misleading here anyway,
# since only June/July/August exist each year and a connected line would
# draw straight through the nine unobserved months.

fig_td1_plot <- function(d) {
  wide <- tidyr::pivot_wider(d, id_cols = date, names_from = measure_key, values_from = value)

  ggplot(wide, aes(x = cdd, y = electricity_use_per_capita)) +
    geom_point_interactive(
      aes(
        data_id = date,
        tooltip = sprintf("%s\n%d cooling degree days\n%.1f kWh/person", format(date, "%B %Y"), cdd, electricity_use_per_capita)
      ),
      colour = INDICATOR_PALETTE[["focus"]], alpha = 0.6, size = 2
    ) +
    geom_smooth(
      method = "lm", formula = y ~ x, se = FALSE,
      colour = CHART_GREY[["rule"]], linetype = "22", linewidth = 0.7
    ) +
    # Extra right-hand expansion: without it, an outlier point near the axis
    # maximum can put the last tick label's text right at the panel edge,
    # clipping it (found on Figure TD-2, "1200" cut down to "120").
    scale_x_continuous(expand = expansion(mult = c(0.02, 0.08))) +
    labs(x = "Cooling degree days (month)", y = "Electricity use per capita (kWh/person, month)") +
    theme_indicator()
}

fig_td1 <- function(d) girafe_indicator(fig_td1_plot(d))

fig_td1_table <- function(d) {
  tidyr::pivot_wider(d, id_cols = date, names_from = measure_label, values_from = value)
}

# ---- Figure TD-2: natural gas use vs. heating degree days, monthly ----------
#
# Same status and reasoning as Figure TD-1 above, for the winter measures.

fig_td2_plot <- function(d) {
  wide <- tidyr::pivot_wider(d, id_cols = date, names_from = measure_key, values_from = value)

  ggplot(wide, aes(x = hdd, y = natural_gas_use_per_capita)) +
    geom_point_interactive(
      aes(
        data_id = date,
        tooltip = sprintf("%s\n%d heating degree days\n%.1f cubic feet/person", format(date, "%B %Y"), hdd, natural_gas_use_per_capita)
      ),
      colour = INDICATOR_PALETTE[["focus"]], alpha = 0.6, size = 2
    ) +
    geom_smooth(
      method = "lm", formula = y ~ x, se = FALSE,
      colour = CHART_GREY[["rule"]], linetype = "22", linewidth = 0.7
    ) +
    # See the matching comment in fig_td1_plot(): extra right-hand expansion
    # keeps the last tick label off the panel edge.
    scale_x_continuous(expand = expansion(mult = c(0.02, 0.08))) +
    labs(x = "Heating degree days (month)", y = "Natural gas use per capita (cubic feet/person, month)") +
    theme_indicator()
}

fig_td2 <- function(d) girafe_indicator(fig_td2_plot(d))

fig_td2_table <- function(d) {
  tidyr::pivot_wider(d, id_cols = date, names_from = measure_label, values_from = value)
}
