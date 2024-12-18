#!/bin/bash


function doCheckDepot()
{
    local DEPOT=$1          # Chaine à rechercher dans le sourcelist
    local RESULTAT=$2       # PRESENCE ou ABSENCE de la chaine

    grep "$DEPOT " /etc/apt/sources.list >/tmp/test.txt
    NB=$(wc -l </tmp/test.txt)
    case "$RESULTAT" in
        PRESENCE)
            if [ "$NB" -ne 1 ]
            then
                cat /tmp/test.txt
                echo "ERREUR: Le dépot '$DEPOT' est attendu 1 fois mais est présent $NB fois !"
                RESULT="1"
            else
                echo "OK: $DEPOT présent"
            fi
            ;;

        ABSENCE)
            if [ "$NB" -ne 0 ]
            then
                cat /tmp/test.txt
                echo "ERREUR: Le dépot '$DEPOT' est présent alors qu'il devrait être absent !"
                RESULT="1"
            else
                echo "OK: $DEPOT absent "
            fi
            ;;
        *)
            echo "ERREUR PROGRAME ! $RESULTAT "
            ;;
    esac

}

function doCheckContainers()
{
    local TAG=$1
    local TAG_FILE=$2

    if grep -q "$TAG" "$TAG_FILE";then
        echo "OK: tag '$TAG' présent"
    else
        echo "ERREUR: tag '$TAG' absent"
        echo "cat $TAG_FILE"
        cat "$TAG_FILE"
        RESULT="1"
    fi
}

function doCheckTag()
{
    local TAG=$1
    local TAG_FILE=/etc/eole/containers.conf.d/common.env

    if [ "$TAG" == "ABSENCE" ]
    then
        if [ -f "$TAG_FILE" ];then
            echo "ERREUR: le fichier '$TAG_FILE' est présent alors qu'il devrait être absent !"
            RESULT="1"
            return 0
        fi
        echo "OK: fichier '$TAG_FILE' absent "
        return 0
    fi
    doCheckContainers "$TAG" "$TAG_FILE"
}

function doCheckSource()
{
    local ATTENDU=$1

    case "$ATTENDU" in
        STABLE_EOLE)
            doCheckDepot "eole-${VM_VERSIONMAJEUR} main" PRESENCE
            doCheckDepot "eole-${VM_VERSIONMAJEUR}-security" PRESENCE
            doCheckDepot "eole-${VM_VERSIONMAJEUR}-updates" PRESENCE
            doCheckDepot "eole-${VM_VERSIONMAJEUR}-proposed-updates" ABSENCE
            doCheckDepot "eole-${VM_VERSION_EOLE}-unstable" ABSENCE
            ;;

        RC_EOLE)
            doCheckDepot "eole-${VM_VERSIONMAJEUR}" PRESENCE
            doCheckDepot "eole-${VM_VERSIONMAJEUR}-security" PRESENCE
            doCheckDepot "eole-${VM_VERSIONMAJEUR}-updates" PRESENCE
            doCheckDepot "eole-${VM_VERSIONMAJEUR}-proposed-updates" PRESENCE
            doCheckDepot "eole-${VM_VERSION_EOLE}-unstable" ABSENCE
            ;;

        DEV_EOLE)
            doCheckDepot "eole-${VM_VERSIONMAJEUR}" ABSENCE
            doCheckDepot "eole-${VM_VERSIONMAJEUR}-security" ABSENCE
            doCheckDepot "eole-${VM_VERSIONMAJEUR}-updates" ABSENCE
            doCheckDepot "eole-${VM_VERSIONMAJEUR}-proposed-updates" ABSENCE
            doCheckDepot "eole-${VM_VERSION_EOLE}-unstable" PRESENCE
            ;;

        STABLE_ENVOLE)
            doCheckDepot "envole-${ENVOLE}" PRESENCE
            doCheckDepot "envole-${ENVOLE}-testing" ABSENCE
            doCheckDepot "envole-${ENVOLE}-unstable" ABSENCE
            ;;

        RC_ENVOLE)
            doCheckDepot "envole-${ENVOLE}" PRESENCE
            doCheckDepot "envole-${ENVOLE}-testing" PRESENCE
            doCheckDepot "envole-${ENVOLE}-unstable" ABSENCE
            ;;

        DEV_ENVOLE)
            doCheckDepot "envole-${ENVOLE}" ABSENCE
            doCheckDepot "envole-${ENVOLE}-testing" ABSENCE
            doCheckDepot "envole-${ENVOLE}-unstable" PRESENCE
            ;;

        ABSENCE_ENVOLE)
            doCheckDepot "envole-${ENVOLE}" ABSENCE
            doCheckDepot "envole-${ENVOLE}-testing" ABSENCE
            doCheckDepot "envole-${ENVOLE}-unstable" ABSENCE
            ;;

        ABSENCE_TAG)
            doCheckTag ABSENCE
            ;;

        TAG_STABLE)
            doCheckTag stable
            ;;

        TAG_TESTING)
            doCheckTag testing
            ;;

        TAG_DEV)
            doCheckTag dev
            ;;

    esac
}

function doUseCase()
{
    local DESCRIPTION=$1        # Intitulé du test
    local PARAM=$2              # Paramètre de la commande Query-Auto
    local ATTENDU_EOLE=$3       # État du dépot eole (STABLE_EOLE, RC_EOLE, DEV_EOLE)
    local ATTENDU_ENVOLE=$4     # État du dépot envole (ABSENCE_ENVOLE, STABLE_ENVOLE, RC_ENVOLE, DEV_ENVOLE)
    local ATTENDU_TAG=$5        # Tag pour les conteneurs Podman

    rm -f /var/lock/eole/eole-system/majauto*
    echo ' '
    echo "=> $DESCRIPTION : "
    ciQueryAuto "$PARAM"
    doCheckSource "$ATTENDU_EOLE"
    doCheckSource "$ATTENDU_ENVOLE"
    ciVersionMajeurAPartirDe "2.9." && doCheckSource "$ATTENDU_TAG"
}

# shellcheck disable=SC1091
source /root/getVMContext.sh NO_DISPLAY

RESULT="0"
cat /etc/apt/sources.list
ciGetEoleVersion
ciGetEnvoleVersion
echo "ENVOLE VERSION = $ENVOLE"

if [ "$VM_MACHINE" == "aca.eolebase" ]
then
    doUseCase "Execution de 'Query-Auto sans param' doit activer Eole stable et pas envole" \
              "" \
              "STABLE_EOLE" \
              "ABSENCE_ENVOLE" \
              "ABSENCE_TAG"

    doUseCase "Execution de 'Query-Auto -C' doit activer Eole RC et pas envole" \
              "-C" \
              "RC_EOLE" \
              "ABSENCE_ENVOLE" \
              "ABSENCE_TAG"

    doUseCase "Execution de 'Query-Auto --candidat' doit activer Eole RC et pas envole" \
              "--candidat" \
              "RC_EOLE" \
              "ABSENCE_ENVOLE" \
              "ABSENCE_TAG"

    doUseCase "Execution de 'Query-Auto -D' doit activer Eole Dev et pas envole" \
              "-D" \
              "DEV_EOLE" \
              "ABSENCE_ENVOLE" \
              "ABSENCE_TAG"

    doUseCase "Execution de 'Query-Auto --devel' doit activer Eole Dev et pas envole" \
              "--devel" \
              "DEV_EOLE" \
              "ABSENCE_ENVOLE" \
              "ABSENCE_TAG"

    if ciVersionMajeurApres "2.5.2"
    then
        doUseCase "Execution de 'Query-Auto -C eole' doit activer Eole RC et pas envole" \
                  "-C eole" \
                  "RC_EOLE" \
                  "ABSENCE_ENVOLE" \
                  "ABSENCE_TAG"

        doUseCase "Execution de 'Query-Auto -C envole' doit activer Eole stable et pas envole" \
                  "-C envole" \
                  "STABLE_EOLE" \
                  "ABSENCE_ENVOLE" \
                  "ABSENCE_TAG"

        doUseCase "Execution de 'Query-Auto --candidat eole' doit activer Eole RC et pas envole" \
                  "--candidat eole" \
                  "RC_EOLE" \
                  "ABSENCE_ENVOLE" \
                  "ABSENCE_TAG"

        doUseCase "Execution de 'Query-Auto --candidat envole' doit activer Eole stable et pas envole" \
                  "--candidat envole" \
                  "STABLE_EOLE" \
                  "ABSENCE_ENVOLE" \
                  "ABSENCE_TAG"

        doUseCase "Execution de 'Query-Auto -D eole' doit activer Eole Dev et pas envole" \
                  "-D eole" \
                  "DEV_EOLE" \
                  "ABSENCE_ENVOLE" \
                  "ABSENCE_TAG"

        doUseCase "Execution de 'Query-Auto -D envole' doit activer Eole stable et pas envole" \
                  "-D envole" \
                  "STABLE_EOLE" \
                  "ABSENCE_ENVOLE" \
                  "ABSENCE_TAG"

        doUseCase "Execution de 'Query-Auto --devel eole' doit activer Eole Dev et pas envole" \
                  "--devel eole" \
                  "DEV_EOLE" \
                  "ABSENCE_ENVOLE" \
                  "ABSENCE_TAG"

        doUseCase "Execution de 'Query-Auto --devel envole' doit activer Eole stable et pas envole" \
                  "--devel envole" \
                  "STABLE_EOLE" \
                  "ABSENCE_ENVOLE" \
                  "ABSENCE_TAG"

        if ciVersionMajeurApres "2.7.1"
        then
            doUseCase "Execution de 'Query-Auto -C eole -D envole' doit activer Eole RC et pas envole" \
                      "-C eole -D envole" \
                      "RC_EOLE" \
                      "ABSENCE_ENVOLE" \
                      "ABSENCE_TAG"

            doUseCase "Execution de 'Query-Auto -D eole -C envole' doit activer Eole Dev et pas envole" \
                      "-D eole -C envole" \
                      "DEV_EOLE" \
                      "ABSENCE_ENVOLE" \
                      "ABSENCE_TAG"

        fi
    fi
fi

if [ "$VM_MACHINE" == "aca.scribe" ]
then
    doUseCase "Execution de 'Query-Auto sans param' doit activer Eole stable et envole stable" \
              "" \
              "STABLE_EOLE" \
              "STABLE_ENVOLE" \
              "TAG_TESTING"

    doUseCase "Execution de 'Query-Auto -S eole.ac-dijon.fr' doit activer Eole stable et envole stable" \
              "-S eole.ac-dijon.fr" \
              "STABLE_EOLE" \
              "STABLE_ENVOLE" \
              "TAG_STABLE"

    doUseCase "Execution de 'Query-Auto -C' doit activer Eole RC et envole RC" \
              "-C" \
              "RC_EOLE" \
              "RC_ENVOLE" \
              "TAG_DEV"

    doUseCase "Execution de 'Query-Auto -C -S eole.ac-dijon.fr' doit activer Eole RC et envole RC" \
              "-C -S eole.ac-dijon.fr" \
              "RC_EOLE" \
              "RC_ENVOLE" \
              "TAG_TESTING"

    doUseCase "Execution de 'Query-Auto --candidat' doit activer Eole RC et envole RC" \
              "--candidat" \
              "RC_EOLE" \
              "RC_ENVOLE" \
              "TAG_DEV"

    doUseCase "Execution de 'Query-Auto -D' doit activer Eole Dev et envole Dev" \
              "-D" \
              "DEV_EOLE" \
              "DEV_ENVOLE" \
              "TAG_DEV"

    doUseCase "Execution de 'Query-Auto -D -S eole.ac-dijon.fr' doit activer Eole Dev et envole Dev" \
              "-D -S eole.ac-dijon.fr" \
              "DEV_EOLE" \
              "DEV_ENVOLE" \
              "TAG_DEV"

    doUseCase "Execution de 'Query-Auto --devel' doit activer Eole Dev et envole Dev" \
              "--devel" \
              "DEV_EOLE" \
              "DEV_ENVOLE" \
              "TAG_DEV"

    if ciVersionMajeurApres "2.5.2"
    then
        doUseCase "Execution de 'Query-Auto -C eole' doit activer Eole RC et envole stable" \
                  "-C eole" \
                  "RC_EOLE" \
                  "STABLE_ENVOLE" \
                  "TAG_DEV"

        doUseCase "Execution de 'Query-Auto -C envole' doit activer Eole stable et envole RC" \
                  "-C envole" \
                  "STABLE_EOLE" \
                  "RC_ENVOLE" \
                  "TAG_TESTING"

        doUseCase "Execution de 'Query-Auto --candidat eole' doit activer Eole RC et envole stable" \
                  "--candidat eole" \
                  "RC_EOLE" \
                  "STABLE_ENVOLE" \
                  "TAG_DEV"

        doUseCase "Execution de 'Query-Auto --candidat envole' doit activer Eole stable et envole RC" \
                  "--candidat envole" \
                  "STABLE_EOLE" \
                  "RC_ENVOLE" \
                  "TAG_TESTING"

        doUseCase "Execution de 'Query-Auto -D eole' doit activer Eole Dev et envole stable" \
                  "-D eole" \
                  "DEV_EOLE" \
                  "STABLE_ENVOLE" \
                  "TAG_DEV"

        doUseCase "Execution de 'Query-Auto -D envole' doit activer Eole stable et envole Dev" \
                  "-D envole" \
                  "STABLE_EOLE" \
                  "DEV_ENVOLE" \
                  "TAG_TESTING"

        doUseCase "Execution de 'Query-Auto --devel eole' doit activer Eole Dev et envole stable" \
                  "--devel eole" \
                  "DEV_EOLE" \
                  "STABLE_ENVOLE" \
                  "TAG_DEV"

        doUseCase "Execution de 'Query-Auto --devel envole' doit activer Eole stable et envole Dev" \
                  "--devel envole" \
                  "STABLE_EOLE" \
                  "DEV_ENVOLE" \
                  "TAG_TESTING"

        if ciVersionMajeurApres "2.7.1"
        then
            doUseCase "Execution de 'Query-Auto -C eole -D envole' doit activer Eole RC et envole Dev" \
                      "-C eole -D envole" \
                      "RC_EOLE" \
                      "DEV_ENVOLE" \
                      "TAG_DEV"

            doUseCase "Execution de 'Query-Auto -D eole -C envole' doit activer Eole Dev et envole RC" \
                      "-D eole -C envole" \
                      "DEV_EOLE" \
                      "RC_ENVOLE" \
                      "TAG_DEV"

        fi
    fi
fi

echo "*****************************************"
if [ "$RESULT" = "0" ]
then
  echo "TEST OK"
else
  echo "!!! TEST EN ERREUR !!!"
fi
exit "$RESULT"
