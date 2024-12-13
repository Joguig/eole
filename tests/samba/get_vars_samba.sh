#!/bin/bash

echo "** determine versions pour $VM_VERSIONMAJEUR"
BASE=$HOME/git
case "$VM_VERSIONMAJEUR" in
    2.5.2)
        EOLE_VERSION=2.5
        SAMBA_VERSION=4.5
        DEBIAN_VERSION=strech
        ;;

    2.6.0)
        EOLE_VERSION=2.6
        SAMBA_VERSION=4.7
        DEBIAN_VERSION=strech
        ;;

    2.6.1)
        EOLE_VERSION=2.6
        SAMBA_VERSION=4.7
        DEBIAN_VERSION=strech
        ;;
        
    2.6.2)
        EOLE_VERSION=2.6.2
        SAMBA_VERSION=4.7
        DEBIAN_VERSION=strech
        ;;

    2.7.0)
        EOLE_VERSION=2.7.0
        SAMBA_VERSION=4.9
        DEBIAN_VERSION=buster-security
        ;;

    2.7.1)
        EOLE_VERSION=2.7.0
        SAMBA_VERSION=4.9
        DEBIAN_VERSION=buster-security
        ;;

    2.7.2)
        EOLE_VERSION=2.7.0
        SAMBA_VERSION=4.9
        DEBIAN_VERSION=buster-security
        ;;

    *)
        EOLE_VERSION=2.7.0
        SAMBA_VERSION=4.9
        DEBIAN_VERSION=buster-security
        ;;
esac

echo "  BASE=$BASE"
echo "  VM_VERSIONMAJEUR=$VM_VERSIONMAJEUR"
echo "  EOLE_VERSION=$EOLE_VERSION"
echo "  SAMBA_VERSION=$SAMBA_VERSION"
echo "  DEBIAN_VERSION=$DEBIAN_VERSION"

