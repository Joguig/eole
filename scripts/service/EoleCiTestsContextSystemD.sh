#!/bin/bash -x

(
echo "Start Context début... " 

# shellcheck disable=SC1091
source /root/getVMContext.sh 
ciContextualizeMe 
) >/var/log/EoleCiTestsContext.log 2>&1 
CDU=$?

exit 0
