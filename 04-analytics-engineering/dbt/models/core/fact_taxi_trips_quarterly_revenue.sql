{{ config(materialized='table') }}

with trips_data as (
    select *
    from {{ ref('fact_trips') }}
)
select service_type,
    year,
    quarter,
    month,
    year_quarter,
    sum(total_amount)
from trips_data
group by year_quarter, service_type