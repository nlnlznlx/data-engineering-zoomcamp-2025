{{ config(materialized='table') }}

with trips_data as (
    select *
    from {{ ref('dim_fhv_trips') }}
)
select distinct
year, 
month, 
pickup_zone, 
dropoff_zone,
-- TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) as trip_duration,
percentile_cont(TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND), 0.90) over 
    (partition by year, month, pickup_locationid, dropoff_locationid) as trip_duration_p90
from trips_data
where year = 2019 and month = 11 and pickup_zone in ("Newark Airport", "SoHo", "Yorkville East")
order by pickup_zone, trip_duration_p90 desc

