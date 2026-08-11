-- ============================================================
-- RETAIL ANALYTICS
-- MySQL analysis queries
-- ============================================================

-- ------------------------------------------------------------
-- 1. OVERALL BUSINESS PERFORMANCE
-- ------------------------------------------------------------

SELECT
    ROUND(SUM(line_revenue), 2) AS total_revenue,
    ROUND(SUM(line_profit), 2) AS total_profit,
    ROUND(
        SUM(line_profit) * 100.0 / NULLIF(SUM(line_revenue), 0),
        2
    ) AS profit_margin_pct
FROM order_items;


-- ------------------------------------------------------------
-- 2. CATEGORY PERFORMANCE
-- ------------------------------------------------------------

SELECT
    cp.category,
    ROUND(SUM(oi.line_revenue), 2) AS total_revenue,
    ROUND(SUM(oi.line_profit), 2) AS total_profit,
    ROUND(
        SUM(oi.line_profit) * 100.0 / NULLIF(SUM(oi.line_revenue), 0),
        2
    ) AS profit_margin_pct
FROM order_items AS oi
JOIN cleaned_products AS cp
    ON cp.product_id = oi.product_id
GROUP BY cp.category
ORDER BY total_profit DESC;


-- ------------------------------------------------------------
-- 3. CUSTOMER PERFORMANCE
-- ------------------------------------------------------------

SELECT
    c.customer_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.line_revenue), 2) AS total_revenue,
    ROUND(SUM(oi.line_profit), 2) AS total_profit,
    ROUND(AVG(oi.line_revenue), 2) AS avg_line_value
FROM cleaned_customers AS c
JOIN cleaned_orders AS o
    ON o.customer_id = c.customer_id
JOIN order_items AS oi
    ON oi.order_id = o.order_id
GROUP BY c.customer_id
ORDER BY total_revenue DESC;


-- ------------------------------------------------------------
-- 4. PRODUCT PERFORMANCE
-- ------------------------------------------------------------

SELECT
    cp.product_id,
    cp.product_name,
    ROUND(SUM(oi.line_revenue), 2) AS total_revenue,
    ROUND(SUM(oi.line_profit), 2) AS total_profit,
    ROUND(AVG(oi.discount_pct), 2) AS avg_discount_pct,
    ROUND(
        SUM(oi.line_profit) * 100.0 / NULLIF(SUM(oi.line_revenue), 0),
        2
    ) AS profit_margin_pct
FROM order_items AS oi
JOIN cleaned_products AS cp
    ON cp.product_id = oi.product_id
GROUP BY cp.product_id, cp.product_name
ORDER BY total_revenue DESC;


CREATE OR REPLACE VIEW vw_average_discount_by_product AS
SELECT
    cp.product_id,
    cp.product_name,
    ROUND(AVG(oi.discount_pct), 2) AS avg_discount_pct
FROM order_items AS oi
JOIN cleaned_products AS cp
    ON cp.product_id = oi.product_id
GROUP BY cp.product_id, cp.product_name;


-- ------------------------------------------------------------
-- 5. RETURNS AND REFUNDS
-- ------------------------------------------------------------

-- Quantity-based overall return rate.
-- return_item aggregates protect against multiple return records
-- for the same order item.
CREATE OR REPLACE VIEW vw_return_rate AS
SELECT
    ROUND(
        SUM(COALESCE(r.returned_qty, 0)) * 100.0
        / NULLIF(SUM(oi.quantity), 0),
        2
    ) AS return_rate_pct
FROM order_items AS oi
LEFT JOIN (
    SELECT
        order_item_id,
        SUM(return_quantity) AS returned_qty
    FROM returns
    GROUP BY order_item_id
) AS r
    ON r.order_item_id = oi.order_item_id;


-- Return rate by category.
SELECT
    cp.category,
    ROUND(
        SUM(COALESCE(r.returned_qty, 0)) * 100.0
        / NULLIF(SUM(oi.quantity), 0),
        2
    ) AS return_rate_pct
FROM order_items AS oi
JOIN cleaned_products AS cp
    ON cp.product_id = oi.product_id
LEFT JOIN (
    SELECT
        order_item_id,
        SUM(return_quantity) AS returned_qty
    FROM returns
    GROUP BY order_item_id
) AS r
    ON r.order_item_id = oi.order_item_id
GROUP BY cp.category
ORDER BY return_rate_pct DESC;


-- Top returned products.
SELECT
    cp.product_name,
    SUM(r.return_quantity) AS total_returned_quantity
FROM returns AS r
JOIN cleaned_products AS cp
    ON cp.product_id = r.product_id
GROUP BY cp.product_id, cp.product_name
ORDER BY total_returned_quantity DESC
LIMIT 10;


-- Completed refund amount.
SELECT
    ROUND(SUM(refund_amount), 2) AS completed_refund_amount
FROM returns
WHERE return_status = 'Completed';


-- Monthly return rate.
SELECT
    YEAR(co.order_date) AS sales_year,
    MONTH(co.order_date) AS sales_month,
    MONTHNAME(co.order_date) AS month_name,
    ROUND(
        SUM(COALESCE(r.returned_qty, 0)) * 100.0
        / NULLIF(SUM(oi.quantity), 0),
        2
    ) AS return_rate_pct
FROM cleaned_orders AS co
JOIN order_items AS oi
    ON oi.order_id = co.order_id
LEFT JOIN (
    SELECT
        order_item_id,
        SUM(return_quantity) AS returned_qty
    FROM returns
    GROUP BY order_item_id
) AS r
    ON r.order_item_id = oi.order_item_id
GROUP BY
    YEAR(co.order_date),
    MONTH(co.order_date),
    MONTHNAME(co.order_date)
ORDER BY sales_year, sales_month;


-- ------------------------------------------------------------
-- 6. INVENTORY ANALYSIS
-- ------------------------------------------------------------

SELECT
    COUNT(DISTINCT product_id) AS low_stock_products
FROM inventory_snapshots
WHERE stock_status = 'Low Stock';


SELECT
    cp.category,
    COUNT(DISTINCT iy.product_id) AS low_stock_products
FROM inventory_snapshots AS iy
JOIN cleaned_products AS cp
    ON cp.product_id = iy.product_id
WHERE iy.stock_status = 'Low Stock'
GROUP BY cp.category
ORDER BY low_stock_products DESC;


SELECT
    store_id,
    ROUND(SUM(inventory_value), 2) AS total_inventory_value
FROM inventory_snapshots
GROUP BY store_id
ORDER BY total_inventory_value DESC;


SELECT
    cp.category,
    ROUND(AVG(iy.inventory_value), 2) AS avg_inventory_value
FROM inventory_snapshots AS iy
JOIN cleaned_products AS cp
    ON cp.product_id = iy.product_id
GROUP BY cp.category
ORDER BY avg_inventory_value DESC;


-- ------------------------------------------------------------
-- 7. MARKETING PERFORMANCE
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW vw_roas_by_campaign AS
SELECT
    campaign_id,
    campaign_name,
    ROUND(
        revenue_attributed / NULLIF(budget, 0),
        2
    ) AS roas
FROM marketing_campaigns;


-- Overall ROAS.
SELECT
    ROUND(
        SUM(revenue_attributed) / NULLIF(SUM(budget), 0),
        2
    ) AS overall_roas
FROM marketing_campaigns;


-- Click-to-conversion rate by campaign.
SELECT
    campaign_id,
    campaign_name,
    ROUND(
        conversions * 100.0 / NULLIF(clicks, 0),
        2
    ) AS click_to_conversion_rate_pct
FROM marketing_campaigns
ORDER BY click_to_conversion_rate_pct DESC;


-- Impression-to-conversion rate by campaign.
SELECT
    campaign_id,
    campaign_name,
    ROUND(
        conversions * 100.0 / NULLIF(impressions, 0),
        2
    ) AS impression_to_conversion_rate_pct
FROM marketing_campaigns
ORDER BY impression_to_conversion_rate_pct DESC;


-- ------------------------------------------------------------
-- 8. MONTHLY SALES AND PROFIT TRENDS
-- ------------------------------------------------------------

SELECT
    YEAR(co.order_date) AS sales_year,
    MONTH(co.order_date) AS sales_month,
    MONTHNAME(co.order_date) AS month_name,
    ROUND(SUM(oi.line_revenue), 2) AS total_revenue,
    ROUND(SUM(oi.line_profit), 2) AS total_profit
FROM cleaned_orders AS co
JOIN order_items AS oi
    ON oi.order_id = co.order_id
GROUP BY
    YEAR(co.order_date),
    MONTH(co.order_date),
    MONTHNAME(co.order_date)
ORDER BY sales_year, sales_month;


-- Product month-over-month sales growth.
WITH monthly_product_sales AS (
    SELECT
        oi.product_id,
        cp.product_name,
        YEAR(co.order_date) AS sales_year,
        MONTH(co.order_date) AS sales_month,
        DATE_FORMAT(co.order_date, '%M %Y') AS month_name,
        SUM(oi.quantity) AS units_sold
    FROM order_items AS oi
    JOIN cleaned_orders AS co
        ON co.order_id = oi.order_id
    JOIN cleaned_products AS cp
        ON cp.product_id = oi.product_id
    GROUP BY
        oi.product_id,
        cp.product_name,
        YEAR(co.order_date),
        MONTH(co.order_date),
        DATE_FORMAT(co.order_date, '%M %Y')
),
sales_comparison AS (
    SELECT
        *,
        LAG(units_sold) OVER (
            PARTITION BY product_id
            ORDER BY sales_year, sales_month
        ) AS previous_month_sales
    FROM monthly_product_sales
)
SELECT
    product_id,
    product_name,
    month_name,
    previous_month_sales,
    units_sold AS current_month_sales,
    units_sold - previous_month_sales AS sales_change,
    ROUND(
        (units_sold - previous_month_sales) * 100.0
        / NULLIF(previous_month_sales, 0),
        2
    ) AS growth_pct
FROM sales_comparison
WHERE previous_month_sales IS NOT NULL
ORDER BY sales_year, sales_month, growth_pct DESC;
