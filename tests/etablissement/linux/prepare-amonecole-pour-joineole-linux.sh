#!/bin/bash

VERSIONMAJEUR="$1"
BOOTSTRAP_TO_USE="$2"
DISTRIB_PC="$3"

# sur le maitre
bash enregistrement-amon-si-besoin.sh "$VERSIONMAJEUR"
ciCheckExitCode $? "enregistrement-amon"

# activation du shell linux pour les utilisateurs
echo "* changement du shell linux"
activation_shell.py "admin,prof1,c31e1"

#echo "* exception Firewall"
#CreoleSet proxy_bypass_domain_eth2 "saltproject.io
#www.ac-dijon.fr
#www.anglaisfacile.com
#scribe.etb3.lan"
#ciCheckExitCode $? "creolset"
#
#echo "* reconfigure"
#ciMonitor reconfigure

# dans proxy
ciSignalHack "* ajout exception dans /opt/lxc/internet/rootfs/etc/squid/domaines_noauth"
for exception in .githubusercontent.com .github.com .linuxmint.com .debian.org .yarnpkg.com .nodesource.com  .launchpad.net .snapcraft.io
do
    if ! grep -q "$exception" /opt/lxc/internet/rootfs/etc/squid/domaines_noauth* 
    then
        echo "ATTENTION: $exception à ajouter dans domaines_noauth_user (comme si saisie dans EAD)"
        echo "$exception" >>/opt/lxc/internet/rootfs/etc/squid/domaines_noauth_user
    else
        echo "$exception déjà présente"
    fi
done

echo "* grep . /opt/lxc/internet/rootfs/etc/squid/domaines_no*"
grep "\." /opt/lxc/internet/rootfs/etc/squid/domaines_no*
 
echo "* ssh internet systemctl restart squid.service"
ssh internet systemctl restart squid.service

echo "* ssh internet systemctl status squid.service"
ssh internet systemctl --no-pager status squid.service

ciSetHttpAndHttpsProxy
bash create-installminion-alternate.sh /opt/lxc/addc/rootfs 10.3.2.2:3128 "$DISTRIB_PC"

bash check-bootstrap-upstream.sh /opt/lxc/addc/rootfs "$BOOTSTRAP_TO_USE"

echo "* apt-cache policy python3-m2crypto"
apt-cache policy python3-m2crypto
echo "-----"
