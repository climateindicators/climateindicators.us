# Figures for indicators/global-greenhouse-gas-emissions.qmd.

REPO <- "global-greenhouse-gas-emissions"

FIVE_YEAR_BREAKS <- c(1990, 1995, 2000, 2005, 2010, 2015)

# ---- Figure 1: worldwide emissions by gas, 1990-2015 -------------------------

FIG1_LABELS <- c(
  co2  = "Carbon dioxide",
  ch4  = "Methane",
  n2o  = "Nitrous oxide",
  fgas = "HFCs, PFCs, and SF6"
)

# Stack order, bottom segment first: largest to smallest by 2015 value.
# Colour role order is separate: carbon dioxide is the baseline everything
# else reads against; the fluorinated gases are the smallest series by far but
# the one the Key Points calls out as "more than tripled" since 1990, which is
# what makes it the series most worth a reader's attention.
FIG1_STACK_ORDER  <- c("co2", "ch4", "n2o", "fgas")
FIG1_COLOUR_KEYS  <- c("co2", "fgas", "n2o", "ch4")

# *_plot() builds the plain ggplot object; fig_*() wraps it for the page. The
# split exists so a plot can be ggsave()'d for a static check without pulling
# in the htmlwidget machinery.
fig_1_plot <- function(d) {
  d$series_key <- factor(d$series_key, levels = FIG1_STACK_ORDER)

  ggplot(d, aes(x = year, y = value, fill = series_key)) +
    geom_col_interactive(
      aes(
        data_id = series_key,
        tooltip = sprintf("%d — %s\n%.2f MtCO2e", year, FIG1_LABELS[as.character(series_key)], value)
      ),
      position = "stack", width = 3.5
    ) +
    scale_fill_manual(
      values = series_colours(FIG1_COLOUR_KEYS),
      breaks = FIG1_STACK_ORDER, labels = FIG1_LABELS[FIG1_STACK_ORDER]
    ) +
    guides(fill = guide_legend(nrow = 2, byrow = TRUE)) +
    scale_x_continuous(breaks = FIVE_YEAR_BREAKS) +
    scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.06))) +
    labs(x = NULL, y = "Emissions (million metric tons of CO2 equivalent)") +
    theme_indicator() +
    legend_top()
}

fig_1 <- function(d) girafe_indicator(fig_1_plot(d))

fig_1_table <- function(d) {
  tidyr::pivot_wider(d, id_cols = year, names_from = series_label, values_from = value)
}

# ---- Figure 2: worldwide emissions by sector, 1990-2015 ----------------------

FIG2_LABELS <- c(
  energy         = "Energy",
  intl_transport = "International transport",
  agriculture    = "Agriculture",
  industrial     = "Industrial processes",
  waste          = "Waste",
  lucf           = "Land-use change and forestry"
)

# Six sectors, one per INDICATOR_PALETTE slot. Energy is the dominant series
# (about 74 percent of the 2015 total, per the Key Points) and reads as the
# baseline; agriculture is the next largest and the other sector the Key
# Points names explicitly, so it takes the attention colour. Land-use change
# and forestry is the one sector that is a net sink rather than a source and
# whose share fell over 1990-2015 (EPA's own workbook shows a negative
# "% change"), which is why it is deliberately pushed to the background slot
# rather than drawn as a peer of the five source sectors.
FIG2_STACK_ORDER <- c("energy", "agriculture", "industrial", "waste", "intl_transport", "lucf")
FIG2_COLOUR_KEYS <- c("energy", "agriculture", "industrial", "waste", "intl_transport", "lucf")

fig_2_plot <- function(d) {
  d$series_key <- factor(d$series_key, levels = FIG2_STACK_ORDER)

  ggplot(d, aes(x = year, y = value, fill = series_key)) +
    geom_col_interactive(
      aes(
        data_id = series_key,
        tooltip = sprintf("%d — %s\n%.2f MtCO2e", year, FIG2_LABELS[as.character(series_key)], value)
      ),
      position = "stack", width = 3.5
    ) +
    scale_fill_manual(
      values = series_colours(FIG2_COLOUR_KEYS),
      breaks = FIG2_STACK_ORDER, labels = FIG2_LABELS[FIG2_STACK_ORDER]
    ) +
    guides(fill = guide_legend(nrow = 2, byrow = TRUE)) +
    scale_x_continuous(breaks = FIVE_YEAR_BREAKS) +
    scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.06))) +
    labs(x = NULL, y = "Emissions (million metric tons of CO2 equivalent)") +
    theme_indicator() +
    legend_top()
}

fig_2 <- function(d) girafe_indicator(fig_2_plot(d))

fig_2_table <- function(d) {
  tidyr::pivot_wider(d, id_cols = year, names_from = series_label, values_from = value)
}

# ---- Figure 3: worldwide CO2 emissions by region, 1990-2021 ------------------

# Nine regions is three more series than INDICATOR_PALETTE has slots, and a
# ninth line or stacked band on one chart is not readable regardless. Small
# multiples sidestep both problems: every panel draws the same single series
# (a region's own CO2 total) in the one baseline colour, so no palette slot is
# spent distinguishing regions and no region's value is grouped or summed for
# display -- the chart and the table beneath it show the same nine numbers.
# Panels are ordered by 2021 emissions, descending, matching the source
# workbook's own row order (EPA's technical documentation text says regions
# are ordered "lowest to highest," which the workbook itself does not do; see
# data-raw/PROVENANCE.md in the indicator repository).
FIG3_REGION_ORDER <- c(
  "East Asia and Pacific", "Europe and Central Asia", "United States",
  "South Asia", "Middle East and North Africa", "Latin America and Caribbean",
  "Sub-Saharan Africa", "Canada", "Other"
)

fig_3_plot <- function(d) {
  d$series_label <- factor(d$series_label, levels = FIG3_REGION_ORDER)

  # group is pinned explicitly: geom_area's default stat ("align") groups by
  # every discrete aesthetic in play, and the per-row tooltip string is
  # discrete and unique per point, so without this every row becomes its own
  # singleton group and the stat silently drops all of them (a real ggiraph
  # gotcha, not a hypothetical one -- verified by ggplot_build() returning
  # zero rows without this line).
  ggplot(d, aes(x = year, y = value, group = series_label)) +
    geom_area_interactive(
      aes(data_id = series_label, tooltip = sprintf("%s, %d\n%.2f MtCO2", series_label, year, value)),
      fill = INDICATOR_PALETTE[["base"]]
    ) +
    facet_wrap(~series_label, ncol = 3) +
    scale_x_continuous(breaks = c(1990, 2000, 2010, 2020)) +
    scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.08))) +
    labs(x = NULL, y = "CO2 emissions (million metric tons)") +
    theme_indicator()
}

fig_3 <- function(d) girafe_indicator(fig_3_plot(d), height = 7.5)

fig_3_table <- function(d) {
  tidyr::pivot_wider(d, id_cols = year, names_from = series_label, values_from = value)
}
