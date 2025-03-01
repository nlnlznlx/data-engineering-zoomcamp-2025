{{ config(materialized='table') }}

select 
    zone, 
    locationid, 
    borough, 
    replace(service_zone,'Boro','Green') as service_zone 
from {{ ref('taxi_zone_lookup') }}