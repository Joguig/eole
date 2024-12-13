#!/bin/bash
echo "Debut $0"

[ ! -d /usr/share/ead2/backend/tmp/importation ] && mkdir /usr/share/ead2/backend/tmp/importation 

echo "Copie des fichiers a importer"
cp "$VM_DIR_EOLE_CI_TEST/dataset/scribe/sconet_anonyme/ElevesSansAdresses.xml" /usr/share/ead2/backend/tmp/importation/
cp "$VM_DIR_EOLE_CI_TEST/dataset/scribe/sconet_anonyme/Structures.xml" /usr/share/ead2/backend/tmp/importation/
cp "$VM_DIR_EOLE_CI_TEST/dataset/scribe/sconet_anonyme/ResponsablesAvecAdresses.xml" /usr/share/ead2/backend/tmp/importation/
cp "$VM_DIR_EOLE_CI_TEST/dataset/scribe/sconet_anonyme/Nomenclature.xml" /usr/share/ead2/backend/tmp/importation/

echo "Definition des preférences"
cat >/usr/share/ead2/backend/tmp/importation/eleve.pref <<EOF
domaine##restreint
quota##50
login##standard
gen_pwd##alea
change_pwd##oui
shell##non
profil##1
EOF

cat >/usr/share/ead2/backend/tmp/importation/responsable.pref <<EOF
login##standard
gen_pwd##alea
mail##perso_restreint
EOF

cat >/usr/share/ead2/backend/tmp/importation/ead-importation.json <<EOF
{
  "structure": "/usr/share/ead2/backend/tmp/importation/Structures.xml",
  "responsable": "/usr/share/ead2/backend/tmp/importation/ResponsablesAvecAdresses.xml",
  "nomenclature": "/usr/share/ead2/backend/tmp/importation/Nomenclature.xml",
  "eleve": "/usr/share/ead2/backend/tmp/importation/ElevesSansAdresses.xml"
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

echo "Importation des comptes ELEVE"
/usr/share/ead2/backend/bin/importation.py --import --type=annuel eleve
result=$?  
echo "importation.py = $result"
ciCheckExitCode "$result"

end_time=$(date +%s)
# elapsed time with second resolution
elapsed=$(( end_time - start_time ))
eval "echo Temps importation : $(date -ud "@$elapsed" +'%H hr %M min %S sec')"
