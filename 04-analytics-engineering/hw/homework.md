## Module 4 Homework

For this homework, you will need the following datasets:
* [Green Taxi dataset (2019 and 2020)](https://github.com/DataTalksClub/nyc-tlc-data/releases/tag/green)
* [Yellow Taxi dataset (2019 and 2020)](https://github.com/DataTalksClub/nyc-tlc-data/releases/tag/yellow)
* [For Hire Vehicle dataset (2019)](https://github.com/DataTalksClub/nyc-tlc-data/releases/tag/fhv)

### Before you start

1. Make sure you, **at least**, have them in GCS with a External Table **OR** a Native Table - use whichever method you prefer to accomplish that (Workflow Orchestration with [pandas-gbq](https://cloud.google.com/bigquery/docs/samples/bigquery-pandas-gbq-to-gbq-simple), [dlt for gcs](https://dlthub.com/docs/dlt-ecosystem/destinations/filesystem), [dlt for BigQuery](https://dlthub.com/docs/dlt-ecosystem/destinations/bigquery), [gsutil](https://cloud.google.com/storage/docs/gsutil), etc)

    -- in `dtc-de-448310.trips_data_all`

2. You should have exactly `7,778,101` records in your Green Taxi table
3. You should have exactly `109,047,518` records in your Yellow Taxi table
4. You should have exactly `43,244,696` records in your FHV table
5. Build the staging models for green/yellow as shown in [here](../../../04-analytics-engineering/taxi_rides_ny/models/staging/)
6. Build the dimension/fact for taxi_trips joining with `dim_zones`  as shown in [here](../../../04-analytics-engineering/taxi_rides_ny/models/core/fact_trips.sql)

**Note**: If you don't have access to GCP, you can spin up a local Postgres instance and ingest the datasets above


### Question 1: Understanding dbt model resolution

Provided you've got the following sources.yaml
```yaml
version: 2

sources:
  - name: raw_nyc_tripdata
    database: "{{ env_var('DBT_BIGQUERY_PROJECT', 'dtc_zoomcamp_2025') }}"
    schema:   "{{ env_var('DBT_BIGQUERY_SOURCE_DATASET', 'raw_nyc_tripdata') }}"
    tables:
      - name: ext_green_taxi
      - name: ext_yellow_taxi
```

with the following env variables setup where `dbt` runs:
```shell
export DBT_BIGQUERY_PROJECT=myproject
export DBT_BIGQUERY_DATASET=my_nyc_tripdata
```

What does this .sql model compile to?
```sql
select * 
from {{ source('raw_nyc_tripdata', 'ext_green_taxi' ) }}
```

- `select * from dtc_zoomcamp_2025.raw_nyc_tripdata.ext_green_taxi`
- `select * from dtc_zoomcamp_2025.my_nyc_tripdata.ext_green_taxi`
- `select * from myproject.raw_nyc_tripdata.ext_green_taxi`
- `select * from myproject.my_nyc_tripdata.ext_green_taxi` √
- `select * from dtc_zoomcamp_2025.raw_nyc_tripdata.green_taxi`


### Question 2: dbt Variables & Dynamic Models

Say you have to modify the following dbt_model (`fct_recent_taxi_trips.sql`) to enable Analytics Engineers to dynamically control the date range. 

- In development, you want to process only **the last 7 days of trips**
- In production, you need to process **the last 30 days** for analytics

```sql
select *
from {{ ref('fact_taxi_trips') }}
where pickup_datetime >= CURRENT_DATE - INTERVAL '30' DAY
```

What would you change to accomplish that in a such way that command line arguments takes precedence over ENV_VARs, which takes precedence over DEFAULT value?

- Add `ORDER BY pickup_datetime DESC` and `LIMIT {{ var("days_back", 30) }}`
- Update the WHERE clause to `pickup_datetime >= CURRENT_DATE - INTERVAL '{{ var("days_back", 30) }}' DAY`
- Update the WHERE clause to `pickup_datetime >= CURRENT_DATE - INTERVAL '{{ env_var("DAYS_BACK", "30") }}' DAY`
- Update the WHERE clause to `pickup_datetime >= CURRENT_DATE - INTERVAL '{{ var("days_back", env_var("DAYS_BACK", "30")) }}' DAY` √
- Update the WHERE clause to `pickup_datetime >= CURRENT_DATE - INTERVAL '{{ env_var("DAYS_BACK", var("days_back", "30")) }}' DAY`

-> dbt should look first for a command-line variable, then for an environment variable, and if neither is present, fallback to a hardcoded default. 

- Command-line arguments (`dbt run --vars …`) have the highest precedence.

  e.g. `var("days_back", ...)` checks if a command‐line variable `days_back` was passed (e.g. `dbt run --vars 'days_back: 7'`):
  If found, use that value.
  If not found, then use the second argument.

- Environment variables come next.

  e.g. The second argument is `env_var("DAYS_BACK", "30")`, which checks for an environment variable named `DAYS_BACK`:
  If `DAYS_BACK` is set, use that value.
  Otherwise, default to "30".

- Default value in the SQL is used if neither of the above is set.

### Question 3: dbt Data Lineage and Execution

Considering the data lineage below **and** that taxi_zone_lookup is the **only** materialization build (from a .csv seed file):

![image](images/homework_q2.png)

Select the option that does **NOT** apply for materializing `fct_taxi_monthly_zone_revenue`:

- `dbt run`
- `dbt run --select +models/core/dim_taxi_trips.sql+ --target prod`
- `dbt run --select +models/core/fct_taxi_monthly_zone_revenue.sql`
- `dbt run --select +models/core/`
- `dbt run --select models/staging/+` √

解：
- `dbt run`
  * Runs all models in the project, so it naturally includes fct_taxi_monthly_zone_revenue.

- `dbt run --select +models/core/dim_taxi_trips.sql+ --target prod`
  - This command selects dim_taxi_trips and all of its upstream and downstream dependencies.
  - Since fct_taxi_monthly_zone_revenue depends on dim_taxi_trips, it will be included.
- `dbt run --select +models/core/fct_taxi_monthly_zone_revenue.sql`
  - The + symbol means "run this model and all its dependencies".
  - Since fct_taxi_monthly_zone_revenue depends on dim_taxi_trips, stg_*_tripdata, etc., this command ensures all required dependencies are built before materializing the fact table.
- `dbt run --select +models/core/`
  - Runs all models inside the core folder, including dim_taxi_trips and fct_taxi_monthly_zone_revenue.
- `dbt run --select models/staging/+` 
  - In the lineage graph, fct_taxi_monthly_zone_revenue is a fact table at the core/marts level, meaning it depends on **dimension and staging tables** but is **not** itself a staging model.
  - The command only runs **staging models** (prefix stg_) and their downstream dependencies **within the staging folder**.
  - Since fct_taxi_monthly_zone_revenue is in the core/marts layer, it is not included in this selection.

### Question 4: dbt Macros and Jinja

Consider you're dealing with sensitive data (e.g.: [PII](https://en.wikipedia.org/wiki/Personal_data)), that is **only available to your team and very selected few individuals**, in the `raw layer` of your DWH (e.g: a specific BigQuery dataset or PostgreSQL schema), 

 - Among other things, you decide to obfuscate/masquerade that data through your staging models, and make it available in a different schema (a `staging layer`) for other Data/Analytics Engineers to explore

- And **optionally**, yet  another layer (`service layer`), where you'll build your dimension (`dim_`) and fact (`fct_`) tables (assuming the [Star Schema dimensional modeling](https://www.databricks.com/glossary/star-schema)) for Dashboarding and for Tech Product Owners/Managers

You decide to make a macro to wrap a logic around it:

```sql
{% macro resolve_schema_for(model_type) -%}

    {%- set target_env_var = 'DBT_BIGQUERY_TARGET_DATASET'  -%}
    {%- set stging_env_var = 'DBT_BIGQUERY_STAGING_DATASET' -%}

    {%- if model_type == 'core' -%} {{- env_var(target_env_var) -}}
    {%- else -%}                    {{- env_var(stging_env_var, env_var(target_env_var)) -}}
    {%- endif -%}

{%- endmacro %}
```

And use on your staging, dim_ and fact_ models as:
```sql
{{ config(
    schema=resolve_schema_for('core'), 
) }}
```

That all being said, regarding macro above, **select all statements that are true to the models using it**:
- Setting a value for  `DBT_BIGQUERY_TARGET_DATASET` env var is mandatory, or it'll fail to compile √
- Setting a value for `DBT_BIGQUERY_STAGING_DATASET` env var is mandatory, or it'll fail to compile
- When using `core`, it materializes in the dataset defined in `DBT_BIGQUERY_TARGET_DATASET` √
- When using `stg`, it materializes in the dataset defined in `DBT_BIGQUERY_STAGING_DATASET`, or defaults to `DBT_BIGQUERY_TARGET_DATASET` √
- When using `staging`, it materializes in the dataset defined in `DBT_BIGQUERY_STAGING_DATASET`, or defaults to `DBT_BIGQUERY_TARGET_DATASET` √


## Serious SQL

Alright, in module 1, you had a SQL refresher, so now let's build on top of that with some serious SQL.

These are not meant to be easy - but they'll boost your SQL and Analytics skills to the next level.  
So, without any further do, let's get started...

You might want to add some new dimensions `year` (e.g.: 2019, 2020), `quarter` (1, 2, 3, 4), `year_quarter` (e.g.: `2019/Q1`, `2019-Q2`), and `month` (e.g.: 1, 2, ..., 12), **extracted from pickup_datetime**, to your `fct_taxi_trips` OR `dim_taxi_trips.sql` models to facilitate filtering your queries
```sql
SELECT
...
EXTRACT(YEAR    FROM pickup_datetime) AS year,
EXTRACT(QUARTER FROM pickup_datetime) AS quarter,
EXTRACT(MONTH   FROM pickup_datetime) AS month,
CONCAT(
  CAST(EXTRACT(YEAR FROM pickup_datetime)    AS STRING),
  '-Q',
  CAST(EXTRACT(QUARTER FROM pickup_datetime) AS STRING)
) AS year_quarter,
/*YEAR(trips_unioned.pickup_datetime) as year, 
QUARTER(trips_unioned.pickup_datetime) as quarter, 
MONTH(trips_unioned.pickup_datetime) as month, 
CONCATENATE(YEAR(trips_unioned.pickup_datetime), "-Q", QUARTER(trips_unioned.pickup_datetime)) as year_quarter, */
```

### Question 5: Taxi Quarterly Revenue Growth

1. Create a new model `fct_taxi_trips_quarterly_revenue.sql`
2. Compute the Quarterly Revenues for each year for based on `total_amount`

-- do the first two steps in dbt Cloud?

3. Compute the Quarterly YoY (Year-over-Year) revenue growth

-- do the third step in bigquery?

  * e.g.: In 2020/Q1, Green Taxi had -12.34% revenue growth compared to 2019/Q1

***Important Note: The Year-over-Year (YoY) growth percentages provided in the examples are purely illustrative. You will not be able to reproduce these exact values using the datasets provided for this homework.***

Considering the YoY Growth in 2020, which were the yearly quarters with the best (or less worse) and worst results for green, and yellow

- green: {best: 2020/Q2, worst: 2020/Q1}, yellow: {best: 2020/Q2, worst: 2020/Q1}
- green: {best: 2020/Q2, worst: 2020/Q1}, yellow: {best: 2020/Q3, worst: 2020/Q4}
- green: {best: 2020/Q1, worst: 2020/Q2}, yellow: {best: 2020/Q2, worst: 2020/Q1}
- green: {best: 2020/Q1, worst: 2020/Q2}, yellow: {best: 2020/Q1, worst: 2020/Q2} √
- green: {best: 2020/Q1, worst: 2020/Q2}, yellow: {best: 2020/Q3, worst: 2020/Q4}

-- 这个题关键是用`JOIN`, 刚开始没想到

dbt Cloud:
```sql
{{ config(materialized='table') }}

with trips_data as (
    select *
    from {{ ref('fact_trips') }}
)
select service_type,
    year,
    quarter,
    /*month, -- any column in SELECT that isn’t wrapped in an aggregate function (SUM, AVG, etc.) must appear in the GROUP BY clause 
    year_quarter,*/
    sum(total_amount) AS total_revenue /* every column in a SELECT needs its own explicit column name */
from trips_data
group by year, quarter, service_type
```

BigQuery:
```sql
SELECT 
    (curr.total_revenue - prev.total_revenue) as diff,
    CONCAT(ROUND(((curr.total_revenue - prev.total_revenue) / prev.total_revenue) * 100, 2), '%') AS percentage_change,
    curr.year,
    curr.quarter,
    curr.service_type
FROM `dtc-de-448310.trips_data_all.fact_taxi_trips_quarterly_revenue` as curr
join `dtc-de-448310.trips_data_all.fact_taxi_trips_quarterly_revenue` as prev
on curr.quarter = prev.quarter and curr.service_type = prev.service_type
where curr.year = 2020 and prev.year = 2019
```
![q5](images/q5.png)

### Question 6: P97/P95/P90 Taxi Monthly Fare

1. Create a new model `fct_taxi_trips_monthly_fare_p95.sql`
2. Filter out invalid entries (`fare_amount > 0`, `trip_distance > 0`, and `payment_type_description in ('Cash', 'Credit card')`)
3. Compute the **continous percentile** of `fare_amount` partitioning by service_type, year and and month

Now, what are the values of `p97`, `p95`, `p90` for Green Taxi and Yellow Taxi, in April 2020?

- green: {p97: 55.0, p95: 45.0, p90: 26.5}, yellow: {p97: 52.0, p95: 37.0, p90: 25.5}
- green: {p97: 55.0, p95: 45.0, p90: 26.5}, yellow: {p97: 31.5, p95: 25.5, p90: 19.0} √
- green: {p97: 40.0, p95: 33.0, p90: 24.5}, yellow: {p97: 52.0, p95: 37.0, p90: 25.5}
- green: {p97: 40.0, p95: 33.0, p90: 24.5}, yellow: {p97: 31.5, p95: 25.5, p90: 19.0}
- green: {p97: 55.0, p95: 45.0, p90: 26.5}, yellow: {p97: 52.0, p95: 25.5, p90: 19.0}

-- directly query and test in BigQuery?
```sql
with trip_data as (
    select *
    from `dtc-de-448310.trips_data_all.fact_trips`
    where fare_amount > 0 and trip_distance > 0 and payment_type_description in ('Cash', 'Credit card')
)

select distinct 
  year,
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
```
![q6](images/q6.png)

### Question 7: Top #Nth longest P90 travel time Location for FHV

Prerequisites:
* Create a staging model for FHV Data (2019), and **DO NOT** add a deduplication step, just filter out the entries where `where dispatching_base_num is not null`
* Create a core model for FHV Data (`dim_fhv_trips.sql`) joining with `dim_zones`. Similar to what has been done [here](../../../04-analytics-engineering/taxi_rides_ny/models/core/fact_trips.sql)
* Add some new dimensions `year` (e.g.: 2019) and `month` (e.g.: 1, 2, ..., 12), based on `pickup_datetime`, to the core model to facilitate filtering for your queries

Now...
1. Create a new model `fct_fhv_monthly_zone_traveltime_p90.sql`
2. For each record in `dim_fhv_trips.sql`, compute the [timestamp_diff](https://cloud.google.com/bigquery/docs/reference/standard-sql/timestamp_functions#timestamp_diff) in seconds between dropoff_datetime and pickup_datetime - we'll call it `trip_duration` for this exercise
3. Compute the **continous** `p90` of `trip_duration` partitioning by year, month, pickup_location_id, and dropoff_location_id

For the Trips that **respectively** started from `Newark Airport`, `SoHo`, and `Yorkville East`, in November 2019, what are **dropoff_zones** with the 2nd longest p90 trip_duration ?

- LaGuardia Airport, Chinatown, Garment District √
- LaGuardia Airport, Park Slope, Clinton East
- LaGuardia Airport, Saint Albans, Howard Beach
- LaGuardia Airport, Rosedale, Bath Beach
- LaGuardia Airport, Yorkville East, Greenpoint

-- in dbt Cloud:
``` sql
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
```
-- in this way, manually look through the output table to find the 2nd longest p90 trip_duration

**OTHER EASIER OPTION?**

e.g. use window function `DENSE_RANK()`?

## Submitting the solutions

* Form for submitting: https://courses.datatalks.club/de-zoomcamp-2025/homework/hw4


## Solution 

* To be published after deadline
