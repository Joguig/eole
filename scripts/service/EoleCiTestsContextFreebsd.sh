#!/bin/bash

(
echo "Start Context début... " 

# shellcheck disable=SC1091
source /root/EoleCiFunctions.sh
ciGetContext 
ciDisplayContext 
ciContextualizeMe 
) >/var/log/EoleCiTestsContext.log 2>&1 
CDU=$?

exit 0
