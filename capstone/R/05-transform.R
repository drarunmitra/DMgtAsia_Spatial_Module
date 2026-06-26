#' transform-demo.R --------------------------------------------------------
#'
#' transform (Step 5) on the tidy AHS data (df_ahs_long). Derive variables and
#' summaries, with the grain checked after every aggregation (the skill never
#' silently changes the grain of the data).
#' -------------------------------------------------------------------------

suppressWarnings(suppressMessages({ library(dplyr); library(tidyr); library(stringr) }))

library(here)
out_dir <- here::here("outputs")
long <- readRDS(file.path(out_dir, "df_ahs_long.rds")) |> tibble::as_tibble()

# --- A. State x round summary ---------------------------------------------
# CAVEAT (flagged, per house style): this is the UNWEIGHTED mean of district
# rates. The true state rate needs population weights - an unweighted mean of
# district rates is a district-level average, not the state's IMR. Named to say so.
state_round <- long |>
  group_by(state, round) |>
  summarise(
    n_districts          = n(),
    mean_imr_unweighted  = round(mean(infant_mortality_rate_imr), 1),
    mean_u5mr_unweighted = round(mean(under_five_mortality_rate), 1),
    mean_cbr_unweighted  = round(mean(crude_birth_rate_cbr), 1),
    mean_srb_unweighted  = round(mean(sex_ratio_at_birth_srb), 1),
    .groups = "drop"
  )

# grain check: one row per state-round (8 states x 3 rounds = 24)
stopifnot(nrow(state_round) == n_distinct(long$state) * n_distinct(long$round))
cat("State x round summary: ", nrow(state_round), " rows (", n_distinct(long$state),
    " states x ", n_distinct(long$round), " rounds) - grain OK\n", sep = "")

# --- B. District-level change in IMR, 2010-11 -> 2012-13 -------------------
imr_change <- long |>
  filter(round %in% c("2010-11", "2012-13")) |>
  select(state, district, unique_district, round, infant_mortality_rate_imr) |>
  pivot_wider(names_from = round, values_from = infant_mortality_rate_imr,
              names_prefix = "imr_") |>
  mutate(
    imr_change   = round(`imr_2012-13` - `imr_2010-11`, 1),       # negative = improvement
    imr_pct_drop = round(100 * (`imr_2010-11` - `imr_2012-13`) / `imr_2010-11`, 1)
  )

# grain check: pivot_wider must NOT change the number of districts
stopifnot(nrow(imr_change) == n_distinct(long$unique_district))
cat("IMR change table: ", nrow(imr_change), " districts - grain preserved (no row blow-up)\n\n",
    sep = "")

cat("--- Biggest IMR declines (district), 2010-11 to 2012-13 ---\n")
imr_change |> arrange(imr_change) |>
  select(district, state, `imr_2010-11`, `imr_2012-13`, imr_change, imr_pct_drop) |>
  head(8) |> as.data.frame() |> print(row.names = FALSE)

cat("\n--- Any districts where IMR ROSE? ---\n")
risen <- imr_change |> filter(imr_change > 0) |> arrange(desc(imr_change))
cat(nrow(risen), "districts had a higher IMR in 2012-13 than 2010-11\n")
if (nrow(risen)) print(as.data.frame(head(risen[, c("district","state","imr_change")], 6)), row.names = FALSE)

# --- write outputs --------------------------------------------------------
write.csv(state_round, file.path(out_dir, "state_round_summary.csv"), row.names = FALSE)
write.csv(imr_change,  file.path(out_dir, "district_imr_change.csv"), row.names = FALSE)
cat("\nWritten -> state_round_summary.csv, district_imr_change.csv\n")
