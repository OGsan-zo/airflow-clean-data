-- ============================================================
-- PROCÉDURES STOCKÉES POUR LA MIGRATION RAW → PUBLIC
-- VERSION COMPATIBLE DBEAVER - SCRIPT COMPLET
-- ============================================================

--@DELIMITER $PROC$

-- ====================
-- 1. Procédure de nettoyage intelligent
-- ====================
DROP PROCEDURE IF EXISTS public.clean_all_tables();

CREATE PROCEDURE public.clean_all_tables()
LANGUAGE plpgsql
AS $PROC$
DECLARE
    has_data BOOLEAN := FALSE;
BEGIN
    -- Vérifier s'il y a des données
    SELECT EXISTS (
        SELECT 1 FROM public.etudiants LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM public.sexes LIMIT 1
    ) INTO has_data;

    IF has_data THEN
        RAISE NOTICE 'Données détectées, nettoyage en cours...';
        
        -- Nettoyage avec CASCADE (ordre inverse des dépendances)
        TRUNCATE TABLE public.payements_ecolages RESTART IDENTITY CASCADE;
        TRUNCATE TABLE public.droits RESTART IDENTITY CASCADE;
        TRUNCATE TABLE public.inscriptions RESTART IDENTITY CASCADE;
        TRUNCATE TABLE public.inscrits RESTART IDENTITY CASCADE;
        TRUNCATE TABLE public.formation_etudiants RESTART IDENTITY CASCADE;
        TRUNCATE TABLE public.niveau_etudiants RESTART IDENTITY CASCADE;
        TRUNCATE TABLE public.etudiants RESTART IDENTITY CASCADE;
        TRUNCATE TABLE public.cin RESTART IDENTITY CASCADE;
        TRUNCATE TABLE public.bacc RESTART IDENTITY CASCADE;
        TRUNCATE TABLE public.propos RESTART IDENTITY CASCADE;
        TRUNCATE TABLE public.sexes RESTART IDENTITY CASCADE;
        TRUNCATE TABLE public.mentions RESTART IDENTITY CASCADE;
        TRUNCATE TABLE public.niveaux RESTART IDENTITY CASCADE;
        TRUNCATE TABLE public.status_etudiants RESTART IDENTITY CASCADE;
        
        RAISE NOTICE 'Toutes les tables ont été nettoyées';
    ELSE
        RAISE NOTICE 'Aucune donnée à nettoyer, première migration';
    END IF;

    -- Insertion des statuts par défaut
    INSERT INTO public.status_etudiants (name) 
    VALUES ('PASSANT'), ('REDOUBLANT'), ('ABANDONNE')
    ON CONFLICT DO NOTHING;

END;
$PROC$;

-- ====================
-- 2. Migration des référentiels (sexes, niveaux, mentions)
-- ====================
DROP PROCEDURE IF EXISTS public.migrate_referentials();

CREATE PROCEDURE public.migrate_referentials()
LANGUAGE plpgsql
AS $PROC$
DECLARE
    sexes_count INTEGER;
    niveaux_count INTEGER;
    mentions_count INTEGER;
BEGIN
    -- Migration sexes
    INSERT INTO public.sexes (nom)
    SELECT DISTINCT TRIM(nom) 
    FROM raw.sexes_raw 
    WHERE nom IS NOT NULL AND TRIM(nom) != ''
    ORDER BY TRIM(nom);
    
    GET DIAGNOSTICS sexes_count = ROW_COUNT;
    RAISE NOTICE 'Sexes migrés: %', sexes_count;

    -- Migration niveaux
    INSERT INTO public.niveaux (nom, type, grade)
    SELECT DISTINCT 
        TRIM(nom),
        COALESCE(type::SMALLINT, 1) as type,
        COALESCE(grade::SMALLINT, 1) as grade
    FROM raw.niveaux_raw 
    WHERE nom IS NOT NULL AND TRIM(nom) != ''
    ORDER BY TRIM(nom);
    
    GET DIAGNOSTICS niveaux_count = ROW_COUNT;
    RAISE NOTICE 'Niveaux migrés: %', niveaux_count;

    -- Migration mentions
    INSERT INTO public.mentions (nom, abr)
    SELECT DISTINCT 
        TRIM(nom),
        LEFT(UPPER(TRIM(nom)), 10) as abr
    FROM raw.mentions_raw 
    WHERE nom IS NOT NULL AND TRIM(nom) != ''
    ORDER BY TRIM(nom);
    
    GET DIAGNOSTICS mentions_count = ROW_COUNT;
    RAISE NOTICE 'Mentions migrées: %', mentions_count;

END;
$PROC$;

-- ====================
-- 3. Migration des tables techniques (CIN, BACC, PROPOS)
-- ====================
DROP PROCEDURE IF EXISTS public.migrate_technical_tables();

CREATE PROCEDURE public.migrate_technical_tables()
LANGUAGE plpgsql
AS $PROC$
DECLARE
    cin_count INTEGER;
    bacc_count INTEGER;
    propos_count INTEGER;
BEGIN
    -- Migration CIN
    INSERT INTO public.cin (numero, date_cin, lieu, ancien_date, nouveau_date)
    SELECT 
        id as numero,
        COALESCE(date_cin::TIMESTAMP, TIMESTAMP '1900-01-01 00:00:00') as date_cin,
        COALESCE(NULLIF(TRIM(lieu), ''), 'INCONNU') as lieu,
        COALESCE(ancien_date::TIMESTAMP, NOW()) as ancien_date,
        COALESCE(nouveau_date::TIMESTAMP, NOW()) as nouveau_date
    FROM raw.cin_raw;
    
    GET DIAGNOSTICS cin_count = ROW_COUNT;
    RAISE NOTICE 'CIN migrés: %', cin_count;

    -- Migration BACC
    INSERT INTO public.bacc (numero, annee, serie)
    SELECT DISTINCT 
        id::TEXT as numero,
        COALESCE(annee::NUMERIC::INTEGER, EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER) as annee,
        COALESCE(NULLIF(TRIM(serie), ''), 'INCONNU') as serie
    FROM raw.bacc_raw 
    ORDER BY COALESCE(annee::NUMERIC::INTEGER, EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER), 
             COALESCE(NULLIF(TRIM(serie), ''), 'INCONNU');
    
    GET DIAGNOSTICS bacc_count = ROW_COUNT;
    RAISE NOTICE 'BACC migrés: %', bacc_count;

    -- Migration PROPOS
    INSERT INTO public.propos (adresse, email, sexe)
    SELECT DISTINCT
        COALESCE(NULLIF(TRIM(adresse), ''), 'NON RENSEIGNE') as adresse,
        COALESCE(NULLIF(TRIM(email), ''), 'non.renseigne@unknown.com') as email,
        COALESCE(NULLIF(TRIM(sexe), ''), 'NON SPECIFIE') as sexe
    FROM raw.propos_raw;
    
    GET DIAGNOSTICS propos_count = ROW_COUNT;
    RAISE NOTICE 'PROPOS migrés: %', propos_count;

END;
$PROC$;

-- ====================
-- 4. Migration des étudiants
-- ====================
DROP PROCEDURE IF EXISTS public.migrate_students();

CREATE PROCEDURE public.migrate_students()
LANGUAGE plpgsql
AS $PROC$
DECLARE
    etudiants_count INTEGER;
    default_bacc_id INTEGER;
    default_propos_id INTEGER;
BEGIN
    -- Créer un BACC par défaut pour les étudiants sans info BACC
    INSERT INTO public.bacc (numero, annee, serie)
    VALUES ('INCONNU', EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER, 'NON RENSEIGNE')
    ON CONFLICT DO NOTHING
    RETURNING id INTO default_bacc_id;
    
    -- Si le BACC par défaut existe déjà, le récupérer
    IF default_bacc_id IS NULL THEN
        SELECT id INTO default_bacc_id 
        FROM public.bacc 
        WHERE numero = 'INCONNU' AND serie = 'NON RENSEIGNE'
        LIMIT 1;
    END IF;
    
    -- Créer un PROPOS par défaut pour les étudiants sans info PROPOS
    INSERT INTO public.propos (adresse, email, sexe)
    VALUES ('NON RENSEIGNE', 'non.renseigne@unknown.com', 'NON SPECIFIE')
    ON CONFLICT DO NOTHING
    RETURNING id INTO default_propos_id;
    
    -- Si le PROPOS par défaut existe déjà, le récupérer
    IF default_propos_id IS NULL THEN
        SELECT id INTO default_propos_id 
        FROM public.propos 
        WHERE adresse = 'NON RENSEIGNE' AND email = 'non.renseigne@unknown.com'
        LIMIT 1;
    END IF;
    
    RAISE NOTICE 'BACC par défaut ID: %, PROPOS par défaut ID: %', default_bacc_id, default_propos_id;
    
    -- Migration des étudiants avec gestion des valeurs manquantes
    INSERT INTO public.etudiants (
        nom, prenom, date_naissance, lieu_naissance, 
        sexe_id, cin_id, bacc_id, propos_id, status_etudiant_id
    )
    SELECT 
        UPPER(TRIM(r.nom)) as nom,
        COALESCE(NULLIF(TRIM(r.prenoms), ''), 'NON RENSEIGNE') as prenom,
        COALESCE(r.date_naissance::TIMESTAMP, TIMESTAMP '2000-01-01 00:00:00') as date_naissance,
        COALESCE(NULLIF(TRIM(r.lieu_naissance), ''), 'INCONNU') as lieu_naissance,
        COALESCE(s.id, 1) as sexe_id,
        r.cin_id,
        CASE 
            WHEN r.bacc_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.bacc WHERE id = r.bacc_id) 
            THEN r.bacc_id 
            ELSE default_bacc_id 
        END as bacc_id,
        CASE 
            WHEN r.propos_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.propos WHERE id = r.propos_id) 
            THEN r.propos_id 
            ELSE default_propos_id 
        END as propos_id,
        1 as status_etudiant_id
    FROM raw.etudiants_raw r
    LEFT JOIN public.sexes s ON s.id = r.sexe_id
    WHERE r.nom IS NOT NULL AND TRIM(r.nom) != '';
    
    GET DIAGNOSTICS etudiants_count = ROW_COUNT;
    RAISE NOTICE 'Étudiants migrés: %', etudiants_count;

END;
$PROC$;

-- ====================
-- 5. Migration de l'historique (niveau_etudiants)
-- ====================
DROP PROCEDURE IF EXISTS public.migrate_student_history();

CREATE PROCEDURE public.migrate_student_history()
LANGUAGE plpgsql
AS $PROC$
DECLARE
    history_count INTEGER;
BEGIN
    INSERT INTO public.niveau_etudiants (
        niveau_id, mention_id, etudiant_id, annee, 
        date_insertion, status_etudiant_id
    )
    SELECT DISTINCT
        r.niveau_id,
        r.mention_id,
        r.etudiant_id,
        COALESCE(r.annee::NUMERIC::INTEGER, EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER) as annee,
        CASE 
            WHEN r.date_insertion IS NULL OR r.date_insertion = '0000-00-00 00:00:00' 
            THEN NOW()
            ELSE r.date_insertion::TIMESTAMP
        END as date_insertion,
        COALESCE(r.status_etudiant::INTEGER, 1) as status_etudiant_id
    FROM raw.niveau_etudiant_raw r
    WHERE r.etudiant_id IS NOT NULL 
      AND r.niveau_id IS NOT NULL 
      AND r.mention_id IS NOT NULL
      AND EXISTS (SELECT 1 FROM public.etudiants WHERE id = r.etudiant_id)
      AND EXISTS (SELECT 1 FROM public.niveaux WHERE id = r.niveau_id)
      AND EXISTS (SELECT 1 FROM public.mentions WHERE id = r.mention_id);
    
    GET DIAGNOSTICS history_count = ROW_COUNT;
    RAISE NOTICE 'Historiques migrés: %', history_count;

END;
$PROC$;

-- ====================
-- 6. Migration des inscrits
-- ====================
DROP PROCEDURE IF EXISTS public.migrate_registrations();

CREATE PROCEDURE public.migrate_registrations()
LANGUAGE plpgsql
AS $PROC$
DECLARE
    inscrits_count INTEGER;
    default_user_id INTEGER := 1;
BEGIN
    -- Créer le rôle admin par défaut s'il n'existe pas
    INSERT INTO public.role (id, name)
    VALUES (1, 'ADMIN')
    ON CONFLICT (id) DO NOTHING;
    
    -- Créer le statut actif par défaut s'il n'existe pas
    INSERT INTO public.status (id, name)
    VALUES (1, 'ACTIF')
    ON CONFLICT (id) DO NOTHING;
    
    -- Créer l'utilisateur admin par défaut s'il n'existe pas
    INSERT INTO public.utilisateur (id, email, mdp, prenom, nom, status_id, role_id, date_creation)
    VALUES (
        1,
        'admin@gmail.com',
        '$2y$10$Djns8FgsL.xk2GBACEtJh.Hs1civTyvdGQ9s6gqbSgDN81QkOHvTi',
        'admin',
        'admin',
        1,
        1,
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;
    
    RAISE NOTICE 'Utilisateur admin (ID: %) vérifié/créé', default_user_id;
    
    -- Migration des inscrits avec vérification de l'utilisateur
    INSERT INTO public.inscrits (
        utilisateur_id, etudiant_id, description, 
        date_inscription, matricule
    )
    SELECT DISTINCT
        CASE 
            WHEN r.id_utilisateur IS NOT NULL AND EXISTS (SELECT 1 FROM public.utilisateur WHERE id = r.id_utilisateur)
            THEN r.id_utilisateur
            ELSE default_user_id
        END as utilisateur_id,
        r.etudiant_id,
        COALESCE(r.descriptions, 'INSCRIPTION STANDARD') as description,
        CASE 
            WHEN r.date_inscription IS NULL OR r.date_inscription = '0000-00-00 00:00:00' 
            THEN NOW()
            ELSE r.date_inscription::TIMESTAMP
        END as date_inscription,
        CONCAT('MAT', LPAD(r.etudiant_id::TEXT, 6, '0')) as matricule
    FROM raw.inscrits_raw r
    WHERE r.etudiant_id IS NOT NULL
      AND EXISTS (SELECT 1 FROM public.etudiants WHERE id = r.etudiant_id);
    
    GET DIAGNOSTICS inscrits_count = ROW_COUNT;
    RAISE NOTICE 'Inscrits migrés: %', inscrits_count;

END;
$PROC$;

-- ====================
-- 7. Procédure MASTER - Exécute toute la migration
-- ====================
DROP PROCEDURE IF EXISTS public.execute_full_migration();

CREATE PROCEDURE public.execute_full_migration()
LANGUAGE plpgsql
AS $PROC$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'DÉBUT DE LA MIGRATION COMPLÈTE';
    RAISE NOTICE '========================================';

    -- Étape 1 : Nettoyage
    RAISE NOTICE '[1/6] Nettoyage des tables...';
    CALL public.clean_all_tables();

    -- Étape 2 : Référentiels
    RAISE NOTICE '[2/6] Migration des référentiels...';
    CALL public.migrate_referentials();

    -- Étape 3 : Tables techniques
    RAISE NOTICE '[3/6] Migration des tables techniques...';
    CALL public.migrate_technical_tables();

    -- Étape 4 : Étudiants
    RAISE NOTICE '[4/6] Migration des étudiants...';
    CALL public.migrate_students();

    -- Étape 5 : Historique
    RAISE NOTICE '[5/6] Migration de l''historique...';
    CALL public.migrate_student_history();

    -- Étape 6 : Inscrits
    RAISE NOTICE '[6/6] Migration des inscrits...';
    CALL public.migrate_registrations();

    RAISE NOTICE '========================================';
    RAISE NOTICE 'MIGRATION TERMINÉE AVEC SUCCÈS';
    RAISE NOTICE '========================================';

END;
$PROC$;

--@DELIMITER ;

-- ============================================================
-- INSTRUCTIONS D'UTILISATION
-- ============================================================

/*
SCRIPT COMPLET COMPATIBLE DBEAVER

1. Sélectionnez TOUT le script (Ctrl+A)
2. Exécutez (Ctrl+Enter ou F5)

3. Pour tester individuellement dans PostgreSQL :
   CALL public.clean_all_tables();
   CALL public.migrate_referentials();
   CALL public.migrate_technical_tables();
   CALL public.migrate_students();
   CALL public.migrate_student_history();
   CALL public.migrate_registrations();

4. Pour exécuter toute la migration :
   CALL public.execute_full_migration();

5. Dans Airflow :
   sql="CALL public.execute_full_migration();"
*/