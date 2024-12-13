#!/bin/bash
echo "Debut $0"

NO="${1}"
TYPE_IMPORT="$2"
if [ -z "$1$2" ] 
then
    echo "Usage : $0 <no> <annuel|maj>"
    exit 1
fi

ETAB="$(printf '%07d' "${NO}" )E"
echo "ETAB=$ETAB"
ETAB_PREFIX="ETB${NO}-"
echo "ETAB_PREFIX=$ETAB_PREFIX"
# etab -> anneé = 2000 + no étab !
ANNEE="$(printf '2%03d' "${NO}" )"
echo "ANNEE=$ANNEE"

if [ -z "$TYPE_IMPORT" ] 
then
    TYPE_IMPORT="annuel"
fi

[ ! -d /usr/share/ead2/backend/tmp/importation ] && mkdir /usr/share/ead2/backend/tmp/importation 

echo "Definition des preférences"
cat >/usr/share/ead2/backend/tmp/importation/enseignant.pref <<EOF
quota##0
login##standard
gen_pwd##alea
change_pwd##non
shell##oui
profil##4
mail##perso_internet
etab##$ETAB
etab_prefix##$ETAB_PREFIX
EOF

echo "* cat /usr/share/ead2/backend/tmp/importation/enseignant.pref"
cat /usr/share/ead2/backend/tmp/importation/enseignant.pref
   
echo "Génération des fichiers a importer"
# suppression login + mot de pass + ajout etab devant chaque id + ecrase date de naissance
# le numéro de "numero" ne doit pas changer pour qu'il considère qu'il y a un changement d'établissement
DATE="0101${ANNEE}"

awk -v ETAB="$ETAB_PREFIX" -v DATE="$DATE" -F';' '!/numero/ { print ETAB$1";"$2";"$3";"$4";"DATE";"$8";"$9";" ; } /numero/ { print $1";"$2";"$3";"$4";"$5";"$8";"$9";" ; }'  <"$VM_DIR_EOLE_CI_TEST/dataset/scribe/csv/Test Prof.csv" >"/usr/share/ead2/backend/tmp/importation/TestProfMultiEtab.csv"
   
echo "* cat /usr/share/ead2/backend/tmp/importation/TestProfMultiEtab.csv" 
cat "/usr/share/ead2/backend/tmp/importation/TestProfMultiEtab.csv"

cat >/usr/share/ead2/backend/tmp/importation/ead-importation.json <<EOF
{
  "enseignant": "/usr/share/ead2/backend/tmp/importation/TestProfMultiEtab.csv"
}
EOF

if [ ! -f /tmp/liste_avant.txt ]
then
    find /home >/tmp/liste_avant.txt
fi

start_time=$(date +%s)

echo "Importation des fichiers"
[[ -f /var/lib/eole/reports/importation.txt ]] && rm /var/lib/eole/reports/importation.txt 

/usr/share/ead2/backend/bin/importation.py --parse=csv2 /usr/share/ead2/backend/tmp/importation/ead-importation.json
result=$?  
ciCheckExitCode "$result" "chargement fichier"

ciAfficheContenuFichier /var/lib/eole/reports/importation.txt

echo "Importation des comptes PROFESSEURS"
echo "Importation mode : $TYPE_IMPORT"
/usr/share/ead2/backend/bin/importation.py --import --type="$TYPE_IMPORT" enseignant
result=$?  
ciCheckExitCode "$result" "importation"

end_time=$(date +%s)
# elapsed time with second resolution
elapsed=$(( end_time - start_time ))
eval "echo Temps importation professeurs : $(date -ud "@$elapsed" +'%H hr %M min %S sec')"
