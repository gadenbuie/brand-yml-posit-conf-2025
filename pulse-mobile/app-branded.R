# Pulse AI Assistant - Pricing Dashboard
# This project contains synthetic data and analysis created for demonstration purposes only.

library(shiny)
library(bslib)
library(dplyr)
library(readr)
library(purrr)
library(tidyr)
library(ggplot2)
library(plotly)
library(scales)

# Load synthetic data
customers <- read_csv("data/synthetic-customers.csv", show_col_types = FALSE)

brand <- brand.yml::read_brand_yml()

ui <- page_sidebar(
  pagetitle = "Pulse AI Assistant Pricing Dashboard",
  theme = bs_theme(brand = brand),

  sidebar = sidebar(
    title = "Pulse AI Assistant",
    fillable = TRUE,

    sliderInput(
      "monthly_price",
      "Monthly Price ($)",
      value = 5,
      min = 1,
      max = 20,
      step = 1
    ),

    selectInput(
      "adoption_scenario",
      "Adoption Scenario:",
      choices = c(
        "Optimistic" = "optimistic",
        "Realistic" = "realistic",
        "Conservative" = "conservative",
        "Underwhelming" = "underwhelming"
      ),
      selected = "realistic"
    ),
    div(
      class = "mt-auto",
      hr(),
      p(
        "This project contains synthetic data and analysis created for demonstration purposes only."
      )
    )
  ),

  layout_columns(
    fill = FALSE,
    value_box(
      title = "Expected Adoption",
      value = textOutput("adoption_percent"),
      showcase = icon("chart-line"),
    ),
    value_box(
      title = "Monthly Revenue",
      value = textOutput("monthly_revenue"),
      showcase = icon("dollar-sign"),
    ),
    value_box(
      title = "ROI",
      value = textOutput("roi_percent"),
      showcase = icon("percentage"),
    )
  ),

  layout_columns(
    card(
      card_header("Monthly Profit Optimization Curve"),
      plotlyOutput("profit_curve", height = "400px")
    ),
    card(
      card_header("User Segment Adoption"),
      plotlyOutput("segment_adoption", height = "400px")
    )
  )
)


server <- function(input, output, session) {
  addResourcePath("brand", dirname(brand$path))

  total_customers <- nrow(customers) * 50
  fixed_costs <- 15000 # Monthly fixed costs (infrastructure, etc.)
  cost_per_user <- 2.25 # Variable cost per active user

  # Simple linear adoption model for straight lines
  get_base_adoption <- function(price, scenario) {
    # Linear decline in adoption as price increases
    max_adoption <- switch(
      scenario,
      "optimistic" = 0.60,
      "realistic" = 0.45,
      "conservative" = 0.35,
      "underwhelming" = 0.25
    )

    min_adoption <- switch(
      scenario,
      "optimistic" = 0.10,
      "realistic" = 0.05,
      "conservative" = 0.03,
      "underwhelming" = 0.02
    )

    # Simple linear decline from max to min over price range
    adoption_rate <- max_adoption -
      (price - 0.99) * (max_adoption - min_adoption) / (20 - 0.99)

    pmax(min_adoption, adoption_rate)
  }

  # Reactive calculations
  adoption_rate <- reactive({
    get_base_adoption(input$monthly_price, input$adoption_scenario)
  })

  subscribers <- reactive({
    round(total_customers * adoption_rate())
  })

  revenue <- reactive({
    subscribers() * input$monthly_price
  })

  costs <- reactive({
    fixed_costs + (subscribers() * cost_per_user)
  })

  profit <- reactive({
    revenue() - costs()
  })

  roi <- reactive({
    if (costs() > 0) {
      (profit() / costs()) * 100
    } else {
      0
    }
  })

  # Value box outputs
  output$adoption_percent <- renderText({
    paste0(round(adoption_rate() * 100, 1), "% of base")
  })

  output$monthly_revenue <- renderText({
    paste0("$", format(round(revenue()), big.mark = ","))
  })

  output$roi_percent <- renderText({
    paste0(round(roi(), 1), "%")
  })

  # Main profit curve
  output$profit_curve <- renderPlotly({
    price_points <- seq(0.99, 20, 0.05) # Much finer resolution for smoother curves
    scenario <- input$adoption_scenario

    curve_data <- tibble(
      price = price_points,
      adoption = map_dbl(price_points, ~ get_base_adoption(.x, scenario)),
      subscribers = total_customers * adoption, # Don't round for smoother curves
      revenue = subscribers * price,
      costs = fixed_costs + (subscribers * cost_per_user),
      profit = revenue - costs
    )

    # Current price point data
    current_data <- tibble(
      price = input$monthly_price,
      revenue = revenue(),
      costs = costs()
    )

    # Reshape data for dual y-axis plot
    plot_data <- curve_data %>%
      select(price, revenue, costs) %>%
      pivot_longer(
        cols = c(revenue, costs),
        names_to = "metric",
        values_to = "value"
      )

    p <- ggplot(plot_data, aes(x = price, y = value, color = metric)) +
      geom_line(size = 2) +
      geom_point(
        data = current_data,
        aes(x = price, y = revenue),
        color = "#595959",
        size = 6,
        inherit.aes = FALSE
      ) +
      geom_point(
        data = current_data,
        aes(x = price, y = costs),
        color = "gray",
        size = 6,
        inherit.aes = FALSE
      ) +
      scale_color_manual(
        values = c(
          "revenue" = "#595959",
          "costs" = "gray"
        ),
        labels = c("costs" = "Total Costs", "revenue" = "Total Revenue"),
        name = "Metric"
      ) +
      scale_y_continuous(
        labels = scales::label_dollar(scale = 1e-3, suffix = "K")
      ) +
      labs(
        x = "Monthly Price ($)",
        y = NULL
      ) +
      theme_minimal() +
      theme(legend.position = "top")

    ggplotly(p, tooltip = c("x", "y", "colour"))
  })

  # Segment adoption chart
  output$segment_adoption <- renderPlotly({
    segments <- customers %>%
      count(customer_segment) %>%
      mutate(
        segment_adoption = case_when(
          customer_segment == "Business User" ~ adoption_rate() * 1.5,
          customer_segment == "Power User" ~ adoption_rate() * 1.2,
          customer_segment == "Social Connector" ~ adoption_rate() * 0.9,
          customer_segment == "Budget Conscious" ~ adoption_rate() * 0.6,
          TRUE ~ adoption_rate()
        ),
        segment_adoption = pmin(0.8, segment_adoption),
        display_name = case_when(
          customer_segment == "Business User" ~ "Business",
          customer_segment == "Power User" ~ "Power",
          customer_segment == "Social Connector" ~ "Social",
          customer_segment == "Budget Conscious" ~ "Budget",
          TRUE ~ customer_segment
        )
      )

    p <- ggplot(
      segments,
      aes(
        x = reorder(display_name, segment_adoption),
        y = segment_adoption
      )
    ) +
      geom_col() +
      coord_flip() +
      scale_y_continuous(labels = scales::percent_format()) +
      labs(
        x = NULL,
        y = "Adoption Rate"
      ) +
      theme_minimal()

    ggplotly(p, tooltip = c("y"))
  })
}

shinyApp(ui = ui, server = server)
