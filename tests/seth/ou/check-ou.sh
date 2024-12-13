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

function createPseudoComputer()
{
    local PC="$1"
    local OS="$2"
    local VERSION="$3"
    
    doSambaTool computer delete "${PC}" 2>/dev/null
    doSambaTool computer create "${PC}"
    if [ -n "$OS" ]
    then
        OS_BASE64=$(printf '%s\n' "$OS" | base64)
        doLdbModify -v <<EOF
dn: CN=${PC},CN=Computers,$BASEDN
changetype: modify
add: operatingSystem
operatingSystem: $OS_BASE64
add: operatingSystemVersion
operatingSystemVersion: $VERSION
EOF
    fi
}

function checkClassifierUserOU()
{
    local USERNAME="$1"
    local DN_CLASSIFIE="$2"

    (doSambaTool user show "$USERNAME" )>/tmp/sortie_console 2>/dev/null
    if grep -q "dn: $DN_CLASSIFIE" /tmp/sortie_console
    then
        echo "$USERNAME: $DN_CLASSIFIE ==> ok"
    else
        echo "$USERNAME: $DN_CLASSIFIE ==> ERREUR:"
        grep dn: /tmp/sortie_console
        RESULTAT=1
    fi
}

function checkClassifierComputerOU()
{
    local COMPUTERNAME="$1"
    local DN_CLASSIFIE="$2"

    (doSambaTool computer show "$COMPUTERNAME" )>/tmp/sortie_console 2>/dev/null
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

function doPrepareConfigEol()
{
    echo "* doPrepareConfigEol ..."

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
set ad_ou_classifier 4 "aucun"
set ad_ou_pattern 4 ""
#
set ad_ou_names 5 "Equipements fixes/Ordinateurs du Domaine"
set ad_ou_classifier 5 "ordinateur"
set ad_ou_pattern 5 "DESKTOP-"
#
set ad_ou_names 6 "Equipements mobiles/Ordinateurs du Domaine"
set ad_ou_classifier 6 "ordinateur"
set ad_ou_pattern 6 "LAPTOP-"
#
set ad_ou_names 7 "CLASSE MOBILE 1/Equipements mobiles/Ordinateurs du Domaine"
set ad_ou_classifier 7 "aucun"
set ad_ou_pattern 7 ""
#
set ad_ou_names 8 "CLASSE MOBILE 2/Equipements mobiles/Ordinateurs du Domaine"
set ad_ou_classifier 8 "aucun"
set ad_ou_pattern 8 ""
#
set ad_ou_names 9 "SALLE DE COURS/Equipements fixes/Ordinateurs du Domaine"
set ad_ou_classifier 9 "ordinateur_par_classe"
set ad_ou_pattern 9 "(SVT|HIS|TEST)"
#
set ad_ou_names 10 "SALLE DES PROFESSEURS/Equipements fixes/Ordinateurs du Domaine"
set ad_ou_classifier 10 "aucun"
set ad_ou_pattern 10 ""
#
set ad_ou_names 11 "MULTIMEDIA/Equipements fixes/Ordinateurs du Domaine"
set ad_ou_classifier 11 "aucun"
set ad_ou_pattern 11 ""
#
set ad_ou_names 12 "TECHNOLOGIE/Equipements fixes/Ordinateurs du Domaine"
set ad_ou_classifier 12 "ordinateur"
set ad_ou_pattern 12 "TEC"
#
set ad_ou_names 13 "CDI/Equipements fixes/Ordinateurs du Domaine"
set ad_ou_classifier 13 "ordinateur"
set ad_ou_pattern 13 "CDI"
#
set ad_ou_names 14 "ULIS/Equipements fixes/Ordinateurs du Domaine"
set ad_ou_classifier 14 "ordinateur"
set ad_ou_pattern 14 "ULIS"
#
set ad_ou_names 15 "SEGPA/Equipements fixes/Ordinateurs du Domaine"
set ad_ou_classifier 15 "ordinateur"
set ad_ou_pattern 15 "SEGPA"
#
set ad_ou_names 16 "UPI/Equipements fixes/Ordinateurs du Domaine"
set ad_ou_classifier 16 "ordinateur"
set ad_ou_pattern 16 "UPI"
#
set ad_ou_names 17 "Power Users/Utilisateurs du Domaine"
set ad_ou_classifier 17 "membreDe"
set ad_ou_group 17 "Domain Users"
set ad_ou_pattern 17 "Test "
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
}

function doPrepare()
{
    if [[ ! -f /tmp/semaphore ]]
    then
        ciMajAuto
        
        echo "* Install eole-ad-dc-ou"
        ciAptEole eole-ad-dc-ou
       
        echo "* définit de les OU dans genconfig"
        doPrepareConfigEol
        
        echo "* reconfigure"
        ciMonitor reconfigure
        echo "==> $?"
        
        touch /tmp/semaphore
    fi
    
    echo "Prépare Computers"
    createPseudoComputer TEST01 ""
    createPseudoComputer TEST02 ""
    createPseudoComputer SRV02 "Windows Server" "2012 (9600)"
    createPseudoComputer CDI01 "Windows 7" "7 (7600)"
    createPseudoComputer CDI02 "Windows 7" "7 (7600)"
    createPseudoComputer DESKTOP-01 "Windows 10 Éducation N" "10.0 (19042)"
    createPseudoComputer DESKTOP-02 "Windows 10 Éducation N" "10.0 (19042)"
    createPseudoComputer LAPTOP-01 "Windows 10 Pro" "10.0 (19042)"
    createPseudoComputer LAPTOP-02 "Windows 10 Pro" "10.0 (19042)"
    createPseudoComputer SVT02 "Windows 10 Éducation N" "10.0 (19042)"
}

function doTest()
{
    echo "Run classifier"
    DEBUG=1 bash /usr/share/eole/postservice/24-ad-ou reconfigure
}

function doCheck()
{
    echo "Test classifier"
    RESULTAT="0"
    
    # check non déplacé
    checkClassifierUserOU "Administrator"   "CN=Administrator,CN=Users,$BASEDN" 
    
    # check déplacé dans Professeurs car dans group professeurs
    checkClassifierUserOU "prof1"           "CN=prof1,OU=Professeurs,OU=Utilisateurs du Domaine,$BASEDN" 
    
    if [ "$EST_SCRIBE_AD" == oui ]
    then
        # check déplacés dans Eleves+Niveau+Classe car dans group Eleves + classifier membreDeENT
        checkClassifierUserOU "c31e1"           "CN=c31e1,OU=c31,OU=3eme,OU=Eleves,OU=Utilisateurs du Domaine,$BASEDN" 
        checkClassifierUserOU "prenom.eleve112" "CN=prenom.eleve112,OU=c31,OU=3eme,OU=Eleves,OU=Utilisateurs du Domaine,$BASEDN" 
    else
        # check déplacés dans Eleves car dans group Eleves
        checkClassifierUserOU "c31e1"           "CN=c31e1,OU=Eleves,OU=Utilisateurs du Domaine,$BASEDN" 
    fi
    
    # check déplacés dans 'CDI/Equipements fixe' car ordinateur + pattern 'CDI'
    checkClassifierComputerOU "CDI01"       "CN=CDI01,OU=CDI,OU=Equipements fixes,OU=Ordinateurs du Domaine,$BASEDN"
    
    # check déplacés dans 'Equipements fixe' car ordinateur + pattern 'DESKTOP*'
    checkClassifierComputerOU "DESKTOP-01"  "CN=DESKTOP-01,OU=Equipements fixes,OU=Ordinateurs du Domaine,$BASEDN"
    
    # check déplacés dans 'Equipements mobile' car ordinateur + pattern 'LAPTOP*'
    checkClassifierComputerOU "LAPTOP-01"   "CN=LAPTOP-01,OU=Equipements mobiles,OU=Ordinateurs du Domaine,$BASEDN"
    
    # check non déplacé
    checkClassifierComputerOU "SRV02"       "CN=SRV02,CN=Computers,$BASEDN"
    
    # check déplacés dans 'SALLE DE COURS' car ordinateur + auto classement par salle (OU=SVT) avec le pattern regex (SVT) 
    checkClassifierComputerOU "SVT02"       "CN=SVT02,OU=SVT,OU=SALLE DE COURS,OU=Equipements fixes,OU=Ordinateurs du Domaine,$BASEDN"

    echo "RESULTAT=$RESULTAT"
}

function doMain()
{
    doPrepare
    doTest
    doCheck
    
    echo "Non Classifié ==============="
    doSambaTool ou listobjects "CN=Users,$BASEDN" --full-dn
    doSambaTool ou listobjects "CN=Computers,$BASEDN" --full-dn
    echo "==============="
    
}

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
    exit "$RESULTAT"
fi

