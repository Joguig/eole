#!/bin/bash

if [ ! -f /root/.ssh/id_rsa ]
then
    echo "* creation SSHKeys root / eoleone "
    ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ""
    
    echo "* update 'eoleone' avec la clé ssh root"
    echo "SSH_PUBLIC_KEY=\"$(cat /root/.ssh/id_rsa.pub)\"" >/tmp/sshkey
    oneuser update eoleone /tmp/sshkey --append
    oneuser update oneadmin /tmp/sshkey --append
fi

if [ -f "$VM_DIR_EOLE_CI_TEST/tests/hapy/scripts/deploy-auto.py" ]
then
    ciSignalHack "Injection deploy-auto.py dans /usr/share/eole/sbin/deploy-auto"
    cp -vf "$VM_DIR_EOLE_CI_TEST/tests/hapy/scripts/deploy-auto.py" /usr/share/eole/sbin/deploy-auto
    ciCheckExitCode $? "$0 : cp"
fi

ciSignalHack "Injection tests/hapy/provisionning/ dans /usr/share/eole/hapy-deploy/scripts"
cp -vf "$VM_DIR_EOLE_CI_TEST/tests/hapy/provisionning/"*.sh /usr/share/eole/hapy-deploy/scripts/
ciCheckExitCode $? "$0 : cp"

if [ -f "$VM_DIR_EOLE_CI_TEST/tests/hapy/postservice/92-add-markets.sh" ]
then
    ciSignalHack "Injection tests/hapy/postservice/92-add-markets.sh dans /usr/share/eole/postservice"
    cp -vf "$VM_DIR_EOLE_CI_TEST/tests/hapy/postservice/92-add-markets.sh" /usr/share/eole/postservice/92-add-markets
    ciCheckExitCode $? "$0 : cp"
fi
if [ -f "$VM_DIR_EOLE_CI_TEST/tests/hapy/postservice/92-add-scripts.sh" ]
then
    ciSignalHack "Injection tests/hapy/postservice/92-add-scripts.sh dans /usr/share/eole/postservice"
    cp -vf "$VM_DIR_EOLE_CI_TEST/tests/hapy/postservice/92-add-scripts.sh" /usr/share/eole/postservice/92-add-scripts
    ciCheckExitCode $? "$0 : cp"
fi
if [ -f "$VM_DIR_EOLE_CI_TEST/tests/hapy/postservice/93-vm_deploy.sh" ]
then
    ciSignalHack "Injection tests/hapy/postservice/93-vm_deploy.sh dans /usr/share/eole/postservice"
    cp -vf "$VM_DIR_EOLE_CI_TEST/tests/hapy/postservice/93-vm_deploy.sh" /usr/share/eole/postservice/93-vm_deploy
    ciCheckExitCode $? "$0 : cp"
fi

if ! grep -q test-eole.ac-dijon.fr /usr/share/eole/hapy-deploy/scripts/15_maj_auto.sh
then
    ciSignalHack "Injection Maj-Auto -C dans /usr/share/eole/hapy-deploy/scripts/15_maj_auto.sh"
    sed -i 's/    Maj-Auto /    Maj-Auto -S test-eole.ac-dijon.fr -V test-eole.ac-dijon.fr -C -F /' /usr/share/eole/hapy-deploy/scripts/15_maj_auto.sh
fi
grep 'Maj-Auto' /usr/share/eole/hapy-deploy/scripts/15_maj_auto.sh | grep -v ":ERROR:"
