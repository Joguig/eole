#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "Ce script doit être lancée en 'root'" 1>&2
   exit 1
fi

VM_OWNER="${1:-jenkins2}"
echo $VM_OWNER

CONTEXT="/mnt/eole-ci-tests/configuration/gateway/routeur_$VM_OWNER.sh"
if [ ! -f "$CONTEXT" ]
then
   echo "fichier routeur owner inexistant"
   exit 1
fi

# shellcheck disable=SC1090
source "$CONTEXT"
IP_GW=$IP_ONE
            
# variable pour savoir s'il faut attacher la GW a un noeud Jenkins
export AGENT_JENKINS

ROOT_KEY="/mnt/eole-ci-tests/security/gateway_keys/root@gateway$IP_GW.pub"
if [ ! -f "$ROOT_KEY" ]
then
   echo "fichier key gateway inexistant"
   exit 1
fi

SSH_JENKINS="$(cat $ROOT_KEY)"
if [ ! -f /home/$VM_OWNER/.ssh/authorized_keys ]
then
    echo "creation autorized key"
    echo "$SSH_JENKINS" >/home/$VM_OWNER/.ssh/authorized_keys 
    chown $VM_OWNER:$VM_OWNER /home/$VM_OWNER/.ssh/authorized_keys
else
    if grep "$SSH_JENKINS" /home/$VM_OWNER/.ssh/authorized_keys >/dev/null
    then
        echo "key gateway dans autorized key : OK"
    else
        echo "ajout gateway dans autorized key"
        echo "$SSH_JENKINS" >>/home/$VM_OWNER/.ssh/authorized_keys 
    fi
fi

SSH_JENKINS="$(cat /var/lib/jenkins/.ssh/id_rsa.pub)"
grep "$SSH_JENKINS" /home/$VM_OWNER/.ssh/authorized_keys >/dev/null
if [ "$?" == 0 ]
then
    echo "key jenkins dans autorized key : OK"
else
    echo "ajout jenkins dans autorized key"
    echo "$SSH_JENKINS" >>/home/$VM_OWNER/.ssh/authorized_keys 
fi

cat /home/$VM_OWNER/.ssh/authorized_keys 
