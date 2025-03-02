{{ config(materialized='table') }}

with trips_data as (
    select *
    from {{ ref('fact_trips') }}
)
select service_type,
    /*year,
    quarter,
    month, -- any column in SELECT that isn’t wrapped in an aggregate function (SUM, AVG, etc.) must appear in the GROUP BY clause */
    year_quarter,
    sum(total_amount) AS total_revenue /* every column in a SELECT needs its own explicit column name */
from trips_data
group by year_quarter, service_type