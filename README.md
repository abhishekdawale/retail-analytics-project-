# Retail Analytics Dashboard

An end-to-end retail analytics project covering data cleaning, exploratory data analysis, SQL-based business analysis, and an interactive Power BI dashboard — built to analyze revenue, profitability, customers, returns, inventory, and marketing performance for a multi-category retail business.

![Dashboard Overview](overview_dashboard.png)

## Overview

This project simulates a real-world retail analytics workflow: raw transactional data is cleaned and explored in Python, business questions are answered in SQL, and the results are brought together in a 6-page Power BI dashboard designed for stakeholder-style decision-making.

**Key numbers at a glance:**

| Metric | Value |
|---|---|
| Total Revenue | 10.50bn |
| Total Profit | 1.91bn |
| Avg. Profit Margin | 18.22% |
| Total Orders | 56.6K |
| Total Customers | 30K |
| Return Rate (by qty) | 2.57% |
| Overall ROAS | 99.67 |

## Tech Stack

- **Python** (pandas, numpy, matplotlib, seaborn) — data cleaning & exploratory data analysis
- **MySQL** — business logic, aggregations, and views for the dashboard layer
- **Power BI** — interactive dashboard, DAX measures, and forecasting

## Project Workflow

1. **Data Cleaning & EDA** (`enterprises_retail_eda.ipynb`)
   - Loaded raw `customers`, `orders`, `order_items`, `products`, `returns`, and `inventory_snapshots` tables
   - Checked and handled missing values (e.g. filling missing `store_id` with `online_order`, missing `campaign_id` with `no_campaign`)
   - Converted date columns to proper datetime types and boolean flags where relevant
   - Checked for and validated duplicate records
   - Detected outliers in order value using the IQR method
   - Engineered new fields: `discount_percentage`, `profit`, and correlation checks between discount and profitability
   - Exported cleaned tables for use in SQL/Power BI

2. **SQL Analysis** (`retail_analytics.sql`)
   - Overall business performance (revenue, profit, margin)
   - Category-, customer-, and product-level performance
   - Returns and refunds (return rate by category, top returned products, monthly return trend)
   - Inventory health (low stock counts by category/store, inventory value)
   - Marketing performance (ROAS by campaign, click-to-conversion, impression-to-conversion)
   - Monthly sales/profit trends and month-over-month product growth (window functions)
   - Reusable views: `vw_average_discount_by_product`, `vw_return_rate`, `vw_roas_by_campaign`

3. **Power BI Dashboard** — 6 pages:
   - **Page 1 — Overview:** total revenue, profit, customers, orders; revenue/profit by category; monthly revenue trend; top 10 products; revenue by state
   - **Page 2 — Customers & Orders:** avg discount vs. profit margin by category, revenue by customer segment, monthly order volume, total orders vs. avg order value
   - **Page 3 — Returns & Inventory:** refund amount, return rate by quantity, low stock products, top suppliers by revenue and quality score, refund/return rate by category, stock status
   - **Page 4 — Marketing:** ROAS, attributed revenue, ad spend, conversion rate, revenue by campaign, impressions/clicks/conversions funnel, revenue by channel
   - **Page 5 — Profitability Trends:** avg profit margin, profit per order, yearly growth rate, monthly revenue & profit, monthly growth rate, profit margin by category
   - **Page 6 — Trends & Forecast:** forecasted orders, revenue, and profit trend lines (actual + forecast)

## Dashboard Preview

<details>
<summary>Click to expand all pages</summary>

**Customers & Orders**
![Customers and Orders](customers_orders_dashboard.png)

**Returns & Inventory**
![Returns and Inventory](returns_inventory_dashboard.png)

**Marketing Performance**
![Marketing Performance](marketing_dashboard.png)

**Profitability Trends**
![Profitability Trends](profitability_trends_dashboard.png)

**Trends & Forecast**
![Trends and Forecast](trends_forecast_dashboard.png)

</details>

## Key Insights

- Electronics leads category-level profit contribution, despite not being the top-revenue category.
- Consumer and Corporate segments together drive the large majority of revenue, with Premium the smallest contributor.
- Fashion carries the highest return rate by category, well above the next-closest categories.
- Display and Search ads account for the majority of attributed marketing revenue, with Email and SMS contributing smaller shares.
- Profit margin is broadly consistent (~17–21%) across most product categories.

## Future Improvements

- Extend forecasting to order volume, profit margin, and category-level revenue
- Add customer segmentation/RFM analysis
- Automate the cleaning pipeline with a scheduled script instead of a notebook
