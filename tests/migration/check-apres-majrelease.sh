#!/bin/bash

VM_VERSIONMAJEUR_CIBLE=$1
VM_PKG_KERNEL_ATTENDU=$2
echo "$0 : VM_VERSIONMAJEUR_CIBLE=$VM_VERSIONMAJEUR_CIBLE, VM_PKG_KERNEL_ATTENDU=$VM_PKG_KERNEL_ATTENDU"

RESULTAT="0"

echo "* Test Noyau apres migration"

echo "** Uname"
uname -a

echo "** Dpkg eole-server"
dpkg -l | grep eole-server

echo "** Dpkg noyau"
dpkg -l | grep linux-

echo "** Bascule VERSION"
VM_VERSIONMAJEUR=$VM_VERSIONMAJEUR_CIBLE
if [ -z "$VM_PKG_KERNEL_ATTENDU" ]
then
    case "$1" in
        2.5.1)
            VM_PKG_KERNEL_ATTENDU=linux-generic-lts-trusty
            VM_MAJAUTO=STABLE
            ;;
        2.5.2)
            VM_PKG_KERNEL_ATTENDU=linux-generic-lts-trusty
            VM_MAJAUTO=STABLE
            ;;

        2.6.1)
            VM_PKG_KERNEL_ATTENDU=linux-generic
            VM_MAJAUTO=STABLE
            ;;

        2.6.2)
            VM_PKG_KERNEL_ATTENDU=linux-generic
            VM_MAJAUTO=STABLE
            ;;

        2.7.1)
            VM_PKG_KERNEL_ATTENDU=linux-image-generic
            VM_MAJAUTO=RC
            ;;

        2.7.2)
            VM_PKG_KERNEL_ATTENDU=linux-image-generic
            VM_MAJAUTO=RC
            ;;

        2.8.1)
            VM_PKG_KERNEL_ATTENDU=linux-image-generic
            VM_MAJAUTO=RC
            ;;

        *)
            VM_PKG_KERNEL_ATTENDU=linux-generic
            ;;
    esac
fi
export VM_MAJAUTO

echo "  VM_VERSIONMAJEUR apres ${VM_VERSIONMAJEUR}"
echo "  VM_MAJAUTO = $VM_MAJAUTO"
echo "  NOYAU ATTENDU = $VM_PKG_KERNEL_ATTENDU"

if dpkg -l "$VM_PKG_KERNEL_ATTENDU"
then
    echo "NOYAU OK"
else
    RESULTAT="1"
    echo "ERREUR: NOYAU INCORRECT !"
    
    echo "** Dpkg -l"
    dpkg -l
fi

echo "************************************************************"
echo "* redemarre creoled"
echo "************************************************************"
service creoled stop
service creoled start
ciWaitTcpPort localhost 8000 10
ciCheckExitCode $?

if [[ "$VM_MAJAUTO" == "RC" ]]; then
    echo "************************************************************"
    echo "* maj_auto_rc"
    echo "************************************************************"
    ciMonitor maj_auto_rc
    RETVAL="$?"
    ciPrintMsg "Maj-Auto RC ==> RESULTAT=$RETVAL"
    [[ "$RETVAL" -eq 0 ]] || RESULTAT=$RETVAL
elif [[ "$VM_MAJAUTO" == "STABLE" ]]; then
    echo "************************************************************"
    echo "* maj_auto_stable"
    echo "************************************************************"
    ciMonitor maj_auto_stable
    RETVAL="$?"
    ciPrintMsg "Maj-Auto RC ==> RESULTAT=$RETVAL"
    [[ "$RETVAL" -eq 0 ]] || RESULTAT=$RETVAL
else
    echo "************************************************************"
    echo "* maj_auto_dev"
    echo "************************************************************"
    ciMonitor maj_auto_dev
    RETVAL="$?"
    ciPrintMsg "Maj-Auto DEV ==> RESULTAT=$RETVAL"
    [[ "$RETVAL" -eq 0 ]] || RESULTAT=$RETVAL
fi

echo "************************************************************"
echo "* interogation creole"
echo "************************************************************"
CreoleGet eole_version
CreoleGet eole_module

ls -l /usr/share/eole/creole/dicos/

dpkg -l | grep eole-

echo "************************************************************"
echo "* Migration configuration"
echo "************************************************************"
ciRunPython mise_a_jour_config_apres_migration.py
RETOUR=$?
[[ "$RETOUR" -eq 0 ]] || RESULTAT=$RETOUR

echo "************************************************************"
echo "* Affichage config.eol apres migration"
echo "************************************************************"
python3 "$VM_DIR_EOLE_CI_TEST/scripts/formatConfigEol1.py" </etc/eole/config.eol

echo "exit RESULTAT=$RESULTAT (si !=0, voir plus haut dans le script !)"
exit $RESULTAT
