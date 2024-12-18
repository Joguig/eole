#!/bin/bash

RESULTAT="0"

if [[ ! -f /tmp/semaphore ]]
then
    case "$VM_MACHINE" in
        aca.dc1)
            echo "* Install eole-ad-dc-gpos"
            ciAptEole eole-ad-dc-gpos

            CONTAINER_ROOTFS=""
            EST_SCRIBE_AD=non
            ;;
        aca.scribe)
            echo "* Install eole-scribe-gpos"
            ciAptEole eole-scribe-gpos

            CONTAINER_ROOTFS="/var/lib/lxc/addc/rootfs"
            EST_SCRIBE_AD=oui
            ;;
        etb3.amonecole)
            echo "* Install eole-ad-dc-gpos"
            ciAptEole eole-ad-dc-gpos

            CONTAINER_ROOTFS="/var/lib/lxc/addc/rootfs"
            EST_SCRIBE_AD=oui
            ;;
      *)
            echo "Machine non gérée : $VM_MACHINE"
            ;;
    esac
    
    #shellcheck disable=SC1091,SC1090
    . "$CONTAINER_ROOTFS/etc/eole/samba4-vars.conf"
    BASEDN="DC=${AD_REALM//./,DC=}"
    echo "BASEDN: $BASEDN"

    OU_TEST="OU=TEST,$BASEDN"
    if [ "$EST_SCRIBE_AD" == oui ]
    then
        # pb expansion variable contenant des espaces
        lxc-attach -n addc -- samba-tool ou create "$OU_TEST"
    else
        samba-tool ou create "$OU_TEST" 
    fi
    
    echo "* définir les varaible GPO Proxy"
    # Adresse du serveur proxy pour les clients
    ciRunPython CreoleSet_Multi.py <<EOF
set gpo_proxy_active oui
set gpo_proxy_type "Manuel"
set gpo_proxy_ip 192.168.0.10 
set gpo_proxy_port 3128
set gpo_proxy_bypass "127.0.0.1/24,eole.lan"
EOF

    echo "* définir les varaible GPO Proxy"
    # Adresse du serveur proxy pour les clients
    ciRunPython CreoleSet_Multi.py <<EOF
set activer_eole_gpos oui
set eole_gpos_a_supprimer 0 "test"

set eole_gpos_a_charger 0 "eole_affichage_bginfo"
set eole_gpos_names 0 "eole_affichage_bginfo"
set eole_gpos_uo 0 "TEST"

set eole_gpos_a_charger 1 "eole_install_minion"
set eole_gpos_names 1 "eole_install_minion"
set eole_gpos_uo 1 "TEST"

set eole_gpos_names 2 "eole_script"
set eole_gpos_uo 2 "TEST"
EOF
    ciCheckExitCode $? "creolset"
    
    CreoleGet --list |grep "^gpo_"
    
    echo "* reconfigure"
    ciMonitor reconfigure
    echo "==> $?"
    
    touch /tmp/semaphore
fi

echo "RESULTAT=$RESULTAT"
exit "$RESULTAT"
