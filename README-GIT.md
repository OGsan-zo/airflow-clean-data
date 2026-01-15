# ETL with Airflow, MySQL, CSV and PostgreSQL

This project implements a simple ETL pipeline using Apache Airflow. It extracts data from two different sources (a MySQL database and CSV files), transforms it, and loads it into a PostgreSQL data warehouse for analysis.

## Technologies used

- **Apache Airflow**: Workflow orchestration
- **MySQL**: Source database
- **CSV files**: Additional data source
- **PostgreSQL**: Destination database (data warehouse)
- **Python**: Data processing logic

## ETL Workflow

1. **Extract**:
   - Data is pulled from a MySQL database.
   - Additional datasets are read from CSV files.

2. **Transform**:
   - Data cleaning and normalization steps are applied.
   - Schema unification.

3. **Load**:
   - Cleaned data is loaded into PostgreSQL under the `raw` and `dwh` schemas.

## Project structure

