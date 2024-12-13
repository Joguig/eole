#!/bin/bash
echo "Debut $0"

[ ! -d /usr/share/ead2/backend/tmp/importation ] && mkdir /usr/share/ead2/backend/tmp/importation 

echo "Copie des fichiers a importer"
#cp "$VM_DIR_EOLE_CI_TEST/dataset/AAF-VE1901/complet/EnvOLE_ENT2DVA_0940072T_Complet_20180830_Eleve_0000.xml" /usr/share/ead2/backend/tmp/importation/Eleve.xml
#cp "$VM_DIR_EOLE_CI_TEST/dataset/AAF-VE1901/complet/EnvOLE_ENT2DVA_0940072T_Complet_20180830_PersRelEleve_0000.xml" /usr/share/ead2/backend/tmp/importation/PersRelEleve.xml
tar -C /usr/share/ead2/backend/tmp/importation -xf "$VM_DIR_EOLE_CI_TEST/dataset/aaf/anon-complet.tgz"

echo "Definition des preférences"
cat >/usr/share/ead2/backend/tmp/importation/eleve.pref <<EOF
domaine##restreint
quota##50
login##standard
gen_pwd##alea
change_pwd##oui
shell##non
EOF

cat >/usr/share/ead2/backend/tmp/importation/responsable.pref <<EOF
login##standard
gen_pwd##alea
mail##internet
EOF

cat >/usr/share/ead2/backend/tmp/importation/ead-importation.json <<EOF
{
  "responsable": "/usr/share/ead2/backend/tmp/importation/anon-complet/FULL_ENTTSSERVICES_Complet_20130117_PersRelEleve_0000.xml",
  "eleve": "/usr/share/ead2/backend/tmp/importation/anon-complet/FULL_ENTTSSERVICES_Complet_20130117_Eleve_0000.xml"
}
EOF

start_time=$(date +%s)

echo "Importation des fichiers"
/usr/share/ead2/backend/bin/importation.py --parse=aaf /usr/share/ead2/backend/tmp/importation/ead-importation.json
result=$?  
echo "importation.py = $result"
ciCheckExitCode "$result"

ciAfficheContenuFichier /var/lib/eole/reports/importation.txt

echo "Importation des comptes ELEVE"
/usr/share/ead2/backend/bin/importation.py --import --type=annuel eleve
result=$?  
echo "importation.py = $result"
ciCheckExitCode "$result"

# ATTENTION CE SONT DE VRAI DONNEES
# PAS DE SORTIE AVEC LES COMPTES

end_time=$(date +%s)
# elapsed time with second resolution
elapsed=$(( end_time - start_time ))
eval "echo Temps importation : $(date -ud "@$elapsed" +'%H hr %M min %S sec')"
