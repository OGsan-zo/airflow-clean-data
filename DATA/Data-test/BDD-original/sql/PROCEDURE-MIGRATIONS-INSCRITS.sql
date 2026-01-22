-- ============================================================
-- PROCÉDURES STOCKÉES POUR LA MIGRATION RAW → PUBLIC
-- VERSION COMPATIBLE DBEAVER
-- ============================================================

--@DELIMITER $PROC$

-- ====================
-- 6. Migration des inscrits (MISE À JOUR UNIQUEMENT)
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

--@DELIMITER ;