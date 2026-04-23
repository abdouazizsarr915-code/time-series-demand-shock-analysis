# =========================================================
# 03b_differenced_distributions.R
# Distribution diagnostics for stationary series
# Histograms + QQ plots
# =========================================================

rm(list = ls())

required_packages <- c(
  "readr",
  "dplyr",
  "ggplot2",
  "patchwork"
)

installed <- rownames(installed.packages())
for (pkg in required_packages) {
  if (!(pkg %in% installed)) install.packages(pkg)
  library(pkg, character.only = TRUE)
}

source("scripts/00_plot_style.R")

dir.create("figures", showWarnings = FALSE)

# ---------------------------------------------------------
# 1. Load stationary data
# ---------------------------------------------------------
trips <- read_csv("data/processed/trips_stationary.csv", show_col_types = FALSE)

taxi_series <- trips$final_taxi
fhv_series  <- trips$final_fhv

taxi_df <- data.frame(value = taxi_series)
fhv_df  <- data.frame(value = fhv_series)

# ---------------------------------------------------------
# 2. Histograms
# ---------------------------------------------------------
p_hist_taxi <- ggplot(taxi_df, aes(x = value)) +
  geom_histogram(fill = taxi_col, color = "white", bins = 35, alpha = 0.9) +
  labs(
    title = "Taxi — Differenced Distribution",
    subtitle = "Histogram of stationary series",
    x = "Differenced log-trips",
    y = "Frequency"
  ) +
  project_theme()

p_hist_fhv <- ggplot(fhv_df, aes(x = value)) +
  geom_histogram(fill = fhv_col, color = "white", bins = 35, alpha = 0.9) +
  labs(
    title = "FHV — Differenced Distribution",
    subtitle = "Histogram of stationary series",
    x = "Differenced log-trips",
    y = "Frequency"
  ) +
  project_theme()

# ---------------------------------------------------------
# 3. QQ plots
# ---------------------------------------------------------
p_qq_taxi <- ggplot(taxi_df, aes(sample = value)) +
  stat_qq(color = taxi_col, alpha = 0.7, size = 1.6) +
  stat_qq_line(color = "black", linewidth = 0.8) +
  labs(
    title = "Taxi — QQ Plot",
    subtitle = "Normality check",
    x = "Theoretical Quantiles",
    y = "Sample Quantiles"
  ) +
  project_theme()

p_qq_fhv <- ggplot(fhv_df, aes(sample = value)) +
  stat_qq(color = fhv_col, alpha = 0.7, size = 1.6) +
  stat_qq_line(color = "black", linewidth = 0.8) +
  labs(
    title = "FHV — QQ Plot",
    subtitle = "Normality check",
    x = "Theoretical Quantiles",
    y = "Sample Quantiles"
  ) +
  project_theme()

# ---------------------------------------------------------
# 4. Save individual plots
# ---------------------------------------------------------
ggsave("figures/07b_hist_taxi.png", p_hist_taxi, width = 8, height = 5, dpi = 300)
ggsave("figures/07c_hist_fhv.png",  p_hist_fhv,  width = 8, height = 5, dpi = 300)
ggsave("figures/07d_qq_taxi.png",   p_qq_taxi,   width = 8, height = 5, dpi = 300)
ggsave("figures/07e_qq_fhv.png",    p_qq_fhv,    width = 8, height = 5, dpi = 300)

# ---------------------------------------------------------
# 5. Save combined figure
# ---------------------------------------------------------
combined_plot <- (p_hist_taxi | p_hist_fhv) / (p_qq_taxi | p_qq_fhv)

ggsave(
  "figures/07f_differenced_distributions_combined.png",
  combined_plot,
  width = 14,
  height = 10,
  dpi = 300
)

cat("Script 03b completed successfully.\n")