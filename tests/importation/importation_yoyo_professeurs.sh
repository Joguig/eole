#!/bin/bash +x
echo "Debut $0"

[ ! -d /usr/share/ead2/backend/tmp/importation ] && mkdir /usr/share/ead2/backend/tmp/importation 

echo "Copie des fichiers a importer"
cp "$VM_DIR_EOLE_CI_TEST/dataset/scribe/csv/Test Prof.csv" /usr/share/ead2/backend/tmp/importation/TestProf.csv

echo "Definition des preférences"
cat >/usr/share/ead2/backend/tmp/importation/enseignant.pref <<EOF
quota##0
login##standard
gen_pwd##alea
change_pwd##non
shell##oui
profil##4
mail##perso_internet
EOF

cat >/usr/share/ead2/backend/tmp/importation/ead-importation.json <<EOF
{
  "enseignant": "/usr/share/ead2/backend/tmp/importation/TestProf.csv"
}
EOF

find /home >/tmp/liste_avant.txt

start_time=$(date +%s)

echo "Importation des fichiers"
[[ -f /var/lib/eole/reports/importation.txt ]] && rm /var/lib/eole/reports/importation.txt 

/usr/share/ead2/backend/bin/importation.py --parse=csv2 /usr/share/ead2/backend/tmp/importation/ead-importation.json
result=$?  
echo "importation.py = $result"

ciAfficheContenuFichier /var/lib/eole/reports/importation.txt

echo "Importation des comptes PROFESSEURS"
/usr/share/ead2/backend/bin/importation.py --import --type=maj enseignant
result=$?  
echo "importation.py = $result"

end_time=$(date +%s)
# elapsed time with second resolution
elapsed=$(( end_time - start_time ))
eval "echo Temps importation : $(date -ud "@$elapsed" +'%H hr %M min %S sec')"
