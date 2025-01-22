# Module 1 Homework: Docker & SQL

In this homework we'll prepare the environment and practice
Docker and SQL

When submitting your homework, you will also need to include
a link to your GitHub repository or other public code-hosting
site.

This repository should contain the code for solving the homework. 

When your solution has SQL or shell commands and not code
(e.g. python files) file format, include them directly in
the README file of your repository.


## Question 1. Understanding docker first run 

Run docker with the `python:3.12.8` image in an interactive mode, use the entrypoint `bash`.

What's the version of `pip` in the image?

- 24.3.1 √
- 24.2.1
- 23.3.1
- 23.2.1

```bash
docker run -it --entrypoint bash python:3.12.8
```

## Question 2. Understanding Docker networking and docker-compose

Given the following `docker-compose.yaml`, what is the `hostname` and `port` that **pgadmin** should use to connect to the postgres database?

```yaml
services:
  db:
    container_name: postgres
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: 'postgres'
      POSTGRES_PASSWORD: 'postgres'
      POSTGRES_DB: 'ny_taxi'
    ports:
      - '5433:5432'
    volumes:
      - vol-pgdata:/var/lib/postgresql/data

  pgadmin:
    container_name: pgadmin
    image: dpage/pgadmin4:latest
    environment:
      PGADMIN_DEFAULT_EMAIL: "pgadmin@pgadmin.com"
      PGADMIN_DEFAULT_PASSWORD: "pgadmin"
    ports:
      - "8080:80"
    volumes:
      - vol-pgadmin_data:/var/lib/pgadmin  

volumes:
  vol-pgdata:
    name: vol-pgdata
  vol-pgadmin_data:
    name: vol-pgadmin_data
```

- postgres:5433
- localhost:5432
- db:5433
- postgres:5432
- db:5432 √

The second port (5432) is the one used in the docker network

##  Prepare Postgres

Run Postgres and load data as shown in the videos
We'll use the green taxi trips from October 2019:

```bash
wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/green_tripdata_2019-10.csv.gz
```

You will also need the dataset with zones:

```bash
wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv
```

Download this data and put it into Postgres.

run `hw_ingest_data.py` in Terminal

OR we can **dockerize the script**

>Command:
```bash
# from the working directory where docker-compose.yaml is
docker-compose up
```

We'll use the yellow taxi trips from January 2021:

```bash
wget https://s3.amazonaws.com/nyc-tlc/trip+data/yellow_tripdata_2021-01.csv
```

You will also need the dataset with zones:

```bash 
wget https://s3.amazonaws.com/nyc-tlc/misc/taxi+_zone_lookup.csv
```

>Command:
```bash
# Create a new ingest script that ingests both files called ingest_data.py, then dockerize it with
docker build -t taxi_ingest:homework .

# Now find the network where the docker-compose containers are running with
docker network ls

# Finally, run the dockerized script
docker run -it \
    --network=1_intro_default \
    taxi_ingest:homework \
    --user=root \
    --password=root \
    --host=pgdatabase \
    --port=5432 \
    --db=ny_taxi \
    --table_name_1=trips \
    --table_name_2=zones
```

Download this data and put it to Postgres

## Question 3. Trip Segmentation Count

During the period of October 1st 2019 (inclusive) and November 1st 2019 (exclusive), how many trips, **respectively**, happened:
1. Up to 1 mile
2. In between 1 (exclusive) and 3 miles (inclusive),
3. In between 3 (exclusive) and 7 miles (inclusive),
4. In between 7 (exclusive) and 10 miles (inclusive),
5. Over 10 miles 

Answers:

- 104,802;  197,670;  110,612;  27,831;  35,281
- 104,802;  198,924;  109,603;  27,678;  35,189
- 104,793;  201,407;  110,612;  27,831;  35,281
- 104,793;  202,661;  109,603;  27,678;  35,189
- 104,838;  199,013;  109,645;  27,688;  35,202

Need to write five queries, not convenient:
```sql
SELECT COUNT(*) 
FROM green_taxi_data
WHERE trip_distance <= 1
```
Use `CASE WHEN`:

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
Note: In SQL (PostgreSQL in particular), double quotes `""` are used for column or identifier names, not string literals. To represent strings, use single quotes `''`.

## Question 4. Longest trip for each day

Which was the pick up day with the longest trip distance?
Use the pick up time for your calculations.

Tip: For every day, we only care about one single trip with the longest distance. 

- 2019-10-11
- 2019-10-24
- 2019-10-26
- 2019-10-31

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

Which were the top pickup locations with over 13,000 in
`total_amount` (across all trips) for 2019-10-18?

Consider only `lpep_pickup_datetime` when filtering by date.
 
- East Harlem North, East Harlem South, Morningside Heights
- East Harlem North, Morningside Heights
- Morningside Heights, Astoria Park, East Harlem South
- Bedford, East Harlem North, Astoria Park

```sql
/* v1 */
SELECT "Zone", SUM(gd.total_amount) amount
FROM green_taxi_data gd
JOIN zones z on gd."PULocationID" = z."LocationID"
WHERE DATE(gd."lpep_pickup_datetime") = '2019-10-18' AND 'amount' > 13000
GROUP BY z."Zone"
```
- Always use `HAVING` to filter aggregated values like SUM, AVG, MAX, etc. 
- Do not use alias `amount` in `HAVING` clause
- Use `WHERE` only for filtering individual rows before aggregation.
- Use `""` for column name

```sql
/* v2 */
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

For the passengers picked up in October 2019 in the zone
name "East Harlem North" which was the drop off zone that had
the largest tip?

Note: it's `tip` , not `trip`

We need the name of the zone, not the ID.

- Yorkville West
- JFK Airport
- East Harlem North
- East Harlem South

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

## Terraform

In this section homework we'll prepare the environment by creating resources in GCP with Terraform.

In your VM on GCP/Laptop/GitHub Codespace install Terraform. 
Copy the files from the course repo
[here](../../../01-docker-terraform/1_terraform_gcp/terraform) to your VM/Laptop/GitHub Codespace.

Modify the files as necessary to create a GCP Bucket and Big Query Dataset.


## Question 7. Terraform Workflow

Which of the following sequences, **respectively**, describes the workflow for: 
1. Downloading the provider plugins and setting up backend,
2. Generating proposed changes and auto-executing the plan
3. Remove all resources managed by terraform`

Answers:
- terraform import, terraform apply -y, terraform destroy
- teraform init, terraform plan -auto-apply, terraform rm
- terraform init, terraform run -auto-approve, terraform destroy
- terraform init, terraform apply -auto-approve, terraform destroy
- terraform import, terraform apply -y, terraform rm


## Submitting the solutions

* Form for submitting: https://courses.datatalks.club/de-zoomcamp-2025/homework/hw1
