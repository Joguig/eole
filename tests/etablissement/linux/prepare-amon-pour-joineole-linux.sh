#!/bin/bash

bash enregistrement-amon-si-besoin.sh "$1"
ciCheckExitCode $? "enregistrement-amon"

echo "* exception Firewall"
CreoleSet proxy_bypass_domain_eth2 "saltproject.io
www.ac-dijon.fr
www.anglaisfacile.com
scribe.etb1.lan"
ciCheckExitCode $? "creolset"

ciSignalHack "* ajout exception dans /etc/squid/domaines_noauth"
#NB : nécessite a minima un reload de squid
for exception in .githubusercontent.com  .github.com .linuxmint.com  .debian.org .yarnpkg.com .nodesource.com .launchpad.net .snapcraft.io
do
    if ! grep -q "$exception" /etc/squid/domaines_noauth* 
    then
        echo "ATTENTION: $exception à ajouter dans domaines_noauth_user (comme si saisie dans EAD)"
        echo "$exception" >>/etc/squid/domaines_noauth_user
    else
        echo "$exception déjà présente"
    fi
done

echo "* grep . /etc/squid/domaines_no*"
grep "\." /etc/squid/domaines_no*

echo "* reconfigure"
ciMonitor reconfigure

echo "* systemctl status squid.service"
systemctl --no-pager status squid.service

echo "* clamconf --non-default"
clamconf --non-default

if pgrep clamd
then
    echo "clamd présent!"
else
    echo "ATTENTION: clamd ne fonctionne pas !" 
    echo "* clamd --debug --config-file=/etc/clamav/clamd.conf"
    clamd --debug --config-file=/etc/clamav/clamd.conf
fi

echo "* Diff template Eole / default 103"
grep -v "^# " </etc/clamav/clamd.conf |sort|uniq >/tmp/clamd-099.conf
clamconf -g clamd.conf | grep -v "^# " |sort|uniq >/tmp/clamd-103.conf 
echo "-----"
diff --side-by-side  /tmp/clamd-099.conf /tmp/clamd-103.conf
echo "-----"
