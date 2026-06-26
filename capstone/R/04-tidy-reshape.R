#' tidy-reshape-demo.R -----------------------------------------------------
#'
#' tidy-reshape (Step 4) applied to df_ahs_cleaned.rds.
#'
#' Observation unit (named FIRST): one DISTRICT per ROUND.
#' The column names encode {indicator}_{year}; only the YEAR is a variable
#' crammed into the names. The 8 indicators are DISTINCT variables (different
#' units per the data dictionary), so they must stay as separate columns - a
#' fully-long stack of CBR + IMR + sex-ratio into one "value" column would be
#' WRONG (incommensurable units in one cell).
#'
#' Tool: pivot_longer() with the `.value` sentinel pulls the round out of the
#' names while keeping each indicator stem as its own column.
#' -------------------------------------------------------------------------

suppressWarnings(suppressMessages({ library(dplyr); library(tidyr); library(stringr) }))

library(here)
out_dir <- here::here("outputs")

wide <- readRDS(here::here("data", "raw", "df_ahs_cleaned.rds")) |> tibble::as_tibble()

cat("BEFORE: ", nrow(wide), " rows x ", ncol(wide), " cols (wide)\n", sep = "")

# --- pivot: split each "{stem}_{YYYY_YY}" into (.value = stem, round = year) -
long <- wide |>
  pivot_longer(
    cols          = -c(state, district, unique_district),
    names_to      = c(".value", "round"),
    names_pattern = "(.*)_(\\d{4}_\\d{2})$"
  ) |>
  mutate(round = str_replace(round, "_", "-")) |>   # 2010_11 -> 2010-11
  arrange(unique_district, round)

cat("AFTER : ", nrow(long), " rows x ", ncol(long), " cols (long by round)\n", sep = "")
cat("rounds:", paste(sort(unique(long$round)), collapse = ", "), "\n\n")

# --- verify the three tidy rules + no value loss --------------------------
n_value_cells_before <- nrow(wide) * (ncol(wide) - 3)   # 24 indicator cols
n_value_cells_after  <- nrow(long) * (ncol(long) - 4)   # 8 indicator cols
stopifnot(n_value_cells_before == n_value_cells_after)   # 262*24 == 786*8
stopifnot(nrow(long) == nrow(wide) * 3)                  # one row per district-round
cat("Value cells conserved:", n_value_cells_before, "==", n_value_cells_after, "(no loss)\n\n")

glimpse(long)
cat("\n--- first rows (one district across its 3 rounds) ---\n")
long |>
  filter(unique_district == first(unique_district)) |>
  select(unique_district, round, crude_birth_rate_cbr,
         infant_mortality_rate_imr, sex_ratio_at_birth_srb) |>
  print()

# --- write the tidy result (raw is never overwritten) ---------------------
write.csv(long, file.path(out_dir, "df_ahs_long.csv"), row.names = FALSE)
saveRDS(long,   file.path(out_dir, "df_ahs_long.rds"))
cat("\nTidy data written -> outputs/df_ahs_long.csv (and .rds)\n")

# Tidy checklist:
#   [x] one variable per column  - state/district/round + 8 named indicators
#   [x] one observation per row   - one district per round (262 x 3 = 786)
#   [x] one value per cell        - each indicator keeps its own scale/units
