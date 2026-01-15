# 1. Vérifier que Airflow est installé
airflow version

# 2. Initialiser la base de données Airflow (obligatoire)
airflow db init

# 3. Créer un utilisateur admin pour le web UI
airflow users create \
    --username admin \
    --firstname Zo \
    --lastname Kely \
    --role Admin \
    --email atn.randr@gmail.com \
    --password admin

# 4. Lancer le webserver dans un terminal
airflow webserver --port 8080

# 5. Dans un autre terminal (même venv), lancer le scheduler
airflow scheduler
