#!/bin/bash

set -x

OWNER=oneadmin
HOMEDIR=$(getent passwd "$OWNER" | cut -d ':' -f 6)
ONE_AUTH="${HOMEDIR}/.one/one_auth"
export ONE_AUTH

VM_NAME="ubuntu14.04-vm"
TEMPLATE_NAME="ubuntu14.04-template"
IMAGE_NAME="Test-EOLE-image"
NET_NAME="CR_internet"

onevm delete "$VM_NAME" 

if [ ! -f /tmp/ubuntu14.04.qcow2.gz ]
then
    # 300Mo ==> 30 * 10Mo
    wget --progress=dot -e dotbytes=10M -O /tmp/ubuntu14.04.qcow2.gz "https://appliances.opennebula.systems/Ubuntu-14.04/ubuntu14.04.qcow2.gz"
    ciCheckExitCode $?

    if ciVersionMajeurAPartirDe "2.9."
    then
        oneimage create \
           --name "$IMAGE_NAME" \
           --path /tmp/ubuntu14.04.qcow2.gz \
           --prefix sd \
           --type OS \
           --format qcow2 \
           --datastore default
    else
        oneimage create \
           --name "$IMAGE_NAME" \
           --path /tmp/ubuntu14.04.qcow2.gz \
           --prefix sd \
           --type OS \
           --driver qcow2 \
           --datastore default
    fi
    ciCheckExitCode $?
fi

SECONDS=0 
OK=1
while (( SECONDS < 300 ));
do
    imgState=$(oneimage show "${IMAGE_NAME}" | awk '{if ($1 == "STATE") {print $3}}')
    if [[ ${imgState} == "used" ]] 
    then
        echo "l'image est Used, stop"
        break
    fi
    if [[ ${imgState} == "rdy" ]] 
    then
        echo "Création terminée, l'image est Ready"
        OK=0
        break
    fi
    echo "Initialisation en cours, merci de patienter ${imgState}"
    sleep 5
done
ciCheckExitCode $OK

onetemplate delete "$TEMPLATE_NAME" >/dev/null 2>&1

onetemplate create \
   --name "$TEMPLATE_NAME" \
   --cpu 1 \
   --vcpu 1 \
   --memory 512 \
   --arch x86_64 \
   --disk "$IMAGE_NAME" \
   --nic "$NET_NAME" \
   --vnc \
   --ssh
   
ciCheckExitCode $? "onetemplate create"

onetemplate instantiate "$TEMPLATE_NAME" \
   --name "${VM_NAME}"
ciCheckExitCode $? "onetemplate instantiate"

SECONDS=0 
OK=1
while (( SECONDS < 300 ));
do
    imgState=$(onevm show "${VM_NAME}" | awk '{if ($1 == "LCM_STATE") {print $3}}')
    if [[ ${imgState} == "RUNNING" ]] 
    then
        echo "La VM est prete"
        OK=0
        break
    fi
    echo "Démarrage en cours, merci de patienter ${imgState}"
    sleep 5
done
ciCheckExitCode $OK

