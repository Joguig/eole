#!/bin/bash
echo "Debut $0"

[ ! -d /usr/share/ead2/backend/tmp/importation ] && mkdir /usr/share/ead2/backend/tmp/importation 

echo "Copie des fichiers a importer"
cp "$VM_DIR_EOLE_CI_TEST/dataset/scribe/sconet_anonyme/sts_emp_0210050R_2009.xml" /usr/share/ead2/backend/tmp/importation/

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

cat >/usr/share/ead2/backend/tmp/importation/administratif.pref <<EOF
quota##0
login##standard
gen_pwd##alea
change_pwd##non
shell##oui
profil##1
mail##perso_aucune
EOF

cat >/usr/share/ead2/backend/tmp/importation/ead-importation.json <<EOF
{
  "enseignant": "/usr/share/ead2/backend/tmp/importation/sts_emp_0210050R_2009.xml"
}
EOF

if [ ! -f /tmp/liste_avant.txt ]
then
    find /home >/tmp/liste_avant.txt
fi

start_time=$(date +%s)

echo "Importation des fichiers"
[[ -f /var/lib/eole/reports/importation.txt ]] && rm /var/lib/eole/reports/importation.txt 

/usr/share/ead2/backend/bin/importation.py --parse=sconet /usr/share/ead2/backend/tmp/importation/ead-importation.json
result=$?
echo "importation.py = $result"
ciCheckExitCode "$result"

ciAfficheContenuFichier /var/lib/eole/reports/importation.txt

echo "Importation des comptes PROFESSEURS"
/usr/share/ead2/backend/bin/importation.py --import --type=annuel enseignant
result=$?  
echo "importation.py = $result"
ciCheckExitCode "$result"

end_time=$(date +%s)
# elapsed time with second resolution
elapsed=$(( end_time - start_time ))
eval "echo Temps importation : $(date -ud "@$elapsed" +'%H hr %M min %S sec')"
