#!/bin/bash

#VM_VERSIONMAJEUR_CIBLE="$1" ## VM_VERSIONMAJEUR_CIBLE appears unused.
login="$2"

echo "************************************************************"
echo "* Test ACL"
echo "************************************************************"
cd /home || exit 1
echo "ACL du fichier /home/workgroups/professeurs/Administration.url"
getfacl workgroups/professeurs/Administration.url
getfacl workgroups/professeurs/Administration.url |grep -q 10001 && ciSignalAlerte "ACL KO"
cd - || exit 1

echo "************************************************************"
echo "* Vérification des répertoires"
echo "************************************************************"
home="/home/${login:0:1}/$login"
adhome="/home/adhomes/$login"
ls -ld "$home"
if [ -L "$home" ]
then
    ciPrintMsgMachine "$home est bien un lien"
else
    ciSignalAlerte "$home n'est pas un lien symbolique"
fi
ls -ld "$adhome"
if [ -d "$adhome" ] && [ ! -L "$adhome" ]
then
    ciPrintMsgMachine "$adhome est bien un répertoire"
else
    ciSignalAlerte "$adhome n'est pas un répertoire"
fi

if ciVersionMajeurAPartirDe "2.8."
then
    echo "************************************************************"
    echo "* Vérification SASL"
    echo "************************************************************"
    REALM=$(CreoleGet ad_domain)
    entry=$(ldapsearch -x -D cn=reader,o=gouv,c=fr -w "$(cat /root/.reader)" uid="$login" userPassword | grep ^userPassword)
    if [ "$(echo "$entry" | cut -d' ' -f 2 | base64 -d)" = "{SASL}$login@$REALM" ]
    then
        ciPrintMsgMachine "Redirection SASL : OK"
    else
        ciSignalAlerte "Redirection SASL :KO"
        echo "$entry"
    fi
fi
