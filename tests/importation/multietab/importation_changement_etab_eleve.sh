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
cat >/usr/share/ead2/backend/tmp/importation/eleve.pref <<EOF
domaine##restreint
quota##50
login##standard
gen_pwd##alea
change_pwd##non
profil##1
shell##non
etab##$ETAB
etab_prefix##$ETAB_PREFIX
EOF

echo "* cat /usr/share/ead2/backend/tmp/importation/eleve.pref"
cat /usr/share/ead2/backend/tmp/importation/eleve.pref
   
echo "Génération des fichiers a importer"
# suppression login + mot de pass + ajout etab devant chaque id + ecrase date de naissance
# le numéro de "numero" ne doit pas changer pour qu'il considère qu'il y a un changement d'établissement
DATE="0101${ANNEE}"

# noter que le numero n'a pas d'ETAB !
cat >"/usr/share/ead2/backend/tmp/importation/TestEleveMultiEtab.csv" <<EOF
numero;nom;prenom;sexe;date;classe;niveau;login;password;options
1;Eleve1;changementetab;M;$DATE;c31;3eme;elevechangementetab;Eole12345!;
EOF

echo "* cat /usr/share/ead2/backend/tmp/importation/TestEleveMultiEtab.csv" 
cat "/usr/share/ead2/backend/tmp/importation/TestEleveMultiEtab.csv"

cat >/usr/share/ead2/backend/tmp/importation/ead-importation.json <<EOF
{
  "eleve": "/usr/share/ead2/backend/tmp/importation/TestEleveMultiEtab.csv"
}
EOF

if [ ! -f /tmp/liste_avant.txt ]
then
    find /home >/tmp/liste_avant.txt
fi

echo "Importation des fichiers"
[[ -f /var/lib/eole/reports/importation.txt ]] && rm /var/lib/eole/reports/importation.txt 

/usr/share/ead2/backend/bin/importation.py --parse=csv2 /usr/share/ead2/backend/tmp/importation/ead-importation.json
result=$?  
ciCheckExitCode "$result" "chargement fichier"

ciAfficheContenuFichier /var/lib/eole/reports/importation.txt

echo "Importation des comptes ELEVE"
echo "Importation mode : $TYPE_IMPORT"
/usr/share/ead2/backend/bin/importation.py --import --type="$TYPE_IMPORT" eleve_ss_resp
result=$?  
ciCheckExitCode "$result" "importation"

