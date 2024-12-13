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

[ ! -d /var/lib/sphynx_backups ] && mkdir -p /var/lib/sphynx_backups

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
FICHIER="$DIR_SAUVEGARDE/sauvegardeSh/${BCK_BASENAME}.tar.gz"
echo "Date sauvegarde            : $BCK_BASENAME"
echo "Fichier sauvegarde utilisé : $FICHIER"

/bin/cp "$FICHIER" /var/lib/sphynx_backups/  
RESULT="$?" 
if [ "$RESULT" -ne 0 ]
then
    echo "Restauration => $RESULT : le fichier '$FICHIER' n'est pas présent !"
    exit 1    
fi

echo "************************************************************"
echo "* Restauration $BCK_BASENAME"
echo "************************************************************"
ciMonitor restauration "$BCK_BASENAME"
ciCheckExitCode $?

echo "************************************************************"
echo "* Migration configuration"
echo "************************************************************"
ciRunPython mise_a_jour_config_apres_migration.py
ciCheckExitCode $?

echo "******* Check Proxy ***********"
ciSetHttpProxy

ciMonitor instance
ciCheckExitCode $?

ciDiagnose
ciCheckExitCode $?

ipsec statusall | grep -q "Sphynx-Amon_1-t1"
ciCheckExitCode $?

exit 0