#!/bin/bash

function doDebug()
{
    [[ -n "$DEBUG" ]] && [[ "$DEBUG" -gt 1 ]] && echo "$@"
}

function doDebug2()
{
    [[ -n "$DEBUG" ]] && [[ "$DEBUG" -gt 2 ]] && echo "$@"
}

function doSambaTool()
{
    if [ "$EST_SCRIBE_AD" == oui ]
    then
        # pb expansion variable contenant des espaces
        lxc-attach -n addc -- samba-tool "$@"
    else
        samba-tool "$@" 
    fi
}

function doLdbSearch()
{
    if [ "$EST_SCRIBE_AD" == oui ]
    then
        # pb expansion variable contenant des espaces
        lxc-attach -n addc -- ldbsearch -H /var/lib/samba/private/sam.ldb "$@"
    else
        ldbsearch -H /var/lib/samba/private/sam.ldb "$@" 
    fi
}

function doLdbModify()
{
    if [ "$EST_SCRIBE_AD" == oui ]
    then
        # pb expansion variable contenant des espaces
        lxc-attach -n addc -- ldbmodify -H /var/lib/samba/private/sam.ldb "$@"
    else
        ldbmodify -H /var/lib/samba/private/sam.ldb "$@"
    fi
}

function doMain()
{
    local ACCOUNT="${1}"
    if [ -z "$ACCOUNT" ]
    then
        echo "usage: $0 <ACCOUNT> <location>"
        exit 1
    fi

    if [ -d /var/lib/lxc/addc/rootfs ]
    then
        # cas ScribeAD
        CONTAINER_ROOTFS="/var/lib/lxc/addc/rootfs"
        EST_SCRIBE_AD=oui
    else
        CONTAINER_ROOTFS=""
        EST_SCRIBE_AD=non
    fi
    #shellcheck disable=SC1091,SC1090
    . "$CONTAINER_ROOTFS/etc/eole/samba4-vars.conf"
    
    if [ "${AD_SERVER_ROLE}" != "controleur de domaine" ]
    then
        echo "Pas de gestion d'UO sur les serveurs membres"
        exit 0
    fi
    
    if [ "${AD_ADDITIONAL_DC}" != "non" ]
    then
        echo "Cette commande ne doit pas être éxecutée sur les Dc Secondaires."
        exit 0
    fi
    

    if ! >/tmp/fichead.txt EDITOR="cat" doSambaTool user edit "${ACCOUNT}"
    then
        return 1
    fi
    DN_DN="$(awk -F: '/dn:/ {print $2;}' < /tmp/fichead.txt)" 
    DN="${DN_DN#* }"
    doLdbModify -v <<EOF
dn: ${DN}
changetype: modify
delete: homeDrive
-
delete: homeDirectory
-
delete: profilePath
-
EOF

}

# execute main si non sourcé
if [[ "${BASH_SOURCE[0]}" == "$0" ]]
then
   doMain "$@"
fi
