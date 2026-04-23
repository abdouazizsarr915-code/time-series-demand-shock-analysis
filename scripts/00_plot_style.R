library(ggplot2)

# Core colors
taxi_col     <- "#D89C00"
fhv_col      <- "#1F77B4"
actual_col   <- "#F26B5E"
forecast_col <- "#0F9D9A"
band_col     <- "grey70"

vol_taxi_col <- "#B57F00"
vol_fhv_col  <- "#1769AA"

project_theme <- function() {
  theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 18),
      plot.subtitle = element_text(size = 12, colour = "grey30"),
      axis.title = element_text(face = "bold"),
      legend.title = element_text(face = "bold"),
      panel.grid.minor = element_blank()
    )
}