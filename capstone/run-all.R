#' run-all.R — one command rebuilds the whole analysis from raw data --------
#'
#' Step 9 (reproduce) ships this as the project's single entry point. It is the
#' concrete form of "a stranger can run one command and reproduce the outputs".
#' Run:  Rscript run-all.R      (or, in an R session, source("run-all.R"))
#'
#' It sources the numbered pipeline scripts (00-, 01-, … 08-) in ORDER, then
#' renders the report. The numbering IS the run order, so adding a step needs no
#' edit here. Portable by design: it locates itself and works from paths relative
#' to its own location, with no directory switching, no absolute paths, and no
#' secrets, so it passes the very Step 9 reproducibility audit it belongs to.
#' -------------------------------------------------------------------------

# --- locate this script (works under Rscript AND source()) ----------------
.proj <- local({
  a <- commandArgs(trailingOnly = FALSE)
  f <- sub("^--file=", "", grep("^--file=", a, value = TRUE))
  if (length(f)) return(dirname(normalizePath(f)))
  of <- sys.frames()[[1]]$ofile               # set when the file is source()d
  if (!is.null(of)) return(dirname(normalizePath(of)))
  normalizePath(getwd())
})

# --- find the pipeline scripts, in run order ------------------------------
# Convention: numbered scripts NN-*.R, in R/ if present else beside this file.
r_dir <- if (dir.exists(file.path(.proj, "R"))) file.path(.proj, "R") else .proj
steps <- sort(list.files(r_dir, pattern = "^[0-9]{2}-.*\\.R$", full.names = TRUE))

# Alternative — pin an explicit order instead of auto-discovery (uncomment):
# steps <- file.path(r_dir, c(
#   "02-profile-document.R", "03-clean-validate.R", "04-tidy-reshape.R",
#   "05-transform.R", "06-eda-plot.R", "07-analyse.R"))

if (!length(steps)) stop("No numbered pipeline scripts (NN-*.R) found in ", r_dir)

message("== rebuild: ", length(steps), " pipeline steps from raw data ==")
for (s in steps) { message("  -> ", basename(s)); source(s, echo = FALSE) }

# --- communicate: render the report, if there is one ----------------------
report <- c(
  list.files(.proj, pattern = "^report\\.qmd$", recursive = TRUE, full.names = TRUE),
  list.files(.proj, pattern = "\\.qmd$",        recursive = TRUE, full.names = TRUE)
)[1]
if (!is.na(report) && nzchar(report)) {
  message("  -> render ", basename(report))
  if (requireNamespace("quarto", quietly = TRUE)) {
    quarto::quarto_render(report)                       # R package, if installed
  } else if (nzchar(Sys.which("quarto"))) {
    system2("quarto", c("render", shQuote(report)))     # fall back to the CLI
  } else {
    message("  (render skipped: install the 'quarto' R package or the quarto CLI)")
  }
}

message("== done: every output rebuilt from raw data + code ==")
