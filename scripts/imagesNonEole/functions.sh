#!/bin/bash
# shellcheck disable=SC2034,SC2148,SC2009

function waitAptStopped()
{
    ciPrintMsgMachine "* waitAptStopped"
    SECONDS=0   # Reset $SECONDS; counting of seconds will (re)start from 0(-ish).
    sleep 10
    while (( SECONDS < 600 )); do
        echo "$SECONDS, lock : "
        #lsof -e /run/user/110/gvfs -f -- /var/lib/dpkg/lock
        lsof /var/lib/dpkg/lock
        RESULT="$?"
        if [ "$RESULT" == "1" ]
        then
            echo "Ok, Stop "
            break
        else
            echo "$SECONDS, attente car result=$RESULT !"
            sleep 10
        fi
    done
}

function doAptGet()
{
    echo "* --------------------------------------------------------------------"
    echo "* doAptGet $* ($SECONDS)"
    NEEDRESTART_SUSPEND=yes apt-get "$@"
    echo "* doAptGet $* --> $?"
    echo "* --------------------------------------------------------------------"
}

function doPipInstall()
{
    echo "* --------------------------------------------------------------------"
    echo "* doPipinstall $* ($SECONDS)"
    if [ "$(lsb_release -rs)x" \> "18.00x" ]
    then
        pip3 install "$@"
    else
        pip install "$@"
    fi
    echo "* doPipinstall $* --> $?"
    echo "* --------------------------------------------------------------------"
}

function doAptGetWithRetry()
{
    ciPrintMsgMachine "* doAptGetWithRetry with retry : $*"
    SECONDS=0   # Reset $SECONDS; counting of seconds will (re)start from 0(-ish).
    while (( SECONDS < 300 )); do
        doAptGet "$@"
        RESULT="$?"
        if [ "$RESULT" == "0" ]
        then
            echo "Ok, Stop "
            return 0
        else
            echo "$SECONDS, attente car result=$RESULT !"
            sleep 30
        fi
    done
    echo "ERREUR: Stop"
    return 1
}

function patchNetworkManager()
{
    ciPrintMsgMachine "* patchNetworkManager"
    sed -i -e 's/managed=false/managed=true/' /etc/NetworkManager/NetworkManager.conf
    
    ciPrintMsgMachine "* cat /etc/NetworkManager/NetworkManager.conf"
    cat /etc/NetworkManager/NetworkManager.conf
    ciPrintMsgMachine "* cat /usr/lib/NetworkManager/conf.d/10-globally-managed-devices.conf"
    cat /usr/lib/NetworkManager/conf.d/10-globally-managed-devices.conf
}


function removeServiceResolvConf()
{
    SYSTEMD_RESOLVED_ENABLE=$(systemctl is-enabled systemd-resolved.service) 
    if [ "$SYSTEMD_RESOLVED_ENABLE" == "enabled" ]
    then
        ciPrintMsgMachine "* SYSTEMD_RESOLVED_ENABLE true"
        cat /etc/systemd/resolved.conf
        rm -f /etc/resolv.conf
        ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
    else
        ciPrintMsgMachine "* removeServiceResolvConf"
        doAptGet remove -y resolvconf
        rm -rf /etc/resolvconf
        rm -f /etc/resolv.conf
        # reinitialise la conf par default
        cat >/etc/resolv.conf <<EOF
domain eole.lan
search eole.lan
nameserver 192.168.0.1
EOF
        chmod 644 /etc/resolv.conf
    fi
}

function removeServicesGenant()
{
    ciPrintMsgMachine "* removeServicesGenant"
    doAptGet remove -y ufw
    doAptGet remove -y unattended-upgrades
    doAptGet remove -y linux-kvm
    # cloud-init présent en 22.04 !
    doAptGet remove -y cloud-init
    #doAptGet remove -y xscreensaver
    #doAptGet remove -y gnome-initial-setup
    # bug python-openssl vs gajim
    #doAptGet remove -y python-openssl
    doAptGet -y --purge autoremove
    if command -v systemctl >/dev/null 2>/dev/null
    then
        systemctl disable apt-daily.timer
        systemctl disable apt-daily.service
        systemctl disable apt-daily-upgrade.timer
        systemctl disable apt-daily-upgrade.service
        systemctl enable debug-shell.service
    fi
    if [[ "$IMAGE_FINALE" = *24.04* ]]
    then
        systemctl disable snapd.service 2>/dev/null
        systemctl disable snapd.apparmor.service 2>/dev/null
        systemctl disable snapd.seeded.service 2>/dev/null
        systemctl disable snapd.lxd.daemon.unix.socket 2>/dev/null
        systemctl disable snapd.lxd.activate.service 2>/dev/null 
        systemctl disable lxd-agent.service 2>/dev/null
        
        if ! command -v dhclient
        then
           doAptGet install -y isc-dhcp-client
        fi
    fi
#    if [ -f /etc/update-manager/release-upgrades ]
#    then
#        ciPrintMsgMachine "* /etc/update-manager/release-upgrades"
#        sed -i -e 's/Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades
#    fi
    
    # fait planter doAptGet update ....
    #ciPrintMsgMachine "* suppression notification update apres login"
    #rm /etc/update-motd.d/91-release-upgrade 
    #rm /etc/update-motd.d/90-updates-available 
    #rm /etc/update-motd.d/80-livepatch 
    #rm /etc/update-motd.d/50-motd-news 

}

function forceModule9P()
{
    ciPrintMsgMachine "* forceModule9P"
    if ! grep "9p" /etc/initramfs-tools/modules >/dev/null
    then
        (
        echo "9p" 
        echo "9pnet" 
        echo "9pnet_virtio"
        ) >>/etc/initramfs-tools/modules
        update-initramfs -u
    else
        echo "9p est dans /etc/initramfs-tools/modules" 
    fi
    
    if command -v updatedb
    then
        # désactive le locate sur /mnt/eole-ci-test !
        if ! grep -q 9p /etc/updatedb.conf
        then
            echo "* désactive le updatedb/locate sur /mnt/eole-ci-test !" 
            sed -i 's#PRUNEFS="NFS#PRUNEFS="9p NFS#' /etc/updatedb.conf

            echo "* updatedb"
            updatedb
        fi
    fi
    
}

function sshAccesRoot()
{
    if [ -f /etc/ssh/sshd_config ]
    then
        ciPrintMsgMachine "* sshAccesRoot"
        if grep PermitRootLogin /etc/ssh/sshd_config
        then
            sed -i -e 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
        else
            echo 'PermitRootLogin yes' >>/etc/ssh/sshd_config
        fi

        ciPrintMsgMachine "* AllowAgentForwarding"
        sed -i -e 's/#AllowAgentForwarding.*/AllowAgentForwarding yes/' /etc/ssh/sshd_config
    else
        ciPrintMsgMachine "* Inject /etc/ssh/sshd_config !"
        cat >/etc/ssh/sshd_config <<EOF
PermitRootLogin yes
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
#AllowAgentForwarding yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem   sftp    /usr/lib/openssh/sftp-server
AddressFamily inet
EOF
        
        cat /etc/ssh/sshd_config
    fi
}


function accountPcadmin()
{
    ciPrintMsgMachine "* accountPcadmin"
    
    if ! id pcadmin
    then
        echo "* Création pcadmin"
        adduser pcadmin --home /home/pcadmin --shell /bin/bash --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
    else
        echo "* pcadmin existe"
    fi

    if [ ! -d /home/pcadmin ] 
    then
        echo "* create pcadmin home"
        mkdir /home/pcadmin
    fi

    echo "* check pcadmin rights"
    chown pcadmin /home/pcadmin
    chmod u+rwx /home/pcadmin
    ls -ld /home/pcadmin

    echo "* Add pcadmin to SUDO"
    sudo usermod -aG sudo pcadmin
    sudo usermod -aG sudo cdrom floppy audio dip video plugdev users netdev bluetooth lpadmin scanner pcadmin

    if [ "$(lsb_release -rs)" != "22.04" ]
    then
        echo "* /etc/pam.d/common-password minlen=4 ubutnu avant 22.04 ?"
        if ! grep 'minlen=4' /etc/pam.d/common-password
        then
            sed -i -e 's/obscure sha512/obscure minlen=4 sha512/' /etc/pam.d/common-password
            sed -i -e 's/first_pass sha512/obscure minlen=4 sha512/' /etc/pam.d/common-password
        fi
    else
        if grep -q 'minlen' /etc/pam.d/common-password
        then
            echo "minlen present dans /etc/pam.d/common-password"
        else
            echo "Inject minlen=4 dans /etc/pam.d/common-password"
            sed -i -e 's/pam_pwquality.so retry=3/pam_pwquality.so retry=3 minlen=4/' /etc/pam.d/common-password
        fi
        if grep -q 'minlen = 4' /etc/security/pwquality.conf
        then
            echo "minlen=4 present dans /etc/security/pwquality.conf"
        else
            echo "Inject minlen dans /etc/security/pwquality.conf"
            sed -i -e '/# minlen = 8/a minlen = 4' /etc/security/pwquality.conf
        fi 
    fi
    
    echo "* pcadmin force mot de passe 'eole'"
    echo "pcadmin:eole" | chpasswd
    echo "chpasswd ==> $?"
}

function tagImage()
{
    ciPrintMsgMachine "* Tag l'Image"
    maintenant=$(date '+%s')
    jour="$(date +'%Y-%m-%d %R')"
    {
    echo DAILY_IMAGE="$IMAGE_FINALE";
    echo DAILY_DATEUPDATE="$maintenant";
    echo DAILY_DATE=\'"$jour"\';
    } >/root/.eole-ci-tests.daily
}

function installPaquetsCommunDebianUbuntu()
{
    ciPrintMsgMachine "* installPaquetsCommunDebianUbuntu"
    doAptGet install "$APT_OPTS" -y hwinfo
    ciCheckExitCode "$?"
    
    doAptGet install "$APT_OPTS" -y wget
    ciCheckExitCode "$?"
    
    doAptGet install "$APT_OPTS" -y git
    ciCheckExitCode "$?"
    
    doAptGet install "$APT_OPTS" -y vim
    ciCheckExitCode "$?"

    doAptGet install "$APT_OPTS" -y curl
    ciCheckExitCode "$?"
    
    doAptGet install "$APT_OPTS" -y unzip
    ciCheckExitCode "$?"
    
    doAptGet install "$APT_OPTS" -y less
    ciCheckExitCode "$?"
    
    doAptGet install "$APT_OPTS" -y xauth
    ciCheckExitCode "$?"
    
    doAptGet install "$APT_OPTS" -y iputils-ping
    ciCheckExitCode "$?"
    
    doAptGet install "$APT_OPTS" -y dnsutils
    ciCheckExitCode "$?"
    
    doAptGet install "$APT_OPTS" -y zerofree
    ciCheckExitCode "$?"
    
    doAptGet install "$APT_OPTS" -y iputils-arping
    ciCheckExitCode "$?"
     
    doAptGet install "$APT_OPTS" -y ldap-utils
    ciCheckExitCode "$?"
    
    doAptGet install "$APT_OPTS" -y net-tools
    ciCheckExitCode "$?"
    
    doAptGet install "$APT_OPTS" -y ethtool
    ciCheckExitCode "$?"
    
    doAptGet install "$APT_OPTS" -y tcpdump
    ciCheckExitCode "$?"
    
    doAptGet install "$APT_OPTS" -y telnet
    ciCheckExitCode "$?"
     
    if [ "$(lsb_release -rs)x" \> "18.00x" ]
    then
        doAptGet install "$APT_OPTS" -y python3-all python3-twisted
        ciCheckExitCode "$?"
    
        doAptGet install "$APT_OPTS" -y python3-pil
    else
        doAptGet install "$APT_OPTS" -y python-all python-twisted
        ciCheckExitCode "$?"
    
        doAptGet install "$APT_OPTS" -y python-imaging
    fi
    ciCheckExitCode "$?"
     
    doAptGet install "$APT_OPTS" -y debconf-i18n debconf-utils
    ciCheckExitCode "$?"
    
    doAptGet install "$APT_OPTS" -y openssh-server
    ciCheckExitCode "$?"
    
    doAptGet install "$APT_OPTS" -y ssh
    ciCheckExitCode "$?"
    
    doAptGet install "$APT_OPTS" -y openssl
    ciCheckExitCode "$?"

    if [ "$1" = "lighttpd" ]
    then
        echo "pas de lighttpd"
    else    
        doAptGet install "$APT_OPTS" -y lighttpd w3m
        ciCheckExitCode "$?"
    fi
    
    doAptGet install "$APT_OPTS" -y smbclient
    ciCheckExitCode "$?"
    
    doAptGet install "$APT_OPTS" -y exim4-base exim4-config exim4-daemon-light --no-install-recommends
    doAptGet install "$APT_OPTS" -y fetchmail --no-install-recommends
    doAptGet install "$APT_OPTS" -y mailutils
    
    doAptGet install "$APT_OPTS" -y tree
    doAptGet install "$APT_OPTS" -y mlocate

    doAptGet install "$APT_OPTS" -y shellcheck
}

function bootEn1024x768()
{
    ciPrintMsgMachine "* conf Grub to 1024x768"
    sed -i -e 's/#GRUB_GFXMODE=640.*/GRUB_GFXMODE=1024x768/' /etc/default/grub
    sed -i -e 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' /etc/default/grub
    sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash noresume"/' /etc/default/grub
}

function installPaquetsCommunDebianUbuntuX()
{
    ciPrintMsgMachine "* installPaquetsCommunDebianUbuntuX"
    doAptGet install "$APT_OPTS" -y cups
    ciCheckExitCode "$?"
    
    doAptGet install "$APT_OPTS" -y gajim
    ciCheckExitCode "$?"
    
    doAptGet install "$APT_OPTS" -y xvfb
    ciCheckExitCode "$?"
    
    doAptGet install "$APT_OPTS" -y filezilla
    ciCheckExitCode "$?"

    #echo "nslcd nslcd/ldap-base string  o=gouv,c=fr" | debconf-set-selections
    #echo "nslcd nslcd/ldap-auth-type    select  none" | debconf-set-selections
    #echo "nslcd nslcd/ldap-uris string  ldap://127.0.0.1/" | debconf-set-selections
    #echo "libnss-ldapd    libnss-ldapd/nsswitch   multiselect group, passwd, shadow" | debconf-set-selections
    #echo "libnss-ldapd:amd64  libnss-ldapd/nsswitch   multiselect group, passwd, shadow" | debconf-set-selections
    #echo "libnss-ldapd    libnss-ldapd/clean_nsswitch boolean false" | debconf-set-selections
    #echo "libnss-ldapd:amd64  libnss-ldapd/clean_nsswitch boolean false" | debconf-set-selections
    #doAptGet install "$APT_OPTS" -y nslcd libnss-ldapd libpam-ldapd
    #ciCheckExitCode "$?"
    
    doAptGet install "$APT_OPTS" -y tshark
    ciCheckExitCode "$?"

    doAptGet install "$APT_OPTS" -y meld
    ciCheckExitCode "$?"
}

function installGeckoDriver()
{
    # J'interroge la page latest ==> cherche le lien linux64 
    # ==> split avec '/ ou "' dans un tableau ==> la version est le 6eme (avec le 'v' )! 
    declare -a URL_TO_VERSION
    IFS='"/' read -r -a URL_TO_VERSION <<< "$(wget -q https://github.com/mozilla/geckodriver/releases/latest -O - | grep 'linux64.tar.gz\" ')"
    # 0 a href=
    # 1 ''
    # 2 mozilla
    # 3 geckodriver
    # 4 releases
    # 5 download
    GeckoDriverVersion=${URL_TO_VERSION[6]}
    GeckoDriverFichier=${URL_TO_VERSION[7]}
    # 8 rel=
    # 9 nofollow 
    echo "GeckoDriverVersion=$GeckoDriverVersion"
    echo "GeckoDriverFichier=$GeckoDriverFichier"
    
    if command -v geckodriver >/dev/null 2>&1
    then
        declare -a CURRENT_VERSION
        read -r -a CURRENT_VERSION <<< "$(geckodriver -V)"
        echo "${CURRENT_VERSION[1]}"
        if [ "v${CURRENT_VERSION[1]}" == "$GeckoDriverVersion" ]
        then
            echo "Geckodriver : déjà la même version !, stop"
            return 0
        fi
    fi        
    
    if [ -n "${GeckoDriverFichier}" ]
    then
        rm -f "/tmp/${GeckoDriverFichier}"
        wget -O "/tmp/${GeckoDriverFichier}" "https://github.com/mozilla/geckodriver/releases/download/${GeckoDriverVersion}/${GeckoDriverFichier}"
        sudo tar -xvzf "/tmp/${GeckoDriverFichier}" --directory /usr/local/bin/
        sudo chmod +x /usr/local/bin/geckodriver
        rm "/tmp/${GeckoDriverFichier}"
        if [ ! -f /etc/profile.d/eole-geckodriver.sh ]
        then
            sudo tee /etc/profile.d/eole-geckodriver.sh <<EOF
export PATH="/usr/local/bin/geckodriver:\$PATH"
EOF
            sudo chmod 644 /etc/profile.d/eole-geckodriver.sh
        fi
    fi
}

function installRobotFramework()
{
    ciPrintMsg "* Install setuptool, robotframework"
    doAptGet remove -y python-openssl
    
    doPipInstall pyopenssl
    doPipInstall setuptools 
    doPipInstall wheel
    doPipInstall robotframework
    doPipInstall robotframework-selenium2library
    doPipInstall robotframework-xvfb
    doPipInstall robotframework-sshlibrary
    doPipInstall robotremoteserver
    doPipInstall packaging
    installGeckoDriver
}

function gestionShutdownACPI()
{
    ciPrintMsgMachine "* gestionShutdownACPI"
    # important pour gestion shutdown depuis OpenNebula
    doAptGet install "$APT_OPTS" -y acpid
#    if command -v xfconf-query 2>/dev/null
#    then
#        DISPLAY=:0.0 xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/power-button-action -s 4
#    else
#        mkdir -p /home/pcadmin/.config/xfce4/xfconf/xfce-perchannel-xml
#        if [ -f "$VM_DIR_EOLE_CI_TEST/scripts/clientlinux/xfce-perchannel-xml" ]
#        then
#            /bin/cp -f "$VM_DIR_EOLE_CI_TEST/scripts/clientlinux/xfce-perchannel-xml" /home/pcadmin/.config/xfce4/xfconf/xfce-perchannel-xml
#        fi
#        chown -R pcadmin:pcadmin /home/pcadmin/.config
#    fi
#    chown -R pcadmin:pcadmin /home/pcadmin/.config
    gsettings list-recursively |grep power
    return 0
}

function downloadIfNeeded()
{
    local url="${1}"
    local fichier="${2}"
    
    if [ -f "$fichier" ] 
    then
        ciPrintMsgMachine "* === $fichier est présent"
    else
        ciPrintMsgMachine "* === download $fichier"
        wget --no-check-certificate "$url" -O "$fichier"
    fi        
}

function doUpgrade()
{
    ciPrintMsgMachine "* doUpgrade"
    if command -v systemctl >/dev/null 2>/dev/null
    then
        systemctl stop apt-daily >/dev/null
        systemctl disable apt-daily
    fi
    dpkg --configure -a 
    
    echo "* cat /etc/apt/sources.list"
    grep -v "^#" /etc/apt/sources.list
    
    waitAptStopped
    doAptGetWithRetry update
    doAptGetWithRetry -y --force-yes upgrade
    #-o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    doAptGetWithRetry -y --force-yes dist-upgrade
    
    echo "** doAptGet -y --purge autoremove"
    doAptGet -y --purge autoremove
    
}

function imposeHostUbuntu()
{
    if [ -f /etc/hostname ]
    then
        if [ "$(cat /etc/hostname)" == "eole" ]
        then
            echo "Impose ubuntu comme nom de machine"
            echo "ubuntu" >/etc/hostname
    
        fi
    fi

    echo "Impose ubuntu pour 127.0.1.1"
    sed -i '/127.0.1.1/s/eole/ubuntu/' /etc/hosts
}

function doUbuntu()
{
    ciPrintMsgMachine "* doUbuntu"
    waitAptStopped
    
    if [ "$LANG" == "C.UTF-8" ]
    then
        doAptGet install -y locales 
        echo "** ERREUR DE LANG / LOCALES ==> Change en FR"
        update-locale LANG="fr_FR.UTF-8" LANGUAGE="fr_FR"
        dpkg-reconfigure locales
    fi
    
    #removeServiceResolvConf
    removeServicesGenant
    bootEn1024x768
    doUpgrade
    removeServicesGenant
    imposeHostUbuntu
    sshAccesRoot
}

function installPip()
{
    ciPrintMsg "* Install Pip"
    
    if [ "$EOLE_CI_CYGWIN" = oui ]
    then
        easy_install-2.7 pip
    else
        if apt search python3-pip 
        then
            doAptGet install -y python3-pip
            # upgrade en 18 ==> traceback !
            #pip3 install pip --upgrade 
        else
            doAptGet install -y python-pip
            # upgrade en 18 ==> traceback !
            #doPipInstall pip --upgrade 
        fi
    fi    
}

function prepareMachineCtl()
{
    doAptGet install -y systemd-container qemu-utils
    ciExtendsLvm root 21G
    umount /var/lib/machines
    # accorde 10G !
    qemu-img resize -f raw /var/lib/machines.raw $((10*1024*1024*1024))
    mount -t btrfs -o loop /var/lib/machines.raw /var/lib/machines
    btrfs filesystem resize max /var/lib/machines
    btrfs quota disable /var/lib/machines
    machinectl pull-tar https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64-root.tar.xz
    #systemd-nspawn -M bionic-server-cloudimg-amd64-root
    #machinectl start bionic-server-cloudimg-amd64-root
    #machinectl login bionic-server-cloudimg-amd64-root
} 

function doUpdateForImage()
{
    case "$IMAGE_FINALE" in
        ubuntu*)
            doUbuntu
            return 0
            ;;
    
        robot*)
            installRobot
            ;;
    
        Windows*)
            ;;

        *)
            echo "IMAGE_FINALE = $IMAGE_FINALE : inconnu, doUpgrade"
            doUbuntu
            return 0
            ;;
    esac
}

