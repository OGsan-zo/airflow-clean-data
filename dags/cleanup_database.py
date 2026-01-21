from airflow import DAG
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.operators.python import PythonOperator
from datetime import datetime
import logging

# --- CONFIGURATION ---
POSTGRES_CONN_ID = 'postgres_connections'
logger = logging.getLogger("airflow.task")

# Tables créées par le DAG d'import (dans l'ordre de dépendance inverse pour la suppression)
RAW_TABLES = [
    'inscrits_raw',           # Dépend de etudiants_raw
    'niveau_etudiant_raw',    # Dépend de etudiants_raw, niveaux_raw, mentions_raw
    'etudiants_raw',          # Dépend de sexes_raw, bacc_raw, cin_raw, propos_raw
    'propos_raw',             # Indépendant
    'cin_raw',                # Indépendant
    'bacc_raw',               # Indépendant
    'formations_raw',         # Dépend de type_formation_raw
    'niveaux_raw',            # Indépendant
    'mentions_raw',           # Indépendant
    'sexes_raw',              # Indépendant
    'type_formation_raw'      # Indépendant
]

def cleanup_raw_tables():
    """
    Supprime toutes les tables créées par le DAG d'import dans le schéma 'raw'.
    Avec logging détaillé de chaque étape.
    """
    try:
        logger.info("=" * 70)
        logger.info("🗑️  DÉMARRAGE DU NETTOYAGE DES TABLES RAW")
        logger.info("=" * 70)
        
        # === ÉTAPE 1 : Connexion à la base ===
        logger.info("📡 Étape 1/5 : Connexion à PostgreSQL...")
        logger.info(f"   Connection ID utilisé : {POSTGRES_CONN_ID}")
        
        try:
            pg_hook = PostgresHook(postgres_conn_id=POSTGRES_CONN_ID)
            logger.info("   ✅ Hook PostgreSQL créé avec succès")
        except Exception as e:
            logger.error(f"   ❌ ERREUR lors de la création du hook : {e}")
            logger.error("   💡 Vérifiez que la connexion existe dans Airflow Admin > Connections")
            raise
        
        # === ÉTAPE 2 : Vérification de la connexion ===
        logger.info("🔍 Étape 2/5 : Test de connexion...")
        try:
            conn = pg_hook.get_conn()
            logger.info("   ✅ Connexion établie avec succès")
            
            cursor = conn.cursor()
            cursor.execute("SELECT version();")
            version = cursor.fetchone()[0]
            logger.info(f"   📊 Version PostgreSQL : {version[:50]}...")
            
            cursor.execute("SELECT current_database();")
            db_name = cursor.fetchone()[0]
            logger.info(f"   📊 Base de données : {db_name}")
            
            cursor.close()
            conn.close()
            
        except Exception as e:
            logger.error(f"   ❌ ERREUR de connexion : {e}")
            raise
        
        # === ÉTAPE 3 : Vérification du schéma ===
        logger.info("📋 Étape 3/5 : Vérification du schéma 'raw'...")
        
        try:
            check_schema_sql = """
            SELECT EXISTS(
                SELECT 1 FROM information_schema.schemata 
                WHERE schema_name = 'raw'
            );
            """
            schema_exists = pg_hook.get_first(check_schema_sql)[0]
            
            if not schema_exists:
                logger.info("   ℹ️  Le schéma 'raw' n'existe pas")
                logger.info("   ℹ️  Rien à nettoyer")
                logger.info("=" * 70)
                logger.info("✅ NETTOYAGE TERMINÉ (schéma inexistant)")
                logger.info("=" * 70)
                return
            
            logger.info("   ✅ Le schéma 'raw' existe")
            
        except Exception as e:
            logger.error(f"   ❌ Erreur lors de la vérification : {e}")
            raise
        
        # === ÉTAPE 4 : Inventaire des tables ===
        logger.info("📊 Étape 4/5 : Inventaire des tables à supprimer...")
        
        tables_found = []
        tables_missing = []
        total_rows = 0
        
        for table_name in RAW_TABLES:
            try:
                # Vérifier si la table existe
                check_table_sql = f"""
                SELECT EXISTS (
                    SELECT 1 FROM information_schema.tables 
                    WHERE table_schema = 'raw' AND table_name = '{table_name}'
                );
                """
                table_exists = pg_hook.get_first(check_table_sql)[0]
                
                if table_exists:
                    # Compter les lignes
                    count_sql = f"SELECT COUNT(*) FROM raw.{table_name};"
                    row_count = pg_hook.get_first(count_sql)[0]
                    tables_found.append((table_name, row_count))
                    total_rows += row_count
                    logger.info(f"   ✓ {table_name:30s} : {row_count:6d} lignes")
                else:
                    tables_missing.append(table_name)
                    
            except Exception as e:
                logger.warning(f"   ⚠️  Erreur sur {table_name} : {e}")
                tables_missing.append(table_name)
        
        logger.info("")
        logger.info(f"   📊 Résumé :")
        logger.info(f"      Tables trouvées    : {len(tables_found)}")
        logger.info(f"      Tables manquantes  : {len(tables_missing)}")
        logger.info(f"      Total de lignes    : {total_rows:,}")
        
        if tables_missing:
            logger.info(f"   ℹ️  Tables non trouvées : {', '.join(tables_missing)}")
        
        if not tables_found:
            logger.info("")
            logger.info("   ℹ️  Aucune table à supprimer")
            logger.info("=" * 70)
            logger.info("✅ NETTOYAGE TERMINÉ (aucune table)")
            logger.info("=" * 70)
            return
        
        # === ÉTAPE 5 : Suppression des tables ===
        logger.info("")
        logger.info("🔥 Étape 5/5 : Suppression des tables...")
        
        deleted_count = 0
        failed_count = 0
        
        for table_name, row_count in tables_found:
            try:
                logger.info(f"   🗑️  Suppression de {table_name}...")
                
                drop_sql = f"DROP TABLE IF EXISTS raw.{table_name} CASCADE;"
                pg_hook.run(drop_sql)
                
                logger.info(f"      ✅ {table_name} supprimée ({row_count} lignes effacées)")
                deleted_count += 1
                
            except Exception as e:
                logger.error(f"      ❌ Erreur lors de la suppression de {table_name} : {e}")
                failed_count += 1
        
        # === VÉRIFICATION FINALE ===
        logger.info("")
        logger.info("🔍 Vérification finale...")
        
        try:
            final_check_sql = """
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'raw' 
            AND table_name LIKE '%_raw'
            ORDER BY table_name;
            """
            remaining_tables = pg_hook.get_records(final_check_sql)
            
            if remaining_tables:
                logger.warning(f"   ⚠️  {len(remaining_tables)} table(s) encore présente(s) :")
                for (table_name,) in remaining_tables:
                    logger.warning(f"      - {table_name}")
            else:
                logger.info("   ✅ Toutes les tables ont été supprimées")
                
        except Exception as e:
            logger.warning(f"   ⚠️  Impossible de vérifier : {e}")
        
        # === RÉSUMÉ FINAL ===
        logger.info("")
        logger.info("=" * 70)
        if failed_count == 0:
            logger.info("🎉 NETTOYAGE TERMINÉ AVEC SUCCÈS")
        else:
            logger.info("⚠️  NETTOYAGE TERMINÉ AVEC AVERTISSEMENTS")
        logger.info("=" * 70)
        logger.info(f"📊 Statistiques :")
        logger.info(f"   Tables supprimées avec succès : {deleted_count}")
        logger.info(f"   Tables en échec               : {failed_count}")
        logger.info(f"   Lignes totales effacées       : {total_rows:,}")
        logger.info("=" * 70)
        logger.info("✅ Le schéma 'raw' est prêt pour de nouveaux imports")
        logger.info("💡 Vous pouvez maintenant lancer le DAG 'import_complet_performant'")
        logger.info("=" * 70)
        
    except Exception as e:
        logger.error("=" * 70)
        logger.error("❌ ÉCHEC DU NETTOYAGE")
        logger.error("=" * 70)
        logger.error(f"Erreur : {str(e)}")
        
        import traceback
        logger.error("")
        logger.error("📋 Trace complète :")
        logger.error(traceback.format_exc())
        logger.error("=" * 70)
        raise

def cleanup_full_schema():
    """
    Option alternative : Supprime et recrée complètement le schéma 'raw'.
    Plus radical mais garantit un nettoyage total.
    """
    try:
        logger.info("=" * 70)
        logger.info("💥 NETTOYAGE COMPLET DU SCHÉMA RAW (DROP CASCADE)")
        logger.info("=" * 70)
        logger.info("⚠️  ATTENTION : Cette action supprime TOUT dans le schéma 'raw'")
        logger.info("=" * 70)
        
        pg_hook = PostgresHook(postgres_conn_id=POSTGRES_CONN_ID)
        
        # Inventaire avant suppression
        try:
            list_tables_sql = """
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'raw'
            ORDER BY table_name;
            """
            tables = pg_hook.get_records(list_tables_sql)
            
            if tables:
                logger.info(f"📋 Tables à supprimer : {len(tables)}")
                for idx, (table_name,) in enumerate(tables, 1):
                    try:
                        count_sql = f"SELECT COUNT(*) FROM raw.{table_name};"
                        row_count = pg_hook.get_first(count_sql)[0]
                        logger.info(f"   {idx}. {table_name} ({row_count} lignes)")
                    except:
                        logger.info(f"   {idx}. {table_name}")
            else:
                logger.info("ℹ️  Le schéma 'raw' est déjà vide")
        except:
            logger.info("ℹ️  Impossible d'inventorier le schéma")
        
        # Suppression et recréation
        logger.info("")
        logger.info("🔥 Exécution du DROP CASCADE...")
        
        sql_cleanup = """
        DROP SCHEMA IF EXISTS raw CASCADE;
        CREATE SCHEMA raw;
        """
        
        pg_hook.run(sql_cleanup)
        
        logger.info("✅ Schéma supprimé et recréé avec succès")
        logger.info("=" * 70)
        logger.info("🎉 NETTOYAGE COMPLET TERMINÉ")
        logger.info("=" * 70)
        
    except Exception as e:
        logger.error(f"❌ ERREUR : {e}")
        import traceback
        logger.error(traceback.format_exc())
        raise

def verify_connection():
    """
    Tâche de vérification préalable : teste si la connexion PostgreSQL est configurée.
    """
    try:
        logger.info("🔍 Vérification de la connexion PostgreSQL...")
        logger.info(f"   Recherche de la connexion : '{POSTGRES_CONN_ID}'")
        
        pg_hook = PostgresHook(postgres_conn_id=POSTGRES_CONN_ID)
        conn = pg_hook.get_conn()
        
        cursor = conn.cursor()
        cursor.execute("SELECT 1;")
        result = cursor.fetchone()
        
        if result[0] == 1:
            logger.info("   ✅ Connexion PostgreSQL opérationnelle")
            logger.info("   ✅ Autorisation de poursuivre le nettoyage")
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        logger.error("=" * 70)
        logger.error("❌ CONNEXION POSTGRESQL NON CONFIGURÉE")
        logger.error("=" * 70)
        logger.error(f"Erreur : {str(e)}")
        logger.error("")
        logger.error("🔧 SOLUTION :")
        logger.error("   1. Ouvrez l'interface Airflow : http://localhost:8080")
        logger.error("   2. Allez dans : Admin > Connections")
        logger.error("   3. Cliquez sur le bouton '+' pour ajouter une connexion")
        logger.error("   4. Remplissez les champs suivants :")
        logger.error(f"      - Connection Id   : {POSTGRES_CONN_ID}")
        logger.error("      - Connection Type : Postgres")
        logger.error("      - Host            : localhost (ou votre serveur)")
        logger.error("      - Schema          : votre_nom_de_base")
        logger.error("      - Login           : votre_utilisateur")
        logger.error("      - Password        : votre_mot_de_passe")
        logger.error("      - Port            : 5432")
        logger.error("   5. Cliquez sur 'Save'")
        logger.error("   6. Relancez ce DAG")
        logger.error("=" * 70)
        raise

# --- DAG ---

with DAG(
    dag_id='db_cleanup_tool',
    start_date=datetime(2025, 1, 1),
    schedule_interval=None,  # Manuel uniquement
    catchup=False,
    tags=['tools', 'maintenance', 'cleanup'],
    description="Outil de nettoyage des tables RAW créées par import_complet_performant"
) as dag:

    # Tâche 1 : Vérifier la connexion
    verify_task = PythonOperator(
        task_id='verify_postgres_connection',
        python_callable=verify_connection
    )
    
    # Tâche 2 : Nettoyer les tables (méthode précise)
    cleanup_tables_task = PythonOperator(
        task_id='clean_raw_tables',
        python_callable=cleanup_raw_tables
    )
    
    # Tâche 3 (alternative) : Nettoyer tout le schéma (méthode radicale)
    # Décommentez cette tâche et commentez cleanup_tables_task si vous voulez
    # supprimer TOUT le schéma au lieu de juste les tables spécifiques
    """
    cleanup_schema_task = PythonOperator(
        task_id='clean_full_schema',
        python_callable=cleanup_full_schema
    )
    verify_task >> cleanup_schema_task
    """
    
    # Séquence : vérifier PUIS nettoyer
    verify_task >> cleanup_tables_task