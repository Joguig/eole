#!/bin/bash

RESULTAT="0"

echo "* check avant démarrage"
ciSetHttpProxy
ciTestHttp
ciCheckCreoled
ciCheckAccesInternet

echo "* Maj-Auto ************ RC **********************"
VM_MAJAUTO=RC ciMonitor maj_auto_rc
RETOUR=$?
echo "Maj-Auto ==> RETVAL=$RETVAL"
[[ "$RETOUR" -eq 0 ]] ||  RESULTAT=$RETOUR

echo "* reconfigure"
ciMonitor reconfigure
RETOUR=$?
echo "reconfigure => $RETOUR"
[[ "$RETOUR" -eq 0 ]] ||  RESULTAT=$RETOUR

exit $RESULTAT
