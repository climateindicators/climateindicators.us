# Figures for indicators/cold-related-deaths.qmd.

REPO <- "cold-related-deaths"

# Series colours, keyed by the machine-readable series key from the data.
INDICATOR_COLOURS <- palette_for(c(
  # 1 blue    underlying-cause-only: the narrower, longer-running baseline.
  "underlying",
  # 2 orange  underlying-or-contributing: the broader, higher picture, and the
  #           series the page's text draws the reader to.
  "underlying_or_contributing"
))

# ---- Figure 1: annual cold-related death rates -------------------------------

# *_plot() builds the plain ggplot object; fig_*() wraps it for the page. The
# split exists so a plot can be ggsave()'d for a static check without pulling
# in the htmlwidget machinery.
fig_1_plot <- function(d) {
  # icd_revision splits the underlying-cause line at the classification
  # change; series_key alone would draw straight through 1998/1999.
  d$seg <- paste(d$series_key, d$icd_revision, sep = "/")
  order <- c("underlying", "underlying_or_contributing")

  ggplot(d, aes(x = year, y = value, colour = series_label, group = seg)) +
    geom_line_interactive(linewidth = 0.9) +
    geom_point_interactive(
      aes(
        data_id = series_key,
        tooltip = sprintf(
          "%d — %s\n%.2f deaths per million (%s)",
          year, series_label, value, icd_revision
        )
      ),
      size = 2.2
    ) +
    scale_colour_manual(
      values = label_colours(d, "series_key", "series_label", order),
      breaks = label_order(d, "series_key", "series_label", order)
    ) +
    guides(colour = guide_legend(nrow = 2, byrow = TRUE)) +
    scale_x_continuous(breaks = seq(1980, 2015, 5)) +
    scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.06))) +
    labs(x = NULL, y = "Death rate (per million people)") +
    theme_indicator() +
    legend_top()
}

fig_1 <- function(d) girafe_indicator(fig_1_plot(d))

fig_1_table <- function(d) {
  tidyr::pivot_wider(d, id_cols = year, names_from = series_label, values_from = value)
}

# ---- Figure TD-1: cold-related deaths by month, 1999-2015 --------------------

MONTH_LEVELS <- c(
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
)

fig_td1_plot <- function(d) {
  # Fixed calendar order, not the alphabetical order a bare factor on month
  # names would give.
  d$month <- factor(d$month, levels = MONTH_LEVELS)

  ggplot(d, aes(x = month, y = value)) +
    geom_col_interactive(
      aes(
        data_id = month,
        tooltip = sprintf("%s\n%d deaths (1999–2015 total)", month, value)
      ),
      fill = unname(INDICATOR_COLOURS["underlying_or_contributing"]),
      width = 0.7
    ) +
    scale_x_discrete(labels = substr(MONTH_LEVELS, 1, 3)) +
    scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.06))) +
    labs(x = NULL, y = "Total deaths, 1999–2015") +
    theme_indicator()
}

fig_td1 <- function(d) girafe_indicator(fig_td1_plot(d))

fig_td1_table <- function(d) {
  d$month <- factor(d$month, levels = MONTH_LEVELS)
  d <- d[order(d$month), ]
  data.frame(Month = as.character(d$month), `Total deaths` = d$value, check.names = FALSE)
}
