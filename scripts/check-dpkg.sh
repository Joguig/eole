#!/bin/bash

# shellcheck disable=SC1091,SC1090
source /root/getVMContext.sh

if [[ "$1" = "--help" ]] 
then
    ciPrintMsg "usage: check-dpkg.sh [<action:>]"
    ciPrintMsg "   exemple: check-dpkg.sh "
    ciPrintMsg "   exemple: check-dpkg.sh ERREUR_SI_DIFFERENT"
    exit 1
fi

ciCheckDpkg "$2"

