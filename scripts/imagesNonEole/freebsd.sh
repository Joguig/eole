#!/usr/local/bin/bash
# shellcheck disable=SC2034,SC2148,SC2009

# shellcheck disable=SC1091
source /dev/stdin </mnt/eole-ci-tests/scripts/imagesNonEole/functions.sh

echo "FRESHINSTALL_IMAGE=$FRESHINSTALL_IMAGE"
echo "DAILY_IMAGE=$DAILY_IMAGE"
IMAGE_FINALE=${1:-$DAILY_IMAGE}
IMAGE_SOURCE=${2:-$FRESHINSTALL_IMAGE}
echo "IMAGE_SOURCE=$IMAGE_SOURCE"
echo "IMAGE_FINALE=$IMAGE_FINALE"
    
ciPrintMsgMachine "* freebsd"

pkg upgrade -y

tagImage
exit 0