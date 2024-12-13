#!/bin/bash

function checkExitCode()
{
    if [[ "$1" -eq 0 ]]
    then
        return 0
    fi

    if [[ -n "$2" ]]
    then
        echo "CheckExitCode $1 ! ($2)"
    else
        echo "CheckExitCode $1"
    fi
    exit "$1"
}

function OneWait()
{
    local ONE_COMMANDE="one${1}"
    local ID_OU_NAME="${2}"
    local STATE_OK="${3}"
    SECONDS=0
    OK=1
    while (( SECONDS < 500 ));
    do
        if ! "${ONE_COMMANDE}" show "${ID_OU_NAME}" >/tmp/onewait 2>&1
        then
            CDU="$?"
            if [[ "err" == "${STATE_OK}" ]]
            then
                # dans ce cas, c'est normal
                OK=0
            else 
                echo "erreur ${ONE_COMMANDE} ==> $CDU"
                cat /tmp/onewait
                OK=2
            fi
            break
        fi
        imgState=$(${ONE_COMMANDE} show "${ID_OU_NAME}" | awk '{if ($1 == "STATE") {print $3}}')
        if [[ "${imgState}" == "${STATE_OK}" ]]
        then
            echo "Ok: l'${1} est ${imgState}"
            OK=0
            break
        fi
        echo "wait ${1} '${2}' for '${3}' : current is '${imgState}' seconds=$SECONDS"
        sleep 5
    done
    return $OK
}

OWNER=oneadmin
HOMEDIR=$(getent passwd "$OWNER" | cut -d ':' -f 6)
ONE_AUTH="${HOMEDIR}/.one/one_auth"
export ONE_AUTH

UBUNTU_RELEASE="16.04"
VM_NAME="ubuntu${UBUNTU_RELEASE}-vm"

echo "* je m'assure que la VM est supprimé $VM_NAME (BD+Images)"
onevm recover "$VM_NAME" --delete
OneWait vm "$VM_NAME" "err"

echo "* onevm list (doit être vide)"
onevm list 

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

if ! command -v onerst 
then
    ciPrintMsgMachine "* install eole-one-backup"
    ciAptEole eole-one-backup

    ciPrintMsgMachine "* activer_one_backup=oui"
    CreoleSet activer_one_backup oui

    CreoleGet one_backup_dir
    CreoleGet one_backup_tagged
    CreoleGet one_backup_tag
    CreoleGet one_backup_unused

    ciPrintMsgMachine "* reconfigure apres install eole-one-backup"
    ciMonitor reconfigure
fi

ciPrintMsgMachine "* --------------------------------"
ciPrintMsgMachine "* Restauration BASE ONE"
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

# le reconfigure a été fait

ciPrintMsgMachine "* diff /etc/eole/config.eol.bak /etc/eole/config.eol"
ciPrintMsgMachine "* --------------------------------"
python3 "$VM_DIR_EOLE_CI_TEST/scripts/formatConfigEol1.py" </etc/eole/config.eol.bak >/tmp/config.eol.bak
python3 "$VM_DIR_EOLE_CI_TEST/scripts/formatConfigEol1.py" </etc/eole/config.eol >/tmp/config.eol
if diff /tmp/config.eol.bak /tmp/config.eol
then
    echo "/etc/eole/config.eol non modifié"
else
    echo "/etc/eole/config.eol modifié"
fi

ciPrintMsgMachine "* reconfigure apres restauration BD"
ciMonitor reconfigure

ciPrintMsgMachine "* Restauration BASE ONE OK"
ciPrintMsgMachine "* --------------------------------"

ciPrintMsgMachine "* Restauration VMS"
mkdir -p /mnt/sauvegardes
mkdir -p /var/tmp/sauvegardes
/bin/cp -urvf "$DIR_SAUVEGARDE/mnt/sauvegardes/one" /var/tmp/sauvegardes/ 
if [ ! -d /var/tmp/sauvegardes/one ]
then
    echo "pas de sauvergarde dans /var/tmp/sauvegardes/one !"
    exit 1
fi

ciPrintMsgMachine "* ls -l /var/tmp/sauvegardes/one"
ls -l /var/tmp/sauvegardes/one

ciPrintMsgMachine "* cat /etc/one/onebck.conf"
cat /etc/one/onebck.conf

echo "* test restauration $VM_NAME"
#Usage: onerst [options]
#    -C, --config-file file           Configuration file
#    -c, --creds file                 Crediential file
#    -e, --end-point url              End point URL
#    -d, --backup-directory dir       Backup directory
#    -T, --backup-tag tag             Tag who marks vm for backup (ex: Backup)
#    -t, --timeout timeout            Timeout for opennebula connection
#    -u, --backup-unused              Backup images not used by any VM
#    -m, --machines vmid              VM ID list (one or more ',' separated)
#    -w, --wait timeout               Wait for action ends
#    -h, --help                       Displays Help
ciMonitor onerst --config-file /etc/one/onebck.conf --backup-directory /var/tmp/sauvegardes

echo "* cat /var/log/rsyslog/local/OneRestore/OneRestore.info.log"
cat /var/log/rsyslog/local/OneRestore/OneRestore.info.log 

echo "* onevm list"
onevm list 
checkExitCode "$?" "onevm list"

echo "* onevm show $VM_NAME"
onevm show "$VM_NAME"

# les VM doivent être en POWEROFF
OneWait vm "$VM_NAME" "POWEROFF"


