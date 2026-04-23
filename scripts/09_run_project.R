# =========================================================
# RUN PROJECT SCRIPT
# End-to-end pipeline: data → modeling → forecasting → GARCH
# =========================================================

rm(list = ls())

cat("🚀 Starting full project pipeline...\n\n")

# ---------------------------------------------------------
# Step 1 — Load & aggregate data
# ---------------------------------------------------------
cat("Step 1: Loading and aggregating data...\n")
source("scripts/01_load_and_aggregate_data.R")

# ---------------------------------------------------------
# Step 2 — Post-PAUSE filtering
# ---------------------------------------------------------
cat("Step 2: Creating post-PAUSE dataset...\n")
source("scripts/02_post_pause_sample.R")

# ---------------------------------------------------------
# Step 3 — Transform & difference
# ---------------------------------------------------------
cat("Step 3: Transforming data (log + differencing)...\n")
source("scripts/03_transform_and_difference.R")
# Step 3b — Distribution diagnostics
cat("Step 3b: Differenced distribution diagnostics...\n")
source("scripts/03b_differenced_distributions.R")
# ---------------------------------------------------------
# Step 4 — Stationarity tests
# ---------------------------------------------------------
cat("Step 4: Running stationarity tests...\n")
source("scripts/04_stationarity_tests.R")

# Step 4b — Filtering analysis
cat("Step 4b: Filtering analysis...\n")
source("scripts/04b_filtering_analysis.R")
# ---------------------------------------------------------
# Step 5 — ACF / PACF analysis
# ---------------------------------------------------------
cat("Step 5: ACF / PACF analysis...\n")
source("scripts/05_acf_pacf_analysis.R")

# ---------------------------------------------------------
# Step 6 — ARMA modeling
# ---------------------------------------------------------
cat("Step 6: ARMA model selection...\n")
source("scripts/06_arma_modeling.R")

# ---------------------------------------------------------
# Step 7 — Forecasting
# ---------------------------------------------------------
cat("Step 7: Forecasting...\n")
source("scripts/07_forecasting.R")

# ---------------------------------------------------------
# Step 8 — GARCH volatility modeling
# ---------------------------------------------------------
cat("Step 8: GARCH volatility modeling...\n")
source("scripts/08_garch_modeling.R")

# ---------------------------------------------------------
# Final message
# ---------------------------------------------------------
cat("\n✅ PROJECT COMPLETED SUCCESSFULLY\n")
cat("All outputs saved in /figures and /data/processed\n")