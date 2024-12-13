#!/bin/bash

function doPaquet()
{
    local FROM_UBUNTU
    local FROM_EOLE
    apt-cache policy "$PQ" >/tmp/dpkg
    #cat /tmp/dpkg
    if grep "/ubuntu " /tmp/dpkg >/dev/null 2>&1 ;
    then
        FROM_UBUNTU=UBUNTU
    else
        FROM_UBUNTU="" 
    fi

    if grep "cdrom://EOLE" /tmp/dpkg >/dev/null 2>&1 ;
    then
        FROM_EOLE=EOLE
    else
        FROM_EOLE=""
    fi
   
    if grep "/eole " /tmp/dpkg >/dev/null 2>&1 ;
    then
        FROM_EOLE=EOLE
    else
        FROM_EOLE=""
    fi

    printf "%-50s;%-10s;%-10s\\n" "$PQ" "$FROM_UBUNTU" "$FROM_EOLE"
    echo "$PQ;$FROM_UBUNTU;$FROM_EOLE" >>"$WORKSPACE/source_paquets.txt"
}

function doRelease()
{
    local VERSION="$1"
    local NO_MODULE="$2"
    
    DEST="$WORKSPACE/$1"
    rm -rf "$DEST"
    mkdir -p "$DEST"
    mkdir -p "$DEST/servermodel"
    
    ls "$BASE/$EOLEMODULES/$NO_MODULE/" | while read -r SM
    do
        MODULE=${SM/-$VERSION//}
        MODULE=${MODULE::-1}
        echo "$SM $MODULE => $DEST/servermodel/$SM.yaml"
        [ -f "$DEST/servermodel/$SM.yaml" ] && rm "$DEST/servermodel/$SM.yaml"
        cat >"$DEST/servermodel/$SM.yaml" <<EOF
ModuleName: $MODULE
ModuleRelease: $VERSION
ModuleParent: Eolebase
ServerModelSource: EOLE
ApplicationServices:
EOF
        sed -e 's#eole/#- #' <"$BASE/$EOLEMODULES/$NO_MODULE/$SM" >>"$DEST/servermodel/$SM.yaml"
    done
    
    #if [ ! -f "$WORKSPACE/source_paquets.txt" ]
    #then
    #fi
    
    mkdir -p "$DEST/dicos/"
    ls "$BASE/dictionnaires/$VERSION/eole/" | while read -r SA
    do
        echo "$SA"
        cp "$BASE/dictionnaires/$VERSION/eole/$SA/*.xml" "$DEST/dicos/"
        [ -f "$DEST/serverapplicatif/$SA.yaml" ] && rm "$DEST/serverapplicatif/$SM.yaml"
        cat >"$DEST/serverapplicatif/$SA.yaml" <<EOF
name: $SA
dicos:
- dicos/$SA.xml
template:
- tempalte/$SA.tmpl
EOF
    done
}

command -v git && apt-get install -y git
cd /tmp || exit 1
git clone ssh://git@dev-eole.ac-dijon.fr/zephir-parc.git
BASE=/tmp/zephir-parc/data
EOLEMODULES=eolemodules
JENKINSDEPOTS=/mnt/jenkins-one/depots
VERSIONPATH=/mnt/eole-ci-tests-one/version
WORKSPACE=/mnt/eole-ci-tests-one/output/ggrandgerard/zephir2

mkdir -p "$WORKSPACE"
#/bin/rm -f "$WORKSPACE/source_paquets.txt"
if [ ! -f "$WORKSPACE/source_paquets.txt" ]
then
    dpkg -l | awk '/^ii/ {print $2;}' | while read -r PQ
    do
       doPaquet "$PQ"
    done
fi

doRelease 2.6.2 22
#doRelease 2.6.1 21
#doRelease 2.6.0 20
#doRelease 2.5.2 11
#doRelease 2.5.1 10
#doRelease 2.5.0 9

exit 0 
