/* Profil */
INSERT INTO profil(mot_de_passe, pseudo, email, nom_personne, prenom_personne, date_naissance, 
avatar, distance_parcourue, nombre_points, compte_verifié, compte_actif, date_derniere_connexion) VALUES 
('123', 'JugurthaK', 'aaa@aaa.com', 'Kabeche', 'Jugurtha', '03-01-1996', 'aaa', '123', '123', '1', '1', now());

INSERT INTO profil(mot_de_passe, pseudo, email, nom_personne, prenom_personne, date_naissance, 
avatar, distance_parcourue, nombre_points, compte_verifié, compte_actif, date_derniere_connexion) VALUES 
('124', 'Maumau', 'aaa@aaa.com', 'Duhamel', 'Maureen', '05-05-1999', 'aaa', '123', '123', '1', '1', now());

INSERT INTO profil(mot_de_passe, pseudo, email, nom_personne, prenom_personne, date_naissance, 
avatar, distance_parcourue, nombre_points, compte_verifié, compte_actif, date_derniere_connexion) VALUES 
('125', 'Sywave', 'aaa@aaa.com', 'Synave', 'Rémi', '26-11-1982', 'aaa', '123', '123', '1', '0', now());

/* Lieux */
INSERT INTO lieu(id_personne, nom_lieu, positionX, positionY, nom_rue, nom_ville, code_postal, note_lieu, photo_lieu, description_lieu, nb_point) VALUES
(1, 'Test', 1.20, 1.20, 'Test', 'Calais', '62000', 12, 'N/A', 'Description Test', 100);
INSERT INTO lieu(id_personne, nom_lieu, positionX, positionY, nom_rue, nom_ville, code_postal, note_lieu, photo_lieu, description_lieu, nb_point) VALUES
(1, 'Tour Eiffel', 1.20, 1.20, 'Champs de Mars', 'Paris', '75000', 15, 'N/A', 'La Eour Tiffel', 100);
INSERT INTO lieu(id_personne, nom_lieu, positionX, positionY, nom_rue, nom_ville, code_postal, note_lieu, photo_lieu, description_lieu, nb_point) VALUES
(1, 'Arc de Triomphe', 1.20, 1.20, 'Av', 'Paris', '75008', 14, 'N/A', 'Trc de Ariomphe', 100);

/* A faire pour tester les lieux */
UPDATE validation_lieu SET choix_verification = 1 WHERE id_personne_verification = 2 AND id_lieu = 1;
UPDATE validation_lieu SET choix_verification = 1 WHERE id_personne_verification = 3 AND id_lieu = 1;

/* Grade */
INSERT INTO grade(nom_grade, logo_grade, nb_points_necessaires) VALUES ('Me Larcheur', 'N\A', 100);

/* Pour activer le Trigger Grade */
UPDATE profil SET nombre_points = 200 WHERE id_personne = 1; 

/* Pour activer le trigger note */
INSERT INTO note VALUES(1, 1, 15);
INSERT INTO note VALUES(2, 1, 14);
INSERT INTO note VALUES(3, 1, 7);

/* Photos */
INSERT INTO photo_lieu(id_lieu, id_personne, lien_photo, note_photo) VALUES (1, 1, 'N/A', 0);

/* Pour activer le trigger de moyenne */
INSERT INTO note_photo VALUES (1, 1, 15);
INSERT INTO note_photo VALUES (2, 1, 7);

/* Forum */
INSERT INTO forum(id_personne, id_lieu,contenu_msg, date_msg) VALUES (1, 1, 'Salut à tous les amis', now());
