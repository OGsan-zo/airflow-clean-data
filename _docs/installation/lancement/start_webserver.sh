#!/bin/bash

cd ~/Documents/Studies/ITU/Stage/ESPA/Data-cleaner/Serveur
source airflow_env/bin/activate
export AIRFLOW_HOME=$(pwd)
airflow webserver --port 8080 --workers 1
