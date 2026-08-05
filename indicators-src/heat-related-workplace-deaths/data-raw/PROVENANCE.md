# Provenance of raw inputs

Everything in this folder is a work of the U.S. Government prepared by EPA staff
(and its contractor ERG, compiling data from the Bureau of Labor Statistics) as
part of their official duties, and is therefore not subject to domestic
copyright (17 U.S.C. 105). It is reproduced here unmodified.

Indicator page (the canonical source, January 19 2025 snapshot):
<https://19january2025snapshot.epa.gov/climate-indicators/closer-look-heat-related-workplace-deaths/index.html>

Technical documentation (PDF, not vendored here):
<https://19january2025snapshot.epa.gov/system/files/documents/2024-06/heat-related-workplace-deaths_documentation.pdf>

## Files

| File | sha256 | Origin |
|---|---|---|
| `heat-related workplace deaths figure 1 04-30-24.xlsx` | `d31cb08b075960d5161e036bbda1fae652da66258e5d839d87ac9e34543d13cc` | ERG/EPA internal workbook, Figure 1 data |
| `heat-related workplace deaths example 1 04-30-24.xlsx` | `1dfe3c5ebaddd3f2a9574f2a454ad566bf0a9384a7535321a590697e5747b501` | ERG/EPA internal workbook, Example 1 (county map) data |

Both workbooks were copied from the local archive at
`…\archive\Excel Files - Indicator Workbooks (for published indicator updates
as of 7-23-2026)\Heat-related workplace deaths\`.

Unlike `heat-related-deaths`, these are **not** EPA's own published
per-figure download CSVs (there is no 5-line metadata preamble, no
windows-1252 encoding concern) — they are the underlying ERG/BLS working
workbooks, each with multiple sheets: one sheet holding the data actually
plotted, and the rest holding BLS's raw backing tables and methods notes.
`R/build_data.R` reads only the plotted-data sheet from each (`Data for
Figure 1`, `Data for map`) with `readxl`; the other sheets are provenance
trail, not re-derived.

## Source documents deliberately NOT vendored

The indicator prose was extracted once from this Word file, which lives in
the archive and is **not** copied into this repository:

| File | sha256 |
|---|---|
| `heat-related workplace deaths - text.docx` | `05d8f47c70619eb6ef7f1be62664e04022668a013bd70c8bdc4ba8bfa7af6e55` |

A second archived file, the technical documentation / metadata doc, is noted
here for completeness but was not used for prose extraction (this indicator's
figures are both on the live page; there's no supplementary figure whose
caption lives only in the TD doc, unlike some other indicators):

| File | sha256 |
|---|---|
| `heat-related_workplace_deaths_TD_METADATA_CLEAN.docx` | `d3d2d0121a15c2c562bcd28e0e8871ec52de8a2df30af4cdd809ab5fcc6b61cd` |

Same two reasons as every other indicator in this project for not vendoring
either docx: the prose now lives in `index.qmd`, the artifact the site
renders; and the text docx carries tracked changes and (potentially)
`word/comments.xml` / `word/people.xml`, so committing it would risk
publishing reviewers' names and internal editorial comments.

`R/gen_narrative.R` can regenerate the prose from the archive for anyone who
has it. The checksum above identifies the exact revision used.

**Citation mechanism note (read before touching `R/gen_narrative.R` again):**
the text docx's inline citation markers are not typed superscript characters.
It was originally authored with real Word endnotes, then the author switched
to Zotero-managed citations (`ADDIN ZOTERO_ITEM CSL_CITATION` fields); track
changes recorded the old endnote marks as *deleted* rather than removing
them, so all 16 `w:endnoteReference` elements in the body sit inside a
`w:del` and are correctly excluded by `read_docx.R`'s existing
accept-all-tracked-changes filter. The live citation marker is each Zotero
field's cached display result — an ordinary superscript `w:t` run — which
`read_docx.R` already handled before any endnote-specific code was added.
`R/utils/read_docx.R` now also resolves genuinely-live (non-deleted)
`w:endnoteReference` marks, for the next indicator that has real ones instead
of a Zotero field.

## Updating the data

Replace the xlsx workbook(s) in this folder and rerun `R/build_data.R`.
`build_data.R` reads each workbook's plotted-data sheet by name (not
position), so a rename of that sheet stops the build with a clear error
rather than silently reading the wrong sheet. Update the table above with the
new sha256 and note the new EPA "Web update" date.
