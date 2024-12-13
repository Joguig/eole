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
            VM_MAJAUTO=STABLE
            ;;

        2.6.2)
            VM_PKG_KERNEL_ATTENDU=linux-generic
            VM_MAJAUTO=STABLE
            ;;

        2.7.0)
            VM_PKG_KERNEL_ATTENDU=linux-image-generic
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
echo "* Paquets obsolètes"
echo "************************************************************"
apt list "?obsolete"

echo "************************************************************"
echo "* Paquets présents avec un flag différent de 'ii'"
echo "************************************************************"
dpkg -l|grep -v ^"ii "

echo "************************************************************"
echo "* redemarre creoled"
echo "************************************************************"
service creoled stop
service creoled start
ciWaitTcpPort localhost 8000 10
ciCheckExitCode $?

echo "************************************************************"
echo "* maj_auto_rc"
echo "************************************************************"
ciMonitor maj_auto_rc
RETVAL="$?"
ciPrintMsg "Maj-Auto RC ==> RESULTAT=$RETVAL"
[[ "$RETVAL" -eq 0 ]] || RESULTAT=$RETVAL

echo "************************************************************"
echo "* interogation creole"
echo "************************************************************"
CreoleGet eole_version
CreoleGet eole_module

ls -l /usr/share/eole/creole/dicos/

dpkg -l | grep eole-

#Seth ou ScribeAD avec conteneur local uniquement
if [[ "$VM_MODULE" = "seth" ]] || [[ -f /var/lib/lxc/addc/config ]]
then
    if ciVersionMajeurApres "2.7.0"
    then
        echo "************************************************************"
        echo "* vérification version de Samba"
        echo "************************************************************"
        if [ -x /usr/bin/lxc-attach ]
        then
            SMBVERS=$(lxc-attach -n addc -- samba -V | cut -d' ' -f2)
        else
            SMBVERS=$(samba -V | cut -d' ' -f2)
        fi
        if ciVersionMajeurEgal "2.7.1"
        then
            EXPECTEDVERS="4.9.18-EOLE"
        elif ciVersionMajeurEgal "2.9.0"
        then
            EXPECTEDVERS="4.15.13-Ubuntu"
        else
            EXPECTEDVERS="4.15.13-Ubuntu"
        fi
        echo "* Version de samba : $SMBVERS"
        echo "* Version attendue : $EXPECTEDVERS"
        if [ "$SMBVERS" != "$EXPECTEDVERS" ]
        then
            ciSignalAlerte "La version de samba n'est pas celle attendue"
            if [ -f /var/lib/lxc/addc/config ]
            then
                ciSignalWarning "Vérifiez si il y a un rétro-portage de Samba depuis focal-proposed en cours"
                ciSignalWarning "Cf. https://dev-eole.ac-dijon.fr/issues/33980#note-2"
            fi
        fi
    fi
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
    echo "* Execute gen_conteneurs : RESULTAT=$RETVAL"

    ciPatchLxcConf
fi

echo "************************************************************"
echo "* Affichage config.eol apres migration"
echo "************************************************************"
python3 "$VM_DIR_EOLE_CI_TEST/scripts/formatConfigEol1.py" </etc/eole/config.eol

echo "exit RESULTAT=$RESULTAT (si !=0, voir plus haut dans le script !)"
exit $RESULTAT
