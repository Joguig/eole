#!/bin/bash

# shellcheck disable=1091
source /root/getVMContext.sh

if [[ -z "$1" ]] 
then
    ciPrintMsg "usage: check-iptables.sh <path-configuration> [<fichier reference>]"
    ciPrintMsg "   exemple1: check-iptables.sh /mnt/eole-ci-tests/configuration/etb1.amon/default"
    ciPrintMsg "   exemple2: check-iptables.sh default "
    ciPrintMsg "   exemple3: check-iptables.sh default iptableSiErreur"
    exit 1
fi

if [[ -z "$2" ]]
then
   MASTER=iptable
else
   MASTER=$2
fi

absolute=$(echo "$1" |cut -c 1)
if [[ "$absolute" == "/" ]]
then
    REFERENCE_FILE=$1/$MASTER
else
    if [[ -z "$VM_VERSIONMAJEUR" ]]
    then
        REFERENCE_FILE=/mnt/eole-ci-tests/configuration/$VM_MACHINE/$1/$MASTER
    else
        REFERENCE_FILE=/mnt/eole-ci-tests/configuration/$VM_MACHINE/$1-$VM_VERSIONMAJEUR/$MASTER
    fi
fi
export REFERENCE_FILE

ciCheckIptables "$1" "$MASTER"
