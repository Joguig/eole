#!/bin/bash

if [ -z "$1" ] 
then
    VERSIONMAJEUR_ORIGINE=$VM_VERSIONMAJEUR
else
    VERSIONMAJEUR_ORIGINE="$1"
    if [ -n "$2" ] 
    then
        BCK_BASENAME="$2"
    fi
fi

echo "Restauration depuis la sauvegarde $VERSIONMAJEUR_ORIGINE !"
VM_VERSIONMAJEUR=$VERSIONMAJEUR_ORIGINE ciGetDirSauvegarde
if [ ! -d "$DIR_SAUVEGARDE/sauvegardeSh/" ]
then
    echo "* Restauration : la sauvegarde n'a pas été faite dans la version $VERSIONMAJEUR_ORIGINE !"
    exit 1    
fi

if [ -z "$BCK_BASENAME" ] 
then
    # shellcheck disable=SC2010
    BCK_BASENAME=$(ls -t "$DIR_SAUVEGARDE/sauvegardeSh/" | grep .tar.gz | head --lines=1 )
    BCK_BASENAME=$(basename "$BCK_BASENAME" .tar.gz)
fi
ciPrintMsgMachine "* Récupération Tar BD..."
FICHIER="$DIR_SAUVEGARDE/sauvegardeSh/${BCK_BASENAME}.tar.gz"
echo "Date sauvegarde            : $BCK_BASENAME"
echo "Fichier sauvegarde utilisé : $FICHIER"

mkdir -p "/var/lib/hapy_backups"
cp "$FICHIER" "/var/lib/hapy_backups/$BCK_BASENAME.tar.gz"
tar tvf "/var/lib/hapy_backups/$BCK_BASENAME.tar.gz"

ciPrintMsgMachine "* restauration BD !."
bash restauration.sh <<EOF
$BCK_BASENAME
oui
EOF

ciPrintMsgMachine "* Requete vmpool sur one.db restauré dans /var/lib/one/one.db ..."
sqlite3 /var/lib/one/one.db <<EOF
select OID,NAME from vm_pool;
EOF
echo $?