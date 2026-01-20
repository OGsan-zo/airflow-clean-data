# ETL & Airflow

---
## Installation de Airflow 

### Installation LOCAL 
1. Aller dans `_docs/installation/new` 
2. Voir le contenu du fichier `_install.sh` (Renommer le fichier si vous etes sur windows en .bat)
3. Changer le dossier d'installation.

### Installation DOCKER
1. Aller dans `DWH-main/airflow-docker`
2. Executer le docker : `docker-installation-airflow.sh` (Renommer le fichier si vous etes sur windows en .bat)


--- 
## Utilisation de Airflow

### Démarrage
1. Aller dans le dossier :
   ```bash
   docs/installation/lancement/
    ````
2. Lancer Airflow :

   ```bash
   ./start_airflow.sh
   ```
--- 
### Arrêt

    ```bash
    ./stop_airflow.sh
    ```
---
## Configuration de Airflow 
1. Installer les requirements dans votre terminal qui est dans l'environnement d'airflow :
   ```bash
   pip install -r requirements.txt
   ```
**NB:** Si vous etes sur le docker , veuillez lire le contenu du fichier `requirements.txt` pour mieux installer vos propres dependances. 
