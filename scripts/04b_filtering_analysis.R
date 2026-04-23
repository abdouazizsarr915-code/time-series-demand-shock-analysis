# =========================================================
# 04b_filtering_analysis.R
# Filtering analysis:
# Moving Average (q=7, q=30) + Simple Exponential Smoothing
# =========================================================

rm(list = ls())

required_packages <- c(
  "readr",
  "dplyr",
  "ggplot2",
  "forecast",
  "zoo",
  "tidyr",
  "patchwork"
)

installed <- rownames(installed.packages())
for (pkg in required_packages) {
  if (!(pkg %in% installed)) install.packages(pkg)
  library(pkg, character.only = TRUE)
}

source("scripts/00_plot_style.R")

dir.create("figures", showWarnings = FALSE)
dir.create("data/processed", showWarnings = FALSE)

# ---------------------------------------------------------
# 1. Load post-PAUSE data
# ---------------------------------------------------------
trips <- read_csv("data/processed/trips_post_pause.csv", show_col_types = FALSE) %>%
  mutate(date = as.Date(date)) %>%
  arrange(date)

# log transform
trips <- trips %>%
  mutate(
    log_taxi = log(taxi_trips),
    log_fhv  = log(fhv_trips)
  )

# ---------------------------------------------------------
# 2. Moving average filters
# ---------------------------------------------------------
q1 <- 7
q2 <- 30

trips <- trips %>%
  mutate(
    taxi_ma_7  = zoo::rollmean(log_taxi, k = q1, fill = NA, align = "center"),
    taxi_ma_30 = zoo::rollmean(log_taxi, k = q2, fill = NA, align = "center"),
    fhv_ma_7   = zoo::rollmean(log_fhv,  k = q1, fill = NA, align = "center"),
    fhv_ma_30  = zoo::rollmean(log_fhv,  k = q2, fill = NA, align = "center")
  )

# residuals
trips <- trips %>%
  mutate(
    taxi_resid_ma_7  = log_taxi - taxi_ma_7,
    taxi_resid_ma_30 = log_taxi - taxi_ma_30,
    fhv_resid_ma_7   = log_fhv - fhv_ma_7,
    fhv_resid_ma_30  = log_fhv - fhv_ma_30
  )

# ---------------------------------------------------------
# 3. Simple exponential smoothing
# ---------------------------------------------------------
# ---------------------------------------------------------
# 3. Simple exponential smoothing
# ---------------------------------------------------------
ses_taxi <- ses(trips$log_taxi, h = 1)
ses_fhv  <- ses(trips$log_fhv,  h = 1)

trips$taxi_ses <- as.numeric(ses_taxi$fitted)
trips$fhv_ses  <- as.numeric(ses_fhv$fitted)

trips <- trips %>%
  mutate(
    taxi_resid_ses = log_taxi - taxi_ses,
    fhv_resid_ses  = log_fhv - fhv_ses
  )
# ---------------------------------------------------------
# 4. Moving average plots
# ---------------------------------------------------------
taxi_ma_df <- trips %>%
  select(date, log_taxi, taxi_ma_7, taxi_ma_30) %>%
  pivot_longer(-date, names_to = "series", values_to = "value")

fhv_ma_df <- trips %>%
  select(date, log_fhv, fhv_ma_7, fhv_ma_30) %>%
  pivot_longer(-date, names_to = "series", values_to = "value")

p_ma_taxi <- ggplot(taxi_ma_df, aes(x = date, y = value, color = series)) +
  geom_line(linewidth = 0.8) +
  labs(
    title = "Taxi — Moving Average Filters",
    subtitle = "Original log-series with q = 7 and q = 30 smoothers",
    x = NULL,
    y = "Log trips",
    color = NULL
  ) +
  scale_color_manual(values = c(
    "log_taxi" = taxi_col,
    "taxi_ma_7" = forecast_col,
    "taxi_ma_30" = "grey40"
  )) +
  project_theme()

p_ma_fhv <- ggplot(fhv_ma_df, aes(x = date, y = value, color = series)) +
  geom_line(linewidth = 0.8) +
  labs(
    title = "FHV — Moving Average Filters",
    subtitle = "Original log-series with q = 7 and q = 30 smoothers",
    x = NULL,
    y = "Log trips",
    color = NULL
  ) +
  scale_color_manual(values = c(
    "log_fhv" = fhv_col,
    "fhv_ma_7" = forecast_col,
    "fhv_ma_30" = "grey40"
  )) +
  project_theme()

# ---------------------------------------------------------
# 5. SES plots
# ---------------------------------------------------------
taxi_ses_df <- trips %>%
  select(date, log_taxi, taxi_ses) %>%
  pivot_longer(-date, names_to = "series", values_to = "value")

fhv_ses_df <- trips %>%
  select(date, log_fhv, fhv_ses) %>%
  pivot_longer(-date, names_to = "series", values_to = "value")

p_ses_taxi <- ggplot(taxi_ses_df, aes(x = date, y = value, color = series)) +
  geom_line(linewidth = 0.8) +
  labs(
    title = "Taxi — Simple Exponential Smoothing",
    subtitle = "Original log-series and SES signal",
    x = NULL,
    y = "Log trips",
    color = NULL
  ) +
  scale_color_manual(values = c(
    "log_taxi" = taxi_col,
    "taxi_ses" = forecast_col
  )) +
  project_theme()

p_ses_fhv <- ggplot(fhv_ses_df, aes(x = date, y = value, color = series)) +
  geom_line(linewidth = 0.8) +
  labs(
    title = "FHV — Simple Exponential Smoothing",
    subtitle = "Original log-series and SES signal",
    x = NULL,
    y = "Log trips",
    color = NULL
  ) +
  scale_color_manual(values = c(
    "log_fhv" = fhv_col,
    "fhv_ses" = forecast_col
  )) +
  project_theme()

# ---------------------------------------------------------
# 6. Residual plots
# ---------------------------------------------------------
taxi_resid_df <- trips %>%
  select(date, taxi_resid_ma_7, taxi_resid_ma_30, taxi_resid_ses) %>%
  pivot_longer(-date, names_to = "type", values_to = "resid")

fhv_resid_df <- trips %>%
  select(date, fhv_resid_ma_7, fhv_resid_ma_30, fhv_resid_ses) %>%
  pivot_longer(-date, names_to = "type", values_to = "resid")

p_resid_taxi <- ggplot(taxi_resid_df, aes(x = date, y = resid, color = type)) +
  geom_line(linewidth = 0.7) +
  labs(
    title = "Taxi — Filter Residuals",
    subtitle = "Residuals from MA and SES filters",
    x = NULL,
    y = "Residual",
    color = NULL
  ) +
  scale_color_manual(values = c(
    "taxi_resid_ma_7" = taxi_col,
    "taxi_resid_ma_30" = "grey40",
    "taxi_resid_ses" = forecast_col
  )) +
  project_theme()

p_resid_fhv <- ggplot(fhv_resid_df, aes(x = date, y = resid, color = type)) +
  geom_line(linewidth = 0.7) +
  labs(
    title = "FHV — Filter Residuals",
    subtitle = "Residuals from MA and SES filters",
    x = NULL,
    y = "Residual",
    color = NULL
  ) +
  scale_color_manual(values = c(
    "fhv_resid_ma_7" = fhv_col,
    "fhv_resid_ma_30" = "grey40",
    "fhv_resid_ses" = forecast_col
  )) +
  project_theme()

# ---------------------------------------------------------
# 7. Residual distributions
# ---------------------------------------------------------
resid_dist_df <- bind_rows(
  trips %>% transmute(service = "Taxi", method = "MA(7)", resid = taxi_resid_ma_7),
  trips %>% transmute(service = "Taxi", method = "MA(30)", resid = taxi_resid_ma_30),
  trips %>% transmute(service = "Taxi", method = "SES", resid = taxi_resid_ses),
  trips %>% transmute(service = "FHV", method = "MA(7)", resid = fhv_resid_ma_7),
  trips %>% transmute(service = "FHV", method = "MA(30)", resid = fhv_resid_ma_30),
  trips %>% transmute(service = "FHV", method = "SES", resid = fhv_resid_ses)
)

p_resid_dist <- ggplot(resid_dist_df, aes(x = resid, fill = service)) +
  geom_histogram(alpha = 0.75, bins = 30, position = "identity") +
  facet_grid(method ~ service, scales = "free") +
  labs(
    title = "Residual Distribution Comparison",
    subtitle = "Moving average vs exponential smoothing residuals",
    x = "Residual value",
    y = "Frequency",
    fill = "Service"
  ) +
  scale_fill_manual(values = c("Taxi" = taxi_col, "FHV" = fhv_col)) +
  project_theme()

# ---------------------------------------------------------
# 8. Save figures
# ---------------------------------------------------------
ggsave("figures/08b_ma_taxi.png", p_ma_taxi, width = 10, height = 5, dpi = 300)
ggsave("figures/08c_ma_fhv.png", p_ma_fhv, width = 10, height = 5, dpi = 300)
ggsave("figures/08d_ses_taxi.png", p_ses_taxi, width = 10, height = 5, dpi = 300)
ggsave("figures/08e_ses_fhv.png", p_ses_fhv, width = 10, height = 5, dpi = 300)
ggsave("figures/08f_resid_taxi.png", p_resid_taxi, width = 10, height = 5, dpi = 300)
ggsave("figures/08g_resid_fhv.png", p_resid_fhv, width = 10, height = 5, dpi = 300)
ggsave("figures/08h_resid_distribution_comparison.png", p_resid_dist, width = 14, height = 9, dpi = 300)

# ---------------------------------------------------------
# 9. Save alpha values from SES
# ---------------------------------------------------------
alpha_table <- data.frame(
  series = c("Taxi", "FHV"),
  alpha = c(ses_taxi$model$par["alpha"], ses_fhv$model$par["alpha"])
)

write_csv(alpha_table, "data/processed/filtering_alpha_values.csv")

cat("Script 04b completed successfully.\n")