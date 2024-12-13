#!/bin/bash
# shellcheck disable=SC2035

apt-eole install eole-bareos eole-bareos-mysql eole-bareoswebui

ciPrintDebug "ciInstance serveur-bareos"
ciConfigurationEole instance serveur-bareos
RETOUR="$?"
ciPrintDebug "ciInstance serveur-bareos ==> $RETOUR"

exit 0