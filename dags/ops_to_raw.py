from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from datetime import datetime
import pandas as pd
import os

# --- CONFIGURATION ---
CSV_PATH = '/home/zo-kely/Documents/Studies/ITU/Stage/ESPA/Data-cleaner/Serveur/dags/resource/BDD-SCOLARITE-1.csv'
POSTGRES_CONN_ID = 'postgres_connections'

# Schéma des tables RAW (comme dans le fichier de référence)
RAW_TABLE_SCHEMAS = {
    "schema": """
        CREATE SCHEMA IF NOT EXISTS raw;
    """,
    'type_formations_raw': """
        CREATE TABLE IF NOT EXISTS raw.type_formations_raw (
            nom_formation TEXT
        );
    """
}

# --- FONCTIONS MODULAIRES ---

def get_unique_values_from_csv(file_path, column_name, delimiter=';'):
    """
    Extrait les valeurs uniques d'une colonne spécifique d'un CSV.
    """
    print(f"[LOG] === DÉBUT EXTRACTION CSV ===")
    print(f"[LOG] Recherche du fichier: {file_path}")
    print(f"[LOG] Le fichier existe: {os.path.exists(file_path)}")
    
    if not os.path.exists(file_path):
        directory = os.path.dirname(file_path)
        print(f"[ERREUR] Fichier introuvable: {file_path}")
        print(f"[LOG] Contenu du dossier parent {directory}:")
        if os.path.exists(directory):
            print(f"[LOG] Fichiers disponibles: {os.listdir(directory)}")
        else:
            print(f"[ERREUR] Le dossier {directory} n'existe pas non plus!")
        raise FileNotFoundError(f"Le fichier {file_path} est introuvable.")
    
    try:
        print(f"[LOG] Lecture du CSV avec délimiteur '{delimiter}'...")
        # MODIFICATION ICI : Essayer différents encodages
        encodings_to_try = ['utf-8', 'latin-1', 'iso-8859-1', 'windows-1252', 'cp1252']
        df = None
        
        for encoding in encodings_to_try:
            try:
                print(f"[LOG] Tentative avec l'encodage: {encoding}")
                df = pd.read_csv(file_path, sep=delimiter, encoding=encoding)
                print(f"[LOG] ✓ CSV chargé avec succès avec l'encodage: {encoding}")
                break
            except UnicodeDecodeError:
                print(f"[LOG] ✗ Échec avec {encoding}, essai suivant...")
                continue
        
        if df is None:
            raise ValueError("Impossible de lire le CSV avec les encodages tentés")
            
        print(f"[LOG] CSV chargé avec succès. Dimensions: {df.shape}")
        print(f"[LOG] Colonnes disponibles: {list(df.columns)}")
        
    except Exception as e:
        print(f"[ERREUR] Échec de lecture du CSV: {str(e)}")
        raise
    
    if column_name not in df.columns:
        print(f"[ERREUR] Colonne '{column_name}' introuvable!")
        print(f"[LOG] Colonnes disponibles: {list(df.columns)}")
        raise KeyError(f"La colonne '{column_name}' n'existe pas dans le CSV.")
    
    # Nettoyage : suppression des doublons et des valeurs nulles
    print(f"[LOG] Extraction des valeurs uniques de la colonne '{column_name}'...")
    values = df[column_name].dropna().unique().tolist()
    print(f"[LOG] {len(values)} valeurs uniques extraites")
    print(f"[LOG] Aperçu des valeurs: {values[:5] if len(values) > 5 else values}")
    
    # Retourne une liste de tuples pour l'insertion PostgreSQL
    result = [(str(v),) for v in values]
    print(f"[LOG] === FIN EXTRACTION CSV ===")
    return result

def prepare_table(hook, table_name):
    """
    Prépare une table PostgreSQL (comme dans le fichier de référence)
    """
    print(f"[LOG] === DÉBUT PRÉPARATION TABLE {table_name} ===")
    
    try:
        # Créer le schéma si besoin
        print(f"[LOG] Création du schéma 'raw' si nécessaire...")
        hook.run("CREATE SCHEMA IF NOT EXISTS raw;")
        print(f"[LOG] Schéma 'raw' OK")
        
        # Créer la table dans le schéma raw
        print(f"[LOG] Création de la table raw.{table_name}...")
        hook.run(RAW_TABLE_SCHEMAS[table_name])
        print(f"[LOG] Table créée (ou existe déjà)")
        
        # Vider la table
        print(f"[LOG] Vidage de la table raw.{table_name}...")
        hook.run(f"TRUNCATE TABLE raw.{table_name}")
        print(f"[LOG] Table vidée avec succès")
        print(f"[LOG] === FIN PRÉPARATION TABLE ===")
        
    except Exception as e:
        print(f"[ERREUR] Échec lors de la préparation de la table: {str(e)}")
        raise

def insert_data_to_postgres(hook, table_name, rows):
    """
    Insère les données dans PostgreSQL (comme dans le fichier de référence)
    """
    print(f"[LOG] === DÉBUT INSERTION DONNÉES ===")
    print(f"[LOG] Table cible: raw.{table_name}")
    print(f"[LOG] Nombre de lignes à insérer: {len(rows)}")
    
    if not rows:
        print("[AVERTISSEMENT] Aucune donnée à insérer!")
        return
    
    try:
        # Insertion avec préfixe 'raw.'
        hook.insert_rows(table=f"raw.{table_name}", rows=rows)
        print(f"[LOG] Insertion réussie: {len(rows)} lignes insérées dans raw.{table_name}")
        print(f"[LOG] === FIN INSERTION DONNÉES ===")
        
    except Exception as e:
        print(f"[ERREUR] Échec lors de l'insertion: {str(e)}")
        print(f"[LOG] Aperçu des données qui ont échoué: {rows[:3]}")
        raise

# --- FONCTION PRINCIPALE (CALLABLE) ---

def task_process_type_formation():
    """
    Logique métier pour la colonne 'type_formation'.
    Suit le pattern du fichier de référence.
    """
    print("[LOG] ========================================")
    print("[LOG] DÉMARRAGE TÂCHE: task_process_type_formation")
    print("[LOG] ========================================")
    
    target_table = "type_formations_raw"
    csv_col = "type_formation"
    
    try:
        # 1. Extraction des données du CSV
        print(f"[LOG] Étape 1/3: Extraction des données...")
        data = get_unique_values_from_csv(CSV_PATH, csv_col)
        
        # 2. Connexion à PostgreSQL et préparation de la table
        print(f"[LOG] Étape 2/3: Connexion PostgreSQL et préparation table...")
        postgres_hook = PostgresHook(postgres_conn_id=POSTGRES_CONN_ID)
        prepare_table(postgres_hook, target_table)
        
        # 3. Insertion des données
        print(f"[LOG] Étape 3/3: Insertion des données...")
        insert_data_to_postgres(postgres_hook, target_table, data)
        
        print("[LOG] ========================================")
        print("[LOG] TÂCHE TERMINÉE AVEC SUCCÈS!")
        print("[LOG] ========================================")
        
    except Exception as e:
        print("[ERREUR] ========================================")
        print(f"[ERREUR] LA TÂCHE A ÉCHOUÉ: {str(e)}")
        print("[ERREUR] ========================================")
        raise

# --- DÉFINITION DU DAG ---

with DAG(
    dag_id='etl_scolarite_modular_test',
    start_date=datetime(2025, 1, 1),
    schedule_interval=None,
    catchup=False,
    tags=['scolarite', 'test']
) as dag:

    load_types = PythonOperator(
        task_id='load_type_formation',
        python_callable=task_process_type_formation
    )