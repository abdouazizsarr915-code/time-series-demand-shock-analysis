# =========================================================
# 02_post_pause_sample.R
# Remove the structural break period and create post-PAUSE sample
# =========================================================

rm(list = ls())

required_packages <- c(
  "dplyr",
  "readr",
  "ggplot2",
  "tidyr",
  "lubridate"
)
source("scripts/00_plot_style.R")
installed <- rownames(installed.packages())
for (pkg in required_packages) {
  if (!(pkg %in% installed)) install.packages(pkg)
  library(pkg, character.only = TRUE)
}

dir.create("data", showWarnings = FALSE)
dir.create("data/processed", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

# ---------------------------------------------------------
# 1. Load processed data from Script 01
# ---------------------------------------------------------
trips_daily <- read_csv("data/processed/trips_daily.csv", show_col_types = FALSE) %>%
  mutate(date = as.Date(date))

trips_long <- read_csv("data/processed/trips_long.csv", show_col_types = FALSE) %>%
  mutate(date = as.Date(date))

# ---------------------------------------------------------
# 2. Define PAUSE cutoff
# PAUSE starts March 22, 2020 at 8PM
# We treat March 22 as transitional and keep data from March 23 onward
# ---------------------------------------------------------
pause_transition_date <- as.Date("2020-03-22")
post_pause_start      <- as.Date("2020-03-23")

# ---------------------------------------------------------
# 3. Create post-PAUSE datasets
# ---------------------------------------------------------
trips_post_pause <- trips_daily %>%
  filter(date >= post_pause_start) %>%
  arrange(date)

trips_post_pause_long <- trips_long %>%
  filter(date >= post_pause_start) %>%
  arrange(date)

# ---------------------------------------------------------
# 4. Save processed post-PAUSE data
# ---------------------------------------------------------
write_csv(trips_post_pause,      "data/processed/trips_post_pause.csv")
write_csv(trips_post_pause_long, "data/processed/trips_post_pause_long.csv")

# ---------------------------------------------------------
# 5. Summary table: full year vs post-PAUSE
# ---------------------------------------------------------
summary_full <- trips_daily %>%
  summarise(
    sample = "Full Year (2020)",
    taxi_mean = mean(taxi_trips, na.rm = TRUE),
    fhv_mean  = mean(fhv_trips, na.rm = TRUE),
    taxi_sd   = sd(taxi_trips, na.rm = TRUE),
    fhv_sd    = sd(fhv_trips, na.rm = TRUE),
    taxi_min  = min(taxi_trips, na.rm = TRUE),
    fhv_min   = min(fhv_trips, na.rm = TRUE),
    taxi_median = median(taxi_trips, na.rm = TRUE),
    fhv_median  = median(fhv_trips, na.rm = TRUE),
    taxi_max  = max(taxi_trips, na.rm = TRUE),
    fhv_max   = max(fhv_trips, na.rm = TRUE),
    taxi_total = sum(taxi_trips, na.rm = TRUE),
    fhv_total  = sum(fhv_trips, na.rm = TRUE),
    n_days = n()
  )

summary_post <- trips_post_pause %>%
  summarise(
    sample = "Post-PAUSE (2020-03-23 onward)",
    taxi_mean = mean(taxi_trips, na.rm = TRUE),
    fhv_mean  = mean(fhv_trips, na.rm = TRUE),
    taxi_sd   = sd(taxi_trips, na.rm = TRUE),
    fhv_sd    = sd(fhv_trips, na.rm = TRUE),
    taxi_min  = min(taxi_trips, na.rm = TRUE),
    fhv_min   = min(fhv_trips, na.rm = TRUE),
    taxi_median = median(taxi_trips, na.rm = TRUE),
    fhv_median  = median(fhv_trips, na.rm = TRUE),
    taxi_max  = max(taxi_trips, na.rm = TRUE),
    fhv_max   = max(fhv_trips, na.rm = TRUE),
    taxi_total = sum(taxi_trips, na.rm = TRUE),
    fhv_total  = sum(fhv_trips, na.rm = TRUE),
    n_days = n()
  )

summary_comparison <- bind_rows(summary_full, summary_post)
print(summary_comparison)

write_csv(summary_comparison, "data/processed/summary_full_vs_post_pause.csv")

# ---------------------------------------------------------
# 6. Plot 1: Full year with PAUSE marker
# ---------------------------------------------------------
p1 <- ggplot(trips_long, aes(x = date, y = trips / 1000, color = service_type)) +
  geom_line(linewidth = 0.9) +
  geom_vline(xintercept = as.numeric(pause_transition_date), linetype = "dashed", linewidth = 0.9, colour = "grey35") +
  annotate(
    "text",
    x = pause_transition_date + 12,
    y = max(trips_long$trips, na.rm = TRUE) / 1000 * 0.93,
    label = "NY PAUSE Lockdown\n(March 22, 2020)",
    hjust = 0,
    size = 4,
    colour = "grey20"
  ) +
  labs(
    title = "NYC Trip Frequency (2020)",
    subtitle = "Yellow Taxi vs. For-Hire Vehicles with PAUSE structural break",
    x = NULL,
    y = "Trips (thousands)",
    color = "Service Type"
  ) +
  scale_color_manual(values = c("Taxi" = taxi_col, "FHV" = fhv_col)) +
  project_theme()

ggsave(
  filename = "figures/02_full_year_with_pause_marker.png",
  plot = p1,
  width = 11,
  height = 6,
  dpi = 300
)

# ---------------------------------------------------------
# 7. Plot 2: Post-PAUSE time series
# ---------------------------------------------------------
p2 <- ggplot(trips_post_pause_long, aes(x = date, y = trips / 1000, color = service_type)) +
  geom_line(linewidth = 0.9) +
  labs(
    title = "NYC Trip Frequency (Post-PAUSE)",
    subtitle = "Daily trips from March 23, 2020 onward",
    x = NULL,
    y = "Trips (thousands)",
    color = "Service Type"
  ) +
  scale_color_manual(values = c("Taxi" = taxi_col, "FHV" = fhv_col)) +
  project_theme()

ggsave(
  filename = "figures/03_post_pause_trip_series.png",
  plot = p2,
  width = 11,
  height = 6,
  dpi = 300
)

# ---------------------------------------------------------
# 8. Plot 3: Monthly boxplots post-PAUSE
# ---------------------------------------------------------
trips_post_pause_long <- trips_post_pause_long %>%
  mutate(month = month(date, label = TRUE, abbr = TRUE))

p3 <- ggplot(trips_post_pause_long, aes(x = month, y = trips / 1000, fill = service_type)) +
  geom_boxplot(alpha = 0.75, outlier.alpha = 0.35) +
  facet_wrap(~service_type, scales = "free_y") +
  labs(
    title = "Post-PAUSE Monthly Variation",
    subtitle = "Distribution of daily trips by month",
    x = "Month",
    y = "Trips (thousands)",
    fill = "Service Type"
  ) +
  scale_fill_manual(values = c("Taxi" = taxi_col, "FHV" = fhv_col)) +
  project_theme() +
  theme(legend.position = "none")

ggsave(
  filename = "figures/04_post_pause_monthly_boxplots.png",
  plot = p3,
  width = 11,
  height = 6,
  dpi = 300
)

cat("Script 02 completed successfully.\n")
cat("Post-PAUSE observations:", nrow(trips_post_pause), "\n")