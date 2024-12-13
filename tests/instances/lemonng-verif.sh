#!/bin/bash

if [ "$VM_VERSIONMAJEUR" != 2.8.1 ]; then
    echo "Patch Lemonldap non nécessaire en version $VM_VERSIONMAJEUR"
    exit 0
fi

if [ -f /var/lib/lxc/reseau/rootfs/usr/share/perl5/Lemonldap/NG/Portal/Auth/AD.pm ]; then
    filename="/var/lib/lxc/reseau/rootfs/usr/share/perl5/Lemonldap/NG/Portal/Auth/AD.pm"
else
    filename="/usr/share/perl5/Lemonldap/NG/Portal/Auth/AD.pm"
fi

echo "* test d'application du patch dans le fichier $filename"

if grep -q EOLE "$filename"; then
    echo OK
else
    echo "EOLE_CI_ALERTE: Patch non appliqué"
fi
