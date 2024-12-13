#!/bin/bash

#

NB_OK_ATTENDU=$1
NB_BVFS_ATTENDU=$(( NB_OK_ATTENDU*2/3 ))
if [ -z "$2" ]
then
    MODE=LOCAL
else
    MODE="$2"
fi

BAREOS_RESULT="0"

activer_bareos_dir=$(CreoleGet activer_bareos_dir)
echo "* activer_bareos_dir=$activer_bareos_dir"

activer_bareos_sd=$(CreoleGet activer_bareos_sd)
echo "* activer_bareos_sd=$activer_bareos_sd"

bareos_compression=$(CreoleGet bareos_compression)
echo "* bareos_compression=$bareos_compression"

eole_module="$(CreoleGet eole_module)"
echo "* eole_module=$eole_module"

if [ "$activer_bareos_sd" = "non" ]
then
    echo "* Activation bareos_sd + reconfigure"    
    CreoleSet activer_bareos_sd oui
    if ciVersionMajeurAvant "2.7.0"
    then
        CreoleSet bareos_sd_local oui
    else
        CreoleSet bareos_dir_use_local_sd oui
    fi
    ciMonitor reconfigure
    ciCheckExitCode $?
fi

if ciVersionMajeurAvant "2.6.0"
then
    BAREOS_DIR_LOG=bareos-dir.err.log
else
    BAREOS_DIR_LOG=bareos-dir.info.log
fi

[ -d /home/a ] && echo >/home/a/toto1.txt

# ne sera pas créer lors du 1er appel !
if [ ! -d /home/backup ]
then
    echo "* mkdir /home/backup !!"
    mkdir /home/backup
fi 
if [ ! -f /home/backup/toto1.txt ]
then
    echo "* création /home/backup/toto1.txt !!"
    echo >/home/backup/toto1.txt
fi

if [[ "$VM_MODULE" == "scribe" ]] || [[ "$VM_MODULE" == "amonecole" ]]
then
    if ciVersionMajeurAPartirDe "2.7."
    then
        # shellcheck disable=SC1091
        . /var/lib/lxc/addc/rootfs/etc/eole/samba4-vars.conf
        if [ -d "/var/lib/lxc/addc/rootfs/home/sysvol/${AD_REALM}/scripts/groups" ]
        then
            echo "* Inject test.txt dans SYSVOL"
            printf 'lecteur,T:,\\scribe\test' >"/var/lib/lxc/addc/rootfs/home/sysvol/${AD_REALM}/scripts/groups/test.txt"
        else
            echo "* PAS d'injection de test.txt dans SYSVOL (le répertoire /home/sysvol/${AD_REALM}/scripts/groups n'existe pas !)"
        fi
    else
        echo "* PAS d'injection de test.txt, car pas de SYSVOL sur les versions avant 2.7 !"
    fi
fi

if [[ "$VM_MODULE" == "seth" ]]
then
    # shellcheck disable=SC1091
    . /etc/eole/samba4-vars.conf
    if [ -d "/home/sysvol/${AD_REALM}/scripts/groups" ]
    then
        echo "* Inject test.txt dans SYSVOL"
        printf 'lecteur,T:,\\FILE\test' >"/home/sysvol/${AD_REALM}/scripts/groups/test.txt" 
    else
        echo "* PAS d'injection de test.txt, car /home/sysvol/${AD_REALM}/scripts/groups n'existe pas !"
    fi
fi

if [[ "$VM_MODULE" == "amon" ]] || [[ "$VM_MODULE" == "amonecole" ]]
then
    if ciVersionMajeurAPartirDe "2.8."
    then
        echo "Création des fichiers domaines_noauth_user"
        container_path_proxy="$(CreoleGet container_path_proxy)"
        echo "domaine1.fr
.domaine2.fr" > "$container_path_proxy/var/lib/eole/domaines_noauth_user"
        cp "$container_path_proxy/var/lib/eole/domaines_noauth_user" "$container_path_proxy/etc/squid/domaines_noauth_user"
        echo "domaine1.fr
domaine2.fr" > "$container_path_proxy/etc/guardian/common/domaines_noauth_user"
        bash "$VM_DIR_EOLE_CI_TEST/tests/migration/check-domaines_noauth_user.sh"
    fi
fi
echo "MODE $MODE $VM_MODULE $VM_VERSIONMAJEUR"
case "$MODE" in
    SMBWIN)
        umount /mnt/samba >/dev/null 2>&1
        [ ! -d /mnt/samba ] && mkdir /mnt/samba
        
        # c'est le nom de la machine de test, pas du modele !
        # ex.: etb1.pceleve-10.1909 pour un modele etb1.pceleve 
        if [ -z "$3" ]
        then
            NOM_MACHINE_PC=etb1.pcdmz
        else
            NOM_MACHINE_PC="$3"
        fi
        # la machine pcdmz s'appelle DESKTOP-5SPH695

        SEARCH_ID=1
        for i in $(seq 1 10)
        do
            echo "Recerche ID : test $i"
            sleep 5
            # pour les postes Windows, l'automate me crée le FICHIER_ID_MACHINE (dans eole-ci TestMachineWindows.saveIdMachineName)
            FICHIER_ID_MACHINE="$VM_DIR_EOLE_CI_TEST/output/$VM_OWNER/${NOM_MACHINE_PC}.id"
            if [ ! -f "$FICHIER_ID_MACHINE" ]
            then
                echo "fichier $FICHIER_ID_MACHINE manquant, stop !"
                continue
            fi 
            ID=$(cat "$FICHIER_ID_MACHINE")
            if [ -z "$ID" ]
            then
                echo "fichier $FICHIER_ID_MACHINE ne contient pas l'ID de la machine windows !"
                continue
            fi
            REPERTOIRE_MACHINE="$VM_DIR_EOLE_CI_TEST/output/$VM_OWNER/$ID"
            if [ ! -d "$REPERTOIRE_MACHINE" ]
            then
                echo "Repertoire $REPERTOIRE_MACHINE manquant, le pc ne l'a pas générer. stop !"
                # si on vient ici, c'est que le service executeur EoleCiTestService est en erreur sur le pc.... et qu'il n'a pas crée ce dossier !
                # il est fort probable que le fichier 'ip' n'est pas disponible nom plus.
                # donc on s'arrete !
                continue
            fi 
            IP_PC=$(tr -d '\r\n' <"$REPERTOIRE_MACHINE/ip" )
            if [ -z "$IP_PC" ]
            then
                echo "fichier $REPERTOIRE_MACHINE/ip ne contient pas l'IP de la machine windows !"
                continue
            fi
            SEARCH_ID=0
            break
        done
        if [ "$SEARCH_ID" -eq 1 ]
        then
            exit 1
        fi
        SMB_MACHINE="pc-$ID"
        SMB_IP=$IP_PC
        SMB_SHARE=sauvegardes
        
        echo "* ping ${SMB_IP}"
        ciGetNamesInterfaces
        ciPingHost "${SMB_IP}" "${VM_INTERFACE0_NAME}"
        
        echo "* check smbclient"
        if [[ "$VM_CONTAINER" = "oui" ]]
        then
            # shellcheck disable=SC2029
            ssh partage "smbclient -V >/dev/null 2>&1 || apt-get install -y smbclient" 
        else
            smbclient -V >/dev/null 2>&1 || apt-get install -y smbclient 
        fi 

        echo "* smbclient -L //${SMB_IP}/${SMB_SHARE} -Upcadmin%eole -m SMB3"
        if [[ "$VM_CONTAINER" = "oui" ]]
        then
            # shellcheck disable=SC2029
            ssh partage smbclient -L "//${SMB_IP}" -Upcadmin%eole -W WORKGROUP -m SMB3
        else
            smbclient -L "//${SMB_IP}" -Upcadmin%eole -W WORKGROUP -m SMB3 -c ls
        fi 
        
        # ************************************************************
        # Voir réponse : https://bugzilla.samba.org/show_bug.cgi?id=12863
        # ************************************************************
        
        echo "* smbclient //${SMB_IP}/${SMB_SHARE} -Upcadmin%eole -m SMB3"
        if [[ "$VM_CONTAINER" = "oui" ]]
        then
            # shellcheck disable=SC2029
            ssh partage smbclient "//${SMB_IP}/${SMB_SHARE}" -Upcadmin%eole -W WORKGROUP -m SMB3
        else
            smbclient "//${SMB_IP}/${SMB_SHARE}" -Upcadmin%eole -W WORKGROUP -m SMB3 -c ls
        fi 
        
        echo "* tests: mount --verbose -t cifs -o rw,vers=2.0,_netdev,username=pcadmin,password=eole  //${SMB_IP}/${SMB_SHARE} /mnt/samba "
        # attention vers=1.0 ne fonctionne plus avec Windows10 !
        if ! mount --verbose -t cifs -o rw,vers=2.0,_netdev,username=pcadmin,password=eole  "//${SMB_IP}/${SMB_SHARE}" /mnt/samba 
        then
            echo "mount impossible !"
            exit 1
        fi
        echo "* tests mount ok, umount"
        umount /mnt/samba
        echo $?

        echo "* bareosconfig.py"
        /usr/share/eole/sbin/bareosconfig.py -s smb --smb_machine="$SMB_MACHINE" --smb_ip="$SMB_IP" --smb_partage="$SMB_SHARE" --smb_login=pcadmin --smb_password=eole
        SUPPORT=$(/usr/share/eole/sbin/bareosconfig.py -d | grep ^Support | sed s"/\ u'/ '/g" | sed s"/{u'/{'/")
        if echo "$SUPPORT" | grep -q "'smb_ip': '$SMB_IP'"
        then
            echo "Support configuré : Ok"
        else

            /usr/share/eole/sbin/bareosconfig.py -d
            echo "Support mal configuré, exit=1"
            exit 1
        fi
        ;;

    SMB)
        umount /mnt/samba >/dev/null 2>&1
        [ ! -d /mnt/samba ] && mkdir /mnt/samba
        
        SMB_MACHINE=$3
        SMB_IP=$4
        SMB_SHARE=$5
        
        echo "* ping ${SMB_IP}"
        ciGetNamesInterfaces
        ciPingHost "${SMB_IP}" "${VM_INTERFACE0_NAME}"

        echo "* check smbclient"
        if [[ "$VM_CONTAINER" = "oui" ]]
        then
            # shellcheck disable=SC2029
            ssh partage "smbclient -V >/dev/null 2>&1 || apt-get install -y smbclient" 
        else
            smbclient -V >/dev/null 2>&1 || apt-get install -y smbclient
        fi 
        
        echo "* smbclient //${SMB_IP}/${SMB_SHARE} -Uroot%eole -m SMB3 -c 'ls' "
        if [[ "$VM_CONTAINER" = "oui" ]]
        then
            # shellcheck disable=SC2029
            ssh partage smbclient "//${SMB_IP}/${SMB_SHARE}" -Uroot%eole -m SMB3 -c 'ls'
        else
            smbclient "//${SMB_IP}/${SMB_SHARE}" -Uroot%eole -m SMB3 -c 'ls'
        fi 
        
        echo "* tests: mount --verbose -t cifs -o rw,vers=2.0,_netdev,username=root,password=eole  //${SMB_IP}/${SMB_SHARE} /mnt/samba "
        # attention vers=1.0 ne fonctionne plus avec Windows10 !
        if ! mount --verbose -t cifs -o rw,vers=2.0,_netdev,username=root,password=eole  "//${SMB_IP}/${SMB_SHARE}" /mnt/samba 
        then
            echo "mount impossible !"
            exit 1
        fi
        echo "* tests mount ok, umount"
        umount /mnt/samba
        echo $?

        if ciVersionMajeurAvant "2.6.2"
        then
            ciSignalHack "Personnalisation des options de montage Bareos (vers=3.0)"
            echo "DISTANT_LOGIN_MOUNT='/bin/mount -t cifs -o username={0},password={1},ip={2},uid={3},noexec,nosuid,nodev,vers=3.0 //{4}/{5} {6}'" > /etc/eole/bareos.conf
        fi

        echo "* bareosconfig.py"
        /usr/share/eole/sbin/bareosconfig.py -s smb --smb_machine="$SMB_MACHINE" --smb_ip="$SMB_IP" --smb_partage="$SMB_SHARE" --smb_password=eole --smb_login=root
        SUPPORT=$(/usr/share/eole/sbin/bareosconfig.py -d | grep ^Support | sed s"/\ u'/ '/g" | sed s"/{u'/{'/")
        if echo "$SUPPORT" | grep -q "'smb_ip': '$SMB_IP'"
        then
            echo "Support configuré : Ok"
        else
            /usr/share/eole/sbin/bareosconfig.py -d
            echo "Support mal configuré, exit=1"
            exit 1
        fi
        ;;

    USB)
        if [ -e /dev/vdb ] 
        then
            DISK_SAUVEGARDE=vdb
        else
            if [ -e /dev/sdb ] 
            then
                DISK_SAUVEGARDE=sdb
            else
                echo "ERREUR: Impossible de trouvé le disque de sauvegarde, exit 1"
                exit 1
            fi
        fi
        echo "FDISK ${DISK_SAUVEGARDE} "
        ( printf 'd\nn\np\n1\n\n\n\nw\n' | fdisk /dev/${DISK_SAUVEGARDE} )
        
        echo "FORMATAGE ${DISK_SAUVEGARDE} ext4 et creation de ${DISK_SAUVEGARDE}1 "
        mkfs -t ext4 /dev/${DISK_SAUVEGARDE}1
        
        echo "bareosconfig"
        /usr/share/eole/sbin/bareosconfig.py -s usb --usb_path=/dev/${DISK_SAUVEGARDE}1
        SUPPORT=$(/usr/share/eole/sbin/bareosconfig.py -d | grep ^Support | sed s"/\ u'/ '/g" | sed s"/{u'/{'/")
        if echo "$SUPPORT" | grep -q "'usb_path': '/dev/${DISK_SAUVEGARDE}1'"
        then
            echo "Support configuré : Ok"
        else
            /usr/share/eole/sbin/bareosconfig.py -d
            echo "Support mal configuré, exit=1"
            exit 1
        fi
        /usr/share/eole/sbin/bareosmount.py --mount --owner
        ;;

    LOCAL)
        /usr/share/eole/sbin/bareosconfig.py -s manual
        SUPPORT=$(/usr/share/eole/sbin/bareosconfig.py -d | grep ^Support | sed s"/\ u'/ '/g" | sed s"/{u'/{'/")
        if [ "$SUPPORT" != "Support : {'support_type': 'manual'}" ]
        then
            /usr/share/eole/sbin/bareosconfig.py -d
            echo "Support mal configuré, exit=1"
            exit 1
        else
            echo "Support configuré : Ok"
        fi
        
        echo "Initialisation fichier et Mysql avant sauvegarde"
        
        if [ -d /home/a/admin/perso ]
        then
            echo "* Création de /home/a/admin/perso/toto3.txt"
            echo >/home/a/admin/perso/toto3.txt
        else
            echo "******** PAS DE Création de /home/a/admin/perso/toto3.txt"
        fi
        
        if [ -x /usr/share/eole/schedule/scripts/mysql ]
        then
            echo "* Définition quota pour c31e1"
            if ciVersionMajeurAPartirDe "2.8."
            then
                python3 -c "from fichier.quota import set_quota;set_quota('c31e1', 50)"
            else
                python -c "from fichier.quota import set_quota;set_quota('c31e1', 50)"
            fi
            echo "* Création base mysql testsquash"
            mysql_add.py testsquash dbuser dbpass
            CreoleRun "echo 'create table testtable (id INT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY);' | mysql --defaults-file=/etc/mysql/debian.cnf testsquash" mysql
        else
            echo "******** PAS DE Création MYSQL"
        fi

        if [ -f /var/lib/lxc/addc/config ]
        then
            echo "* Création d'un compte machine dans AD"
            lxc-attach -n addc samba-tool computer create BareosComputer
        fi
        ;;
                
    *)
        echo "Option du test incorrecte : SMB, USB, LOCAL"
        exit 1
        ;;
esac

echo "* vide message !"
printf 'cancel all\nmessages\nquit' | bconsole -c /etc/bareos/bconsole.conf >/dev/null

echo "* SUPPORT=$SUPPORT"
/usr/share/eole/sbin/bareosconfig.py -n --level=Full

ciWaitBareos
ciCheckExitCode "$?" "Timeout log bareos"

echo "Liste répertoire sauvegardes"
case "$MODE" in
    SMB)
        if [[ "$VM_CONTAINER" = "oui" ]]
        then
            # shellcheck disable=SC2029
            ssh partage smbclient "//${SMB_IP}/${SMB_SHARE}" -Uroot%eole -m SMB3 -c 'ls'
        else
            smbclient "//${SMB_IP}/${SMB_SHARE}" -Uroot%eole -m SMB3 -c 'ls'
        fi 
        ;;

    USB)
        ls -l /dev/"${DISK_SAUVEGARDE}"1
        ;;

    LOCAL)
        ls -l /mnt/sauvegardes
        ;;
esac

echo "Vérification présence 'Access denied' lors de la sauvegarde ?"
if grep "Access denied" "/var/log/rsyslog/local/bareos-dir/${BAREOS_DIR_LOG}"
then
    echo "nok"
    BAREOS_RESULT="1"
else
    echo "Ok"
fi

echo "Test"
NB=$(grep --count "Backup OK" "/var/log/rsyslog/local/bareos-dir/${BAREOS_DIR_LOG}" )
echo "nb = $NB, NB_OK_ATTENDU=$NB_OK_ATTENDU"
if [ "$NB" -ne "$NB_OK_ATTENDU" ] 
then 
    echo "ERREUR pas le bon nombre de lignes 'Backup'"
    BAREOS_RESULT="1"
else
    if [ "$MODE" == "LOCAL" ]
    then
        ciPutBackup
        BAREOS_RESULT=$?
        
        echo "* Execution diagnose Bareos (bash /usr/share/eole/diagnose/153-bareos)"
        bash /usr/share/eole/diagnose/153-bareos
        echo "153-bareos => $?"
    fi
fi
if ciVersionMajeurApres "2.8.0"
then
    NB=$(grep --count 'run AfterJob ".bvfs_update"' "/var/log/rsyslog/local/bareos-dir/${BAREOS_DIR_LOG}" )
    echo "nb = $NB, NB_BVFS_ATTENDU=$NB_BVFS_ATTENDU"
    if [ "$NB" -ne "$NB_BVFS_ATTENDU" ]
    then
        echo "ERREUR pas le bon nombre de lignes '.bvfs_update'"
        BAREOS_RESULT="1"
    fi
fi

exit $BAREOS_RESULT
