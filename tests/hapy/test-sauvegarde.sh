#!/bin/bash

ciPrintMsgMachine "* Sauvegarde BD"
sauvegarde.sh

# shellcheck disable=SC2086,SC2010
BCK_BASENAME=$(ls -t "/var/lib/hapy_backups/" | grep .tar.gz | head --lines=1 )
BCK_BASENAME=$(basename "$BCK_BASENAME" .tar.gz)
echo "$BCK_BASENAME"

ciPrintMsgMachine "* Contenu Tar BD..."
tar tvf "/var/lib/hapy_backups/$BCK_BASENAME.tar.gz"

CONFIGURATION=default ciGetDirSauvegarde
ciPrintMsgMachine "* Copie sauvegardes BD..."
mkdir -p "$DIR_SAUVEGARDE/sauvegardeSh"
cp -vf "/var/lib/hapy_backups/${BCK_BASENAME}.tar.gz" "$DIR_SAUVEGARDE/sauvegardeSh/${BCK_BASENAME}.tar.gz"

ciPrintMsgMachine "* Requete vmpool sur one.db exporté..."
tar -C /tmp -xvf "$DIR_SAUVEGARDE/sauvegardeSh/${BCK_BASENAME}.tar.gz"

ciPrintMsgMachine "* grep vm_pool"
grep vm_pool "/tmp/${BCK_BASENAME}/one.db"

ciPrintMsgMachine "* recreation bd depuis sauvegarde"
# attention : le one.db de la sauvegarde est un dump
sqlite3 /tmp/one.db <"/tmp/${BCK_BASENAME}/one.db" 
echo $?

ciPrintMsgMachine "* requete test sur bd depuis sauvegarde"
sqlite3 /tmp/one.db <<EOF
select OID,NAME from vm_pool;
EOF
echo $?
