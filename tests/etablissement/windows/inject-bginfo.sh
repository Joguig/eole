#!/bin/bash

# shellcheck disable=SC1091
source /etc/eole/samba4-vars.conf

cat >"/home/sysvol/${AD_REALM}/scripts/users/admin.txt" <<EOF
cmd,c:\util\bginfo.exe /NOLICPROMPT /POPUP,NOWAIT
EOF

#lecteur,N:,\\${AD_REALM}\NETLOGON

exit
