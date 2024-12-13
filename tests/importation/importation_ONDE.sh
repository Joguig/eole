#!/bin/bash

echo "Debut $0"
[ ! -d /usr/share/ead2/backend/tmp/importation ] && mkdir /usr/share/ead2/backend/tmp/importation
CSV_ELEVES="/usr/share/ead2/backend/tmp/importation/eleves.csv"
CSV_RESPONSABLES="/usr/share/ead2/backend/tmp/importation/responsables.csv"

echo "Création fichier élèves"
cat >$CSV_ELEVES <<EOF
Nom élève;Nom d'usage élève;Prénom élève;Date naissance;Sexe;INE;Adresse1;Cp1;Commune1;Pays1;Adresse2;Cp2;Commune2;Pays2; Cycle;Niveau;Libellé classe;Identifiant classe;Attestation fournie;Autorisation associations;Autorisation photo;Décision de passage
MARTIN;;Martin;01/01/2001;M;1111111111A;1 rue de Test;21000;Dijon;FRANCE;;;;;CYCLE II;CE2;Classe de M Machin;99999;Non;Non;Non;
MARTIN;;Martine;01/01/2001;M;1111111112A;1 rue de Test;21000;Dijon;FRANCE;;;;;CYCLE II;CE1;Classe de M Truc;99998;Non;Non;Non;
EOF

echo "Création fichier responsables"
cat >$CSV_RESPONSABLES <<EOF
Civilité Responsable;Nom usage responsable;Nom responsable;Prénom responsable;Adresse responsable;CP responsable;Commune responsable;Pays;Courriel;Téléphone domicile;Téléphone travail;Téléphone portable;Nom d'usage enfant;Nom de famille enfant;Prénom enfant;Classes enfants;Nom d'usage enfant;Nom de famille enfant;Prénom enfant;Classes enfants;Nom d'usage enfant;Nom de famille enfant;Prénom enfant;Classes enfants
M.;;MARTIN;Jean;1 rue de Test;21000;Dijon;FRANCE;;;;;;MARTIN;Martin;CLASSE  CE2;;MARTIN;Martine;CLASSE  CE1;;;
MME;;MARTINE;Jeanne;1 rue de Test;21000;Dijon;FRANCE;;;;;;MARTIN;Martin;CLASSE  CE2;;;;;;;
MME;;MARTINO;Janine;2 rue de Test;21000;Dijon;FRANCE;;;;;;MARTIN;Martine;CLASSE  CE1;;;;;;;
EOF

cat >/usr/share/ead2/backend/tmp/importation/ead-importation.json <<EOF
{
  "eleve": "$CSV_ELEVES",
  "responsable": "$CSV_RESPONSABLES"
}
EOF

echo "Lecture des fichiers ONDE"
/usr/share/ead2/backend/bin/importation.py --parse=be1d /usr/share/ead2/backend/tmp/importation/ead-importation.json
result=$?
echo "importation.py = $result"
echo

echo "Traitement des données"
/usr/share/ead2/backend/bin/importation.py --import --type=annuel eleve
result=$?
echo "importation.py = $result"
echo

echo
login='martin.martin'
echo "Test de $login"
echo "* vérification de la classe"
[[ $(ldapsearch -x uid=$login Divcod | grep ^Divcod) == "Divcod: classedemmachin" ]] && echo OK || echo "EOLE_CI_ALERTE: classe invalide"
echo "* vérification des responsables"
if ciVersionMajeurAPartirDe "2.8."
then
    [[ $(python3 -c "from scribe import responsables;r = responsables.Responsable();r.ldap_admin.connect();print(r._get_responsables(eleve='$login') == ['jean.martin', 'jeanne.martine'])") == 'True' ]] && echo OK || echo "EOLE_CI_ALERTE: responsables invalides"
else
    [[ $(python -c "from scribe import responsables;r = responsables.Responsable();r.ldap_admin.connect();print r._get_responsables(eleve='$login') == ['jean.martin', 'jeanne.martine']") == 'True' ]] && echo OK || echo "EOLE_CI_ALERTE: responsables invalides"
fi

echo
login='martine.martin'
echo "Test de $login"
echo "* vérification de la classe"
[[ $(ldapsearch -x uid=$login Divcod | grep ^Divcod) == "Divcod: classedemtruc" ]] && echo OK || echo "EOLE_CI_ALERTE: classe invalide"
echo "* vérification des responsables"
if ciVersionMajeurAPartirDe "2.8."
then
    [[ $(python3 -c "from scribe import responsables;r = responsables.Responsable();r.ldap_admin.connect();print(r._get_responsables(eleve='$login') == ['jean.martin', 'janine.martino'])") == 'True' ]] && echo OK || echo "EOLE_CI_ALERTE: responsables invalides"
else
    [[ $(python -c "from scribe import responsables;r = responsables.Responsable();r.ldap_admin.connect();print r._get_responsables(eleve='$login') == ['jean.martin', 'janine.martino']") == 'True' ]] && echo OK || echo "EOLE_CI_ALERTE: responsables invalides"
fi

echo
echo "*********************************"
echo

echo "FIN $0"
exit 0
