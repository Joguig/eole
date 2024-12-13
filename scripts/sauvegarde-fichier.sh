#!/bin/bash

function sauvegardeFichier()
{
    if [ -L "${1}" ]
    then
        if [ -f "${1}" ]
        then
            if ! /bin/cp "${1}" "$DESTINATION/${1}" 2>/dev/null
            then
                echo "sauvegardeFichier: Erreur '$1' cas 1 lien !"
            fi
        else
            echo "sauvegardeFichier: $1 est un dossier lien symbolique"
        fi
        return
    fi

    if [ -d "${1}" ]
    then
        if ! /bin/cp -rf "${1}" "$DESTINATION" 2>/dev/null
        then
            echo "sauvegardeFichier: Erreur '$1' cas 2 dir !"
        fi
    else
        if [ -f "${1}" ]
        then
            if ! /bin/cp -f "${1}" "$DESTINATION" 2>/dev/null
            then
                echo "sauvegardeFichier: Erreur '$1' cas 3 fichier !"
            fi
        fi
    fi
    
    for conteneur in $LIST_CONTENEUR
    do
        if [ ! -d "$DESTINATION/${conteneur}/" ] 
        then 
            mkdir -p "$DESTINATION/${conteneur}/"
        fi
        fInLxc="/var/lib/lxc/${conteneur}/rootfs${1}"
        if [ -f "${fInLxc}" ] 
        then
            if ! /bin/cp -rf "${fInLxc}" "$DESTINATION/${conteneur}/" 2>/dev/null
            then
                echo "sauvegardeFichier: Erreur '${fInLxc}' cas 4 !"
            fi
        fi
    done
}


# shellcheck disable=SC1091,SC1090
source /root/getVMContext.sh NO_DISPLAY

DESTINATION=/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/
if [ ! -d "$DESTINATION" ] 
then 
    mkdir -p "$DESTINATION"
fi

if command -v lxc-ls >/dev/null
then
    LIST_CONTENEUR="$(lxc-ls 2>/dev/null)"
    for conteneur in $LIST_CONTENEUR
    do
        if [ ! -d "$DESTINATION" ] 
        then 
            mkdir -p "$DESTINATION/${conteneur}/"
        fi
    done
fi

echo "Sauvegarde des logs suite a erreur dans '$1' pour la VM '$VM_ID' "
case "$1" in
    apt-eole)
        sauvegardeFichier /var/log/rsyslog/local/creoled/creoled.info.log
        sauvegardeFichier /var/log/apt/term.log
        sauvegardeFichier /var/log/creoled.log
        ;;
    gen_conteneur)
        sauvegardeFichier /var/log/isolation.log
        sauvegardeFichier /var/log/lxc/reseau.log
        sauvegardeFichier /var/log/lxc/bdd.log
        sauvegardeFichier /var/log/lxc/internet.log
        sauvegardeFichier /var/log/lxc/partage.log
        sauvegardeFichier /var/log/apt/term.log
        ;;

    upgrade_auto)
        sauvegardeFichier /var/log/creoled.log
        sauvegardeFichier /var/log/apt/term.log
        sauvegardeFichier /var/log/upgrade-auto.log
        cp -rf /tmp/Upgrade-Auto* "$DESTINATION"
        cp -rf /var/log/dist-upgrade "$DESTINATION"
        ;;

    instance)
        [ -d /var/log/lxc/ ] && cp -rf /var/log/lxc/  "$DESTINATION"
        sauvegardeFichier /var/log/ltsp_build_client.log
        sauvegardeFichier /var/log/rsyslog/local/creoled/creoled.info.log
        sauvegardeFichier /var/log/apt/term.log
        sauvegardeFichier /var/log/ltsp_build_client-fat_amd64.log
        sauvegardeFichier /var/log/creoled.log
        sauvegardeFichier /opt/fog_installer/installer.log
        cp -f /var/log/hapy-deploy*.log "$DESTINATION" 2>/dev/null
        ;;
        
    reconfigure)
        sauvegardeFichier /var/log/reconfigure.log
        ;;

    maj_auto)
        sauvegardeFichier /etc/network/interfaces
        sauvegardeFichier /etc/resolv.conf
        sauvegardeFichier /var/log/apt/term.log
        sauvegardeFichier /var/log/creoled.log
        ;;
        
    enregistrement_zephir)
        ;;
        
    diagnose)
        sauvegardeFichier /var/log/rsyslog/local/creoled/creoled.info.log
        sauvegardeFichier /var/log/creoled.log
        ;;

    *)
        ;;
esac
sauvegardeFichier /var/log/eole-ci-tests.log
sauvegardeFichier /var/log/EoleCiTestsContext.log
sauvegardeFichier /var/log/EoleCiTestsDaemon.log
[ -f /var/log/upstart/EoleCiTestsContext.log ] && cp /var/log/upstart/EoleCiTestsContext.log "$DESTINATION"/EoleCiTestsContextUpstart.log
[ -f /var/log/upstart/EoleCiTestsDaemon.log ] && cp /var/log/upstart/EoleCiTestsDaemon.log "$DESTINATION"/EoleCiTestsDaemonUpstart.log
ps xawf -eo pid,user='---User---',cgroup='----------CGroup------------',args > "$VM_DIR/ps-axwf-apres_erreur.log"

if command -v journalctl >/dev/null 2>&1
then
    journalctl --no-pager >"$VM_DIR/systemd-journalctl-complet.log"
    journalctl --no-pager -xe >"$VM_DIR/systemd-journalctl-xe.log"
    grep " creoled" <"$VM_DIR/systemd-journalctl-xe.log" | grep -i 'Impossible de charger ' >/tmp/grep_creoled_erreur
    if [ -s /tmp/grep_creoled_erreur ]
    then
        echo "************************************************************************"    
        echo "Grep 'creole' + 'Impossible de charger' $VM_DIR/systemd-journalctl-xe.log"
        cat /tmp/grep_creoled_erreur
        echo "************************************************************************"    
    fi 
    
    if [ -n "$DAILY_DATE" ]
    then
		ciPrintMsgMachine "Export journalctl entre Daily - maintenant (moins polution salt)"
    	journalctl --no-pager --since "$DAILY_DATE" | grep -v "The Salt Master has cached the public key for this node, this salt minion will wait for 10 seconds" >"$VM_DIR/systemd-journalctl-apres-daily.log"
	fi
    
fi

# dans monitor_eole-ci, en cas d'erreur nous créons le gen_rpt 
cp /tmp/*.tar.gz "$DESTINATION" >/dev/null 2>&1
