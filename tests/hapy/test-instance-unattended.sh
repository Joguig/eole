#!/bin/bash

CONFIGURATION=default
export CONFIGURATION

ciMajAuto
ciCheckExitCode $? "ciConfigurationEole: ciMajAuto"

ciCheckCreoled

ciGetConfigurationFromZephir
ciCheckExitCode $? "ciConfigurationEole: ciGetConfigurationFromZephir"

# obligatorie car enregistrement zephir repositionnne les sources list !
ciMajAutoSansTest
ciCheckExitCode $? "ciConfigurationEole: ciMajAutoSansTest"

echo "* Get Id Zephir $VM_MACHINE ${VM_VERSIONMAJEUR} default"
ID=$(VM_MACHINE=$VM_MACHINE CONFIGURATION=default ciGetIdZephir)
echo "* id = $ID"

# ciInstance
echo "* instance-unattended"
/usr/share/eole/sbin/instance-unattended --store-passwords --file-passwords /tmp/secret.pwd
ciCheckExitCode $? "ciConfigurationEole: ciInstance"

echo "* check /tmp/secret.pwd "
cat /tmp/secret.pwd
