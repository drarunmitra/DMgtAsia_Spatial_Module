#' build-data-dictionary.R -------------------------------------------------
#'
#' profile-document (Step 2) applied to df_ahs_cleaned.rds.
#' The deterministic skeleton (type, % missing, distinct, examples) comes from R.
#' The PROSE drafts (description / units / allowed_values / confidence / note) are
#' HARDWIRED below in place of the ellmer call - they are the AI draft, produced
#' under references/data-dictionary-standard.md, and every row stays
#' confirmed = FALSE until a human signs off.
#'
#' Source: Annual Health Survey (AHS), Office of the Registrar General of India -
#' district-level aggregate indicators. PUBLIC AGGREGATE data (no individual
#' records, no PHI), so no CARE/consent gate and safe for cloud calls.
#'
#' Conventions: tidyverse, native pipe |>, snake_case, here::here()-style paths.
#' -------------------------------------------------------------------------

suppressWarnings(suppressMessages({
  library(tibble); library(dplyr); library(purrr); library(tidyr); library(stringr)
}))

library(here)
out_dir <- here::here("outputs")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

raw <- readRDS(here::here("data", "raw", "df_ahs_cleaned.rds")) |> as_tibble()

# --- 1. Deterministic skeleton (facts from data; never guessed) -----------
skeleton <- tibble(variable = names(raw)) |>
  mutate(
    type        = map_chr(raw, \(c) class(c)[1]),
    pct_missing = map_dbl(raw, \(c) round(mean(is.na(c)) * 100, 1)),
    n_distinct  = map_int(raw, \(c) dplyr::n_distinct(c, na.rm = TRUE)),
    example     = map_chr(raw, \(c) paste(format(utils::head(stats::na.omit(c), 3),
                                                  trim = TRUE), collapse = ", "))
  )

# --- 2. HARDWIRED AI drafts (prose only) ----------------------------------
# Per-indicator-family drafts, expanded across the three AHS rounds.
years     <- c("2010_11", "2011_12", "2012_13")
yr_label  <- function(stub, yr) str_glue("{stub} (AHS round {str_replace(yr, '_', '-20')}).")
sr_note   <- paste("Convention ASSUMED females per 1000 males (standard Indian/AHS",
                   "usage); confirm against the AHS bulletin before use.")

fam <- tribble(
  ~prefix,                       ~desc_stub,                                                       ~units,                  ~allowed,   ~conf,     ~note,
  "crude_birth_rate_cbr",        "Crude birth rate: live births per 1000 mid-year population",     "per 1000 population",  "10-45",    "high",    "",
  "crude_death_rate_cdr",        "Crude death rate: deaths per 1000 mid-year population",           "per 1000 population",  "3-15",     "high",    "",
  "infant_mortality_rate_imr",   "Infant mortality rate: deaths before age 1 per 1000 live births", "per 1000 live births", "0-150",    "high",    "",
  "neo_natal_mortality_rate",    "Neonatal mortality rate: deaths within 28 days per 1000 live births", "per 1000 live births", "0-100", "high",  "",
  "under_five_mortality_rate",   "Under-five mortality rate: deaths before age 5 per 1000 live births", "per 1000 live births", "0-200", "high",  "",
  "sex_ratio_at_birth_srb",      "Sex ratio at birth: female births per 1000 male births",          "females per 1000 males", "700-1100", "medium", sr_note,
  "sex_ratio_0_4_years",         "Child sex ratio (ages 0-4): females per 1000 males aged 0-4",      "females per 1000 males", "750-1100", "medium", sr_note,
  "sex_ratio_total",             "Overall sex ratio: females per 1000 males, all ages",             "females per 1000 males", "800-1250", "medium", sr_note
)

indicator_drafts <- fam |>
  crossing(year = years) |>
  mutate(
    variable       = str_glue("{prefix}_{year}"),
    description    = yr_label(desc_stub, year),
    units          = units,
    allowed_values = allowed,
    confidence     = conf,
    note           = note
  ) |>
  select(variable, description, units, allowed_values, confidence, note)

id_drafts <- tribble(
  ~variable,          ~description,                                                                        ~units, ~allowed_values,                                                                                           ~confidence, ~note,
  "state",            "Indian state containing the district.",                                             "n/a",  "Bihar; Chhattisgarh; Jharkhand; Madhya Pradesh; Odisha; Rajasthan; Uttar Pradesh; Uttarakhand",          "high",      "",
  "district",         "District name. NOT unique across states; use unique_district as the key.",          "n/a",  "free text",                                                                                               "high",      "261 distinct names over 262 rows: one name recurs across two states.",
  "unique_district",  "Composite key district_state (lowercase, underscore-joined); the primary key.",     "n/a",  "unique per row",                                                                                          "high",      ""
)

drafts <- bind_rows(id_drafts, indicator_drafts)

# every drafted variable must match a real column (no invented rows)
stopifnot(setequal(drafts$variable, skeleton$variable))

# --- 3. Join drafts onto the skeleton; flag for human sign-off ------------
source_str <- "Annual Health Survey (AHS), Office of the Registrar General of India; district-level aggregate indicators."

data_dictionary <- skeleton |>
  left_join(drafts, by = "variable") |>
  mutate(source = source_str, confirmed = FALSE) |>
  relocate(variable, type, description, units, allowed_values,
           pct_missing, n_distinct, example, source, confidence, confirmed, note)

# --- 4. Provenance header -------------------------------------------------
provenance <- tibble(
  field = c("source", "extraction_date", "governance_status", "data_sensitivity",
            "expected_schema", "version", "documented_on", "documented_by"),
  value = c(source_str,
            "REPLACE_ME (record source AHS bulletin + extraction date)",
            "Public aggregate data; no individual records; no PHI; no consent/CARE gate.",
            "public-aggregate",
            paste(names(raw), collapse = ", "),
            "df_ahs_cleaned.rds",
            as.character(Sys.Date()),
            "REPLACE_ME")
)

# --- 5. Write outputs (raw is never overwritten) --------------------------
write.csv(data_dictionary, file.path(out_dir, "data-dictionary.csv"), row.names = FALSE)
write.csv(provenance,      file.path(out_dir, "data-dictionary-provenance.csv"), row.names = FALSE)
saveRDS(raw,               file.path(out_dir, "raw-state-snapshot.rds"))

if (requireNamespace("skimr", quietly = TRUE)) {
  writeLines(format(skimr::skim(raw)), file.path(out_dir, "raw-state-skim.txt"))
}

# --- 6. Sign-off summary --------------------------------------------------
n_medium <- sum(data_dictionary$confidence == "medium")
cat("Wrote data-dictionary.csv (", nrow(data_dictionary), "variables),",
    "provenance, and raw-state snapshot to:\n  ", out_dir, "\n", sep = "")
cat("All rows confirmed = FALSE. ", n_medium,
    " rows flagged confidence = medium (sex-ratio convention) - review before use.\n", sep = "")
