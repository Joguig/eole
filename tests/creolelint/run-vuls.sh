#!/bin/bash

IP_TO_SCAN="$1"
#VULS_USER='vuls'
#FROM_DATE='2017'

cd "$HOME" || exit 1

echo  "
[servers]

[servers.${IP_TO_SCAN}]
user         = \"root\"
host         = \"${IP_TO_SCAN}\"
port         = \"22\"
#keyPath      = \"/home/vuls/id_rsa_one\"
" > ~/config.toml
EOF



