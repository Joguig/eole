#!/bin/bash
# shellcheck disable=SC2035

ciMonitor sauvegarde
ciCheckExitCode $?

ciPrintDebug "Sauvegarde $FICHIER"
ciGetDirSauvegarde
[ ! -d "$DIR_SAUVEGARDE/sauvegardeSh/" ] && mkdir -p "$DIR_SAUVEGARDE/sauvegardeSh/"

cd /var/lib/zephir_backups/ || exit 1
ls -l 
cp -vf *.tar.gz "$DIR_SAUVEGARDE/sauvegardeSh/"
ciCheckExitCode $?

ls -l "$DIR_SAUVEGARDE/sauvegardeSh/"
# suppression des fichiers de plus de 10 jours !
find "$DIR_SAUVEGARDE/sauvegardeSh/" -name '*.gz' -ctime +10 -delete
exit 0