from airflow import DAG
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from datetime import datetime

# Configuration
POSTGRES_CONN_ID = 'postgres_connections'

with DAG(
    dag_id='raw_to_final_migration_v2',
    start_date=datetime(2025, 1, 1),
    schedule_interval=None,
    catchup=False,
    tags=['silver', 'production', 'clean_and_load']
) as dag:

    # =========================================================
    # ÉTAPE 0 : CRÉATION DES TABLES (SI NÉCESSAIRE)
    # =========================================================
    
    create_tables = SQLExecuteQueryOperator(
        task_id='create_public_tables',
        conn_id=POSTGRES_CONN_ID,
        sql="""
            -- Tables de référence de base
            CREATE TABLE IF NOT EXISTS public.sexes (
                id SERIAL PRIMARY KEY,
                nom VARCHAR(50) NOT NULL
            );

            CREATE TABLE IF NOT EXISTS public.status (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255) NOT NULL
            );

            CREATE TABLE IF NOT EXISTS public.status_etudiants (
                id SERIAL PRIMARY KEY,
                name VARCHAR(50) NOT NULL
            );

            CREATE TABLE IF NOT EXISTS public.role (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255) NOT NULL
            );

            CREATE TABLE IF NOT EXISTS public.utilisateur (
                id SERIAL PRIMARY KEY,
                role_id INTEGER NOT NULL,
                status_id INTEGER,
                email VARCHAR(255) NOT NULL,
                mdp VARCHAR(255) NOT NULL,
                nom VARCHAR(255) NOT NULL,
                prenom VARCHAR(255) NOT NULL,
                date_creation TIMESTAMP,
                FOREIGN KEY (role_id) REFERENCES role(id),
                FOREIGN KEY (status_id) REFERENCES status(id)
            );

            CREATE TABLE IF NOT EXISTS public.cin (
                id SERIAL PRIMARY KEY,
                numero INTEGER NOT NULL,
                date_cin TIMESTAMP NOT NULL,
                lieu VARCHAR(255) NOT NULL,
                ancien_date TIMESTAMP NOT NULL,
                nouveau_date TIMESTAMP NOT NULL
            );

            CREATE TABLE IF NOT EXISTS public.bacc (
                id SERIAL PRIMARY KEY,
                numero VARCHAR(255),
                annee INTEGER NOT NULL,
                serie VARCHAR(50) NOT NULL
            );

            CREATE TABLE IF NOT EXISTS public.propos (
                id SERIAL PRIMARY KEY,
                adresse VARCHAR(255) NOT NULL,
                email VARCHAR(255) NOT NULL,
                sexe VARCHAR(50) NOT NULL
            );

            CREATE TABLE IF NOT EXISTS public.etudiants (
                id SERIAL PRIMARY KEY,
                cin_id INTEGER,
                bacc_id INTEGER NOT NULL,
                propos_id INTEGER NOT NULL,
                nom VARCHAR(255) NOT NULL,
                prenom VARCHAR(255) NOT NULL,
                date_naissance TIMESTAMP NOT NULL,
                lieu_naissance VARCHAR(255) NOT NULL,
                sexe_id INTEGER NOT NULL,
                status_etudiant_id INTEGER,
                FOREIGN KEY (cin_id) REFERENCES cin(id),
                FOREIGN KEY (bacc_id) REFERENCES bacc(id),
                FOREIGN KEY (propos_id) REFERENCES propos(id),
                FOREIGN KEY (sexe_id) REFERENCES sexes(id),
                FOREIGN KEY (status_etudiant_id) REFERENCES status_etudiants(id)
            );

            CREATE TABLE IF NOT EXISTS public.mentions (
                id SERIAL PRIMARY KEY,
                nom VARCHAR(100) NOT NULL,
                abr VARCHAR(10)
            );

            CREATE TABLE IF NOT EXISTS public.niveaux (
                id SERIAL PRIMARY KEY,
                nom VARCHAR(100) NOT NULL,
                type SMALLINT NOT NULL,
                grade SMALLINT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS public.parcours (
                id SERIAL PRIMARY KEY,
                mention_id INTEGER NOT NULL,
                nom VARCHAR(100) NOT NULL,
                FOREIGN KEY (mention_id) REFERENCES mentions(id)
            );

            CREATE TABLE IF NOT EXISTS public.type_formations (
                id SERIAL PRIMARY KEY,
                nom VARCHAR(100) NOT NULL
            );

            CREATE TABLE IF NOT EXISTS public.formations (
                id SERIAL PRIMARY KEY,
                type_formation_id INTEGER NOT NULL,
                nom VARCHAR(100) NOT NULL,
                FOREIGN KEY (type_formation_id) REFERENCES type_formations(id)
            );

            CREATE TABLE IF NOT EXISTS public.niveau_etudiants (
                id SERIAL PRIMARY KEY,
                niveau_id INTEGER NOT NULL,
                mention_id INTEGER NOT NULL,
                annee INTEGER NOT NULL,
                date_insertion TIMESTAMP NOT NULL,
                etudiant_id INTEGER NOT NULL,
                status_etudiant_id INTEGER DEFAULT 1 NOT NULL,
                FOREIGN KEY (niveau_id) REFERENCES niveaux(id),
                FOREIGN KEY (mention_id) REFERENCES mentions(id),
                FOREIGN KEY (etudiant_id) REFERENCES etudiants(id),
                FOREIGN KEY (status_etudiant_id) REFERENCES status_etudiants(id)
            );

            CREATE TABLE IF NOT EXISTS public.formation_etudiants (
                id SERIAL PRIMARY KEY,
                etudiant_id INTEGER NOT NULL,
                formation_id INTEGER NOT NULL,
                date_formation TIMESTAMP NOT NULL,
                FOREIGN KEY (etudiant_id) REFERENCES etudiants(id),
                FOREIGN KEY (formation_id) REFERENCES formations(id)
            );

            CREATE TABLE IF NOT EXISTS public.inscriptions (
                id SERIAL PRIMARY KEY,
                etudiant_id INTEGER NOT NULL,
                utilisateur_id INTEGER NOT NULL,
                date_inscription TIMESTAMP NOT NULL,
                FOREIGN KEY (etudiant_id) REFERENCES etudiants(id),
                FOREIGN KEY (utilisateur_id) REFERENCES utilisateur(id)
            );

            CREATE TABLE IF NOT EXISTS public.inscrits (
                id SERIAL PRIMARY KEY,
                utilisateur_id INTEGER NOT NULL,
                etudiant_id INTEGER NOT NULL,
                description VARCHAR(255) NOT NULL,
                date_inscription TIMESTAMP NOT NULL,
                matricule VARCHAR(255),
                FOREIGN KEY (etudiant_id) REFERENCES etudiants(id),
                FOREIGN KEY (utilisateur_id) REFERENCES utilisateur(id)
            );

            CREATE TABLE IF NOT EXISTS public.type_droits (
                id SERIAL PRIMARY KEY,
                nom VARCHAR(100) NOT NULL
            );

            CREATE TABLE IF NOT EXISTS public.droits (
                id SERIAL PRIMARY KEY,
                type_droit_id INTEGER NOT NULL,
                reference VARCHAR(255) NOT NULL,
                date_versement TIMESTAMP NOT NULL,
                montant DOUBLE PRECISION NOT NULL,
                utilisateur_id INTEGER NOT NULL,
                etudiant_id INTEGER NOT NULL,
                annee INTEGER NOT NULL,
                FOREIGN KEY (type_droit_id) REFERENCES type_droits(id),
                FOREIGN KEY (etudiant_id) REFERENCES etudiants(id),
                FOREIGN KEY (utilisateur_id) REFERENCES utilisateur(id)
            );

            CREATE TABLE IF NOT EXISTS public.ecolages (
                id SERIAL PRIMARY KEY,
                formations_id INTEGER NOT NULL,
                montant DOUBLE PRECISION NOT NULL,
                date_ecolage TIMESTAMP,
                FOREIGN KEY (formations_id) REFERENCES formations(id)
            );

            CREATE TABLE IF NOT EXISTS public.payements_ecolages (
                id SERIAL PRIMARY KEY,
                etudiant_id INTEGER NOT NULL,
                reference VARCHAR(255) NOT NULL,
                datepayements TIMESTAMP NOT NULL,
                montant DOUBLE PRECISION NOT NULL,
                tranche INTEGER NOT NULL,
                utilisateur_id INTEGER NOT NULL,
                annee INTEGER NOT NULL,
                FOREIGN KEY (etudiant_id) REFERENCES etudiants(id),
                FOREIGN KEY (utilisateur_id) REFERENCES utilisateur(id)
            );
        """
    )
    
    # =========================================================
    # ÉTAPE 1 : NETTOYAGE DES TABLES
    # =========================================================
    
    step_1_clean = SQLExecuteQueryOperator(
        task_id='step_1_clean_tables',
        conn_id=POSTGRES_CONN_ID,
        sql="CALL public.clean_all_tables();"
    )

    # =========================================================
    # ÉTAPE 2 : MIGRATION DES RÉFÉRENTIELS
    # =========================================================
    
    step_2_referentials = SQLExecuteQueryOperator(
        task_id='step_2_migrate_referentials',
        conn_id=POSTGRES_CONN_ID,
        sql="CALL public.migrate_referentials();"
    )

    # =========================================================
    # ÉTAPE 3 : MIGRATION DES TABLES TECHNIQUES
    # =========================================================
    
    step_3_technical = SQLExecuteQueryOperator(
        task_id='step_3_migrate_technical_tables',
        conn_id=POSTGRES_CONN_ID,
        sql="CALL public.migrate_technical_tables();"
    )

    # =========================================================
    # ÉTAPE 4 : MIGRATION DES ÉTUDIANTS
    # =========================================================
    
    step_4_students = SQLExecuteQueryOperator(
        task_id='step_4_migrate_students',
        conn_id=POSTGRES_CONN_ID,
        sql="CALL public.migrate_students();"
    )

    # =========================================================
    # ÉTAPE 5 : MIGRATION DE L'HISTORIQUE
    # =========================================================
    
    step_5_history = SQLExecuteQueryOperator(
        task_id='step_5_migrate_student_history',
        conn_id=POSTGRES_CONN_ID,
        sql="CALL public.migrate_student_history();"
    )

    # =========================================================
    # ÉTAPE 6 : MIGRATION DES INSCRITS
    # =========================================================
    
    step_6_registrations = SQLExecuteQueryOperator(
        task_id='step_6_migrate_registrations',
        conn_id=POSTGRES_CONN_ID,
        sql="CALL public.migrate_registrations();"
    )

    # =========================================================
    # DÉPENDANCES - CHAÎNE SÉQUENTIELLE
    # =========================================================
    
    create_tables >> step_1_clean >> step_2_referentials >> step_3_technical >> step_4_students >> step_5_history >> step_6_registrations