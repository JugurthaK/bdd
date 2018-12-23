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
/* Fin de la Fonction Passage_Inactif()*/
/* Cette fonction doit être utilisée avec CRON ou un autre ordonnanceur */
create or replace function compteur_compte_actif() returns integer as $$
    BEGIN
        RETURN (SELECT count(id_personne) FROM profil WHERE compte_actif = 1);
    END;
$$ language plpgsql;
/* Fin de la fonction Compteur_compte_actif() */

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

CREATE TRIGGER validationLieu
    AFTER UPDATE ON validation_lieu
    FOR EACH ROW
    EXECUTE PROCEDURE verif_lieu();


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

CREATE TRIGGER ajoutMembreActifs
    AFTER INSERT ON lieu
    FOR EACH ROW
    EXECUTE PROCEDURE ajoutMembresActifsCreationLieu();


CREATE OR REPLACE FUNCTION updateGrade() RETURNS trigger as $$
    DECLARE
        cursUsers CURSOR FOR SELECT profil.nombre_points, profil.id_personne FROM profil GROUP BY profil.id_personne;
        cursGrade CURSOR FOR SELECT grade.nb_points_necessaires, grade.id_grade FROM grade GROUP BY grade.id_grade;
        userNbPoints int;
        userId int;
        gradePoints int;
        gradeId int;
    BEGIN
    OPEN cursUsers;
        LOOP
            FETCH cursUsers INTO userNbPoints, userId;
            EXIT WHEN NOT FOUND;
                OPEN cursGrade;
                    LOOP
                        FETCH cursGrade INTO gradePoints, gradeId;
                        EXIT WHEN NOT FOUND;
                        IF userNbPoints >= gradePoints THEN
                            INSERT INTO grade_obtenu VALUES (userId, gradeId, now());
                            RAISE INFO 'USER % UNLOCKED GRADE %', userId, gradeId;
                        END IF;
                    END LOOP;
                CLOSE cursGrade;
        END LOOP;
    CLOSE cursUsers;
    RETURN NEW;
END;
$$ language plpgsql; 

CREATE TRIGGER gradeUpdate
    AFTER UPDATE ON profil
    FOR EACH ROW
    EXECUTE PROCEDURE updateGrade();

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

CREATE TRIGGER noteUpdate
    AFTER INSERT ON note
    FOR EACH ROW
    EXECUTE PROCEDURE moyenne_note();

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

CREATE TRIGGER notePhotoUpdate
    AFTER INSERT ON note_photo
    FOR EACH ROW
    EXECUTE PROCEDURE moyenne_note_photo();