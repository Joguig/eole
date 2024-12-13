#!/bin/bash
# shellcheck disable=SC2034,SC2148

function cleanAppsGw()
{
    echo "Sortie nettoyage..."
    rm -vf "*.qcow2" 2>/dev/null
    rm -vf "*.qcow2.bz2" 2>/dev/null
    rm -vf "*.qcow2.md5" 2>/dev/null
    rm -vf "*.qcow2.sha256" 2>/dev/null
}
export -f cleanAppsGw

trap cleanAppsGw EXIT

# code executer sur l'agent Jenkins (gateway)

SOURCE="$1"
NOM="$2"
WORKSPACE="$3"
ARCHITECTURE="$4"
VERSION_APPLIANCE="$5"
VERSION_EOLE="$6"
MODULE_EOLE="$7"
MD5="$8"
TAILLE_DISQUE="$9"
TAILLE_MEMOIRE="${10}"
BOOT_TYPE="${11}"
pwd
cd "/root" || exit 1

# shellcheck disable=1091
source /mnt/eole-ci-tests/scripts/EoleCiFunctions.sh
apt-get install -y wget coreutils sshfs

echo "* Pwd"
pwd

echo "SOURCE=$SOURCE"
echo "NOM=$NOM"
echo "WORKSPACE=$WORKSPACE"
echo "ARCHITECTURE=$ARCHITECTURE"
echo "VERSION_APPLIANCE=$VERSION_APPLIANCE"
echo "VERSION_EOLE=$VERSION_EOLE"
echo "MODULE_EOLE=$MODULE_EOLE"
declare -c MODULE_EOLE_CAMELCASE # Changes only initial char to uppercase.
MODULE_EOLE_CAMELCASE="${MODULE_EOLE}"
echo "MODULE_EOLE_CAMELCASE=$MODULE_EOLE_CAMELCASE"
echo "MD5=$MD5"
echo "TAILLE_DISQUE=$TAILLE_DISQUE"
echo "TAILLE_MEMOIRE=$TAILLE_MEMOIRE"
echo "BOOT_TYPE=$BOOT_TYPE"
SECONDS=0
RELOAD=non
MOUNT_APPLIANCE=non
if [ -z "$SSHKEY_FILE" ]
then
    echo "ERREUR: SSHKEY_FILE n'est pas définit"
    exit 1
fi
if [  "$TAILLE_DISQUE" -lt "-1" ]
then
    echo "ERREUR: TAILLE_DISQUE = $TAILLE_DISQUE inférieur à Zéro !"
    exit 1
fi

echo "* Check acces lab1"
if ! ssh -o BatchMode=yes -o StrictHostKeyChecking=false -o IdentityFile="$SSHKEY_FILE" market@lab1.labs.eole.education "ls -l"
then
    echo "ERREUR: Check acces lab1 : stop"
    exit 1
else
    echo "Check acces lab1 : OK"
fi

echo "* Téléchargement de $NOM.qcow2.bz2"
#if [ ! -f "$NOM.qcow2.bz2" ]
#then
rm -f "$NOM.qcow2" 2>/dev/null
rm -f "$NOM.qcow2.bz2" 2>/dev/null
rm -f "$NOM.qcow2.md5" 2>/dev/null
rm -f "$NOM.qcow2.sha256" 2>/dev/null
SECONDS=0

#apt-get install -y qemu-utils

#qemu-img convert -p -c -f qcow2 "$SOURCE" -O qcow2 "$NOM.qcow2"
#CDU="$?"
#if [ ! -f "$NOM.qcow2" ] 
#then
#    echo "Durée = $SECONDS s"
    echo "wget + bzip2 ..."
    wget --progress=dot -e dotbytes=50M -c --no-http-keep-alive -O - "$SOURCE" | tee >(md5sum >"$NOM.qcow2.md5") >(sha256sum >"$NOM.qcow2.sha256") | bzip2 -9c > "$NOM.qcow2.bz2"
    CDU="$?"
#else
#    ls -l "$NOM.qcow2"
#    echo "Durée = $SECONDS s"
#    echo "bzip2 ..."
#    tee <"$NOM.qcow2" >(md5sum >"$NOM.qcow2.md5") >(sha256sum >"$NOM.qcow2.sha256") | bzip2 -9c > "$NOM.qcow2.bz2"
#    rm -f "$NOM.qcow2" 2>/dev/null
#    CDU="$?"
#fi
echo "Durée = $SECONDS s"

if [ ! -f "$NOM.qcow2.bz2" ] 
then
    echo "ERREUR: impossible téléchager l'image depuis ONE ($CDU)"
    exit 1
fi
echo "Durée = $SECONDS s"
#fi

if [ ! -f "$NOM.qcow2.md5" ]
then
    echo "ERREUR: $NOM.qcow2.md5 manquant"
    exit 1
fi
MD5_DOWNLOAD=$(awk '{print $1;}' "$NOM.qcow2.md5")
echo "MD5_DOWNLOAD=$MD5_DOWNLOAD"
if [ "$MD5_DOWNLOAD" != "$MD5" ]
then
    echo "ERREUR: MD5 différent"
    exit 1
else
    echo "MD5 OK"
fi

if [ ! -f "$NOM.qcow2.sha256" ]
then
    echo "* $NOM.qcow2.sha256 manquant"
    exit 1
fi
SHA256_DOWNLOAD=$(awk '{ print $1;}' <"$NOM.qcow2.sha256")
echo "SHA256_DOWNLOAD=$SHA256_DOWNLOAD"

echo "* Montage /mnt/appliances "
if [ ! -d /mnt/appliances ]
then
    mkdir -p /mnt/appliances
    chmod 777 /mnt/appliances
fi
if ! grep -q appliances /proc/mounts
then
    if ! sshfs market@lab1.labs.eole.education:"appmarket-simple/src/" /mnt/appliances -o IdentityFile="$SSHKEY_FILE"
    then
        echo "ERREUR: impossible de monter /mnt/appliances"
        exit 1
    fi
    MOUNT_APPLIANCE=oui
fi

echo "* Déploiement image $NOM.qcow2.bz2 ?"
DO_COPY=non
if [ ! -f "/mnt/appliances/public/images/$NOM.qcow2.bz2" ]
then
    echo "* Nouvelle image $NOM.qcow2.bz2, ... copy"
    DO_COPY=oui
else
    if test "$NOM.qcow2.bz2" -nt "/mnt/appliances/public/images/$NOM.qcow2.bz2"
    then
        echo "* image actualisée $NOM.qcow2.bz2, ... copy"
        DO_COPY=oui
    else
        echo "* image identique $NOM.qcow2.bz2, pas de copy"
        DO_COPY=non
    fi
fi

if [ $DO_COPY == oui ]
then
    echo "* oui, il faut déployer l'image $NOM.qcow2.bz2 "
    SECONDS=0
    if ! cp -vf "$NOM.qcow2.bz2" "/mnt/appliances/public/images/$NOM.qcow2.bz2"
    then
        echo "ERREUR: impossible de copier l'image dans '/mnt/appliances/public/images/$NOM.qcow2.bz2'"
        exit 1
    fi
    if ! cp -vf "$NOM.qcow2.md5" "/mnt/appliances/public/images/$NOM.qcow2.md5"
    then
        echo "ERREUR: impossible de copier le MD5 dans '/mnt/appliances/public/images/$NOM.qcow2.md5'"
        exit 1
    fi
    if ! cp -vf "$NOM.qcow2.sha256" "/mnt/appliances/public/images/$NOM.qcow2.sha256"
    then
        echo "ERREUR: impossible de copier le SHA256 dans '/mnt/appliances/public/images/$NOM.qcow2.sha256'"
        exit 1
    fi
    echo "Durée = $SECONDS s"
fi
ls -l "/mnt/appliances/public/images/$NOM.qcow2.bz2"

echo "* Préparation yaml dans /tmp/${NOM}.yaml"
maintenant=$(date '+%s')
cat >"/tmp/${NOM}.yaml" <<EOF
---
name: $NOM
version: $VERSION_APPLIANCE
publisher: Pôle de Compétence Logiciels Libres
short_description: Module $MODULE_EOLE_CAMELCASE $VERSION_EOLE
description: |-
  Module EOLE $MODULE_EOLE_CAMELCASE $VERSION_EOLE avec paquet de contextualisation installé

tags:
- pcll
- eole
- $VERSION_EOLE
- $MODULE_EOLE

format: qcow2

creation_time: $maintenant

os-id: EOLE
os-release: '$VERSION_EOLE'
os-arch: x86_64
hypervisor: KVM

# Compatibility with OpenNebula releases. Appliance will be
# offered only to OpenNebula clients with matching version!!
opennebula_version: 5.2, 5.4, 5.6, 5.8, 5.10, 5.12, 6.2

# The template for the appliance without disks and in YAML format
opennebula_template:
  context:
    network: 'YES'
    ssh_public_key: "\$USER[SSH_PUBLIC_KEY]"
  cpu: '1'
  graphics:
    listen: 0.0.0.0
    type: vnc
  memory: '$TAILLE_MEMOIRE'
  os:
    arch: x86_64
  logo: images/logos/eole.png

logo: eole.png

images:
- name: $NOM
  url: https://magasin.eole.education/images/$NOM.qcow2.bz2
  type: OS
  dev_prefix: sd
  driver: qcow2
  size: $TAILLE_DISQUE
  checksum:
    md5: $MD5
    sha256: $SHA256_DOWNLOAD
EOF

echo "* Contenu ${NOM}.yaml (futur)"
echo "******************************************"
cat "/tmp/${NOM}.yaml"
echo "******************************************"

echo "* Recherche yaml dans data/applicances"
PATH_APPLIANCE=$(rgrep "^name: $NOM" /mnt/appliances/data/applicances/eole2 |awk -F: '{ print $1;}')
if [ -n "$PATH_APPLIANCE" ] 
then
    echo "Trouvé dans : $PATH_APPLIANCE"
    if ! diff "/tmp/${NOM}.yaml" "$PATH_APPLIANCE"
    then
        echo "Diff actualise : $PATH_APPLIANCE"
        cat "/tmp/${NOM}.yaml" >"$PATH_APPLIANCE"
        RELOAD=oui
    else
        echo "Pas de diff : stop"
        RELOAD=non 
    fi
else
    PATH_APPLIANCE="/mnt/appliances/data/applicances/eole2/$(uuidgen).yaml"
    echo "A créer dans : $PATH_APPLIANCE"
    cat "/tmp/${NOM}.yaml" >"$PATH_APPLIANCE"
    RELOAD=oui
fi
cat "$PATH_APPLIANCE"

if [ "$MOUNT_APPLIANCE" == oui ]
then
    echo "* umount /mnt/appliances"
    fusermount -u /mnt/appliances
fi

if [ "$RELOAD" == oui ]
then
    echo "* Reload demandé"
    if ! ssh -o IdentityFile="$SSHKEY_FILE" market@lab1.labs.eole.education touch appmarket-simple/src/data/reload
    then
        echo "ERREUR: reload demandé"
        exit 1
    fi
fi

UUID=$(basename "${PATH_APPLIANCE}" .yaml)
echo "* L'appliance '$NOM' est disponible à l'URL : https://magasin.eole.education/appliance/$UUID"
echo "Attention : délai de 10 minutes avant d'être visible dans sunstone"

echo "* Nettoyage gateway $NOM.qcow2.bz2, $NOM.qcow2.md5, $NOM.qcow2.sha256"
rm -f "$NOM.qcow2" 2>/dev/null
rm -f "$NOM.qcow2.bz2" 2>/dev/null
rm -f "$NOM.qcow2.md5" 2>/dev/null
rm -f "$NOM.qcow2.sha256" 2>/dev/null

cleanAppsGw
exit 0
