#!/bin/bash -x

# shellcheck disable=SC1091
source /root/getVMContext.sh
ciContextualizeMe 
CDU=$?

exit 0
