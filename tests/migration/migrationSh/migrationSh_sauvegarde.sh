#!/bin/bash
# shellcheck disable=SC2035

DESTINATION="${1:-26}"
SCRIPT="migration${DESTINATION}.sh"

USER="3a.01"
echo "Modification du mot de passe pour $USER"
if [ -x /usr/sbin/changepasswordeole.pl ]
then
    /usr/sbin/changepasswordeole.pl "$USER" "Eole54321!"
else
    echo "Eole54321!" | CreoleRun "smbldap-passwd -p $USER" fichier
fi

ciGetDirSauvegarde
[ ! -d "$DIR_SAUVEGARDE/migrationSh/" ] && mkdir -p "$DIR_SAUVEGARDE/migrationSh/"

cd /root || exit 1
/bin/rm -f "$SCRIPT"
wget "ftp://eoleng.ac-dijon.fr/pub/Outils/migration/$SCRIPT"
ciCheckExitCode $?

#Chemin :
#Voulez-vous sauvegarder automatiquement les données et les ACL

# la presence de ce fichier ==>
bash -x "$SCRIPT" <<EOF
/mnt/sauvegardes
oui
EOF
ciCheckExitCode $?

/bin/rm -f sauvegarde.tar.gz
ls -l /mnt/sauvegardes
tar cvf sauvegarde.tar.gz /mnt/sauvegardes
cp -vf sauvegarde.tar.gz "$DIR_SAUVEGARDE/migrationSh/sauvegarde-$DESTINATION.tar.gz"
ciCheckExitCode $?

ls -l "$DIR_SAUVEGARDE/migrationSh/"
# suppression des fichiers de plus de 10 jours !
find "$DIR_SAUVEGARDE/migrationSh/" -name '*.gz' -ctime +10 -delete
exit 0
