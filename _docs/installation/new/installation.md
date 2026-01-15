Parfait ! 👌 On va **supprimer proprement l'ancienne installation** et ensuite **installer Airflow dans ton nouveau répertoire propre** :

---

## 🧹 ÉTAPE 1 – Supprimer l’ancienne installation d’Airflow

### 🔍 1.1 Trouver l'ancien environnement

Si tu avais un environnement `airflow_env` dans un répertoire comme :

```
~/Documents/Studies/ITU/S6/Mr Naina/Airflow/TP/airflow_env/
```

Alors tu peux simplement **le supprimer** :

```bash
rm -rf ~/Documents/Studies/ITU/S6/Mr\ Naina/Airflow/TP/airflow_env
```

(⚠️ Le `\` sert à gérer l’espace dans `Mr Naina`)

Tu peux aussi supprimer le `AIRFLOW_HOME` de cette installation, s’il existe :

```bash
rm -rf ~/airflow
```

### 🚫 1.2 Vérifie que `airflow` n’est plus globalement accessible

Après avoir désactivé tout environnement :

```bash
deactivate
which airflow
```

Si ça ne retourne **rien**, c’est parfait. Sinon, on l’a mal supprimé.

---

## 🏗️ ÉTAPE 2 – Nouvelle installation d’Airflow dans `~/Documents/Studies/ITU/S6/Serveur`

### 📁 2.1 Crée un dossier propre

```bash
cd ~/Documents/Studies/ITU/S6/Serveur
mkdir airflow_project
cd airflow_project
```

### 🐍 2.2 Crée et active un environnement virtuel

```bash
python3 -m venv airflow_env
source airflow_env/bin/activate
```

---

## 📥 ÉTAPE 3 – Installation propre d’Airflow

### 📌 3.1 Définir les variables d’environnement

```bash
export AIRFLOW_VERSION=3.0.0
export PYTHON_VERSION="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
export CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"
```

### ✅ 3.2 Installer Airflow avec contraintes officielles

```bash
pip install --upgrade pip
pip install "apache-airflow==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}"
```

### 🧩 3.3 Installer les providers SQL

```bash
pip install apache-airflow-providers-mysql apache-airflow-providers-postgres apache-airflow-providers-common-sql \
  --constraint "${CONSTRAINT_URL}"
```

---

## ⚙️ ÉTAPE 4 – Initialiser Airflow

### 📁 4.1 Définir un `AIRFLOW_HOME` propre dans le projet

Toujours dans `airflow_project` :

```bash
export AIRFLOW_HOME=$(pwd)/airflow_home
```

Et crée les dossiers nécessaires :

```bash
mkdir -p $AIRFLOW_HOME/dags
```

### 🛠️ 4.2 Initialiser la base de données Airflow

```bash
airflow db init
```

---

## 👤 ÉTAPE 5 – Créer un utilisateur admin

```bash
airflow users create \
  --username admin \
  --firstname Zo \
  --lastname Kely \
  --role Admin \
  --email zo@example.com \
  --password admin
```

---

## 🚀 ÉTAPE 6 – Lancer Airflow

### Dans un terminal :

```bash
airflow scheduler
```

### Dans un **autre** terminal :

```bash
source ~/Documents/Studies/ITU/S6/Serveur/airflow_project/airflow_env/bin/activate
export AIRFLOW_HOME=~/Documents/Studies/ITU/S6/Serveur/airflow_project/airflow_home
airflow webserver --port 8080
```

---

## 🎯 Résultat attendu

* Tu vas pouvoir ouvrir [http://localhost:8080](http://localhost:8080)
* Tu verras tes DAGs dans la section d’accueil.

---
