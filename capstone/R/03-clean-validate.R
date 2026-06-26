#' clean-validate-demo.R ---------------------------------------------------
#'
#' clean-validate (Step 3) applied to df_ahs_cleaned.rds, with rules SEEDED
#' from the Step 2 data dictionary. Demonstrates the two-way validation:
#'   (a) skimr re-profile  -> SEE the cleaned data
#'   (b) pointblank agent   -> ENFORCE dictionary ranges + sets + key uniqueness
#'                             + genuine epidemiological consistency (U5MR>=IMR>=NMR)
#' Nothing is dropped/imputed: the data arrives clean; we only verify.
#' -------------------------------------------------------------------------

suppressWarnings(suppressMessages({
  library(tibble); library(dplyr); library(purrr); library(stringr); library(tidyr)
}))

library(here)
out_dir <- here::here("outputs")

raw  <- readRDS(here::here("data", "raw", "df_ahs_cleaned.rds")) |> as_tibble()
dict <- read.csv(file.path(out_dir, "data-dictionary.csv"), stringsAsFactors = FALSE)

# --- 1. Standardise names (deterministic; already snake_case here) ---------
dat <- if (requireNamespace("janitor", quietly = TRUE)) janitor::clean_names(raw) else raw
transformations <- tibble(
  step = "clean_names", detail = "already snake_case; no change",
  rows_before = nrow(raw), rows_after = nrow(dat)
)

# --- 2. Surface problems (deterministic; NO changes) ----------------------
miss <- map_dbl(dat, \(c) mean(is.na(c)))
cat("Columns with any missing:", sum(miss > 0), "\n")
dup_key <- dat |> count(unique_district) |> filter(n > 1)
cat("Duplicate unique_district keys:", nrow(dup_key), "\n")
dup_name <- dat |> count(district) |> filter(n > 1)
cat("District NAMES shared across states:", nrow(dup_name),
    if (nrow(dup_name)) paste0(" (", paste(dup_name$district, collapse = ", "), ")") else "", "\n")

# --- 3. (AI recode) not needed: `state` already canonical (8 tidy values) --
transformations <- bind_rows(transformations, tibble(
  step = "recode", detail = "skipped: state already canonical (8 values), no messy categoricals",
  rows_before = nrow(dat), rows_after = nrow(dat)
))

# --- 4. SEE it: skimr re-profile ------------------------------------------
if (requireNamespace("skimr", quietly = TRUE)) {
  writeLines(format(skimr::skim(dat)), file.path(out_dir, "clean-state-skim.txt"))
  cat("skimr re-profile written -> clean-state-skim.txt\n")
}

# --- 5. ENFORCE it: pointblank agent, rules seeded from the dictionary -----
# parse numeric "min-max" ranges out of the dictionary's allowed_values
ranges <- dict |>
  filter(type == "numeric", str_detect(allowed_values, "^\\d")) |>
  separate(allowed_values, c("lo", "hi"), sep = "-", convert = TRUE, remove = FALSE) |>
  select(variable, lo, hi)

states <- str_split(dict$allowed_values[dict$variable == "state"], ";\\s*")[[1]]

if (requireNamespace("pointblank", quietly = TRUE)) {
  library(pointblank)
  ag <- create_agent(dat, label = "AHS clean-validate (rules from dictionary)")

  # (a) dictionary RANGE rules (one per numeric indicator)
  for (i in seq_len(nrow(ranges))) {
    ag <- col_vals_between(ag, columns = ranges$variable[i],
                           left = ranges$lo[i], right = ranges$hi[i], na_pass = TRUE)
  }
  # (b) dictionary SET rule + key not-null + key uniqueness
  ag <- ag |>
    col_vals_in_set(state, set = states) |>
    col_vals_not_null(unique_district) |>
    rows_distinct(columns = vars(unique_district))

  # (c) EPIDEMIOLOGICAL consistency: U5MR >= IMR >= NMR within each round
  for (yr in c("2010_11", "2011_12", "2012_13")) {
    ag <- ag |>
      col_vals_gte(columns  = str_glue("under_five_mortality_rate_{yr}"),
                   value    = vars(!!sym(str_glue("infant_mortality_rate_imr_{yr}")))) |>
      col_vals_gte(columns  = str_glue("infant_mortality_rate_imr_{yr}"),
                   value    = vars(!!sym(str_glue("neo_natal_mortality_rate_{yr}"))))
  }

  ag <- interrogate(ag)
  report <- get_agent_report(ag, display_table = FALSE)
  write.csv(report, file.path(out_dir, "validation-report.csv"), row.names = FALSE)

  n_fail_rows <- sum(report$n_fail, na.rm = TRUE)
  cat("\npointblank: ", nrow(report), " checks; all passed = ", all_passed(ag),
      "; total failing rows across checks = ", n_fail_rows, "\n", sep = "")
  show_cols <- intersect(c("type", "columns", "units", "n_pass", "n_fail"), names(report))
  print(as.data.frame(report[, show_cols]), row.names = FALSE)
} else {
  cat("pointblank not installed; install with pak::pak('pointblank') to run the formal gate.\n")
}

write.csv(transformations, file.path(out_dir, "transformations-log.csv"), row.names = FALSE)
cat("\ntransformations-log.csv written. rows in =", nrow(raw), " out =", nrow(dat),
    " (no silent loss).\n")
