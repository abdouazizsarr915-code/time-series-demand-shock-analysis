# =========================================================
# 05_acf_pacf_analysis.R
# ACF / PACF analysis for stationary series
# =========================================================

rm(list = ls())

library(readr)
library(dplyr)
library(ggplot2)

dir.create("figures", showWarnings = FALSE)

# ---------------------------------------------------------
# 1. Load stationary data
# ---------------------------------------------------------
trips <- read_csv("data/processed/trips_stationary.csv", show_col_types = FALSE)

taxi_series <- trips$final_taxi
fhv_series  <- trips$final_fhv

# ---------------------------------------------------------
# 2. ACF & PACF plots (Taxi)
# ---------------------------------------------------------
png("figures/08_acf_taxi.png", width = 800, height = 500)
acf(taxi_series, main = "ACF - Taxi (Stationary Series)")
dev.off()

png("figures/09_pacf_taxi.png", width = 800, height = 500)
pacf(taxi_series, main = "PACF - Taxi (Stationary Series)")
dev.off()

# ---------------------------------------------------------
# 3. ACF & PACF plots (FHV)
# ---------------------------------------------------------
png("figures/10_acf_fhv.png", width = 800, height = 500)
acf(fhv_series, main = "ACF - FHV (Stationary Series)")
dev.off()

png("figures/11_pacf_fhv.png", width = 800, height = 500)
pacf(fhv_series, main = "PACF - FHV (Stationary Series)")
dev.off()

cat("Script 05 completed successfully.\n")