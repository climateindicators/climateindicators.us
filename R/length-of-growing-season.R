# Figures for indicators/length-of-growing-season.qmd.

REPO <- "length-of-growing-season"

# Every value on this page is a deviation from the 1895-2023 average, so zero is
# a real reference the reader has to be able to find, not just a spot on the
# axis. Each figure draws it explicitly.
BASELINE <- 0

# ---- Figure 1: length of growing season, contiguous 48 states ----------------

# *_plot() builds the plain ggplot object; fig_*() wraps it for the page. The
# split exists so a plot can be ggsave()'d for a static check without pulling
# in the htmlwidget machinery.
fig_1_plot <- function(d) {
  ggplot(d, aes(x = year, y = value)) +
    geom_hline(yintercept = BASELINE, colour = CHART_GREY[["rule"]], linewidth = 0.4) +
    geom_line_interactive(colour = INDICATOR_PALETTE[["base"]], linewidth = 0.9) +
    geom_point_interactive(
      aes(
        data_id = year,
        tooltip = sprintf("%d\n%+.1f days vs. the 1895-2023 average", year, value)
      ),
      colour = INDICATOR_PALETTE[["base"]], size = 1.4
    ) +
    scale_x_continuous(breaks = seq(1900, 2020, 20)) +
    labs(x = NULL, y = "Days shorter or longer than average") +
    theme_indicator()
}

fig_1 <- function(d) girafe_indicator(fig_1_plot(d))

fig_1_table <- function(d) {
  data.frame(
    Year = d$year,
    "Days shorter or longer than average" = sprintf("%+.2f", d$value),
    check.names = FALSE, stringsAsFactors = FALSE
  )
}

# ---- Figures 2 and 4: two-series deviation lines -----------------------------
#
# Both figures are the same chart with a different pair of series, so they share
# one builder. `colour_keys` fixes which palette slot each series draws in and
# `legend_keys` fixes the order the legend reads; they differ for Figure 2, see
# below.

fig_lines_plot <- function(d, colour_keys, legend_keys, y_label, tooltip_suffix) {
  ggplot(d, aes(x = year, y = value, colour = series_label, group = series_key)) +
    geom_hline(yintercept = BASELINE, colour = CHART_GREY[["rule"]], linewidth = 0.4) +
    geom_line_interactive(linewidth = 0.9) +
    geom_point_interactive(
      aes(
        data_id = series_key,
        tooltip = sprintf("%d — %s\n%+.1f days %s", year, series_label, value, tooltip_suffix)
      ),
      size = 1.4
    ) +
    scale_colour_manual(
      values = label_colours(d, "series_key", "series_label", colour_keys),
      breaks = label_order(d, "series_key", "series_label", legend_keys)
    ) +
    scale_x_continuous(breaks = seq(1900, 2020, 20)) +
    labs(x = NULL, y = y_label) +
    theme_indicator() +
    legend_top()
}

fig_table_wide <- function(d) {
  tidyr::pivot_wider(
    d,
    id_cols     = year,
    names_from  = series_label,
    values_from = value
  )
}

# Colour and legend order deliberately differ. EPA's own key point is that the
# West has gained growing season roughly twice as fast as the East, so the
# western series takes `focus` and the eastern one the `base` it is read
# against, which puts them in the opposite order to the legend, which follows
# EPA's figure title, "West Versus East".
FIG2_COLOUR_KEYS <- c("east", "west")
FIG2_LEGEND_KEYS <- c("west", "east")

fig_2_plot <- function(d) {
  fig_lines_plot(
    d,
    colour_keys    = FIG2_COLOUR_KEYS,
    legend_keys    = FIG2_LEGEND_KEYS,
    y_label        = "Days shorter or longer than average",
    tooltip_suffix = "vs. that half's 1895-2023 average"
  )
}
fig_2 <- function(d) girafe_indicator(fig_2_plot(d))
fig_2_table <- function(d) fig_table_wide(d)

# The two frost series are peers and read in the order the season runs, so
# colour order and legend order are the same vector here.
FIG4_KEYS <- c("last_spring_frost", "first_fall_frost")

fig_4_plot <- function(d) {
  fig_lines_plot(
    d,
    colour_keys    = FIG4_KEYS,
    legend_keys    = FIG4_KEYS,
    y_label        = "Days later or earlier than average",
    tooltip_suffix = "vs. the 1895-2023 average"
  )
}
fig_4 <- function(d) girafe_indicator(fig_4_plot(d))
fig_4_table <- function(d) fig_table_wide(d)

# ---- Figures 3, 5 and 6: change by state over 1895-2023 ----------------------
#
# EPA publishes these three as choropleth maps. They are drawn here as
# horizontal diverging bars, one per state, which carries the same numbers with
# the ranking made explicit and needs no mapping dependency. The page says so
# under each figure. Values run both ways, so the bars grow from an explicit
# zero rule rather than leaving the reader to find x = 0 on the axis.
#
# `descending` exists because the three figures do not agree on which sign is
# the larger change. For growing season length and first fall frost a bigger
# positive value is the stronger signal; for the last spring frost it is a
# bigger negative one, since an earlier spring frost is what lengthens the
# season. Sorting each so its strongest state lands at the top keeps the three
# tabs reading the same way.
fig_state_sorted <- function(d, descending) {
  d[order(d$value, decreasing = descending), ]
}

fig_state_plot <- function(d, fill, x_label, descending) {
  d <- fig_state_sorted(d, descending)
  d$state <- factor(d$state, levels = d$state)

  ggplot(d, aes(y = state, x = value)) +
    geom_vline(xintercept = BASELINE, colour = CHART_GREY[["rule"]], linewidth = 0.4) +
    geom_col_interactive(
      aes(
        data_id = state,
        tooltip = sprintf("%s\n%+.2f days", state, value)
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

fig_state_table <- function(d, value_label, descending) {
  d <- fig_state_sorted(d, descending)
  d <- d[rev(seq_len(nrow(d))), ]  # strongest first, to match the chart's top
  out <- data.frame(
    State = d$state,
    sprintf("%+.2f", d$value),
    check.names = FALSE, stringsAsFactors = FALSE
  )
  names(out)[2] <- value_label
  out
}

fig_3_plot <- function(d) {
  fig_state_plot(
    d, fill = INDICATOR_PALETTE[["base"]],
    x_label = "Change in length of growing season, 1895 to 2023 (days)",
    descending = FALSE
  )
}
fig_3 <- function(d) girafe_indicator(fig_3_plot(d), height = 10)
fig_3_table <- function(d) fig_state_table(d, "Change in growing season (days)", FALSE)

fig_5_plot <- function(d) {
  fig_state_plot(
    d, fill = INDICATOR_PALETTE[["focus"]],
    x_label = "Change in timing of last spring frost, 1895 to 2023 (days)",
    descending = TRUE
  )
}
fig_5 <- function(d) girafe_indicator(fig_5_plot(d), height = 10)
fig_5_table <- function(d) fig_state_table(d, "Change in last spring frost (days)", TRUE)

fig_6_plot <- function(d) {
  fig_state_plot(
    d, fill = INDICATOR_PALETTE[["compare"]],
    x_label = "Change in timing of first fall frost, 1895 to 2023 (days)",
    descending = FALSE
  )
}
fig_6 <- function(d) girafe_indicator(fig_6_plot(d), height = 10)
fig_6_table <- function(d) fig_state_table(d, "Change in first fall frost (days)", FALSE)
