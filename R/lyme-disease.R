# Figures for indicators/lyme-disease.qmd.

REPO <- "lyme-disease"

# Series colours, keyed by the machine-readable series key from the data. This
# indicator's keys are the four CSTE/CDC surveillance case definitions in
# `definition_key`. They are not four concurrent series: they are four
# consecutive eras of one national incidence series, so the slot order below is
# deliberately not chronological.
INDICATOR_COLOURS <- palette_for(c(
  # 1 blue    the reference stretch: 14 years, the longest era and the one the
  #           modern record is read against.
  "def_2008",
  # 2 orange  the attention colour, because 2022 is the point most likely to be
  #           misread. Its apparent jump is largely an artefact of the new
  #           definition letting high-incidence jurisdictions report on
  #           laboratory evidence alone, not a jump in disease risk.
  "def_2022",
  # 3 aqua    a comparison era: the twelve years between the first and second
  #           breakpoints.
  "def_1996",
  # 4 magenta the earliest and shortest era, four years under the original
  #           reporting definition; least comparable to anything after it.
  "def_1990"
))

# ---- Figure 1: national Lyme disease incidence, 1992-2022 --------------------

# Legend text: "<definition> (<first>-<last>)", with the coverage span read from
# the upstream meta.yml, which that repo derives from the data itself. Typing
# the years here instead would be a second copy able to drift from the first.
fig_1_era_labels <- function(meta) {
  s <- meta_for(meta, "lyme_incidence_national.csv")$series
  stats::setNames(
    vapply(s, function(x) sprintf("%s (%s)", x$label, x$coverage), character(1)),
    vapply(s, function(x) x$key, character(1))
  )
}

# *_plot() builds the plain ggplot object; fig_*() wraps it for the page. The
# split exists so a plot can be ggsave()'d for a static check without pulling
# in the htmlwidget machinery.
fig_1_plot <- function(d, meta) {
  eras <- unique(d$definition_key[order(d$year)])
  labels <- fig_1_era_labels(meta)
  stopifnot(
    "figure 1: meta.yml does not describe every case definition in the data" =
      all(eras %in% names(labels))
  )
  d$era <- unname(labels[d$definition_key])

  # Breakpoints, derived: the boundary between one era's last year and the
  # next era's first. Drawn between the two rather than on either.
  era_last <- vapply(eras, function(k) max(d$year[d$definition_key == k]), numeric(1))
  breakpoints <- utils::head(era_last, -1L) + 0.5

  ggplot(d, aes(x = year, y = value, colour = era, group = definition_key)) +
    geom_vline(
      xintercept = breakpoints,
      colour = "#9a9a94", linetype = "22", linewidth = 0.4
    ) +
    geom_line_interactive(linewidth = 0.9) +
    # Markers are filled with the era colour and ringed in the surface colour,
    # so a point stays legible where the line doubles back over itself. The
    # ring is why fill, not colour, carries the marker: colour is already the
    # line's aesthetic.
    geom_point_interactive(
      aes(
        fill = era, data_id = definition_key,
        tooltip = ifelse(
          nzchar(note),
          sprintf("%d - %s\n%.1f cases per 100,000 people\n\n%s",
                  year, definition_label, value, note),
          sprintf("%d - %s\n%.1f cases per 100,000 people",
                  year, definition_label, value)
        )
      ),
      shape = 21, colour = "white", size = 2.4, stroke = 0.8
    ) +
    scale_colour_manual(
      values = label_colours(d, "definition_key", "era", eras),
      breaks = label_order(d, "definition_key", "era", eras)
    ) +
    scale_fill_manual(
      values = label_colours(d, "definition_key", "era", eras),
      guide = "none"
    ) +
    guides(colour = guide_legend(nrow = 2, byrow = TRUE)) +
    scale_x_continuous(breaks = c(seq(1992, 2017, 5), 2022)) +
    scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.08))) +
    labs(x = NULL, y = "Reported cases per 100,000 people") +
    theme_indicator() +
    legend_top()
}

fig_1 <- function(d, meta) girafe_indicator(fig_1_plot(d, meta), height = 4.6)

fig_1_table <- function(d) {
  out <- d[, c("year", "definition_label", "value", "note")]
  names(out) <- c("Year", "Case definition",
                  "Cases per 100,000 people", "Note (EPA / CDC)")
  out
}

# ---- Figure 2: incidence by jurisdiction, 2022 -------------------------------

# CDC designates a jurisdiction "high-incidence" once it has averaged at least
# this many confirmed cases per 100,000 people over three consecutive years,
# and it is the same number EPA's own Figure 2 caption uses as the cutoff for
# what its map draws at all. It is a published definition, not a threshold
# chosen here to make the chart look tidy.
FIG2_HIGH_INCIDENCE <- 10

# Sorted ascending so the highest rate lands at the top of a horizontal bar
# chart, with the jurisdiction that filed no report at the very bottom -- it
# has no rate to rank and must not be sorted as if it were a zero.
fig_2_sorted <- function(d) {
  d[order(d$value, decreasing = FALSE, na.last = FALSE), ]
}

fig_2_plot <- function(d) {
  d <- fig_2_sorted(d)

  d$jurisdiction <- factor(d$jurisdiction, levels = d$jurisdiction)
  reported <- !is.na(d$value)

  ggplot(d, aes(y = jurisdiction, x = value)) +
    geom_vline(
      xintercept = FIG2_HIGH_INCIDENCE,
      colour = "#9a9a94", linetype = "22", linewidth = 0.4
    ) +
    geom_col_interactive(
      data = d[reported, ],
      aes(
        data_id = jurisdiction,
        tooltip = sprintf("%s\n%.1f cases per 100,000 people",
                          jurisdiction, value)
      ),
      fill = INDICATOR_PALETTE[[1]], width = 0.72
    ) +
    # The non-reporting jurisdiction keeps its row and says why, in place of a
    # bar. Sized and coloured to read as an annotation, not as data.
    geom_text_interactive(
      data = d[!reported, ],
      aes(
        x = 0, label = "no report filed for 2022",
        data_id = jurisdiction,
        tooltip = sprintf("%s\nFiled no report for 2022. Not a rate of zero.",
                          jurisdiction)
      ),
      hjust = 0, nudge_x = 1.5, size = 2.9, colour = "#6b6b66", fontface = "italic"
    ) +
    annotate(
      "text", x = FIG2_HIGH_INCIDENCE, y = 2.2, hjust = -0.08,
      label = paste0("CDC high-incidence threshold: ",
                     FIG2_HIGH_INCIDENCE, " per 100,000"),
      size = 2.9, colour = "#6b6b66"
    ) +
    # Pinned rather than left to the discrete scale, which builds its level set
    # layer by layer: the bar layer excludes the non-reporting jurisdiction, so
    # that one arrived with the text layer and got appended to the end of the
    # axis -- landing at the top of the chart, above the highest rate.
    scale_y_discrete(limits = levels(d$jurisdiction)) +
    scale_x_continuous(
      limits = c(0, NA), expand = expansion(mult = c(0, 0.04)),
      position = "top"
    ) +
    labs(x = "Reported cases per 100,000 people (2022)", y = NULL) +
    theme_indicator() +
    theme(
      # theme_indicator() is built for a vertical chart: gridlines running
      # across the categories and a baseline under them. Both flip here.
      panel.grid.major.x = element_line(colour = "#dcdcd7", linewidth = 0.4),
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
    Jurisdiction = d$jurisdiction,
    `Cases per 100,000 people` = ifelse(
      nzchar(d$flag), "not reported", sprintf("%.1f", d$value)
    ),
    check.names = FALSE, stringsAsFactors = FALSE
  )
}

# Figure 3 (the 1996-vs-2022 dot maps) has no figure function: EPA published
# the images and no data at all, so there is nothing to chart.
