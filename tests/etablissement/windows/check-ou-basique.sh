#!/bin/bash

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

function doLdbsearch()
{
    if [ "$EST_SCRIBE_AD" == oui ]
    then
        # pb expansion variable contenant des espaces
        lxc-attach -n addc -- ldbsearch -H /var/lib/samba/private/sam.ldb "$@"
    else
        ldbsearch -H /var/lib/samba/private/sam.ldb "$@" 
    fi
}

function checkClassifierUserOU()
{
    local USERNAME="$1"
    local DN_CLASSIFIE="$2"

    (doSambaTool user show "$USERNAME" )>/tmp/sortie_console
    if grep -q "dn: $DN_CLASSIFIE" /tmp/sortie_console
    then
        echo "$USERNAME: $DN_CLASSIFIE ==> ok"
    else
        echo "===================================================="
        echo "$USERNAME: $DN_CLASSIFIE ==> ERREUR:"
        grep dn: /tmp/sortie_console
        #sed 's/^/  /' /tmp/sortie_console
        echo "===================================================="
        RESULTAT=1
    fi
}

function checkClassifierComputerOU()
{
    local COMPUTERNAME="$1"
    local DN_CLASSIFIE="$2"

    (doSambaTool computer show "$COMPUTERNAME" )>/tmp/sortie_console
    if grep -q "dn: $DN_CLASSIFIE" /tmp/sortie_console 
    then
        echo "$COMPUTERNAME: $DN_CLASSIFIE ==> ok"
    else
        echo "===================================================="
        echo "$COMPUTERNAME: $DN_CLASSIFIE ==> ERREUR:"
        sed 's/^/  /' /tmp/sortie_console
        echo "===================================================="
        RESULTAT=1
    fi
}

function doPrepare()
{
    if [[ -f /tmp/semaphore ]]
    then
        return
    fi

    ciMajAuto

    echo "* Install eole-ad-dc-ou"
    ciAptEole eole-ad-dc-ou

    if ciVersionMajeurEgal "2.8.1"
    then
        ciSignalAttention "* CreoleSet veyon_computer_organization_type ou"
        CreoleSet veyon_computer_organization_type ou
    fi
    
    echo "* Ajout OU et Regles de classification ..."
    CreoleSet activer_ad_ou --default

ciRunPython CreoleSet_Multi.py <<EOF
set activer_ad_ou oui
set activer_ad_ou_classifier oui
#
set ad_ou_names 0 "Utilisateurs du Domaine"
set ad_ou_classifier 0 "aucun"
set ad_ou_pattern 0 ""
#
set ad_ou_names 1 "Professeurs/Utilisateurs du Domaine"
set ad_ou_classifier 1 "membreDe"
set ad_ou_group 1 "professeurs"
set ad_ou_pattern 1 ""
#
set ad_ou_names 2 "Administratifs/Utilisateurs du Domaine"
set ad_ou_classifier 2 "membreDe"
set ad_ou_group 2 "administratifs"
set ad_ou_pattern 2 ""
#
set ad_ou_names 3 "Eleves/Utilisateurs du Domaine"
set ad_ou_classifier 3 "membreDe"
set ad_ou_group 3 "eleves"
set ad_ou_pattern 3 ""
#
set ad_ou_names 4 "Ordinateurs du Domaine"
set ad_ou_classifier 4 "ordinateur"
set ad_ou_pattern 4 "PC-"
#
EOF
ciCheckExitCode $? "CreoleSet_Multi OU"

if [ "$VM_MACHINE" == "aca.scribe" ]
then
    ciRunPython CreoleSet_Multi.py <<EOF
set ad_ou_names 3 "Eleves/Utilisateurs du Domaine"
set ad_ou_classifier 3 "membreDeENT"
set ad_ou_group 3 "eleves"
set ad_ou_pattern 3 ""
EOF
    ciCheckExitCode $? "CreoleSet_Multi OU"
fi

    echo "* reconfigure"
    ciMonitor reconfigure
    echo "==> $?"
        
    touch /tmp/semaphore
}

function doTest()
{
    echo "Run classifier"
    DEBUG=2 bash /usr/share/eole/postservice/24-ad-ou reconfigure
}

function doCheck()
{
    echo "Test classifier"
    RESULTAT="0"
    
    # check non déplacé
    checkClassifierUserOU "Administrator"   "CN=Administrator,CN=Users,$BASEDN" 
    
    # check déplacé dans Professeurs car dans group professeurs
    checkClassifierUserOU "prof1"           "CN=prof1,OU=Professeurs,OU=Utilisateurs du Domaine,$BASEDN" 
    
    # check déplacés dans Eleves car dans group Eleves
    checkClassifierUserOU "c31e1"           "CN=c31e1,OU=Eleves,OU=Utilisateurs du Domaine,$BASEDN" 
    
    (doLdbsearch -b "CN=Computers,$BASEDN" "(&(objectClass=computer)(!(isCriticalSystemObject=TRUE)))" dn) |grep dn:
    #checkClassifierComputerOU "CDI01"       "CN=CDI01,OU=CDI,OU=Equipements fixes,OU=Ordinateurs du Domaine,$BASEDN"
    
    echo "RESULTAT=$RESULTAT"
}

function doMain()
{
    doPrepare
    doTest
    doCheck
}

if ciVersionMajeurAvant "2.7.2"
then
    echo "pas d'eole-ad-dc-ou avant 2.7.2" 
    exit 0
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
BASEDN="DC=${AD_REALM//./,DC=}"
echo "BASEDN: $BASEDN"

# execute main si non sourcé
if [[ "${BASH_SOURCE[0]}" == "$0" ]]
then
    doMain "$@"
    #exit "$RESULTAT"
    exit 0
fi

