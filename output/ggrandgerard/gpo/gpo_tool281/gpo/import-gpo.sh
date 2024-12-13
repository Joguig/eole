#!/bin/bash

GPONAME="$1"
EXPORT_TAR_GZ="$2"
DN_TO_LINK="$3"

# shellcheck disable=SC1091,SC1090
. /etc/eole/samba4-vars.conf
    
# shellcheck disable=SC1091,SC1090
. /usr/lib/eole/samba4.sh

if samba_import_gpo "$GPONAME" "$EXPORT_TAR_GZ" "$DN_TO_LINK" >>/var/log/samba/import-gpo.log
then
    echo "* Import GPO $GPONAME : OK"
else
    echo "* Import GPO $GPONAME : Erreur ($?)"
fi
exit 0
