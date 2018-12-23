# Documentation
Bienvenue sur ce projet de BDD avancée, traitant de la normalisation. 
Le but du projet était de produire une base de donnée afin d'aider un groupe de projet tutoré à créer une sorte de Pokémon GO pour touriste. (C'est la raison pour laquelle nous appelerons ce projet PPGO : _Presque Pokémon Go_)
![MCD de notre Table](./bdd.png)

## Initialisation de la BDD

### 1 - Création des Tables

####Table Profil

~~~~sql    
    CREATE TABLE profil (
        id_personne serial NOT NULL PRIMARY KEY,
        mot_de_passe text NOT NULL,
        pseudo text NOT NULL,
        email text NOT NULL,
        nom_personne text NOT NULL,
        prenom_personne text NOT NULL,
        date_naissance text NOT NULL,
        avatar text NOT NULL,
        distance_parcourue float NOT NULL DEFAULT 0,
        nombre_points int NOT NULL DEFAULT 0,
        compte_verifié int DEFAULT 0,
        compte_actif int DEFAULT 1,
        date_derniere_connexion DATE DEFAULT current_timestamp
    );  
~~~~
## La Normalisation
