# app.R
# Premium Shiny Dashboard for Robot Health & RUL Prediction
# Replicates the look and feel of the original Python dashboard.

library(shiny)
library(shinydashboard)
library(dplyr)
library(plotly)
library(DT)
source("logic.R")

# CUSTOM CSS FOR COLOR CODING
custom_css <- "
  .content-wrapper { background-color: #f4f6f9; }
  .main-header .logo { font-family: 'Source Sans Pro', sans-serif; font-weight: bold; }
  .box { border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
"

# UI DEFINITION
ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(title = "Robot Health Monitor"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Add Live Reading", tabName = "live", icon = icon("plus-circle")),
      hr(),
      actionButton("refresh", "Refresh Data", icon = icon("sync"), class = "btn-primary"),
      br(), br(),
      tags$div(style="padding: 15px; color: #888;", 
               tags$p("Mode: Standalone R"),
               tags$p("Data: NASA CMAPSS"))
    )
  ),
  dashboardBody(
    tags$head(tags$style(HTML(custom_css))),
    tabItems(
      # Main Dashboard Tab
      tabItem(tabName = "dashboard",
        # 1. Summary Metrics (4 Columns)
        fluidRow(
          valueBoxOutput("total_box", width = 3),
          valueBoxOutput("failed_box", width = 2),
          valueBoxOutput("critical_box", width = 2),
          valueBoxOutput("warning_box", width = 2),
          valueBoxOutput("healthy_box", width = 3)
        ),
        
        # 2. Main Layout (3:2 Split)
        fluidRow(
          # Left: All Engines (7/12 = ~3/5)
          column(width = 7,
            box(title = "All Engines Status (Click a row to Inspect)", status = "primary", solidHeader = TRUE, width = NULL,
                DTOutput("status_table"))
          ),
          # Right: Engine Inspector (5/12 = ~2/5)
          column(width = 5,
            box(title = "Engine Inspector (Full Sensor Health)", status = "success", solidHeader = TRUE, width = NULL,
                uiOutput("inspector_ui"))
          )
        ),
        
        # 3. Forecast Plot
        fluidRow(
          box(title = "Remaining Useful Life (RUL) Forecast", status = "info", solidHeader = TRUE, width = 12,
              plotlyOutput("rul_plot", height = "300px"))
        ),
        
        # 4. Diagnostics & Evaluation (Expandable)
        fluidRow(
          box(title = "Sensor Diagnostics (Failing Sensor & Damage %)", status = "warning", solidHeader = TRUE, 
              width = 6, collapsible = TRUE, collapsed = FALSE,
              DTOutput("diag_table")),
          box(title = "Evaluation Metrics (Baseline vs Calibrated)", status = "success", solidHeader = TRUE, 
              width = 6, collapsible = TRUE, collapsed = TRUE,
              fluidRow(
                column(6, tags$b("Baseline (Simple Mapping)"), tableOutput("metrics_base")),
                column(6, tags$b("Calibrated (Regression)"), tableOutput("metrics_cal"))
              ))
        )
      ),
      
      # Live Input Tab
      tabItem(tabName = "live",
        fluidRow(
          box(title = "Insert New Sensor Reading", status = "success", solidHeader = TRUE, width = 6,
              fluidRow(
                column(6, numericInput("l_unit", "Unit #", value = 999, min = 1)),
                column(6, numericInput("l_cycle", "Cycle #", value = 1, min = 1))
              ),
              fluidRow(
                column(4, numericInput("l_s2", "Temp (s2)", value = 642)),
                column(4, numericInput("l_s4", "Press (s4)", value = 1589)),
                column(4, numericInput("l_s11", "Vibr (s11)", value = 47))
              ),
              actionButton("submit_live", "Add to Pipeline", class = "btn-success btn-block")
          ),
          box(title = "Live Batch History", status = "info", width = 6,
              DTOutput("live_preview"))
        )
      )
    )
  )
)

# SERVER LOGIC
server <- function(input, output, session) {
  
  # Reactive values
  val <- reactiveValues(
    processed_data = NULL,
    truth_data = NULL,
    live_data = data.frame(unit=integer(), cycle=integer(), sensor_2=numeric(), sensor_4=numeric(), sensor_11=numeric())
  )
  
  # Refresh Logic
  observeEvent(input$refresh, {
    progress <- shiny::Progress$new()
    on.exit(progress$close())
    progress$set(message = "Processing NASA Dataset...", value = 0.5)
    
    tryCatch({
      raw <- load_cmapss_data()
      val$processed_data <- get_rul_predictions(raw$train, raw$test)
      val$truth_data <- raw$truth
      progress$set(value = 1)
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  }, ignoreNULL = FALSE)
  
  # Live Input
  observeEvent(input$submit_live, {
    new_row <- data.frame(
      unit = input$l_unit, cycle = input$l_cycle,
      sensor_2 = input$l_s2, sensor_4 = input$l_s4, sensor_11 = input$l_s11
    )
    val$live_data <- rbind(val$live_data, new_row)
    showNotification("New cycle data added to live stream.", type = "message")
  })
  
  # SUMMARY BOXES
  output$total_box <- renderValueBox({
    req(val$processed_data)
    valueBox(nrow(val$processed_data), "Total Engines", icon = icon("gears"), color = "light-blue")
  })
  output$failed_box <- renderValueBox({
    req(val$processed_data)
    n <- sum(val$processed_data$status == "FAILED")
    valueBox(n, "Failed (0 RUL)", icon = icon("skull"), color = "red")
  })
  output$critical_box <- renderValueBox({
    req(val$processed_data)
    n <- sum(val$processed_data$status == "FAIL SOON")
    valueBox(n, "Critical Health", icon = icon("fire"), color = "orange")
  })
  output$warning_box <- renderValueBox({
    req(val$processed_data)
    n <- sum(val$processed_data$status == "WARNING")
    valueBox(n, "Warning", icon = icon("exclamation-triangle"), color = "yellow")
  })
  output$healthy_box <- renderValueBox({
    req(val$processed_data)
    n <- sum(val$processed_data$status == "HEALTHY")
    valueBox(n, "Healthy", icon = icon("check-circle"), color = "green")
  })

  # TABLES
  status_dt_options <- list(pageLength = 10, scrollX = TRUE, dom = 'ftp')
  
  output$status_table <- renderDT({
    req(val$processed_data)
    val$processed_data %>%
      select(unit, cycle, health_score, estimated_cycles_left, status) %>%
      datatable(options = status_dt_options, selection = 'single') %>%
      formatStyle('status', backgroundColor = styleEqual(
        c("HEALTHY", "WARNING", "FAIL SOON", "FAILED"),
        c("#2ecc71", "#f1c40f", "#e67e22", "#e74c3c")
      ), color = "white", fontWeight = "bold")
  })
  
  output$action_table <- renderDT({
    req(val$processed_data)
    val$processed_data %>%
      filter(status %in% c("FAILED", "FAIL SOON")) %>%
      select(unit, estimated_cycles_left, status) %>%
      datatable(options = list(pageLength = 10, dom = 'tp')) %>%
      formatStyle('status', backgroundColor = styleEqual(
        c("FAIL SOON", "FAILED"), c("#e67e22", "#e74c3c")
      ), color = "white", fontWeight = "bold")
  })

  # PLOTS
  output$rul_plot <- renderPlotly({
    req(val$processed_data)
    p <- ggplot(val$processed_data, aes(x = unit, y = estimated_cycles_left, fill = status,
                                        text = paste("Unit:", unit, "<br>RUL:", estimated_cycles_left))) +
      geom_bar(stat = "identity") +
      scale_fill_manual(values = c("HEALTHY" = "#2ecc71", "WARNING" = "#f1c40f", "FAIL SOON" = "#e67e22", "FAILED" = "#e74c3c")) +
      theme_minimal() + labs(x = "Engine Unit", y = "Estimated Cycles (RUL)")
    ggplotly(p, tooltip = "text")
  })

  # INSPECTOR LOGIC
  output$inspector_ui <- renderUI({
    s <- input$status_table_rows_selected
    if (length(s) == 0) return(tags$p("Select an engine from the table on the left to see detailed sensor health."))
    
    selected_unit <- val$processed_data$unit[s]
    details <- get_diagnostics(val$processed_data %>% filter(unit == selected_unit))
    
    tagList(
      tags$h4(paste("Unit", selected_unit, "- Status:", details$status)),
      tags$p(paste("Overall Health Score:", round(details$health_score, 1))),
      plotlyOutput("sensor_breakdown_plot", height = "250px"),
      tags$br(),
      tags$p(tags$b("Maintenance Recommendation:")),
      tags$p(paste("Check", details$failing_sensor, "due to excessive contribution."))
    )
  })

  output$sensor_breakdown_plot <- renderPlotly({
    s <- input$status_table_rows_selected
    req(length(s) > 0)
    
    selected_unit <- val$processed_data$unit[s]
    details <- get_diagnostics(val$processed_data %>% filter(unit == selected_unit))
    
    # Extract all 21 normalized sensor values
    # We'll only show sensors that have some variation (not constant 0)
    sensor_indices <- 1:21
    n_values <- sapply(sensor_indices, function(i) details[[paste0("n_s", i)]])
    
    # Sensor Name Mapping (NASA CMAPSS)
    sensor_names <- c(
      "1: T2 (Fan Inlet Temp)", "2: T24 (LPC Outlet Temp)", "3: T30 (HPC Outlet Temp)", 
      "4: T50 (LPT Outlet Temp)", "5: P2 (Fan Inlet Pres)", "6: P15 (Bypass Pres)", 
      "7: P30 (HPC Outlet Pres)", "8: Nf (Fan Speed)", "9: Nc (Core Speed)", 
      "10: epr (Pres Ratio)", "11: Ps30 (HPC Static Pres)", "12: phi (Fuel Ratio)", 
      "13: NRf (Corr. Fan Speed)", "14: NRc (Corr. Core Speed)", "15: BPR (Bypass Ratio)", 
      "16: farB (Burner Ratio)", "17: htBleed (Enthalpy)", "18: Nf_dmd (Dem. Fan Speed)", 
      "19: PCNf_dmd (Dem. Corr. Fan)", "20: W31 (HPT Coolant)", "21: W32 (LPT Coolant)"
    )
    
    plot_data <- data.frame(
      SensorID = paste0("Sensor ", sensor_indices),
      SensorName = sensor_names,
      NormalizedValue = n_values
    ) %>%
      filter(NormalizedValue > 0.001)
    
    p <- ggplot(plot_data, aes(x = reorder(SensorName, NormalizedValue), y = NormalizedValue, fill = NormalizedValue)) +
      geom_bar(stat = "identity") +
      coord_flip() +
      scale_fill_gradient(low = "yellow", high = "red") +
      theme_minimal() +
      labs(title = "Sensor Deviation (Real-World Names)", x = "", y = "Degradation Level (0 to 1)") +
      theme(legend.position = "none")
    
    ggplotly(p)
  })

  # EXPANDABLES
  output$diag_table <- renderDT({
    req(val$processed_data)
    get_diagnostics(val$processed_data) %>%
      select(unit, status, damage_percent, failing_sensor) %>%
      datatable(options = list(pageLength = 5)) %>%
      formatStyle('damage_percent', 
                  background = styleColorBar(c(0, 100), '#ff7f7f'),
                  backgroundSize = '98% 88%',
                  backgroundRepeat = 'no-repeat',
                  backgroundPosition = 'center')
  })
  
  output$metrics_base <- renderTable({
    req(val$processed_data, val$truth_data)
    get_eval_metrics(val$processed_data, val$truth_data)$baseline
  })
  output$metrics_cal <- renderTable({
    req(val$processed_data, val$truth_data)
    get_eval_metrics(val$processed_data, val$truth_data)$calibrated
  })
  
  output$live_preview <- renderDT({
    datatable(val$live_data, options = list(pageLength = 5))
  })
}

shinyApp(ui, server)
