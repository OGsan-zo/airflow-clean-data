#!/bin/bash

cd ~/Documents/Studies/ITU/Serveur/airflow
source airflow_env/bin/activate
export AIRFLOW_HOME=$(pwd)
airflow scheduler
