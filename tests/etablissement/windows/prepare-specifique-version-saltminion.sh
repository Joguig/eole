#!/bin/bash

function executeSurLeDC()
{
    SCRIPT="$1"
    if [ -n "${ROOTFS}" ] 
    then
        cat "$SCRIPT" >"${ROOTFS}${SCRIPT}"
    fi
    ${CMD} bash "$SCRIPT"
}

function injectExe()
{
    local EXE="$1"
    local MINION_VERSION="$2"
    local MINION_MAJOR="$3"

    if ! wget --progress=dot -e dotbytes=10M --no-check-certificate -O "${WORKSTATIONFS}/usr/share/eole/workstation/saltstack/$EXE" "http://eole.ac-dijon.fr/workstation/saltstack/$EXE"
    then
        if [ "x$MINION_VERSION" \< "x3006" ]
        then
            echo "ATTENTION: $EXE téléchargé depuis dépot Salt https://packages.broadcom.com/artifactory/saltproject-generic/windows/${MINION_VERSION}/$EXE"
            wget --progress=dot -e dotbytes=10M --no-check-certificate -O "${WORKSTATIONFS}/usr/share/eole/workstation/saltstack/$EXE" "https://packages.broadcom.com/artifactory/saltproject-generic/windows/${MINION_VERSION}/$EXE"
        else
            echo "ATTENTION: $EXE téléchargé depuis dépot Salt https://packages.broadcom.com/artifactory/saltproject-generic/windows/${MINION_VERSION}/$EXE"
            wget --progress=dot -e dotbytes=10M --no-check-certificate -O "${WORKSTATIONFS}/usr/share/eole/workstation/saltstack/$EXE" "https://packages.broadcom.com/artifactory/saltproject-generic/windows/${MINION_VERSION}/$EXE"
        fi
    fi
}

function injectVersionDansInstallMinionConf()
{
    MINION_VERSION="$1"
    MINION_MAJOR="$2"
    
    echo "* mise à jour installMinion.conf pour $MINION_MAJOR"
    cat >/tmp/installMinion.conf <<EOF
#debug=1
salt-version-amd64=${MINION_VERSION}-Py3-AMD64
salt-version-x86=${MINION_VERSION}-Py3-x86
EOF
    
    # télécharge les EXE
    EXE_AMD64="Salt-Minion-${MINION_VERSION}-Py3-AMD64-Setup.exe"
    injectExe "${EXE_AMD64}" "${MINION_VERSION}" "${MINION_MAJOR}"
    EXE_X86="Salt-Minion-${MINION_VERSION}-Py3-x86-Setup.exe"
    injectExe "${EXE_X86}" "${MINION_VERSION}" "${MINION_MAJOR}"
    
    # et inject installMinion.conf
    if [ ! -f "${WORKSTATIONFS}/usr/share/eole/workstation/installMinion.conf.sav" ]
    then
        echo "* sauvegarde installMinion.conf"
        cat "${WORKSTATIONFS}/usr/share/eole/workstation/installMinion.conf"  >"${WORKSTATIONFS}/usr/share/eole/workstation/installMinion.conf.sav"
        ciAfficheContenuFichier "${WORKSTATIONFS}/usr/share/eole/workstation/installMinion.conf"
    fi
    cat /tmp/installMinion.conf >"${WORKSTATIONFS}/usr/share/eole/workstation/installMinion.conf"
    ciAfficheContenuFichier "${WORKSTATIONFS}/usr/share/eole/workstation/installMinion.conf"
}

function injectScriptsFutur()
{
    # direct pour /salt/joineole
    cp -v "$VM_DIR_EOLE_CI_TEST/tests/etablissement/windows/installMinion-Futur.ps1" "${WORKSTATIONFS}/usr/share/eole/workstation/installMinion.ps1"
    
    # pour la GPO
    if [ -n "${ROOTFS}" ] 
    then
        cp -v "$VM_DIR_EOLE_CI_TEST/tests/etablissement/windows/installMinion-Futur.ps1" "${ROOTFS}/tmp/installMinion-Futur.ps1"
        cp -v "$VM_DIR_EOLE_CI_TEST/tests/etablissement/windows/ps-Futur.ps1" "${ROOTFS}/tmp/ps-Futur.ps1"
    fi
}

CHOIX_VERSION="$1"
UTILISE_GPO="$2"

# shellcheck disable=SC1091
. /root/getVMContext.sh NO_DISPLAY

ciSetHttpAndHttpsProxy
# shellcheck disable=SC2154
proxy=$http_proxy

ROOTFS=""
WORKSTATIONFS=""
CMD=""
if [ -d /var/lib/lxc/addc/rootfs ]
then
    ROOTFS="/var/lib/lxc/addc/rootfs"
    WORKSTATIONFS=""
    CMD="ssh addc "
fi

if [ -d /opt/lxc/addc/rootfs ]
then
    ROOTFS="/opt/lxc/addc/rootfs"
    WORKSTATIONFS=""
    CMD="ssh addc "
fi

cat >/tmp/cleanGpo.sh <<EOF 
source /etc/eole/samba4-vars.conf
source /usr/lib/eole/samba4.sh
samba_delete_gpo eole_script
samba_delete_gpo eole_script1 
EOF

export proxy
case "$CHOIX_VERSION" in
    ANCIENNE)
        MINION_VERSION=3004.1
        injectVersionDansInstallMinionConf "3004.1" "3004"
        ;;
    FUTUR)
        MINION_VERSION=3007.1
        injectVersionDansInstallMinionConf "3007.1" "3007"
        injectScriptsFutur
        ;;
    ACTUEL)
        ${CMD} bash /tmp/cleanGpo.sh
        # et, il suffit de faire un reconfigure
        if [ -f "${WORKSTATIONFS}/usr/share/eole/workstation/installMinion.conf.sav" ]
        then
            echo "* restore installMinion.conf"
            cat "${WORKSTATIONFS}/usr/share/eole/workstation/installMinion.conf.sav"  >"${WORKSTATIONFS}/usr/share/eole/workstation/installMinion.conf"
        fi
        ciMonitor reconfigure
        ciAfficheContenuFichier "${WORKSTATIONFS}/usr/share/eole/workstation/installMinion.conf"
        exit 0
        ;;
esac

if [ "$UTILISE_GPO" == UTILISE_LA_GPO ]
then
    # PS. eole_script doit exister !
    cat >/tmp/injectEoleScript1.sh <<EOF 
# création eole_script1 a partir d'eole_script et injection installMinion-Futur.ps1
rm -rf /usr/share/eole/gpo/eole_script1
mkdir /usr/share/eole/gpo/eole_script1
cd /usr/share/eole/gpo/eole_script1
tar xvf /usr/share/eole/gpo/eole_script.tar.gz
[ -f /tmp/installMinion-Futur.ps1 ] && cp /tmp/installMinion-Futur.ps1 ./policy/Machine/Scripts/Startup/installMinion.ps1.SAMBABACKUP
[ -f /tmp/ps-Futur.ps1 ] && cp /tmp/ps-Futur.ps1 ./policy/User/Scripts/Logon/ps.ps1.SAMBABACKUP
cd /tmp ||exit 1

# source context et fonctions
source /etc/eole/samba4-vars.conf
source /usr/lib/eole/samba4.sh

# désactive eole_script
samba_delete_gpo eole_script

# install eole_script1
samba_delete_gpo eole_script1 
samba_import_gpo eole_script1 /usr/share/eole/gpo/eole_script1 \${BASEDN}
EOF
    executeSurLeDC /tmp/injectEoleScript1.sh
fi

if [ "$UTILISE_GPO" == N_UTILISE_PAS_LES_GPO ]
then
    executeSurLeDC /tmp/cleanGpo.sh
fi



