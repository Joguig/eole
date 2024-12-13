#!/bin/bash

echo "* Création du fichier domaines_noauth_user"

echo "domaine1.fr
.domaine2.fr" > "$(CreoleGet container_path_proxy)/etc/squid/domaines_noauth_user"

exit 0
