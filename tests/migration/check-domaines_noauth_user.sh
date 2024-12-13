#!/bin/bash

RESULTAT="0"

echo "* check domaines_noauth_user"

container_path_proxy="$(CreoleGet container_path_proxy)"

if [ ! -f "$container_path_proxy/etc/squid/domaines_noauth_user" ]; then
    echo "Impossible de trouver le fichier $container_path_proxy/etc/squid/domaines_noauth_user"
    RESULTAT="1"
fi
echo "Fichier $container_path_proxy/etc/squid/domaines_noauth_user"
cat "$container_path_proxy/etc/squid/domaines_noauth_user"
if [ ! -f "$container_path_proxy/var/lib/eole/domaines_noauth_user" ]; then
    echo "Impossible de trouver le fichier $container_path_proxy/var/lib/eole/domaines_noauth_user"
    RESULTAT="1"
fi
echo
echo "Fichier $container_path_proxy/var/lib/eole/domaines_noauth_user"
cat "$container_path_proxy/etc/squid/domaines_noauth_user"
if [ ! -f "$container_path_proxy/etc/guardian/common/domaines_noauth_user" ]; then
    echo "Impossible de trouver le fichier $container_path_proxy/etc/guardian/common/domaines_noauth_user"
    RESULTAT="1"
fi
echo
echo "Fichier $container_path_proxy/etc/guardian/common/domaines_noauth_user"
cat "$container_path_proxy/etc/guardian/common/domaines_noauth_user"

diff -q "$container_path_proxy/etc/squid/domaines_noauth_user" "$container_path_proxy/var/lib/eole/domaines_noauth_user" || RESULTAT="1"

diff -q "$container_path_proxy/etc/squid/domaines_noauth_user" "$container_path_proxy/etc/guardian/common/domaines_noauth_user" && RESULTAT="1"

echo "domaine1.fr
domaine2.fr" > /tmp/domaines_noauth_user

diff -q /tmp/domaines_noauth_user "$container_path_proxy/etc/guardian/common/domaines_noauth_user" || RESULTAT="1"

rm /tmp/domaines_noauth_user

exit $RESULTAT
