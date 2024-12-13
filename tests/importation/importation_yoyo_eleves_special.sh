#!/bin/bash
echo "Debut $0"

[ ! -d /usr/share/ead2/backend/tmp/importation ] && mkdir /usr/share/ead2/backend/tmp/importation 

ICI=$(dirname "$0")
FICHIER_SOURCE="$VM_DIR_EOLE_CI_TEST/dataset/scribe/csv/Test Eleve.csv"
case "$1" in
    mac)
        FICHIER="/tmp/Test Eleve_mac_bom.csv"
        "$ICI/create_mac_bom.sh" "$FICHIER_SOURCE" "$FICHIER"
        ;;
    win)
        FICHIER="/tmp/Test Eleve_win_bom.csv"
        "$ICI/create_windows_bom.sh" "$FICHIER_SOURCE" "$FICHIER"
        ;;
    *)
        exit 1
        ;;
esac

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

find /home >/tmp/liste_avant.txt

echo "Importation des fichiers"
[[ -f /var/lib/eole/reports/importation.txt ]] && rm /var/lib/eole/reports/importation.txt 

/usr/share/ead2/backend/bin/importation.py --parse=csv2 /usr/share/ead2/backend/tmp/importation/ead-importation.json 2>/tmp/import.log
result=$?

sed s'/Traceback/Backtrace/' /tmp/import.log

echo "importation.py = $result"
if [ $result -ne 2 ]
then
    ciPrintMsgMachine "ERREUR code retour obtenu $result (attendu $PARSING)"
fi

# test d'erreur : inutile de continuer
exit 0
