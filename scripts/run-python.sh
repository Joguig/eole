#!/bin/bash

# shellcheck disable=SC1091,SC1090
source /root/getVMContext.sh

ciRunPython "$1" "$2" "$3" "$4" "$5"
