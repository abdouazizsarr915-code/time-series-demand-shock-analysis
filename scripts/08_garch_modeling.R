# =========================================================
# 08_garch_modeling.R
# ARMA + GARCH modeling with proper date-based plots
# =========================================================

rm(list = ls())

required_packages <- c(
  "readr",
  "dplyr",
  "rugarch",
  "ggplot2"
)

installed <- rownames(installed.packages())
for (pkg in required_packages) {
  if (!(pkg %in% installed)) install.packages(pkg)
  library(pkg, character.only = TRUE)
}

dir.create("figures", showWarnings = FALSE)
dir.create("data/processed", showWarnings = FALSE)

# ---------------------------------------------------------
# 1. Load stationary data
# ---------------------------------------------------------
trips <- read_csv("data/processed/trips_stationary.csv", show_col_types = FALSE) %>%
  mutate(date = as.Date(date))

taxi <- trips$final_taxi
fhv  <- trips$final_fhv
dates <- trips$date

# ---------------------------------------------------------
# 2. Define GARCH specifications
# Using the ARMA orders selected earlier
# Taxi: ARMA(2,1)
# FHV : ARMA(1,2)
# ---------------------------------------------------------
spec_taxi <- ugarchspec(
  variance.model = list(model = "sGARCH", garchOrder = c(1, 1)),
  mean.model = list(armaOrder = c(2, 1), include.mean = TRUE),
  distribution.model = "norm"
)

spec_fhv <- ugarchspec(
  variance.model = list(model = "sGARCH", garchOrder = c(1, 1)),
  mean.model = list(armaOrder = c(1, 2), include.mean = TRUE),
  distribution.model = "norm"
)

# ---------------------------------------------------------
# 3. Fit GARCH models
# ---------------------------------------------------------
fit_taxi <- ugarchfit(spec = spec_taxi, data = taxi, solver = "hybrid")
fit_fhv  <- ugarchfit(spec = spec_fhv,  data = fhv,  solver = "hybrid")

cat("\n===== TAXI GARCH MODEL =====\n")
show(fit_taxi)

cat("\n===== FHV GARCH MODEL =====\n")
show(fit_fhv)

# ---------------------------------------------------------
# 4. Extract conditional volatility
# ---------------------------------------------------------
vol_taxi <- as.numeric(sigma(fit_taxi))
vol_fhv  <- as.numeric(sigma(fit_fhv))

vol_taxi_df <- data.frame(
  date = dates,
  volatility = vol_taxi
)

vol_fhv_df <- data.frame(
  date = dates,
  volatility = vol_fhv
)

# ---------------------------------------------------------
# 5. Plot historical conditional volatility
# ---------------------------------------------------------
p_vol_taxi <- ggplot(vol_taxi_df, aes(x = date, y = volatility)) +
  geom_line(linewidth = 0.7) +
  labs(
    title = "Taxi Conditional Volatility (GARCH)",
    x = NULL,
    y = "Volatility"
  ) +
  theme_minimal()

ggsave(
  filename = "figures/18_volatility_taxi.png",
  plot = p_vol_taxi,
  width = 10,
  height = 5,
  dpi = 300
)

p_vol_fhv <- ggplot(vol_fhv_df, aes(x = date, y = volatility)) +
  geom_line(linewidth = 0.7) +
  labs(
    title = "FHV Conditional Volatility (GARCH)",
    x = NULL,
    y = "Volatility"
  ) +
  theme_minimal()

ggsave(
  filename = "figures/19_volatility_fhv.png",
  plot = p_vol_fhv,
  width = 10,
  height = 5,
  dpi = 300
)

# ---------------------------------------------------------
# 6. Forecast future volatility
# ---------------------------------------------------------
n_ahead <- 30

fc_taxi <- ugarchforecast(fit_taxi, n.ahead = n_ahead)
fc_fhv  <- ugarchforecast(fit_fhv,  n.ahead = n_ahead)

vol_fc_taxi <- as.numeric(sigma(fc_taxi))
vol_fc_fhv  <- as.numeric(sigma(fc_fhv))

future_dates <- seq(from = max(dates) + 1, by = "day", length.out = n_ahead)

vol_fc_taxi_df <- data.frame(
  date = future_dates,
  volatility = vol_fc_taxi
)

vol_fc_fhv_df <- data.frame(
  date = future_dates,
  volatility = vol_fc_fhv
)

# ---------------------------------------------------------
# 7. Plot forecast volatility with real dates
# ---------------------------------------------------------
p_fc_taxi <- ggplot(vol_fc_taxi_df, aes(x = date, y = volatility)) +
  geom_line(linewidth = 0.7) +
  labs(
    title = "Forecast Volatility - Taxi",
    x = NULL,
    y = "Volatility"
  ) +
  theme_minimal()

ggsave(
  filename = "figures/20_forecast_volatility_taxi.png",
  plot = p_fc_taxi,
  width = 10,
  height = 5,
  dpi = 300
)

p_fc_fhv <- ggplot(vol_fc_fhv_df, aes(x = date, y = volatility)) +
  geom_line(linewidth = 0.7) +
  labs(
    title = "Forecast Volatility - FHV",
    x = NULL,
    y = "Volatility"
  ) +
  theme_minimal()

ggsave(
  filename = "figures/21_forecast_volatility_fhv.png",
  plot = p_fc_fhv,
  width = 10,
  height = 5,
  dpi = 300
)

# ---------------------------------------------------------
# 8. Save volatility outputs
# ---------------------------------------------------------
write_csv(vol_taxi_df, "data/processed/garch_volatility_taxi.csv")
write_csv(vol_fhv_df,  "data/processed/garch_volatility_fhv.csv")
write_csv(vol_fc_taxi_df, "data/processed/garch_forecast_volatility_taxi.csv")
write_csv(vol_fc_fhv_df,  "data/processed/garch_forecast_volatility_fhv.csv")

cat("\nScript 08 completed successfully.\n")