#!/bin/bash +x
echo "Debut $0"

IsLink(){
  if [ -L "$1" ]
  then
    echo "OK: le lien '$1' existe"
  else
    echo "EOLE_CI_ALERTE: le lien '$1' n'existe pas"
    RESULTAT=1
  fi
}

IsNotLink(){
  if [ ! -L "$1" ]
  then
    echo "OK: le lien '$1' n'existe pas"
  else
    echo "EOLE_CI_ALERTE: le lien '$1' existe"
    RESULTAT=1
  fi
}

export RESULTAT="0"
[ ! -d /usr/share/ead2/backend/tmp/importation ] && mkdir /usr/share/ead2/backend/tmp/importation
CSVFNAME="/usr/share/ead2/backend/tmp/importation/ftp.csv"

# élèves : 4 cas
# 1. changement de classe et d'options
# 2. changement de classe et perte d'option
# 3. même classe et changement d'options
# 4. même classe et perte d'option

echo "Création fichier a importer élèves 1"
cat >$CSVFNAME <<EOF
numero;nom;prenom;sexe;date;classe;niveau;options;
771;Ftp1;Eleve;M;01/02/2003;4a;4g;opt41
772;Ftp2;Eleve;M;02/02/2003;4a;4g;opt41
773;Ftp3;Eleve;M;03/02/2003;4a;4g;opt41
774;Ftp4;Eleve;M;04/02/2003;4a;4g;opt41
EOF

cat >/usr/share/ead2/backend/tmp/importation/ead-importation.json <<EOF
{
  "eleve": "$CSVFNAME"
}
EOF

echo "Importation du fichier élèves 1"
/usr/share/ead2/backend/bin/importation.py --parse=csv2 /usr/share/ead2/backend/tmp/importation/ead-importation.json
result=$?
echo "importation.py = $result"
echo

echo "Importation des comptes élèves 1"
/usr/share/ead2/backend/bin/importation.py --import --type=annuel eleve_ss_resp
result=$?
echo "importation.py = $result"
echo

echo "Création fichier a importer élèves 2"
cat >$CSVFNAME <<EOF
numero;nom;prenom;sexe;date;classe;niveau;options;
771;Ftp1;Eleve;M;01/02/2003;4b;4g;opt42
772;Ftp2;Eleve;M;02/02/2003;4b;4g;
773;Ftp3;Eleve;M;03/02/2003;4a;4g;opt42
774;Ftp4;Eleve;M;04/02/2003;4a;4g;
EOF

cat >/usr/share/ead2/backend/tmp/importation/ead-importation.json <<EOF
{
  "eleve": "$CSVFNAME"
}
EOF

echo "Importation du fichier élèves 2"
/usr/share/ead2/backend/bin/importation.py --parse=csv2 /usr/share/ead2/backend/tmp/importation/ead-importation.json
result=$?
echo "importation.py = $result"
echo

echo "Importation des comptes élèves 2"
/usr/share/ead2/backend/bin/importation.py --import --type=annuel eleve_ss_resp
result=$?
echo "importation.py = $result"
echo

# nouvelles classes
IsLink /home/e/eleve.ftp1/.ftp/4b
IsLink /home/e/eleve.ftp2/.ftp/4b

# nouvelles options
IsLink /home/e/eleve.ftp1/.ftp/opt42
IsLink /home/e/eleve.ftp3/.ftp/opt42

# anciennes classes
IsNotLink /home/e/eleve.ftp1/.ftp/4a
IsNotLink /home/e/eleve.ftp2/.ftp/4a

# anciennes options
IsNotLink /home/e/eleve.ftp1/.ftp/opt41
IsNotLink /home/e/eleve.ftp2/.ftp/opt41
IsNotLink /home/e/eleve.ftp3/.ftp/opt41
IsNotLink /home/e/eleve.ftp4/.ftp/opt41

echo
echo "*********************************"
echo

# enseignants : 4 cas
# 1. modification d'équipes pédagogiques
# 2. perte d'équipe pédagogique

echo "Création fichier a importer enseignants 1"
cat >$CSVFNAME <<EOF
numero;nom;prenom;sexe;date;classes;options;
881;Ftp1;Prof;M;01/01/1983;4a;;
882;Ftp2;Prof;M;02/01/1983;4a;;
EOF

cat >/usr/share/ead2/backend/tmp/importation/ead-importation.json <<EOF
{
  "enseignant": "$CSVFNAME"
}
EOF

echo "Importation du fichier enseignants 1"
/usr/share/ead2/backend/bin/importation.py --parse=csv2 /usr/share/ead2/backend/tmp/importation/ead-importation.json
result=$?
echo "importation.py = $result"
echo

echo "Importation des comptes enseignants 1"
/usr/share/ead2/backend/bin/importation.py --import --type=annuel enseignant
result=$?
echo "importation.py = $result"
echo

echo "Création fichier a importer enseignants 2"
cat >$CSVFNAME <<EOF
numero;nom;prenom;sexe;date;classes;options;
881;Ftp1;Prof;M;01/01/1983;4b;;
882;Ftp2;Prof;M;02/01/1983;;;
EOF

cat >/usr/share/ead2/backend/tmp/importation/ead-importation.json <<EOF
{
  "enseignant": "$CSVFNAME"
}
EOF

echo "Importation du fichier enseignants 2"
/usr/share/ead2/backend/bin/importation.py --parse=csv2 /usr/share/ead2/backend/tmp/importation/ead-importation.json
result=$?
echo "importation.py = $result"
echo

echo "Importation des comptes enseignants 2"
/usr/share/ead2/backend/bin/importation.py --import --type=annuel enseignant
result=$?
echo "importation.py = $result"
echo

# nouvelles équipes
IsLink /home/p/prof.ftp1/.ftp/profs-4b

# anciennes équipes
IsNotLink /home/p/prof.ftp1/.ftp/profs-4a
IsNotLink /home/p/prof.ftp2/.ftp/profs-4a

echo
echo "*********************************"
echo

echo "FIN $0 : resultat=$RESULTAT"
#exit $RESULTAT
exit 0
