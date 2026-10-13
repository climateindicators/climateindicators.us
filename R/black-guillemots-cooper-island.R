# Figures for indicators/black-guillemots-cooper-island.qmd.

REPO <- "black-guillemots-cooper-island"

# ---- Figure 1: breeding pairs and nest sites on Cooper Island, 1972-2023 -----

# Breeding pairs is the series the page's text is about; installed nest sites
# is the capacity it is read against, so it takes the base colour and a dash.
FIG1_ORDER <- c("breeding_pairs", "nest_sites_installed")
FIG1_LABELS <- c(
  breeding_pairs       = "Breeding pairs",
  nest_sites_installed = "Nest sites installed"
)
FIG1_COLOUR_KEYS <- c("nest_sites_installed", "breeding_pairs")

fig_1_plot <- function(d) {
  d$label <- unname(FIG1_LABELS[d$series])

  ggplot(d, aes(x = year, y = value, colour = label, linetype = label, group = series)) +
    geom_line_interactive(aes(data_id = series), linewidth = 0.9) +
    geom_point_interactive(
      aes(data_id = series, tooltip = sprintf("%d\n%s: %d", year, label, as.integer(value))),
      size = 1.6
    ) +
    scale_colour_manual(
      values = label_colours(d, "series", "label", FIG1_COLOUR_KEYS),
      breaks = label_order(d, "series", "label", FIG1_ORDER)
    ) +
    scale_linetype_manual(
      values = stats::setNames(c("solid", "dashed"), FIG1_LABELS[FIG1_ORDER]),
      breaks = label_order(d, "series", "label", FIG1_ORDER)
    ) +
    scale_x_continuous(breaks = seq(1975, 2020, 5)) +
    scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.06))) +
    labs(x = NULL, y = "Number of breeding pairs or nest sites") +
    theme_indicator() +
    legend_top()
}

fig_1 <- function(d) girafe_indicator(fig_1_plot(d))

fig_1_table <- function(d) {
  d$label <- factor(FIG1_LABELS[d$series], levels = FIG1_LABELS[FIG1_ORDER])
  w <- tidyr::pivot_wider(d[order(d$label), ], id_cols = year, names_from = label, values_from = value)
  w[order(w$year), ]
}
