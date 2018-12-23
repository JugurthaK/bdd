# Documentation

Bienvenue sur ce projet de BDD avancée, traitant de la normalisation.
Le but du projet était de produire une base de donnée afin d'aider un groupe de projet tutoré à créer une sorte de Pokémon GO pour touriste. (C'est la raison pour laquelle nous appelerons ce projet PPGO : _Presque Pokémon Go_)
![MCD de notre Base](https://raw.githubusercontent.com/JugurthaK/bdd/master/img/bdd.PNG)

_MCD de notre BDD : **NB** Il manque la table note photo cette dernière est de la même architecture que la table note_

## Initialisation de la BDD

### 1 - Création des Tables

#### Table Profil :

Tous les utilisateurs créés et ayant accès à l'application.

```sql
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
```

![Schéma de Normalisation de la table profil](https://raw.githubusercontent.com/JugurthaK/bdd/master/img/table_profil.png)

#### Table Lieu

Tous les lieux recensés par l'application

```sql
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
```

![Schéma de Normalisation de la table lieu](https://raw.githubusercontent.com/JugurthaK/bdd/master/img/table_lieu.png)

#### Table Validation Lieu

Table permettant de stocker un lieu comme un lieu touristique, et permettant aussi aux personnes ayant déjà visité un lieu de valider la participation de quelqu'un.

```sql
    CREATE TABLE validation_lieu(
    id_lieu serial NOT NULL,
    id_personne_visiteur int NOT NULL REFERENCES profil(id_personne),
    id_personne_verification int NOT NULL REFERENCES profil (id_personne),
    choix_verification int NOT NULL DEFAULT 0, /* Passer à 1 si nbVote > count(id_personne_verification)/2 */
	CONSTRAINT pk_validation_lieu PRIMARY KEY (id_lieu, id_personne_visiteur, id_personne_verification)
);
```

![Schéma de Normalisation de la table validation_lieu](https://raw.githubusercontent.com/JugurthaK/bdd/master/img/table_validation_lieu.png)

#### Table Photo

Table contenant l'ensemble des photos des lieux de l'application, les mieux notées sont utilisées comme illustration du Lieu.

```sql
    CREATE TABLE photo_lieu (
	id_photo serial NOT NULL PRIMARY KEY,
    id_lieu int NOT NULL REFERENCES lieu(id_lieu),
    id_personne int NOT NULL REFERENCES profil(id_personne),
    lien_photo text NOT NULL, /* Photo en base 64 */
    note_photo int NOT NULL
);
```

![Schéma de Normalisation de la table photo](https://raw.githubusercontent.com/JugurthaK/bdd/master/img/table_photo.png)

#### Table note_photo

Permet de recenser toutes les photos notées par les utilisateurs

```sql
    CREATE TABLE note_photo(
	id_personne integer NOT NULL REFERENCES profil(id_personne),
	id_photo integer NOT NULL REFERENCES photo_lieu(id_photo),
	note float,
	CONSTRAINT pk_note_photo PRIMARY KEY (id_personne, id_photo)
);
```

![Schéma de Normalisation de la table note_photo](https://raw.githubusercontent.com/JugurthaK/bdd/master/img/table_note_photo.png)

#### Table note

Permet de recenser les notes donées par les utilisateurs à certains lieux

```sql
    CREATE TABLE note(
	id_personne integer NOT NULL REFERENCES profil(id_personne),
	id_lieu integer NOT NULL REFERENCES profil(id_personne),
	note float,
	CONSTRAINT pk_note PRIMARY KEY (id_personne, id_lieu)
);
```

![Schéma de Normalisation de la table note](https://raw.githubusercontent.com/JugurthaK/bdd/master/img/table_note.png)

#### Table Grade

Permet de stocker tous les grades créés pour l'application.

```sql
    CREATE TABLE grade(
	id_grade serial NOT NULL PRIMARY KEY,
	nom_grade varchar(256) NOT NULL,
	logo_grade text NOT NULL,
	nb_points_necessaires integer NOT NULL,
);
```

![Schéma de Normalisation de la table grade](https://raw.githubusercontent.com/JugurthaK/bdd/master/img/table_grade.png)

#### Table Grade Obtenu

Permet de savoir quelle personne détient quelle grade et depuis combien de temps.

```sql
    CREATE TABLE grade_obtenu(
	id_personne integer NOT NULL REFERENCES profil(id_personne),
	id_grade integer NOT NULL REFERENCES grade(id_grade),
	date_obtention date NOT NULL DEFAULT current_timestamp,
	CONSTRAINT pk_grade_obtenu PRIMARY KEY (id_personne, id_grade)
);
```

![Schéma de Normalisation de la table grade_obtenu](https://raw.githubusercontent.com/JugurthaK/bdd/master/img/table_grade_obtenu.png)

#### Table Forum

Permet de stocker tous les messages postés par la communauté sur un lieu.

```sql
    CREATE TABLE forum(
	id_message serial NOT NULL PRIMARY KEY,
	id_personne integer NOT NULL REFERENCES profil(id_personne),
	id_lieu integer NOT NULL REFERENCES lieu(id_lieu),
	contenu_msg text NOT NULL,
	date_msg date NOT NULL
);
```

![Schéma de Normalisation de la table forum](https://raw.githubusercontent.com/JugurthaK/bdd/master/img/table_forum.png)

### 2 - Création des fonctions et trigger

#### Procédure passage_inactif (@return void)

Cette fonction permet d'aller vérifier la table profil et **modifie tous les attributs compte_actif à 0 pour les personnes ayant une date de dernière connexion supérieure à 1 mois**, et inversement, c'est à dire remettre à 1 l'attribue pour les personnes s'étant connectées il y a un moins d'un mois.

Cette fonction n'est reliée à aucun trigger car elle doit être effectuée de manière récurente _(journalière ?)_ et ne peut donc pas dépendre d'un event sql mais d'une tâche cron.

```sql
    create or replace function passage_inactif() returns void as $$
    declare
        cursUser CURSOR FOR SELECT id_personne, date_derniere_connexion FROM profil;
        id profil.id_personne%TYPE;
        dateDerniereCo profil.date_derniere_connexion%TYPE;

    BEGIN
        OPEN cursUser;
            LOOP
                FETCH cursUser INTO id, dateDerniereCo;
                EXIT WHEN NOT FOUND;
                RAISE INFO 'Interval Retourné : %', age(dateDerniereCo);
                IF age(dateDerniereCo) > '1 mons' THEN
                    UPDATE profil SET compte_actif = 0 WHERE id_personne = id;
                ELSE IF age(dateDerniereCo) < '1 mons' THEN
                    UPDATE profil SET compte_actif = 1 WHERE id_personne = id;
                END IF;
            END IF;
            END LOOP;
        CLOSE cursUser;
    END;
$$ language plpgsql;
```

#### Fonction Compteur_compte_actif (@return int)

Cette fonction permet de **récupérer le nombre de comptes actifs**, elle est imbriquée dans une autre fonction qui sera présentée plus tard.

_Cette fonction n'a pas vraiment lieu d'être algorithmiquement parlant, mais nous n'avions pas fait de BDD depuis longtemps_

```sql
create or replace function compteur_compte_actif() returns integer as $$
    BEGIN
        RETURN (SELECT count(id_personne) FROM profil WHERE compte_actif = 1);
    END;
$$ language plpgsql;
```

#### Fonction verif_lieu (@return trigger)

Cette fonction permet d'aller décompteur le nombre de fois qu'un lieu a été validé par la communauté, si le nombre de validation est supérieur à la moitié du nombe de comptes actifs _(récupéré par la fonction compteur_compte_actif())_ alors l'attribut **verification_lieu** de la table lieu est update à 1.

```sql
create or replace function verif_lieu() returns trigger as $$
    declare
        cursLieu CURSOR FOR SELECT id_lieu, count(id_lieu) FROM validation_lieu WHERE choix_verification = 1 GROUP BY id_lieu;
        id INTEGER;
        nbValidationLieu INTEGER;
        nbUserActif INTEGER;
    BEGIN
        SELECT compteur_compte_actif() INTO nbUserActif;
        OPEN cursLieu;
            LOOP
                FETCH cursLieu INTO id, nbValidationLieu;
                EXIT WHEN NOT FOUND;
                IF nbValidationLieu > (nbUserActif/2) THEN
                    UPDATE lieu SET verification_lieu = 1 WHERE id_lieu = id;
                    RAISE INFO 'LE LIEU % A ETE VALIDE PAR LA COMMUNAUTE', id;
                END IF;
            END LOOP;
        CLOSE cursLieu;
        RETURN NEW;
    END;
$$ language plpgsql;

/* Le Trigger */
CREATE TRIGGER validationLieu
    AFTER UPDATE ON validation_lieu
    FOR EACH ROW
    EXECUTE PROCEDURE verif_lieu();
```

#### Fonction ajoutMembresActifsCreationLieu (@return trigger)

_C'est un peu long comme nom_

Cette fonction, et son trigger permettent directement d'ajouter à la table verification_lieu **l'ensemble des comptes actifs et vérifiés** au moment T pour valider l'existence d'un lieu ou la véracité d'une visite.

```sql
CREATE OR REPLACE FUNCTION ajoutMembresActifsCreationLieu() RETURNS trigger AS $$
    DECLARE
        cursUsers CURSOR FOR SELECT profil.id_personne FROM profil WHERE compte_verifié = 1 AND compte_actif = 1;
        id INTEGER;

    BEGIN
        OPEN cursUsers;
            LOOP
                FETCH cursUsers INTO id;
                EXIT WHEN NOT FOUND;
                    INSERT INTO validation_lieu VALUES (NEW.id_lieu, NEW.id_personne, id);
                    RAISE INFO 'LA PERSONNE ID % A ETE AJOUTEE A LA VERIFICATION DU LIEU %', id, NEW.id_lieu;
            END LOOP;
        CLOSE cursUsers;

    RETURN NEW;
    END;
$$ language plpgsql;

/* Le Trigger */
CREATE TRIGGER ajoutMembreActifs
    AFTER INSERT ON lieu
    FOR EACH ROW
    EXECUTE PROCEDURE ajoutMembresActifsCreationLieu();
```

#### Fonction Update Grade (@return trigger)

Cette fonction permet

```sql
CREATE OR REPLACE FUNCTION updateGrade() RETURNS trigger as $$
    DECLARE
        cursGrade CURSOR FOR SELECT grade.nb_points_necessaires, grade.id_grade FROM grade GROUP BY grade.id_grade;
        gradePoints int;
        gradeId int;
        userNbPoints int;
    BEGIN
        OPEN cursGrade;
            LOOP
                FETCH cursGrade INTO gradePoints, gradeId;
                EXIT WHEN NOT FOUND;
                    SELECT nombre_points FROM profil WHERE id_personne = NEW.id_personne INTO userNbPoints;
                    IF userNbPoints >= gradePoints THEN
                        INSERT INTO grade_obtenu VALUES (NEW.id_personne, gradeId, now());
                        RAISE INFO 'USER % UNLOCKED GRADE %', NEW.id_personne, gradeId;
                    END IF;
            END LOOP;
        CLOSE cursGrade;
    RETURN NEW;
END;
$$ language plpgsql;

/* Le trigger */
CREATE TRIGGER gradeUpdate
    AFTER UPDATE OF nombre_points ON profil
    FOR EACH ROW
    EXECUTE PROCEDURE updateGrade();
```

#### Fonction moyenne_lieu

Cette fonction se charge d'aller dans la table note, et de faire une moyenne de toutes les notes d'un lieu puis d'en modifier l'attribut dans la table lieu.

```sql
CREATE OR REPLACE FUNCTION moyenne_note() RETURNS TRIGGER as $$
    DECLARE
    idLieu int;
    moyenneLieu float;

    BEGIN
    SELECT avg(note) FROM note WHERE id_lieu = NEW.id_lieu INTO moyenneLieu;
    UPDATE lieu SET note_lieu = moyenneLieu;
    RAISE INFO 'LA MOYENNE DU LIEU ID % EST DESORMAIS %', NEW.id_lieu, moyenneLieu;
    RETURN NEW;
END;
$$ language plpgsql;

/* Le trigger*/

CREATE TRIGGER noteUpdate
    AFTER INSERT ON note
    FOR EACH ROW
    EXECUTE PROCEDURE moyenne_note();
```

#### Fonction moyenne_photo

Même fonction qu'au dessus, cette fois-ci pour les photos.

```sql
CREATE OR REPLACE FUNCTION moyenne_note_photo() RETURNS TRIGGER as $$
    DECLARE
    idPhoto int;
    moyennePhoto float;

    BEGIN
    SELECT avg(note) FROM note_photo WHERE id_photo = NEW.id_photo INTO moyennePhoto;
    UPDATE photo_lieu SET note_photo = moyennePhoto;
    RAISE INFO 'PHOTO ID % MOYENNE : %', NEW.id_photo, moyennePhoto;
    RETURN NEW;
END;
$$ language plpgsql;

/* Le trigger */

CREATE TRIGGER notePhotoUpdate
    AFTER INSERT ON note_photo
    FOR EACH ROW
    EXECUTE PROCEDURE moyenne_note_photo();
```

### 3 - Jeu de données pour les essais

#### Parce qu'il faut bien des utilisateurs ...

```sql
INSERT INTO profil(mot_de_passe, pseudo, email, nom_personne, prenom_personne, date_naissance,
avatar, distance_parcourue, nombre_points, compte_verifié, compte_actif, date_derniere_connexion) VALUES
('123', 'JugurthaK', 'aaa@aaa.com', 'Kabeche', 'Jugurtha', '03-01-1996', 'aaa', '123', '123', '1', '1', '2018-11-20';

INSERT INTO profil(mot_de_passe, pseudo, email, nom_personne, prenom_personne, date_naissance,
avatar, distance_parcourue, nombre_points, compte_verifié, compte_actif, date_derniere_connexion) VALUES
('124', 'Maumau', 'aaa@aaa.com', 'Duhamel', 'Maureen', '05-05-1999', 'aaa', '123', '123', '1', '1', now());

INSERT INTO profil(mot_de_passe, pseudo, email, nom_personne, prenom_personne, date_naissance,
avatar, distance_parcourue, nombre_points, compte_verifié, compte_actif, date_derniere_connexion) VALUES
('125', 'Sywave', 'aaa@aaa.com', 'Synave', 'Rémi', '26-11-1982', 'aaa', '123', '123', '1', '0', now());
```

Tous les utilisateurs sont créés à la date du jour, si on execute la procédure

```sql
SELECT passage_inactif();
```

Seul Jugurtha passe en compte inactif car sa date de dernière connexion est supérieure à 1 mois.

#### Et il faut bien des lieux

```sql
INSERT INTO lieu(id_personne, nom_lieu, positionX, positionY, nom_rue, nom_ville, code_postal, note_lieu, photo_lieu, description_lieu, nb_point) VALUES
(1, 'Test', 1.20, 1.20, 'Test', 'Calais', '62000', 12, 'N/A', 'Description Test', 100);
INSERT INTO lieu(id_personne, nom_lieu, positionX, positionY, nom_rue, nom_ville, code_postal, note_lieu, photo_lieu, description_lieu, nb_point) VALUES
(1, 'Tour Eiffel', 1.20, 1.20, 'Champs de Mars', 'Paris', '75000', 15, 'N/A', 'La Eour Tiffel', 100);
INSERT INTO lieu(id_personne, nom_lieu, positionX, positionY, nom_rue, nom_ville, code_postal, note_lieu, photo_lieu, description_lieu, nb_point) VALUES
(1, 'Arc de Triomphe', 1.20, 1.20, 'Av', 'Paris', '75008', 14, 'N/A', 'Trc de Ariomphe', 100);
```

Lors de l'insertion de ces 3 lieux, il y a logiquement un RAISE INFO qui affiche des données de la façon suivante :

    INFO:  LA PERSONNE ID 2 A ETE AJOUTEE A LA VERIFICATION DU LIEU 1
    INFO:  LA PERSONNE ID 3 A ETE AJOUTEE A LA VERIFICATION DU LIEU 1
    INFO:  LA PERSONNE ID 1 A ETE AJOUTEE A LA VERIFICATION DU LIEU 1

#### Et faut quand même faire en sorte de pouvoir valider les lieux

```sql
UPDATE validation_lieu SET choix_verification = 1 WHERE id_personne_verification = 2 AND id_lieu = 1;
UPDATE validation_lieu SET choix_verification = 1 WHERE id_personne_verification = 3 AND id_lieu = 1;
```

Et normalement, on obtient ça :

    INFO:  LE LIEU 1 A ETE VALIDE PAR LA COMMUNAUTE

#### Et la gamification ?

```sql
INSERT INTO grade(nom_grade, logo_grade, nb_points_necessaires) VALUES ('Me Larcheur', 'N\A', 100);
```

Et pour activer le trigger :

```sql
UPDATE profil SET nombre_points = 200 WHERE id_personne = 1;
```

Logiquement, le terminal retourne :

    INFO: USER 1 UNLOCKED GRADE 1

#### Maintenant il faut bien trier les lieux

Il est préférable de mettre les lignes 1 à 1 pour voir la moyenne ce mettre à jour.

```sql
INSERT INTO note VALUES(1, 1, 15);
INSERT INTO note VALUES(2, 1, 14);
INSERT INTO note VALUES(3, 1, 7);
```

Exemple d'output :

    INSERT INTO note VALUES(1, 1, 15);
    INFO: LA MOYENNE DE 1 EST DESORMAIS 15
    INSERT INTO note VALUES(2, 1, 14);
    INFO: LA MOYENNE DE 1 EST DESORMAIS 14.5
    INSERT INTO note VALUES(3, 1, 7);
    INFO: LA MOYENNE DE 1 EST DESORMAIS 12

#### Et on refait la même avec les photos :

```sql
INSERT INTO photo_lieu(id_lieu, id_personne, lien_photo, note_photo) VALUES (1, 1, 'N/A', 0);
```

```sql
INSERT INTO note_photo VALUES (1, 1, 15);
INSERT INTO note_photo VALUES (2, 1, 7);
```

#### Et pour finir, on fait communiquer tout ça

```sql
INSERT INTO forum(id_personne, id_lieu,contenu_msg, date_msg) VALUES (1, 1, 'Salut à tous les amis', now());
```

## La Normalisation

Pour notre base de données, nous avons pu la mettre sous forme de 3ème forme normale, c’est-à-dire qu’on l’a passée d’abord en 1ère forme normale afin que tous les attributs de chaque relation de la base de données aient **une valeur atomique et constante dans le temps**, sachant qu’ils ne peuvent désigner une donnée composée.
Puis on l’a passée en 2ème forme normale pour avoir des relations en 1ère forme normale dont **chaque attribut non-clé dépend totalement et non partiellement de la clé primaire**.
Enfin, nous avons mis notre base de données à la 3ème forme normale, qui vise à éliminer les redondances. Ainsi, les relations de notre base de données sont en 2ème forme normale et **tout attribut non-clé de ces relations ne peuvent dépendre d’un attribut non-clé**.

_Les schémas de normalisation sont disponibles en dessous des tables_
