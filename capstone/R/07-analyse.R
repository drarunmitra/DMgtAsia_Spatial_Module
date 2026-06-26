#' analyse-demo.R ----------------------------------------------------------
#'
#' analyse (Step 7) on the AHS data - the only 🔴 step. The PLAN (candidate
#' approach, exclusions, cautions) was produced by AI at temperature 0 and
#' reviewed; the human chose multiple linear regression; R fits it here. The
#' LLM never fits or reports estimates - they come from R.
#'
#' Outcome: district IMR (continuous), 2012-13 round (one row per district).
#' Predictors: CBR, CDR, SRB, state.  EXCLUDED: NMR, U5MR (definitional overlap
#' with IMR -> structural collinearity, not valid predictors).
#' -------------------------------------------------------------------------

suppressWarnings(suppressMessages({ library(dplyr); library(broom) }))

library(here)
out_dir <- here::here("outputs")
long <- readRDS(file.path(out_dir, "df_ahs_long.rds")) |> as_tibble()

d12 <- long |>
  filter(round == "2012-13") |>
  mutate(state = factor(state))   # alphabetical reference level (Bihar)
cat("Analytic sample (2012-13):", nrow(d12), "districts\n\n")

# --- Fit the CHOSEN model (human decision) --------------------------------
model <- lm(infant_mortality_rate_imr ~ crude_birth_rate_cbr +
              crude_death_rate_cdr + sex_ratio_at_birth_srb + state,
            data = d12)

# --- Estimates WITH 95% CIs (not a bare significance verdict) --------------
est <- tidy(model, conf.int = TRUE) |>
  mutate(across(where(is.numeric), \(x) round(x, 3)))
cat("=== Coefficients (estimate, 95% CI, p) ===\n")
print(as.data.frame(est), row.names = FALSE)

g <- glance(model)
cat(sprintf("\nModel fit: R2 = %.3f, adj R2 = %.3f, n = %d, F p = %.3g\n",
            g$r.squared, g$adj.r.squared, nobs(model), g$p.value))

# --- Diagnostics (MANDATORY) ----------------------------------------------
cat("\n=== Collinearity (VIF) ===\n")
if (requireNamespace("performance", quietly = TRUE)) {
  print(performance::check_collinearity(model))
} else if (requireNamespace("car", quietly = TRUE)) {
  print(car::vif(model))
} else {
  cat("(install performance or car for VIF)\n")
}

res <- residuals(model)
cat(sprintf("\nResiduals: Shapiro-Wilk p = %.3g (normality); ", shapiro.test(res)$p.value))
cat(sprintf("BP homoscedasticity check skipped unless lmtest present.\n"))
n_infl <- sum(cooks.distance(model) > 4 / nobs(model))
cat("Influential points (Cook's D > 4/n):", n_infl, "\n")

# --- Save tidy results for the report -------------------------------------
write.csv(est, file.path(out_dir, "imr-model-coefficients.csv"), row.names = FALSE)
saveRDS(model, file.path(out_dir, "imr-model.rds"))
cat("\nWritten -> imr-model-coefficients.csv, imr-model.rds\n")

# --- Refusal guardrail (demonstration) ------------------------------------
# A request to "drop predictors until SRB is significant" would be REFUSED by
# the analyse skill: that is specification search / p-hacking and invalidates
# the inference. The model set here was pre-specified from the question.
