#!/bin/bash

LXC_PATH="$1"
BOOTSTRAP_TO_USE="$2"

ciSetHttpAndHttpsProxy
# shellcheck disable=SC2154
#proxy="$http_proxy"

echo "* ls -l ${LXC_PATH}/usr/share/eole/workstation/installMinion.*"
ls -l "${LXC_PATH}/usr/share/eole/workstation/installMinion."*

if [ -f "${LXC_PATH}/usr/share/eole/workstation/bootstrap-salt/bootstrap-salt.sh" ] 
then
    SCRIPT_VERSION_PAQUET=$(grep "__ScriptVersion=" "${LXC_PATH}/usr/share/eole/workstation/bootstrap-salt/bootstrap-salt.sh")
    echo "SCRIPT_VERSION_PAQUET=$SCRIPT_VERSION_PAQUET"

    if wget --no-check-certificate -O /tmp/bootstrap-salt.sh https://github.com/saltstack/salt-bootstrap/releases/latest/download/bootstrap-salt.sh
    then
        SCRIPT_VERSION_ONLINE=$(grep "__ScriptVersion=" /tmp/bootstrap-salt.sh)

        diff /tmp/bootstrap-salt.sh "${LXC_PATH}/usr/share/eole/workstation/bootstrap-salt/bootstrap-salt.sh" >"/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/bootstrap-salt.diff"
        echo "diff = $?"
        echo "EOLE_CI_PATH bootstrap-salt.diff"

        cp /tmp/bootstrap-salt.sh "/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/bootstrap-salt-upstream.sh"
        echo "EOLE_CI_PATH bootstrap-salt-upstream.sh"

        if [ "$SCRIPT_VERSION_ONLINE" != "$SCRIPT_VERSION_PAQUET" ]
        then
            echo "SCRIPT_VERSION_ONLINE=$SCRIPT_VERSION_ONLINE"
            ciSignalWarning "Le script UPSTREAM a été modifié. Verifier le code 'bootstrap-salt.sh' dans notre dépot 'eole-workstatyion-joineole'"
        else
            echo "Le script bootstrap-salt.sh conforme à UPSTREAM"
        fi
    else
        echo "Impossible de télécharger https://github.com/saltstack/salt-bootstrap/releases/latest/download/bootstrap-salt.sh"
    fi

    if [ -f "/mnt/eole-ci-tests/tests/etablissement/linux/bootstrap-salt.sh" ]
    then
        SCRIPT_VERSION_ONLINE=$(grep "__ScriptVersion=" /mnt/eole-ci-tests/tests/etablissement/linux/bootstrap-salt.sh)

        diff /mnt/eole-ci-tests/tests/etablissement/linux/bootstrap-salt.sh "${LXC_PATH}/usr/share/eole/workstation/bootstrap-salt/bootstrap-salt.sh" >"/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/bootstrap-salt.eolecitests.diff"
        echo "diff = $?"
        echo "EOLE_CI_PATH bootstrap-salt.eolecitests.diff"

        if [ "$SCRIPT_VERSION_ONLINE" != "$SCRIPT_VERSION_PAQUET" ]
        then
            echo "SCRIPT_VERSION_EOLECITEST=$SCRIPT_VERSION_ONLINE"
            ciSignalWarning "Le script UPSTREAM a été modifié. Verifier le code 'bootstrap-salt.sh' dans notre dépot 'eole-ci-tests', BOOTSTRAP_TO_USE=$BOOTSTRAP_TO_USE"
            if [ "$BOOTSTRAP_TO_USE" == "FUTUR" ]
            then
                ciSignalHack "Surcharge 'bootstrap-salt.sh' depuis /mnt/eole-ci-tests/tests/etablissement/linux/bootstrap-salt.sh"
                cat /mnt/eole-ci-tests/tests/etablissement/linux/bootstrap-salt.sh >"${LXC_PATH}/usr/share/eole/workstation/bootstrap-salt/bootstrap-salt.sh"
                pushd "${LXC_PATH}/usr/share/eole/workstation/bootstrap-salt/" || exit 1
                sha256sum bootstrap-salt.sh >bootstrap-salt.sh.sha256
                popd  || exit 1
            else
                echo "pas de surcharge"
            fi
        else
            echo "Le script bootstrap-salt.sh conforme à UPSTREAM"
        fi
    fi
else
    echo "Pas de script bootstrap-salt.sh sur le module"
fi
