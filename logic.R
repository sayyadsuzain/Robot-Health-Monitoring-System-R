# logic.R
# Core analytical functions for Robot Health & RUL Prediction System

library(dplyr)  #data manipulation this is used to work with data frames easily and efficiently
library(readr)  #Reading data files this library is used to load data into R quickly and cleanly
library(tidyr)  #Data cleaning & Reshaping ..  this is used to make your data "tidy"( well structured)

# 1. LOAD DATA
load_cmapss_data <- function(data_folder = "data") {
  # Define filenames
  train_file <- file.path(data_folder, "train_FD001.txt")
  test_file <- file.path(data_folder, "test_FD001.txt")
  truth_file <- file.path(data_folder, "RUL_FD001.txt")
  
  if (!file.exists(train_file)) stop("Training data not found. Ensure .txt files are in the data/ folder.")
  
  # Column names for CMAPSS
  cols <- c("unit", "cycle", "setting_1", "setting_2", "setting_3", paste0("sensor_", 1:21))
  
  # Read files (space separated, no header)
  train_df <- read_delim(train_file, delim = " ", col_names = cols, show_col_types = FALSE)
  test_df <- read_delim(test_file, delim = " ", col_names = cols, show_col_types = FALSE)
  truth_df <- read_delim(truth_file, delim = " ", col_names = "true_rul", show_col_types = FALSE) %>%
    mutate(unit = row_number())
  
  return(list(train = train_df, test = test_df, truth = truth_df))
}

# 2. NORMALIZATION & HEALTH SCORE
calculate_health_score <- function(df) {
  # Normalize all 21 sensors
  # Formula: (val - min) / (max - min)
  for (i in 1:21) {
    s_name <- paste0("sensor_", i)
    n_name <- paste0("n_s", i)
    s_min <- min(df[[s_name]], na.rm = TRUE)
    s_max <- max(df[[s_name]], na.rm = TRUE)
    
    if (s_max == s_min) {
      df[[n_name]] <- 0 # Constant sensors get 0 penalty contribution
    } else {
      df[[n_name]] <- (df[[s_name]] - s_min) / (s_max - s_min)
    }
  }
  
  # Health Score based on the primary failing sensors (2, 4, 11) 
  # as per original project requirement, but now we have all n_s1 to n_s21 available.
  df %>%
    mutate(
      health_score = 100 - (50 * n_s2 + 30 * n_s4 + 20 * n_s11)
    )
}

# 3. RUL PREDICTION (Linear Regression & Baseline)
get_rul_predictions <- function(train_df, test_df) {
  # Add Current cycles and True RUL to training data
  train_full <- train_df %>%
    group_by(unit) %>%
    mutate(true_rul = max(cycle) - cycle) %>%
    ungroup() %>%
    calculate_health_score()
  
  # Train Calibrated model
  model <- lm(true_rul ~ health_score, data = train_full)
  
  # Predict for test engines at their LAST cycle
  test_last <- test_df %>%
    calculate_health_score() %>%
    group_by(unit) %>%
    filter(cycle == max(cycle)) %>%
    ungroup()
  
  # Calibrated Prediction
  test_last$estimated_cycles_left <- round(predict(model, test_last))
  
  # Ensure no negative RUL
  test_last$estimated_cycles_left <- pmax(test_last$estimated_cycles_left, 0)
  
  # Baseline Prediction (Simplified linear mapping 0-100 health to 0-200 cycles)
  test_last$baseline_rul <- round(test_last$health_score * 2.0)
  
  # Add Status based on calibrated percentiles
  thresholds <- quantile(test_last$estimated_cycles_left, probs = c(0.1, 0.25))
  
  test_last <- test_last %>%
    mutate(status = case_when(
      estimated_cycles_left == 0 ~ "FAILED",
      estimated_cycles_left <= thresholds[1] ~ "FAIL SOON",
      estimated_cycles_left <= thresholds[2] ~ "WARNING",
      TRUE ~ "HEALTHY"
    ))
  
  return(test_last)
}

# 3b. EVALUATION METRICS
get_eval_metrics <- function(preds, truth_df) {
  eval_df <- preds %>%
    inner_join(truth_df, by = c("unit")) %>%
    mutate(
      error_cal = estimated_cycles_left - true_rul,
      error_base = baseline_rul - true_rul
    )
  
  metrics <- list(
    calibrated = data.frame(
      Metric = c("MAE", "RMSE"),
      Value = c(round(mean(abs(eval_df$error_cal)), 2), round(sqrt(mean(eval_df$error_cal^2)), 2))
    ),
    baseline = data.frame(
      Metric = c("MAE", "RMSE"),
      Value = c(round(mean(abs(eval_df$error_base)), 2), round(sqrt(mean(eval_df$error_base^2)), 2))
    )
  )
  return(metrics)
}

# 4. DIAGNOSTICS
get_diagnostics <- function(df) {
  df %>%
    mutate(
      penalty_temp = 50 * n_s2,
      penalty_pressure = 30 * n_s4,
      penalty_vibration = 20 * n_s11,
      total_penalty = penalty_temp + penalty_pressure + penalty_vibration,
      damage_percent = round((total_penalty / 100) * 100, 1),
      failing_sensor = case_when(
        penalty_temp >= penalty_pressure & penalty_temp >= penalty_vibration ~ "Sensor 2 (High Temp)",
        penalty_pressure >= penalty_temp & penalty_pressure >= penalty_vibration ~ "Sensor 4 (High Pressure)",
        TRUE ~ "Sensor 11 (Vibration)"
      )
    )
}
