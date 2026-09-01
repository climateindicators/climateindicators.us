# Figures for indicators/drought.qmd.

REPO <- "drought"

# Two decimal places for the index values in Figures 1-3 (PDSI, SPEI): EPA's
# own Key Points quote these to about that precision, and a tooltip showing
# -0.120833333 would be noise. The underlying data is never rounded, only
# what a reader sees.
fmt2 <- function(x) sprintf("%.2f", x)

# Figure 4's values are already a percentage (0-100), not a 0-1 fraction, so
# this appends "%" directly rather than going through scales::percent(), which
# expects a fraction.
fmt_pct <- function(x) sprintf("%.1f%%", x)

# ---- Figure 1: Palmer Drought Severity Index, annual --------------------------

# *_plot() builds the plain ggplot object; fig_*() wraps it for the page. The
# split exists so a plot can be ggsave()'d for a static check without pulling
# in the htmlwidget machinery.

# EPA's own caption: "annual values... The thicker line is a nine-year
# weighted average" - both series are lines, the smoothed one drawn thicker,
# the same shape as heavy-precipitation's Figure 2.
fig_1_plot <- function(d) {
  order <- c("annual_average", "nine_yr_average")
  raw   <- d[d$series_key == "annual_average", ]
  ma    <- d[d$series_key == "nine_yr_average", ]
  cols  <- label_colours(d, "series_key", "series_label", order)
  tt    <- function(year, label, value) sprintf("%d\n%s: %s", year, label, fmt2(value))

  ggplot(d, aes(x = year, y = value, colour = series_label, group = series_label)) +
    geom_hline(yintercept = 0, colour = CHART_GREY[["rule"]], linewidth = 0.4) +
    geom_line_interactive(
      data = raw,
      aes(data_id = series_label, tooltip = tt(year, series_label, value)),
      linewidth = 0.6
    ) +
    geom_line_interactive(
      data = ma,
      aes(data_id = series_label, tooltip = tt(year, series_label, value)),
      linewidth = 1.4
    ) +
    scale_colour_manual(values = cols, breaks = label_order(d, "series_key", "series_label", order)) +
    scale_x_continuous(breaks = seq(1900, 2020, 20)) +
    labs(x = NULL, y = "Palmer Drought Severity Index") +
    theme_indicator() +
    legend_top()
}

fig_1 <- function(d) girafe_indicator(fig_1_plot(d))

fig_1_table <- function(d) {
  w <- tidyr::pivot_wider(d, id_cols = year, names_from = series_label, values_from = value)
  out <- data.frame(Year = w$year, check.names = FALSE)
  for (nm in setdiff(names(w), "year")) out[[nm]] <- fmt2(w[[nm]])
  out
}

# ---- Figure 2: SPEI, five-year average -----------------------------------------

fig_2_plot <- function(d) {
  # group is set explicitly to a constant, not left to ggplot's default
  # grouping: with only x/y mapped, ggplot infers the group from the
  # interaction of every discrete aesthetic, including `tooltip`, and every
  # row's tooltip text is unique (it embeds the year), which silently
  # fragments the line into one invisible one-point segment per row.
  ggplot(d, aes(x = year, y = value, group = 1)) +
    geom_hline(yintercept = 0, colour = CHART_GREY[["rule"]], linewidth = 0.4) +
    geom_line_interactive(
      aes(data_id = series_label,
          tooltip = sprintf("%d\n%s: %s", year, series_label, fmt2(value))),
      colour = INDICATOR_PALETTE[["base"]], linewidth = 1
    ) +
    scale_x_continuous(breaks = seq(1900, 2020, 20)) +
    labs(x = NULL, y = "SPEI value") +
    theme_indicator()
}

fig_2 <- function(d) girafe_indicator(fig_2_plot(d))

fig_2_table <- function(d) {
  data.frame(Year = d$year, "Five-year SPEI" = fmt2(d$value), check.names = FALSE)
}

# ---- Figure 3: change in five-year SPEI, by NOAA climate division -------------
#
# EPA's own Figure 3 is a choropleth map of the 344 individual NOAA climate
# divisions. This site has no source of climate-division polygon geometry,
# unlike the CONUS state outlines the `maps` package bundles for the
# point-based maps elsewhere on this site (heat-waves, river-flooding), so
# the division-level comparison is drawn as a dot strip instead: every
# division is its own point, grouped by state and coloured by direction, the
# same idiom river-flooding's off-map strip uses for stations a projected map
# cannot hold. No division's value is aggregated away, unlike a state-level
# choropleth would require.

# The final field of a climate division code is its two-letter state code
# (a state small enough to be a single division is named "ALL", e.g.
# "ALL_RI" for Rhode Island; see data/meta.yml upstream).
division_state <- function(d) {
  d$state <- sub("^.*_([A-Z]{2})$", "\\1", d$climate_division)
  d
}

direction_colours <- function() {
  stats::setNames(
    c(INDICATOR_PALETTE[["focus"]], INDICATOR_PALETTE[["base"]]),
    c("increase", "decrease")
  )
}
DIRECTION_LABELS <- c(increase = "Wetter (SPEI increased)", decrease = "Drier (SPEI decreased)")

prep_3 <- function(d) {
  d <- division_state(d)
  d$direction <- factor(ifelse(d$value >= 0, "increase", "decrease"),
                        levels = c("increase", "decrease"))
  # States ordered by their median division value, driest at the top, so the
  # west-versus-east pattern EPA's own Key Point describes reads directly off
  # the axis rather than needing the tooltip.
  state_order <- names(sort(tapply(d$value, d$state, stats::median)))
  d$state <- factor(d$state, levels = state_order)
  d
}

fig_3_plot <- function(d) {
  d <- prep_3(d)

  ggplot(d, aes(x = value, y = state)) +
    geom_vline(xintercept = 0, colour = CHART_GREY[["rule"]], linewidth = 0.4) +
    geom_point_interactive(
      aes(
        fill = direction,
        data_id = climate_division,
        tooltip = sprintf(
          "%s, %s\n%s: %s", climate_division, state,
          ifelse(value >= 0, "Wetter", "Drier"), fmt2(value)
        )
      ),
      shape = 21, size = 1.5, colour = CHART_GREY[["surface"]], stroke = 0.3, alpha = 0.85,
      position = position_jitter(height = 0.3, width = 0, seed = 1)
    ) +
    scale_fill_manual(values = direction_colours(), labels = DIRECTION_LABELS) +
    guides(fill = guide_legend(nrow = 1, override.aes = list(size = 3, alpha = 1))) +
    labs(x = "Change in five-year SPEI", y = NULL) +
    theme_indicator() +
    legend_top() +
    theme(
      axis.text.y = element_text(size = rel(0.62)),
      panel.grid.major.y = element_blank()
    )
}

fig_3 <- function(d) girafe_indicator(fig_3_plot(d), height = 10)

# Sorted driest to wettest, matching the axis order of the chart above.
fig_3_table <- function(d) {
  d <- division_state(d)
  d <- d[order(d$value), ]
  data.frame(
    Division = d$climate_division, State = d$state, Value = fmt2(d$value),
    check.names = FALSE, stringsAsFactors = FALSE
  )
}

# ---- Figure 4: percent of U.S. land area by drought category, weekly ----------
#
# D0 through D4 are isolated, mutually exclusive categories (the percentage
# of land in exactly that category, not that category or worse; see the
# upstream repository's R/build_data.R and data-raw/PROVENANCE.md), so unlike
# a cumulative reading, stacking these five series to a shared 0-100% axis is
# correct: their sum for a given week is the total percentage of U.S. land
# area in any drought category.

# Stack order, top segment first: D4 (Exceptional, the smallest and most
# severe category) sits on top so it stays visible against the four wider
# bands beneath it.
FIG4_STACK_ORDER <- c("d4", "d3", "d2", "d1", "d0")
# Colour order is not the stack order: D0 (Abnormally dry, the mildest and
# largest category) is the baseline everything else sits within, so it takes
# the "base" role; D4 is what EPA's own Key Points single out (2012), so it
# takes "focus" even though it is drawn on top rather than at the bottom.
FIG4_COLOUR_KEYS <- c("d0", "d4", "d3", "d2", "d1")

fig_4_plot <- function(d) {
  key_labels <- stats::setNames(
    d$series_label[match(FIG4_STACK_ORDER, d$series_key)], FIG4_STACK_ORDER
  )
  d$series_key <- factor(d$series_key, levels = FIG4_STACK_ORDER)

  ggplot(d, aes(x = date, y = value, fill = series_key, group = series_key)) +
    geom_area_interactive(
      aes(
        data_id = as.character(series_key),
        tooltip = sprintf(
          "%s\nWeek of %s\n%s", key_labels[as.character(series_key)],
          format(date, "%Y-%m-%d"), fmt_pct(value)
        )
      ),
      position = "stack", colour = NA
    ) +
    scale_fill_manual(
      values = series_colours(FIG4_COLOUR_KEYS),
      breaks = FIG4_STACK_ORDER, labels = key_labels[FIG4_STACK_ORDER]
    ) +
    scale_x_date(date_breaks = "5 years", date_labels = "%Y") +
    scale_y_continuous(
      labels = function(x) paste0(x, "%"),
      limits = c(0, NA), expand = expansion(mult = c(0, 0.04))
    ) +
    guides(fill = guide_legend(nrow = 2, byrow = TRUE)) +
    labs(x = NULL, y = "Percent of U.S. land area") +
    theme_indicator() +
    legend_top()
}

fig_4 <- function(d) girafe_indicator(fig_4_plot(d), height = 4.6)

fig_4_table <- function(d) {
  w <- tidyr::pivot_wider(d, id_cols = date, names_from = series_label, values_from = value)
  out <- data.frame(Date = w$date, check.names = FALSE)
  for (nm in setdiff(names(w), "date")) out[[nm]] <- fmt_pct(w[[nm]])
  out
}
