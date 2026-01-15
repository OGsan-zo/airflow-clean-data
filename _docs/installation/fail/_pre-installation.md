# 1. Vérifier la version de Python (>= 3.7)
python3 --version

# 2. Vérifier que pip est installé
pip3 --version

# 3. Vérifier que vous avez accès à virtualenv
virtualenv --version

# 4. Vérifier que vous êtes dans le bon dossier
pwd
# Il doit afficher :
# /home/zo-kely/Documents/Studies/ITU/S6/Mr Naina/Airflow/TP/airflow_env

# 5. Vérifier qu'il n'y a pas déjà un environnement virtuel actif
echo $VIRTUAL_ENV
# S'il retourne quelque chose → un venv est déjà actif
