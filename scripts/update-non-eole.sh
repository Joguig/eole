#!/bin/bash
# shellcheck disable=SC2034,SC2148,SC2009

# shellcheck disable=SC1091
source /dev/stdin </mnt/eole-ci-tests/scripts/imagesNonEole/functions.sh
/bin/bash /mnt/eole-ci-tests/scripts/service/CheckUpdate.sh
# shellcheck disable=SC1091
source /root/getVMContext.sh NO_DISPLAY
echo "FRESHINSTALL_IMAGE=$FRESHINSTALL_IMAGE"
echo "DAILY_IMAGE=$DAILY_IMAGE"
IMAGE_FINALE=${1:-$DAILY_IMAGE}
IMAGE_SOURCE=${2:-$FRESHINSTALL_IMAGE}
echo "IMAGE_SOURCE=$IMAGE_SOURCE"
echo "IMAGE_FINALE=$IMAGE_FINALE"
export DEBIAN_FRONTEND=noninteractive

if [ -f "/etc/lsb-release" ]
then
    # shellcheck disable=SC1091
    source /etc/lsb-release
    VM_BASE_IMAGE="ubuntu"
else
    if [ -f "/etc/debian_version" ]
    then
        VM_BASE_IMAGE="debian"
    else
        if [ "$EOLE_CI_CYGWIN" = non ]
        then
            ciPrintMsg "ni ubuntu, ni debian, ni windows, donc non géré ! "
            exit 0
        fi
    fi
fi

doUpdateForImage
exit $?