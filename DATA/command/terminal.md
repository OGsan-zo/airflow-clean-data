# List of all command 


## 1- Prendre les details de la Base de donnee  
1. `Moins` de details de la base :
> sudo -u postgres pg_dump \
  --schema-only \
  --no-owner \
  --no-privileges \
  nom_de_ta_base > schema.sql



2. Pour `Plus` de details de la base : 
> sudo -u postgres pg_dump -s nom_de_ta_base > schema.sql

## 2- Creation de la base de test 
+ 2 commandes sont disponible : 
    * Si tu veux creer la base de donnee propre , fait la commande `1`.
    + Si tu veux la meme structure que ta base fait la commande `2`. 

***Attention*** : 
```javascript
La commande `2` copie exactement ta base de donnee => 'Structure + Data'. 

```

1. La commande pour creer une base postgres 
> sudo -u postgres createdb ma_base_test

2. Commande pour copier ta base de donnee dans une nouvelle base de test
> sudo -u postgres createdb ma_base_test -T ma_base_prod


## 3- Supprimer la base de donnee 
***Attention*** :
```javascript
Tu dois DECONNECTER toutes les bases de donnees qui peuvent etre connecter AVANT DE LA SUPPRIMER.
```

Voici la commande
> sudo -u postgres dropdb ma_base_test

## 4- Verifier de la base 
+ Pour verifier si votre base de donnee a bien ete creer ou supprimer :
> sudo -u postgres psql -l


