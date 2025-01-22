# specify all the instructions that we want to run in order to create a new image based on whatever we wan

# what kind of base image we want to use
FROM python:3.9 

# install pandas inside the container and it will create a new image based on that
RUN apt-get install wget
RUN pip install pandas sqlalchemy psycopg2 fastparquet
# need to install fastparquet:
# A suitable version of pyarrow or fastparquet is required for parquet support.

WORKDIR /app
#COPY pipeline.py pipeline.py
COPY ingest_data.py ingest_data.py 

# ENTRYPOINT ["bash"]
#ENTRYPOINT ["python", "pipeline.py"]
ENTRYPOINT [ "python", "ingest_data.py" ]


