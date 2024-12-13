#!/bin/bash

#set -x
function checkExitCode()
{
    if [[ "$1" -eq 0 ]]
    then
        return 0
    fi

    if [[ -n "$2" ]]
    then
        echo "CheckExitCode $1 ! ($2)"
    else
        echo "CheckExitCode $1"
    fi
    exit "$1"
}

OWNER=oneadmin
HOMEDIR=$(getent passwd "$OWNER" | cut -d ':' -f 6)
ONE_AUTH="${HOMEDIR}/.one/one_auth"
export ONE_AUTH

VM_NAME="ubuntu14.04-vm"
TEMPLATE_NAME="ubuntu14.04-template"
IMAGE_NAME="Test-EOLE-image"
#DS_SYSTEM="$(CreoleGet one_ds_system_prefix)default"
#DS_ISO="$(CreoleGet one_ds_iso_name)"
DS_IMAGES="$(CreoleGet one_ds_image_name)"
L2_VNETS="$(CreoleGet l2_vnets)"
if [ -z "$L2_VNETS" ]
then
    echo "l2_vnets doit être renseigné pour ce script !"
    exit 1
fi
NET_NAME="CR_${L2_VNETS}"

echo "* Extension LVM var+lib+one"
ciExtendsLvm "var+lib+one" 50G

function OneWait()
{
    local ONE_COMMANDE="one${1}"
    local ID_OU_NAME="${2}"
    local STATE_OK="${3}"
    SECONDS=0
    OK=1
    while (( SECONDS < 500 ));
    do
        # >/dev/null 2>/dev/null
        if ! "${ONE_COMMANDE}" show "${ID_OU_NAME}" 
        then
            if [[ "err" == "${STATE_OK}" ]]
            then
                # dans ce cas, c'est normal
                OK=0
            else 
                OK=2
            fi
            break
        fi
        imgState=$(${ONE_COMMANDE} show "${ID_OU_NAME}" | awk '{if ($1 == "STATE") {print $3}}')
        if [[ "${imgState}" == "${STATE_OK}" ]]
        then
            echo "Ok: l'${1} est ${imgState}"
            OK=0
            break
        fi
        echo "wait ${1} '${2}' for '${3}' : current is '${imgState}' seconds=$SECONDS"
        sleep 5
    done
    return $OK
}

echo "* onevm recover $VM_NAME --delete"
onevm recover "$VM_NAME" --delete
OneWait vm "$VM_NAME" "err"

if [ ! -f /var/tmp/ubuntu14.04.qcow2.gz ]
then
    # 300Mo ==> 30 * 10Mo
    wget --progress=dot -e dotbytes=10M -O /var/tmp/ubuntu14.04.qcow2.gz "https://appliances.opennebula.systems/Ubuntu-14.04/ubuntu14.04.qcow2.gz"
    checkExitCode $?

    # je détruis pour forcer la recreation
    echo "* oneimage delete $IMAGE_NAME"
    oneimage delete "$IMAGE_NAME"
    OneWait image "$IMAGE_NAME" "err"
fi

echo "* oneimage show ${IMAGE_NAME} ==> $imgState"
oneimage show "${IMAGE_NAME}"

imgState=$(oneimage show "${IMAGE_NAME}" | awk '{if ($1 == "STATE") {print $3}}')
echo "* oneimage show ${IMAGE_NAME} ==> $imgState"
if [[ ${imgState} != "rdy" ]]
then
    echo "* oneimage delete $IMAGE_NAME"
    oneimage delete "$IMAGE_NAME"
    OneWait image "$IMAGE_NAME" "err"

    echo "* oneimage create $IMAGE_NAME"
    oneimage create \
           --name "$IMAGE_NAME" \
           --path /var/tmp/ubuntu14.04.qcow2.gz \
           --prefix vd \
           --type OS \
           --driver qcow2 \
           --datastore "$DS_IMAGES"
    checkExitCode $?

    OneWait image "$IMAGE_NAME" "rdy"
    checkExitCode $?
fi

echo "* onetemplate delete $TEMPLATE_NAME"
onetemplate delete "$TEMPLATE_NAME" >/dev/null 2>&1
OneWait template "$TEMPLATE_NAME" "err"

cat >/tmp/template.tmpl <<EOF
NAME = "$TEMPLATE_NAME"
CPU = "1.0"
DISK = [ IMAGE = "$IMAGE_NAME", IMAGE_UNAME = "$OWNER" ]
GRAPHICS = [ LISTEN = "0.0.0.0", TYPE = "vnc" ]
MEMORY = "512"
NIC = [ NETWORK = "$NET_NAME" ]
OS = [ ARCH = "x86_64" ]
VCPU = "1"
LOGO = "images/logos/ubuntu.png"
CONTEXT = [
    NETWORK = "YES",
    SSH_PUBLIC_KEY = "\$USER[SSH_PUBLIC_KEY]"
]
EOF

echo "* onetemplate create $TEMPLATE_NAME"
onetemplate create /tmp/template.tmpl
checkExitCode $? "onetemplate create"

echo "* onetemplate show $TEMPLATE_NAME"
onetemplate show "$TEMPLATE_NAME"

echo "* onetemplate instantiate $TEMPLATE_NAME"
onetemplate instantiate "$TEMPLATE_NAME" --name "${VM_NAME}"
checkExitCode $? "onetemplate instantiate"

OneWait vm "$VM_NAME" "ACTIVE"

