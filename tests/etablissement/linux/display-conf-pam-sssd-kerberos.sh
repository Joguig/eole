#!/bin/bash

# shellcheck disable=SC1091,SC1090
. /root/getVMContext.sh NO_DISPLAY

ls -l /etc/pam.d/
find /etc/pam.d/ |while read -r f
do 
   echo "#----------------------"
   echo "cat $f"
   grep -v "^#" "$f" |grep -v "^$" 
   echo "#----------------------"
done 

ciAfficheContenuFichier /etc/nsswitch.conf
ciAfficheContenuFichier /etc/realmd.conf
ciAfficheContenuFichier /etc/sssd/sssd.conf
ciAfficheContenuFichier /etc/security/pam_mount.conf.xml
rgrep sss /etc/pam.d/ 

exit 0
