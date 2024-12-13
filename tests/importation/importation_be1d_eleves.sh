#!/bin/bash
echo "Debut $0"

[ ! -d /usr/share/ead2/backend/tmp/importation ] && mkdir /usr/share/ead2/backend/tmp/importation

FICHIER="$VM_DIR_EOLE_CI_TEST/dataset/scribe/be1d/eleves.csv"

echo "Copie des fichiers a importer"
cp "$FICHIER" "/usr/share/ead2/backend/tmp/importation/Test Eléve.csv"

echo "Definition des preférences"
cat >/usr/share/ead2/backend/tmp/importation/eleve.pref <<EOF
domaine##restreint
quota##50
login##standard
gen_pwd##alea
change_pwd##non
profil##1
shell##non
EOF

cat >/usr/share/ead2/backend/tmp/importation/ead-importation.json <<EOF
{
  "eleve": "/usr/share/ead2/backend/tmp/importation/Test Eléve.csv"
}
EOF

if [ ! -f /tmp/liste_avant.txt ]
then
    find /home >/tmp/liste_avant.txt
fi

echo "Importation des fichiers"
[[ -f /var/lib/eole/reports/importation.txt ]] && rm /var/lib/eole/reports/importation.txt

/usr/share/ead2/backend/bin/importation.py --parse=be1d /usr/share/ead2/backend/tmp/importation/ead-importation.json
result=$?
echo "importation.py = $result"
ciCheckExitCode "$result"

ciAfficheContenuFichier /var/lib/eole/reports/importation.txt

echo "Importation des comptes ELEVE"
/usr/share/ead2/backend/bin/importation.py --import --type=maj eleve_ss_resp
result=$?
echo "importation.py = $result"
ciCheckExitCode "$result"

