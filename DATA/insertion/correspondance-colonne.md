Parfait 👍
Maintenant on peut être **très précis**, parce que j’ai **lu ton fichier CSV** et j’ai la **liste exacte des colonnes Excel**.

Je vais te donner **clairement** :

1. ✅ les **tables à insérer en premier**
2. 🔗 les **colonnes Excel correspondantes**
3. 🧭 l’**ordre logique d’insertion**

---

# 📊 1️⃣ Colonnes présentes dans ton fichier Excel (CSV)

Voici les colonnes **réelles** de ton fichier :

```
CLEPRIM
CODETUD
NOM
AUNIV
NIVEAU
type_formation
MENTION
EXONERE
matricule
mail
phone
num_fiche_bourse
gp
code_redoublement
cdparc
sexe
date_naissance
num_cin
date_cin
nationalite
annee_bacc
serie_bacc
bouriser
taux_bourses
adresse
semestre
lieu_cin
lieu_nai
date_duplicata
lieu_dupli
montant_b
date_inscription
num_exam
resultat
rattrapage_semestre_impaire
rattrapage_semestre_paire
NIVEAUADMIN
moyenne_semestre_impaire
moyenne_semestre_paire
moyenne_generale
rang
```

---

# 🟢 2️⃣ TABLES À INSÉRER EN PREMIER (RÉFÉRENTIELS)

Ces tables **ne dépendent d’aucune autre** et sont directement issues de l’Excel.

## 🔹 Table `sexes`

| Table         | Colonne Excel |
| ------------- | ------------- |
| sexes.libelle | `sexe`        |

```sql
INSERT INTO sexes(libelle)
SELECT DISTINCT sexe
FROM staging_excel
WHERE sexe IS NOT NULL;
```

---

## 🔹 Table `mentions`

| Table            | Colonne Excel |
| ---------------- | ------------- |
| mentions.libelle | `MENTION`     |

---

## 🔹 Table `niveaux`

| Table           | Colonne Excel |
| --------------- | ------------- |
| niveaux.libelle | `NIVEAU`      |
| niveaux.admin   | `NIVEAUADMIN` |

---

## 🔹 Table `parcours`

| Table         | Colonne Excel |
| ------------- | ------------- |
| parcours.code | `cdparc`      |

---

## 🔹 Table `type_formations`

| Table                   | Colonne Excel    |
| ----------------------- | ---------------- |
| type_formations.libelle | `type_formation` |

---

## 🔹 Table `bacc`

| Table      | Colonne Excel |
| ---------- | ------------- |
| bacc.annee | `annee_bacc`  |
| bacc.serie | `serie_bacc`  |

---

## 🔹 Table `cin`

| Table               | Colonne Excel |
| ------------------- | ------------- |
| cin.numero          | `num_cin`     |
| cin.date_delivrance | `date_cin`    |
| cin.lieu            | `lieu_cin`    |

---

## 🔹 Table `status_etudiants`

| Table                    | Colonne Excel |
| ------------------------ | ------------- |
| status_etudiants.libelle | `resultat`    |

---

## 🔹 Table `type_droits`

| Table               | Colonne Excel |
| ------------------- | ------------- |
| type_droits.libelle | `EXONERE`     |

---

# 🟡 3️⃣ TABLES PRINCIPALES (APRÈS RÉFÉRENTIELS)

## 🔸 Table `etudiants`

| Champ          | Colonne Excel              |
| -------------- | -------------------------- |
| nom            | `NOM`                      |
| matricule      | `matricule`                |
| email          | `mail`                     |
| telephone      | `phone`                    |
| date_naissance | `date_naissance`           |
| adresse        | `adresse`                  |
| nationalite    | `nationalite`              |
| sexe_id        | `sexe → sexes.id`          |
| cin_id         | `num_cin → cin.id`         |
| bacc_id        | `(annee_bacc, serie_bacc)` |

👉 **Ne pas insérer tant que les tables ci-dessus ne sont pas remplies**

---

## 🔸 Table `formations`

| Champ             | Colonne Excel    |
| ----------------- | ---------------- |
| type_formation_id | `type_formation` |
| mention_id        | `MENTION`        |
| niveau_id         | `NIVEAU`         |
| parcours_id       | `cdparc`         |

---

# 🟠 4️⃣ TABLES MÉTIER / RELATIONNELLES

## 🔸 Table `inscriptions`

| Champ            | Colonne Excel      |
| ---------------- | ------------------ |
| etudiant_id      | `matricule`        |
| formation_id     | via jointure       |
| date_inscription | `date_inscription` |
| semestre         | `semestre`         |

---

## 🔸 Table `droits`

| Champ         | Colonne Excel  |
| ------------- | -------------- |
| type_droit_id | `EXONERE`      |
| montant       | `montant_b`    |
| taux          | `taux_bourses` |

---

# 🧭 5️⃣ ORDRE FINAL D’INSERTION (OFFICIEL)

### ✅ À respecter strictement

1. sexes
2. mentions
3. niveaux
4. parcours
5. type_formations
6. bacc
7. cin
8. status_etudiants
9. type_droits
10. etudiants
11. formations
12. inscriptions
13. droits

---
