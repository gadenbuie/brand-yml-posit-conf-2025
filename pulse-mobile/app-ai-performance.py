"""
Pulse AI Assistant Performance Tracking Dashboard
A Shiny for Python application for monitoring AI assistant metrics
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots

from shiny import App, ui, render, reactive
from shiny.types import FileInfo
from shinywidgets import render_widget, output_widget
import faicons


# Load synthetic data
def load_data():
    """Load and prepare the synthetic datasets"""
    try:
        customers = pd.read_csv("data/synthetic-customers.csv")
        usage_data = pd.read_csv("data/synthetic-usage-data.csv")
        support_tickets = pd.read_csv("data/synthetic-support-tickets.csv")
        ai_interventions = pd.read_csv("data/synthetic-ai-interventions.csv")

        # Convert date columns
        ai_interventions["intervention_date"] = pd.to_datetime(
            ai_interventions["intervention_date"]
        )
        support_tickets["created_date"] = pd.to_datetime(
            support_tickets["created_date"]
        )
        customers["signup_date"] = pd.to_datetime(customers["signup_date"])

        return customers, usage_data, support_tickets, ai_interventions
    except FileNotFoundError:
        # If data doesn't exist, create sample data
        return create_sample_data()


def create_sample_data():
    """Create minimal sample data if files don't exist"""
    # This is a fallback - in production, data generation script should be run first
    customers = pd.DataFrame(
        {
            "customer_id": [f"CUST{i:06d}" for i in range(1, 101)],
            "customer_segment": np.random.choice(
                ["Budget Conscious", "Power User", "Social Connector", "Business User"],
                100,
            ),
            "monthly_bill": np.random.uniform(25, 120, 100),
            "satisfaction_score": np.random.randint(1, 11, 100),
        }
    )

    ai_interventions = pd.DataFrame(
        {
            "customer_id": np.random.choice(customers["customer_id"], 200),
            "intervention_date": pd.date_range("2024-01-01", "2024-12-31", periods=200),
            "intervention_type": np.random.choice(
                [
                    "Billing Support",
                    "Technical Support",
                    "Account Management",
                    "Usage Optimization",
                ],
                200,
            ),
            "savings_amount": np.random.uniform(10, 150, 200),
            "confidence_score": np.random.uniform(0.6, 0.99, 200),
        }
    )

    return customers, pd.DataFrame(), pd.DataFrame(), ai_interventions


# Load data
customers, usage_data, support_tickets, ai_interventions = load_data()

# Define UI
app_ui = ui.page_sidebar(
    ui.sidebar(
        ui.h3("🤖 AI Performance Filters"),
        ui.input_date_range(
            "date_range",
            "Date Range:",
            start=ai_interventions["intervention_date"].min(),
            end=ai_interventions["intervention_date"].max(),
        ),
        ui.input_selectize(
            "intervention_types",
            "Intervention Types:",
            choices=list(ai_interventions["intervention_type"].unique()),
            selected=list(ai_interventions["intervention_type"].unique()),
            multiple=True,
        ),
        ui.input_selectize(
            "customer_segments",
            "Customer Segments:",
            choices=list(customers["customer_segment"].unique()),
            selected=list(customers["customer_segment"].unique()),
            multiple=True,
        ),
        ui.hr(),
        ui.p(
            "🎯 Key Performance Indicators", style="font-weight: bold; color: #8a2be2;"
        ),
        width=300,
    ),
    ui.h1(
        "Pulse AI Assistant Performance Dashboard",
        style="color: #8a2be2; margin-bottom: 20px;",
    ),
    ui.p(
        "This project contains synthetic data and analysis created for demonstration purposes only.",
        style="background-color: #fff3cd; padding: 10px; border-left: 4px solid #ffc107; margin-bottom: 20px;",
    ),
    # KPI Value Boxes
    ui.layout_columns(
        ui.output_ui("total_savings_box"),
        ui.output_ui("total_interventions_box"),
        ui.output_ui("avg_confidence_box"),
        ui.output_ui("unique_customers_box"),
        fill=False
    ),
    ui.navset_tab(
        ui.nav_panel(
            "📊 Performance Overview",
            output_widget("savings_trend_plot"),
            ui.hr(),
            output_widget("intervention_portfolio"),
        ),
        ui.nav_panel(
            "🎯 Customer Segments",
            output_widget("segment_adoption_plot"),
        ),
        ui.nav_panel(
            "📈 Trends & Analytics",
            output_widget("monthly_trends"),
        ),
        ui.nav_panel(
            "💰 Financial Impact",
            ui.layout_columns(
                ui.output_ui("financial_summary"),
                output_widget("cumulative_savings"),
                col_widths=[4, 8]
            ),
        ),
    ),
    fillable=True,
    title="Pulse AI Performance Dashboard",
    theme=ui.Theme.from_brand(__file__),
)


# Define server logic
def server(input, output, session):
    @reactive.calc
    def filtered_data():
        """Filter data based on user inputs"""
        # Filter AI interventions
        filtered_ai = ai_interventions[
            (
                ai_interventions["intervention_date"]
                >= pd.to_datetime(input.date_range()[0])
            )
            & (
                ai_interventions["intervention_date"]
                <= pd.to_datetime(input.date_range()[1])
            )
            & (ai_interventions["intervention_type"].isin(input.intervention_types()))
        ]

        # Join with customer data and filter by segments
        merged_data = filtered_ai.merge(customers, on="customer_id", how="left")
        merged_data = merged_data[
            merged_data["customer_segment"].isin(input.customer_segments())
        ]

        return merged_data

    @render.ui
    def total_savings_box():
        data = filtered_data()
        total_savings = data["savings_amount"].sum()
        return ui.value_box(
            title="Total Savings",
            value=f"${total_savings:,.0f}",
            showcase=faicons.icon_svg("dollar-sign"),
            theme="success",
        )

    @render.ui
    def total_interventions_box():
        data = filtered_data()
        total_interventions = len(data)
        return ui.value_box(
            title="Total Interventions",
            value=f"{total_interventions:,}",
            showcase=faicons.icon_svg("bullseye"),
            theme="primary",
        )

    @render.ui
    def avg_confidence_box():
        data = filtered_data()
        avg_confidence = data["confidence_score"].mean()
        return ui.value_box(
            title="Avg Confidence",
            value=f"{avg_confidence:.1%}",
            showcase=faicons.icon_svg("chart-bar"),
            theme="secondary",
        )

    @render.ui
    def unique_customers_box():
        data = filtered_data()
        unique_customers = data["customer_id"].nunique()
        return ui.value_box(
            title="Unique Customers",
            value=f"{unique_customers:,}",
            showcase=faicons.icon_svg("users"),
            theme="warning",
        )

    @render_widget
    def savings_trend_plot():
        """Plot savings trends over time"""
        data = filtered_data()

        # Group by week for trend analysis
        data["week"] = data["intervention_date"].dt.to_period("W")
        weekly_savings = data.groupby("week")["savings_amount"].sum().reset_index()
        weekly_savings["week"] = weekly_savings["week"].dt.start_time

        fig = px.line(
            weekly_savings,
            x="week",
            y="savings_amount",
            title="Weekly AI Assistant Savings Trend",
            labels={"savings_amount": "Weekly Savings ($)", "week": "Week"},
        )

        fig.update_traces(line=dict(color="#8a2be2", width=3))
        fig.update_layout(plot_bgcolor="white", height=400, title_font_size=16)

        return fig


    @render_widget
    def intervention_portfolio():
        """Plot intervention type performance"""
        data = filtered_data()

        portfolio = (
            data.groupby("intervention_type")
            .agg({"savings_amount": "sum", "confidence_score": "mean"})
            .reset_index()
        )

        fig = px.bar(
            portfolio,
            x="intervention_type",
            y="savings_amount",
            color="confidence_score",
            title="AI Intervention Portfolio Performance",
            labels={
                "savings_amount": "Total Savings ($)",
                "intervention_type": "Intervention Type",
            },
            color_continuous_scale="Viridis",
        )

        fig.update_layout(
            plot_bgcolor="white", height=400, title_font_size=16, xaxis_tickangle=-45
        )

        return fig


    @render_widget
    def segment_adoption_plot():
        """Customer segment adoption analysis"""
        data = filtered_data()

        segment_stats = (
            data.groupby("customer_segment")
            .agg({"customer_id": "nunique", "savings_amount": "sum"})
            .reset_index()
        )

        # Get total customers per segment
        total_customers = (
            customers.groupby("customer_segment")
            .size()
            .reset_index(name="total_customers")
        )
        segment_stats = segment_stats.merge(total_customers, on="customer_segment")
        segment_stats["adoption_rate"] = (
            segment_stats["customer_id"] / segment_stats["total_customers"]
        )

        fig = px.bar(
            segment_stats,
            x="customer_segment",
            y="adoption_rate",
            color="savings_amount",
            title="AI Adoption Rate by Customer Segment",
            labels={
                "adoption_rate": "Adoption Rate",
                "customer_segment": "Customer Segment",
            },
            color_continuous_scale="Blues",
        )

        fig.update_layout(
            plot_bgcolor="white", height=400, title_font_size=16, yaxis_tickformat=".1%"
        )

        return fig



    @render_widget
    def monthly_trends():
        """Monthly performance trends"""
        data = filtered_data()

        data["month"] = data["intervention_date"].dt.to_period("M")
        monthly_data = (
            data.groupby(["month", "intervention_type"])
            .agg({"savings_amount": "sum", "confidence_score": "mean"})
            .reset_index()
        )
        monthly_data["month"] = monthly_data["month"].dt.start_time

        fig = px.line(
            monthly_data,
            x="month",
            y="savings_amount",
            color="intervention_type",
            title="Monthly Savings Trends by Intervention Type",
            labels={"savings_amount": "Monthly Savings ($)", "month": "Month"},
        )

        fig.update_layout(plot_bgcolor="white", height=400, title_font_size=16)

        return fig



    @render.ui
    def financial_summary():
        """Financial impact summary"""
        data = filtered_data()

        total_savings = data["savings_amount"].sum()
        total_interventions = len(data)
        avg_savings_per_intervention = data["savings_amount"].mean()

        # Calculate projected annual savings
        days_in_period = (
            pd.to_datetime(input.date_range()[1])
            - pd.to_datetime(input.date_range()[0])
        ).days
        daily_avg = total_savings / max(days_in_period, 1)
        projected_annual = daily_avg * 365

        return ui.div(
            ui.h4("💰 Financial Impact Summary", style="color: #8a2be2;"),
            ui.hr(),
            ui.p(
                f"Total Savings: ${total_savings:,.0f}",
                style="font-size: 16px; font-weight: bold;",
            ),
            ui.p(
                f"Total Interventions: {total_interventions:,}",
                style="font-size: 14px;",
            ),
            ui.p(
                f"Avg per Intervention: ${avg_savings_per_intervention:.0f}",
                style="font-size: 14px;",
            ),
            ui.hr(),
            ui.p(
                f"Projected Annual Savings: ${projected_annual:,.0f}",
                style="font-size: 16px; font-weight: bold; color: #4cd964;",
            ),
            ui.p(
                "Based on current performance trends",
                style="font-size: 12px; color: #666;",
            ),
        )

    @render_widget
    def cumulative_savings():
        """Cumulative savings over time"""
        data = filtered_data().sort_values("intervention_date")
        data["cumulative_savings"] = data["savings_amount"].cumsum()

        fig = px.line(
            data,
            x="intervention_date",
            y="cumulative_savings",
            title="Cumulative AI Assistant Savings",
            labels={
                "cumulative_savings": "Cumulative Savings ($)",
                "intervention_date": "Date",
            },
        )

        fig.update_traces(line=dict(color="#4cd964", width=3))
        fig.update_layout(plot_bgcolor="white", height=400, title_font_size=16)

        return fig



# Create the app
app = App(app_ui, server)
