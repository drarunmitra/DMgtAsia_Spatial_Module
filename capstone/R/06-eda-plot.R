#' eda-plot-demo.R ---------------------------------------------------------
#'
#' eda-plot (Step 6) on the tidy AHS data. Two figures that follow the skill's
#' enriched figure-quality rules: dots over bars (show every district), clean
#' theme, no chartjunk, good labels, one question per plot.
#' -------------------------------------------------------------------------

suppressWarnings(suppressMessages({
  library(dplyr); library(ggplot2); library(forcats)
}))

library(here)
out_dir <- here::here("outputs")
fig_dir <- file.path(out_dir, "figures")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

long <- readRDS(file.path(out_dir, "df_ahs_long.rds")) |> as_tibble()
state_round <- read.csv(file.path(out_dir, "state_round_summary.csv"), stringsAsFactors = FALSE)

accent <- "#1f5560"; grey <- "grey55"
theme_eda <- theme_classic(base_size = 13) +
  theme(plot.title.position = "plot",
        plot.subtitle = element_text(colour = grey),
        plot.caption  = element_text(colour = grey, size = 8))

# === Figure 1 — DOTS over bars: every district's IMR, by state (2012-13) ===
# Question: how does district IMR spread WITHIN each state in the latest round?
# A bar of state means would hide the spread and the n; dots show both.
latest <- long |> filter(round == "2012-13")

p_dots <- ggplot(latest,
                 aes(x = fct_reorder(state, infant_mortality_rate_imr, .fun = median),
                     y = infant_mortality_rate_imr)) +
  geom_jitter(width = 0.14, height = 0, alpha = 0.55, colour = accent) +
  stat_summary(fun = median, geom = "crossbar", width = 0.5,
               linewidth = 0.4, colour = "grey25") +
  coord_flip() +
  labs(
    title    = "District infant mortality varies widely within every state",
    subtitle = "Each dot is a district; bar marks the state median (AHS 2012-13)",
    x = NULL, y = "Infant mortality rate (per 1000 live births)",
    caption  = "Dots, not bars: the spread and the district count would be hidden by a bar chart."
  ) +
  theme_eda
ggsave(file.path(fig_dir, "imr-by-state-dots-2012-13.png"), p_dots,
       width = 8, height = 5, dpi = 200)

# === Figure 2 — trend: state-mean IMR across the three rounds ==============
# Question: which states' (unweighted) mean district IMR is falling, and how fast?
state_round <- state_round |>
  mutate(round = factor(round, levels = c("2010-11", "2011-12", "2012-13")))

p_trend <- ggplot(state_round,
                  aes(round, mean_imr_unweighted, group = state, colour = state)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 2) +
  labs(
    title    = "Mean district IMR fell across most EAG states, 2010-11 to 2012-13",
    subtitle = "Unweighted mean of district rates (not population-weighted)",
    x = NULL, y = "Mean district IMR (per 1000 live births)", colour = NULL,
    caption  = "Unweighted state means; a population-weighted state rate would differ."
  ) +
  theme_eda + theme(legend.position = "right")
ggsave(file.path(fig_dir, "mean-imr-trend-by-state.png"), p_trend,
       width = 8, height = 5, dpi = 200)

cat("Figures written to outputs/figures/:\n",
    " - imr-by-state-dots-2012-13.png   (dots over bars: district spread)\n",
    " - mean-imr-trend-by-state.png     (trend across rounds)\n", sep = "")

# quick numeric companion to the trend figure (so the picture has receipts)
cat("\nMean district IMR by state and round (unweighted):\n")
state_round |>
  select(state, round, mean_imr_unweighted) |>
  tidyr::pivot_wider(names_from = round, values_from = mean_imr_unweighted) |>
  as.data.frame() |> print(row.names = FALSE)
