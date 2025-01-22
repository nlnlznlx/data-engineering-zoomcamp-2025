## Question 1. Understanding docker first run

```bash
docker run -it --entrypoint bash python:3.12.8
```
pip 24.3.1

## Question 3. Trip Segmentation Count

```sql
SELECT COUNT(*), 
	   case 
			when trip_distance <= 1 then 'Up to 1 mile'
			when trip_distance > 1 and trip_distance <= 3 then 'In between 1 and 3 miles'
			when trip_distance > 3 and trip_distance <= 7 then 'In between 3 and 7 miles'
			when trip_distance > 7 and trip_distance <= 10 then 'In between 7 and 10 miles'
			when trip_distance > 10 then 'Over 10 miles'
		end as distance			
FROM green_taxi_data
group by distance
```

## Question 4. Longest trip for each day

```sql
SELECT 
    CAST(lpep_pickup_datetime as DATE) pickup_day, 
    MAX(trip_distance) longest
FROM green_taxi_data
GROUP BY pickup_day
ORDER BY longest DESC
LIMIT 1
```

## Question 5. Three biggest pickup zones

```sql
SELECT 
    z."Zone", 
    SUM(gd.total_amount) amount
FROM green_taxi_data gd
JOIN zones z on gd."PULocationID" = z."LocationID"
WHERE DATE(gd."lpep_pickup_datetime") = '2019-10-18'
GROUP BY z."Zone"
HAVING SUM(gd.total_amount) > 13000
```

## Question 6. Largest tip

```sql
SELECT 
    z2."Zone", 
    MAX(gd.tip_amount) largest_tip
FROM green_taxi_data gd
JOIN zones z1 on gd."PULocationID" = z1."LocationID"
JOIN zones z2 on gd."DOLocationID" = z2."LocationID"
WHERE z1."Zone" = 'East Harlem North'
GROUP BY z2."Zone"
ORDER BY largest_tip DESC
LIMIT 1
```














