#!/bin/bash

GPO_NAME="$1"
EXPORT_TAR_GZ="$2"

# shellcheck disable=SC1091,SC1090
. /etc/eole/samba4-vars.conf
    
# shellcheck disable=SC1091,SC1090
. /usr/lib/eole/samba4.sh
samba_export_gpo "$GPO_NAME" "$EXPORT_TAR_GZ"
exit 0
