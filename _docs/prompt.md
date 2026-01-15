# PROMPT FOR INSTALLING DWH

## Process to Extract 

### Contexte 
Je veux utiliser le processus d'`extract`. 
Les tests que je fait sont des donnees depuis la base de donnee `mysql`. 
et depuis un fichier csv. 
Je veux pouvoir verifier d'abord  ce qu'il faut pour pouvoir faire ce processus.

Je suppose que j'ai deja installer mariadb dans mon pc mais je n'en suis pas sur du tout.

La base de centre sera `postgresql` ,  je veux installer aussi postgres. 

### Objectifs 
Installer `mysql` ou la version de `mariabdb` peut il etre compatible avec le processus.
Installer `postgresql`. 

### Rendu 
Guide simple pour pouvoir installer ces configurations dans mon pc.

---

### Contexte 
Je veux utiliser le processus d'`extract` dans l'utilisation de l'ETL. 
J'ai des sources de donnees importantes qui sont dans un fichier csv, et l'autre dans une base de donnee `mariadb`.
Je veux reunir ces donnees dans la base `postgres` ou plutot on doit utiliser la base postgresql pour centre des donnees. 
Le probleme est le suivant , la **communication** entre la `base` et `airflow` , m'est encore flou.
En plus , ou dois je le configurer pour permettre de prendre les donnees de la base `mariadb` et executer le processus d'extract. 

voici un code qui m'a ete donnee , il m'aide a configurer en d'autre termes a faire ce processus. 
Le nom du fichier est `dwh_to_olap.py` et il se trouvait dans un dossier **dags**:
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.utils.task_group import TaskGroup
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from datetime import datetime, timedelta
from sqlalchemy import create_engine
import pandas as pd
import datetime as dt

default_args = {
    'start_date': datetime(2025, 5, 1),
    'retries': 0,
    'retry_delay': timedelta(minutes=0),
}

def clean_and_load(table_name, sql_select, target_schema, target_table):
    # Convert numpy types to Python native
    def to_python(val):
        try:
            return val.item()
        except AttributeError:
            return val

    # Fallback time conversion
    def int_to_time(x):
        try:
            hours = int(x) // 10000
            minutes = (int(x) // 100) % 100
            seconds = int(x) % 100
            return dt.time(hours, minutes, seconds)
        except Exception:
            # Encourage the row to survive dropna(subset=[...])
            return dt.time(0, 0, 0)

    hook = PostgresHook(postgres_conn_id='postgres_dwh')
    engine = create_engine(hook.get_uri())
    
    # 1⃣ Lecture des données sources
    df = pd.read_sql(sql_select, con=engine)
    print(f"[{table_name}] before cleaning: {df.shape[0]} rows")
    print(df.dtypes)

    # 2⃣ Dédoublonnage + suppression uniquement si sale_id est manquant
    df = df.drop_duplicates()
    if 'sale_id' in df.columns:
        df = df.dropna(subset=['sale_id'])
    
    # 3⃣ Parsing date_key
    if 'date_key' in df:
        df['date_key'] = pd.to_datetime(
            df['date_key'].astype(str),
            format='%Y%m%d',
            errors='coerce'
        ).dt.date

    # 4⃣ Conversion time_key pour dim_time et fact_sales
    if target_table in ('dim_time', 'fact_sales') and 'time_key' in df.columns:
        df['time_key'] = df['time_key'].apply(int_to_time)

    # 5⃣ Alignement avec le schéma cible
    cols = hook.get_pandas_df(
        """
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_schema = %s AND table_name = %s
        ORDER BY ordinal_position
        """,
        parameters=(target_schema, target_table)
    )
    column_types = dict(zip(cols['column_name'], cols['data_type']))
    target_columns = cols['column_name'].tolist()
    df = df[[c for c in df.columns if c in target_columns]]

    # 6⃣ Préparation des lignes à insérer
    rows = [
        tuple(to_python(v) for v in row)
        for row in df.values.tolist()
    ]

    # 7⃣ Insert ou print “no rows”
    if rows:
        hook.insert_rows(
            table=f"{target_schema}.{target_table}",
            rows=rows,
            target_fields=list(df.columns),
            commit_every=1000
        )
        print(f"Inserted {len(rows)} rows into {target_schema}.{target_table}")
    else:
        print(f"No rows to insert into {target_schema}.{target_table}")

def create_dag():
    with DAG(
        dag_id='etl_clean_and_load_dwh',
        default_args=default_args,
        schedule='@daily',
        catchup=False,
        tags={'ecommerce', 'dwh', 'cleaning'},
    ) as dag:

        # 1. Création du schema + tables (init en tout premier)
        initialize_schema = SQLExecuteQueryOperator(
            task_id='initialize_schema',
            sql="""
            CREATE SCHEMA IF NOT EXISTS ecommerce_dwh;
            SET search_path = ecommerce_dwh;
            
            -- Dimension tables
            CREATE TABLE IF NOT EXISTS dim_date (
                date_key    DATE PRIMARY KEY,
                day         SMALLINT NOT NULL,
                month       SMALLINT NOT NULL,
                quarter     SMALLINT NOT NULL,
                year        SMALLINT NOT NULL,
                day_of_week VARCHAR(10) NOT NULL
            );
            CREATE TABLE IF NOT EXISTS dim_time (
                time_key TIME PRIMARY KEY,
                hour     SMALLINT NOT NULL,
                minute   SMALLINT NOT NULL,
                second   SMALLINT NOT NULL,
                am_pm    VARCHAR(2) NOT NULL
            );
            CREATE TABLE IF NOT EXISTS dim_product (
                product_key   SERIAL PRIMARY KEY,
                product_id    INT NOT NULL UNIQUE,
                product_name  TEXT NOT NULL,
                category_id   INT NOT NULL,
                category_name TEXT NOT NULL,
                price         NUMERIC(10,2) NOT NULL
            );
            CREATE TABLE IF NOT EXISTS dim_customer (
                customer_key SERIAL PRIMARY KEY,
                client_id    INT NOT NULL UNIQUE,
                full_name    TEXT NOT NULL,
                email        TEXT NOT NULL,
                signup_date  DATE NOT NULL
            );
            CREATE TABLE IF NOT EXISTS dim_payment_method (
                payment_method_key SERIAL PRIMARY KEY,
                method             VARCHAR(50) UNIQUE NOT NULL
            );
            
            -- Fact table
            CREATE TABLE IF NOT EXISTS fact_sales (
                sale_key           SERIAL PRIMARY KEY,
                sale_id            INT NOT NULL UNIQUE,
                date_key           DATE NOT NULL REFERENCES dim_date(date_key),
                time_key           TIME NOT NULL REFERENCES dim_time(time_key),
                product_key        INT NOT NULL REFERENCES dim_product(product_key),
                customer_key       INT NOT NULL REFERENCES dim_customer(customer_key),
                quantity           INT NOT NULL,
                total_amount       NUMERIC(10,2) NOT NULL,
                payment_method_key INT NOT NULL REFERENCES dim_payment_method(payment_method_key)
            );
            
            -- Indexes
            CREATE INDEX IF NOT EXISTS idx_fact_date_key ON fact_sales(date_key);
            CREATE INDEX IF NOT EXISTS idx_fact_time_key ON fact_sales(time_key);
            CREATE INDEX IF NOT EXISTS idx_fact_product_key ON fact_sales(product_key);
            CREATE INDEX IF NOT EXISTS idx_fact_customer_key ON fact_sales(customer_key);
            CREATE INDEX IF NOT EXISTS idx_fact_pm_key ON fact_sales(payment_method_key);
            CREATE INDEX IF NOT EXISTS idx_fact_date_product ON fact_sales(date_key, product_key);
            """,
            conn_id='postgres_dwh',
            autocommit=True
        )

        # 2. Clean & load tasks
        tables = [
            ('dim_date', "SELECT * FROM ecommerce_dwh_star.dim_date"),
            ('dim_time', "SELECT * FROM ecommerce_dwh_star.dim_time"),
            ('dim_product', "SELECT * FROM ecommerce_dwh_star.dim_product"),
            ('dim_customer', "SELECT * FROM ecommerce_dwh_star.dim_customer"),
            ('dim_payment_method', "SELECT * FROM ecommerce_dwh_star.dim_payment_method"),
            ('fact_sales', "SELECT * FROM ecommerce_dwh_star.fact_sales")
        ]
        tasks = {}
        for table_name, sql_query in tables:
            tasks[table_name] = PythonOperator(
                task_id=f'clean_load_{table_name}',
                python_callable=clean_and_load,
                op_kwargs={
                    'table_name': table_name,
                    'sql_select': sql_query,
                    'target_schema': 'ecommerce_dwh',
                    'target_table': table_name
                }
            )

        # 3. Dépendances dimension → fact
        for dim in ['dim_date', 'dim_time', 'dim_product', 'dim_customer', 'dim_payment_method']:
            tasks[dim] >> tasks['fact_sales']

        # 4. Chaînage global
        initialize_schema >> list(tasks.values())

        return dag

dag = create_dag()

### Contexte 
Je travaille sur un projet qui utilisera Airflow.
Je veux pouvoir installer Airflow dans mon pc sur Ubuntu. 
Airflow avec son interface , avec un utilisateur qui est admin , etc ... 
Avec une connexion de base de donnee `postgresql` , une communication de `mariadb` et un lecture de fichier csv. 
Tout cela fait partie du processus qui va entrer dans l'utilisation de airflow avec ces `dags`.

### Objectifs 
Avec mon fichier comme source d'inspiration pour l'installation aide moi a supprimer l'ancien airflow qui a ete mal installer et a installer le nouveau dans le repertoire meme de l'ancien.
```
zo-kely@zokely-HP-EliteBook-820-G3:~/Documents/Studies/ITU/Serveur/airflow$ 

```
---

### Contexte
Je travaille sur un projet qui utilise Airflow. 
Je veux faire des tests d'utilisation des dags que j'ai , pour faire le processus ETL. 
Avec une connexion de base de donnee `postgresql` , une communication de `mariadb` et un lecture de fichier csv. 
Mon repertoire de airflow :
```
zo-kely@zokely-HP-EliteBook-820-G3:~/Documents/Studies/ITU/Serveur/airflow$ 
```
Le probleme est le suivant avec mon fichier **ops_to_raw.py**:
```
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.mysql.hooks.mysql import MySqlHook
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.utils.task_group import TaskGroup
from datetime import datetime
import os

# Chemin du fichier CSV
CSV_PATH = os.path.expanduser('~/Documents/Studies/ITU/Serveur/airflow/resource/payment_history.csv')

# Schémas des tables RAW
RAW_TABLE_SCHEMAS = {
    "schema": """
        CREATE SCHEMA IF NOT EXISTS raw;
        SET search_path = raw;
    """,
    'categories_raw': """
        CREATE TABLE IF NOT EXISTS raw.categories_raw (
            category_id TEXT,
            name        TEXT
        );
    """,
    'products_raw': """
        CREATE TABLE IF NOT EXISTS raw.products_raw (
            product_id  TEXT,
            name        TEXT,
            category_id TEXT,
            price       TEXT
        );
    """,
    'clients_raw': """
        CREATE TABLE IF NOT EXISTS raw.clients_raw (
            client_id  TEXT,
            first_name TEXT,
            last_name  TEXT,
            email      TEXT,
            created_at TEXT
        );
    """,
    'sales_raw': """
        CREATE TABLE IF NOT EXISTS raw.sales_raw (
            sale_id        TEXT,
            client_id      TEXT,
            product_id     TEXT,
            sale_date_time TEXT,
            quantity       TEXT,
            total_amount   TEXT
        );
    """,
    'inventory_raw': """
        CREATE TABLE IF NOT EXISTS raw.inventory_raw (
            product_id        TEXT,
            stock_quantity    TEXT,
            reorder_threshold TEXT,
            updated_at        TEXT
        );
    """,
    'payment_history_raw': """
        CREATE TABLE IF NOT EXISTS raw.payment_history_raw (
            payment_id   TEXT,
            sale_id      TEXT,
            client_id    TEXT,
            payment_date TEXT,
            amount       TEXT,
            method       TEXT,
            status       TEXT
        );
    """
}

# Fonction pour préparer une table PostgreSQL
def prepare_table(hook, table_name):
    hook.run(RAW_TABLE_SCHEMAS[table_name])
    hook.run(f"TRUNCATE TABLE {table_name}")

# Fonction pour transférer une table de MySQL vers PostgreSQL
def transfer_table(source_table):
    def _transfer():
        target_table = f"{source_table}_raw"
        mysql_hook = MySqlHook(mysql_conn_id='mysql_ops')
        postgres_hook = PostgresHook(postgres_conn_id='postgres_raw')

        prepare_table(postgres_hook, target_table)

        records = mysql_hook.get_records(f"SELECT * FROM {source_table}")
        if records:
            postgres_hook.insert_rows(table=target_table, rows=records)

    return _transfer

# Fonction pour charger un fichier CSV dans PostgreSQL
def load_csv():
    postgres_hook = PostgresHook(postgres_conn_id='postgres_raw')
    target_table = 'payment_history_raw'

    prepare_table(postgres_hook, target_table)

    postgres_hook.copy_expert(
        sql=f"COPY {target_table} FROM STDIN WITH CSV HEADER DELIMITER ','",
        filename=CSV_PATH
    )

with DAG(
    dag_id='etl_ops_to_raw',
    start_date=datetime(2025, 4, 27),
    schedule='@daily',
    catchup=False,
    tags={'ecommerce', 'dwh'},
) as dag:
    
    create_schema = SQLExecuteQueryOperator(
        task_id='create_raw_schema',
        sql=RAW_TABLE_SCHEMAS["schema"],
        conn_id='postgres_raw',
        autocommit=True
    )

    with TaskGroup(group_id='transfer_tables') as transfer_group:
        tables = ['categories', 'products', 'clients', 'sales', 'inventory']
        for table in tables:
            PythonOperator(
                task_id=f'transfer_{table}',
                python_callable=transfer_table(table),
            )

    load_csv_task = PythonOperator(
        task_id='load_csv_payment_history',
        python_callable=load_csv
    )

    create_schema >> transfer_group >> load_csv_task

dag = dag
```

je rencontre des erreurs comme ceci :
[2025-06-30T17:39:10.959+0300] {local_task_job_runner.py:120} INFO - ::group::Pre task execution logs
[2025-06-30T17:39:11.807+0300] {taskinstance.py:2076} INFO - Dependencies all met for dep_context=non-requeueable deps ti=<TaskInstance: etl_ops_to_raw.transfer_tables.transfer_categories manual__2025-06-30T14:38:52.013150+00:00 [queued]>
[2025-06-30T17:39:12.674+0300] {taskinstance.py:2076} INFO - Dependencies all met for dep_context=requeueable deps ti=<TaskInstance: etl_ops_to_raw.transfer_tables.transfer_categories manual__2025-06-30T14:38:52.013150+00:00 [queued]>
[2025-06-30T17:39:12.676+0300] {taskinstance.py:2306} INFO - Starting attempt 1 of 1
[2025-06-30T17:39:13.921+0300] {taskinstance.py:2330} INFO - Executing <Task(PythonOperator): transfer_tables.transfer_categories> on 2025-06-30 14:38:52.013150+00:00
[2025-06-30T17:39:13.943+0300] {standard_task_runner.py:63} INFO - Started process 22397 to run task
[2025-06-30T17:39:13.969+0300] {standard_task_runner.py:90} INFO - Running: ['airflow', 'tasks', 'run', 'etl_ops_to_raw', 'transfer_tables.transfer_categories', 'manual__2025-06-30T14:38:52.013150+00:00', '--job-id', '60', '--raw', '--subdir', 'DAGS_FOLDER/ops_to_raw.py', '--cfg-path', '/tmp/tmp7vd5edhh']
[2025-06-30T17:39:13.976+0300] {standard_task_runner.py:91} INFO - Job 60: Subtask transfer_tables.transfer_categories
[2025-06-30T17:39:17.100+0300] {task_command.py:426} INFO - Running <TaskInstance: etl_ops_to_raw.transfer_tables.transfer_categories manual__2025-06-30T14:38:52.013150+00:00 [running]> on host zokely-HP-EliteBook-820-G3
[2025-06-30T17:39:20.778+0300] {taskinstance.py:2648} INFO - Exporting env vars: AIRFLOW_CTX_DAG_OWNER='airflow' AIRFLOW_CTX_DAG_ID='etl_ops_to_raw' AIRFLOW_CTX_TASK_ID='transfer_tables.transfer_categories' AIRFLOW_CTX_EXECUTION_DATE='2025-06-30T14:38:52.013150+00:00' AIRFLOW_CTX_TRY_NUMBER='1' AIRFLOW_CTX_DAG_RUN_ID='manual__2025-06-30T14:38:52.013150+00:00'
[2025-06-30T17:39:20.785+0300] {taskinstance.py:430} INFO - ::endgroup::
[2025-06-30T17:39:20.807+0300] {base.py:84} INFO - Using connection ID '***_raw' for task execution.
[2025-06-30T17:39:20.857+0300] {sql.py:470} INFO - Running statement: 
                      CREATE TABLE IF NOT EXISTS raw.categories_raw
                      (
                          category_id TEXT,
                          name        TEXT
                      );
                      , parameters: None
[2025-06-30T17:39:20.860+0300] {taskinstance.py:441} INFO - ::group::Post task execution logs
[2025-06-30T17:39:20.861+0300] {taskinstance.py:2905} ERROR - Task failed with exception
Traceback (most recent call last):
  File "/home/zo-kely/Documents/Studies/ITU/Serveur/airflow/airflow_env/lib/python3.10/site-packages/airflow/models/taskinstance.py", line 465, in _execute_task
    result = _execute_callable(context=context, **execute_callable_kwargs)
  File "/home/zo-kely/Documents/Studies/ITU/Serveur/airflow/airflow_env/lib/python3.10/site-packages/airflow/models/taskinstance.py", line 432, in _execute_callable
    return execute_callable(context=context, **execute_callable_kwargs)
  File "/home/zo-kely/Documents/Studies/ITU/Serveur/airflow/airflow_env/lib/python3.10/site-packages/airflow/models/baseoperator.py", line 400, in wrapper
    return func(self, *args, **kwargs)
  File "/home/zo-kely/Documents/Studies/ITU/Serveur/airflow/airflow_env/lib/python3.10/site-packages/airflow/operators/python.py", line 235, in execute
    return_value = self.execute_callable()
  File "/home/zo-kely/Documents/Studies/ITU/Serveur/airflow/airflow_env/lib/python3.10/site-packages/airflow/operators/python.py", line 252, in execute_callable
    return self.python_callable(*self.op_args, **self.op_kwargs)
  File "/home/zo-kely/Documents/Studies/ITU/Serveur/airflow/dags/ops_to_raw.py", line 88, in _transfer
    prepare_table(postgres_hook, target_table)
  File "/home/zo-kely/Documents/Studies/ITU/Serveur/airflow/dags/ops_to_raw.py", line 77, in prepare_table
    hook.run(RAW_TABLE_SCHEMAS[table_name])
  File "/home/zo-kely/Documents/Studies/ITU/Serveur/airflow/airflow_env/lib/python3.10/site-packages/airflow/providers/common/sql/hooks/sql.py", line 418, in run
    self._run_command(cur, sql_statement, parameters)
  File "/home/zo-kely/Documents/Studies/ITU/Serveur/airflow/airflow_env/lib/python3.10/site-packages/airflow/providers/common/sql/hooks/sql.py", line 475, in _run_command
    cur.execute(sql_statement)
psycopg2.errors.InvalidSchemaName: schema "raw" does not exist
LINE 2:                       CREATE TABLE IF NOT EXISTS raw.categor...
                                                         ^

[2025-06-30T17:39:21.518+0300] {taskinstance.py:1206} INFO - Marking task as FAILED. dag_id=etl_ops_to_raw, task_id=transfer_tables.transfer_categories, run_id=manual__2025-06-30T14:38:52.013150+00:00, execution_date=20250630T143852, start_date=20250630T143911, end_date=20250630T143921
[2025-06-30T17:39:22.052+0300] {standard_task_runner.py:110} ERROR - Failed to execute job 60 for task transfer_tables.transfer_categories (schema "raw" does not exist
LINE 2:                       CREATE TABLE IF NOT EXISTS raw.categor...
                                                         ^
; 22397)
[2025-06-30T17:39:22.097+0300] {local_task_job_runner.py:240} INFO - Task exited with return code 1
[2025-06-30T17:39:24.873+0300] {taskinstance.py:3498} INFO - 0 downstream tasks scheduled from follow-on schedule check
[2025-06-30T17:39:25.392+0300] {local_task_job_runner.py:222} INFO - ::endgroup::

Ce qui fait echouer mon processus executer par airflow.
