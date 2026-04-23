# =========================================================
# 04_stationarity_tests.R
# Stationarity tests on transformed series
# =========================================================

rm(list = ls())

required_packages <- c(
  "readr",
  "dplyr",
  "tseries"
)

installed <- rownames(installed.packages())
for (pkg in required_packages) {
  if (!(pkg %in% installed)) install.packages(pkg)
  library(pkg, character.only = TRUE)
}

dir.create("data/processed", showWarnings = FALSE)

# ---------------------------------------------------------
# 1. Load stationary dataset
# ---------------------------------------------------------
trips_stationary <- read_csv("data/processed/trips_stationary.csv", show_col_types = FALSE)

taxi_series <- trips_stationary$final_taxi
fhv_series  <- trips_stationary$final_fhv

# ---------------------------------------------------------
# 2. ADF tests
# H0: non-stationary
# Reject H0 => stationary
# ---------------------------------------------------------
adf_taxi <- adf.test(taxi_series)
adf_fhv  <- adf.test(fhv_series)

# ---------------------------------------------------------
# 3. KPSS tests
# H0: stationary
# Fail to reject H0 => stationary
# ---------------------------------------------------------
kpss_taxi <- kpss.test(taxi_series)
kpss_fhv  <- kpss.test(fhv_series)

# ---------------------------------------------------------
# 4. Print results
# ---------------------------------------------------------
cat("\n==================== ADF TESTS ====================\n")
cat("Taxi ADF p-value:", adf_taxi$p.value, "\n")
cat("FHV  ADF p-value:", adf_fhv$p.value, "\n")

cat("\n=================== KPSS TESTS ====================\n")
cat("Taxi KPSS p-value:", kpss_taxi$p.value, "\n")
cat("FHV  KPSS p-value:", kpss_fhv$p.value, "\n")

# ---------------------------------------------------------
# 5. Save summary table
# ---------------------------------------------------------
stationarity_results <- tibble(
  series = c("Taxi", "FHV"),
  adf_p_value  = c(adf_taxi$p.value, adf_fhv$p.value),
  kpss_p_value = c(kpss_taxi$p.value, kpss_fhv$p.value)
)

print(stationarity_results)

write_csv(stationarity_results, "data/processed/stationarity_test_results.csv")

cat("\nScript 04 completed successfully.\n")