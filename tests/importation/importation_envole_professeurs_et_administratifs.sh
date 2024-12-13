#!/bin/bash
echo "Debut $0"

[ ! -d /usr/share/ead2/backend/tmp/importation ] && mkdir /usr/share/ead2/backend/tmp/importation 

echo "Copie des fichiers a importer"
cp "$VM_DIR_EOLE_CI_TEST/dataset/envole/professeurs.csv" /usr/share/ead2/backend/tmp/importation/
cp "$VM_DIR_EOLE_CI_TEST/dataset/envole/agents.csv" /usr/share/ead2/backend/tmp/importation/

echo "Definition des preférences"
cat >/usr/share/ead2/backend/tmp/importation/enseignant.pref <<EOF
quota##0
login##standard
gen_pwd##alea
change_pwd##oui
shell##oui
profil##4
mail##perso_internet
EOF

cat >/usr/share/ead2/backend/tmp/importation/administratif.pref <<EOF
quota##0
login##standard
gen_pwd##alea
change_pwd##oui
shell##oui
profil##1
mail##perso_internet
EOF

cat >/usr/share/ead2/backend/tmp/importation/ead-importation.json <<EOF
{
  "enseignant": "/usr/share/ead2/backend/tmp/importation/professeurs.csv",
  "administratif": "/usr/share/ead2/backend/tmp/importation/agents.csv"
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
echo "importation.py = $result"
ciCheckExitCode "$result"

ciAfficheContenuFichier /var/lib/eole/reports/importation.txt

echo "Importation des comptes PROFESSEURS"
/usr/share/ead2/backend/bin/importation.py --import --type=annuel enseignant
result=$?  
echo "importation.py = $result"
ciCheckExitCode "$result"

echo "Inject PROFPO comme PrintOperators"
if [ "$VM_MACHINE" == "etb3.amonecole" ] && ciVersionMajeurAPartirDe "2.8." 
then
    ciSignalAttention "pas de test mail sur ETB3"
    ssh addc smbldap-groupmod -m profpo PrintOperators
    result=$?  
else
    CreoleRun 'smbldap-groupmod -m profpo PrintOperators' partage
    result=$?  
fi
echo "smbldap-groupmod = $result"
ciCheckExitCode "$result"


end_time=$(date +%s)
# elapsed time with second resolution
elapsed=$(( end_time - start_time ))
eval "echo Temps importation : $(date -ud "@$elapsed" +'%H hr %M min %S sec')"
