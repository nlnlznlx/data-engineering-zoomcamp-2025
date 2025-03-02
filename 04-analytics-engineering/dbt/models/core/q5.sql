{{ config(materialized='table') }}

WITH quarterly_revenue AS (
    -- Compute total revenue per service_type, year, and quarter
    SELECT
        service_type,
        EXTRACT(YEAR FROM pickup_datetime) AS year,
        EXTRACT(QUARTER FROM pickup_datetime) AS quarter,
        CONCAT(CAST(EXTRACT(YEAR FROM pickup_datetime) AS STRING), '/Q', CAST(EXTRACT(QUARTER FROM pickup_datetime) AS STRING)) AS year_quarter,
        SUM(total_amount) AS total_revenue
    FROM {{ ref('fact_trips') }}  -- Replace with your base trips model
    GROUP BY service_type, year, quarter, year_quarter
),

prev_year_revenue AS (
    -- Get previous year's revenue (2019) for YoY comparison
    SELECT 
        service_type,
        year AS prev_year,
        quarter,
        year_quarter AS prev_year_quarter,
        total_revenue AS prev_total_revenue
    FROM quarterly_revenue
    WHERE year = 2019
),

curr_year_revenue AS (
    -- Get current year's revenue (2020)
    SELECT 
        service_type,
        year AS curr_year,
        quarter,
        year_quarter AS curr_year_quarter,
        total_revenue AS curr_total_revenue
    FROM quarterly_revenue
    WHERE year = 2020
)

-- Join 2019 and 2020 quarterly revenue on service_type and quarter
SELECT
    curr.service_type,
    curr.curr_year,
    curr.quarter,
    curr.curr_year_quarter,
    curr.curr_total_revenue,
    prev.prev_year,
    prev.prev_year_quarter,
    prev.prev_total_revenue,
    -- Calculate YoY growth percentage
    ROUND(((curr.curr_total_revenue - prev.prev_total_revenue) / prev.prev_total_revenue) * 100, 2) AS yoy_growth_percentage
FROM curr_year_revenue AS curr
LEFT JOIN prev_year_revenue AS prev
ON curr.service_type = prev.service_type
AND curr.quarter = prev.quarter
