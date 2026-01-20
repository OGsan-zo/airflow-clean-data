# ✅ 1️⃣ Principe utilisé

L’ordre d’insertion dépend **uniquement des clés étrangères (FK)** :

* ✅ **Tables sans FK** → à insérer en premier
* 🔁 **Tables dépendantes** → après
* 🔗 **Tables de liaison** → en dernier

---

# 🟢 2️⃣ TABLES À INSÉRER EN PREMIER (tables de référence)

Ces tables **ne dépendent d’aucune autre**.
👉 **Elles doivent être remplies avant tout le reste.**

### 🔹 Niveau 1 – Référentiels purs

```
bacc
cin
mentions
niveaux
parcours
propos
role
sexes
status
status_etudiants
type_droits
type_formations
```

👉 Typiquement :

* valeurs fixes
* listes
* dictionnaires
* peu de lignes

🟢 **On les remplit avec des `SELECT DISTINCT` depuis l’Excel**

---

# 🟡 3️⃣ TABLES PRINCIPALES (dépendent des référentiels)

Ces tables utilisent des clés étrangères vers les tables ci-dessus.

### 🔹 Niveau 2 – Entités principales

```
utilisateur
etudiants
formations
```

Dépendances :

* `etudiants` → bacc, cin, sexes, status_etudiants
* `formations` → type_formations, mentions, niveaux, parcours
* `utilisateur` → role, status

👉 ⚠️ **Ne pas les insérer tant que les référentiels ne sont pas remplis**

---

# 🟠 4️⃣ TABLES DÉPENDANTES / MÉTIER

Ces tables dépendent **directement des entités principales**.

### 🔹 Niveau 3

```
inscrits
inscriptions
droits
ecolages
payements_ecolages
formation_etudiants
niveau_etudiants
status_etudiants (liaison)
```

👉 C’est ici qu’on respecte :

* l’ordre d’insertion
* les batchs
* les transactions

---

# 🔴 5️⃣ ORDRE FINAL D’INSERTION (résumé clair)

### ✅ ORDRE OFFICIEL À SUIVRE

1. **Référentiels**

   * bacc, cin, sexes, mentions, niveaux, parcours, propos, role, status, type_droits, type_formations

2. **Entités principales**

   * utilisateur
   * etudiants
   * formations

3. **Relations / métier**

   * inscriptions
   * inscrits
   * droits
   * ecolages
   * payements_ecolages
   * formation_etudiants
   * niveau_etudiants

👉 Cet ordre **évite 100 % des erreurs FK**.

---
