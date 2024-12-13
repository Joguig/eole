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

    ciPrintMsgMachine "* reconfigure"
    ciMonitor reconfigure
fi

TAG=$(CreoleGet one_backup_tag)

mkdir -p /mnt/sauvegardes

if [ -d /mnt/sauvegardes/one ]
then
    /bin/rm -rf /mnt/sauvegardes/one
fi

OWNER=oneadmin
HOMEDIR=$(getent passwd "$OWNER" | cut -d ':' -f 6)
ONE_AUTH="${HOMEDIR}/.one/one_auth"
export ONE_AUTH

UBUNTU_RELEASE="16.04"
VM_NAME="ubuntu${UBUNTU_RELEASE}-vm"

ciPrintMsgMachine "* 1er backup... "
cat >/tmp/update_vm.tmpl <<EOF
NAME = "$NAME"
LABELS = "$TAG"
EOF
onevm update "${VM_NAME}" /tmp/update_vm.tmpl
checkExitCode "$?" "onevm update"

#Usage: onebck [options]
#    -C, --config-file file           Configuration file
#    -c, --creds file                 Crediential file
#    -e, --end-point url              End point URL
#    -d, --backup-directory dir       Backup directory
#    -T, --backup-tag tag             Tag who marks vm for backup (ex: Backup)
#    -t, --timeout timeout            Timeout for opennebula connection
#    -u, --backup-unused              Backup images not used by any VM
#    -w, --wait timeout               Wait for action ends
#    -h, --help                       Displays Help
ciMonitor onebck --backup-tag "$TAG"

ls -l /mnt/sauvegardes/ 
if [ -d /mnt/sauvegardes/one ]
then
    du -h /mnt/sauvegardes/
else
    ciSignalAlerte "Sauvegarde NOK"
fi

ciPrintMsgMachine "* 2nd backup"
cat >/tmp/update_vm.tmpl <<EOF
NAME = "$NAME"
LABELS = "pas-de-backup"
EOF
onevm update "${VM_NAME}" /tmp/update_vm.tmpl
checkExitCode "$?" "onevm update"

CONFIGURATION=default ciGetDirSauvegarde
ciPrintMsgMachine "Copie sauvegardes..."
/bin/mkdir -p "$DIR_SAUVEGARDE/mnt/sauvegardes"
/bin/rm -rf "$DIR_SAUVEGARDE/mnt/sauvegardes/one" 2>/dev/null
if [ -d /mnt/sauvegardes/one ]
then
    /bin/cp -rvf /mnt/sauvegardes/one "$DIR_SAUVEGARDE/mnt/sauvegardes/"
else
    ciSignalAlerte "Sauvegarde /mnt/sauvegardes/one NOK"
fi


echo "* cat /var/log/rsyslog/local/OneBackup/OneBackup.info.log"
cat /var/log/rsyslog/local/OneBackup/OneBackup.info.log 
