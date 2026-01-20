from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from datetime import datetime
import pandas as pd
import os
import logging

# --- CONFIGURATION ---
CSV_PATH = '/home/zo-kely/Documents/Studies/ITU/Stage/ESPA/Data-cleaner/Serveur/dags/resource/BDD-SCOLARITE-1.csv'
POSTGRES_CONN_ID = 'postgres_connections'

logger = logging.getLogger("airflow.task")

# --- FONCTIONS GÉNÉRIQUES ---

def get_df():
    """Charge le CSV et log les informations de base."""
    if not os.path.exists(CSV_PATH):
        logger.error(f"❌ FICHIER INTROUVABLE : {CSV_PATH}")
        raise FileNotFoundError(f"Le fichier CSV n'existe pas au chemin : {CSV_PATH}")
    
    logger.info(f"📖 Lecture du fichier : {CSV_PATH}")
    df = pd.read_csv(CSV_PATH, sep=';', encoding='latin-1', low_memory=False)
    logger.info(f"✅ CSV chargé. Dimensions : {df.shape}")
    return df

def import_ref_table(csv_col, target_table, target_column):
    """Importation avec logs détaillés par étape."""
    logger.info(f"🚀 DÉMARRAGE IMPORT : {target_table}")
    
    try:
        df = get_df()
        if csv_col not in df.columns:
            logger.error(f"❌ Colonne '{csv_col}' absente. Disponibles : {df.columns.tolist()}")
            raise KeyError(f"Colonne {csv_col} manquante")

        unique_values = df[csv_col].dropna().unique().tolist()
        data_to_insert = [(str(v),) for v in unique_values]
        logger.info(f"📊 Données uniques : {len(data_to_insert)} lignes")

        pg_hook = PostgresHook(postgres_conn_id=POSTGRES_CONN_ID)
        
        logger.info(f"🛠 Préparation table raw.{target_table}")
        sql = f"""
        CREATE SCHEMA IF NOT EXISTS raw;
        CREATE TABLE IF NOT EXISTS raw.{target_table} (
            {target_column} TEXT
        );
        TRUNCATE TABLE raw.{target_table};
        """
        pg_hook.run(sql)
        
        if data_to_insert:
            logger.info(f"🔥 Insertion dans raw.{target_table}")
            pg_hook.insert_rows(
                table=f"raw.{target_table}", 
                rows=data_to_insert, 
                target_fields=[target_column]
            )
            logger.info(f"✅ {len(data_to_insert)} lignes insérées")
        else:
            logger.warning(f"⚠️ Aucune donnée pour {csv_col}")

    except Exception as e:
        logger.error(f"💥 ERREUR : {str(e)}")
        raise

def import_bacc_table():
    """Importation BACC (Année + Série)."""
    logger.info("🚀 DÉMARRAGE IMPORT BACC")
    
    try:
        df = get_df()
        
        cols_needed = ['annee_bacc', 'serie_bacc']
        for c in cols_needed:
            if c not in df.columns:
                raise KeyError(f"Colonne '{c}' manquante")

        bacc_df = df[cols_needed].dropna().drop_duplicates()
        data_to_insert = list(bacc_df.itertuples(index=False, name=None))
        
        logger.info(f"📊 Couples uniques : {len(data_to_insert)}")

        pg_hook = PostgresHook(postgres_conn_id=POSTGRES_CONN_ID)
        
        sql = """
        CREATE SCHEMA IF NOT EXISTS raw;
        CREATE TABLE IF NOT EXISTS raw.bacc_raw (
            annee TEXT,
            serie TEXT
        );
        TRUNCATE TABLE raw.bacc_raw;
        """
        pg_hook.run(sql)
        
        pg_hook.insert_rows(
            table="raw.bacc_raw", 
            rows=data_to_insert, 
            target_fields=['annee', 'serie']
        )
        logger.info(f"✅ {len(data_to_insert)} lignes insérées")

    except Exception as e:
        logger.error(f"💥 ERREUR BACC : {str(e)}")
        raise

# --- DAG ---

with DAG(
    dag_id='import_referentiels_complet_v2',
    start_date=datetime(2025, 1, 1),
    schedule=None,  
    catchup=False,
    tags=['debug', 'raw', 'scolarite']
) as dag:

    referentiels = [
        ('sexes', 'sexe', 'sexes_raw', 'nom'),
        ('mentions', 'MENTION', 'mentions_raw', 'nom'),
        ('niveaux', 'NIVEAU', 'niveaux_raw', 'nom'),
        ('type_formations', 'type_formation', 'type_formations_raw', 'nom'),
        ('pays', 'nationalite', 'pays_raw', 'nom'),
        ('parcours', 'cdparc', 'parcours_raw', 'nom')
    ]

    for task_id, csv_col, target_table, target_col in referentiels:
        PythonOperator(
            task_id=f'import_{task_id}',
            python_callable=import_ref_table,
            op_kwargs={
                'csv_col': csv_col,
                'target_table': target_table,
                'target_column': target_col
            }
        )

    import_bacc = PythonOperator(
        task_id='import_bacc',
        python_callable=import_bacc_table
    )