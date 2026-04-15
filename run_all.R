# run_all.R
# One-click script to launch the Robot Health & RUL Prediction Dashboard

print("--- Starting Robot Health Monitor Setup ---")

# 1. CHECK & INSTALL LIBRARIES
required_libs <- c("shiny", "shinydashboard", "dplyr", "plotly", "readr", "DT", "tidyr")
missing_libs <- required_libs[!(required_libs %in% installed.packages()[,"Package"])]

if (length(missing_libs) > 0) {
  print(paste("Installing missing tools:", paste(missing_libs, collapse = ", ")))
  install.packages(missing_libs, repos = "https://cloud.r-project.org")
}

# 2. SET WORKING DIRECTORY
# We use the absolute path to ensure it works from any launch point
project_path <- "E:/DBMS-2/robot_health_r"
if (dir.exists(project_path)) {
  setwd(project_path)
  print(paste("Working directory set to:", project_path))
} else {
  stop(paste("Project folder not found at:", project_path))
}

# 3. LAUNCH THE DASHBOARD
print("Launching Dashboard...")
shiny::runApp(launch.browser = TRUE)
