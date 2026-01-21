from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from datetime import datetime
import pandas as pd
import logging

# --- CONFIGURATION ---
EXCEL_PATH = '/home/zo-kely/Documents/Studies/ITU/Stage/ESPA/Data-cleaner/Serveur/dags/resource/BDD-SCOLARITE-NOM_PRENOMS SEPARES.xls'
POSTGRES_CONN_ID = 'postgres_connections'
logger = logging.getLogger("airflow.task")

# --- AUTO-DÉTECTION DES COLONNES ---
def detect_columns(df):
    """Détecte automatiquement les noms de colonnes du CSV (majuscules/minuscules)."""
    cols = df.columns.tolist()
    
    # Créer un dictionnaire de mapping flexible
    mapping = {}
    
    # Recherche insensible à la casse
    for col in cols:
        col_upper = col.upper()
        col_lower = col.lower()
        
        # Colonnes principales
        if 'NOM' in col_upper and 'PRENOMS' not in col_upper:
            mapping['nom'] = col
        elif 'PRENOM' in col_upper:
            mapping['prenoms'] = col
        elif col_lower == 'sexe':
            mapping['sexe'] = col
        elif 'NIVEAU' in col_upper:
            mapping['niveau'] = col
        elif 'MENTION' in col_upper:
            mapping['mention'] = col
        elif 'TYPE' in col_upper and 'FORMATION' in col_upper:
            mapping['type_formation'] = col
        
        # Colonnes secondaires
        elif 'AUNIV' in col_upper or ('ANNEE' in col_upper and 'UNIV' in col_upper):
            mapping['annee_univ'] = col
        elif 'DATENAISS' in col_upper or ('DATE' in col_upper and 'NAISS' in col_upper):
            mapping['date_naissance'] = col
        elif 'LIEUNAIS' in col_upper or ('LIEU' in col_upper and 'NAISS' in col_upper):
            mapping['lieu_nai'] = col
        elif 'ANNEEBAC' in col_upper or ('ANNEE' in col_upper and 'BAC' in col_upper):
            mapping['annee_bacc'] = col
        elif 'SERIEBAC' in col_upper or ('SERIE' in col_upper and 'BAC' in col_upper):
            mapping['serie_bacc'] = col
        elif 'DATECIN' in col_upper or ('DATE' in col_upper and 'CIN' in col_upper):
            mapping['date_cin'] = col
        elif 'LIEUCIN' in col_upper or ('LIEU' in col_upper and 'CIN' in col_upper):
            mapping['lieu_cin'] = col
        elif 'ADRESSE' in col_upper:
            mapping['adresse'] = col
        elif 'EMAIL' in col_upper or 'MAIL' in col_upper:
            mapping['email'] = col
        elif 'DATEINSCR' in col_upper or ('DATE' in col_upper and 'INSCR' in col_upper):
            mapping['date_inscription'] = col
    
    return mapping

# --- OUTILS DE NETTOYAGE ---
def clean_str(val):
    """Normalise les chaînes : Majuscules, sans espaces, gère les None."""
    if pd.isna(val) or str(val).strip().lower() in ['nan', 'null', '', '0']:
        return None
    return str(val).strip().upper()

def clean_value(val):
    """Convertit les valeurs pandas (NaT, NaN, etc.) en None pour PostgreSQL."""
    if pd.isna(val):
        return None
    if isinstance(val, pd.Timestamp):
        # Convertir les timestamps pandas en string
        return val.strftime('%Y-%m-%d %H:%M:%S')
    val_str = str(val).strip()
    if val_str.lower() in ['nan', 'nat', 'null', '', 'none']:
        return None
    return val_str

def get_df():
    """Charge le fichier Excel et détecte automatiquement les colonnes."""
    try:
        logger.info(f"📂 Chargement du fichier Excel depuis : {EXCEL_PATH}")
        
        # Détection automatique du moteur selon l'extension
        if EXCEL_PATH.endswith('.xlsx'):
            engine = 'openpyxl'
        elif EXCEL_PATH.endswith('.xls'):
            engine = 'xlrd'  # Pour les anciens formats Excel
        else:
            engine = None
        
        logger.info(f"   Moteur utilisé : {engine}")
        
        # Lecture du fichier Excel
        df = pd.read_excel(EXCEL_PATH, engine=engine)
        logger.info(f"✅ Excel chargé : {len(df)} lignes, {len(df.columns)} colonnes")
        
        # Afficher toutes les colonnes
        logger.info(f"📋 COLONNES DÉTECTÉES DANS LE CSV :")
        for idx, col in enumerate(df.columns, 1):
            logger.info(f"   {idx:2d}. {col}")
        
        # Auto-détection
        col_map = detect_columns(df)
        logger.info(f"\n🔍 MAPPING AUTOMATIQUE DES COLONNES :")
        for logical, real in col_map.items():
            logger.info(f"   {logical:20s} -> {real}")
        
        # Stocker le mapping comme attribut du DataFrame
        df.col_map = col_map
        
        # Normaliser les colonnes clés
        cols_to_norm = ['sexe', 'niveau', 'type_formation', 'mention']
        for logical_col in cols_to_norm:
            if logical_col in col_map:
                real_col = col_map[logical_col]
                df[real_col] = df[real_col].apply(clean_str)
                logger.info(f"  ✓ Colonne '{real_col}' normalisée")
        
        return df
    except Exception as e:
        logger.error(f"❌ ERREUR lors du chargement du CSV : {e}")
        raise

# --- HELPER FUNCTION ---
def get_col(df, logical_name):
    """Retourne le nom réel de la colonne ou None si non trouvée."""
    return df.col_map.get(logical_name)

# --- FONCTIONS D'IMPORTATION ---
def import_referentiels_base():
    """Importe Type_formation, Mentions, Niveaux, Sexes."""
    try:
        logger.info("=" * 70)
        logger.info("🚀 DÉBUT : import_referentiels_base")
        logger.info("=" * 70)
        
        df = get_df()
        pg_hook = PostgresHook(postgres_conn_id=POSTGRES_CONN_ID)
        
        # === TYPE FORMATION ===
        logger.info("\n📌 Étape 1/4 : Type de formation")
        data_types = [(1, 'ACADEMIQUE'), (2, 'PROFESSIONNEL')]
        logger.info(f"  📊 Types de formation : {data_types}")
        
        # === SEXES ===
        logger.info("\n📌 Étape 2/4 : Sexes")
        sexe_col = get_col(df, 'sexe')
        if sexe_col:
            sexes_uniques = [s for s in df[sexe_col].unique() if s and s != '0']
            sexes = [(s,) for s in sexes_uniques]
            logger.info(f"  📊 Sexes trouvés : {sexes_uniques}")
        else:
            logger.warning("  ⚠️  Colonne 'sexe' introuvable")
            sexes = []
        
        # === MENTIONS ===
        logger.info("\n📌 Étape 3/4 : Mentions")
        mention_col = get_col(df, 'mention')
        if mention_col:
            mentions_uniques = [m for m in df[mention_col].unique() if m]
            mentions = [(m, m) for m in mentions_uniques]
            logger.info(f"  📊 Mentions trouvées : {len(mentions_uniques)} uniques")
            if mentions_uniques:
                logger.info(f"      Exemples : {', '.join(mentions_uniques[:5])}")
        else:
            logger.warning("  ⚠️  Colonne 'mention' introuvable")
            mentions = []
        
        # === NIVEAUX ===
        logger.info("\n📌 Étape 4/4 : Niveaux")
        niveau_col = get_col(df, 'niveau')
        if niveau_col:
            niveaux_uniques = [n for n in df[niveau_col].unique() if n]
            niveaux = [(n, 1, None) for n in niveaux_uniques]
            logger.info(f"  📊 Niveaux trouvés : {len(niveaux_uniques)} uniques")
            if niveaux_uniques:
                logger.info(f"      Exemples : {', '.join(niveaux_uniques[:5])}")
        else:
            logger.warning("  ⚠️  Colonne 'niveau' introuvable")
            niveaux = []

        # === CRÉATION ET INSERTION ===
        logger.info("\n🔨 Création des tables...")
        sql = """
        CREATE SCHEMA IF NOT EXISTS raw;
        CREATE TABLE IF NOT EXISTS raw.type_formation_raw (id INT PRIMARY KEY, nom TEXT UNIQUE NOT NULL);
        CREATE TABLE IF NOT EXISTS raw.sexes_raw (id SERIAL PRIMARY KEY, nom TEXT UNIQUE NOT NULL);
        CREATE TABLE IF NOT EXISTS raw.mentions_raw (id SERIAL PRIMARY KEY, nom TEXT UNIQUE NOT NULL, abr TEXT);
        CREATE TABLE IF NOT EXISTS raw.niveaux_raw (id SERIAL PRIMARY KEY, nom TEXT UNIQUE NOT NULL, type INT, grade TEXT);
        TRUNCATE raw.type_formation_raw, raw.sexes_raw, raw.mentions_raw, raw.niveaux_raw RESTART IDENTITY CASCADE;
        """
        pg_hook.run(sql)
        logger.info("  ✅ Tables créées")
        
        logger.info("\n💾 Insertion...")
        pg_hook.insert_rows("raw.type_formation_raw", data_types, ["id", "nom"])
        logger.info(f"  ✅ {len(data_types)} types de formation")
        
        if sexes:
            pg_hook.insert_rows("raw.sexes_raw", sexes, ["nom"])
            logger.info(f"  ✅ {len(sexes)} sexes")
        if mentions:
            pg_hook.insert_rows("raw.mentions_raw", mentions, ["nom", "abr"])
            logger.info(f"  ✅ {len(mentions)} mentions")
        if niveaux:
            pg_hook.insert_rows("raw.niveaux_raw", niveaux, ["nom", "type", "grade"])
            logger.info(f"  ✅ {len(niveaux)} niveaux")
        
        logger.info("=" * 70)
        logger.info("🎉 SUCCÈS : import_referentiels_base terminé")
        logger.info("=" * 70)
        
    except Exception as e:
        logger.error(f"\n❌ ERREUR : {e}")
        import traceback
        logger.error(traceback.format_exc())
        raise

def import_formations():
    """Importe les Formations."""
    try:
        logger.info("=" * 70)
        logger.info("🚀 DÉBUT : import_formations")
        logger.info("=" * 70)
        
        df = get_df()
        pg_hook = PostgresHook(postgres_conn_id=POSTGRES_CONN_ID)
        
        type_form_col = get_col(df, 'type_formation')
        if not type_form_col:
            raise KeyError("Colonne 'type_formation' introuvable")
        
        form_uniques = df[type_form_col].dropna().unique()
        data_form = [(2 if 'PROF' in str(f).upper() else 1, f) for f in form_uniques]
        
        logger.info(f"  📊 {len(data_form)} formations trouvées")
        
        sql = """
        CREATE TABLE IF NOT EXISTS raw.formations_raw (id SERIAL PRIMARY KEY, type_formation_id INT NOT NULL, nom TEXT UNIQUE NOT NULL);
        TRUNCATE raw.formations_raw RESTART IDENTITY CASCADE;
        """
        pg_hook.run(sql)
        
        if data_form:
            pg_hook.insert_rows("raw.formations_raw", data_form, ["type_formation_id", "nom"])
            logger.info(f"  ✅ {len(data_form)} formations insérées")
        
        logger.info("🎉 SUCCÈS")
        
    except Exception as e:
        logger.error(f"❌ ERREUR : {e}")
        raise

def import_bacc_cin_propos():
    """Importe BACC, CIN et PROPOS."""
    try:
        logger.info("=" * 70)
        logger.info("🚀 DÉBUT : import_bacc_cin_propos")
        logger.info("=" * 70)
        
        df = get_df()
        pg_hook = PostgresHook(postgres_conn_id=POSTGRES_CONN_ID)
        
        # BACC
        annee_col = get_col(df, 'annee_bacc')
        serie_col = get_col(df, 'serie_bacc')
        data_bacc = []
        if annee_col and serie_col:
            temp = df[[annee_col, serie_col]].dropna().drop_duplicates()
            temp = temp[(temp[annee_col] != 0) & (temp[annee_col] != '0')]
            data_bacc = [(clean_value(a), clean_value(s)) for a, s in temp.values.tolist()]
            data_bacc = [(a, s) for a, s in data_bacc if a and s]
        logger.info(f"  📊 BACC : {len(data_bacc)} enregistrements")
        
        # CIN
        date_cin_col = get_col(df, 'date_cin')
        lieu_cin_col = get_col(df, 'lieu_cin')
        data_cin = []
        if date_cin_col and lieu_cin_col:
            temp = df[[date_cin_col, lieu_cin_col]].dropna(how='all').drop_duplicates()
            data_cin = []
            for d, l in temp.values.tolist():
                d_clean = clean_value(d)
                l_clean = clean_value(l)
                if d_clean and d_clean != '0':
                    data_cin.append((d_clean, l_clean, None, None))
        logger.info(f"  📊 CIN : {len(data_cin)} enregistrements")
        
        # PROPOS
        adresse_col = get_col(df, 'adresse')
        email_col = get_col(df, 'email')
        sexe_col = get_col(df, 'sexe')
        data_propos = []
        if adresse_col or email_col or sexe_col:
            cols = [c for c in [adresse_col, email_col, sexe_col] if c]
            temp = df[cols].dropna(how='all').drop_duplicates()
            data_propos = []
            for row_vals in temp.values.tolist():
                cleaned = [clean_value(v) for v in row_vals]
                if any(cleaned):
                    data_propos.append(tuple(cleaned))
        logger.info(f"  📊 PROPOS : {len(data_propos)} enregistrements")
        
        # Création tables
        sql = """
        CREATE TABLE IF NOT EXISTS raw.bacc_raw (
            id SERIAL PRIMARY KEY, 
            annee TEXT, 
            serie TEXT, 
            UNIQUE(annee, serie)
        );
        CREATE TABLE IF NOT EXISTS raw.cin_raw (
            id SERIAL PRIMARY KEY, 
            date_cin TEXT, 
            lieu TEXT, 
            ancien_date TEXT, 
            nouveau_date TEXT
        );
        CREATE TABLE IF NOT EXISTS raw.propos_raw (
            id SERIAL PRIMARY KEY, 
            adresse TEXT, 
            email TEXT, 
            sexe TEXT
        );
        TRUNCATE raw.bacc_raw, raw.cin_raw, raw.propos_raw RESTART IDENTITY CASCADE;
        """
        pg_hook.run(sql)
        
        # Insertions avec gestion des doublons
        if data_bacc:
            # Utiliser une requête SQL avec ON CONFLICT
            conn = pg_hook.get_conn()
            cursor = conn.cursor()
            try:
                for annee, serie in data_bacc:
                    cursor.execute(
                        """
                        INSERT INTO raw.bacc_raw (annee, serie) 
                        VALUES (%s, %s) 
                        ON CONFLICT (annee, serie) DO NOTHING
                        """,
                        (annee, serie)
                    )
                conn.commit()
                logger.info(f"  ✅ BACC : {len(data_bacc)} enregistrements traités")
            finally:
                cursor.close()
                conn.close()
        
        if data_cin:
            pg_hook.insert_rows("raw.cin_raw", data_cin, 
                ["date_cin", "lieu", "ancien_date", "nouveau_date"])
            logger.info(f"  ✅ CIN : {len(data_cin)} enregistrements insérés")
        
        if data_propos:
            if len(data_propos[0]) == 3:
                pg_hook.insert_rows("raw.propos_raw", data_propos, 
                    ["adresse", "email", "sexe"])
            elif len(data_propos[0]) == 2:
                data_propos = [(a, b, None) if not email_col else (a, None, b) 
                              for a, b in data_propos]
                pg_hook.insert_rows("raw.propos_raw", data_propos, 
                    ["adresse", "email", "sexe"])
            logger.info(f"  ✅ PROPOS : {len(data_propos)} enregistrements insérés")
        
        logger.info("🎉 SUCCÈS")
        
    except Exception as e:
        logger.error(f"❌ ERREUR : {e}")
        raise

def import_etudiants_et_niveau_etudiant():
    """Importe étudiants, niveau_etudiant et inscrits."""
    try:
        logger.info("=" * 70)
        logger.info("🚀 DÉBUT : import_etudiants")
        logger.info("=" * 70)
        
        df = get_df()
        pg_hook = PostgresHook(postgres_conn_id=POSTGRES_CONN_ID)
        
        # Lookups
        def get_lookup(table, key_col):
            res = pg_hook.get_records(f"SELECT {key_col}, id FROM raw.{table}")
            return {str(row[0]): row[1] for row in res if row[0]}
        
        sexe_map = get_lookup("sexes_raw", "nom")
        mention_map = get_lookup("mentions_raw", "nom")
        niveau_map = get_lookup("niveaux_raw", "nom")
        
        bacc_res = pg_hook.get_records("SELECT annee, serie, id FROM raw.bacc_raw")
        bacc_map = {f"{r[0]}{r[1]}": r[2] for r in bacc_res}
        
        cin_res = pg_hook.get_records("SELECT date_cin, lieu, id FROM raw.cin_raw")
        cin_map = {f"{r[0]}_{r[1]}": r[2] for r in cin_res}
        
        propos_res = pg_hook.get_records("SELECT email, id FROM raw.propos_raw WHERE email IS NOT NULL")
        propos_map = {str(r[0]): r[1] for r in propos_res}
        
        logger.info(f"  ✓ Lookups chargés")
        
        # Préparation données
        etudiants_uniques = {}
        niveau_etudiant_data = []
        inscrits_data = []
        
        nom_col = get_col(df, 'nom')
        prenoms_col = get_col(df, 'prenoms')
        
        for idx, row in df.iterrows():
            if pd.isna(row.get(nom_col)):
                continue
            
            nom = str(row[nom_col]).strip().upper()
            prenoms = str(row.get(prenoms_col, '')).strip().upper() if prenoms_col and pd.notna(row.get(prenoms_col)) else ''
            etud_key = (nom, prenoms)
            
            # IDs
            sexe_col = get_col(df, 'sexe')
            mention_col = get_col(df, 'mention')
            niveau_col = get_col(df, 'niveau')
            annee_bacc_col = get_col(df, 'annee_bacc')
            serie_bacc_col = get_col(df, 'serie_bacc')
            date_cin_col = get_col(df, 'date_cin')
            lieu_cin_col = get_col(df, 'lieu_cin')
            email_col = get_col(df, 'email')
            annee_univ_col = get_col(df, 'annee_univ')
            date_inscription_col = get_col(df, 'date_inscription')
            date_naissance_col = get_col(df, 'date_naissance')
            lieu_nai_col = get_col(df, 'lieu_nai')
            
            s_id = sexe_map.get(str(row.get(sexe_col, ''))) if sexe_col else None
            m_id = mention_map.get(str(row.get(mention_col, ''))) if mention_col else None
            n_id = niveau_map.get(str(row.get(niveau_col, ''))) if niveau_col else None
            
            # BACC - nettoyer les valeurs
            bacc_annee = clean_value(row.get(annee_bacc_col, '')) if annee_bacc_col else ''
            bacc_serie = clean_value(row.get(serie_bacc_col, '')) if serie_bacc_col else ''
            bacc_key = f"{bacc_annee}{bacc_serie}" if bacc_annee and bacc_serie else None
            b_id = bacc_map.get(bacc_key) if bacc_key and bacc_key != '' else None
            
            # CIN - nettoyer les valeurs
            date_c = clean_value(row.get(date_cin_col, '')) if date_cin_col else ''
            lieu_c = clean_value(row.get(lieu_cin_col, '')) if lieu_cin_col else ''
            cin_key = f"{date_c}_{lieu_c}" if date_c and lieu_c else None
            c_id = cin_map.get(cin_key) if cin_key and cin_key != '_' else None
            
            # PROPOS (email) - nettoyer les valeurs
            email_val = clean_value(row.get(email_col, '')) if email_col else None
            p_id = propos_map.get(str(email_val)) if email_val else None
            
            # Étudiant unique
            if etud_key not in etudiants_uniques:
                etud_id = len(etudiants_uniques) + 1
                etudiants_uniques[etud_key] = {
                    'id': etud_id,
                    'data': (
                        nom, 
                        prenoms or None,
                        clean_value(row.get(date_naissance_col)) if date_naissance_col else None,
                        clean_value(row.get(lieu_nai_col)) if lieu_nai_col else None,
                        s_id, b_id, c_id, p_id
                    )
                }
            else:
                etud_id = etudiants_uniques[etud_key]['id']
            
            # Niveau étudiant
            date_inscr = clean_value(row.get(date_inscription_col)) if date_inscription_col else None
            if not date_inscr and annee_univ_col:
                annee_u = row.get(annee_univ_col)
                if pd.notna(annee_u):
                    date_inscr = f"01/01/{annee_u}"
            
            niveau_etudiant_data.append((
                n_id, 
                m_id,
                clean_value(row.get(annee_univ_col)) if annee_univ_col else None,
                date_inscr, 
                etud_id, 
                None
            ))
            
            # Inscrits
            niv = clean_value(row.get(niveau_col)) if niveau_col else 'N/A'
            ment = clean_value(row.get(mention_col)) if mention_col else 'N/A'
            annee = clean_value(row.get(annee_univ_col)) if annee_univ_col else 'N/A'
            desc = f"Inscription {niv or 'N/A'} {ment or 'N/A'} - Année {annee or 'N/A'}"
            inscrits_data.append((2, etud_id, desc, date_inscr))
        
        etudiants_data = [v['data'] for v in etudiants_uniques.values()]
        
        logger.info(f"  📊 {len(etudiants_data)} étudiants uniques")
        logger.info(f"  📊 {len(niveau_etudiant_data)} niveaux")
        logger.info(f"  📊 {len(inscrits_data)} inscriptions")
        
        # Création tables
        sql = """
        CREATE TABLE IF NOT EXISTS raw.etudiants_raw (id SERIAL PRIMARY KEY, nom TEXT NOT NULL, prenoms TEXT, date_naissance TEXT, lieu_naissance TEXT, sexe_id INT, bacc_id INT, cin_id INT, propos_id INT, UNIQUE(nom, prenoms));
        CREATE TABLE IF NOT EXISTS raw.niveau_etudiant_raw (id SERIAL PRIMARY KEY, niveau_id INT, mention_id INT, annee TEXT, date_insertion TEXT, etudiant_id INT, status_etudiant TEXT);
        CREATE TABLE IF NOT EXISTS raw.inscrits_raw (id SERIAL PRIMARY KEY, id_utilisateur INT DEFAULT 2, etudiant_id INT, descriptions TEXT, date_inscription TEXT);
        TRUNCATE raw.etudiants_raw, raw.niveau_etudiant_raw, raw.inscrits_raw RESTART IDENTITY CASCADE;
        """
        pg_hook.run(sql)
        
        # Insertions
        if etudiants_data:
            pg_hook.insert_rows("raw.etudiants_raw", etudiants_data,
                ["nom", "prenoms", "date_naissance", "lieu_naissance", "sexe_id", "bacc_id", "cin_id", "propos_id"])
        if niveau_etudiant_data:
            pg_hook.insert_rows("raw.niveau_etudiant_raw", niveau_etudiant_data,
                ["niveau_id", "mention_id", "annee", "date_insertion", "etudiant_id", "status_etudiant"])
        if inscrits_data:
            pg_hook.insert_rows("raw.inscrits_raw", inscrits_data,
                ["id_utilisateur", "etudiant_id", "descriptions", "date_inscription"])
        
        logger.info("🎉 SUCCÈS")
        
    except Exception as e:
        logger.error(f"❌ ERREUR : {e}")
        raise

# --- DAG ---
with DAG(
    dag_id='import_complet_performant',
    start_date=datetime(2025, 1, 1),
    schedule_interval=None,
    catchup=False,
    tags=['production', 'raw_import']
) as dag:
    t_ref = PythonOperator(task_id='import_ref_base', python_callable=import_referentiels_base)
    t_form = PythonOperator(task_id='import_formations', python_callable=import_formations)
    t_tech = PythonOperator(task_id='import_bacc_cin_propos', python_callable=import_bacc_cin_propos)
    t_etud = PythonOperator(task_id='import_etudiants_et_niveaux', python_callable=import_etudiants_et_niveau_etudiant)
    [t_ref, t_form, t_tech] >> t_etud