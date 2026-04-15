# 🤖 ROBOT HEALTH & RUL PREDICTION: FULL PROJECT RECORD
**Authors:** Rihan & Suzain

---

## 📄 1. README (Project Documentation)

### 🤖 Robot Health & RUL Prediction (R Edition)

### 📑 Project Overview
This project is an advanced predictive maintenance dashboard built using R and Shiny. It processes NASA's CMAPSS dataset to monitor the health of 100 turbofan engines and predict their Remaining Useful Life (RUL).

### 🧠 Scientific Methodology
Our system uses a 3-step analytical pipeline:

1.  **Data Normalization**: Min-Max scaling for all 21 sensors.
    - `n_val = (x - min) / (max - min)`
2.  **Health Indexing**: A weighted penalty formula targeting critical components.
    - `Health = 100 - (50*S2 + 30*S4 + 20*S11)`
3.  **Linear Regression**: Statistical modeling trained on degradation data to estimate RUL cycles.
    - `Predicted_RUL = lm(True_RUL ~ Health_Score)`

### 🚀 How to Run
1.  Open **RStudio** or **Rgui**.
2.  Run the following command:
    ```r
    source("E:/DBMS-2/robot_health_r/run_all.R")
    ```

### 📊 Key Features
- **Summary Fleet Stats**: Health status counts for 100 engines.
- **Engine Inspector**: Click any row to see a full 21-sensor breakdown with descriptive names.
- **Maintenance Recommendations**: Automated diagnosis identifying precisely which sensor needs a check-up.
- **Evaluation Comparison**: Compares the Baseline model vs. our Calibrated Regression model.

---

## 🎤 2. PRESENTATION SCRIPT

### Phase 1: The Foundation
"Good morning, Ma’am! Today, we are excited to present our project: The Robot Health & RUL Prediction System. Our goal was to build a Standalone R/Shiny application that can monitor engine health in real-time."

### Phase 2: The Math Section
"1. **Normalization**: We scale each sensor from 0 to 1.
2. **Health Score**: We combine Temp, Pressure, and Vibration into a 100-point score.
3. **Linear Regression**: We use historical data to predict the cycles remaining."

### Phase 3: The Demo
"As we demo the app, you'll see the Engine Inspector which shows 21 different sensors. If I click on an engine, it highlights the exact sensor that is failing."

---

## 💻 3. CORE LOGIC (`logic.R`)

```r
# logic.R
# Core analytical functions for Robot Health & RUL Prediction System
library(dplyr)
library(readr)
library(tidyr)

# 1. LOAD DATA
load_cmapss_data <- function(data_folder = "data") {
  # ... (Data Loading Logic)
}

# 2. NORMALIZATION & HEALTH SCORE
calculate_health_score <- function(df) {
  # ... (Normalization for 21 Sensors)
}

# 3. RUL PREDICTION
get_rul_predictions <- function(train_df, test_df) {
  # ... (Linear Regression & Status Classification)
}

# 4. DIAGNOSTICS
get_diagnostics <- function(df) {
  # ... (Failing sensor identification)
}
```

---

## 🖥️ 4. DASHBOARD UI (`app.R`)

```r
# app.R
# Premium Shiny Dashboard
library(shiny)
library(shinydashboard)
# ... (UI Layout 3:2 and Engine Inspector)
```

---

## 🚀 5. AUTOMATION SCRIPT (`run_all.R`)

```r
# run_all.R
# One-click dashboard launch
source("E:/DBMS-2/robot_health_r/run_all.R")
```
