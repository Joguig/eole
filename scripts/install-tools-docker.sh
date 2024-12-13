#!/bin/bash

if [ "$(lsb_release -rs)x" \> "18.00x" ]
then
    bash "$VM_DIR_EOLE_CI_TEST/scripts/install-tools-docker-focal.sh"
else
	bash "$VM_DIR_EOLE_CI_TEST/scripts/install-tools-docker-bionic.sh"
fi
