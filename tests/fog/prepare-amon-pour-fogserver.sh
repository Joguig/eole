#!/bin/bash

bash enregistrement-amon-si-besoin.sh "$1"
ciCheckExitCode $? "enregistrement-amon"

ciSignalHack "* ajout exception dans /etc/squid/domaines_noauth"
for exception in .saltproject.io packages.broadcom.com .saltstack.com .linuxmint.com .github.com .github-releases.githubusercontent.com .objects.githubusercontent.com
do
    if ! grep -q "$exception" /etc/squid/domaines_noauth 
    then
        echo "$exception à ajouter"
        echo "$exception" >>/etc/squid/domaines_noauth
    else
        echo "$exception déjà présente"
    fi
done

echo "* grep . /etc/squid/domaines_no*"
grep "\." /etc/squid/domaines_no*
 
echo "* systemctl restart squid.service"
systemctl restart squid.service

echo "* systemctl status squid.service"
systemctl --no-pager status squid.service

echo "* sauvegarde CA machine"
ciSauvegardeCaMachine
