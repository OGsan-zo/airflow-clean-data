Voici exactement **comment lancer et arrêter Airflow** proprement dans ton environnement local sous Linux 👇

---

## ✅ **Avant toute chose : active ton environnement virtuel**

Avant de faire quoi que ce soit, **rentre dans ton dossier** et active l’environnement :

```bash
cd ~/Documents/Studies/ITU/S6/Mr\ Naina/Airflow/TP/airflow_env
source airflow_env/bin/activate
```

---

## 🚀 **Lancer Airflow**

### 1. Initialiser la base de données *(à faire une seule fois après installation)*

```bash
airflow db init
```

### 2. Créer un utilisateur admin *(si ce n'est pas encore fait)*

```bash
airflow users create \
  --username admin \
  --password admin \
  --firstname Zo \
  --lastname Kely \
  --role Admin \
  --email admin@example.com
```

### 3. Lancer le **Webserver** (interface web, port 8080)

```bash
airflow webserver --port 8080
```

> Ouvre ton navigateur sur : [http://localhost:8080](http://localhost:8080)

### 4. Dans un **autre terminal**, active encore le venv et lance le **Scheduler** :

```bash
source airflow_env/bin/activate
airflow scheduler
```

> Le Scheduler lit tes DAGs et déclenche les tâches automatiquement.

---

## 🛑 **Arrêter Airflow**

### Depuis les deux terminaux :

* Dans **le terminal du webserver** : presse `Ctrl + C` pour arrêter.
* Dans **le terminal du scheduler** : presse aussi `Ctrl + C`.

---

## 💡 (Optionnel) Tout lancer en un seul terminal

Tu peux aussi créer un script pour tout lancer d’un coup avec `tmux`, `screen` ou `&`, mais pour apprendre, c’est mieux d’utiliser **deux terminaux distincts** au début.

---

Souhaites-tu que je t’écrive un **petit script `start_airflow.sh`** pour automatiser le lancement complet ?
