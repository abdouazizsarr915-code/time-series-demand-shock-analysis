# =========================================================
# 07_forecasting.R
# Train/test forecasting with ARMA models
# =========================================================

rm(list = ls())

required_packages <- c(
  "readr",
  "dplyr",
  "forecast",
  "ggplot2"
)

installed <- rownames(installed.packages())
for (pkg in required_packages) {
  if (!(pkg %in% installed)) install.packages(pkg)
  library(pkg, character.only = TRUE)
}

dir.create("data/processed", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)
source("scripts/00_plot_style.R")

# ---------------------------------------------------------
# 1. Load stationary data
# ---------------------------------------------------------
trips <- read_csv("data/processed/trips_stationary.csv", show_col_types = FALSE)

taxi <- trips$final_taxi
fhv  <- trips$final_fhv
dates <- as.Date(trips$date)

# ---------------------------------------------------------
# 2. Train / test split
# ---------------------------------------------------------
n <- nrow(trips)
test_size <- 30
train_size <- n - test_size

taxi_train <- taxi[1:train_size]
taxi_test  <- taxi[(train_size + 1):n]

fhv_train <- fhv[1:train_size]
fhv_test  <- fhv[(train_size + 1):n]

test_dates <- dates[(train_size + 1):n]

# ---------------------------------------------------------
# 3. Candidate models
# ---------------------------------------------------------
candidate_orders <- list(
  c(1, 0, 1),
  c(2, 0, 1),
  c(1, 0, 2),
  c(2, 0, 2)
)

# ---------------------------------------------------------
# 4. Function to select best forecast model on training set
# ---------------------------------------------------------
select_best_arma <- function(series, series_name) {
  results <- data.frame()
  model_store <- list()
  
  for (ord in candidate_orders) {
    p <- ord[1]
    d <- ord[2]
    q <- ord[3]
    
    fit <- try(arima(series, order = c(p, d, q)), silent = TRUE)
    
    if (!inherits(fit, "try-error")) {
      results <- rbind(
        results,
        data.frame(
          model = paste0("ARMA(", p, ",", q, ")"),
          AIC = AIC(fit),
          BIC = BIC(fit)
        )
      )
      model_store[[paste0("ARMA(", p, ",", q, ")")]] <- fit
    }
  }
  
  results <- results %>% arrange(AIC)
  best_name <- results$model[1]
  best_fit <- model_store[[best_name]]
  
  cat("\n====================", series_name, "====================\n")
  print(results)
  cat("Best model:", best_name, "\n")
  
  list(results = results, best_fit = best_fit, best_name = best_name)
}

# ---------------------------------------------------------
# 5. Select best models
# ---------------------------------------------------------
taxi_model <- select_best_arma(taxi_train, "Taxi")
fhv_model  <- select_best_arma(fhv_train, "FHV")

write.csv(taxi_model$results, "data/processed/forecast_model_selection_taxi.csv", row.names = FALSE)
write.csv(fhv_model$results,  "data/processed/forecast_model_selection_fhv.csv", row.names = FALSE)

# ---------------------------------------------------------
# 6. Forecast 30 steps ahead
# ---------------------------------------------------------
taxi_fc <- predict(taxi_model$best_fit, n.ahead = test_size)
fhv_fc  <- predict(fhv_model$best_fit,  n.ahead = test_size)

taxi_forecast <- taxi_fc$pred
taxi_se       <- taxi_fc$se

fhv_forecast <- fhv_fc$pred
fhv_se       <- fhv_fc$se

# 95% intervals
taxi_lower <- taxi_forecast - 1.96 * taxi_se
taxi_upper <- taxi_forecast + 1.96 * taxi_se

fhv_lower <- fhv_forecast - 1.96 * fhv_se
fhv_upper <- fhv_forecast + 1.96 * fhv_se

# ---------------------------------------------------------
# 7. Accuracy metrics
# ---------------------------------------------------------
forecast_metrics <- function(actual, predicted) {
  mse <- mean((actual - predicted)^2)
  rmse <- sqrt(mse)
  mae <- mean(abs(actual - predicted))
  tibble(MSE = mse, RMSE = rmse, MAE = mae)
}

taxi_metrics <- forecast_metrics(taxi_test, taxi_forecast) %>%
  mutate(series = "Taxi", model = taxi_model$best_name)

fhv_metrics <- forecast_metrics(fhv_test, fhv_forecast) %>%
  mutate(series = "FHV", model = fhv_model$best_name)

metrics_all <- bind_rows(taxi_metrics, fhv_metrics) %>%
  select(series, model, MSE, RMSE, MAE)

print(metrics_all)
write.csv(metrics_all, "data/processed/forecast_accuracy_metrics.csv", row.names = FALSE)

# ---------------------------------------------------------
# 8. Forecast data frames for plotting
# ---------------------------------------------------------
taxi_plot_df <- tibble(
  date = test_dates,
  actual = taxi_test,
  forecast = taxi_forecast,
  lower = taxi_lower,
  upper = taxi_upper
)

fhv_plot_df <- tibble(
  date = test_dates,
  actual = fhv_test,
  forecast = fhv_forecast,
  lower = fhv_lower,
  upper = fhv_upper
)

# ---------------------------------------------------------
# 9. Plot forecasts
# ---------------------------------------------------------
p_taxi <- ggplot(taxi_plot_df, aes(x = date)) +
  geom_ribbon(aes(ymin = lower, ymax = upper), fill = band_col, alpha = 0.25) +
  geom_line(aes(y = actual, color = "Actual"), linewidth = 1) +
  geom_line(aes(y = forecast, color = "Forecast"), linewidth = 1, linetype = "dashed") +
  labs(
    title = paste("Taxi Forecast vs Actual -", taxi_model$best_name),
    subtitle = "30-step ahead forecast on stationary series",
    x = NULL,
    y = "Differenced log-trips",
    color = NULL
  ) +
  scale_color_manual(values = c("Actual" = actual_col, "Forecast" = forecast_col)) +
  project_theme()

ggsave(
  filename = "figures/16_forecast_taxi.png",
  plot = p_taxi,
  width = 10,
  height = 5,
  dpi = 300
)

p_fhv <- ggplot(fhv_plot_df, aes(x = date)) +
  geom_ribbon(aes(ymin = lower, ymax = upper), fill = band_col, alpha = 0.25) +
  geom_line(aes(y = actual, color = "Actual"), linewidth = 1) +
  geom_line(aes(y = forecast, color = "Forecast"), linewidth = 1, linetype = "dashed") +
  labs(
    title = paste("FHV Forecast vs Actual -", fhv_model$best_name),
    subtitle = "30-step ahead forecast on stationary series",
    x = NULL,
    y = "Differenced log-trips",
    color = NULL
  ) +
  scale_color_manual(values = c("Actual" = actual_col, "Forecast" = forecast_col)) +
  project_theme()

ggsave(
  filename = "figures/17_forecast_fhv.png",
  plot = p_fhv,
  width = 10,
  height = 5,
  dpi = 300
)

cat("\nScript 07 completed successfully.\n")