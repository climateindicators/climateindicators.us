# Figures for indicators/west-nile-virus.qmd.

REPO <- "west-nile-virus"

# ---- Figure 1: national annual incidence, 2002-2023 ---------------------------

# *_plot() builds the plain ggplot object; fig_*() wraps it for the page. The
# split exists so a plot can be ggsave()'d for a static check without pulling
# in the htmlwidget machinery. A single series, so no colour legend.
fig_1_plot <- function(d) {
  ggplot(d, aes(x = year, y = value)) +
    geom_line_interactive(colour = INDICATOR_PALETTE[["base"]], linewidth = 0.9) +
    geom_point_interactive(
      aes(
        data_id = year,
        tooltip = sprintf("%d\n%.2f cases per 100,000 people", year, value)
      ),
      colour = INDICATOR_PALETTE[["base"]], size = 2.4
    ) +
    # Every third year, anchored so the range's first and last years both carry
    # a label; all 22 would collide at this width.
    scale_x_continuous(breaks = seq(min(d$year), max(d$year), by = 3)) +
    scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.08))) +
    labs(x = NULL, y = "Reported cases per 100,000 people") +
    theme_indicator()
}

fig_1 <- function(d) girafe_indicator(fig_1_plot(d))

fig_1_table <- function(d) {
  data.frame(
    Year = d$year,
    `Cases per 100,000 people` = sprintf("%.3f", d$value),
    check.names = FALSE, stringsAsFactors = FALSE
  )
}

# ---- Figure 2: average annual incidence by state, 2002-2023 -------------------

# Sorted ascending so the highest rate lands at the top of a horizontal bar
# chart, matching Lyme's and Heat-Related Illnesses' Figure 2.
fig_2_sorted <- function(d) {
  d[order(d$value, decreasing = FALSE), ]
}

fig_2_plot <- function(d) {
  d <- fig_2_sorted(d)
  d$state <- factor(d$state, levels = d$state)

  ggplot(d, aes(y = state, x = value)) +
    geom_col_interactive(
      aes(
        data_id = state,
        tooltip = sprintf(
          "%s\n%.2f cases per 100,000 people, averaged annually",
          state, value
        )
      ),
      fill = INDICATOR_PALETTE[["base"]], width = 0.72
    ) +
    scale_x_continuous(
      limits = c(0, NA), expand = expansion(mult = c(0, 0.04)),
      position = "top"
    ) +
    # The period the average covers is not repeated here: the caption block
    # above the figure carries EPA's own title, which names it.
    labs(x = "Average annual cases per 100,000 people", y = NULL) +
    theme_indicator() +
    theme(
      # theme_indicator() is built for a vertical chart: gridlines running
      # across the categories and a baseline under them. Both flip here.
      panel.grid.major.x = element_line(colour = CHART_GREY[["grid"]], linewidth = 0.4),
      panel.grid.major.y = element_blank(),
      axis.line.x        = element_blank(),
      axis.text.y        = element_text(size = rel(0.72)),
      axis.ticks.length  = unit(0, "pt")
    )
}

fig_2 <- function(d) girafe_indicator(fig_2_plot(d), height = 9.5)

fig_2_table <- function(d) {
  d <- fig_2_sorted(d)
  d <- d[rev(seq_len(nrow(d))), ]  # highest first, to match the chart
  data.frame(
    State = d$state,
    `Average annual cases per 100,000 people` = sprintf("%.3f", d$value),
    check.names = FALSE, stringsAsFactors = FALSE
  )
}
