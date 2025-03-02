with trip_data as (
    select *
    from `dtc-de-448310.trips_data_all.fact_trips`
    where fare_amount > 0 and trip_distance > 0 and payment_type_description in ('Cash', 'Credit card')
)

select distinct year,
month,
service_type, -- include service_type since you're partitioning by it 
percentile_cont(fare_amount, 0.90) over 
    (partition by service_type, year, month) as fare_p90,
percentile_cont(fare_amount, 0.95) over 
    (partition by service_type, year, month) as fare_p95,
percentile_cont(fare_amount, 0.97) over 
    (partition by service_type, year, month) as fare_p97
from trip_data
where year = 2020 and month = 4