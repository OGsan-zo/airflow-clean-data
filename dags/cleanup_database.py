from airflow import DAG
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.operators.python import PythonOperator
from datetime import datetime

# --- CONFIGURATION ---
POSTGRES_CONN_ID = 'postgres_connections'

def cleanup_raw_schema():
    """
    Supprime et recrée le schéma 'raw' pour effacer TOUTES les tables de test.
    """
    pg_hook = PostgresHook(postgres_conn_id=POSTGRES_CONN_ID)
    
    # SQL pour tout supprimer proprement
    sql = """
    DROP SCHEMA IF EXISTS raw CASCADE;
    CREATE SCHEMA raw;
    """
    print("[LOG] Nettoyage du schéma 'raw' en cours...")
    pg_hook.run(sql)
    print("[LOG] Le schéma 'raw' est maintenant vide et prêt pour de nouveaux tests.")

with DAG(
    dag_id='db_cleanup_tool',
    start_date=datetime(2025, 1, 1),
    schedule_interval=None, # On ne le lance que manuellement
    catchup=False,
    tags=['tools', 'maintenance'],
) as dag:

    cleanup_task = PythonOperator(
        task_id='clean_raw_data',
        python_callable=cleanup_raw_schema
    )