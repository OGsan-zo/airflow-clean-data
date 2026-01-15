#!/bin/bash

set -e  # stop on error

cd ~/Documents/Studies/ITU/Serveur/airflow

# 1. Créer un environnement virtuel
python3 -m venv airflow_env
source airflow_env/bin/activate

# 2. Upgrade pip
pip install --upgrade pip setuptools wheel

# 3. Définir les versions
AIRFLOW_VERSION=2.9.1
PYTHON_VERSION="$(python --version | cut -d' ' -f2 | cut -d. -f1-2)"
CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"

# 4. Installer Airflow avec PostgreSQL support
pip install "apache-airflow[postgres,mysql,celery]==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}"

# 5. Initialiser le dossier Airflow
export AIRFLOW_HOME=$(pwd)
airflow db init

# 6. Créer un utilisateur admin
airflow users create \
    --username admin \
    --firstname Zo \
    --lastname Kely \
    --role Admin \
    --email atn.randr@gmail.com \
    --password admin

echo "✅ Installation terminée. Active l’environnement avec :"
echo "source airflow_env/bin/activate"
