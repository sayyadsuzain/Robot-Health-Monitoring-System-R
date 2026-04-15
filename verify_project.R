# verify_project.R
# Diagnostic script to ensure the R environment and project logic are correct.

print("--- 🧪 Starting Project Verification ---")

# Check libraries
required_libs <- c("shiny", "shinydashboard", "dplyr", "plotly", "readr", "DT", "tidyr")
missing_libs <- required_libs[!(required_libs %in% installed.packages()[,"Package"])]

if (length(missing_libs) > 0) {
  print(paste("❌ Missing libraries:", paste(missing_libs, collapse = ", ")))
  print("Run this in R: install.packages(c('shiny', 'shinydashboard', 'dplyr', 'plotly', 'readr', 'DT', 'tidyr'))")
} else {
  print("✅ All libraries found.")
}

# Source logic
tryCatch({
  source("logic.R")
  print("✅ logic.R sourced successfully.")
}, error = function(e) {
  print(paste("❌ Error sourcing logic.R:", e$message))
})

# Test data loading
tryCatch({
  data <- load_cmapss_data("data")
  print("✅ Data files located and loaded.")
  print(paste("   - Training rows:", nrow(data$train)))
  print(paste("   - Test units:", length(unique(data$test$unit))))
}, error = function(e) {
  print(paste("❌ Error loading data:", e$message))
})

# Test predictions
tryCatch({
  preds <- get_rul_predictions(data$train, data$test)
  print("✅ RUL predictions calculated successfully.")
  print("--- Sample Predictions (First 5 units) ---")
  print(head(preds %>% select(unit, cycle, health_score, estimated_cycles_left, status), 5))
}, error = function(e) {
  print(paste("❌ Error calculating predictions:", e$message))
})

print("--- 🏁 Verification Complete ---")
