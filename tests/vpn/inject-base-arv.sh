#!/bin/bash

ciGetDirConfiguration
ls -l "$DIR_CONFIGURATION/var/lib/arv/db" 
if [ ! -f "$DIR_CONFIGURATION/var/lib/arv/db/sphynxdb.sqlite" ]
then
    ciPrintErreurAndExit "manque $DIR_CONFIGURATION/var/lib/arv/db/sphynxdb.sqlite dans la configuration Git eole-ci-tests"

fi

echo "inject base arv"
cp "$DIR_CONFIGURATION/var/lib/arv/db/sphynxdb.sqlite" /var/lib/arv/db/sphynxdb.sqlite

echo "Listes des id_zephir connue"
ls -d "$VM_DIR_OUTPUT/"*/idzephir | while read FICHIER ;
do
    IDZEPHIR=$(cat "$FICHIER")
    D=$(dirname "$FICHIER")
    ls -l "$D"
    if  [ ! -f "$D/env" ]
    then
        echo "$FICHIER dans $D : manque 'env' !"
        continue
    fi  
    if  [ ! -f "$D/configurationZephir" ]
    then  
        echo "$FICHIER dans $D : manque 'configurationZephir' !"
        continue
    fi
    (
        VAR=$(grep VM_MACHINE= <"$D/env")
        eval "$VAR" 
        VAR=$(grep VM_VERSIONMAJEUR= <"$D/env")
        eval "$VAR" 
        CONFIGURATION=$(cat "$D/configurationZephir")
        NAME="${VM_MACHINE}-${CONFIGURATION}-${VM_VERSIONMAJEUR}"
        sqlite3 /var/lib/arv/db/sphynxdb.sqlite "UPDATE arv_db_node_node SET id_zephir=${IDZEPHIR} WHERE name='${NAME}'"
        echo $?
    )
done
sqlite3 /var/lib/arv/db/sphynxdb.sqlite "SELECT name, id_zephir FROM arv_db_node_node"
      
echo "redémarre ARV"
service arv restart

exit 0