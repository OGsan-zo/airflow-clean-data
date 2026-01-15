# 1. Aller dans le dossier de travail
cd ~/Documents/Studies/ITU/S6/Mr\ Naina/Airflow/TP/airflow_env

# 2. Créer un environnement virtuel (si ce n’est pas encore fait)
python3 -m venv venv

# 3. Activer l’environnement virtuel
source venv/bin/activate

# 4. Mettre pip à jour
pip install --upgrade pip setuptools wheel

# 5. Définir la version souhaitée d'Airflow (ex : 2.7.3)
AIRFLOW_VERSION=2.7.3
PYTHON_VERSION="$(python --version | cut -d " " -f 2 | cut -d "." -f 1,2)"
CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"

# 6. Installer Apache Airflow avec les contraintes officielles
pip install "apache-airflow==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}"
