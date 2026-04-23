# =========================================================
# 06_arma_modeling.R
# Fit ARMA models + model selection + diagnostics
# =========================================================

rm(list = ls())

required_packages <- c(
  "readr",
  "dplyr",
  "forecast",
  "tseries"
)

installed <- rownames(installed.packages())
for (pkg in required_packages) {
  if (!(pkg %in% installed)) install.packages(pkg)
  library(pkg, character.only = TRUE)
}

dir.create("data/processed", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

# ---------------------------------------------------------
# 1. Load stationary data
# ---------------------------------------------------------
trips <- read_csv("data/processed/trips_stationary.csv", show_col_types = FALSE)

taxi <- trips$final_taxi
fhv  <- trips$final_fhv

# ---------------------------------------------------------
# 2. Candidate ARMA models
# ---------------------------------------------------------
models <- list(
  c(1,1),
  c(2,1),
  c(1,2),
  c(2,2)
)

# ---------------------------------------------------------
# 3. Function to fit models and store metrics
# ---------------------------------------------------------
fit_models <- function(series, name) {
  
  results <- data.frame()
  fitted_models <- list()
  
  for (m in models) {
    p <- m[1]
    q <- m[2]
    
    fit <- try(arima(series, order = c(p, 0, q)), silent = TRUE)
    
    if (!inherits(fit, "try-error")) {
      
      aic <- AIC(fit)
      bic <- BIC(fit)
      
      # Ljung-Box test on residuals
      lb <- Box.test(fit$residuals, lag = 20, type = "Ljung-Box")
      
      results <- rbind(results, data.frame(
        model = paste0("ARMA(", p, ",", q, ")"),
        AIC = aic,
        BIC = bic,
        LjungBox_p = lb$p.value
      ))
      
      fitted_models[[paste0("ARMA(", p, ",", q, ")")]] <- fit
    }
  }
  
  results <- results %>% arrange(AIC)
  
  cat("\n====================", name, "====================\n")
  print(results)
  
  # Best model
  best_model_name <- results$model[1]
  best_model <- fitted_models[[best_model_name]]
  
  cat("\nBest model for", name, ":", best_model_name, "\n")
  
  return(list(results = results, best_model = best_model))
}

# ---------------------------------------------------------
# 4. Fit models
# ---------------------------------------------------------
taxi_fit <- fit_models(taxi, "Taxi")
fhv_fit  <- fit_models(fhv, "FHV")

# ---------------------------------------------------------
# 5. Save results
# ---------------------------------------------------------
write.csv(taxi_fit$results, "data/processed/arma_results_taxi.csv", row.names = FALSE)
write.csv(fhv_fit$results,  "data/processed/arma_results_fhv.csv", row.names = FALSE)

# ---------------------------------------------------------
# 6. Residual diagnostics (best models)
# ---------------------------------------------------------
png("figures/12_residuals_taxi.png", width = 800, height = 500)
ts.plot(taxi_fit$best_model$residuals, main = "Residuals - Taxi")
dev.off()

png("figures/13_residuals_fhv.png", width = 800, height = 500)
ts.plot(fhv_fit$best_model$residuals, main = "Residuals - FHV")
dev.off()

# ACF of residuals
png("figures/14_residuals_acf_taxi.png", width = 800, height = 500)
acf(taxi_fit$best_model$residuals, main = "ACF Residuals - Taxi")
dev.off()

png("figures/15_residuals_acf_fhv.png", width = 800, height = 500)
acf(fhv_fit$best_model$residuals, main = "ACF Residuals - FHV")
dev.off()

cat("\nScript 06 completed successfully.\n")