#!/bin/bash

VERSION_CIBLE="$1"
RESULTAT="0"

[ -f /root/.apres_upgrade ] && /bin/rm -f /root/.apres_upgrade

echo "* Etat du partitionnement"
df -h
echo

if [[ "$VERSION_CIBLE" = "2.7.0" ]] && [[ "$VM_MODULE" = "seth" ]]
then
    echo "* Export samba 'avant'"
    bash -x /mnt/eole-ci-tests/scripts/samba-eolecitest.sh --export-samba "avant"
fi

#if [[ "$VERSION_CIBLE" = "2.6.2" ]]
#then
#    echo "* HACK pour 2.6.1 RC "
#    sed -i -e "s/if data.lower().startswith(self.version) and '-' not in data:/if data.lower().startswith(self.version):/" /usr/share/eole/upgrade/Upgrade-Auto
#    sed -i -e "s/'2.6.0': ['scribe', 'horus', 'zephir', 'sphynx', 'eolebase'],/'2.6.2': ['scribe', 'horus', 'zephir', 'sphynx', 'eolebase', 'amon'],/" /usr/share/eole/upgrade/Upgrade-Auto
#    sed -i "s/and '-' not in data:/:/" /usr/share/eole/upgrade/Upgrade-Auto
#    echo "* cat /usr/share/eole/upgrade/Upgrade-Auto"
#    echo "*****************************************"
#    tail -n +240 /usr/share/eole/upgrade/Upgrade-Auto | head -n 30
#    echo "******************************************"
#fi
if [[ "$VERSION_CIBLE" = "2.9.0" ]]
then
    ciSignalWarning "* HACK pour 2.9.0 RC"
    sed -i -e "s/RC_VERSION = ''/RC_VERSION = 'rc'/" /usr/share/eole/upgrade/Upgrade-Auto
fi

echo "* change répertoire en /root"
cd /root || exit 1

echo "* do Upgrade-Auto "
ciMonitor upgrade_auto "$VERSION_CIBLE"
RETOUR=$?
echo "upgrade_auto ==> RETOUR=$RETOUR"
[[ "$RETOUR" -eq 0 ]] || RESULTAT=$RETOUR

echo "upgrade_auto OK, enregistre la nouvelle version du module"
echo "$VERSION_CIBLE" >/root/.apres_upgrade

#if [[ "$VERSION_CIBLE" = "2.6.1" ]]
#then
#    if [[ "$VM_MODULE" == "amon" ]] || [[ "$VM_MODULE" == "amonecole" ]]
#    then
#        ciCheckCreoled
#        echo "* HACK fin pour 2.6.1 RC "
#        apt-eole install eole-cntlm eole-proxy lightsquid libgd-gd2-perl libcgi-pm-perl libhtml-parser-perl
#    fi
#fi

if [[ "$VERSION_CIBLE" = "2.7.0" ]] && [[ "$VM_MODULE" = "seth" ]]
then
    echo "* Export samba 'apres'"
    bash -x /mnt/eole-ci-tests/scripts/samba-eolecitest.sh --export-samba "apres"
fi

exit $RESULTAT
