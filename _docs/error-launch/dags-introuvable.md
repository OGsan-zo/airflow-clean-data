### 1. Le conflit de configuration (le plus probable)
- Dans ton message précédent, tu as fait un export AIRFLOW__CORE__DAGS_FOLDER=$(pwd). Les variables d'environnement (export) sont prioritaires sur ton fichier airflow.cfg. Si tu as fait cet export alors que tu étais dans le dossier Serveur (et non Serveur/dags), Airflow continue de boucler sur tout le projet et plante avant de lire ton script.

La solution : Force Airflow à utiliser le bon dossier pour cette session :

```
export AIRFLOW__CORE__DAGS_FOLDER=/home/zo-kely/Documents/Studies/ITU/Stage/ESPA/Data-cleaner/Serveur/dags
airflow dags list
```

### 2. Probleme de dependance 
Le problème est clair : **pandas n'est pas installé dans votre environnement Airflow**.

#### Solution :

##### 1. Installez pandas dans l'environnement virtuel Airflow :

```bash
# Activez votre environnement virtuel si ce n'est pas déjà fait
source /home/zo-kely/Documents/Studies/ITU/Stage/ESPA/Data-cleaner/Serveur/airflow_env/bin/activate

# Installez pandas
pip install pandas
```

##### 2. Installez également les autres dépendances nécessaires :

```bash
# Si vous utilisez PostgreSQL (comme indiqué dans votre DAG)
pip install apache-airflow-providers-postgres

# Pour la connexion PostgreSQL
pip install psycopg2-binary

# Ou si vous préférez
pip install psycopg2
```

##### 3. Vérifiez que pandas est bien installé :

```bash
python -c "import pandas; print(f'Pandas version: {pandas.__version__}')"
```

##### 4. Redémarrez les services Airflow :

```bash
# Arrêtez d'abord les services en cours
# Ctrl+C dans les terminaux où tournent airflow scheduler et airflow webserver

# Redémarrez le scheduler
airflow scheduler

# Dans un autre terminal, redémarrez le webserver
airflow webserver --port 8080
```

##### 5. Vérifiez que le DAG apparaît maintenant :

```bash
airflow dags list | grep etl_scolarite
```

## Alternative si vous voulez un environnement plus propre :

Si vous préférez gérer les dépendances de manière organisée, créez un fichier `requirements.txt` :

```bash
cd /home/zo-kely/Documents/Studies/ITU/Stage/ESPA/Data-cleaner/Serveur/
cat > requirements.txt << 'EOF'
pandas>=1.5.0
apache-airflow-providers-postgres>=5.0.0
psycopg2-binary>=2.9.0
EOF

# Installez toutes les dépendances
pip install -r requirements.txt
```

## Note importante :

Airflow a son propre environnement Python isolé. Même si pandas est installé globalement sur votre système, vous devez l'installer **dans l'environnement virtuel Airflow** car c'est là que les DAGs sont exécutés.

Après avoir installé pandas, votre DAG devrait apparaître dans la liste des DAGs disponibles.