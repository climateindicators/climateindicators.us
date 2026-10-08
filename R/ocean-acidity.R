# Figures for indicators/ocean-acidity.qmd.

REPO <- "ocean-acidity"

# ---- Figure 1: ocean carbon dioxide levels and acidity, 1983-2022 ------------

# Upstream source order. Every station is a peer, so they take the first four
# palette slots in that order.
FIG1_KEYS <- c("Hawaii", "Canary Islands", "Bermuda", "Cariaco")

# pCO2 on top: EPA's figure reads carbon dioxide first and the pH response second.
FIG1_PANELS <- c(
  pCO2 = "Dissolved carbon dioxide (pCO₂, micro-atmospheres)",
  pH   = "Acidity (pH; lower is more acidic)"
)

fig_1_plot <- function(d) {
  d$decimal_year <- as.numeric(d$decimal_year)
  d$station      <- factor(d$station, levels = FIG1_KEYS)
  d$panel        <- factor(FIG1_PANELS[d$measure], levels = unname(FIG1_PANELS))

  ggplot(d, aes(x = decimal_year, y = value, colour = station, group = station)) +
    geom_line_interactive(
      aes(data_id = station, tooltip = station),
      linewidth = 0.5
    ) +
    facet_wrap(~panel, ncol = 1, scales = "free_y") +
    scale_colour_manual(values = series_colours(FIG1_KEYS)) +
    scale_x_continuous(breaks = seq(1985, 2020, by = 5)) +
    labs(x = NULL, y = NULL) +
    theme_indicator() +
    legend_top() +
    theme(panel.spacing = unit(1, "lines"))
}

fig_1 <- function(d) girafe_indicator(fig_1_plot(d), height = 6)

# Stations sample on their own dates, so there is no shared row key to pivot on.
fig_1_table <- function(d) {
  data.frame(
    Station        = d$station,
    `Decimal year` = d$decimal_year,
    Measure        = d$measure,
    Value          = as.character(d$value),
    Unit           = d$unit,
    check.names = FALSE
  )
}
