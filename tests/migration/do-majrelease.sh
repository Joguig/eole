#!/bin/bash

VERSION_CIBLE="$1"
RESULTAT="0"

[ -f /root/.apres_upgrade ] && /bin/rm -f /root/.apres_upgrade

if [[ "$VERSION_CIBLE" = "2.7.0" ]] && [[ "$VM_MODULE" = "seth" ]] 
then
    echo "* Export samba 'avant'"
    bash -x /mnt/eole-ci-tests/scripts/samba-eolecitest.sh --export-samba "avant"
fi

#if [[ "$VERSION_CIBLE" = "2.8.1" ]] 
#then
#    echo "* HACK pour 2.8.1 RC "
#    sed -i "s/option = ''/option = '-D'/" /usr/bin/Maj-Release
#fi

echo "* change répertoire en /root"
cd /root || exit 1

echo "* do Maj-Release "
ciMonitor maj_release "$VERSION_CIBLE"
RETOUR=$?
echo "maj_release ==> RETOUR=$RETOUR"
[[ "$RETOUR" -eq 0 ]] || RESULTAT=$RETOUR

echo "maj_release OK, enregistre la nouvelle version du module"
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
