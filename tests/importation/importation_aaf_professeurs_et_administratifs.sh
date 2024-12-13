#!/bin/bash
echo "Debut $0"

[ ! -d /usr/share/ead2/backend/tmp/importation ] && mkdir /usr/share/ead2/backend/tmp/importation 

echo "Copie des fichiers a importer"
cp "$VM_DIR_EOLE_CI_TEST/dataset/AAF-VE1901/complet/EnvOLE_ENT2DVA_0940072T_Complet_20180830_PersEducNat_0000.xml" /usr/share/ead2/backend/tmp/importation/PersEducNat.xml

echo "Definition des preférences"
cat >/usr/share/ead2/backend/tmp/importation/enseignant.pref <<EOF
quota##0
login##standard
gen_pwd##alea
change_pwd##non
shell##oui
mail##internet
EOF

cat >/usr/share/ead2/backend/tmp/importation/administratif.pref <<EOF
quota##0
login##standard
gen_pwd##alea
change_pwd##non
shell##oui
mail##perso_aucune
EOF

cat >/usr/share/ead2/backend/tmp/importation/ead-importation.json <<EOF
{
  "enseignant": "/usr/share/ead2/backend/tmp/importation/PersEducNat.xml"
}
EOF

find /home >/tmp/liste_avant.txt

start_time=$(date +%s)

echo "Importation des fichiers"
/usr/share/ead2/backend/bin/importation.py --parse=aaf /usr/share/ead2/backend/tmp/importation/ead-importation.json
result=$?
echo "importation.py = $result"
ciCheckExitCode "$result"

ciAfficheContenuFichier /var/lib/eole/reports/importation.txt

echo "Importation des comptes PROFESSEURS"
/usr/share/ead2/backend/bin/importation.py --import --type=annuel enseignant
result=$?  
echo "importation.py = $result"
ciCheckExitCode "$result"

# ATTENTION CE SONT DE VRAI DONNEES
# PAS DE SORTIE AVEC LES COMPTES
end_time=$(date +%s)
# elapsed time with second resolution
elapsed=$(( end_time - start_time ))
eval "echo Temps importation : $(date -ud "@$elapsed" +'%H hr %M min %S sec')"
