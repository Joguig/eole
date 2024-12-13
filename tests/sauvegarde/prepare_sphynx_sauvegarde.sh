#!/bin/bash

BCK_BASENAME=$(date +"%d-%m-%Y")
export BCK_BASENAME

/bin/cp -f /mnt/eole-ci-tests/configuration/aca.sphynx/sphynxdb.sqlite /var/lib/arv/db/
ciCheckExitCode $?

ciMonitor reconfigure
ciCheckExitCode $?

ciRunPython arv_apply_conf_ipsec.py
ciCheckExitCode $?

ipsec statusall | grep -q "Sphynx-Amon_1-t1"
ciCheckExitCode $?

ciMonitor sauvegarde
ciCheckExitCode $?

FICHIER=/var/lib/sphynx_backups/${BCK_BASENAME}.tar.gz
ciPrintDebug "Sauvegarde $FICHIER"
ciGetDirSauvegarde
[ ! -d "$DIR_SAUVEGARDE/sauvegardeSh/" ] && mkdir -p "$DIR_SAUVEGARDE/sauvegardeSh/"
[ -f "$DIR_SAUVEGARDE/sauvegardeSh/${BCK_BASENAME}.tar.gz" ] && rm -f "$DIR_SAUVEGARDE/sauvegardeSh/${BCK_BASENAME}.tar.gz"
cp "$FICHIER" "$DIR_SAUVEGARDE/sauvegardeSh/"
ciCheckExitCode $?

ls -l "$DIR_SAUVEGARDE/sauvegardeSh/"
# suppression des fichiers de plus de 10 jours !
find "$DIR_SAUVEGARDE/sauvegardeSh/" -name '*.gz' -ctime +10 -delete

exit 0