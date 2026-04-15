# 🎤 Presentation Guide: Robot Health & RUL Prediction
**Prepared for:** Rihan & Suzain  
**Project:** Predictive Maintenance using R Shiny & NASA CMAPSS Dataset

---

## 1. Project Introduction (Who is speaking: Rihan/Suzain)
"Good morning, Ma’am! Today, we are excited to present our project: **The Robot Health & RUL Prediction System.** 

Our goal was to build aStandalone R/Shiny application that can monitor engine health in real-time and predict **Remaining Useful Life (RUL)**—essentially telling us when a machine will fail before it actually happens."

---

## 2. The Technical Stack
"We moved away from traditional SQL databases to create a more portable, data-science-focused solution using:
- **R / Shiny**: For the interactive web interface.
- **Dplyr & Readr**: For high-speed data processing.
- **Linear Regression (LM)**: For the predictive modeling.
- **NASA CMAPSS Dataset**: Real-world turbofan engine degradation data."

---

## 3. The Formulas (The 'Math' behind the project)
*Ma'am might ask how the health score is calculated. Here are the 3 main steps:*

### Step A: Normalization (Min-Max Scaling)
"Every sensor has different units (Temperature in Celsius, Pressure in PSI). We normalize them to a range of **0 to 1** so we can compare them."
> **Formula:** `n_val = (x - min(x)) / (max(x) - min(x))`

### Step B: Weighted Health Score
"Based on our analysis, **Sensor 2 (Temperature)**, **Sensor 4 (Pressure)**, and **Sensor 11 (Vibration)** are the biggest indicators of failure. We calculate a health score out of 100."
> **Formula:** `Health = 100 - (50 * n_S2 + 30 * n_S4 + 20 * n_S11)`

### Step C: RUL Prediction (Linear Regression)
"We train a Linear Regression model on thousands of rows of historical data to find the relationship between the **Health Score** and the **Cycles Remaining**."
> **Formula:** `RUL = (a * Health_Score) + b`

---

## 4. Live Demo Steps
"Now, let’s walk through the dashboard:"

1.  **Dashboard Overview**: Point out the **100 Engines** and their current statuses (Healthy, Warning, Critical).
2.  **Interactive Drill-Down**: "If I click on **Engine 3**, look at the **Engine Inspector** on the right. It shows a detailed breakdown of all 21 sensors for just that unit."
3.  **Sensor Diagnosis**: "The bar chart shows that **Sensor 2 (LPC Outlet Temp)** is the primary cause of degradation for this specific engine."
4.  **Live Simulation**: Go to the **'Add Live Reading'** tab. "We can simulate a new sensor reading. If I enter high numbers for Temperature and Pressure, the system will update the health score and alert the maintenance team."

---

## 5. Conclusion
"In conclusion, our system provides an end-to-end solution for predictive maintenance. It doesn't just show data; it provides **actionable insights** by identifying precisely which part needs a check-up.

Thank you, Ma’am! We are now open for any questions."
