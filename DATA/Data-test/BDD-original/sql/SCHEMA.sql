-- ============================================
-- CRÉATION SIMPLIFIÉE DE LA BASE DE DONNÉES
-- Système de gestion des étudiants
-- ============================================

-- Tables de référence de base
-- ============================================

CREATE TABLE sexes (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(50) NOT NULL
);

CREATE TABLE status (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE status_etudiants (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

CREATE TABLE role (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- Tables utilisateurs
-- ============================================

CREATE TABLE utilisateur (
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

-- Tables informations personnelles
-- ============================================

CREATE TABLE cin (
    id SERIAL PRIMARY KEY,
    numero INTEGER NOT NULL,
    date_cin TIMESTAMP NOT NULL,
    lieu VARCHAR(255) NOT NULL,
    ancien_date TIMESTAMP NOT NULL,
    nouveau_date TIMESTAMP NOT NULL
);

CREATE TABLE bacc (
    id SERIAL PRIMARY KEY,
    numero VARCHAR(255),
    annee INTEGER NOT NULL,
    serie VARCHAR(50) NOT NULL
);

CREATE TABLE propos (
    id SERIAL PRIMARY KEY,
    adresse VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    sexe VARCHAR(50) NOT NULL
);

-- Table étudiants
-- ============================================

CREATE TABLE etudiants (
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

-- Tables académiques
-- ============================================

CREATE TABLE mentions (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    abr VARCHAR(10)
);

CREATE TABLE niveaux (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    type SMALLINT NOT NULL,
    grade SMALLINT NOT NULL
);

CREATE TABLE parcours (
    id SERIAL PRIMARY KEY,
    mention_id INTEGER NOT NULL,
    nom VARCHAR(100) NOT NULL,
    FOREIGN KEY (mention_id) REFERENCES mentions(id)
);

CREATE TABLE type_formations (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL
);

CREATE TABLE formations (
    id SERIAL PRIMARY KEY,
    type_formation_id INTEGER NOT NULL,
    nom VARCHAR(100) NOT NULL,
    FOREIGN KEY (type_formation_id) REFERENCES type_formations(id)
);

-- Tables de liaison étudiants-formations
-- ============================================

CREATE TABLE niveau_etudiants (
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

CREATE TABLE formation_etudiants (
    id SERIAL PRIMARY KEY,
    etudiant_id INTEGER NOT NULL,
    formation_id INTEGER NOT NULL,
    date_formation TIMESTAMP NOT NULL,
    FOREIGN KEY (etudiant_id) REFERENCES etudiants(id),
    FOREIGN KEY (formation_id) REFERENCES formations(id)
);

-- Tables inscriptions
-- ============================================

CREATE TABLE inscriptions (
    id SERIAL PRIMARY KEY,
    etudiant_id INTEGER NOT NULL,
    utilisateur_id INTEGER NOT NULL,
    date_inscription TIMESTAMP NOT NULL,
    FOREIGN KEY (etudiant_id) REFERENCES etudiants(id),
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateur(id)
);

CREATE TABLE inscrits (
    id SERIAL PRIMARY KEY,
    utilisateur_id INTEGER NOT NULL,
    etudiant_id INTEGER NOT NULL,
    description VARCHAR(255) NOT NULL,
    date_inscription TIMESTAMP NOT NULL,
    matricule VARCHAR(255),
    FOREIGN KEY (etudiant_id) REFERENCES etudiants(id),
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateur(id)
);

-- Tables financières
-- ============================================

CREATE TABLE type_droits (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL
);

CREATE TABLE droits (
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

CREATE TABLE ecolages (
    id SERIAL PRIMARY KEY,
    formations_id INTEGER NOT NULL,
    montant DOUBLE PRECISION NOT NULL,
    date_ecolage TIMESTAMP,
    FOREIGN KEY (formations_id) REFERENCES formations(id)
);

CREATE TABLE payements_ecolages (
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

-- ============================================
-- Index pour optimisation des performances
-- ============================================

CREATE INDEX idx_utilisateur_role ON utilisateur(role_id);
CREATE INDEX idx_utilisateur_status ON utilisateur(status_id);
CREATE INDEX idx_etudiants_cin ON etudiants(cin_id);
CREATE INDEX idx_etudiants_bacc ON etudiants(bacc_id);
CREATE INDEX idx_etudiants_propos ON etudiants(propos_id);
CREATE INDEX idx_niveau_etudiants_niveau ON niveau_etudiants(niveau_id);
CREATE INDEX idx_niveau_etudiants_mention ON niveau_etudiants(mention_id);
CREATE INDEX idx_niveau_etudiants_etudiant ON niveau_etudiants(etudiant_id);
CREATE INDEX idx_formation_etudiants_etudiant ON formation_etudiants(etudiant_id);
CREATE INDEX idx_formation_etudiants_formation ON formation_etudiants(formation_id);
CREATE INDEX idx_inscriptions_etudiant ON inscriptions(etudiant_id);
CREATE INDEX idx_inscriptions_utilisateur ON inscriptions(utilisateur_id);
CREATE INDEX idx_droits_etudiant ON droits(etudiant_id);
CREATE INDEX idx_droits_utilisateur ON droits(utilisateur_id);
CREATE INDEX idx_payements_etudiant ON payements_ecolages(etudiant_id);
CREATE INDEX idx_payements_utilisateur ON payements_ecolages(utilisateur_id);