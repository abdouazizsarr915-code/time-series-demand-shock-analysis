# NYC Mobility Demand — Time Series Modeling and Volatility Analysis

End-to-end statistical analysis of urban mobility demand using ARMA and GARCH models, with a focus on structural breaks and post-shock dynamics.

---

## Overview

This project analyzes the dynamics of daily mobility demand in New York City using Yellow Taxi and For-Hire Vehicle (FHV) trip data.

The objective is to:

* understand how demand evolves over time,
* identify the impact of a major structural shock (COVID-19),
* model short-term behavior using time series techniques,
* and quantify uncertainty through volatility modeling.

---

## Data

* Source: NYC Taxi & Limousine Commission (TLC)
* Frequency: Daily aggregated trips
* Period: 2020
* Services:

  * Yellow Taxi
  * For-Hire Vehicles (Uber, Lyft, etc.)

---

## Structural Break

A major structural break occurs on March 22, 2020 (NYC lockdown).
All modeling is conducted on the post-shock period, where statistical properties are more stable.

![Full Year Demand with Structural Break](figures/main/02_full_year_with_pause_marker.png)

---

## Methodology

### Transformation

To ensure stationarity and stabilize variance, the following transformations are applied:

* Log transformation
* First-order differencing
* Seasonal differencing (weekly pattern, lag = 7)

---

### Stationarity Testing

Two complementary statistical tests are used:

* Augmented Dickey-Fuller (ADF)
* KPSS test

Results indicate:

* ADF rejects the null hypothesis of a unit root (p < 0.01)
* KPSS fails to reject stationarity

The transformed series is therefore considered stationary.

---

### Model Identification

Autocorrelation analysis (ACF and PACF) is used to determine model structure.

Selected models:

* Taxi: ARMA(2,1)
* FHV: ARMA(1,2)

---

### Forecasting

Short-term forecasts are generated on the stationary series and compared to observed values.

![Taxi Forecast vs Actual](figures/main/16b_forecast_taxi_levels.png)
![FHV Forecast vs Actual](figures/main/17b_forecast_fhv_levels.png)

The models capture general demand dynamics, but do not fully account for extreme shocks, which is a known limitation of linear time series models.

---

### Volatility Modeling

To model time-varying uncertainty, a GARCH(1,1) model is applied to the residuals.

![Taxi Volatility](figures/main/18_volatility_taxi.png)
![FHV Volatility](figures/main/19_volatility_fhv.png)

The results show clear evidence of volatility clustering and periods of elevated uncertainty following structural disruptions.

---

## Key Insights

* Mobility demand exhibits strong temporal dependence
* Structural shocks significantly alter the data-generating process
* ARMA models effectively capture baseline dynamics
* Volatility is time-varying and exhibits clustering behavior
* Taxi demand appears more sensitive to shocks than FHV demand

---

## Technical Stack

* Language: R
* Libraries: dplyr, ggplot2, forecast, tseries
* Methods: ARMA, GARCH, ADF, KPSS, ACF/PACF
* Workflow: Modular scripts and reproducible pipeline

---

## Reproducibility

To reproduce the full analysis:

```r
source("scripts/09_run_project.R")
```

All figures and processed datasets will be generated automatically.

---

## Project Structure

```
scripts/       # data processing, modeling, and analysis
data/          # raw and processed datasets
figures/       # main and diagnostic visualizations
report/        # written report (if included)
```

---

## Conclusion

This project demonstrates how combining mean dynamics (ARMA models) and variance dynamics (GARCH models) provides a more comprehensive understanding of real-world time series affected by structural shocks and uncertainty.

---

## Extensions

Potential extensions include:

* Seasonal models (SARIMA)
* Inclusion of exogenous variables (weather, policy indicators)
* Multivariate modeling (VAR, DCC-GARCH)
* Regime-switching approaches

---
