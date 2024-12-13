#!/bin/bash
# shellcheck disable=SC2034,SC2148

function checkExitCode()
{
    EC="${1}"
    if [[ "$EC" -eq 0 ]]
    then
        return 0
    fi
    bash sauvegarde-fichier.sh maj_auto
    
    echo "* dpkg --get-selections | grep hold"
    dpkg --get-selections | grep hold
    
    if [ "$VM_VERSIONMAJEUR" \< "zzzzz" ]
    then
        ciCheckExitCode "$EC" 
    else
        echo "Warning: exit code=$EC, mais je continue...."
    fi
}

function doUpdateUbuntu()
{
    echo "*********************************************************"
    echo "* apt-get update & apt-get upgrade"

    if [ -d /etc/needrestart/conf.d ]
    then
        cat > /etc/needrestart/conf.d/EoleCiTests.conf <<EOF
\$nrconf{blacklist_rc} = [
    q(^EoleCiTestsDaemon) ,
];
EOF
    fi

    apt-get update
    apt-get -y upgrade
}

function injectEnvole()
{
    echo "*********************************************************"
    echo "* faut-il injecter Envole ?"
    if [ "${VM_MODULE}" == "scribe" ] || [ "${VM_MODULE}" == "horus" ] || [ "${VM_MODULE}" == "amonecole" ]
    then
        echo "Oui sur ${VM_MODULE}"
    else
        echo "Non sur ${VM_MODULE}"
        return 0
    fi

    if ! grep envole /etc/apt/sources.list
    then
        ciGetEnvoleVersion
        echo "ENVOLE VERSION = $ENVOLE"

        if [ "$VM_MAJAUTO" == "DEV" ]
        then
            echo "deb http://test-eole.ac-dijon.fr/envole envole-${ENVOLE}-unstable main" > /etc/apt/sources.list.d/envole.list
        else
            echo "deb http://test-eole.ac-dijon.fr/envole envole-${ENVOLE} main" >/etc/apt/sources.list.d/envole.list
        fi
    else
        echo "* Source list Envole dans /etc/apt/sources.list ! "
    fi

    if [ -f /etc/apt/sources.list.d/envole.list ]
    then 
        echo "* Source list Envole"
        cat /etc/apt/sources.list.d/envole.list
    else
        echo "* pas de source list 'envole.list' !!"
    fi

    doUpdateUbuntu
}

function createMountPointHome()
{
    echo "*********************************************************"
    echo "* Home dans /etc/fstab ? "
    if grep home /etc/fstab
    then
        echo "home dans fstab"
    else
        ciPrintMsg "VGS"
        vgs
        
        ciPrintMsg "Identifier le /dev"
        LVM=$(vgs --noheadings -o name |xargs)
        if [ -z "${LVM}" ]
        then
            ciPrintMsg "impossible de trouver le dev LVM"
            ciSignalHack "Hack rapide pour EOLE 2.10"
            ciPrintMsg "blkid"
            ID=$(blkid | grep ext4)
            ciPrintMsg "$ID"
            eval "$(echo "$ID" | cut -d' ' -f2)"
            echo "UUID=$UUID /home           ext4    defaults        0       2" >>/etc/fstab
            mount -a
            systemctl daemon-reload
            return 1
        fi
        echo "LVM=$LVM"
        
        LV="/dev/${LVM}/home"
        lvdisplay "${LV}"
        if lvdisplay "${LV}" ;
        then
            echo "${LV} existe déjà !"
        else
            echo "Creation de ${LV} "
            lvcreate -v -l50%FREE -n home "${LVM}"
            result="$?"
            if [ "$result" -eq "5" ]
            then
                echo "Plus de place, stop"
                return 0
            fi
            # /dev/sda5
            checkExitCode "$result"
    
            echo "FORMATAGE ext4 et creation de ${LV} "
            mkfs -t ext4 "${LV}"
            checkExitCode "$?"
        fi
    
        echo "Enregistrment dans /etc/fstab"
        MAPPER=$(ls /dev/mapper/*-home)
        echo "# ajout pendant $0 " >>/etc/fstab
        echo "${MAPPER} /home           ext4    defaults        0       2" >>/etc/fstab
    
        echo "Mount ${MAPPER} temporaire et transfert de /home/eole dedans"
        mkdir /mnt/home
        mount "${MAPPER}" /mnt/home
        checkExitCode "$?"
        mv /home/eole/ /mnt/home
        sync
        umount "${MAPPER}"
        checkExitCode "$?"
        rm -rf /mnt/home
    
        echo "remount ${MAPPER} en /home"
        mount /home
        checkExitCode "$?"
        
    fi
    echo "*********************************************************"
    echo "* affichage partitionnement "
    df -h
    
    pvdisplay
    
    vgdisplay
}

#########################################################################################################
#
# Extends LVM root with size
#
#########################################################################################################
function ciExtendsLvmRoot()
{
    ciPrintMsgMachine "ciExtendsLvmRoot"

    AJOUTER_A=var
    
    ciPrintMsg "VGS"
    vgs

    ciPrintMsg "Identifier le /dev"
    LVM=$(vgs --noheadings -o name |xargs)
    if [ -z "${LVM}" ]
    then
        ciSignalWarning "impossible de trouver le dev LVM"
        return 1
    fi

    echo "LVM=${LVM}"
    ls -l "/dev/${LVM}"

    LV="/dev/${LVM}/root"
    lvdisplay "${LV}"
    checkExitCode "$?"
   
    ciPrintMsg "Current size LV de /dev/${LVM}/root"
    LV_SIZE=$(lvs "/dev/${LVM}/root" --noheadings -olv_size)
    echo "$LV_SIZE"

    ciPrintMsg "Ajouter +10G au LV de /dev/${LVM}/root"
    lvextend -L+10G "/dev/${LVM}/root"
    RESULT="$?"
    if [ "$RESULT" -ne 0 ]
    then
        ciSignalWarning "impossible d'étendre le LV (exit=$RESULT)"
        return 1
    fi

    ciPrintMsg "Étendre le système de fichier pour occuper tout l’espace ajouté"
    resize2fs "/dev/${LVM}/root"
    RESULT="$?"
    if [ "$RESULT" -ne 0 ]
    then
        ciSignalWarning "impossible resizer le LV (exit=$RESULT)"
        return 1
    fi

    ciPrintMsg "ciExtendsLvmRoot : ok"
    return 0
}
export -f ciExtendsLvmRoot

function cleanSourceListBeforeInstall()
{
    echo "*********************************************************"
    echo "* Source list "
    grep -v "#" /etc/apt/sources.list
    
    /bin/rm -f /etc/apt/sources.list.d/envole.list
}

function installEole2()
{
    echo "*********************************************************"
    echo "* installEole2 $FRESHINSTALL_MODULE  VM_VERSION_EOLE=$VM_VERSION_EOLE"
    if [ "$FRESHINSTALL_MODULE" == base ]
    then
        injectEnvole
    
        # je suis sur une eolebase
        if [ "$VM_VERSION_EOLE" == "2.11" ]
        then
            ciSignalHack "Ajout des dépots 2.9 ${VM_MODULE} pour $VM_VERSION_EOLE"
            rm /etc/apt/sources.list.d/eole*.list 2>/dev/null
            echo "deb http://test-eole.ac-dijon.fr/eole eole-2.9.0 main cloud" > /etc/apt/sources.list.d/eole.list
            echo "deb http://test-eole.ac-dijon.fr/eole eole-2.9.0-security main cloud" >> /etc/apt/sources.list.d/eole.list
            echo "deb http://test-eole.ac-dijon.fr/eole eole-2.9.0-updates main cloud" >> /etc/apt/sources.list.d/eole.list
            wget -O /tmp/repository.key "http://test-eole.ac-dijon.fr/eole/project/eole-2.9-repository.key"
            apt-key add /tmp/repository.key
            apt-get update
            #apt-get install libruby2.7
            
            DEPOT=${VM_VERSION_EOLE}-unstable
            echo "deb http://test-eole.ac-dijon.fr/eole eole-${DEPOT} main cloud" > /etc/apt/sources.list.d/eole.list
            apt-get update
        fi
        
        # je suis sur une eolebase
        ciMajAutoSansTest
        checkExitCode "$?"
    else
        # je suis sur autre chose (ubuntu)
        echo "*********************************************************"
        echo "* Active depot EOLE"
        # je suis sur une ubuntu ==> donc 'eole' n'apparait pas dans le sources.list
        if [ "$VM_MAJAUTO" == "DEV" ]
        then
            if [ "$VM_VERSION_EOLE" == "2.10" ]
            then
                DEPOT=${VM_VERSION_EOLE}-unstable
                #wget -O /tmp/repository.key "http://test-eole.ac-dijon.fr/eole/project/eole-${VM_VERSION_EOLE}-repository.key"
                #RESULT="$?"
                #if [ "$RESULT" -ne 0 ]
                #then 
                #    ciSignalHack "Ajout des dépots 2.9 ${VM_MODULE} pour $VM_VERSION_EOLE"
                #    rm /etc/apt/sources.list.d/eole*.list 2>/dev/null
                #    echo "deb http://test-eole.ac-dijon.fr/eole eole-2.9.0 main cloud" > /etc/apt/sources.list.d/eole.list
                #    wget -O /tmp/repository.key "http://test-eole.ac-dijon.fr/eole/project/eole-2.9-repository.key"
                #    apt-key add /tmp/repository.key
                #    apt-get update
                #    
                    #ciSignalHack "Activation Dépots SaltStack Python3"
                    #wget -O - https://packages.broadcom.com/py3/ubuntu/24.04/amd64/latest/SALTSTACK-GPG-KEY.pub | sudo apt-key add -
                    #echo "deb http://packages.broadcom.com/py3/ubuntu/24.04/amd64/latest focal main" >> /etc/apt/sources.list.d/saltstack.list
    
                #else
                    #apt-key add /tmp/repository.key
                    ciSignalHack "Installation manuelle du paquet contenant les clés EOLE"
                    KEYRING_PACKAGE=eole-archive-keyring_2024.03.07-1_all.deb
                    wget "http://eole.ac-dijon.fr/eole/pool/main/e/eole-keyring/${KEYRING_PACKAGE}" -O "/tmp/${KEYRING_PACKAGE}"
                    dpkg -i "/tmp/${KEYRING_PACKAGE}"
                    RESULT="$?"
                    echo "deb http://test-eole.ac-dijon.fr/eole eole-${DEPOT} main cloud" > /etc/apt/sources.list.d/eole.list
                #fi

                # désactivation de la configuration automatique de l'annuaire (#33931)
                debconf-set-selections <<EOF
slapd slapd/no_configuration boolean true
EOF

                ciPrintMsgMachine "2.10 : disable apt-news, esm-cache"
                systemctl disable apt-news.service
                systemctl disable esm-cache.service
                apt-get remove -y apt-news
                apt-get remove -y esm-cache
                apt-get remove -y ubuntu-advantage-tools
                
                ciPrintMsgMachine "2.10 : (re)enable snapd.apparmor"
                systemctl enable --now snapd.apparmor

            else
                if [ "$VM_VERSION_EOLE" == "3.0" ]
                then
                    # hapy 3.0 = hapy 2.8
                    ciSignalHack "Ajout des dépots 2.9.0 stable pour $VM_VERSION_EOLE"
                    echo "deb http://test-eole.ac-dijon.fr/eole eole-2.9.0 main cloud" >> /etc/apt/sources.list.d/eole.list
                    
                    ciSignalHack "Activation Dépots SaltStack Python3"
                    wget -O - https://packages.broadcom.com/py3/ubuntu/22.04/amd64/latest/SALTSTACK-GPG-KEY.pub | sudo apt-key add -
                    echo "deb http://packages.broadcom.com/py3/ubuntu/22.04/amd64/latest focal main" >> /etc/apt/sources.list.d/saltstack.list
    
                    wget -O /tmp/repository.key "http://test-eole.ac-dijon.fr/eole/project/eole-2.9-repository.key"
                    RESULT="$?"
                    apt-key add /tmp/repository.key
                else
                    DEPOT=${VM_VERSION_EOLE}-unstable
                    echo "deb http://test-eole.ac-dijon.fr/eole eole-${DEPOT} main cloud" > /etc/apt/sources.list.d/eole.list
                
                    wget -O /tmp/repository.key "http://test-eole.ac-dijon.fr/eole/project/eole-${VM_VERSION_EOLE}-repository.key"
                    RESULT="$?"
                    apt-key add /tmp/repository.key
                fi
            fi

        else
            DEPOT=$VM_VERSIONMAJEUR
            (
                echo "deb http://eole.ac-dijon.fr/eole eole-${DEPOT} main cloud"
                echo "deb http://eole.ac-dijon.fr/eole eole-${DEPOT}-security main cloud"
                echo "deb http://eole.ac-dijon.fr/eole eole-${DEPOT}-updates main cloud"
            ) > /etc/apt/sources.list.d/eole.list
            wget -O /tmp/repository.key "http://test-eole.ac-dijon.fr/eole/project/eole-${VM_VERSION_EOLE}-repository.key"
            RESULT="$?"
            apt-key add /tmp/repository.key
        fi
        if [ "$RESULT" -ne 0 ]
        then
            # si erreur ==> unauthenticated !
            #APT_OPTS="--allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages -y "
            APT_OPTS="-y"
        else
            APT_OPTS=""
        fi

        echo "*********************************************************"
        echo "* Source list Eole"
        cat /etc/apt/sources.list.d/eole.list
       
        doUpdateUbuntu
        
        echo "*********************************************************"
        echo "* apt list --upgradable"
        apt list --upgradable
        
        # je suis sur une ubuntu OU eolebase ==> donc 'envole' n'apparait pas dans le sources.list
        echo "*********************************************************"
        echo "* install eole-server eole-exim-pkg"
        apt-get install "$APT_OPTS" -y eole-server eole-exim-pkg
        CDU=$?
        if [ "$CDU" == "100" ]
        then
             echo "*****************************************************"
             echo "* install --dry-run -o Debug::pkgProblemResolver=yes  "
             apt-get install --dry-run -o Debug::pkgProblemResolver=yes eole-server eole-exim-pkg
             
             echo "*****************************************************"
             echo "* apt-rdepends eole-server   "
             apt rdepends eole-server
             
             PAQUETS_A_PROBLEME=$(apt rdepends eole-server 2>/dev/null | grep " conflit " | awk -F":" '{ print $2; }' | awk -F" " '{ print $1; }' | sort)
             echo "*****************************************************"
             echo "PAQUETS_A_PROBLEME='$PAQUETS_A_PROBLEME'"
             echo "*****************************************************"
             echo "* Analyse des problèmes "
             for PQ in $PAQUETS_A_PROBLEME
             do
                 echo "*****************************************************"
                 echo "***** Pkg problématique $PQ"
                 apt-cache policy "$PQ"
                 
                 echo "***** test 'apt-get install $PQ'"
                 apt-get install --dry-run -o Debug::pkgProblemResolver=yes "$PQ"
                 echo "*****************************************************"
             done
        fi
        # pour enregistrer la VM, il ne faut pas s'arreter !
        checkExitCode "$CDU" 
        echo "EOLE_CI_FORCE_UPDATE $CDU"
    
        if [ "$VM_VERSION_EOLE" != "2.9" ]
        then
            echo "*********************************************************"
            echo "* ciExtendsLvm Base"
            ciExtendsLvmRoot
        fi
    fi
    
    if [ "${VM_MODULE}" == "samba4" ]
    then
        VM_MODULE="base"
    fi
    
    if [ "${VM_MODULE}" != "base" ]
    then
        if [ "$VM_CONTAINER" == "oui" ]
        then
            if ciVersionMajeurAPartirDe "2.9."
            then
                echo "* ciExtendsLvmRoot Container"
                ciExtendsLvmRoot
            fi
            
            echo "*********************************************************"
            echo "* Container ==> install eole-lxc-controller eole-${VM_MODULE}-module"
            if [ "$FRESHINSTALL_MODULE" == base ]
            then
                if ! ciVersionMajeurAPartirDe "2.9."
                then
                    env -i HOME="$HOME" LC_CTYPE="${LC_ALL:-${LC_CTYPE:-$LANG}}" PATH="$PATH" USER="$USER" \
                       apt-eole install eole-lxc-controller "eole-${VM_MODULE}-module" ssmtp
                else
                    env -i HOME="$HOME" LC_CTYPE="${LC_ALL:-${LC_CTYPE:-$LANG}}" PATH="$PATH" USER="$USER" \
                       apt-eole install eole-lxc-controller "eole-${VM_MODULE}-module"
                fi
            else
                env -i HOME="$HOME" LC_CTYPE="${LC_ALL:-${LC_CTYPE:-$LANG}}" PATH="$PATH" USER="$USER" \
                  apt-get install "$APT_OPTS" -y eole-lxc-controller "eole-${VM_MODULE}-module"
            fi
    
            checkExitCode "$?"
        else
            if [ "${VM_MODULE}" == "scribe" ] || [ "${VM_MODULE}" == "horus" ]
            then
                injectEnvole
        
                echo "*********************************************************"
                echo "* install php-mcrypt "
                if ! apt-get install -y php-mcrypt
                then
                    if [ -f "$VM_DIR_EOLE_CI_TEST/php-mcrypt_1.0_all.deb" ]
                    then
                        echo "* HACK php-mcrypt "
                        dpkg -i "$VM_DIR_EOLE_CI_TEST/php-mcrypt_1.0_all.deb"
                        checkExitCode "$?"
                        ciSignalAlerte "* HACK php-mcrypt_1.0_all.deb"
                    fi
                else
                    echo "* HACK php-mcrypt : php-mcrypt installé depuis le dépot : plus besoin du HACK"
                fi
                
                #bash "$VM_DIR_EOLE_CI_TEST/scripts/install-sympa.sh"
            fi
            echo "*********************************************************"
            echo "* module != eolebase ==> install eole-${VM_MODULE}-all"
            if [ "$FRESHINSTALL_MODULE" == base ]
            then
                # pour zephir, il est important d'utiliser apt-eole !
                env -i HOME="$HOME" LC_CTYPE="${LC_ALL:-${LC_CTYPE:-$LANG}}" PATH="$PATH" USER="$USER" \
                    apt-eole install "eole-${VM_MODULE}-all"
            else
                env -i HOME="$HOME" LC_CTYPE="${LC_ALL:-${LC_CTYPE:-$LANG}}" PATH="$PATH" USER="$USER" \
                    apt-get install "$APT_OPTS" -y "eole-${VM_MODULE}-all"
            fi
            checkExitCode "$?"
        fi
    fi
    
    echo "*********************************************************"
    echo "* faut il enlever 'envole.list' ?"
    if grep -q envole /etc/apt/sources.list
    then
        echo "* il faut enlever 'envole.list' : OUI"
        rm -f /etc/apt/sources.list.d/envole.list
    else
        echo "* il faut enlever 'envole.list' : NON"
    fi
    
    echo "*********************************************************"
    echo "* plymouth-themes plymouth-label"
    if [ "$FRESHINSTALL_MODULE" == base ]
    then
        apt-eole install plymouth-themes plymouth-label
    else
        apt-get install "$APT_OPTS" -y plymouth-themes plymouth-label
        echo "* nettoyage /etc/apt/sources.list.d/eole.list"
        rm -f /etc/apt/sources.list.d/eole.list
    fi
    checkExitCode "$?"
    
    echo "*********************************************************"
    echo "* autoremove"
    apt-get autoremove --purge -y
    checkExitCode "$?"
    
    echo "*********************************************************"
    echo "* test zephir "
    if [ "${VM_MODULE}" = "zephir" ]
    then
        if [ -f /etc/init.d/z_stats ]
        then
            echo "ERREUR: le service z_stats existe encore !"
            exit 1
        fi
    fi    
}

function installEole3()
{
    if [ "$VM_MODULE" == hapy ]
    then
        FRESHINSTALL_MODULE=ubuntu installEole2
        return
    fi
    echo "* ssh AccesRoot"
    sed -i -e 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

    echo "* ssh AllowAgentForwarding"
    sed -i -e 's/#AllowAgentForwarding.*/AllowAgentForwarding yes/' /etc/ssh/sshd_config
    systemctl restart ssh

    apt update 
    apt install nfs-common -y
    apt install net-tools -y
    apt install ufw -y
    systemctl start ssh
    
    #echo "sur la daily je ne télécharge que la partie Core (ubuntu minimal)"
    #snap install core --stable
    #echo "l'install microk8s se fait à l'instance!"
    #bash /mnt/eole-ci-tests/scripts/install-eolebase3.sh
}

function installEoleFromUbuntu()
{
    ciGetEoleVersion
    echo "VM_VERSION_EOLE=$VM_VERSION_EOLE"
    
    export DEBIAN_FRONTEND=noninteractive
    createMountPointHome
    cleanSourceListBeforeInstall
    doUpdateUbuntu
    
    if [ "${VM_VERSION_EOLE}" == "3.0" ]
    then
        installEole3
    else
        installEole2
    fi
    
    echo "*********************************************************"
    echo "* Tag image fresh install"
    if [[ -f "/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/.eole-ci-tests.freshinstall" ]]
    then
        cp "/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/.eole-ci-tests.freshinstall" /root/.eole-ci-tests.freshinstall
        chmod 755 /root/.eole-ci-tests.freshinstall
        chown root:root /root/.eole-ci-tests.freshinstall
    fi
    
    echo "*********************************************************"
    echo "* init context daily : resolv.conf, interfaces"
    ciContextualizeDaily
    checkExitCode "$?"
    
    echo "*********************************************************"
    echo "Fin ==> OK"
    exit 0
}

# shellcheck disable=1091
source /root/getVMContext.sh
installEoleFromUbuntu
