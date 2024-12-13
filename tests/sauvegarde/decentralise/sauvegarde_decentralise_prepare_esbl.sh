#!/bin/bash
# shellcheck disable=SC2035

ciInstallBareos

ciPrintDebug "ciInstance clientbareos"
ciConfigurationEole instance clientbareos
RETOUR="$?"
ciPrintDebug "ciInstance clientbareos ==> $RETOUR"

exit 0