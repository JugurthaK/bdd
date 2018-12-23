# Documentation
Bienvenue sur ce projet de BDD avancée, traitant de la normalisation. 
Le but du projet était de produire une base de donnée afin d'aider un groupe de projet tutoré à créer une sorte de Pokémon GO pour touriste. (C'est la raison pour laquelle nous appelerons ce projet PPGO : _Presque Pokémon Go_)
![MCD de notre Table](https://raw.githubusercontent.com/JugurthaK/bdd/master/img/bdd.PNG)
_MCD de notre BDD_

## Initialisation de la BDD

### 1 - Création des Tables

#### Table Profil

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
~~~~sql
    CREATE TABLE lieu(
	id_lieu serial NOT NULL PRIMARY KEY,
	id_personne int NOT NULL REFERENCES profil(id_personne),
	nom_lieu varchar(256) NOT NULL,
	positionX float NOT NULL,
	positionY float NOT NULL,
	nom_rue varchar(256) NOT NULL,
	nom_ville varchar (256) NOT NULL,
	code_postal varchar(256) NOT NULL,
	note_lieu float NOT NULL,
	lieu_payant integer NOT NULL default 0, /*tous gratuits, passer à 1 quand c'est payant*/
	photo_lieu text NOT NULL,
	description_lieu varchar(256) NOT NULL,
	verification_lieu integer NOT NULL DEFAULT 0, /*même trigger que validation_lieu*/
	nb_point integer NOT NULL
);
~~~~
~~~~sql
    CREATE TABLE validation_lieu(
    id_lieu serial NOT NULL,
    id_personne_visiteur int NOT NULL REFERENCES profil(id_personne),
    id_personne_verification int NOT NULL REFERENCES profil (id_personne),
    choix_verification int NOT NULL DEFAULT 0, /* Passer à 1 si nbVote > count(id_personne_verification)/2 */
	CONSTRAINT pk_validation_lieu PRIMARY KEY (id_lieu, id_personne_visiteur, id_personne_verification)
);
~~~~
~~~~sql
    CREATE TABLE photo_lieu (
	id_photo serial NOT NULL PRIMARY KEY,
    id_lieu int NOT NULL REFERENCES lieu(id_lieu),
    id_personne int NOT NULL REFERENCES profil(id_personne),
    lien_photo text NOT NULL, /* Photo en base 64 */
    note_photo int NOT NULL
);
~~~~
~~~~sql
    CREATE TABLE note_photo(
	id_personne integer NOT NULL REFERENCES profil(id_personne),
	id_photo integer NOT NULL REFERENCES photo_lieu(id_photo),
	note float,
	CONSTRAINT pk_note_photo PRIMARY KEY (id_personne, id_photo)
);
~~~~
~~~~sql
    CREATE TABLE note(
	id_personne integer NOT NULL REFERENCES profil(id_personne),
	id_lieu integer NOT NULL REFERENCES profil(id_personne),
	note float,
	CONSTRAINT pk_note PRIMARY KEY (id_personne, id_lieu)
);
~~~~
~~~~sql
    CREATE TABLE grade(
	id_grade serial NOT NULL PRIMARY KEY,
	nom_grade varchar(256) NOT NULL,
	logo_grade text NOT NULL,
	nb_points_necessaires integer NOT NULL,
);

~~~~
~~~~sql
    CREATE TABLE grade_obtenu(
	id_personne integer NOT NULL REFERENCES profil(id_personne),
	id_grade integer NOT NULL REFERENCES grade(id_grade),
	date_obtention date NOT NULL DEFAULT current_timestamp,
	CONSTRAINT pk_grade_obtenu PRIMARY KEY (id_personne, id_grade)
);
~~~~
~~~~sql
    CREATE TABLE forum(
	id_message serial NOT NULL PRIMARY KEY,
	id_personne integer NOT NULL REFERENCES profil(id_personne),
	id_lieu integer NOT NULL REFERENCES lieu(id_lieu),
	contenu_msg text NOT NULL,
	date_msg date NOT NULL
);
~~~~
## La Normalisation
