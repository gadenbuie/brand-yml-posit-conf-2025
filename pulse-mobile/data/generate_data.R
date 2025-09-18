# Synthetic Data Generation for Pulse Mobile AI Assistant Demo
# This script generates artificial telecom data for demonstration purposes only
# All data is computer-generated and does not represent actual customer information

library(dplyr)
library(readr)
library(lubridate)

set.seed(42)

# Generate customer profiles
generate_customers <- function(n = 5000) {
  customer_segments <- c("Budget Conscious", "Power User", "Social Connector", "Business User")
  plan_types <- c("Basic", "Standard", "Premium", "Unlimited")

  customers <- tibble(
    customer_id = paste0("CUST", sprintf("%06d", 1:n)),
    age = sample(18:65, n, replace = TRUE),
    plan_type = sample(plan_types, n, replace = TRUE,
                      prob = c(0.3, 0.35, 0.25, 0.1)),
    monthly_bill = case_when(
      plan_type == "Basic" ~ runif(n, 25, 35),
      plan_type == "Standard" ~ runif(n, 45, 65),
      plan_type == "Premium" ~ runif(n, 75, 95),
      plan_type == "Unlimited" ~ runif(n, 95, 120)
    ),
    signup_date = sample(seq(as.Date("2020-01-01"), as.Date("2024-01-01"), by = "day"), n, replace = TRUE),
    customer_segment = sample(customer_segments, n, replace = TRUE),
    has_autopay = sample(c(TRUE, FALSE), n, replace = TRUE, prob = c(0.7, 0.3)),
    satisfaction_score = pmax(1, pmin(10, round(rnorm(n, 7.5, 1.5)))),
    total_lifetime_value = runif(n, 200, 2500)
  )

  return(customers)
}

# Generate usage data
generate_usage_data <- function(customers, months = 12) {
  usage_data <- tibble()

  for (month_offset in 0:(months-1)) {
    month_date <- floor_date(Sys.Date() - months(month_offset), "month")

    monthly_usage <- customers |>
      rowwise() |>
      mutate(
        billing_month = month_date,
        data_gb = case_when(
          plan_type == "Basic" ~ max(0, rnorm(1, 8, 3)),
          plan_type == "Standard" ~ max(0, rnorm(1, 15, 5)),
          plan_type == "Premium" ~ max(0, rnorm(1, 25, 8)),
          plan_type == "Unlimited" ~ max(0, rnorm(1, 45, 15))
        ),
        voice_minutes = case_when(
          customer_segment == "Business User" ~ max(0, rnorm(1, 800, 200)),
          customer_segment == "Social Connector" ~ max(0, rnorm(1, 600, 150)),
          TRUE ~ max(0, rnorm(1, 400, 100))
        ),
        text_messages = case_when(
          age < 30 ~ max(0, rnorm(1, 2500, 500)),
          age < 50 ~ max(0, rnorm(1, 1200, 300)),
          TRUE ~ max(0, rnorm(1, 400, 100))
        ),
        overage_charges = pmax(0, case_when(
          plan_type == "Unlimited" ~ 0,
          plan_type == "Basic" & data_gb > 10 ~ (data_gb - 10) * 10,
          plan_type == "Standard" & data_gb > 20 ~ (data_gb - 20) * 8,
          plan_type == "Premium" & data_gb > 35 ~ (data_gb - 35) * 5,
          TRUE ~ 0
        ))
      ) |>
      ungroup()

    usage_data <- bind_rows(usage_data, monthly_usage)
  }

  return(usage_data)
}

# Generate support tickets and issues that AI could prevent
generate_support_data <- function(customers) {
  issue_types <- c(
    "Billing Error", "Overage Surprise", "Plan Optimization",
    "Network Issue", "Account Security", "Service Outage",
    "Payment Failure", "Roaming Charges", "Feature Confusion"
  )

  # AI Preventable issues and their prevention methods
  ai_preventable <- c(
    "Billing Error", "Overage Surprise", "Plan Optimization",
    "Payment Failure", "Roaming Charges"
  )

  prevention_savings <- c(
    "Billing Error" = 25,
    "Overage Surprise" = 35,
    "Plan Optimization" = 15,
    "Payment Failure" = 10,
    "Roaming Charges" = 45
  )

  # Generate historical support tickets
  n_tickets <- nrow(customers) * 0.8  # 80% of customers had at least one ticket

  support_tickets <- tibble(
    ticket_id = paste0("TKT", sprintf("%06d", 1:n_tickets)),
    customer_id = sample(customers$customer_id, n_tickets, replace = TRUE),
    issue_type = sample(issue_types, n_tickets, replace = TRUE),
    created_date = sample(seq(as.Date("2023-01-01"), Sys.Date(), by = "day"), n_tickets, replace = TRUE),
    resolution_time_hours = case_when(
      issue_type %in% c("Billing Error", "Plan Optimization") ~ sample(1:24, n_tickets, replace = TRUE),
      issue_type %in% c("Network Issue", "Service Outage") ~ sample(0.5:4, n_tickets, replace = TRUE),
      TRUE ~ sample(0.25:8, n_tickets, replace = TRUE)
    ),
    ai_preventable = issue_type %in% ai_preventable,
    potential_savings = ifelse(ai_preventable, prevention_savings[issue_type], 0)
  ) |>
  mutate(potential_savings = ifelse(is.na(potential_savings), 0, potential_savings))

  return(support_tickets)
}

# Generate AI assistant intervention data (simulated for prototype)
generate_ai_interventions <- function(customers) {
  # Simulate AI interventions for last 3 months
  intervention_types <- c(
    "Prevented Overage", "Optimized Plan", "Caught Billing Error",
    "Prevented Payment Failure", "Roaming Alert"
  )

  savings_map <- c(
    "Prevented Overage" = 35,
    "Optimized Plan" = 25,
    "Caught Billing Error" = 20,
    "Prevented Payment Failure" = 10,
    "Roaming Alert" = 45
  )

  # About 30% of customers benefit from AI assistant
  ai_customers <- sample(customers$customer_id, nrow(customers) * 0.3)

  interventions <- tibble()

  for (customer in ai_customers) {
    n_interventions <- sample(1:5, 1, prob = c(0.4, 0.3, 0.2, 0.08, 0.02))

    customer_interventions <- tibble(
      customer_id = customer,
      intervention_date = sample(seq(Sys.Date() - 90, Sys.Date(), by = "day"),
                                n_interventions, replace = TRUE),
      intervention_type = sample(intervention_types, n_interventions, replace = TRUE),
      savings_amount = savings_map[intervention_type],
      confidence_score = runif(n_interventions, 0.75, 0.98)
    )

    interventions <- bind_rows(interventions, customer_interventions)
  }

  return(interventions)
}

# Main data generation function
main <- function() {
  cat("Generating synthetic telecom data for Pulse Mobile AI Assistant demo...\n")

  # Generate all datasets
  customers <- generate_customers(5000)
  usage_data <- generate_usage_data(customers, 12)
  support_tickets <- generate_support_data(customers)
  ai_interventions <- generate_ai_interventions(customers)

  # Add header comments to indicate synthetic data
  header_comment <- "# Synthetic data generated for Pulse Mobile AI Assistant demonstration\n# This data is artificial and created for demo purposes only\n# Generated on: "

  # Save datasets with synthetic prefix
  write_csv(customers, "data/synthetic-customers.csv")
  write_csv(usage_data, "data/synthetic-usage-data.csv")
  write_csv(support_tickets, "data/synthetic-support-tickets.csv")
  write_csv(ai_interventions, "data/synthetic-ai-interventions.csv")

  cat("✓ Generated synthetic-customers.csv (", nrow(customers), " customers)\n")
  cat("✓ Generated synthetic-usage-data.csv (", nrow(usage_data), " records)\n")
  cat("✓ Generated synthetic-support-tickets.csv (", nrow(support_tickets), " tickets)\n")
  cat("✓ Generated synthetic-ai-interventions.csv (", nrow(ai_interventions), " interventions)\n")
  cat("\nSynthetic data generation complete!\n")
}

# Run if script is executed directly
if (sys.nframe() == 0) {
  main()
}