# =========================================================
# 03_transform_and_difference.R
# Log transform + differencing (trend + seasonality)
# =========================================================

rm(list = ls())

library(dplyr)
library(readr)
library(ggplot2)
library(lubridate)

dir.create("figures", showWarnings = FALSE)
source("scripts/00_plot_style.R")

# ---------------------------------------------------------
# 1. Load post-PAUSE data
# ---------------------------------------------------------
trips <- read_csv("data/processed/trips_post_pause.csv", show_col_types = FALSE) %>%
  mutate(date = as.Date(date)) %>%
  arrange(date)

# ---------------------------------------------------------
# 2. Log transformation
# ---------------------------------------------------------
trips <- trips %>%
  mutate(
    log_taxi = log(taxi_trips),
    log_fhv  = log(fhv_trips)
  )

# ---------------------------------------------------------
# 3. First difference (remove trend)
# ---------------------------------------------------------
trips <- trips %>%
  mutate(
    d1_taxi = c(NA, diff(log_taxi)),
    d1_fhv  = c(NA, diff(log_fhv))
  )

# ---------------------------------------------------------
# 4. Seasonal difference (lag 7)
# ---------------------------------------------------------
trips <- trips %>%
  mutate(
    d7_taxi = dplyr::lag(d1_taxi, 7),
    d7_fhv  = dplyr::lag(d1_fhv, 7)
  ) %>%
  mutate(
    final_taxi = d1_taxi - d7_taxi,
    final_fhv  = d1_fhv - d7_fhv
  )

# ---------------------------------------------------------
# 5. Remove NA rows
# ---------------------------------------------------------
trips_clean <- trips %>%
  filter(!is.na(final_taxi), !is.na(final_fhv))

write_csv(trips_clean, "data/processed/trips_stationary.csv")

# ---------------------------------------------------------
# 6. Plot raw vs log
# ---------------------------------------------------------
p1 <- ggplot(trips, aes(x = date)) +
  geom_line(aes(y = taxi_trips, color = "Taxi"), linewidth = 0.9) +
  geom_line(aes(y = fhv_trips, color = "FHV"), linewidth = 0.9) +
  labs(
    title = "Raw Daily Trip Series",
    subtitle = "Post-PAUSE sample",
    x = NULL,
    y = "Trips",
    color = "Service Type"
  ) +
  scale_color_manual(values = c("Taxi" = taxi_col, "FHV" = fhv_col)) +
  project_theme()

ggsave("figures/05_raw_series.png", p1, width = 10, height = 5, dpi = 300)

p2 <- ggplot(trips, aes(x = date)) +
  geom_line(aes(y = log_taxi, color = "Taxi"), linewidth = 0.9) +
  geom_line(aes(y = log_fhv, color = "FHV"), linewidth = 0.9) +
  labs(
    title = "Log-Transformed Series",
    subtitle = "Variance-stabilized mobility demand",
    x = NULL,
    y = "Log trips",
    color = "Service Type"
  ) +
  scale_color_manual(values = c("Taxi" = taxi_col, "FHV" = fhv_col)) +
  project_theme()

ggsave("figures/06_log_series.png", p2, width = 10, height = 5, dpi = 300)
# ---------------------------------------------------------
# 7. Plot differenced series
# ---------------------------------------------------------
p3 <- ggplot(trips_clean, aes(x = date)) +
  geom_line(aes(y = final_taxi, color = "Taxi"), linewidth = 0.9) +
  geom_line(aes(y = final_fhv, color = "FHV"), linewidth = 0.9) +
  labs(
    title = "Stationary Series",
    subtitle = "Log-transformed, differenced, and seasonally differenced series",
    x = NULL,
    y = "Differenced log-trips",
    color = "Service Type"
  ) +
  scale_color_manual(values = c("Taxi" = taxi_col, "FHV" = fhv_col)) +
  project_theme()

ggsave("figures/07_stationary_series.png", p3, width = 10, height = 5, dpi = 300)
cat("Script 03 completed successfully.\n")
cat("Final observations:", nrow(trips_clean), "\n")