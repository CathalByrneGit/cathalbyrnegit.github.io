# ══════════════════════════════════════════════════════════════════
# data/refresh.R — deliberate data refresh for the housing series
#
# This is the ONLY place the site touches the Eurostat and CSO APIs.
# The posts read frozen .rds files committed to the repo; published
# figures therefore cannot change unless this script is run, the
# diff below is reviewed, and the result is deliberately committed.
#
# Usage (from the site root):
#   Rscript data/refresh.R
#
# Then: review the printed diff, inspect git diff on the csv mirrors,
# and commit only if the changes are understood and the post prose
# has been checked against them.
# ══════════════════════════════════════════════════════════════════

suppressPackageStartupMessages({
  library(eurostat)
  library(csodata)
  library(dplyr)
})

data_dir <- "posts/2026-06-10-housing_1/data"
csv_dir  <- file.path(data_dir, "csv")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)

stamp <- format(Sys.Date(), "%Y-%m-%d")

# ── helper: save rds + csv mirror, and report diff vs previous ──────
freeze <- function(obj, name) {
  rds_path <- file.path(data_dir, paste0(name, ".rds"))
  csv_path <- file.path(csv_dir,  paste0(name, ".csv"))

  if (file.exists(rds_path)) {
    old <- readRDS(rds_path)
    if (identical(dim(old), dim(obj)) &&
        isTRUE(all.equal(old, obj, check.attributes = FALSE))) {
      cat(sprintf("  %-28s unchanged (%d rows)\n", name, nrow(obj)))
    } else {
      cat(sprintf("  %-28s CHANGED: %d -> %d rows  *** REVIEW BEFORE COMMIT ***\n",
                  name, nrow(old), nrow(obj)))
    }
  } else {
    cat(sprintf("  %-28s new freeze (%d rows)\n", name, nrow(obj)))
  }

  saveRDS(obj, rds_path)
  # csv mirror: human-inspectable, git-diffable
  tryCatch(write.csv(as.data.frame(obj), csv_path, row.names = FALSE),
           error = function(e) message("    (csv mirror skipped: ", e$message, ")"))
  invisible(obj)
}

cat("Refreshing frozen data —", stamp, "\n\n")

# ── 1. Eurostat SBS: F411 / F412 ────────────────────────────────────
cat("Eurostat sbs_ovw_act (F411, F412)...\n")
eurostat_raw <- eurostat::get_eurostat(
  "sbs_ovw_act",
  filters = list(nace_r2 = c("F411", "F412")),
  stringsAsFactors = TRUE,
  time_format = "num"
)
freeze(eurostat_raw, "sbs_ovw_act_raw")

# label_eurostat downloads dictionaries — also a network call,
# so the LABELLED object is what gets frozen for the posts.
sbs_labelled <- eurostat::label_eurostat(eurostat_raw)
freeze(sbs_labelled, "sbs_ovw_act_labelled")

# ── 2. Eurostat population (per-capita denominators) ───────────────
cat("Eurostat tps00001 (population, 2022)...\n")
eurostat_pop_raw <- eurostat::get_eurostat(
  "tps00001",
  filters = list(time = c("2022")),
  stringsAsFactors = TRUE,
  time_format = "num"
)
freeze(eurostat_pop_raw, "tps00001_raw")
freeze(eurostat::label_eurostat(eurostat_pop_raw), "tps00001_labelled")

# ── 3. CSO tables ───────────────────────────────────────────────────
cso_tables <- c(
  CNAPA01 = "Construction national accounts (GVA/GOS/COE by NACE)",
  BAA12   = "Annual enterprise statistics (persons engaged, to 2019)",
  GPIIA04 = "Gross household income",
  GPIIA05 = "Gross household income (county)",
  HPM03   = "Residential property price index",
  DEA08   = "Earnings data"
)
for (tbl in names(cso_tables)) {
  cat(sprintf("CSO %s (%s)...\n", tbl, cso_tables[[tbl]]))
  freeze(csodata::cso_get_data(tbl), paste0(tbl, "_raw"))
}

# ── 4. Manifest ─────────────────────────────────────────────────────
rds_files <- list.files(data_dir, pattern = "\\.rds$", full.names = TRUE)
manifest <- data.frame(
  file        = basename(rds_files),
  md5         = tools::md5sum(rds_files),
  rows        = sapply(rds_files, function(f) {
                  x <- readRDS(f); if (is.data.frame(x)) nrow(x) else NA }),
  refreshed   = stamp,
  row.names   = NULL
)
write.csv(manifest, file.path(data_dir, "MANIFEST.csv"), row.names = FALSE)

cat("\nDone. Frozen files in", data_dir, "\n")
cat("Manifest written. If anything reported CHANGED above:\n")
cat("  1. git diff", csv_dir, "  — inspect exactly which values moved\n")
cat("  2. check the post prose still matches the tables\n")
cat("  3. commit the rds + csv + manifest together with a message\n")
cat("     recording why the refresh was run\n")
