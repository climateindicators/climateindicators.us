# Figures for indicators/heating-and-cooling-degree-days.qmd.

REPO <- "heating-and-cooling-degree-days"

# ---- Figure 1: national annual HDD and CDD, 1895-2023 ------------------------

FIG1_ORDER <- c("hdd", "cdd")

# *_plot() builds the plain ggplot object; fig_*() wraps it for the page. The
# split exists so a plot can be ggsave()'d for a static check without pulling
# in the htmlwidget machinery.
fig_1_plot <- function(d) {
  ggplot(d, aes(x = year, y = value, colour = series_label, group = series_key)) +
    geom_line_interactive(linewidth = 0.9) +
    geom_point_interactive(
      aes(
        data_id = series_key,
        tooltip = sprintf("%d — %s\n%d degree days", year, series_label, value)
      ),
      size = 1.6
    ) +
    scale_colour_manual(
      values = label_colours(d, "series_key", "series_label", FIG1_ORDER),
      breaks = label_order(d, "series_key", "series_label", FIG1_ORDER)
    ) +
    scale_x_continuous(breaks = seq(1900, 2020, 20)) +
    scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.06))) +
    labs(x = NULL, y = "Degree days") +
    theme_indicator() +
    legend_top()
}

fig_1 <- function(d) girafe_indicator(fig_1_plot(d))

fig_1_table <- function(d) {
  tidyr::pivot_wider(d, id_cols = year, names_from = series_label, values_from = value)
}

# ---- Figures 2 and 3: change in annual HDD / CDD by state, 1960-2023 vs. -----
# ---- 1895-1959 -----------------------------------------------------------------
#
# Both figures share this shape: a horizontal diverging bar per state, sorted
# ascending so the largest increase lands at the top (matching Figure 2 of
# heat-related-illnesses and lyme-disease). Unlike those figures, values here
# can be negative, so bars run from a zero baseline in either direction and a
# vertical rule marks that baseline explicitly rather than relying on the
# reader to find x = 0 on the axis.

fig_state_sorted <- function(d) {
  d[order(d$value, decreasing = FALSE), ]
}

fig_state_plot <- function(d, fill, x_label, tooltip_unit) {
  d <- fig_state_sorted(d)
  d$state <- factor(d$state, levels = d$state)

  ggplot(d, aes(y = state, x = value)) +
    geom_vline(xintercept = 0, colour = CHART_GREY[["rule"]], linewidth = 0.4) +
    geom_col_interactive(
      aes(
        data_id = state,
        tooltip = sprintf("%s\n%+.2f %s", state, value, tooltip_unit)
      ),
      fill = fill, width = 0.72
    ) +
    scale_x_continuous(expand = expansion(mult = 0.06), position = "top") +
    labs(x = x_label, y = NULL) +
    theme_indicator() +
    theme(
      # theme_indicator() is built for a vertical chart: gridlines running
      # across the categories and a baseline under them. Both flip here.
      panel.grid.major.x = element_line(colour = CHART_GREY[["grid"]], linewidth = 0.4),
      panel.grid.major.y = element_blank(),
      axis.line.x        = element_blank(),
      axis.text.y        = element_text(size = rel(0.7)),
      axis.ticks.length  = unit(0, "pt")
    )
}

fig_state_table <- function(d, value_label) {
  d <- fig_state_sorted(d)
  d <- d[rev(seq_len(nrow(d))), ]  # highest first, to match the chart
  out <- data.frame(
    State = d$state,
    sprintf("%.2f", d$value),
    check.names = FALSE, stringsAsFactors = FALSE
  )
  names(out)[2] <- value_label
  out
}

fig_2_plot <- function(d) {
  fig_state_plot(
    d, fill = INDICATOR_PALETTE[["base"]],
    x_label = "Change in heating degree days, 1960-2023 average vs. 1895-1959 average",
    tooltip_unit = "degree days"
  )
}
fig_2 <- function(d) girafe_indicator(fig_2_plot(d), height = 10)
fig_2_table <- function(d) fig_state_table(d, "Change in heating degree days")

fig_3_plot <- function(d) {
  fig_state_plot(
    d, fill = INDICATOR_PALETTE[["compare"]],
    x_label = "Change in cooling degree days, 1960-2023 average vs. 1895-1959 average",
    tooltip_unit = "degree days"
  )
}
fig_3 <- function(d) girafe_indicator(fig_3_plot(d), height = 10)
fig_3_table <- function(d) fig_state_table(d, "Change in cooling degree days")
