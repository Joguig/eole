#!/bin/bash

echo "************************************************************"
VM_VERSIONMAJEUR_CIBLE=$1
VM_PKG_KERNEL_ATTENDU=$2
echo "$0 : VM_VERSIONMAJEUR_CIBLE=$VM_VERSIONMAJEUR_CIBLE, VM_PKG_KERNEL_ATTENDU=$VM_PKG_KERNEL_ATTENDU"

RESULTAT="0"

echo "************************************************************"
echo "* Test Noyau apres migration"

echo "** Uname"
uname -a

echo "** Dpkg noyau"
dpkg -l | grep linux-generic

echo "** Bascule VERSION"
VM_VERSIONMAJEUR=$VM_VERSIONMAJEUR_CIBLE
if [ -z "$VM_PKG_KERNEL_ATTENDU" ]
then
    case "$1" in
        2.4.0)
            VM_PKG_KERNEL_ATTENDU=linux-generic-lts-trusty
            VM_MAJAUTO=STABLE
            ;;
        2.4.1)
            VM_PKG_KERNEL_ATTENDU=linux-generic-lts-trusty
            VM_MAJAUTO=STABLE
            ;;
        2.4.2)
            VM_PKG_KERNEL_ATTENDU=linux-generic-lts-trusty
            VM_MAJAUTO=STABLE
            ;;
        2.5.0)
            VM_PKG_KERNEL_ATTENDU=linux-generic-lts-trusty
            VM_MAJAUTO=STABLE
            ;;
        2.5.1)
            VM_PKG_KERNEL_ATTENDU=linux-generic-lts-trusty
            VM_MAJAUTO=STABLE
            ;;
        2.5.2)
            VM_PKG_KERNEL_ATTENDU=linux-generic-lts-trusty
            VM_MAJAUTO=STABLE
            ;;

        2.6.0)
            VM_PKG_KERNEL_ATTENDU=linux-generic
            VM_MAJAUTO=STABLE
            ;;

        2.6.1)
            VM_PKG_KERNEL_ATTENDU=linux-generic
            VM_MAJAUTO=RC
            ;;

        2.6.2)
            VM_PKG_KERNEL_ATTENDU=linux-generic
            VM_MAJAUTO=DEV
            ;;

        *)
            VM_PKG_KERNEL_ATTENDU=linux-generic
            ;;
    esac
fi

echo "  VM_VERSIONMAJEUR apres $VM_VERSIONMAJEUR"
echo "  VM_MAJAUTO = $VM_MAJAUTO"
echo "  NOYAU ATTENDU = $VM_PKG_KERNEL_ATTENDU"

if dpkg -l $VM_PKG_KERNEL_ATTENDU
then
    echo "NOYAU OK"
else
    RESULTAT="1"
    echo "ERREUR NOYAU INCORRECT !"
fi

echo "************************************************************"
echo "* Migration configuration"
echo "************************************************************"
ciRunPython mise_a_jour_config_apres_migration.py
RETOUR=$?
[[ "$RETOUR" -eq 0 ]] || RESULTAT=$RETOUR

if [[ "$VM_CONTAINER" == "oui" ]]
then
    echo "************************************************************"
    echo "* Execute gen_conteneurs"
    echo "************************************************************"
    ciMonitor gen_conteneurs
    RETVAL="$?"
    echo "* Execute gen_conteneurs : RETVAL=$RETVAL"

    ciPatchLxcConf
fi

echo "******* Check Proxy ***********"
ciSetHttpProxy

echo "************************************************************"
echo "* reconfigure"
echo "************************************************************"
ciMonitor reconfigure
RETOUR=$?
[[ "$RETOUR" -eq 0 ]] || RESULTAT=$RETOUR

echo "************************************************************"
echo "Inject eolerc"
echo "************************************************************"
if [[ -f /etc/profile.d/eolerc.sh ]]
then
    . /etc/profile.d/eolerc.sh  >/dev/null
    RETOUR=$?
    echo "eolerc.sh => $RETOUR"
else
    echo "PAS DE FICHIER eolerc.sh !!!!"
fi

echo "************************************************************"
echo "Machine $VM_MACHINE : Diagnose"
echo "************************************************************"
ciDiagnose
RETOUR=$?
[[ "$RETOUR" -eq 0 ]] || RESULTAT=$RETOUR

exit $RESULTAT
