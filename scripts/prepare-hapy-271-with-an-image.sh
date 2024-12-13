#!/bin/bash

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

function OneWait()
{
    local ONE_COMMANDE="one${1}"
    local ID_OU_NAME="${2}"
    local STATE_OK="${3}"
    SECONDS=0
    OK=1
    while (( SECONDS < 500 ));
    do
        if ! "${ONE_COMMANDE}" show "${ID_OU_NAME}" >/tmp/onewait 2>&1
        then
            CDU="$?"
            if [[ "err" == "${STATE_OK}" ]]
            then
                # dans ce cas, c'est normal
                OK=0
            else 
                echo "erreur ${ONE_COMMANDE} ==> $CDU"
                cat /tmp/onewait
                OK=2
            fi
            break
        fi
        imgState=$(${ONE_COMMANDE} show "${ID_OU_NAME}" | awk '{if ($1 == "STATE") {print $3}}')
        if [[ "${imgState}" == "${STATE_OK}" ]]
        then
            echo "Ok: ${1} '${2}' is ${imgState}"
            OK=0
            break
        fi
        echo "wait ${1} '${2}' for '${3}' : current is '${imgState}' seconds=$SECONDS"
        sleep 5
    done
    return $OK
}

#set -x
OWNER=oneadmin
HOMEDIR=$(getent passwd "$OWNER" | cut -d ':' -f 6)
ONE_AUTH="${HOMEDIR}/.one/one_auth"
export ONE_AUTH

UBUNTU_RELEASE="16.04"
VM_NAME="ubuntu${UBUNTU_RELEASE}-vm"
TEMPLATE_NAME="ubuntu${UBUNTU_RELEASE}-template"
IMAGE_NAME="Test-EOLE-image"
#DS_SYSTEM="$(CreoleGet one_ds_system_prefix)default"
#DS_ISO="$(CreoleGet one_ds_iso_name)"
DS_IMAGES="$(CreoleGet one_ds_image_name)"
L2_VNETS="$(CreoleGet l2_vnets)"
if [ -z "$L2_VNETS" ]
then
    VNETS="$(CreoleGet vnets)"
    if [ -z "$VNETS" ]
    then
        echo "l2_vnets ou vnets doiventt être renseigné pour ce script !"
        exit 1
    else
        # attention il peut y avoir plusieurs, mais dans les confs il n'y en à qu'un !
        NET_NAME="CR_${VNETS}"
    fi
else
    NET_NAME="CR_${L2_VNETS}"
fi

echo "* Extension LVM var+lib+one"
ciExtendsLvm "var+lib+one" 50G

echo "* onevm recover $VM_NAME --delete"
onevm recover "$VM_NAME" --delete
OneWait vm "$VM_NAME" "err"

if [ ! -f /var/tmp/ubuntu${UBUNTU_RELEASE}.qcow2.gz ]
then
    URL=$(onemarketapp show "Ubuntu ${UBUNTU_RELEASE}" |awk '/SOURCE/ { print $3; }')
    if [ -z "$URL" ]
    then
        ciSignalWarning "onemarketapp show \"Ubuntu ${UBUNTU_RELEASE}\" : KO → utilisation URL de secours"
        URL="https://marketplace.opennebula.io/appliance/f886bdb6-1119-11ea-b898-f0def1753696/download/0"
    fi
    # 300Mo ==> 30 * 10Mo
    wget --progress=dot -e dotbytes=10M -O /var/tmp/ubuntu${UBUNTU_RELEASE}.qcow2 "$URL"
    checkExitCode $?
    
    FILE_INFO="$(file /var/tmp/ubuntu${UBUNTU_RELEASE}.qcow2)"
    if [ "$FILE_INFO" == "/var/tmp/ubuntu${UBUNTU_RELEASE}.qcow2: HTML document, ASCII text" ]
    then
        echo "Mauvais format : $FILE_INFO"
        return 1
    fi

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
    if ciVersionMajeurAPartirDe "2.9."
    then
        oneimage create \
               --name "$IMAGE_NAME" \
               --path /var/tmp/ubuntu${UBUNTU_RELEASE}.qcow2 \
               --prefix vd \
               --type OS \
               --format qcow2 \
               --persistent \
               --datastore "$DS_IMAGES"
    else
        oneimage create \
               --name "$IMAGE_NAME" \
               --path /var/tmp/ubuntu${UBUNTU_RELEASE}.qcow2 \
               --prefix vd \
               --type OS \
               --driver qcow2 \
               --persistent \
               --datastore "$DS_IMAGES"
    fi
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
FEATURES = [ "ACPI" = "yes", "PAE" = "no" ]
DISK = [ IMAGE = "$IMAGE_NAME", IMAGE_UNAME = "$OWNER" ]
GRAPHICS = [ LISTEN = "0.0.0.0", TYPE = "vnc" ]
MEMORY = "1024"
INPUT = [ BUS = "usb", TYPE = "tablet" ]
NIC = [ NETWORK = "$NET_NAME", MODEL = "virtio" ]
OS = [ ARCH = "x86_64", KERNEL_CMD = "console=ttyS0" ]
VCPU = "1"
LOGO = "images/logos/ubuntu.png"
CONTEXT = [
    NETWORK = "YES",
    SSH_PUBLIC_KEY = "\$USER[SSH_PUBLIC_KEY]",
    PASSWORD = "Eole12345!"
]
RAW = [ type = "kvm",
        data = "<devices>
                  <serial type=\"pty\">
                       <source path=\"/dev/pts/5\"/>
                       <target port=\"0\"/>
                  </serial>
                  <console type=\"pty\" tty=\"/dev/pts/5\">
                       <source path=\"/dev/pts/5\"/>
                       <target port=\"0\"/>
                  </console>
                </devices>"
]
EOF

if ciVersionMajeurAPartirDe "2.8."
then
    echo 'CPU_MODEL = [ MODEL = "host-passthrough" ]' >>/tmp/template.tmpl
fi

echo "* onetemplate create $TEMPLATE_NAME"
onetemplate create /tmp/template.tmpl
checkExitCode $? "onetemplate create"

echo "* onetemplate show $TEMPLATE_NAME"
onetemplate show "$TEMPLATE_NAME"

echo "* onetemplate instantiate $TEMPLATE_NAME"
onetemplate instantiate "$TEMPLATE_NAME" --name "${VM_NAME}"
checkExitCode $? "onetemplate instantiate"

if OneWait vm "$VM_NAME" "ACTIVE"
then
    # ok chargé. je peux supprimer le téléchargement
    /bin/rm /var/tmp/ubuntu${UBUNTU_RELEASE}.qcow2
fi

 
