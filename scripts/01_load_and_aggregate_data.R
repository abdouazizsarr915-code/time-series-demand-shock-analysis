# =========================================================
# 01_load_and_aggregate_data.R
# Load pre-aggregated NYC Taxi and FHV trip data
# =========================================================

rm(list = ls())

required_packages <- c(
  "dplyr",
  "readr",
  "lubridate",
  "ggplot2",
  "tidyr"
)
source("scripts/00_plot_style.R")
installed <- rownames(installed.packages())
for (pkg in required_packages) {
  if (!(pkg %in% installed)) install.packages(pkg)
  library(pkg, character.only = TRUE)
}

dir.create("data", showWarnings = FALSE)
dir.create("data/raw", showWarnings = FALSE)
dir.create("data/processed", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

fhv_file  <- "data/raw/2020_For_Hire_Vehicles_Trip_Data.csv"
taxi_file <- "data/raw/2020_Yellow_Taxi_Trip_Data.csv"

fhv_raw  <- read_csv(fhv_file, show_col_types = FALSE)
taxi_raw <- read_csv(taxi_file, show_col_types = FALSE)

cat("FHV raw rows:", nrow(fhv_raw), "\n")
cat("Taxi raw rows:", nrow(taxi_raw), "\n")

cat("FHV columns:\n")
print(names(fhv_raw))
cat("Taxi columns:\n")
print(names(taxi_raw))

fhv_daily <- fhv_raw %>%
  rename(
    date = by_day_pickup_datetime,
    fhv_trips = trips
  ) %>%
  mutate(
    date = parse_date_time(date, orders = "Y b d I:M:S p"),
    date = as.Date(date)
  ) %>%
  arrange(date)

taxi_daily <- taxi_raw %>%
  rename(
    date = by_day_tpep_pickup_datetime,
    taxi_trips = trips
  ) %>%
  mutate(
    date = parse_date_time(date, orders = "Y b d I:M:S p"),
    date = as.Date(date)
  ) %>%
  arrange(date)

cat("Missing FHV dates:", sum(is.na(fhv_daily$date)), "\n")
cat("Missing Taxi dates:", sum(is.na(taxi_daily$date)), "\n")

trips_daily <- full_join(taxi_daily, fhv_daily, by = "date") %>%
  arrange(date) %>%
  mutate(
    taxi_trips = replace_na(taxi_trips, 0),
    fhv_trips  = replace_na(fhv_trips, 0)
  )

trips_long <- trips_daily %>%
  pivot_longer(
    cols = c(taxi_trips, fhv_trips),
    names_to = "service_type",
    values_to = "trips"
  ) %>%
  mutate(
    service_type = recode(
      service_type,
      "taxi_trips" = "Taxi",
      "fhv_trips"  = "FHV"
    )
  )

write_csv(trips_daily, "data/processed/trips_daily.csv")
write_csv(trips_long,  "data/processed/trips_long.csv")

summary_table <- trips_daily %>%
  summarise(
    taxi_mean = mean(taxi_trips, na.rm = TRUE),
    fhv_mean  = mean(fhv_trips, na.rm = TRUE),
    taxi_sd   = sd(taxi_trips, na.rm = TRUE),
    fhv_sd    = sd(fhv_trips, na.rm = TRUE),
    taxi_min  = min(taxi_trips, na.rm = TRUE),
    fhv_min   = min(fhv_trips, na.rm = TRUE),
    taxi_max  = max(taxi_trips, na.rm = TRUE),
    fhv_max   = max(fhv_trips, na.rm = TRUE),
    n_days    = n()
  )

print(summary_table)
p_full <- ggplot(trips_long, aes(x = date, y = trips / 1000, color = service_type)) +
  geom_line(linewidth = 0.9) +
  labs(
    title = "NYC Daily Trips in 2020",
    subtitle = "Yellow Taxi vs. For-Hire Vehicles",
    x = NULL,
    y = "Trips (thousands)",
    color = "Service Type"
  ) +
  scale_color_manual(values = c("Taxi" = taxi_col, "FHV" = fhv_col)) +
  project_theme()

ggsave(
  filename = "figures/01_full_year_trip_series.png",
  plot = p_full,
  width = 10,
  height = 5,
  dpi = 300
)
cat("Script 01 completed successfully.\n")