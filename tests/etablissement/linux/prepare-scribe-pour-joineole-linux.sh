#!/bin/bash

BOOTSTRAP_TO_USE="$1"
DISTRIB_PC="$2"
echo "BOOTSTRAP_TO_USE=BOOTSTRAP_TO_USE DISTRIB_PC=$DISTRIB_PC"

ciSetHttpAndHttpsProxy
# shellcheck disable=SC2154
proxy=$http_proxy
export proxy 

# activation du shell linux pour les utilisateurs
echo "* changement du shell linux"
activation_shell.py "admin,prof1,c31e1"

# vérification Bootstrap + update si besoin
bash check-bootstrap-upstream.sh "" "$BOOTSTRAP_TO_USE"

# surcharge installminion si besoin
bash create-installminion-alternate.sh "" "$proxy" "$DISTRIB_PC"

echo "* apt-cache policy python3-m2crypto"
apt-cache policy python3-m2crypto
echo "-----"