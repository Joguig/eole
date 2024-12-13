#!/bin/bash

MY_ABSOLUTEPATH=$(realpath "$0")
MY_PARENT_PATH=$(dirname "$MY_ABSOLUTEPATH")

CONFIGURATION=autodeploy
export CONFIGURATION

"$MY_PARENT_PATH/inject-automatisation.sh"
ciCheckExitCode $? "$0 : injection"

echo "***************************************************"
echo "/usr/share/eole/postservice/92-add-markets instance"
bash /usr/share/eole/postservice/92-add-markets instance

echo "***************************************************"
echo "/usr/share/eole/postservice/92-add-scripts instance"
bash /usr/share/eole/postservice/92-add-scripts instance

echo "***************************************************"
echo "/usr/share/eole/postservice/93-vm_deploy reconfigure"
bash /usr/share/eole/postservice/93-vm_deploy reconfigure

echo "* ls -l /var/log/hapy-deploy"
ls -l /var/log/hapy-deploy

