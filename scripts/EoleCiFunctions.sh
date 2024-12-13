#!/bin/bash

#########################################################################################################
#
# ciPrintCallStack($@): affiche la stack BASH
#
#########################################################################################################
function ciPrintCallStack()
{
   # to avoid noise we start with 1 to skip get_stack caller
   local i
   local stack_size=${#FUNCNAME[@]}
   echo "-- call stack --"
   for (( i=1; i<stack_size ; i++ ));
   do
      local func="${FUNCNAME[$i]}"
      [ -z "$func" ] && func=MAIN
      local j=$(( i - 1 ))
      local linen="${BASH_LINENO[$j]}"
      local src="${BASH_SOURCE[$i]}"
      [ -z "$src" ] && src=non_file_source
      echo "$func" "$src" "$linen"
   done
   echo "----------------"
}
export -f ciPrintCallStack

#########################################################################################################
#
# ciPrintMsg($@): affiche le message
#
#
#########################################################################################################
function ciPrintMsg()
{
    echo -e "$@"
    return 0
}
export -f ciPrintMsg

#########################################################################################################
#
# ciVersionMajeurApres($@): test Version Majeur Apres STRCITEMENT
#
#########################################################################################################
function ciVersionMajeurApres()
{
    if [[ -z "$VM_VERSIONMAJEUR" ]]
    then
        return 1
    fi
    #shellcheck disable=SC2206
    local vmCible=(${VM_VERSIONMAJEUR//\./ })
    #shellcheck disable=SC2206
    local vmATester=(${1//\./ })
    delta=$((vmCible[0] - vmATester[0]))
    if [[ $delta -eq 0 ]]
    then
        delta=$((vmCible[1]- vmATester[1]))
        if [[ $delta -eq 0 ]]
        then
            delta=$((vmCible[2] - vmATester[2]))
        fi
    fi
    [[ $delta -gt 0 ]]
}
export -f ciVersionMajeurApres

#########################################################################################################
#
# ciVersionMajeurAPartirDe($@): test Version Majeur a partir de
#
#########################################################################################################
function ciVersionMajeurAPartirDe()
{
    if [[ -z "$VM_VERSIONMAJEUR" ]]
    then
        return 1
    fi
    #shellcheck disable=SC2206
    local vmCible=(${VM_VERSIONMAJEUR//\./ })
    #shellcheck disable=SC2206
    local vmATester=(${1//\./ })
    delta=$((vmCible[0] - vmATester[0]))
    if [[ $delta -eq 0 ]]
    then
        delta=$((vmCible[1] - vmATester[1]))
        if [[ $delta -eq 0 ]]
        then
            delta=$((vmCible[2] - vmATester[2]))
        fi
    fi
    [[ $delta -ge 0 ]]
}
export -f ciVersionMajeurAPartirDe

#########################################################################################################
#
# ciVersionMajeurEgal($@): test Version Majeur egal
#
#########################################################################################################
function ciVersionMajeurEgal()
{
    if [[ -z "$VM_VERSIONMAJEUR" ]]
    then
        return 1
    fi 
    [[ "${VM_VERSIONMAJEUR}" == "${1}" ]]
}
export -f ciVersionMajeurEgal

#########################################################################################################
#
# ciVersionMajeurAvant($@): test Version Majeur Avant
#
#########################################################################################################
function ciVersionMajeurAvant()
{
    if [[ -z "$VM_VERSIONMAJEUR" ]]
    then
        return 1
    fi 
    #shellcheck disable=SC2206
    local vmCible=(${VM_VERSIONMAJEUR//\./ })
    #shellcheck disable=SC2206
    local vmATester=(${1//\./ })
    delta=$((vmCible[0] - vmATester[0]))
    if [[ $delta -eq 0 ]]
    then
        delta=$((vmCible[1] - vmATester[1]))
        if [[ $delta -eq 0 ]]
        then
            delta=$((vmCible[2] - vmATester[2]))
        fi
    fi
    [[ $delta -lt 0 ]]
}
export -f ciVersionMajeurAvant

#########################################################################################################
#
# ciLogger($@): affiche le message dans Syslog
#
#
#########################################################################################################
function ciLogger()
{
#    if ciVersionMajeurAPartirDe "2.8."
#    then
#        if [ ! -f /dev/log ]
#        then
#            if [ ! -f /root/bugdevlog ]
#            then
#                touch /root/bugdevlog
#                echo -e "Machine $VM_MACHINE ${VM_VERSIONMAJEUR} : /dev/log manquant !"
#                ls -l /run/systemd/journal/dev-log /dev/log
#                systemctl status systemd-journald-dev-log.socket
#            fi
#        fi
#    fi
    logger -t EOLECITESTS -- "$@"
    return 0
}
export -f ciLogger


#########################################################################################################
#
# ciPrintMsgMachine($@): affiche le message
#
#########################################################################################################
function ciPrintMsgMachine()
{
    echo -e "Machine $VM_MACHINE ${VM_VERSIONMAJEUR} : $*"
    ciLogger "$@"
    return 0
}
export -f ciPrintMsgMachine

#########################################################################################################
#
# ciPrintConsole($@): affiche le message
#
#########################################################################################################
function ciPrintConsole()
{
    ciPrintMsgMachine "$@"
    if [ "$VM_IS_FREEBSD" == "1" ]
    then
        echo -e "$@" >>/dev/console
    else
        echo -e "$@" >>/dev/tty8
    fi

    return 0
}
export -f ciPrintConsole

#########################################################################################################
#
# ciPrintDebug($@):
#
#########################################################################################################
function ciPrintDebug()
{
    # a l'écran si DEBUG = oui !
    if [[ "${DEBUG}" = all ]] || [[ "${DEBUG}" = true ]] || [[ "${VM_DEBUG}" -gt "0" ]]
    then
        # toujours vers la console 8
        if [ "$VM_IS_FREEBSD" == "1" ]
        then
            echo -e "$@" >>/dev/console
        else
            echo -e "$@" >>/dev/tty8
        fi
        ciPrintMsgMachine "$@"
    fi
    return 0
}
export -f ciPrintDebug

#########################################################################################################
#
# ciPrintErreurAndExit($@): affiche le message
#
#########################################################################################################
function ciPrintErreurAndExit()
{
    echo -e "$@"
    exit 1
}
export -f ciPrintErreurAndExit

#########################################################################################################
#
# ciSignalHack($@): affiche le message
#
#########################################################################################################
function ciSignalHack()
{
    # color RED
    tput setaf 1 -T xterm

    ciPrintMsgMachine "HACK: $*"

    # color RESET
    tput sgr0 -T xterm
    return 0
}
export -f ciSignalHack

#########################################################################################################
#
# ciSignalAttention($@): affiche le message
#
#########################################################################################################
function ciSignalAttention()
{
    # color ORANGE
    tput setaf 172 -T xterm

    ciPrintConsole "ATTENTION: $*"

    # color RESET
    tput sgr0 -T xterm
    return 0
}
export -f ciSignalAttention

#########################################################################################################
#
# ciSignalAlerte($@): affiche le message
#  arg2... = le texte
#########################################################################################################
function ciSignalAlerte()
{
    ciPrintMsg "*****************************************************************"
    # la mise en forme est imposé dans l'automate !
    ciPrintMsg "EOLE_CI_ALERTE: $*"
    ciPrintMsg "*****************************************************************"
    ciLogger "EOLE_CI_ALERTE: $*"
    return 0
}
export -f ciSignalAlerte

#########################################################################################################
#
# ciSignalWarning($@): affiche le message
#  arg2... = le texte
#########################################################################################################
function ciSignalWarning()
{
    ciPrintMsg "*****************************************************************"
    # la mise en forme est imposé dans l'automate !
    ciPrintMsg "EOLE_CI_WARNING: $*"
    ciPrintMsg "*****************************************************************"
    ciLogger "EOLE_CI_WARNING: $*"
    return 0
}
export -f ciSignalWarning

#########################################################################################################
#
# ciAfficheContenuFichier($@): Affiche le contenu du fichier si présent
#
#
#########################################################################################################
function ciAfficheContenuFichier()
{
    if [ -f "$1" ]
    then
        ciPrintMsg "--------------------------------------------"
        ciPrintMsg "cat $1"
        cat "$1" 2>/dev/null
        ciPrintMsg "--------------------------------------------"
    fi
    return 0
}
export -f ciAfficheContenuFichier

#########################################################################################################
#
# ciAfficheDuree()
# affiche la durée en j/h/m/s
#
#########################################################################################################
function ciAfficheDuree()
{
    local T=$1
    if [ "$1" -lt 0 ]
    then
        printf '-'
        printf ' '
        T=$((-$1))
    fi

    local D=$((T/60/60/24))
    local H=$((T/60/60%24))
    local M=$((T/60%60))
    local S=$((T%60))
    (( D > 0 )) && (printf '%d' $D; printf 'j ')
    (( H > 0 )) && (printf '%d' $H; printf 'h ')
    (( M > 0 )) && (printf '%d' $M; printf 'm ')
    (( D > 0 || H > 0 || M > 0 )) && printf 'et '
    printf '%d' $S
    printf 's'
}
export -f ciAfficheDuree

#########################################################################################################
#
# ciEnv()
#
#########################################################################################################
function ciEnv()
{
    bash -c "set -o posix; set | sed -e '/^_/,\$d';" | sort |grep -v "LS_COLORS"|grep -v "^ "
    #printenv |sort |grep -v "LS_COLORS"|grep -v "^ "
}
export -f ciEnv

#########################################################################################################
#
# ciRunPython2($@): Execute une commande python avec python2
#
#########################################################################################################
function ciRunPython2()
{
    local PY
    local PY1

    if ciVersionMajeurAPartirDe "2.8."
    then
        ciSignalWarning "Appel Python2 sur EOLE 2.8 !"
    fi

    ciPrintMsgMachine "ciRunPython2 $*"
    PY=$1
    if [[ "$PY" = "/"* ]]
    then
        python2 -u "$PY" "$2" "$3" "$4" "$5" 2>&1
        result="$?"
        ciPrintConsole "ciRunPython2 $PY ==> RESULT=$result"
        return $result
    fi

    PY1=$VM_DIR_EOLE_CI_TEST/scripts/$PY
    if [ -f "$PY1" ]
    then
        python2 -u "$PY1" "$2" "$3" "$4" "$5" 2>&1
        result="$?"
        ciPrintConsole "ciRunPython2 $PY ==> RESULT=$result"
        return $result
    fi

    if [ -f "./$PY" ]
    then
        python2 -u "./$PY" "$2" "$3" "$4" "$5" 2>&1
        result="$?"
        ciPrintConsole "ciRunPython2 $PY ==> RESULT=$result"
        return $result
    fi

    ciPrintMsgMachine "ciRunPython2: PATH=$PATH"
    ciPrintMsgMachine "ciRunPython2: PWD=$PWD"
    ciPrintErreurAndExit "ERREUR COMMANDE '$PY' INCONNUE"
}
export -f ciRunPython2

#########################################################################################################
#
# ciRunPython($@): Execute une commande python
#
#########################################################################################################
function ciRunPython()
{
    local PY
    local PY1

    MSG="ciRunPython"
    PYTHON="python"
    if ciVersionMajeurAPartirDe "2.8."
    then
        PYTHON="python3"
        MSG="ciRunPython(3)"
    else
        if ! command -v "${PYTHON}" >/dev/null
        then
            PYTHON="python3"
            MSG="ciRunPython(3)"
        fi
    fi

    ciPrintMsgMachine "${MSG} $*"
    PY=$1
    if [[ "$PY" = "/"* ]]
    then
        "${PYTHON}" -u "$PY" "$2" "$3" "$4" "$5" 2>&1
        result="$?"
        ciPrintConsole "${MSG} $PY ==> RESULT=$result"
        return $result
    fi

    PY1=$VM_DIR_EOLE_CI_TEST/scripts/$PY
    if [ -f "$PY1" ]
    then
        "${PYTHON}" -u "$PY1" "$2" "$3" "$4" "$5" 2>&1
        result="$?"
        ciPrintConsole "${MSG} $PY ==> RESULT=$result"
        return $result
    fi

    if [ -f "./$PY" ]
    then
        "${PYTHON}" -u "./$PY" "$2" "$3" "$4" "$5" 2>&1
        result="$?"
        ciPrintConsole "${MSG} $PY ==> RESULT=$result"
        return $result
    fi

    ciPrintMsgMachine "${MSG}: PATH=$PATH"
    ciPrintMsgMachine "${MSG}: PWD=$PWD"
    ciPrintErreurAndExit "ERREUR COMMANDE '$PY' INCONNUE"
}
export -f ciRunPython

#########################################################################################################
#
# ciMonitorWithStrace($@): Execute une commande python avec Strace
#
#########################################################################################################
function ciMonitorWithStrace()
{
    ciPrintMsg "*********************************************"
    if ciVersionMajeurAvant "2.5.0" && [[ -n "${VM_VERSIONMAJEUR}" ]]
    then
        SCRIPT_MONITOR="$VM_DIR_EOLE_CI_TEST/scripts/monitor3/monitor_eole_ci2.py"
        PYTHON="python"
        ciPrintConsole "(py2) ciMonitorWithStrace $*"
    else
        SCRIPT_MONITOR="$VM_DIR_EOLE_CI_TEST/scripts/monitor3/monitor_eole_ci4.py"
        PYTHON="python3"
        ciPrintConsole "(py3) ciMonitorWithStrace $*"
    fi
    PYTHONPATH="$VM_DIR_EOLE_CI_TEST/scripts/monitor3:$VM_DIR_EOLE_CI_TEST/scripts:$PYTHONPATH"
    if [ -z "${http_proxy+x}" ]
    then
        strace -o /tmp/trace_python.log \
           env -i HOME="$HOME" \
               PATH="$PATH" \
               TERM="$TERM" \
               LANG="$LANG" \
               SHELL="$SHELL" \
               USER="$USER" \
               IFS='' \
               PYTHONPATH="$PYTHONPATH" \
               DO_GEN_RPT="$DO_GEN_RPT" \
               VM_ID="$VM_ID" \
               VM_OWNER="$VM_OWNER" \
               VM_ONE="$VM_ONE" \
               VM_VERSIONMAJEUR="${VM_VERSIONMAJEUR}" \
               VM_MACHINE="$VM_MACHINE" \
               VM_MODULE="$VM_MODULE" \
               VM_TIMEOUT="$VM_TIMEOUT" \
               CONFIGURATION="$CONFIGURATION" \
               VM_MAJAUTO="$VM_MAJAUTO" \
               VM_CONTAINER="$VM_CONTAINER" \
               VM_ETABLISSEMENT="$VM_ETABLISSEMENT" \
               VM_NO_ETAB="$VM_NO_ETAB" \
               VM_DEBUG="$VM_DEBUG" \
               "$PYTHON" "$SCRIPT_MONITOR" "$@" 2>&1
    else
        strace -o /tmp/trace_python.log \
           env -i http_proxy="$http_proxy" \
               HOME="$HOME" \
               PATH="$PATH" \
               TERM="$TERM" \
               LANG="$LANG" \
               SHELL="$SHELL" \
               USER="$USER" \
               IFS='' \
               PYTHONPATH="$PYTHONPATH" \
               DO_GEN_RPT="$DO_GEN_RPT" \
               VM_ID="$VM_ID" \
               VM_OWNER="$VM_OWNER" \
               VM_ONE="$VM_ONE" \
               VM_VERSIONMAJEUR="${VM_VERSIONMAJEUR}" \
               VM_MACHINE="$VM_MACHINE" \
               VM_MODULE="$VM_MODULE" \
               VM_TIMEOUT="$VM_TIMEOUT" \
               CONFIGURATION="$CONFIGURATION" \
               VM_MAJAUTO="$VM_MAJAUTO" \
               VM_CONTAINER="$VM_CONTAINER" \
               VM_ETABLISSEMENT="$VM_ETABLISSEMENT" \
               VM_NO_ETAB="$VM_NO_ETAB" \
               VM_DEBUG="$VM_DEBUG" \
               "$PYTHON" "$SCRIPT_MONITOR" "$@" 2>&1
    fi
    result="$?"
    if [ "$result" -ne 0 ]
    then
        grep "open" /tmp/trace_python.log | grep -v ".pyc"
    fi

    ciPrintConsole "ciMonitorWithStrace $PYTHON ==> RESULT=$result"
    return $result
}
export -f ciMonitorWithStrace

#########################################################################################################
#
# ciMonitor($@): Execute une commande python
#
#########################################################################################################
function ciMonitor()
{
    ciPrintMsg "*********************************************"
    if ciVersionMajeurAvant "2.5.0" && [[ -n "${VM_VERSIONMAJEUR}" ]]
    then
        SCRIPT_MONITOR="$VM_DIR_EOLE_CI_TEST/scripts/monitor3/monitor_eole_ci2.py"
        PYTHON="python"
        ciPrintConsole "(py2) ciMonitor $*"
    else
        SCRIPT_MONITOR="$VM_DIR_EOLE_CI_TEST/scripts/monitor3/monitor_eole_ci4.py"
        PYTHON="python3"
        ciPrintConsole "(py3) ciMonitor $*"
    fi
    PYTHONPATH="$VM_DIR_EOLE_CI_TEST/scripts/monitor3:$VM_DIR_EOLE_CI_TEST/scripts:$PYTHONPATH"
    if [ -z "${http_proxy+x}" ]
    then
        env -i HOME="$HOME" \
               PATH="$PATH" \
               TERM="$TERM" \
               LANG="$LANG" \
               SHELL="$SHELL" \
               USER="$USER" \
               IFS='' \
               PYTHONPATH="$PYTHONPATH" \
               DO_GEN_RPT="$DO_GEN_RPT" \
               VM_ID="$VM_ID" \
               VM_OWNER="$VM_OWNER" \
               VM_ONE="$VM_ONE" \
               VM_VERSIONMAJEUR="${VM_VERSIONMAJEUR}" \
               VM_MACHINE="$VM_MACHINE" \
               FRESHINSTALL_MODULE="$FRESHINSTALL_MODULE" \
               VM_MODULE="$VM_MODULE" \
               VM_TIMEOUT="$VM_TIMEOUT" \
               CONFIGURATION="$CONFIGURATION" \
               VM_MAJAUTO="$VM_MAJAUTO" \
               VM_CONTAINER="$VM_CONTAINER" \
               VM_ETABLISSEMENT="$VM_ETABLISSEMENT" \
               VM_NO_ETAB="$VM_NO_ETAB" \
               VM_DEBUG="$VM_DEBUG" \
               "$PYTHON" "$SCRIPT_MONITOR" "$@" 2>&1
    else
        env -i http_proxy="$http_proxy" \
               HOME="$HOME" \
               PATH="$PATH" \
               TERM="$TERM" \
               LANG="$LANG" \
               SHELL="$SHELL" \
               USER="$USER" \
               IFS='' \
               PYTHONPATH="$PYTHONPATH" \
               DO_GEN_RPT="$DO_GEN_RPT" \
               VM_ID="$VM_ID" \
               VM_OWNER="$VM_OWNER" \
               VM_ONE="$VM_ONE" \
               VM_VERSIONMAJEUR="${VM_VERSIONMAJEUR}" \
               VM_MACHINE="$VM_MACHINE" \
               FRESHINSTALL_MODULE="$FRESHINSTALL_MODULE" \
               VM_MODULE="$VM_MODULE" \
               VM_TIMEOUT="$VM_TIMEOUT" \
               CONFIGURATION="$CONFIGURATION" \
               VM_MAJAUTO="$VM_MAJAUTO" \
               VM_CONTAINER="$VM_CONTAINER" \
               VM_ETABLISSEMENT="$VM_ETABLISSEMENT" \
               VM_NO_ETAB="$VM_NO_ETAB" \
               VM_DEBUG="$VM_DEBUG" \
               "$PYTHON" "$SCRIPT_MONITOR" "$@" 2>&1
    fi
    result="$?"
    ciPrintConsole "ciMonitor $PYTHON ==> RESULT=$result"
    return $result
}
export -f ciMonitor


#########################################################################################################
#
# ciMd5ConfigEol()
#
#########################################################################################################
function ciMd5ConfigEol()
{
    if ciVersionMajeurApres "3."
    then
        MD5="EOLE3"
    else
        MD5=$(md5sum "$1" | awk '{ print $1; }')
    fi
}
export -f ciMd5ConfigEol

#########################################################################################################
#
# ciClearJournalLogs
#
#########################################################################################################
function ciClearJournalLogs()
{
    journalctl --flush
    journalctl --rotate
    journalctl --vacuum-time=1s
}
export -f ciClearJournalLogs

#########################################################################################################
#
# ciExportCurrentStatus()
#
#########################################################################################################
function ciExportCurrentStatus()
{
    ciPrintConsole "ciExportCurrentStatus: ($1)"
    if [ "$VM_IS_FREEBSD" == "1" ]
    then
        ps xaf > "$VM_DIR/ps-axwf-cgroups.log"
    else
        ps xawf -eo pid,user='---User---',cgroup='----------CGroup------------',args > "$VM_DIR/ps-axwf-cgroups.log"
    fi
    if command -v systemd-analyze >/dev/null 2>&1
    then
        if [ ! -f "$VM_DIR/systemd-analyze.dot" ]
        then
            systemd-analyze dot >"$VM_DIR/systemd-analyze.dot" 2>/dev/null
            if command -v dot >/dev/null 2>&1
            then
                dot -Tsvg "$VM_DIR/systemd-analyze.dot" >"$VM_DIR/systemd-analyze-dot.svg"
            fi
            systemd-analyze plot >"$VM_DIR/systemd-analyze-plot.svg" 2>"$VM_DIR/systemd-analyze-plot.log"
        fi
        if [ ! -f "$VM_DIR/systemd-critical-chain.log" ]
        then
            (LANG=C systemd-analyze critical-chain --fuzz 1h  | grep -ve '-\.\.\.' )>"$VM_DIR/systemd-critical-chain.log"
            systemd-analyze blame >"$VM_DIR/systemd-blame.log"
        fi
        journalctl --no-pager -xe >"$VM_DIR/systemd-journalctl-xe.log"
    else
        if command -v initctl2dot >/dev/null 2>&1
        then
            initctl2dot -o - >"$VM_DIR/initctl2dot-upstart.dot"
        fi
    fi

    LIST_CONTENEUR="$(lxc-ls 2>/dev/null)"
    for conteneur in $LIST_CONTENEUR
    do
        # si systemd on master ==> systemd on container, hum...
        if command -v systemd-analyze >/dev/null 2>&1
        then
            if [ ! -f "$VM_DIR/${conteneur}-systemd-analyze.dot" ]
            then
                lxc-attach -n "$conteneur" -- systemd-analyze dot >"$VM_DIR/${conteneur}-systemd-analyze.dot" 2>/dev/null
                lxc-attach -n "$conteneur" -- systemd-analyze plot >"$VM_DIR/${conteneur}-systemd-analyze-plot.svg" 2>"$VM_DIR/${conteneur}-systemd-analyze-plot.log"
                (LANG=C lxc-attach -n "$conteneur" -- systemd-analyze critical-chain --fuzz 1h  | grep -ve '-\.\.\.' )>"$VM_DIR/${conteneur}-systemd-critical-chain.log"
                lxc-attach -n "$conteneur" -- systemd-analyze blame >"$VM_DIR/${conteneur}-systemd-blame.log"
            fi
            lxc-attach -n "$conteneur" -- journalctl --no-pager -xe >"$VM_DIR/${conteneur}-systemd-journalctl-xe.log"
        else
            if command -v initctl2dot >/dev/null 2>&1
            then
                lxc-attach -n "$conteneur" -- initctl2dot -o - >"$VM_DIR/${conteneur}-initctl2dot-upstart.dot"
            fi
        fi

    done
    ciPrintConsole "ciExportCurrentStatus: fin"
}
export -f ciExportCurrentStatus

#########################################################################################################
#
# ciEstCeQueLImageEstInstanciee()
#
#########################################################################################################
function ciEstCeQueLImageEstInstanciee()
{
    ciPrintMsgMachine "ciEstCeQueLImageEstInstanciee"

    if ! ciGetContextInstance
    then
        return 0
    else
        local cdu=0
        ciPrintMsg "*************************************************************"
        if [ "$INSTANCE_METHODE" != "$VM_METHODE" ]
        then
            cdu=1
            ciPrintMsg "Dernière Instance : methode différente"
        fi

        if [ "$INSTANCE_CONFIGURATION" != "$CONFIGURATION" ]
        then
            cdu=1
            ciPrintMsg "Dernière Instance : configuration différente"
        fi

        if [ "$INSTANCE_MACHINE" != "$VM_MACHINE" ]
        then
            cdu=1
            ciPrintMsg "Dernière Instance : machine différente"
        fi

        if [ "$INSTANCE_VERSIONMAJEUR" != "${VM_VERSIONMAJEUR}" ]
        then
            cdu=1
            ciPrintMsg "Dernière Instance : version majeure différente"
        fi

        ciMd5ConfigEol /etc/eole/config.eol
        if [ "$INSTANCE_MD5" != "$MD5" ]
        then
            cdu=1
            ciPrintMsg "Dernière Instance : MD5 différent config.eol modifié"
            ciPrintMsg "TAG_MD5 = $INSTANCE_MD5 MD5=$MD5"
        fi

        maintenant=$(date '+%s')
        diff=$(( maintenant - INSTANCE_DATEUPDATE))
        if [[ $diff -gt 70000 ]];
        then
            cdu=1
            diff_texte=$(ciAfficheDuree "$diff")
            ciPrintMsg "Dernière Instance : $diff_texte, > 70000 secondes"
        fi
        if [ "$cdu" -eq 0 ]
        then
            ciPrintMsg "Dernière Instance : Pas besoin de mise à jour !!! "
        fi
        ciPrintMsg "INSTANCE_DATE=$INSTANCE_DATE, cdu=$cdu"
        ciPrintMsg "*************************************************************"
        return $cdu
    fi
}
export -f ciEstCeQueLImageEstInstanciee

#########################################################################################################
#
# Extends LVM root with size
#
#########################################################################################################
function ciExtendsLvm()
{
    ciPrintMsgMachine "ciExtendsLvm $1 $2"

    AJOUTER_A=var
    if [ -n "$1" ]
    then
        AJOUTER_A="$1"
    fi

    TAILLE_EN_PLUS=10G
    if [ -n "$2" ]
    then
        TAILLE_EN_PLUS="$2"
    fi

    ciPrintMsg "Identifier le /dev"
    LVM=$(vgs --noheadings -o name |xargs)
    if [ -z "${LVM}" ]
    then
        ciSignalWarning "impossible de trouver le dev LVM"
        return 1
    fi

    echo "LVM=${LVM}"
    ls -l "/dev/${LVM}"

    LVM_FREE=$(vgs --noheadings -o pv_free | xargs)
    LVM_FREE="${LVM_FREE//\<}"
    echo "LVM_FREE=${LVM_FREE}"

    LV="/dev/${LVM}/keep_1"
    if [[ ! -L "${LV}" ]]
    then
        LV="/dev/${LVM}/keep_2"
        if [[ ! -L "${LV}" ]]
        then
            ciSignalWarning "pas de volume keep_* présent, stop !"
            return 0
        else
            ciSignalWarning "le LVM keep_2 est présent, je l'utilise !"
        fi
    fi

    if [[ -L "${LV}" ]]
    then
        ciPrintMsg "Désactivation du LV inutile ($LV) "
        lvchange -a n "$LV"
        RESULT="$?"
        if [ "$RESULT" -ne 0 ]
        then
            ciSignalWarning "impossible de désactiver le LV '$LV'(exit=$RESULT)"
            return 1
        fi

        ciPrintMsg "Suppression du LV non-actif ($LV) "
        lvremove -f "$LV"
        RESULT="$?"
        if [ "$RESULT" -ne 0 ]
        then
            ciSignalWarning "impossible de supprimer le LV '$LV'(exit=$RESULT)"
            return 1
        fi
    fi

    ciPrintMsg "Lister les LVM"
    lvscan

    ciPrintMsg "Voir l’espace libre sur le VG"
    vgdisplay | grep "Free  PE / Size"

    LVM_FREE1=$(vgs --noheadings -o pv_free | xargs)
    LVM_FREE1="${LVM_FREE1//\<}"
    echo "LVM_FREE1=${LVM_FREE1}"
    if [ "${LVM_FREE1}" == "0" ]
    then
        ciSignalWarning "pas de place disponible pour etendre le LVM"
        return 0
    fi

    ciPrintMsg "Current size LV de /dev/${LVM}/${AJOUTER_A}"
    LV_SIZE=$(lvs "/dev/${LVM}/${AJOUTER_A}" --noheadings -olv_size)
    echo "$LV_SIZE"

    ciPrintMsg "Ajouter ${TAILLE_EN_PLUS} au LV de /dev/${LVM}/${AJOUTER_A}"
    lvextend "-L ${TAILLE_EN_PLUS}" "/dev/${LVM}/${AJOUTER_A}"
    RESULT="$?"
    if [ "$RESULT" -ne 0 ]
    then
        ciSignalWarning "impossible d'étendre le LV (exit=$RESULT)"
        return 1
    fi

    ciPrintMsg "Étendre le système de fichier pour occuper tout l’espace ajouté"
    resize2fs "/dev/${LVM}/${AJOUTER_A}"
    RESULT="$?"
    if [ "$RESULT" -ne 0 ]
    then
        ciSignalWarning "impossible resizer le LV (exit=$RESULT)"
        return 1
    fi

    ciPrintMsg "ciExtendsLvm : ok"
    return 0
}
export -f ciExtendsLvm

#########################################################################################################
#
# Extends LVM root with all size
#
#########################################################################################################
function ciExtendsLvmRoot()
{
    ciPrintMsg "ciExtendsLvmRoot"

    LVM=$(vgs --noheadings -o name |xargs)
    if [ -z "${LVM}" ]
    then
        ciSignalWarning "impossible de trouver le dev LVM"
        return 1
    fi

    AJOUTER_A="/dev/${LVM}/root"
    if [ ! -e "$AJOUTER_A" ]
    then
        AJOUTER_A="/dev/${LVM}/ubuntu-lv"
        if [ ! -e "$AJOUTER_A" ]
        then
            ciSignalWarning "impossible d'étendre le LV ni root ni ubuntu-lv"
            return 1
        fi
    fi
    ciPrintMsg "ciExtendsLvmRoot -> $AJOUTER_A"
	
    LVM_FREE1=$(vgs --noheadings -o pv_free | xargs)
    LVM_FREE1="${LVM_FREE1//\<}"
    echo "LVM_FREE1=${LVM_FREE1}"
    if [ "${LVM_FREE1}" == "0" ]
    then
        ciSignalWarning "pas de place disponible pour etendre le LVM"
        return 0
    fi

    lvextend -L+"${LVM_FREE1}" "$AJOUTER_A"
    RESULT="$?"
    if [ "$RESULT" -ne 0 ]
    then
        ciSignalWarning "impossible d'étendre le LV (exit=$RESULT)"
        return 1
    fi

    ciPrintMsg "Étendre le système de fichier pour occuper tout l’espace ajouté"
    resize2fs "$AJOUTER_A"
    RESULT="$?"
    if [ "$RESULT" -ne 0 ]
    then
        ciSignalWarning "impossible resizer le LV (exit=$RESULT)"
        return 1
    fi
    ciPrintMsg "${LVM_FREE1} ajouter à $AJOUTER_A"
    return 0
}
export -f ciExtendsLvmRoot

#########################################################################################################
#
# ciExtendsLvmWithDisk100G [ <to> [ <size> ]]
#      Extends LVM <to> with <size>go from 2nd disk
#
#########################################################################################################
function ciExtendsLvmWithDisk100G()
{
    ciPrintMsgMachine "ciExtendsLvmWithDisk100G $1 $2"

    AJOUTER_A=var
    if [ -n "$1" ]
    then
        AJOUTER_A="$1"
    fi

    TAILLE_EN_PLUS=10G
    if [ -n "$2" ]
    then
        TAILLE_EN_PLUS="$2"
    fi

    if [ -e /dev/vdb ]
    then
        DISK_SAUVEGARDE=vdb
    else
        if [ -e /dev/sdb ]
        then
            DISK_SAUVEGARDE=sdb
        else
            echo "ERREUR: Impossible de trouvé le disque de sauvegarde, return 1"
            return 1
        fi
    fi

    if [[ ! -b "/dev/${DISK_SAUVEGARDE}" ]]
    then
        echo "ERREUR: le device n'est pas un block device !, stop"
        return 1
    fi

    PV="/dev/${DISK_SAUVEGARDE}1"
    if [[ ! -b "${PV}" ]]
    then
        echo "FDISK ${DISK_SAUVEGARDE} "
        ( printf 'd\nn\np\n1\n\n\n\nw\n' | fdisk /dev/${DISK_SAUVEGARDE} )
    else
        echo "${PV} exist dèjà, pas de formatage"
    fi

    echo "Créer le PV ${PV}"
    pvcreate "${PV}"
    RESULT="$?"
    if [ "$RESULT" -ne 0 ]
    then
        echo "ERREUR: impossible de créer ${PV}, existe déjà ?"
        return 1
    fi

    echo "Identifier le LVM"
    LVM=$(vgs --noheadings -o name |xargs)
    if [ -z "${LVM}" ]
    then
        echo "ERREUR: impossible de trouver le dev LVM"
        return 1
    fi

    echo "Ajouter le disque ${PV} à ${LVM}"
    vgextend "${LVM}" "${PV}"
    RESULT="$?"
    if [ "$RESULT" -ne 0 ]
    then
        echo "ERREUR: impossible d'étendre ${LVM} avec ${PV}, existe déjà dans le vg ?"
        #return 1
    fi

    echo "Ajouter ${TAILLE_EN_PLUS} au LV de /${AJOUTER_A}"
    lvextend "-L+${TAILLE_EN_PLUS}" "/dev/${LVM}/${AJOUTER_A}"
    RESULT="$?"
    if [ "$RESULT" -ne 0 ]
    then
        echo "ERREUR: impossible d'étendre le LV (exit=$RESULT)"
        return 1
    fi

    echo "Étendre le système de fichier pour occuper tout l’espace ajouté"
    resize2fs "/dev/${LVM}/${AJOUTER_A}"
    RESULT="$?"
    if [ "$RESULT" -ne 0 ]
    then
        ciPrintMsg "ERREUR: impossible resizer le LV (exit=$RESULT)"
        return 1
    fi

    echo "ciExtendsLvmWithDisk100G : ok"
    return 0
}
export -f ciExtendsLvmWithDisk100G

#########################################################################################################
#
# Injection des liens dans grp_eole
#
#########################################################################################################
function ciInjectLinks()
{
    ciPrintConsole "Injection des liens dans le Bureau Partage '\\\\<srv>\\icones\\grp_eole\\_Machine\\Bureau/' "
    if [ "$VM_CONTAINER" == "oui" ]
    then
        if ciVersionMajeurAPartirDe "2.7."
        then
            ciSignalHack "inject grp_eole , bizarre !"
            mkdir -p "/home/netlogon/icones/grp_eole/_Machine/Bureau/"
            cp -vf "$VM_DIR_EOLE_CI_TEST/scripts/windows/grp_eole/"*.url /home/netlogon/icones/grp_eole/_Machine/Bureau/
            cp -vf "$VM_DIR_EOLE_CI_TEST/scripts/windows/grp_eole/"*.lnk /home/netlogon/icones/grp_eole/_Machine/Bureau/
        else
            scp "$VM_DIR_EOLE_CI_TEST/scripts/windows/grp_eole/"*.url partage:/home/netlogon/icones/grp_eole/_Machine/Bureau/
            scp "$VM_DIR_EOLE_CI_TEST/scripts/windows/grp_eole/"*.lnk partage:/home/netlogon/icones/grp_eole/_Machine/Bureau/
        fi
    else
        if ciVersionMajeurAPartirDe "2.7."
        then
            ciSignalHack "inject grp_eole , bizarre !"
            mkdir -p "/home/netlogon/icones/grp_eole/_Machine/Bureau/"
            /bin/cp -vf "$VM_DIR_EOLE_CI_TEST/scripts/windows/grp_eole/"*.url "/home/netlogon/icones/grp_eole/_Machine/Bureau/"
            /bin/cp -vf "$VM_DIR_EOLE_CI_TEST/scripts/windows/grp_eole/"*.lnk "/home/netlogon/icones/grp_eole/_Machine/Bureau/"
        else
            scp "$VM_DIR_EOLE_CI_TEST/scripts/windows/grp_eole/"*.url partage:/home/netlogon/icones/grp_eole/_Machine/Bureau/
            scp "$VM_DIR_EOLE_CI_TEST/scripts/windows/grp_eole/"*.lnk partage:/home/netlogon/icones/grp_eole/_Machine/Bureau/
        fi
    fi
}
export -f ciInjectLinks


#########################################################################################################
#
# Telechargement Wpkg Client
#
#########################################################################################################
function ciDownloadWpkgClient()
{
    ciPrintConsole "Téléchargement WPKG_Client"

    if [ "$VM_IS_UBUNTU" == "0" ]
    then
        ciPrintMsgMachine "ciDownloadWpkgClient: n'est pas Ubuntu !"
        return 0
    fi

    WPKG_CLIENT_VERSION=1.3.14-x64.msi
    if [ ! -d /tmp/WPKG_Client_$WPKG_CLIENT_VERSION ]
    then
        if [ ! -f "$VM_DIR_EOLE_CI_TEST/scripts/windows/wpkg/WPKG_Client_$WPKG_CLIENT_VERSION" ]
        then
            wget "http://wpkg.org/files/client/stable/WPKG%20Client%20W$WPKG_CLIENT_VERSION" -O /tmp/WPKG_Client_$WPKG_CLIENT_VERSION
            /bin/cp -f /tmp/WPKG_Client_$WPKG_CLIENT_VERSION "$VM_DIR_EOLE_CI_TEST/scripts/windows/wpkg/WPKG_Client_$WPKG_CLIENT_VERSION"
        else
            /bin/cp -f "$VM_DIR_EOLE_CI_TEST/scripts/windows/wpkg/WPKG_Client_$WPKG_CLIENT_VERSION" /tmp/WPKG_Client_$WPKG_CLIENT_VERSION
        fi
    fi

    WPKG_CLIENT_VERSION=1.3.14-x32.msi
    if [ ! -d /tmp/WPKG_Client_$WPKG_CLIENT_VERSION ]
    then
        if [ ! -f "$VM_DIR_EOLE_CI_TEST/scripts/windows/wpkg/WPKG_Client_$WPKG_CLIENT_VERSION" ]
        then
            wget "http://wpkg.org/files/client/stable/WPKG%20Client%20W$WPKG_CLIENT_VERSION" -O /tmp/WPKG_Client_$WPKG_CLIENT_VERSION
            /bin/cp -f /tmp/WPKG_Client_$WPKG_CLIENT_VERSION "$VM_DIR_EOLE_CI_TEST/scripts/windows/wpkg/WPKG_Client_$WPKG_CLIENT_VERSION"
        else
            /bin/cp -f "$VM_DIR_EOLE_CI_TEST/scripts/windows/wpkg/WPKG_Client_$WPKG_CLIENT_VERSION" /tmp/WPKG_Client_$WPKG_CLIENT_VERSION
        fi
    fi

    # voir : https://drive.google.com/folderview?id=0B9Eadi-crzpOVEtTM01aYm5YNm8&usp=sharing
    WPKG_GP_VERSION=0.17_x64.exe
    WPKG_GP_URL="https://doc-0k-88-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/url2avsl2oqkuqard7gnnuqo9ob8holo/1443780000000/07311612454075409855/*/0B87wGUqZq-0NNEVxbldNUTIyVDg?e=download"
    if [ ! -d /tmp/Wpkg-GP-$WPKG_GP_VERSION ]
    then
        if [ ! -f "$VM_DIR_EOLE_CI_TEST/scripts/windows/wpkg/Wpkg-GP-$WPKG_GP_VERSION" ]
        then
            wget "$WPKG_GP_URL" -O /tmp/Wpkg-GP-$WPKG_GP_VERSION
            /bin/cp -f /tmp/Wpkg-GP-$WPKG_GP_VERSION "$VM_DIR_EOLE_CI_TEST/scripts/windows/wpkg/Wpkg-GP-$WPKG_GP_VERSION"
        else
            /bin/cp -f "$VM_DIR_EOLE_CI_TEST/scripts/windows/wpkg/Wpkg-GP-$WPKG_GP_VERSION" /tmp/Wpkg-GP-$WPKG_GP_VERSION
        fi
    fi

    WPKG_GP_VERSION=0.17_x86.exe
    WPKG_GP_URL="https://doc-00-88-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/q2h9utr13b0edqlpgo0f3cinj8kt3a44/1443780000000/07311612454075409855/*/0B87wGUqZq-0NOVl5LXZKdFlhZTg?e=download"
    if [ ! -d /tmp/Wpkg-GP-$WPKG_GP_VERSION ]
    then
        if [ ! -f "$VM_DIR_EOLE_CI_TEST/scripts/windows/wpkg/Wpkg-GP-$WPKG_GP_VERSION" ]
        then
            wget "$WPKG_GP_URL" -O /tmp/Wpkg-GP-$WPKG_GP_VERSION
            /bin/cp -f /tmp/Wpkg-GP-$WPKG_GP_VERSION "$VM_DIR_EOLE_CI_TEST/scripts/windows/wpkg/Wpkg-GP-$WPKG_GP_VERSION"
        else
            /bin/cp -f "$VM_DIR_EOLE_CI_TEST/scripts/windows/wpkg/Wpkg-GP-$WPKG_GP_VERSION" /tmp/Wpkg-GP-$WPKG_GP_VERSION
        fi
    fi
}
export -f ciDownloadWpkgClient

#########################################################################################################
#
# checkExitCode($@)
#
#########################################################################################################
function ciCheckExitCode()
{
    if [[ "$1" -eq 0 ]]
    then
        return 0
    fi

    if [[ -n "$2" ]]
    then
        ciPrintConsole "CheckExitCode $1 ! ($2)"
    else
        ciPrintConsole "CheckExitCode $1"
    fi
    exit "$1"
}
export -f ciCheckExitCode

#########################################################################################################
#
# monitor la commande 'apt-eole'
#
#########################################################################################################
function ciAptEole()
{
    ciPrintConsole "Installation paquets : $*"
    apt-eole install "$@"
    RETOUR=$?
    if [[ "$RETOUR" -ne 0 ]]
    then
        ciPrintMsgMachine "erreur apt-eole '$*' ==> sauvegarde creoled"
        [ -f /var/log/creoled.log ] && /bin/cp /var/log/creoled.log  "$VM_DIR"
        #if [[ "$VM_MAJAUTO" = "DEV" ]]
        #then
        #    ciPrintMsgMachine "apt-eole install $* ==> exit=$RETOUR"
        #    ciSignalHack "En MODE DEV ignore !"
        #    ciSignalWarning "apt-eole install $* ==> exit=$RETOUR, ignoré en DEV"
        #else
        bash sauvegarde-fichier.sh apt-eole
        ciCheckExitCode "$RETOUR" "apt-eole install $*"
        #fi
    fi
    ciPrintMsgMachine "----"
    return 0
}
export -f ciAptEole

#########################################################################################################
#
# Install Bareos
#
#########################################################################################################
function ciInstallBareos()
{
    echo "* install eole-bareos"
    if ciVersionMajeurApres "2.5.0"
    then
        ciAptEole eole-bareos
    else
        ciAptEole eole-bacula
    fi
}
export -f ciInstallBareos

#########################################################################################################
#
# ciCheckCreoled: check serveur creoled
#
#########################################################################################################
function ciCheckCreoled()
{
    if ciVersionMajeurApres "3."
    then
        ciPrintMsgMachine "plus de Creoled sur EOLE3 !"
        return 0
    fi

    if ciWaitTcpPort localhost 8000 2
    then
        ciPrintMsgMachine "ciCheckCreoled ok"
        return 0
    else
        ciPrintMsgMachine "ciCheckCreoled ERREUR"
        ciSignalWarning "Redémarrage de creoled car manquant !"
        service creoled stop
        service creoled start
        ciWaitTcpPort localhost 8000 10
        ciCheckExitCode $? "ciWaitTcpPort localhost"
    fi
}
export -f ciCheckCreoled

#########################################################################################################
#
# affiche les info du ccertificat
#
#########################################################################################################
function ciDisplayCertificatInfo()
{
    ls -l "$1"
    openssl x509 -in "$1" -noout -issuer -subject -dates | sed 's/^/    /'
}
export -f ciDisplayCertificatInfo

#########################################################################################################
#
# sauvegarde Ca pour enregistrement zephir futur
#
#########################################################################################################
function ciSauvegardeCaMachine()
{
    if ciVersionMajeurAvant "2.6.0"
    then
        return 0
    fi

    if [ ! -f /etc/ssl/certs/ca_local.crt ]
    then
        return 0
    fi

    local CDU=0
    if [ -f /var/lib/samba/private/tls/ca.pem ]
    then
        ciPrintMsgMachine "Sauvegarde CA SAMBA pour $VM_MACHINE"
        /bin/cp -f /var/lib/samba/private/tls/ca.pem "$DIR_OUTPUT_OWNER/${VM_MACHINE}_ca_samba.pem"
        CDU="$?"
        ciDisplayCertificatInfo "$DIR_OUTPUT_OWNER/${VM_MACHINE}_ca_samba.pem"
    fi

    if [ "$VM_MACHINE" = "aca.zephir" ]
    then
        ciPrintMsgMachine "Sauvegarde CA $VM_MACHINE"
        /bin/cp -f /etc/ssl/certs/ca_local.crt "$DIR_OUTPUT_OWNER/ca_zephir.crt"
        CDU="$?"
        /bin/cp -f /etc/ssl/certs/ca_local.crt "$DIR_OUTPUT_OWNER/${VM_MACHINE}.crt"
        ciDisplayCertificatInfo "$DIR_OUTPUT_OWNER/${VM_MACHINE}.crt"
        return $CDU
    fi
    if [ "$VM_MACHINE" = "etb1.scribe" ]
    then
        ciPrintMsgMachine "Sauvegarde CA $VM_MACHINE"
        /bin/cp -f /etc/ssl/certs/ca_local.crt "$DIR_OUTPUT_OWNER/${VM_MACHINE}.crt"
        CDU="$?"
        ciDisplayCertificatInfo "$DIR_OUTPUT_OWNER/${VM_MACHINE}.crt"
        return $CDU
    fi
    if [ "$VM_MACHINE" = "etb3.amonecole" ]
    then
        ciPrintMsgMachine "Sauvegarde CA $VM_MACHINE"
        /bin/cp -f /etc/ssl/certs/ca_local.crt "$DIR_OUTPUT_OWNER/${VM_MACHINE}.crt"
        CDU="$?"
        ciDisplayCertificatInfo "$DIR_OUTPUT_OWNER/${VM_MACHINE}.crt"
        return $CDU
    fi

    if [ -f /etc/ssl/certs/ca_local.crt ]
    then
        ciPrintMsgMachine "Sauvegarde CA $VM_MACHINE"
        /bin/cp -f /etc/ssl/certs/ca_local.crt "$DIR_OUTPUT_OWNER/${VM_MACHINE}.crt"
        CDU="$?"
        ciDisplayCertificatInfo "$DIR_OUTPUT_OWNER/${VM_MACHINE}.crt"
    fi

    return $CDU
}
export -f ciSauvegardeCaMachine

#########################################################################################################
#
# ciGetCaZephir($@) : recupere la Ca du Zephir
#
# Attention : référencé dans les tests squash
#########################################################################################################
function ciGetCaZephir()
{
    ciInjectCaMachineSsh zephir.ac-test.fr
}
export -f ciGetCaZephir

#########################################################################################################
#
# ciImportCaCertificatSSLInLocalStore <hostname> [<port>]: recupere la Ca du host
#########################################################################################################
function ciImportCaCertificatSSLInLocalStore()
{
  local HOST_REMOTE
  local PORT_REMOTE
  local RESULT

  HOST_REMOTE="$1"
  PORT_REMOTE="${2:-443}"
  RESULT=0
  echo "importCaCertificatSSLInLocalStore ${HOST_REMOTE}:${PORT_REMOTE}"
  # curl --verbose https://live.cardeasexml.com/ultradns.php
  # test OK -> stop
  # openssl x509 -noout -serial -fingerprint -sha1 -inform dem -in
  if echo "x" | timeout 1 openssl s_client -servername "${HOST_REMOTE}" -connect "${HOST_REMOTE}:${PORT_REMOTE}" -showcerts 2>/tmp/showcerts.err >/tmp/showcerts;
  then
    mkdir -p /tmp/import-certs/
    sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' </tmp/showcerts >"/tmp/certs.pem"
    ISSUER=$(openssl x509 -in /tmp/certs.pem -issuer -noout |sed 's/.* //')
    TROUVE="0"
    while read -r F
    do
        if ! diff /tmp/certs.pem "$F" >/dev/null
        then
            TROUVE="1"
        fi
    done < <(find /tmp/import-certs/ -name '*.pem')
    if [ "$TROUVE" == "0" ]
    then
        cp /tmp/certs.pem "/tmp/import-certs/$ISSUER.pem"
        cp "/tmp/import-certs/$ISSUER.pem" "/usr/local/share/ca-certificates/$ISSUER.crt"
        RESULT="1"
    fi
  fi
  /bin/rm /tmp/showcerts.err
  /bin/rm /tmp/showcerts
  return $RESULT
}
export -f ciImportCaCertificatSSLInLocalStore

#########################################################################################################
#
# ciInjectCaMachineSsh($@) : recupere la Ca de la Machine et inject la dans le catalogue CA system
#
#########################################################################################################
function ciInjectCaMachineSsh()
{
    # utiliser cette fonction si il a un accès SSH, sinon utiliser ciInjectCaMachineVirtfs !
    if ciVersionMajeurAvant "2.6.0"
    then
        return 0
    fi

    test -n "${1}"
    ciCheckExitCode "$?" "ciInjectCaMachineSsh nom host distant non renseigné"

    local REMOTE_SERVER="root@${1}"
    local REMOTE_CA_PATH="/etc/ssl/certs/ca_local.crt"
    local REMOTE_CA_URL="${REMOTE_SERVER}:${REMOTE_CA_PATH}"
    local LOCAL_CA_NAME="${2:-${1}-ca}"
    local LOCAL_CA_PATH="/usr/local/share/ca-certificates/${LOCAL_CA_NAME}.crt"

    ciSignalAttention "INJECTION CA ${REMOTE_CA_URL} EN LOCAL À ${LOCAL_CA_PATH}"
    ciMonitor scp "${REMOTE_CA_URL}" "${LOCAL_CA_PATH}"
    ciCheckExitCode "$?" "scp"

    update-ca-certificates
    ciCheckExitCode "$?" "update-ca-certificates"

    ls -l "${LOCAL_CA_PATH}"
    ciPrintMsgMachine "Affiche infos certificat ${LOCAL_CA_PATH}"
    openssl x509 -in "${LOCAL_CA_PATH}" -noout -issuer -subject -dates -purpose

    ciPrintMsgMachine "Comparaison des certificats '${REMOTE_CA_URL}' et '${LOCAL_CA_PATH}'"
    ciMonitor ssh "${REMOTE_SERVER}" sha256sum "${REMOTE_CA_PATH}"
    sha256sum "${LOCAL_CA_PATH}"

    return 0
}
export -f ciInjectCaMachineSsh


#########################################################################################################
#
# ciInjectCaMachineVirtfs($@) : recupere la Ca de la Machine et inject la dans le catalogue CA system
#
#########################################################################################################
function ciInjectCaMachineVirtfs()
{
    # utiliser cette fonction si il n'y a pas d'accès SSH
    if ciVersionMajeurAvant "2.6.0"
    then
        return 0
    fi

    local CA_A_IMPORTER="${1}"
    local NOM_CA="${2:-$CA_A_IMPORTER}"
    if [ -f "$DIR_OUTPUT_OWNER/${CA_A_IMPORTER}.crt" ]
    then
        ciSignalAttention "INJECTION CA ${CA_A_IMPORTER} EN LOCAL "

        ciPrintMsgMachine "ls -l $DIR_OUTPUT_OWNER/${CA_A_IMPORTER}.crt"
        ls -l "$DIR_OUTPUT_OWNER/${CA_A_IMPORTER}.crt"

        ciPrintMsgMachine "/bin/cp -f $DIR_OUTPUT_OWNER/${CA_A_IMPORTER}.crt /usr/local/share/ca-certificates/${NOM_CA}.crt"
        /bin/cp -f "$DIR_OUTPUT_OWNER/${CA_A_IMPORTER}.crt" "/usr/local/share/ca-certificates/${NOM_CA}.crt"
        ciCheckExitCode "$?" "Copie de la CA"
        update-ca-certificates
        ciCheckExitCode "$?" "update-ca-certificates"

        ls -l "/usr/local/share/ca-certificates/${NOM_CA}.crt"
        ciPrintMsgMachine "Affiche infos certificat /usr/local/share/ca-certificates/${NOM_CA}.crt "
        openssl x509 -in "/usr/local/share/ca-certificates/${NOM_CA}.crt" -noout -issuer -subject -dates -purpose

    else
        ciPrintMsgMachine "ERREUR: la CA ${CA_A_IMPORTER} n''existe pas ! "
        return 1
    fi
    return 0
}
export -f ciInjectCaMachineVirtfs

#########################################################################################################
#
# ciInjectCaLDAPMA($@) : recupere la Ca de la Machine LDAPMA et l’injecte dans le catalogue CA system
# et le fichier /etc/certs/certificat.pem si il existe
#
#########################################################################################################
function ciInjectCaLDAPMA()
{
    local ldapma_ca
    ldapma_ca="$VM_DIR_EOLE_CI_TEST/dataset/ecologie/ldapma/etc/certs/CAldap.pem"
    if ciVersionMajeurAvant "2.6.0"
    then
        return 0
    fi

    if [ -f "${ldapma_ca}" ]
    then
        system_certs="$(openssl crl2pkcs7 -nocrl -certfile /etc/ssl/certs/ca-certificates.crt | openssl pkcs7 -print_certs -noout | sed -e 's/issuer=\s*//' -e 's/subject=\s*//')"
        if [[ "${system_certs}" =~ $(openssl x509 -in "$ldapma_ca" -subject -issuer -noout | sed -e 's/issuer=\s*//' -e 's/subject=\s*//' ) ]]
        then
            ciSignalAttention "CA CAldap.pem deja dans le bundle EN LOCAL "
        else

            ciSignalAttention "INJECTION CA CAldap.pem EN LOCAL "
            ciPrintMsgMachine "/bin/cp -f $ldapma_ca /usr/local/share/ca-certificates/ldapma_ca.pem"
            /bin/cp -f "$ldapma_ca" "/usr/local/share/ca-certificates/ldapma_ca.pem"
            ciCheckExitCode "$?" "Copie de la CA"
            update-ca-certificates
            ciCheckExitCode "$?" "update-ca-certificates"
        fi
        if [ -f "/etc/certs/certificat.pem" ]
        then
            local_certs="$(openssl crl2pkcs7 -nocrl -certfile /etc/certs/certificat.pem | openssl pkcs7 -print_certs -noout | sed -e 's/issuer=\s*//' -e 's/subject=\s*//')"
            if [[ "${local_certs}" =~ $(openssl x509 -in "$ldapma_ca" -subject -issuer -noout | sed -e 's/issuer=\s*//' -e 's/subject=\s*//' ) ]]
            then
                ciSignalAttention "CA CAldap.pem deja dans le bundle /etc/certs/certificat.pem "
            else
                ciPrintMsgMachine "openssl x509 -in $VM_DIR_EOLE_CI_TEST/dataset/ecologie/ldapma/etc/certs/CAldap.pem >> /etc/certs/certificat.pem"
                openssl x509 -in "${VM_DIR_EOLE_CI_TEST}/dataset/ecologie/ldapma/etc/certs/CAldap.pem" >> /etc/certs/certificat.pem
            fi
        fi
        return 0
    else
        ciPrintMsgMachine "ERREUR: la CA ${CA_A_IMPORTER} n''existe pas ! "
        return 1
    fi
}
export -f ciInjectCaLDAPMA

#########################################################################################################
#
# test l'acces Http à test-eole.ac-dijon.fr
#
#########################################################################################################
function ciTestHttp()
{
    local URL
    if [ -z "$1" ]
    then
        URL=http://test-eole.ac-dijon.fr/eole/
    else
        URL="${1}"
    fi
    
    local DISPLAY_ERROR=oui
    if [ "$2" == NO_DISPLAY_ERROR ]
    then
        DISPLAY_ERROR=non
    fi
    
    if [ "$VM_IS_UBUNTU" == "1" ]
    then
        wget --no-check-certificate --dns-timeout=60 --connect-timeout=60 -v -O- "$URL" >/tmp/testHttp 2>&1
    fi
    if [ "$VM_IS_FREEBSD" == "1" ]
    then
        curl --verbose --max-time 5 --head "$URL" 2>&1 | tee >/tmp/testHttp
    fi
    if grep "200 OK" /tmp/testHttp >/dev/null
    then
        ciPrintMsgMachine "ciTestHttp : Test accés dépot '$URL' : OK"
        return 0
    else
        ciPrintMsgMachine "ciTestHttp : Test accés dépot '$URL' : ERREUR"
        if [ "$DISPLAY_ERROR" == oui ]
        then
            cat /tmp/testHttp
        fi
        return 1
    fi
}
export -f ciTestHttp

#########################################################################################################
#
# ciDisagnoseNetwork($@): Diagnose Network
#########################################################################################################
function ciDiagnoseNetwork()
{
    ciPrintMsgMachine "ciDiagnoseNetwork:"

    ciGetNamesInterfaces

    if [ "$VM_IS_UBUNTU" == "1" ]
    then
        ciPrintMsg "** ip addr"
        /bin/ip addr

        ciPrintMsg "** ip route"
        /bin/ip route
        
    fi

    GW_ACTUEL="$(ciGetGatewayIP)"
    ciPrintMsg "** GW_ACTUEL : $GW_ACTUEL"

    if [ "$VM_IS_UBUNTU" == "1" ]
    then
        ls -l /etc/netplan 2>/dev/null
        ciAfficheContenuFichier /etc/netplan/01-netcfg.yaml
        ciAfficheContenuFichier /etc/netplan/01-network-manager-all.yaml
        ciAfficheContenuFichier /etc/netplan/50-cloud-init.yaml
        ciAfficheContenuFichier /etc/network/interfaces
        ciAfficheContenuFichier /etc/resolv.conf
        ciAfficheContenuFichier /etc/systemd/resolved.conf
        ciAfficheContenuFichier /run/systemd/resolve/stub-resolv.conf
        ls -l /etc/resolv.conf /etc/systemd/resolved.conf /run/systemd/resolve/stub-resolv.conf 2>/dev/null
    fi
    if [ "$VM_IS_FREEBSD" == "1" ]
    then
        ciAfficheContenuFichier /etc/network/interfaces
        ciAfficheContenuFichier /etc/resolv.conf
    fi

    if command -v systemctl >/dev/null 2>/dev/null
    then
         ciPrintMsgMachine "systemctl is-active network.target : $(systemctl is-active network.target)"
         ciPrintMsgMachine "systemctl is-active network-online.target : $(systemctl is-active network-online.target)"
         ciPrintMsgMachine "systemctl is-system-running : $(systemctl is-system-running)"
    fi

    if ! ciPingHost 192.168.0.1 "$VM_INTERFACE0_NAME"
    then
        # Grave
        ciPrintMsg "** iptables"
        iptables -t filter -S; iptables -t nat -S; iptables -t mangle -S; iptables -t raw -S; 
        
        ciPrintMsg "** systemd-resolved status "
        systemctl status --no-pager systemd-resolved.service
        
        if command -v resolvectl 2>/dev/null
        then
            ciPrintMsg "** resolvectl"
            resolvectl
        fi
    fi
}
export -f ciDiagnoseNetwork

#########################################################################################################
#
# ciWaitTestHttp($@): Attente acces Http
# arg1: url
# arg2: maxtry
#########################################################################################################
function ciWaitTestHttp()
{
    local url
    local maxtry
    local cdu
    local counter

    url="$1"
    maxtry=$2

    counter=0
    while [[ ${counter} -lt ${maxtry} ]] ;
    do
        counter=$(( counter + 1 ))
        if ciTestHttp "${url}" NO_DISPLAY_ERROR
        then
            return 0
        fi
        ciPrintMsgMachine "ciWaitTestHttp (${counter}/${maxtry}): wait.."
        sleep 10
    done

    ciTestHttp "${url}" DISPLAY_ERROR
    ciDiagnoseNetwork >"$VM_DIR/ciDignoseNetwork.log" 2>&1
    echo "EOLE_CI_PATH ciDignoseNetwork.log"
    ciPrintErreurAndExit "ERREUR: ciWaitTestHttp ${url} : timeout, service non disponible, STOP ! $(date "+%Y-%m-%d %H:%M:%S")"
}
export -f ciWaitTestHttp

#########################################################################################################
#
# postionne http_proxy uniquement si /etc/eole/config.eol n'existe pas
#
#########################################################################################################
function ciSetHttpProxy()
{
    if [ "$VM_MACHINE" = "daily" ]
    then
        ciPrintMsgMachine "ciSetHttpProxy, pas de proxy pour les Daily"
        unset http_proxy
        return 0
    fi

    #if ciVersionMajeurEgal "2.7.0"
    #then
    #    ciSignalHack "ciSetHttpProxy, NO_PROXY pour 127.0.0.1,localhost"
    #    export no_proxy=127.0.0.1,localhost
    #fi

# Si en 2.5.x
#  W: Impossible de récupérer https://esm.ubuntu.com/ubuntu/dists/trusty-infra-security/main/binary-amd64/Packages  server certificate verification failed. CAfile: /etc/ssl/certs/ca-certificates.crt CRLfile: none
# il faut ajouter le proxy !
#    if ciVersionMajeurAvant "2.6.1"
#    then
#        ciPrintMsgMachine "ciSetHttpProxy, pas de proxy avant version 2.6.1 ! (${VM_VERSIONMAJEUR})"
#        unset http_proxy
#        return 0
#    fi

    if [[ "$VM_ETABLISSEMENT" = "rie" ]]
    then
        ciPrintMsgMachine "ciSetHttpProxy, pas de proxy pour les machines 'rie'"
        unset http_proxy
        return 0
    fi

    if [[ "$VM_ETABLISSEMENT" = "aca" ]]
    then
        ciPrintMsgMachine "ciSetHttpProxy, pas de proxy pour les machines 'academie'"
        unset http_proxy
        return 0
    fi

    if [[ -n "$VM_ETH1_GW" ]] && [[ "$VM_ETH1_NAME" == "RIE" ]]
    then
        ciPrintMsgMachine "ciSetHttpProxy, la machine a une patte sur 'rie', pas de proxy ($VM_ETH1_GW,$VM_ETH1_NAME)"
        unset http_proxy
        return 0
    fi

    if [[ -n "$VM_ETH0_GW" ]] && [[ "$VM_ETH0_NAME" == "academie" ]]
    then
        ciPrintMsgMachine "ciSetHttpProxy, la machine a une patte sur 'academie', pas de proxy"
        unset http_proxy
        return 0
    fi

    if [[ "$VM_ETABLISSEMENT" = "etb3" ]]
    then
        ciSignalAttention "ciSetHttpProxy, Injection 'http_proxy=http://admin:eole@10.3.2.2:3128' "
        export http_proxy=http://admin:eole@10.3.2.2:3128
        return 0
    fi

    ciSignalAttention "ciSetHttpProxy, Injection 'http_proxy=http://admin:eole@$VM_ETH0_GW:3128' "
    export http_proxy=http://admin:eole@$VM_ETH0_GW:3128
    return 0
}
export -f ciSetHttpProxy

#########################################################################################################
#
# postionne http_proxy uniquement si /etc/eole/config.eol n'existe pas
#
#########################################################################################################
function ciSetHttpAndHttpsProxy()
{
    ciSetHttpProxy
    if [ -v http_proxy ]
    then
        export https_proxy="${http_proxy}"
        ciSignalAttention "ciSetHttpAndHttpsProxy, Injection 'https_proxy=${https_proxy}' "
    else
        unset https_proxy
    fi
}
export -f ciSetHttpAndHttpsProxy

#########################################################################################################
#
# ciInjectClamBD
#
#########################################################################################################
function ciInjectClamBD()
{
    ciPrintMsgMachine "ciInjectClamBD"

    if ciVersionMajeurAvant "2.9.0"
    then
        return 0
    fi

    ciGetDirConfiguration
    if [ ! -d "$DIR_CONFIGURATION/clamd" ]
    then
        mkdir "$DIR_CONFIGURATION/clamd"
    fi
    for f in main.cvd bytecode.cvd daily.cvd
    do
        if [ -f "$DIR_CONFIGURATION/clamd/$f" ]
        then
            if [ ! -f "/var/lib/clamav/$f" ]
            then
                echo "$f n'existe pas dans /var/lib/clamav"
                cp -v "$DIR_CONFIGURATION/clamd/$f" "/var/lib/clamav/$f"
            else
                if test "$DIR_CONFIGURATION/clamd/$f" -nt "/var/lib/clamav/$f"
                then
                    echo "$f restaure car plus récent"
                    cp -v "$DIR_CONFIGURATION/clamd/$f" "/var/lib/clamav/$f"
                else
                    echo "$f déja à jour"
                fi
            fi
        else
            echo "$f n'existe pas dans la sauvegarde"
        fi
    done
}
export -f ciInjectClamBD

#########################################################################################################
#
# ciSauvegardeClamBD
#
#########################################################################################################
function ciSauvegardeClamBD()
{
    ciPrintMsgMachine "ciSauvegardeClamBD"

    if ciVersionMajeurAvant "2.9.0"
    then
        return 0
    fi

    ciGetDirConfiguration
    if [ ! -d "$DIR_CONFIGURATION/clamd" ]
    then
        mkdir "$DIR_CONFIGURATION/clamd"
    fi
    for f in main.cvd bytecode.cvd daily.cvd
    do
        if [ ! -f "/var/lib/clamav/$f" ]
        then
            echo "$f n'existe pas dans /var/lib/clamav"
            continue
        fi
        if [ -f "$DIR_CONFIGURATION/clamd/$f" ]
        then
            if test "/var/lib/clamav/$f" -nt "$DIR_CONFIGURATION/clamd/$f"
            then
                echo "$f sauvegarde car nouveau"
                cp -v "/var/lib/clamav/$f" "$DIR_CONFIGURATION/clamd/$f"
            else
                echo "$f déja à jour"
            fi
        else
            echo "$f nouvelle sauvegarde"
            cp -v "/var/lib/clamav/$f" "$DIR_CONFIGURATION/clamd/$f"
        fi
    done
}
export -f ciSauvegardeClamBD

#########################################################################################################
#
# execute des commandes avant Instance
#
#########################################################################################################
function ciAvantInstance()
{
    ciSetHttpProxy
    ciTestHttp

    ciPrintMsgMachine "ciAvantInstance : Installation paquets complémentaires avant instance"

    case "$VM_MACHINE" in
        aca.zephir)
            if ciVersionMajeurEgal "2.3"
            then
                ciAptEole esbl-zephir-module ecdl-zephir-module eole-zephir-medde
            else
                ciAptEole eole-zephir-medde
            fi
            ;;

        aca.proxy)
            if ciVersionMajeurAPartirDe "2.9."
            then
                ciAptEole eole-proxy eole-sso-client
            else
                ciAptEole eole-proxy eole-sso
            fi

            ciInjectClamBD

            ;;

        aca.dc1)
            if ciVersionMajeurApres "2.6.1"
            then
                if [ "$CONFIGURATION" == "ecologie" ]
                then
                    ciAptEole seth-ecologie
                elif [ "$CONFIGURATION" == "default" ]
                then
                    if ciVersionMajeurAvant "2.8.0"
                    then
                        ciAptEole seth-education
                    fi
                fi
            fi

            if ciVersionMajeurApres "2.7.0"
            then
                if ! dpkg -l eolead-gpo-script >/dev/null 2>&1
                then
                    ciAptEole eole-gpo-script
                fi
            fi
            if ciVersionMajeurApres "2.7.1"
            then
                if [ "$CONFIGURATION" == "setheducation" ]
                then
                    ciMajAutoSansTest
                    ciAptEole eole-seth-education eole-seth-aaf eole-workstation
                fi
            fi

            if ciVersionMajeurApres "2.7.1" && ciVersionMajeurAvant "2.8.1"
            then
                ciAptEole eole-ad-dc-pso
                ciAptEole eole-ad-dc-ou
            fi

            ;;

        aca.dc2)
            if ciVersionMajeurApres "2.7.1"
            then
                if [ "$CONFIGURATION" == "setheducation" ]
                then
                    ciMajAutoSansTest
                    ciAptEole eole-seth-education
                fi
            fi
            ;;

        aca.file)
            if ciVersionMajeurApres "2.6.1"
            then
                ciAptEole eole-fichier-actions
            fi
            if ciVersionMajeurApres "2.7.1"
            then
                if [ "$CONFIGURATION" == "setheducation" ]
                then
                    ciMajAutoSansTest
                    ciAptEole eole-seth-education
                fi
            fi
            ;;

        aca.scribe)
            if [ "$CONFIGURATION" == "scribead" ]
            then
                ciAptEole scribe-ad
            fi

            if ciVersionMajeurApres "2.7.1" && ciVersionMajeurAvant "2.8.1"
            then
                ciAptEole eole-ad-dc-pso
                ciAptEole eole-ad-dc-ou
            fi
            ;;

        etb1.amon)
            ciInstallBareos

            ciInjectClamBD

            ;;

        etb1.fogserver)
            if ciVersionMajeurAPartirDe "2.8."
            then
                ciSetHttpAndHttpsProxy
                ciAptEole eole-fog
            fi
            ;;

        etb1.scribe)
            if [ "$CONFIGURATION" == "scribead" ]
            then
                ciAptEole scribe-ad
            fi

            if [ "$CONFIGURATION" != "eolead" ]
            then
                # etb1.scribe : toutes versions
                ciAptEole eole-ecostations
                ciAptEole eole-infosquota
                if ciVersionMajeurAPartirDe "2.9."
                then
                    ciSignalWarning "EJabberd désactivé en version ${VM_VERSIONMAJEUR}"
                else
                    ciAptEole eole-ejabberd
                fi

                if ciVersionMajeurAPartirDe "2.8."
                then
                   ciSignalWarning "OCS non porté en version ${VM_VERSIONMAJEUR} : #31081"
                else
                   ciAptEole eole-esbl-ocs
                fi

                if ciVersionMajeurApres "2.7.0"
                then
                    #if ciVersionMajeurAPartirDe "2.9."
                    #then
                    #   ciSignalWarning "GLPI désactivé en version ${VM_VERSIONMAJEUR}"
                    #else
                        ciAptEole eole-glpi
                    #fi
                else
                    ciAptEole eole-esbl-glpi
                    ciAptEole eole-wpkg
                fi

                if ciVersionMajeurApres "2.7.1" && ciVersionMajeurAvant "2.8.1"
                then
                    ciAptEole eole-ad-dc-pso
                    ciAptEole eole-ad-dc-ou
                fi

            fi

            if [ "$CONFIGURATION" == "lemonng" ]
            then
                ciAptEole eole-lemonldap-ng-scribe
            fi

            apt-get install --fix-missing

            ciPrintConsole "Injection /etc/nut/dummy.dev"
            /bin/cp -f "$VM_DIR_EOLE_CI_TEST/dataset/nut/dummy.dev" /etc/nut/
            chmod 640 /etc/nut/dummy.dev
            chown nut:nut /etc/nut/dummy.dev
            if [ -d /etc/bareos/bareosfichiers.d ]
            then
            cat > /etc/bareos/bareosfichiers.d/nut.conf<<EOF
Include {
  Options {
    aclsupport = no
    @/etc/bareos/include-options.conf
  }
  File = /etc/nut/dummy.dev
}
EOF
            fi
            ;;

        etb1.eclairdmz)
            # ne pas installer eole-gaspacho-agent, car il a besoin du CA du scribe. Nous voulons pouvoir enregistrer l'image
            # donc dans les tests, il faut ajouter gaspacho + injecter la CA + reconfigure
            ;;

        etb3.eclair)
            #fait dans init-eclair-001.sh
            #if ciVersionMajeurApres "2.6.0"
            #then
            #    ciAptEole eole-gaspacho-agent
            #    ciInjectCaMachineVirtfs etb3.amonecole gaspacho-server
            #fi
            ;;

        etb3.amonecole)

            if ciVersionMajeurApres "2.7.0"
            then
                if [ "$CONFIGURATION" != "lemonng" ]
                then
                    ciAptEole eole-glpi
                fi
            else
                ciAptEole eole-esbl-glpi
            fi

            if ciVersionMajeurAPartirDe "2.8."
            then
                ciAptEole eole-infosquota
                ciSignalWarning "OCS non porté en version ${VM_VERSIONMAJEUR} : #31081"
            else
                ciAptEole eole-esbl-ocs
            fi

            if ciVersionMajeurAPartirDe "2.9."
            then
                ciSignalWarning "EJabberd désactivé en version ${VM_VERSIONMAJEUR}"
            else
                if [ "$CONFIGURATION" != "lemonng" ]
                then
                    ciAptEole eole-ejabberd
                fi
            fi

            apt-get install --fix-missing

            ciAptEole eole-wpkg

            if [ "$CONFIGURATION" == "lemonng" ]
            then
                ciAptEole eole-lemonldap-ng-amonecole
            fi

            ciPrintConsole "Injection /etc/nut/dummy.dev"
            /bin/cp -f "$VM_DIR_EOLE_CI_TEST/dataset/nut/dummy.dev" /etc/nut/
            chmod 640 /etc/nut/dummy.dev
            chown nut:nut /etc/nut/dummy.dev
            if [ -d /etc/bareos/bareosfichiers.d ]
            then
                cat > /etc/bareos/bareosfichiers.d/nut.conf<<EOF
Include {
  Options {
    aclsupport = no
    @/etc/bareos/include-options.conf
  }
  File = /etc/nut/dummy.dev
}
EOF
            fi
            ;;

        rie.ecdl-ddt101)
            if ciVersionMajeurApres "2.5.1"
            then
                ciInjectCaLDAPMA
            fi
            if ciVersionMajeurEgal "2.5.2"
            then
                ciSignalHack "CreoleCat -t  named.conf.options.ecdl!!!! "
                CreoleCat -t named.conf.options.ecdl
            fi
            ciPingHost "banshee.eole.e2.rie.gouv.fr" "$VM_INTERFACE0_NAME"
            ciTestHttp "http://banshee.eole.e2.rie.gouv.fr/test_wget.txt"
            ;;

        etb4.amonecoleeclair)
            if ciVersionMajeurApres "2.6.1"
            then
                ciPrintConsole "Injection /etc/nut/dummy.dev"
                /bin/cp -f "$VM_DIR_EOLE_CI_TEST/dataset/nut/dummy.dev" /etc/nut/
                chmod 640 /etc/nut/dummy.dev
                chown nut:nut /etc/nut/dummy.dev
                if [ -d /etc/bareos/bareosfichiers.d ]
                then
                cat > /etc/bareos/bareosfichiers.d/nut.conf<<EOF
Include {
  Options {
    aclsupport = no
    @/etc/bareos/include-options.conf
  }
  File = /etc/nut/dummy.dev
}
EOF
                fi
            fi
            ;;

        siegeNT2.eSSL)
            if ciVersionMajeurApres "2.5.0"
            then
                ciAptEole eole-dhcp supervision-psin
            fi
            ;;

        siegeNT1.eSSL)
            if ciVersionMajeurApres "2.5.0"
            then
                ciAptEole eole-dhcp eole-ocsinventory-agent supervision-psin
            fi
            ;;

       rie.esbl-ddt101-geomatique)
            if ciVersionMajeurApres "2.6.0"
            then
                ciAptEole eole-db eole-postgis eole-postgresql postgresql-contrib
            fi
            ;;

       rie.esbl-ddt101-applisweb)
            if ciVersionMajeurApres "2.6.2"
            then
                ciAptEole eole-client-annuaire eole-web eole-web-pkg eole-mysql eole-mysql-pkg eole-db eole-phpmyadmin eole-phpmyadmin-pkg esbl-ocs eole-esbl-ocs esbl-ocs-pkg esbl-glpi esbl-grr eole-esbl-grr eole-wapt
                if ciVersionMajeurApres "2.7.0"
                then
                    ciAptEole eole-glpi
                else
                    ciAptEole eole-esbl-glpi
                fi

            fi
            ;;

        *)
            ciPrintMsgMachine "Pas de paquets complémentaires pour cette machine "
            ;;
    esac
}
export -f ciAvantInstance

#########################################################################################################
#
# monitor la commande 'instance'
#
#########################################################################################################
function ciMonitorInstance()
{
    if ciVersionMajeurApres "3."
    then
        echo "VM_MODULE=$VM_MODULE"
        if [ "$VM_MODULE" == "base" ]
        then
            bash "$VM_DIR_EOLE_CI_TEST/tests/eole3/install-eolebase3.sh" "$CONFIGURATION"
            return "$?"
        fi
        # amon3
        # hapy3
    fi
    ciMonitor instance
}
export -f ciMonitorInstance

#########################################################################################################
#
# monitor la commande 'instance'
#
#########################################################################################################
function ciInstance()
{
    ciPrintMsgMachine "ciInstance"

    ciEstCeQueLImageEstInstanciee

    ciCheckCreoled

    if [[ "$VM_DEBUG" -gt "1" ]]
    then
        echo "tail -f /var/log/syslog dans un processus independant"
        tail -f /var/log/syslog &
        PID_TAIL=$!
    fi

    ciAvantInstance

    if [ -f "$PWD/index.html.tmp" ]
    then
        ciSignalWarning "Nettoyage 'index.html.tmp'"
        /bin/rm -f "$PWD/index.html.tmp" 2>/dev/null
    fi
    if [ -f "$PWD/blacklists.tmp" ]
    then
        ciSignalWarning "Nettoyage 'blacklists.tmp'"
        /bin/rm -f "$PWD/blacklists.tmp" 2>/dev/null
    fi
    if [ -f "$PWD/results.bin" ]
    then
        ciSignalWarning "Nettoyage 'results.bin'"
        /bin/rm -f "$PWD/results.bin" 2>/dev/null
    fi

    #if [[ "x${VM_VERSIONMAJEUR}" < "x3" ]]
    #then
    #    echo "Liste des 'winbind enum ' dans les templates "
    #    if rgrep "winbind enum" /usr/share/eole/creole/distrib/*
    #    then
    #        ciSignalHack "désactivation des options 'winbind enum *' sur Samba (voir #33316)"
    #        sed -i "s/winbind enum/#winbind enum/g" /usr/share/eole/creole/distrib/*
    #    fi
    #fi

    ciMonitorInstance
    RETOUR=$?

    if [ -f "$PWD/index.html.tmp" ]
    then
        ciSignalWarning "Détection 'index.html.tmp'"
        ls -l "$PWD/index.html.tmp"
    fi
    if [ -f "$PWD/blacklists.tmp" ]
    then
        ciSignalWarning "Détection 'blacklists.tmp'"
        ls -l "$PWD/blacklists.tmp"
    fi
    if [ -f "$PWD/results.bin" ]
    then
        ciSignalWarning "Détection 'results.bin'"
        ls -l "$PWD/results.bin"
    fi

    if [[ "$VM_DEBUG" -gt "1" ]]
    then
        [ -n "$PID_TAIL" ] && kill -9 "$PID_TAIL"
    fi
    [[ "$RETOUR" -eq 0 ]] || return "$RETOUR"

    if [ -f /etc/profile.d/eolerc.sh ]
    then
        if ciVersionMajeurAvant "2.6.1"
        then
            ciSignalWarning "eolerc.sh désactivé pour les versions < 2.6.1 !"
            # cela provoque! : /etc/profile.d/eolerc.sh: ligne 6: HISTCONTROL : variable en lecture seule
        else
            ciPrintMsgMachine "Inject /etc/profile.d/eolerc.sh"
            set +e
            # shellcheck disable=SC1091,SC1090
            if ! source /etc/profile.d/eolerc.sh
            then
                ciSignalWarning "eolerc.sh => $? en erreur !"
            fi
        fi
    else
        ciPrintMsg "PAS DE FICHIER eolerc.sh !!!! "
    fi

    ciApresInstance

    ciCheckAccesInternet

    ciPrintMsgMachine "Affiche configuration"
    case "${VM_VERSIONMAJEUR}" in
        2.3)
            /usr/share/creole/parsedico.py >"$DIR_CONFIGURATION/parsedico.list"
            ;;

        2.4)
            ciPrintMsgMachine " pas de configuration en 2.4"
            ;;

        2.5.2)
            ciSignalHack "force PYTHONIOENCODING=UTF8 en 2.5.2"
            PYTHONIOENCODING=UTF8 CreoleGet --list >"$DIR_CONFIGURATION/creoleget.list"
            ;;

        2.*)
            CreoleGet --list >"$DIR_CONFIGURATION/creoleget.list"
            ;;

        3.*)
            ciPrintMsgMachine " pas de configuration en 3.0"

    esac

    if command -v updatedb
    then
        # désactive le locate sur /mnt/eole-ci-test !
        sed -i 's#PRUNEFS="NFS#PRUNEFS="9p NFS#' /etc/updatedb.conf

        ciPrintMsgMachine "updatedb"
        updatedb
    fi

    ciPrintMsgMachine "Tag l'Image Instanciée"
    ciMd5ConfigEol /etc/eole/config.eol
    maintenant=$(date '+%s')
    jour="$(date +'%Y-%m-%d %R')"
    { echo INSTANCE_MACHINE="$VM_MACHINE";
      echo INSTANCE_CONFIGURATION="$CONFIGURATION";
      echo INSTANCE_MD5="$MD5";
      echo INSTANCE_VERSIONMAJEUR="${VM_VERSIONMAJEUR}";
      echo INSTANCE_DATEUPDATE="$maintenant";
      echo INSTANCE_DATE=\'"$jour"\';
    } >/root/.eole-ci-tests.instance
    cat /root/.eole-ci-tests.instance
    # shellcheck disable=SC1091
    source /root/.eole-ci-tests.instance

    ciPrintConsole "ciInstance '$CONFIGURATION' '${VM_VERSIONMAJEUR}' '$VM_MAJAUTO' : OK"
    return 0
}
export -f ciInstance

#########################################################################################################
#
# monitor la commande 'instance'
#
#########################################################################################################
function ciApresInstance()
{
    ciPrintMsgMachine "ciApresInstance : Installation paquets complémentaires APRES instance"
    case "$VM_MACHINE" in
        aca.dc1)
            if ciVersionMajeurAPartirDe "2.7."
            then
                if [ "$CONFIGURATION" == "default" ]
                then
                    if [ ! -d /home/sysvol/domseth.ac-test.fr/scripts/users/ ]
                    then
                        find /home/sysvol/
                        ciSignalAttention " Le chemin /home/sysvol/domseth.ac-test.fr/scripts/users/ n'existe pas !!"
                        mkdir -p /home/sysvol/domseth.ac-test.fr/scripts/users/
                    fi
                    cat >"/home/sysvol/domseth.ac-test.fr/scripts/users/admin.txt" <<EOF
cmd,c:\util\bginfo.exe /NOLICPROMPT /POPUP,NOWAIT
EOF
                fi
            fi
            ;;

        aca.zephir)
            ciSauvegardeCaMachine
            ;;

        aca.scribe)
            ciSauvegardeCaMachine
            ciInjectLinks
            ;;

        etb1.amon)
            ciSauvegardeClamBD
            ;;

        etb1.scribe)
            ciSauvegardeCaMachine
            #ciDownloadWpkgClient
            ciInjectLinks

            if ciVersionMajeurAPartirDe "2.7."
            then
                if [ "$CONFIGURATION" == "default" ]
                then
                    ciSignalAttention "INJECT Bginfo.exe dans script 'scripts/users/admin.txt'"
                    ciSignalAttention "INJECT map N: \\dompedago.etb1.lan\NETLOGON"
                    cat >"/var/lib/lxc/addc/rootfs/home/sysvol/dompedago.etb1.lan/scripts/users/admin.txt" <<EOF
cmd,c:\util\bginfo.exe /NOLICPROMPT /POPUP,NOWAIT
lecteur,N:,\\\\dompedago.etb1.lan\NETLOGON
EOF
                fi
            fi
            ;;

        etb3.amonecole)
            ciSauvegardeCaMachine
            ciInjectLinks

            if ciVersionMajeurAPartirDe "2.7."
            then
                if [ "$CONFIGURATION" == "default" ]
                then
                    ciSignalAttention "INJECT Bginfo.exe dans script 'scripts/users/admin.txt'"
                    ciSignalAttention "INJECT map N: \\etb3.lan\NETLOGON"
                    cat >"/opt/lxc/addc/rootfs/home/sysvol/etb3.lan/scripts/users/admin.txt" <<EOF
cmd,c:\util\bginfo.exe /NOLICPROMPT /POPUP,NOWAIT
lecteur,N:,\\\\etb3.lan\NETLOGON
EOF
                fi
            fi
            ;;

        aca.proxy)
            ciSendEvent gateway APRES_INSTANCE
            ;;

        siegeNT2.eSSL)
            if ciVersionMajeurApres "2.5.0"
            then
                ciPrintMsgMachine "Suppression depot intra PNE"
                /bin/rm -f /etc/apt/sources.list.d/DepotIntraPNESR.list
            fi
            ;;

        siegeNT1.eSSL)
            if ciVersionMajeurApres "2.5.0"
            then
                ciPrintMsgMachine "Suppression depot intra PNE"
                /bin/rm -f /etc/apt/sources.list.d/DepotIntraPNESR.list
            fi
            ;;

        *)
            ;;

    esac
}
export -f ciApresInstance

#########################################################################################################
#
# monitor la commande 'diagnose'
#
#########################################################################################################
function ciDiagnose()
{
    ciCheckCreoled

    ciMonitor diagnose
    RETOUR=$?
    ciPrintMsg "diagnose => $RETOUR"
    return "$RETOUR"
}
export -f ciDiagnose

#########################################################################################################
#
# calcul l'emplacement du fichier config.eol pour la machine et la configuration donnée sur le VirtFs
#
#########################################################################################################
function ciGetConfigEolPath()
{
    ciGetDirConfiguration
    if ciVersionMajeurEgal "2.3"
    then
        if [ -f "$DIR_CONFIGURATION/etc/eole/config.ini" ]
        then
            CONFIG_EOL_PATH="$DIR_CONFIGURATION/etc/eole/config.ini"
        else
            CONFIG_EOL_PATH="$DIR_CONFIGURATION/etc/eole/config.eol"
        fi
    else
        CONFIG_EOL_PATH="$DIR_CONFIGURATION/etc/eole/config.eol"
    fi
    export CONFIG_EOL_PATH
}
export -f ciGetConfigEolPath

#########################################################################################################
#
# affiche le fichier config.eol en format lisible / comparable
#
#########################################################################################################
function ciDisplayConfigEol()
{
    python3 "$VM_DIR_EOLE_CI_TEST/scripts/formatConfigEol1.py" </etc/eole/config.eol
}
export -f ciDisplayConfigEol

#########################################################################################################
#
# copie le fichier config.eol pour la machine et la configuration donnée
#
#########################################################################################################
function ciCopieConfigEol()
{
    if ciVersionMajeurApres "3."
    then
        ciPrintMsgMachine "Pas de Config Eol pour EOLE3"
        return 0
    fi

    CONFIGURATION_A_MIGRER=non
    ciGetConfigEolPath
    ciPrintMsgMachine "Install Config Eol depuis $CONFIG_EOL_PATH"
    /bin/cp -f "$CONFIG_EOL_PATH" /etc/eole/config.eol
    RETOUR=$?
    if [ "$RETOUR" -ne 0 ]
    then
        ciPrintMsg "/bin/cp -f config.eol => $RETOUR"
        return "$RETOUR"
    fi

    if [ "$CONFIGURATION_A_MIGRER" == "oui" ]
    then
        ciPrintMsgMachine "************************************************************"
        ciPrintMsgMachine "* Migration configuration"
        ciPrintMsgMachine "************************************************************"
        ciRunPython mise_a_jour_config_apres_migration.py
        RETOUR=$?
        if [[ "$RETOUR" -eq 0 ]]
        then
            ciPrintMsgMachine "************************************************************"
            ciPrintMsgMachine "* Sauvegarde configuration !!! "
            ciPrintMsgMachine "************************************************************"
            ciDisplayConfigEol >"$CONFIG_EOL_PATH"
            RETOUR=$?
        fi
    fi

    if [ -f "$DIR_CONFIGURATION/fichiersVariante" ]
    then
        ciPrintMsgMachine "************************************************************"
        ciPrintMsgMachine "* Installation fichiers variante"
        ciPrintMsgMachine "************************************************************"

        while read -r f
        do
            if [ "$f" == "." ] || [ "$f" == "./etc/eole" ] || [ "$f" == "./etc/eole/config.eol" ] || [ "$f" == "./fichiersVariante" ]
            then
                continue
            fi
            fichier=${f:2}
            if [ -d "$DIR_CONFIGURATION/$fichier" ]
            then
                if [ ! -d "/$fichier" ]
                then
                    echo "creation du répertoire : $fichier"
                    mkdir "/$fichier"
                fi
            else
                echo "copy de : $fichier"
                /bin/cp -fv "$DIR_CONFIGURATION/$fichier" "/$fichier"
            fi
         done <"$DIR_CONFIGURATION/fichiersVariante"
    else
        ciPrintMsgMachine "* pas de fichiers variante"
    fi
    return "$RETOUR"
}
export -f ciCopieConfigEol

#########################################################################################################
#
# appel get_id_zephir.py
#
#########################################################################################################
function ciGetIdZephir()
{
    local PYTHON
    PYTHON="python"
    if ciVersionMajeurAPartirDe "2.8."
    then
        PYTHON="python3"
    fi
    "$PYTHON" "$VM_DIR_EOLE_CI_TEST/scripts/monitor3/get_id_zephir.py" 2>/dev/null
}
export -f ciGetIdZephir

#########################################################################################################
#
# monitor zephir_recupere_configuration
#
#########################################################################################################
function ciGetConfigurationFromZephir()
{
    ciPrintMsgMachine "ciGetConfigurationFromZephir configuration=$CONFIGURATION"
    if [ -z "$CONFIGURATION" ]
    then
        ciPrintMsgMachine "ciGetConfigurationFromZephir : CONFIGURATION vide stop"
        return 1
    fi
    ciInjectCaMachineSsh zephir.ac-test.fr >"$VM_DIR/ciInjectCaMachineSsh.log" 
    CDU=$?
    if [ $CDU -ne 0 ]
    then
        cat "$VM_DIR/ciInjectCaMachineSsh.log"
        ciPrintMsgMachine "ciGetConfigurationFromZephir : erreur injection CA"
        return 1
    fi

    [ -f /root/zephir.eol ] && /bin/rm -f /root/zephir.eol
    ciMonitor zephir_recupere_configuration
    RETOUR=$?

    if [ "$RETOUR" -ne "0" ]
    then
        if [ -f /usr/lib/python2.7/dist-packages/OpenSSL/test/test_ssl.py ]
        then
            ciPrintMsgMachine "ciGetConfigurationFromZephir : execute test standard 'python /usr/lib/python2.7/dist-packages/OpenSSL/test/test_ssl.py'"
            python /usr/lib/python2.7/dist-packages/OpenSSL/test/test_ssl.py
        fi
        return "$RETOUR"
    fi

    if [ -f /root/zephir.eol ]
    then
        if ! ciVersionMajeurApres "2.5.1"
        then
            ciPrintMsgMachine "BIZARRE : /root/zephir.eol existe !! "
        fi
        ciPrintMsgMachine "/bin/cp -f /root/zephir.eol /etc/eole/config.eol"
        /bin/cp --force /root/zephir.eol /etc/eole/config.eol
    fi

    ciPrintMsgMachine "Sauvegarde IdZephir dans $VM_DIR/idzephir"
    ID_ZEPHIR=$(ciGetIdZephir)
    ciPrintMsgMachine "ID_ZEPHIR=$ID_ZEPHIR CONFIGURATION=$CONFIGURATION"
    echo "$ID_ZEPHIR" >"$VM_DIR/idzephir"
    echo "$CONFIGURATION" >"$VM_DIR/configurationZephir"
    return "$RETOUR"
}
export -f ciGetConfigurationFromZephir

#########################################################################################################
#
# configure la machine par un scripe de restauration (zephir,...)
#
#########################################################################################################
function ciRestaureDepuisConfiguration()
{
    ciPrintDebug "RestaureDepuisConfiguration"
    ciGetDirSauvegarde

    ciPrintMsgMachine "restaure depuis '$DIR_SAUVEGARDE'"
    "$VM_DIR_EOLE_CI_TEST/scripts/restore-depuis-configuration.sh" "$DIR_SAUVEGARDE/"
    RETOUR=$?
    ciPrintMsg "restore-depuis-configuration.sh => $RETOUR"
    return "$RETOUR"
}
export -f ciRestaureDepuisConfiguration

#########################################################################################################
#
# récupere la sauvegarde du partage /mmt/eole-ci-tests vers /mnt/sauvegardes
#
#########################################################################################################
function ciGetBackup()
{
    ciPrintDebug "ciGetBackup"
    ciGetDirSauvegarde

    ciPrintMsgMachine "Copie sauvegardes..."
    [ ! -d /mnt/sauvegardes ] && ciCreateDir /mnt/sauvegardes

    if [ ! -d "$DIR_SAUVEGARDE/mnt/sauvegardes" ]
    then
        ciPrintMsg "ERREUR: Le repertoire '$DIR_SAUVEGARDE/mnt/sauvegardes' n'existe pas"
        return 1
    fi
    /bin/cp -rf "$DIR_SAUVEGARDE/mnt/sauvegardes" /mnt

    if ciVersionMajeurApres "2.5.0"
    then
        ciPrintMsgMachine "Change owner bareos"
        chown -R bareos /mnt/sauvegardes
    else
        ciPrintMsgMachine "Change owner bacula"
        chown -R bacula /mnt/sauvegardes
    fi
    ls -lR /mnt/sauvegardes
    return 0
}
export -f ciGetBackup

#########################################################################################################
#
# copie la sauvegarde de /mnt/sauvegardes dans le partage /mmt/eole-ci-tests
#
#########################################################################################################
function ciPutBackup()
{
    ciPrintDebug "ciPutBackup"
    ciGetDirSauvegarde

    ciPrintMsgMachine "Copie sauvegardes..."
    if [ ! -d /mnt/sauvegardes ]
    then
        ciPrintMsg "ERREUR: Le repertoire '/mnt/sauvegardes' n'existe pas"
        return 1
    fi

    if [ ! -d "$DIR_SAUVEGARDE/mnt" ]
    then
        ciCreateDir "$DIR_SAUVEGARDE/mnt"
    else
        /bin/rm -rf "$DIR_SAUVEGARDE/mnt/sauvegardes/"
    fi
    /bin/cp -rf /mnt/sauvegardes/ "$DIR_SAUVEGARDE/mnt/"
    if [ -d /var/log/rsyslog/local/bareos-dir ]
    then
        /bin/cp -rf /var/log/rsyslog/local/bareos-dir/ "$DIR_SAUVEGARDE/mnt/sauvegardes/"
    else
        ciSignalWarning "/var/log/rsyslog/local/bareos-dir/ n'existe pas"
    fi
    if [ -d /var/log/rsyslog/local/bareos-fd ]
    then
        /bin/cp -rf /var/log/rsyslog/local/bareos-fd/  "$DIR_SAUVEGARDE/mnt/sauvegardes/"
    else
        ciSignalWarning "/var/log/rsyslog/local/bareos-fd/ n'existe pas"
    fi
    if [ -d /var/log/rsyslog/local/bareos-sd ]
    then
        /bin/cp -rf /var/log/rsyslog/local/bareos-sd/ "$DIR_SAUVEGARDE/mnt/sauvegardes/"
    else
        ciSignalWarning "/var/log/rsyslog/local/bareos-sd/ n'existe pas"
    fi
    /bin/cp -rf /var/lib/eole/reports/resultat-bareos "$DIR_SAUVEGARDE/mnt/sauvegardes/"
    ls -lR "$DIR_SAUVEGARDE/mnt/sauvegardes/"
    return 0
}
export -f ciPutBackup

#########################################################################################################
#
# Attend la fin d'une opération de sauvergarde + affiche les messages eu fur et a mesure
#
#########################################################################################################
function ciWaitBareos()
{
    local OK
    local LIMITE_GLOBAL="${1:-600}"
    local DUREE_PAUSE="20"
    ciPrintDebug "ciWaitBareos $LIMITE_GLOBAL"

    echo "Pause de 10 secondes, attente démarrage sauvegarde = changement"
    sleep 10

    SECONDS=0   # Reset $SECONDS; counting of seconds will (re)start from 0(-ish).
    OK=1
    while (( SECONDS < LIMITE_GLOBAL )); do
        echo "********************* BCONSOLE: messages dir *********************************"
        if ciVersionMajeurEgal "2.6.0"
        then
            ciSignalHack "Suppression traceback 2.6.0"
            echo "messages" | bconsole -c /etc/bareos/bconsole.conf | sed s'/Traceback/Backtrace/'
        else
            echo "messages" | bconsole -c /etc/bareos/bconsole.conf
        fi
        echo "********************* BCONSOLE: status dir ***********************************"
        echo "status dir running days=0" | bconsole -c /etc/bareos/bconsole.conf | grep -q "No Jobs running"
        CDU=$?
        if [[ "$CDU" = "0" ]]
        then
            echo "Ok fini, Stop "
            OK=0
            break
        fi

        echo "********************* Pause $SECONDS/$LIMITE_GLOBAL, attente $DUREE_PAUSE secondes"
        sleep "$DUREE_PAUSE"
    done
    return "$OK"
}
export -f ciWaitBareos

#########################################################################################################
#
# configure la machine par une restauration baccula
#
#########################################################################################################
function ciBacculaRestaure()
{
    ciPrintDebug "ciBacculaRestaure"
    ciGetDirSauvegarde

    ciPrintMsgMachine "Copie sauvegardes..."
    [ ! -d /mnt/sauvegardes ] && ciCreateDir /mnt/sauvegardes
    /bin/cp -v "$DIR_SAUVEGARDE/mnt/sauvegardes/*" /mnt/sauvegardes

    ciPrintMsgMachine "Bacularestore"
    director=$(basename /mnt/sauvegardes/*-catalog-0003 -catalog-0003)
    ciPrintMsg "  director = $director"
    /usr/share/eole/bacula/bacularestore.py --catalog "$director"
}
export -f ciBacculaRestaure

function ciGetNamesInterfacesFreebsd()
{
    VM_NB_INTERFACE=$(ifconfig | grep -c -i Ethernet)
    export VM_NB_INTERFACE
    ciPrintMsg "Nb interfaces = $VM_NB_INTERFACE"

    VM_INTERFACE0_NAME=vtnet0
    export VM_INTERFACE0_NAME
    if [ "$VM_NB_INTERFACE" -eq 1 ]
    then
        return 0
    fi

    VM_INTERFACE1_NAME=vtnet1
    export VM_INTERFACE1_NAME
    if [ "$VM_NB_INTERFACE" -eq 2 ]
    then
        return 0
    fi

    VM_INTERFACE2_NAME=vtnet2
    export VM_INTERFACE2_NAME
    if [ "$VM_NB_INTERFACE" -eq 3 ]
    then
        return 0
    fi

    VM_INTERFACE3_NAME=vtnet3
    export VM_INTERFACE1_NAME
    if [ "$VM_NB_INTERFACE" -eq 4 ]
    then
        return 0
    fi

    VM_INTERFACE4_NAME=vtnet4
    export VM_INTERFACE4_NAME
    if [ "$VM_NB_INTERFACE" -eq 5 ]
    then
        return 0
    fi

    ciSignalWarning "Cas nombre interface = $VM_NB_INTERFACE non géré pour FreeBSD !"
    return 0
}
export -f ciGetNamesInterfacesFreebsd

function ciIsBootUEFI()
{
    if test -d /sys/firmware/efi
    then
        return 0
    else
        return 1
    fi
}
export -f ciIsBootUEFI

function ciGetNamesInterfacesUbuntu()
{
    VM_NB_INTERFACE=$(lspci | grep -c -i Ethernet)
    export VM_NB_INTERFACE
    #ciPrintMsg "Nb interfaces = $VM_NB_INTERFACE"

    if ip link show eth0 >/dev/null 2>&1 ;
    then
        VM_INTERFACE0_NAME=eth0
    else
        if ciIsBootUEFI
        then
            VM_INTERFACE0_NAME=enp2s0
        else
            VM_INTERFACE0_NAME=ens4
        fi
    fi
    export VM_INTERFACE0_NAME
    if [ "$VM_NB_INTERFACE" -eq 1 ]
    then
        return 0
    fi

    if ip link show eth1 >/dev/null 2>&1 ;
    then
        VM_INTERFACE1_NAME=eth1
    else
        if ciIsBootUEFI
        then
            VM_INTERFACE1_NAME=enp3s0
        else
            VM_INTERFACE1_NAME=ens5
        fi
    fi
    export VM_INTERFACE1_NAME
    if [ "$VM_NB_INTERFACE" -eq 2 ]
    then
        return 0
    fi

    if ip link show eth2 >/dev/null 2>&1 ;
    then
        VM_INTERFACE2_NAME=eth2
    else
        if ciIsBootUEFI
        then
            VM_INTERFACE2_NAME=enp4s0
        else
            VM_INTERFACE2_NAME=ens6
        fi
    fi
    export VM_INTERFACE2_NAME
    if [ "$VM_NB_INTERFACE" -eq 3 ]
    then
        return 0
    fi

    if ip link show eth3 >/dev/null 2>&1 ;
    then
        VM_INTERFACE3_NAME=eth3
    else
        if ciIsBootUEFI
        then
            VM_INTERFACE3_NAME=enp5s0
        else
            VM_INTERFACE3_NAME=ens7
        fi
    fi
    export VM_INTERFACE3_NAME
    if [ "$VM_NB_INTERFACE" -eq 4 ]
    then
        return 0
    fi

    if ip link show eth4 >/dev/null 2>&1 ;
    then
        VM_INTERFACE4_NAME=eth4
    else
        if ciIsBootUEFI
        then
            VM_INTERFACE4_NAME=enp6s0
        else
            VM_INTERFACE4_NAME=ens8
        fi
    fi
    export VM_INTERFACE4_NAME
    if [ "$VM_NB_INTERFACE" -eq 5 ]
    then
        return 0
    fi

    ciSignalWarning "Cas nombre interface = $VM_NB_INTERFACE non géré pour Ubuntu!"
    return 0
}
export -f ciGetNamesInterfacesUbuntu

function ciGetNamesInterfaces()
{
    if [ -n "$VM_NB_INTERFACE" ]
    then
        return 0
    fi

    if [ "$VM_IS_FREEBSD" == "1" ]
    then
        ciGetNamesInterfacesFreebsd
        return 0
    fi

    if [ "$VM_IS_UBUNTU" == "1" ]
    then
        ciGetNamesInterfacesUbuntu
        return 0
    fi

    ciSignalWarning "Cas VM_IS_FREEBSD=$VM_IS_FREEBSD, VM_IS_UBUNTU=$VM_IS_UBUNTU non géré !"
    return 0
}
export -f ciGetNamesInterfaces

#########################################################################################################
#
# get ip dev
#
#########################################################################################################
function ciGetIpV4Device()
{
    ip addr show dev "$1" |grep "inet " | tr '/' ' ' | awk '{print $2}'
}
export -f ciGetIpV4Device

#########################################################################################################
#
# impose une configration minimal avec réseau
#
#########################################################################################################
function ciDefautNetwork()
{
    ciPrintDebug "DefautNetwork"

    ciGetNamesInterfaces

    ciPrintMsg "Méthode inconnue ==> par defaut ip + maj_auto "
    if [ -n "$VM_ETH0_IP" ]
    then
        ciPrintMsg "Set $VM_INTERFACE0_NAME = $VM_ETH0_IP"
        ifconfig "$VM_INTERFACE0_NAME" "$VM_ETH0_IP" netmask 255.255.255.0
    fi
    if [ -n "$VM_ETH0_GW" ]
    then
        ciPrintMsg "Set default gateway = $VM_ETH0_GW via $VM_INTERFACE0_NAME"
        route add default gw "$VM_ETH0_GW" dev "$VM_INTERFACE0_NAME"
    fi
}
export -f ciDefautNetwork


#########################################################################################################
#
# ciCopySSHDKey($1)
#
#########################################################################################################
function ciCopySSHDKey()
{
    if [ ! -f "$DIR_CONFIGURATION_MACHINE/minimale/etc/ssh/$1" ]
    then
        [ ! -d "$DIR_CONFIGURATION_MACHINE/minimale/etc/ssh" ] && ciCreateDir "$DIR_CONFIGURATION_MACHINE/minimale/etc/ssh/"
        if [ -f "/etc/ssh/$1" ]
        then
            ciPrintDebug "Sauvegarde SSHD keys : $1"
            /bin/cp -v "/etc/ssh/$1" "$DIR_CONFIGURATION_MACHINE/minimale/etc/ssh/$1"
            chmod "$2" "$DIR_CONFIGURATION_MACHINE/minimale/etc/ssh/$1"
        else
            ciPrintDebug "Sauvegarde SSHD keys : $1 (pas de cléf de ce type)"
        fi
    else
        ciPrintDebug "Inject SSHD keys : $1"
        /bin/cp -u "$DIR_CONFIGURATION_MACHINE/minimale/etc/ssh/$1" /etc/ssh/
        chmod "$2" "/etc/ssh/$1"
    fi
}
export -f ciCopySSHDKey

#########################################################################################################
#
# récupere l'IP courrante
#
#########################################################################################################
function ciGetCurrentIp()
{
    local CHAINE_IP_ADDR
    declare -a TABLEAU_IP_ADDR

    if [ "$VM_IS_FREEBSD" == "1" ]
    then
        CHAINE_IP_ADDR=$(ifconfig "${VM_INTERFACE0_NAME}" | grep 'inet ')
        # je convertis en tableau
        read -r -a TABLEAU_IP_ADDR <<< "${CHAINE_IP_ADDR}"
        # l'ip est en 1
        echo "${TABLEAU_IP_ADDR[1]}"
    else
        # j'affiche uniquement la ligne IP V4 de 'ip addr'
        CHAINE_IP_ADDR=$(ip -4 -o addr show "${VM_INTERFACE0_NAME}")
        # je convertis en tableau en remplacant le /24 par ' '24
        read -r -a TABLEAU_IP_ADDR <<< "${CHAINE_IP_ADDR//\// }"
        # l'ip est en 3
        echo "${TABLEAU_IP_ADDR[3]}"
    fi
}
export -f ciGetCurrentIp

#########################################################################################################
#
# récupere l'IP gateway en cours
#
#########################################################################################################
function ciGetGatewayIP()
{
    if [ "$VM_IS_UBUNTU" == "1" ]
    then
        /bin/ip route | grep "dev $VM_INTERFACE0_NAME" | awk '/default via/ { print $3;}' | sort | uniq
    fi
    if [ "$VM_IS_FREEBSD" == "1" ]
    then
        netstat -nr | grep "$VM_INTERFACE0_NAME" | awk '/default/ { print $2;}' | sort | uniq
    fi
}
export -f ciGetGatewayIP

#########################################################################################################
#
# set l'IP gateway et la route
#
#########################################################################################################
function ciSetGatewayIP()
{
    local GW
    if [ -z "${1}" ]
    then
        GW="${VM_ETH0_GW}"
    else
        GW="${1}"
    fi

    ciPrintMsg "GW différente : force ${GW}"
    ciSignalWarning "le pb peut venir d'un DHCP qui aurait donné une ip incorrecte"
    ciSignalWarning "Vérifier qu'il n'y a pas de VM avec server DHCP sur le réseau aca / jenkins"
    if [ "$VM_IS_UBUNTU" == "1" ]
    then
        /bin/ip route del 0/0
        /bin/ip route add default via "${GW}" dev "$VM_INTERFACE0_NAME" onlink

        ciPrintMsg "** Affiche route (apres)"
        /bin/ip route
    fi
    if [ "$VM_IS_FREEBSD" == "1" ]
    then
        route add default "${GW}"

        ciPrintMsg "** Affiche route (apres)"
        netstat -nr
    fi
}
export -f ciSetGatewayIP

#########################################################################################################
#
# affiche l'IP gateway et la route
#
#########################################################################################################
function ciDisplayGatewayIp()
{
    if [ "$VM_IS_UBUNTU" == "1" ]
    then
        ciPrintMsg "** ip addr"
        /bin/ip addr

        ciPrintMsg "** ip route"
        /bin/ip route

    fi
    if [ "$VM_IS_FREEBSD" == "1" ]
    then
        ciPrintMsg "** ifconfig"
        ifconfig

        ciPrintMsg "** netstat -nr"
        netstat -nr
    fi
}
export -f ciDisplayGatewayIp

#########################################################################################################
#
# vrai si utilise systemd/netplan
#
#########################################################################################################
function ciUtiliseSystemdNetplan()
{
    if [ ! "v$(lsb_release -rs)" \> "v18." ]
    then
        return 1
    fi
    
    CODENAME="$(lsb_release -cs)"
    case "$CODENAME" in
        bionic)
            return 0
            ;;

        focal)
            return 0
            ;;
    
        impish)
            return 0
            ;;
    
        jammy)
            return 0
            ;;
    
        noble)
            return 0
            ;;
            
        virginia)
            return 0
            ;;
            
        vera)
            return 0
            ;;
            
        ulyana)
            return 0
            ;;
            
        *)
            return 1
            ;;
            
    esac
}
export -f ciUtiliseSystemdNetplan

#########################################################################################################
#
# vrai l'image disk est unu Desktop
#
#########################################################################################################
function ciEstUnDesktop()
{
    if systemctl is-active --quiet NetworkManager.service ;
    then
        return 0
    else
        return 1
    fi
}
export -f ciEstUnDesktop

#########################################################################################################
#
# impose la configration minimale de la machine (ip, route, gw, ssh, autorized keys)
#
#########################################################################################################
function ciContextualisationMinimaleSystemdDesktop()
{
    ciPrintMsgMachine "ciContextualisationMinimaleSystemdDesktop"
    if [ "v$(lsb_release -rs)" \< "v22.04" ]
    then
        ciPrintMsgMachine "Cas desktop \< 22.04 "
        ciPrintMsgMachine "desktop ==> uniquement DHCP"
        if [ -f "$DIR_CONFIGURATION_MACHINE/minimale/etc/netplan/01-network-manager-all.yaml" ]
        then
            ciPrintMsgMachine "nettoyage si besoin /etc/network/interfaces /etc/netplan/01-netcfg.yaml"
            /bin/rm -f /etc/network/interfaces /etc/netplan/01-netcfg.yaml

            ciPrintMsgMachine "Inject /etc/netplan/01-network-manager-all.yaml"
            cat "$DIR_CONFIGURATION_MACHINE/minimale/etc/netplan/01-network-manager-all.yaml" >/etc/netplan/01-network-manager-all.yaml
            chmod 600 /etc/netplan/01-network-manager-all.yaml

            ciPrintMsgMachine "netplan generate --debug"
            netplan --debug generate
        else
            ciPrintMsgMachine "pas de fichier $DIR_CONFIGURATION_MACHINE/minimale/etc/netplan/01-network-manager-all , hum... douteux !"
        fi
    else
        ciPrintMsgMachine "Cas desktop >= 22.04 "
        ciPrintMsgMachine "desktop ==> uniquement DHCP"

        ciPrintMsgMachine "nettoyage si besoin /etc/network/interfaces /etc/netplan/01-netcfg.yaml /etc/netplan/01-network-manager-all.yaml"
        /bin/rm -f /etc/network/interfaces /etc/netplan/01-netcfg.yaml /etc/netplan/01-network-manager-all.yaml

        ciPrintMsgMachine "surcharge /etc/netplan/01-network-manager-all.yaml"
        cat >/etc/netplan/01-network-manager-all.yaml <<EOF
network:
version: 2
renderer: NetworkManager
ethernets:
${VM_INTERFACE0_NAME}:
  dhcp4: yes
  dhcp-identifier: mac
EOF
        chmod 600 /etc/netplan/01-network-manager-all.yaml

        ciPrintMsgMachine "netplan generate --debug"
        netplan --debug generate

        #
        if [ -f /etc/gdm3/custom.conf ]
        then
            cat /etc/gdm3/custom.conf
            ciPrintMsgMachine "set WaylandEnable=false dans /etc/gdm3/custom.conf"
            sed -i -e 's/.*WaylandEnable=.*/WaylandEnable=false/' /etc/gdm3/custom.conf
        else
            ciPrintMsgMachine "inject WaylandEnable=false avec /etc/gdm3/custom.conf"
            cat >/etc/gdm3/custom.conf <<EOF
[daemon]
WaylandEnable=false
EOF
        fi

    fi
}

function ciContextualisationMinimaleSystemdServer()
{
    ciPrintMsgMachine "ciContextualisationMinimaleSystemdServer"

    ciPrintMsgMachine "Inject /etc/resolv.conf"
    if [ -f "$DIR_CONFIGURATION_MACHINE/minimale/etc/resolv.conf" ]
    then
        ciPrintMsgMachine "/bin/rm -f /etc/resolv.conf (pour casser le lien!)"
        /bin/rm -f /etc/resolv.conf

       /bin/cp "$DIR_CONFIGURATION_MACHINE/minimale/etc/resolv.conf" /etc/resolv.conf
       chmod 644 /etc/resolv.conf
        [[ "$VM_DEBUG" -gt "1" ]] && cat /etc/resolv.conf
    fi
    if [ -f "$DIR_CONFIGURATION_MACHINE/minimale/etc/netplan/01-netcfg.yaml" ]
    then
        ciPrintMsgMachine "ls -l /etc/netplan"
        ls -l /etc/netplan

        ciPrintMsgMachine "netoyage si besoin /etc/network/interfaces /etc/netplan/01-network-manager-all.yaml /etc/netplan/00-installer-config.yaml /etc/netplan/50-cloud-init.yaml"
        /bin/rm -f /etc/network/interfaces /etc/netplan/01-network-manager-all.yaml /etc/netplan/00-installer-config.yaml /etc/netplan/50-cloud-init.yaml

        if [ "v$(lsb_release -rs)" \< "v22.04" ]
        then
            ciPrintMsgMachine "Inject /etc/netplan/01-netcfg.yaml avant 22.04"
            cat "$DIR_CONFIGURATION_MACHINE/minimale/etc/netplan/01-netcfg.yaml" >/etc/netplan/01-netcfg.yaml
            chmod 600 /etc/netplan/01-netcfg.yaml
            
        else
            if ciIsBootUEFI
            then
                ciPrintMsgMachine "Inject /etc/netplan/01-netcfg-2204.yaml dans /etc/netplan/01-netcfg.yaml"
                cat "$DIR_CONFIGURATION_MACHINE/minimale/etc/netplan/01-netcfg-2204.yaml" >/etc/netplan/01-netcfg.yaml
                chmod 600 /etc/netplan/01-netcfg.yaml
                
                if [ "v$(lsb_release -rs)" == "v24.04" ]
                then
                    if [ -d /etc/needrestart/conf.d ]
                    then
        cat > /etc/needrestart/conf.d/EoleCiTests.conf <<EOF
\$nrconf{blacklist_rc} = [
    q(^EoleCiTestsDaemon) ,
];
EOF
                    fi
                fi
                
            else
                ciPrintMsgMachine "Inject /etc/netplan/01-netcfg-2204.yaml dans /etc/netplan/01-netcfg.yaml avec conversion nom carte"
                cat "$DIR_CONFIGURATION_MACHINE/minimale/etc/netplan/01-netcfg-2204.yaml" >/etc/netplan/01-netcfg.yaml
                chmod 600 /etc/netplan/01-netcfg.yaml
                if [ "$VM_INTERFACE0_NAME" != "enp2s0" ]
                then
                    sed -i -e "s/enp2s0/$VM_INTERFACE0_NAME/" /etc/netplan/01-netcfg.yaml
                    if [ "$VM_INTERFACE1_NAME" != "enp3s0" ]
                    then
                        sed -i -e "s/enp3s0/$VM_INTERFACE1_NAME/" /etc/netplan/01-netcfg.yaml
                        if [ "$VM_INTERFACE2_NAME" != "enp4s0" ]
                        then
                            sed -i -e "s/enp4s0/$VM_INTERFACE2_NAME/" /etc/netplan/01-netcfg.yaml
                            if [ "$VM_INTERFACE3_NAME" != "enp5s0" ]
                            then
                                sed -i -e "s/enp5s0/$VM_INTERFACE3_NAME/" /etc/netplan/01-netcfg.yaml
                                if [ "$VM_INTERFACE4_NAME" != "enp6s0" ]
                                then
                                    sed -i -e "s/enp6s0/$VM_INTERFACE4_NAME/" /etc/netplan/01-netcfg.yaml
                                fi
                            fi
                        fi
                    fi
                fi
            fi
        fi

        ciPrintMsgMachine "netplan generate --debug"
        netplan --debug generate
    else
        ciPrintMsgMachine "pas de fichier $DIR_CONFIGURATION_MACHINE/minimale/etc/netplan/01-netcfg.yaml , hum... douteux !"
    fi
}

function ciContextualisationMinimaleSystemd()
{
    ciPrintMsgMachine "ciContextualisationMinimaleSystemd"

    ciPrintMsgMachine "Inject /etc/hostname"
    hostnamectl set-hostname "$nomhost"
    [[ "$VM_DEBUG" -gt "1" ]] && hostnamectl --static status

    ciPrintMsgMachine "ls -l /etc/netplan/"
    ls -l /etc/netplan/

    if ciEstUnDesktop
    then
        ciContextualisationMinimaleSystemdDesktop
    else
        ciContextualisationMinimaleSystemdServer
    fi
}

function ciContextualisationMinimaleNetworkInterfaces()
{
    ciPrintMsgMachine "ciContextualisationMinimaleNetworkInterfaces"

    if [ ! -f "$DIR_CONFIGURATION_MACHINE/minimale/etc/network/interfaces.fi" ]
    then
        ciPrintMsg "Sauvegarde /etc/network/interfaces dans $DIR_CONFIGURATION_MACHINE/minimale/etc/network/interfaces.fi"
        /bin/cp /etc/network/interfaces "$DIR_CONFIGURATION_MACHINE/minimale/etc/network/interfaces.fi"
    fi

    ciPrintMsgMachine "Inject /etc/hostname"
    /bin/cp "$DIR_CONFIGURATION_MACHINE/minimale/etc/hostname" /etc/hostname
    [[ "$VM_DEBUG" -gt "1" ]] && cat /etc/hostname

    ciPrintMsgMachine "Inject /etc/resolv.conf"
    if [ -f "$DIR_CONFIGURATION_MACHINE/minimale/etc/resolv.conf" ]
    then
       /bin/cp "$DIR_CONFIGURATION_MACHINE/minimale/etc/resolv.conf" /etc/resolv.conf
       chmod 644 /etc/resolv.conf
        [[ "$VM_DEBUG" -gt "1" ]] && cat /etc/resolv.conf
    fi

    ciPrintMsgMachine "Inject /etc/network/interfaces"
    if [ -f "$DIR_CONFIGURATION_MACHINE/minimale/etc/network/interfaces" ]
    then
        cat "$DIR_CONFIGURATION_MACHINE/minimale/etc/network/interfaces" >/etc/network/interfaces
        if [ "$VM_INTERFACE0_NAME" != "eth0" ]
        then
            sed -i -e "s/eth0/$VM_INTERFACE0_NAME/" /etc/network/interfaces
            if [ "$VM_INTERFACE1_NAME" != "eth1" ]
            then
                sed -i -e "s/eth1/$VM_INTERFACE1_NAME/" /etc/network/interfaces
                if [ "$VM_INTERFACE2_NAME" != "eth2" ]
                then
                    sed -i -e "s/eth2/$VM_INTERFACE2_NAME/" /etc/network/interfaces
                    if [ "$VM_INTERFACE3_NAME" != "eth3" ]
                    then
                        sed -i -e "s/eth3/$VM_INTERFACE3_NAME/" /etc/network/interfaces
                        if [ "$VM_INTERFACE4_NAME" != "eth4" ]
                        then
                            sed -i -e "s/eth4/$VM_INTERFACE4_NAME/" /etc/network/interfaces
                        fi
                    fi
                fi
            fi
        fi
    fi
    [[ "$VM_DEBUG" -gt "1" ]] && cat /etc/network/interfaces
}

function ciContextualisationMinimale()
{
    #local ARRET_IF
    local nomhost
    ciPrintMsgMachine "ciContextualisationMinimale:"

    # pour ne pas etre reexcute en cas de réexecution
    # si reboot ==> ignore
    # si delete recreate ==> ignore
    if [ -f /root/.eole-ci-tests.minimale ]
    then
        # shellcheck disable=SC1091
        source /root/.eole-ci-tests.minimale 2>/dev/null
        export VM_ID_MINIMALE
        export VM_ID_MINIMALE_DATE
        if [ "$VM_ID" == "$VM_ID_MINIMALE" ]
        then
            ciPrintMsgMachine "Contextualisation minimale déjà réalisée à $VM_ID_MINIMALE_DATE"
            return 0
        else
            ciPrintMsgMachine "Contextualisation minimale réalisée pour $VM_ID_MINIMALE, à refaire"
        fi
    fi

    ciGetDirConfigurationMachine

    ciGetNamesInterfaces

    if ciVersionMajeurApres "2.6.2"
    then
        ciPrintMsgMachine "rm /etc/netplan/* désactivé !"
        #ciPrintMsgMachine "rm /etc/netplan/*"
        #/bin/rm -f /etc/netplan/*
    fi

    nomhost=$(cat "$DIR_CONFIGURATION_MACHINE/minimale/etc/hostname")

    ciPrintMsgMachine "Inject /etc/hosts"
    if [ -f "$DIR_CONFIGURATION_MACHINE/minimale/etc/hosts" ]
    then
        /bin/cp "$DIR_CONFIGURATION_MACHINE/minimale/etc/hosts" /etc/hosts
        [[ "$VM_DEBUG" -gt "1" ]] && cat /etc/hosts
    fi

    if ciVersionMajeurApres "2.9.0"
    then
        ciPrintMsgMachine "lsb_release -a -cs -rs"
        lsb_release -a
        lsb_release -cs
        lsb_release -rs
    fi
    if ciUtiliseSystemdNetplan
    then
        ciContextualisationMinimaleSystemd
    else
        ciContextualisationMinimaleNetworkInterfaces
    fi

    if ciVersionMajeurAvant "2.7.0"
    then
        ciCopySSHDKey ssh_host_dsa_key 600
        ciCopySSHDKey ssh_host_dsa_key.pub 644
    fi
    ciCopySSHDKey ssh_host_rsa_key 600
    ciCopySSHDKey ssh_host_rsa_key.pub 644
    ciCopySSHDKey ssh_host_ecdsa_key 600
    ciCopySSHDKey ssh_host_ecdsa_key.pub 644
    ciCopySSHDKey ssh_host_ed25519_key 600
    ciCopySSHDKey ssh_host_ed25519_key.pub 644

    ciPrintMsgMachine "Inject authorized_keys"
    [ ! -d /root/.ssh ] && mkdir /root/.ssh
    if [ ! -s /root/.ssh/authorized_keys ]
    then
        touch /root/.ssh/authorized_keys
        chmod 600 /root/.ssh/authorized_keys
    fi

    ciPrintMsgMachine "Actualisation /root/.ssh/authorized_keys"
    for f in "$VM_DIR_EOLE_CI_TEST/security/authorized_keys"/*
    do
        KEY=$(cat "$f")
        if ! grep -q "$KEY" /root/.ssh/authorized_keys
        then
            ciPrintDebug "Ajout '$f'"
            echo "$KEY" >>/root/.ssh/authorized_keys
        else
            ciPrintDebug "Déjà présent '$f'"
        fi
    done

    ciPrintMsgMachine "Inject bash_history"
    cat >>/root/.bash_history <<EOF
mkdir $VM_DIR_EOLE_CI_TEST
mount -t 9p -o trans=virtio eole-ci $VM_DIR_EOLE_CI_TEST -oversion=9p2000.L
. /root/getVMContext.sh
$VM_DIR_EOLE_CI_TEST/scripts/configure-vm.sh -M minimale
$VM_DIR_EOLE_CI_TEST/scripts/configure-vm.sh -M configeol
$VM_DIR_EOLE_CI_TEST/scripts/configure-vm.sh -M instance -C default
tail -fn23 $VM_DIR_EOLE_CI_TEST/output/\$VM_OWNER/\$VM_ID/instanceAutomatique.log
cd $VM_DIR_EOLE_CI_TEST/scripts
/root/mount.eole-ci-tests
EOF

#    if [ "$VM_OWNER" == ggrandgerard ]
#    then
#        ciPrintMsgMachine "Inject /etc/profile.d/${VM_OWNER}.sh"
#        mkdir -p /etc/profile.d/
#        cat >>"/etc/profile.d/${VM_OWNER}.sh" <<EOF
#/root/mount.eole-ci-tests
#. /root/getVMContext.sh
#EOF
#    else
#        if [ -f "/etc/profile.d/${VM_OWNER}.sh" ]
#        then
#            /bin/rm "/etc/profile.d/${VM_OWNER}.sh" 2>/dev/null
#        fi
#    fi

    if ciVersionMajeurApres "2.4.2" && ciVersionMajeurAvant "2.6.0"
    then
        SQUID=squid3
    else
        SQUID=squid
    fi
    if [ "$VM_CONTAINER" == "oui" ]
    then
        FICHIER_NOAUTH=/opt/lxc/internet/rootfs/etc/${SQUID}/domaines_noauth
    else
        FICHIER_NOAUTH=/etc/${SQUID}/domaines_noauth
    fi
    # Attention: ce fichier n'est utilisé que pour la configuration minimale, l'instance
    # écrasera ce fichier !
    # si le fichier existe, et qu'il est vide
    if [ -f $FICHIER_NOAUTH ]
    then
        if [[ -s $FICHIER_NOAUTH ]]
        then
            ciPrintMsgMachine "Injection domaines NOAUTH"
            cat >$FICHIER_NOAUTH <<EOF
.debian.org
.test-eoleng.ac-dijon.fr
.test-eole.ac-dijon.fr
.eole.ac-dijon.fr
.eole.lan
.yarnpkg.com
.nodesource.com
EOF
        fi
    fi

    ciPrintConsole "Contextualisation minimale OK"
    VM_ID_MINIMALE_DATE=$(date "+%Y-%m-%d %H:%M:%S")
    cat >/root/.eole-ci-tests.minimale <<EOF
VM_ID_MINIMALE="$VM_ID"
VM_ID_MINIMALE_DATE="$VM_ID_MINIMALE_DATE"
EOF
    #cat /root/.eole-ci-tests.minimale
    ciPrintMsgMachine "Fin ciContextualisationMinimale"
}
export -f ciContextualisationMinimale

#########################################################################################################
#
# impose ip static
#
#########################################################################################################
function ciConfigurationIpStaticUbuntu()
{
    if [ "$VM_EST_MACHINE_EOLE" == "non" ] && ciUtiliseSystemdNetplan
    then
        ciPrintMsgMachine "netplan apply --debug"
        netplan --debug apply
        sleep 5

        ciDisplayGatewayIp
    else
        SSH_ACTIVE=$(ciIsActiveService ssh)
        if [ "$SSH_ACTIVE" == "active" ]
        then
            ciPrintMsgMachine "ARRET SSH"
            service ssh stop
        fi

        ciPrintMsgMachine "ip $VM_INTERFACE0_NAME down/up"
        if [ -f "/run/network/ifstate.$VM_INTERFACE0_NAME" ]
        then
            /bin/rm -f "/run/network/ifstate.$VM_INTERFACE0_NAME"
        fi
        ip link set "$VM_INTERFACE0_NAME" down
        ip link set "$VM_INTERFACE0_NAME" up

        if [ "$SSH_ACTIVE" == "active" ]
        then
            ciPrintMsgMachine "redémarrage SSH"
            service ssh start
        fi
    fi

    LESIPS=$(ciGetCurrentIp)
    ciPrintMsgMachine "LESIPS=$LESIPS (vérification)"
    if [ "$LESIPS" != "$VM_ETH0_IP" ]
    then
        # Ouille,... si upstart ?
        if ciVersionMajeurAvant "2.6.0"
        then
            ciPrintMsgMachine "Configuration $VM_INTERFACE0_NAME en ${VM_VERSIONMAJEUR}"
            /bin/ip addr flush dev "$VM_INTERFACE0_NAME"
            /bin/ip addr add "${VM_ETH0_IP}/255.255.255.0" broadcast "${VM_ETH0_NETWORK}.255" dev "$VM_INTERFACE0_NAME" label "$VM_INTERFACE0_NAME"
            /bin/ip link set dev "$VM_INTERFACE0_NAME" up
            /bin/ip route add default via "${VM_ETH0_GW}" dev "$VM_INTERFACE0_NAME" onlink
        fi
    fi

}
export -f ciConfigurationIpStaticUbuntu

#########################################################################################################
#
# impose ip static
#
#########################################################################################################
function ciConfigurationIpStaticFreebsd()
{
    ifconfig "$VM_INTERFACE0_NAME" inet "${VM_ETH0_IP}"
}
export -f ciConfigurationIpStaticFreebsd

#########################################################################################################
#
# impose la configration minimale de la machine (ip, route, gw, ssh, autorized keys)
#
#########################################################################################################
function ciConfigurationMinimale()
{
    # pour ne pas etre reexcute en cas de réexecution
    # si reboot ==> ignore
    # si delete recreate ==> ignore
    if [ -f /root/.eole-ci-tests.confminimale ]
    then
        # shellcheck disable=SC1091
        source /root/.eole-ci-tests.confminimale 2>/dev/null
        export VM_ID_CONFMINIMALE
        export VM_ID_CONFMINIMALE_DATE
        if [ "$VM_ID" == "$VM_ID_CONFMINIMALE" ]
        then
            ciPrintMsgMachine "ciConfigurationMinimale: déjà réalisée à $VM_ID_CONFMINIMALE_DATE"
            return 0
        else
            ciPrintMsgMachine "ciConfigurationMinimale: réalisée pour $VM_ID_CONFMINIMALE, à refaire"
        fi
    else
        ciPrintMsgMachine "ciConfigurationMinimale: 1er fois, à faire..."
    fi

    ciGetDirConfigurationMachine
    ciGetNamesInterfaces

    if [[ "$VM_ETH0_DHCP" = non ]]
    then
        LESIPS=$(ciGetCurrentIp)
        if [ "$LESIPS" != "$VM_ETH0_IP" ]
        then
            ciPrintMsgMachine "IP actuelle: $LESIPS, attendue: $VM_ETH0_IP"
            ciPrintMsgMachine "Redémarrage network à faire (!)"
            if [ "$VM_IS_UBUNTU" == "1" ]
            then
                ciConfigurationIpStaticUbuntu
            fi
            if [ "$VM_IS_FREEBSD" == "1" ]
            then
                ciConfigurationIpStaticFreebsd
            fi
        else
            ciPrintMsgMachine "IP actuelle $LESIPS OK"
        fi
    fi

    GW_ACTUEL="$(ciGetGatewayIP)"
    if [ "$GW_ACTUEL" != "${VM_ETH0_GW}" ]
    then
        ciSetGatewayIP
    else
        ciPrintMsgMachine "GW actuelle : $GW_ACTUEL OK"
    fi

    if [ -f "$DIR_CONFIGURATION_MACHINE/minimale/startup.sh" ]
    then
        ciPrintMsgMachine "Execution $DIR_CONFIGURATION_MACHINE/minimale/startup.sh "
        "$DIR_CONFIGURATION_MACHINE/minimale/startup.sh"
    else
        ciPrintMsgMachine "pas de fichier startup '$DIR_CONFIGURATION_MACHINE/minimale/startup.sh' "
    fi

    if [ "$VM_IS_UBUNTU" == "1" ]
    then
        if [ "$(cat /proc/sys/vm/swappiness)" == "60" ]
        then
            ciPrintMsgMachine "Configurer sysctl.swapiness=0"
            sysctl vm.swappiness=0 >/dev/null
        fi
    fi

    ciPrintConsole "Configuration minimale OK"
    VM_ID_CONFMINIMALE_DATE=$(date "+%Y-%m-%d %H:%M:%S")
    cat >/root/.eole-ci-tests.confminimale <<EOF
VM_ID_CONFMINIMALE="$VM_ID"
VM_ID_CONFMINIMALE_DATE="$VM_ID_CONFMINIMALE_DATE"
EOF
    #cat /root/.eole-ci-tests.confminimale
    ciPrintMsgMachine "Fin ciConfigurationMinimale : $VM_ID le $VM_ID_CONFMINIMALE_DATE"
}
export -f ciConfigurationMinimale

############################################################################################
#
# Gestion de la configuration 'minimale' si le module n'est pas instancié !
#
############################################################################################
function ciConfigureAutomatiqueMinimale()
{
    local COUNT_UP
    local CURRENT_IP
    local RESULT_PING

    ciPrintMsgMachine "Debut ciConfigureAutomatiqueMinimale"

    if [[ -z "$VM_ETH0_IP" ]] && [[ -z "$VM_ETH0_DHCP" ]]
    then
        ciPrintMsgMachine "Fichier de context.sh pour la VM_MACHINE = $VM_MACHINE n'a pas été chargé ou n'existe pas"
        return 1
    fi

    if [[ "$VM_ETH0_DHCP" = oui ]]
    then
        ciPrintMsgMachine "Configurer en DHCP"
        ciConfigurationMinimale
        CURRENT_IP="$(ciGetCurrentIp)"

        ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "Configuration minimale DHCP : $CURRENT_IP"
        return 0
    fi

    if [[ -z "$VM_ETH0_IP" ]]
    then
        ciPrintMsgMachine "VM_ETH0_IP est vide malgré VM_ETH0_DHCP=non pour la VM_MACHINE = $VM_MACHINE. Abandon !"
        return 1
    fi

    CURRENT_IP="$(ciGetCurrentIp)"
    if [[ -z "$CURRENT_IP" ]]
    then
        ciPrintMsgMachine "CURRENT_IP vide !"
        set -x
        ciGetCurrentIp
        set +x
        ip addr
    fi

    if [[ "$VM_ETH0_IP" == "$CURRENT_IP" ]]
    then
        ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "Configuration déjà réalisée avec $VM_ETH0_IP"
        return 0
    fi
    #
    # Opus... : nous sommes en dhcp. normalement, la contextualization aurait du donner les bonnes
    #   valeurs. Donc, nous essayons de résoudre le pb !
    #
    ciPrintMsgMachine "CURRENT_IP=$CURRENT_IP"

    ciGetNamesInterfaces
    ciPrintMsgMachine "Check '$VM_INTERFACE0_NAME' Up"
    COUNT_UP=$(ip addr show dev "$VM_INTERFACE0_NAME" |grep -c UP)
    if [ "$COUNT_UP" -gt "1" ];
    then
        ciPrintMsgMachine "Interface DOWN et pas instancié, donc configuration minimale"
        ciConfigurationMinimale

        ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "Configuration minimale : $VM_ETH0_IP"
        return 0
    fi

    ciPrintMsgMachine "Check hostname -I vide"
    if [[ "$CURRENT_IP" = "" ]]
    then
        ciPrintMsgMachine "Pas d'ip ==> impossible de tester avec ip disponible ==> conf minimale imposée"
        ciConfigurationMinimale

        ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "Configuration minimale imposée ! : $VM_ETH0_IP"
        return 0
    fi

    ciPrintMsgMachine "Check $VM_ETH0_IP in use ?"
    ciPingHost "$VM_ETH0_IP" "$VM_INTERFACE0_NAME"
    RESULT_PING=$?
    if [[ $RESULT_PING -eq 0 ]]
    then
        ciPrintMsg "RESULT_PING=$RESULT_PING, WARNING ADRESS IN USE, Stop !"
        # on continue, mais attention la machine n'est pas correcte
        ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "ERREUR ADRESSE IN USE : $VM_ETH0_IP"
        return 0
    fi

    ciPrintConsole "Ip $VM_ETH0_IP libre et pas instancié, donc configuration minimale"
    ciConfigurationMinimale

    ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "Configuration auto minimale : $VM_ETH0_IP"
    return 0
}
export -f ciConfigureAutomatiqueMinimale

#########################################################################################################
#
# determine quel repertoire utiliser pour la configuration de la machine
#
#########################################################################################################
function ciGetDirConfigurationMachine()
{
    DIR_CONFIGURATION_MACHINE=$VM_DIR_EOLE_CI_TEST/configuration/$VM_MACHINE/
    export DIR_CONFIGURATION_MACHINE
}
export -f ciGetDirConfigurationMachine

#########################################################################################################
#
# determine quel repertoire utiliser pour les sortie Owner
#
#########################################################################################################
function ciGetDirOutputOwner()
{
    DIR_OUTPUT_OWNER="$VM_DIR_EOLE_CI_TEST/output/$VM_OWNER/"
    export DIR_OUTPUT_OWNER
    ciPrintDebug "Output owner dans : $DIR_OUTPUT_OWNER"
}
export -f ciGetDirOutputOwner

#########################################################################################################
#
# determine quel repertoire utiliser pour les sortie de la VM
#
#########################################################################################################
function ciGetDirOutputVm()
{
    DIR_OUTPUT_VM="$DIR_OUTPUT_OWNER/$VM_ID/"
    export DIR_OUTPUT_VM
    ciPrintDebug "Output VM dans : $DIR_OUTPUT_VM"
}
export -f ciGetDirOutputVm

#########################################################################################################
#
# determine quel repertoire utiliser pour la configuration de la machine
#
#########################################################################################################
function ciGetDirConfigurationMinimale()
{
    ciGetDirConfigurationMachine
    DIR_CONFIGURATION=$DIR_CONFIGURATION_MACHINE/minimale
    ciPrintDebug "Configuration de : $DIR_CONFIGURATION"
}
export -f ciGetDirConfigurationMinimale

#########################################################################################################
#
# récupére la configuration d'une anceinne version
#
#########################################################################################################
function ciGetConfigurationFromOldVersion()
{
    ciPrintDebug "ciGetConfigurationFromOldVersion $CONFIGURATION ${VM_VERSIONMAJEUR}"
    ALL_VERSION="2.10.0 2.9.0 2.8.1 2.8.0 2.7.2 2.7.1 2.7.0 2.6.2 2.6.1 2.6.0 2.5.2"
    for V in $ALL_VERSION
    do
        if ciVersionMajeurApres "$V"
        then
            if [ -d "$DIR_CONFIGURATION_MACHINE/$CONF-$V" ]
            then
                /bin/cp -rf "$DIR_CONFIGURATION_MACHINE/${CONF}-$V/" "$DIR_CONFIGURATION_MACHINE/${CONF}-${VM_VERSIONMAJEUR}/"
                CONFIGURATION_A_MIGRER=oui
                ciPrintMsg "ATTENTION : Copie de version $CONFIGURATION $V, CONFIGURATION A MIGRER !"
                return
            fi
        fi
    done
}
export -f ciGetConfigurationFromOldVersion

#########################################################################################################
#
# get default CONFIGURATION 
# si INSTANCE existe --> CONFIGURATION=INSTANCE_CONFIGURATION
# sinon CONFIGURATION=default
#########################################################################################################
function ciGetDefaultConfiguration()
{
    if [ -n "$INSTANCE_CONFIGURATION" ]
    then
        CONFIGURATION="$INSTANCE_CONFIGURATION"
    else
        CONFIGURATION=default
    fi
    export CONFIGURATION
}
export -f ciGetDefaultConfiguration

#########################################################################################################
#
# determine quel repertoire utiliser pour la configuration de la machine
#
#########################################################################################################
function ciGetDirConfiguration()
{
    ciPrintDebug "ciGetDirConfiguration $CONFIGURATION ${VM_VERSIONMAJEUR}"

    CONFIGURATION_A_MIGRER=non
    local CONF=$CONFIGURATION
    if [[ "$CONF" == "minimale" ]]
    then
        ciGetDirConfigurationMinimale
        # bretelles !
        if [ ! -d "$DIR_CONFIGURATION_MACHINE" ]
        then
            ciPrintErreurAndExit "Machine $VM_MACHINE : le répertoire de template '$DIR_CONFIGURATION' n'existe pas, stop"
        fi
        return 0
    fi

    ciGetDirConfigurationMachine
    # bretelles !
    if [ ! -d "$DIR_CONFIGURATION_MACHINE" ]
    then
        ciPrintErreurAndExit "Machine $VM_MACHINE : le répertoire de template '$DIR_CONFIGURATION' n'existe pas, stop"
    fi

    if [[ "$CONF" == "" ]]
    then
        ciGetDefaultConfiguration
        CONF=$CONFIGURATION
    fi

    if [ ! -d "$DIR_CONFIGURATION_MACHINE/${CONF}-${VM_VERSIONMAJEUR}" ]
    then
        ciGetConfigurationFromOldVersion
    fi

    if [ -d "$DIR_CONFIGURATION_MACHINE/$CONF-${VM_VERSIONMAJEUR}" ]
    then
        DIR_CONFIGURATION=$DIR_CONFIGURATION_MACHINE/$CONF-${VM_VERSIONMAJEUR}
        ciPrintDebug "Configuration de : $DIR_CONFIGURATION"
        return 0
    fi

    ciPrintErreurAndExit "Machine $VM_MACHINE : Pas de configuration pour la version ${VM_VERSIONMAJEUR} : ni pour $CONFIGURATION, ni pour 'default', Erreur grave !"
}
export -f ciGetDirConfiguration

#########################################################################################################
#
# determine le repertoire à utiliser pour la sauvegarde Bacula de la machine
#
#########################################################################################################
function ciGetDirSauvegarde()
{
    ciPrintDebug "ciGetDirSauvegarde $CONFIGURATION ${VM_VERSIONMAJEUR}"

    if [ -z "${VM_VERSIONMAJEUR}" ]
    then
        ciPrintErreurAndExit "Machine $VM_MACHINE : la variable CONFIGURATION n'est pas définie, stop"
    fi

    if [ -z "$CONFIGURATION" ]
    then
        ciPrintMsg "Machine $VM_MACHINE : la variable CONFIGURATION n'est pas définie, utilise 'default'"
        ciGetDefaultConfiguration
    fi

    DIR_SAUVEGARDE_MNT=$VM_DIR_EOLE_CI_TEST/sauvegarde
    if [ ! -d "$DIR_SAUVEGARDE_MNT" ]
    then
        ciCreateDir "$DIR_SAUVEGARDE_MNT"
    fi

    DIR_SAUVEGARDE_MACHINE=$DIR_SAUVEGARDE_MNT/$VM_MACHINE
    if [ ! -d "$DIR_SAUVEGARDE_MACHINE" ]
    then
        ciCreateDir "$DIR_SAUVEGARDE_MACHINE"
    fi

    DIR_SAUVEGARDE=$DIR_SAUVEGARDE_MACHINE/$CONFIGURATION-${VM_VERSIONMAJEUR}
    ciPrintMsg "Répertoire de sauvegarde : $DIR_SAUVEGARDE"
    if [ ! -d "$DIR_SAUVEGARDE" ]
    then
        ciCreateDir "$DIR_SAUVEGARDE"
    fi
}
export -f ciGetDirSauvegarde

#########################################################################################################
#
# Check Connectivite
#
#########################################################################################################
function ciCheckConnectivite()
{
    ciPrintDebug "ciCheckConnectivite"
    RETVAL="0"

    ciPrintMsg "*********************************************"
    ciPrintMsg "* Affiche connectivité"
    ciPrintMsg "*********************************************"
    ip addr |grep "inet "

    if [[ "$VM_ETABLISSEMENT" = "" ]]
    then
        ciPrintMsg "*********************************************"
        ciPrintMsg "* Ping Gateway EOLE 192.168.230.254"
        ciPrintMsg "*********************************************"
        ciPingHost 192.168.230.254 "$VM_INTERFACE0_NAME"
        RETVAL="$?"
        if [[ "$RETVAL" == "1" ]]
        then
            ciPingHost 192.168.232.2 "$VM_INTERFACE0_NAME"
            RETVAL="$?"
            ciSignalAttention "Ping DNS EOLE !!!!!!!!!!!!!! ==> RETVAL=$RETVAL"
        else
            ciPrintMsg "Ping Gateway EOLE ==> RETVAL=$RETVAL"
        fi
    else
        if [[ "$VM_ETABLISSEMENT" = "aca" ]]
        then
            ciPrintMsg "*********************************************"
            ciPrintMsg "* Ping Gateway $VM_ETH0_GW"
            ciPrintMsg "*********************************************"
            ciPingHost "$VM_ETH0_GW" "$VM_INTERFACE0_NAME"
            RETVAL="$?"
            if [[ "$RETVAL" == "1" ]]
            then
                ciPingHost 192.168.232.2 "$VM_INTERFACE0_NAME"
                RETVAL="$?"
                ciSignalAttention "Ping DNS EOLE !!!!!!!!!!!!!! ==> RETVAL=$RETVAL"
                
                ciDiagnoseNetwork
            else
                ciPrintMsg "Ping Gateway ==> RETVAL=$RETVAL"
            fi
        fi
    fi

    return "$RETVAL"
}
export -f ciCheckConnectivite

#########################################################################################################
#
# Check Connectivite Http
#
#########################################################################################################
function ciCheckAccesInternet()
{
    ciPrintDebug "ciCheckAccesInternet"
    # il est important de positionner http_proxy si besoin. il ne faut pas le faire dans le context de ce shell
    (
        ciGetNamesInterfaces
        ciSetHttpProxy
        ciCheckConnectivite
        ciWaitTestHttp "http://ftp.crihan.fr/ubuntu/dists" 2
        ciWaitTestHttp "http://eole.ac-dijon.fr/ubuntu/dists" 2
        ciWaitTestHttp "http://test-eole.ac-dijon.fr/ubuntu/dists" 2
    )
}
export -f ciCheckAccesInternet

#########################################################################################################
#
# Mount Context
#
#########################################################################################################
function ciMountContext()
{
    if [[ -e /dev/disk/by-label/CONTEXT ]]
    then
        ciPrintMsg "Monte CDROM de CONTEXT dans /mnt/cdrom (Ubuntu)"
        mount -t iso9660 -o ro -L CONTEXT /mnt/cdrom
        return $?
    fi

    if [ -e /dev/iso9660/CONTEXT ];
    then
        ciPrintMsg "Monte CDROM de CONTEXT dans /mnt/cdrom (Freebsd)"
        mount -t cd9660 -o ro /dev/iso9660/CONTEXT /mnt/cdrom
        return $?
    fi

    #ciPrintErreurAndExit "getVMContext.sh: Pas de context Nebula ==> Arrêt"
    ciSignalWarning "ciMountContext: Pas de label context Nebula ==> Arrêt ?"

    CD="$(find /dev/sr* | sort | tail -1)"
    if [ -n "$CD" ]
    then
        ciSignalHack "Monte CDROM de $CD dans /mnt/cdrom (Ubuntu)"
        mount -t iso9660 -o ro "$CD" /mnt/cdrom
    fi
    CD="$(find /dev/cd* | sort | tail -1)"
    if [ -n "$CD" ]
    then
        ciSignalHack "Monte CDROM de $CD dans /mnt/cdrom (Freebsd)"
        mount -t cd9660 -o ro "$CD" /mnt/cdrom
    fi
    return $?
}
export -f ciMountContext

#########################################################################################################
#
# Get Context Vm
#
#########################################################################################################
function ciGetContextCDROM()
{
    ciPrintDebug "GetContextCDROM"

    [[ ! -d /mnt ]] && mkdir -p /mnt

    [[ ! -d /mnt/cdrom ]] && mkdir -p /mnt/cdrom

    # test si deja monté !
    if [[ ! -f /mnt/cdrom/context.sh ]]
    then
        if ! ciMountContext
        then
            echo "pb montage context Nebula ==> réessai"
            sleep 10
            ciMountContext
        fi
    fi

    if [ -f /mnt/cdrom/context.sh ]
    then
        # shellcheck disable=SC1091,SC1090
        source /mnt/cdrom/context.sh
        export VM_DEBUG          # 0,1,2 ...
        export VM_ID             # "1900"
        export VM_OWNER          # "gilles"
        export VM_MACHINE        # "aca.eolebase"
        export VM_HOSTNAME       # "eolebase"
        export VM_ONE            # "one, ..."
        export VM_DAEMON         # "once, start"
        export VM_METHODE        # instance, testCharge
        export VM_CONFIGURATION  # default ...
        # pour daily
        export VM_MAJAUTO        # "STABLE"
        export VM_VERSIONMAJEUR  # "2.3"
        export VM_CONTAINER      # "non"
    else
        #ciPrintErreurAndExit "getVMContext.sh: Pas de context Nebula ==> Arrêt"
        ciSignalWarning "getVMContext.sh: Pas de context Nebula ==> Arrêt"
    fi

    if [ -f /root/.apres_upgrade ]
    then
        VERSION_CIBLE="$(cat /root/.apres_upgrade)"
        ciPrintMsg "VM_VERSIONMAJEUR surchargé par $VERSION_CIBLE suite à upgrade"
        VM_VERSIONMAJEUR="$VERSION_CIBLE"
        export VM_VERSIONMAJEUR
    fi

    if [[ -z "$VM_DAEMON" ]]
    then
        export VM_DAEMON="once"
    fi
    return 0
}
export -f ciGetContextCDROM

#########################################################################################################
#
# ciCheckPath
#
#########################################################################################################
function ciCheckPath()
{
    ciPrintDebug "CheckPath"

    # inject le PATH EOLE pour les traitements avant instaniation
    if [[ ":$PATH:" != *":/usr/share/eole:"* ]];
    then
        #ciPrintMsg "Inject /usr/share/eole dans PATH"
        export PATH=/snap/bin:/usr/share/eole:/usr/share/eole/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    fi
    if [[ ":$PYTHONPATH:" != *":$VM_DIR_EOLE_CI_TEST/scripts/monitor3:"* ]];
    then
        #ciPrintMsg "Inject $VM_DIR_EOLE_CI_TEST/scripts/monitor3 dans PYTHONPATH"
        export PYTHONPATH="$VM_DIR_EOLE_CI_TEST/scripts/monitor3:$VM_DIR_EOLE_CI_TEST/scripts:$PYTHONPATH"
    fi

    # inject le repertoire de script à la fin du PATH si pas présent
    if [[ ":$PATH:" != *":$VM_DIR_EOLE_CI_TEST/scripts:"* ]];
    then
        export PATH=$PATH:$VM_DIR_EOLE_CI_TEST/scripts
        #ciPrintMsg "Inject $VM_DIR_EOLE_CI_TEST/scripts dans PATH"
    fi
    return 0
}
export -f ciCheckPath

#########################################################################################################
#
# Get Context Owner
#
#########################################################################################################
function ciGetContextOwner()
{
    ciPrintDebug "GetContextOwner"
    if [[ -z "$IP_GW" ]]
    then
        local CONTEXT
        CONTEXT="$VM_DIR_EOLE_CI_TEST/configuration/gateway/routeur_$VM_OWNER.sh"
        if [ -f "$CONTEXT" ]
        then
            ciPrintDebug "load '$CONTEXT'"
            # shellcheck disable=SC1090
            source "$CONTEXT"
            if [[ "$VM_ONE" == one ]]
            then
                IP_GW=$IP_ONE
            else
                IP_GW=$IP_EOLE
            fi
            if [[ -z "$IP_GW_UTILISATEUR" ]]
            then
                IP_GW_UTILISATEUR=192.168.230.$IP_GW
            fi

            # ip complete de la gateway ACADEMIE de utilisateur
            export IP_GW_UTILISATEUR

            # ip (0-255) du reseau EOLE pour la gateway ACADEMIE de utilisateur
            export IP_GW

            # ip complete du poste du développeur pour notification
            export IP_UTILISATEUR

            # ip complete de la configuration ROADWARRIOR
            export IP_ROADWARRIOR

            # boite mail de renvoi de tous les mails venant des VM
            export MAIL_UTILISATEUR

            # variable pour savoir s'il faut attacher la GW a un noeud Jenkins
            export AGENT_JENKINS
            export VM_JNLPMAC

            # variable pour savoir s'il faut attacher la GW a un runner Gitlab
            export AGENT_GITLAB
        else
            ciPrintDebug "fichier '$CONTEXT' inexistant ou illisible"
            return 1
        fi
    fi
    return 0
}
export -f ciGetContextOwner

#########################################################################################################
#
# Get Context Machine
#
#########################################################################################################
function ciGetContextMachine()
{
    ciPrintDebug "GetContextMachine"
    if [[ -z "$VM_MODULE" ]]
    then
        local CONTEXT
        CONTEXT="$VM_DIR_EOLE_CI_TEST/configuration/$VM_MACHINE/context.sh"
        if [ -d "$VM_DIR_EOLE_CI_TEST/configuration/$VM_MACHINE" ]
        then
            if [ -f "$CONTEXT" ]
            then
                ciPrintDebug "load '$CONTEXT'"
                # shellcheck disable=SC1091,SC1090
                source "$CONTEXT"
                export VM_ETABLISSEMENT
                export VM_NO_ETAB
                export VM_MODULE
                export VM_CONTAINER
                export VM_VERSIONMAJEUR
                export VM_EST_MACHINE_EOLE

                export VM_ETH0_DHCP
                export VM_ETH0_IP
                export VM_ETH0_GW
                export VM_ETH0_NAME
                export VM_ETH0_NETWORK
                export VM_ETH0_DNS

                export VM_ETH1_DHCP
                export VM_ETH1_IP
                export VM_ETH1_GW
                export VM_ETH1_NAME
                export VM_ETH1_NETWORK
                export VM_ETH1_DNS

                export VM_ETH2_DHCP
                export VM_ETH2_IP
                export VM_ETH2_GW
                export VM_ETH2_NAME
                export VM_ETH2_NETWORK
                export VM_ETH2_DNS

                export VM_ETH3_DHCP
                export VM_ETH3_IP
                export VM_ETH3_GW
                export VM_ETH3_NAME
                export VM_ETH3_NETWORK
                export VM_ETH3_DNS

                export VM_ETH4_DHCP
                export VM_ETH4_IP
                export VM_ETH4_GW
                export VM_ETH4_NAME
                export VM_ETH4_NETWORK
                export VM_ETH4_DNS
                return 0
            else
                ciPrintDebug "fichier '$CONTEXT' inexistant ou illisible"
                return 1
            fi
        else
            return 1
        fi
    else
        return 0
    fi
}
export -f ciGetContextMachine

#########################################################################################################
#
# Get Context Fresh Install
#
#########################################################################################################
function ciGetContextFreshInstall()
{
    ciPrintDebug "GetContextFreshInstall"
    if [[ -z "$FRESHINSTALL_IMAGE" ]]
    then
        local CONTEXT
        CONTEXT="/root/.eole-ci-tests.freshinstall"
        if [ -f $CONTEXT ]
        then
            ciPrintDebug "load '$CONTEXT'"
            # shellcheck disable=SC1091,SC1090
            source "$CONTEXT"
            export FRESHINSTALL_IMAGE
            export FRESHINSTALL_ISO
            export FRESHINSTALL_VERSIONMAJEUR
            export FRESHINSTALL_VERSION
            export FRESHINSTALL_ARCHITECTURE
            export FRESHINSTALL_MODULE
            export FRESHINSTALL_MAJAUTO
            export FRESHINSTALL_CONTAINER
        else
            ciPrintDebug "fichier '$CONTEXT' inexistant ou illisible"
            return 1
        fi
    fi
    return 0
}
export -f ciGetContextFreshInstall

#########################################################################################################
#
# Get Context Daily
#
#########################################################################################################
function ciGetContextDaily()
{
    ciPrintDebug "ciGetContextDaily"
    local CONTEXT
    CONTEXT="/root/.eole-ci-tests.daily"
    if [ -f $CONTEXT ]
    then
        ciPrintDebug "load '$CONTEXT'"
        DAILY_DATEUPDATE=0
        # shellcheck disable=SC1091,SC1090
        source "$CONTEXT"
        export DAILY_DATE
        export DAILY_DATEUPDATE
        export DAILY_CONTAINER
        export DAILY_MAJAUTO
        return 0
    else
        ciPrintDebug "fichier '$CONTEXT' inexistant ou illisible"
        return 1
    fi
}
export -f ciGetContextDaily

#########################################################################################################
#
# Get Context Instance
#
#########################################################################################################
function ciGetContextInstance()
{
    ciPrintDebug "ciGetContextInstance"
    if [[ -z "$INSTANCE_DATE" ]]
    then
        local CONTEXT
        CONTEXT="/root/.eole-ci-tests.instance"
        if [ -f $CONTEXT ]
        then
            ciPrintDebug "load '$CONTEXT'"
            # shellcheck disable=SC1091,SC1090
            source "$CONTEXT"
            export INSTANCE_DATEUPDATE
            export INSTANCE_METHODE
            export INSTANCE_CONFIGURATION
            export INSTANCE_MACHINE
            export INSTANCE_VERSIONMAJEUR
            export INSTANCE_DATE
            export INSTANCE_MD5
        else
            ciPrintDebug "fichier '$CONTEXT' inexistant ou illisible"
            return 1
        fi
    fi
    return 0
}
export -f ciGetContextInstance

#########################################################################################################
#
# Display Context Vm
#
#########################################################################################################
function ciDisplayContext()
{
    ciPrintDebug "DisplayContext"
    #ciPrintMsg "PATH     : $PATH"
    ciPrintMsg "TEMPLATE : VM_ONE=$VM_ONE, VM_ID=$VM_ID, VM_OWNER=$VM_OWNER, VM_DAEMON=$VM_DAEMON, VM_MACHINE=$VM_MACHINE"
    ciPrintMsg "TEMPLATE : VM_VERSIONMAJEUR=${VM_VERSIONMAJEUR}, VM_MAJAUTO=$VM_MAJAUTO"
    [[ -n "$VM_METHODE" ]]          && ciPrintMsg "ONBOOT   : VM_METHODE=$VM_METHODE, VM_CONFIGURATION=$VM_CONFIGURATION"
    [[ -n "$IP_GW_UTILISATEUR" ]]   && ciPrintMsg "USER     : IP_GW=$IP_GW, GW=$IP_GW_UTILISATEUR, IP_UTILISATEUR=$IP_UTILISATEUR, MAIL=$MAIL_UTILISATEUR"
    [[ -n "$FRESHINSTALL_IMAGE" ]]  && ciPrintMsg "FI       : IMAGE=$FRESHINSTALL_IMAGE, ISO=$FRESHINSTALL_ISO, MODULE=$FRESHINSTALL_MODULE"
    [[ -n "$DAILY_DATEUPDATE" ]]    && ciPrintMsg "DAILY    : DATE=$DAILY_DATE, MAJAUTO=$DAILY_MAJAUTO"
    [[ -n "$INSTANCE_DATEUPDATE" ]] && ciPrintMsg "INSTANCE : DATE=$INSTANCE_DATE, METHODE=$INSTANCE_METHODE, CONFIGURATION=$INSTANCE_CONFIGURATION"
    ciPrintMsg "MODELE   : VM_MODULE=$VM_MODULE, VM_CONTAINER=$VM_CONTAINER, VM_ETABLISSEMENT=$VM_ETABLISSEMENT"
    [[ -n "$VM_ETH0_NAME" ]] && ciPrintMsg "ETH0     : NAME=$VM_ETH0_NAME, DHCP=$VM_ETH0_DHCP, IP=$VM_ETH0_IP, GW=$VM_ETH0_GW, DNS=$VM_ETH0_DNS"
    [[ -n "$VM_ETH1_NAME" ]] && ciPrintMsg "ETH1     : NAME=$VM_ETH1_NAME, DHCP=$VM_ETH1_DHCP, IP=$VM_ETH1_IP, GW=$VM_ETH1_GW, DNS=$VM_ETH1_DNS"
    [[ -n "$VM_ETH2_NAME" ]] && ciPrintMsg "ETH2     : NAME=$VM_ETH2_NAME, DHCP=$VM_ETH2_DHCP, IP=$VM_ETH2_IP, GW=$VM_ETH2_GW, DNS=$VM_ETH2_DNS"
    [[ -n "$VM_ETH3_NAME" ]] && ciPrintMsg "ETH3     : NAME=$VM_ETH3_NAME, DHCP=$VM_ETH3_DHCP, IP=$VM_ETH3_IP, GW=$VM_ETH3_GW, DNS=$VM_ETH3_DNS"
    [[ -n "$VM_ETH4_NAME" ]] && ciPrintMsg "ETH4     : NAME=$VM_ETH4_NAME, DHCP=$VM_ETH4_DHCP, IP=$VM_ETH4_IP, GW=$VM_ETH4_GW, DNS=$VM_ETH4_DNS"
}
export -f ciDisplayContext

#########################################################################################################
#
# Get Context Vm
#
#########################################################################################################
function ciGetContext()
{
    ciPrintDebug "GetContext"
    ciGetContextCDROM
    if [[ -z "$VM_ID" ]]
    then
        ciPrintErreurAndExit "Pas de VM_ID : stop "
    fi
    if [[ -z "$HOME" ]]
    then
        HOME=/root
        export HOME
    fi
    ciCheckPath
    ciInitOutput
    ciGetContextOwner
    ciGetContextMachine || /bin/true
    ciGetContextFreshInstall || /bin/true
    ciGetContextDaily || /bin/true
    ciGetContextInstance || /bin/true
    ciGetDirOutputOwner
    ciGetDirOutputVm
    if [ "$VM_OWNER" == ggrandgerard ] || [ "$VM_OWNER" == jenkins ]
    then
        #echo "Surcharge LS_COLORS"

        #bd = (BLOCK, BLK)   Block device (buffered) special file
        #cd = (CHAR, CHR)    Character device (unbuffered) special file
        #di = (DIR)  Directory
        #do = (DOOR) [Door][1]
        #ex = (EXEC) Executable file (ie. has 'x' set in permissions)
        #fi = (FILE) Normal file
        #ln = (SYMLINK, LINK, LNK)   Symbolic link. If you set this to ‘target’ instead of a numerical value, the color is as for the file pointed to.
        #mi = (MISSING)  Non-existent file pointed to by a symbolic link (visible when you type ls -l)
        #no = (NORMAL, NORM) Normal (non-filename) text. Global default, although everything should be something
        #or = (ORPHAN)   Symbolic link pointing to an orphaned non-existent file
        #ow = (OTHER_WRITABLE)   Directory that is other-writable (o+w) and not sticky
        #pi = (FIFO, PIPE)   Named pipe (fifo file)
        #sg = (SETGID)   File that is setgid (g+s)
        #so = (SOCK) Socket file
        #st = (STICKY)   Directory with the sticky bit set (+t) and not other-writable
        #su = (SETUID)   File that is setuid (u+s)
        #tw = (STICKY_OTHER_WRITABLE)    Directory that is sticky and other-writable (+t,o+w)
        #*.extension =   Every file using this extension e.g. *.rpm = files with the ending .rpm

        #0   = default colour
        #1   = bold
        #4   = underlined
        #5   = flashing text (disabled on some terminals)
        #7   = reverse field (exchange foreground and background color)
        #8   = concealed (invisible)

        #40  = black background
        #41  = red background
        #42  = green background
        #43  = orange background
        #44  = blue background
        #45  = purple background
        #46  = cyan background
        #47  = grey background
        #100 = dark grey background
        #101 = light red background
        #102 = light green background
        #103 = yellow background
        #104 = light blue background
        #105 = light purple background
        #106 = turquoise background
        #107 = white background

        #30  = black
        #31  = red
        #32  = green
        #33  = orange
        #34  = blue
        #35  = purple
        #36  = cyan
        #37  = grey
        #90  = dark grey
        #91  = light red
        #92  = light green
        #93  = yellow
        #94  = light blue
        #95  = light purple
        #96  = turquoise
        #97  = white
        LS_COLORS=$LS_COLORS:'di=1;33:ln=36'
        export LS_COLORS
    fi
    return 0
}
export -f ciGetContext

#########################################################################################################
#
# gen Conteneur
#
#########################################################################################################
function ciGenConteneur()
{
    ciPrintMsgMachine "GenConteneur"
    if [[ "$VM_CONTAINER" = "oui" ]]
    then
        ciPrintMsg "*********************************************"
        ciPrintMsg "* Test conteneurs ? "
        ciPrintMsg "*********************************************"
        if [ -d /opt/lxc ]
        then
            ciPrintMsg "* /opt/lxc ? "
            ls -l /opt/lxc
        fi
        if [ -d /var/lib/lxc ]
        then
            ciPrintMsg "* /var/lib/lxc ? "
            ls -l /var/lib/lxc
        fi
        LIST_CONTENEUR=$(lxc-ls)
        ciPrintMsg "LIST_CONTENEUR=$LIST_CONTENEUR"
        if [[ -z "$LIST_CONTENEUR"  ]]
        then
            ciPrintMsg "*********************************************"
            ciMonitor gen_conteneurs
            RETOUR="$?"
            if [[ "$RETOUR" != "0" ]]
            then
                return "$RETOUR"
            fi
            ciPrintMsg "*********************************************"
            lxc-status
            RETOUR="$?"

            ciPatchLxcConf

            ciSignalHack "Allow https in apt-cacher-ng configuration"
            echo "PassThroughPattern: ^(.*):443$" >> /etc/apt-cacher-ng/acng.conf
        else
            ciPrintMsg "*********************************************"
            ciPrintMsg "* Conteneurs déjà installé dans /opt/lxc ? "
            ciPrintMsg "*********************************************"
            lxc-status
            RETOUR="$?"
        fi

        if [ -f /etc/apt/sources.list.d/ubuntu-proposed.list ]
        then
            for c in $LIST_CONTENEUR
            do
                LXC_DEST_PATH="/opt/lxc/$c/rootfs/etc/apt/sources.list.d/ubuntu-proposed.list"
                if [ -f "${LXC_DEST_PATH}" ]
                then
                    ciPrintMsg "* source list ubuntu-proposed.list déjà présent"
                    # TODO: a voir update ?
                else
                    ciPrintMsg "* inject source list ubuntu-proposed.list dans ${LXC_DEST_PATH}"
                    /bin/cp -f /etc/apt/sources.list.d/ubuntu-proposed.list "${LXC_DEST_PATH}"
                fi
            done
        else
            ciPrintMsg "* source list ubuntu-proposed.list inexistant, pas de copie dans les conteneurs"
        fi

        return "$RETOUR"
    else
        ciPrintMsg "*********************************************"
        ciPrintMsg "* Pas de conteneurs pour ce module."
        ciPrintMsg "*********************************************"
        return 0
    fi
}
export -f ciGenConteneur


#########################################################################################################
#
# monitor la commande Query-Auto
#
#########################################################################################################
function ciQueryAuto()
{
    ciSetHttpProxy
    ciPrintMsgMachine "Query-Auto $*"
    ciMonitor query_auto "$*"
    RETOUR=$?
    return "$RETOUR"
}
export -f ciQueryAuto

#########################################################################################################
#
# monitor la commande Maj-Auto
#
#########################################################################################################
function ciMajAutoSansTest()
{
    ciSetHttpProxy

    if [ "$VM_IS_UBUNTU" == "1" ]
    then
       ciPrintMsgMachine "dpkg --configure -a"

        dpkg --configure -a
        RETOUR=$?
        if [ "$RETOUR" -ne 0 ]
        then
            ciSignalAttention "************************************************************"
            ciPrintMsgMachine "Cette erreur peut avoir cassée l'image,si elle est en mode persistant !"
            ciSignalAttention "************************************************************"
            ciSignalAlerte "Erreur majauto, l'image est 'cassée' si la maj est en mode persistante !"
        fi
    fi

    ciWaitTestHttp "http://ftp.crihan.fr/ubuntu/dists" 2
    ciWaitTestHttp "http://eole.ac-dijon.fr/ubuntu/dists" 2
    ciWaitTestHttp "http://test-eole.ac-dijon.fr/ubuntu/dists" 2

    ciPrintMsgMachine "Maj-Auto $VM_MAJAUTO"
    ciMonitor maj_auto
    RETOUR=$?
    return "$RETOUR"
}
export -f ciMajAutoSansTest

#########################################################################################################
#
# monitor la commande Maj-Auto
#
#########################################################################################################
function ciMajAuto()
{
    if [[ "DEV" != "$VM_MAJAUTO" ]]
    then
        if ciEstCeQueLImageEstAJour
        then
            ciPrintMsgMachine "Image à jour: je ne fais rien"
            return 0
        fi
    else
        ciPrintMsgMachine "ciMajAuto : à mettre à jour car MAJAUTO = DEV"
    fi

    ciMajAutoSansTest
    return "$?"
}
export -f ciMajAuto


#########################################################################################################
#
# Execute Maj-Auto si Besoin + reconfigure
#
#########################################################################################################
function ciMajAutoEtReconfigure()
{
    ciPrintMsgMachine "ciMajAutoEtReconfigure"
    if ciEstCeQueLImageEstAJour
    then
        ciPrintMsgMachine "ciMajAutoEtReconfigure : Image à jour; je ne fais rien"
    else
        ciPrintMsgMachine "ciMajAutoEtReconfigure : Image non à jour; Maj-Auto + reconfigure"

        ciPrintMsgMachine "Maj-Auto $VM_MAJAUTO"
        ciMonitor maj_auto
        ciCheckExitCode $? "maj auto"

        ciMonitor reconfigure
        ciCheckExitCode $? "reconfigure"
    fi
}
export -f ciMajAutoEtReconfigure

#########################################################################################################
#
# ciEstCeQueLImageEstAJour()
#
#########################################################################################################
function ciEstCeQueLImageEstAJour()
{
    local limite
    local diff
    local maintenant
    local date_a_tester
    local date_trigger

    if ciGetContextDaily
    then
        if [[ "$DAILY_MAJAUTO" != "$VM_MAJAUTO" ]]
        then
            ciPrintMsgMachine "ciEstCeQueLImageEstAJour : à mettre à jour car $DAILY_MAJAUTO != $VM_MAJAUTO"
            return 1
        fi

        maintenant=$(date '+%s')
        FICHIER_TRIGGER_VERSION="$VM_DIR_EOLE_CI_TEST/depots/${VM_VERSIONMAJEUR}.last"
        if [ -f "${FICHIER_TRIGGER_VERSION}" ]
        then
            date_trigger=$(date -r "${FICHIER_TRIGGER_VERSION}" '+%Y-%m-%d %H:%M:%S')
            ciPrintMsgMachine "${FICHIER_TRIGGER_VERSION} : dernière maj = $date_trigger"
            date_a_tester=$(date -r "${FICHIER_TRIGGER_VERSION}" '+%s')
            limite=1000
        else
            date_a_tester="$maintenant"
            limite=70000
        fi

        ciPrintDebug "ciEstCeQueLImageEstAJour : date DAILY_DATE = ${DAILY_DATE}"
        ciPrintDebug "ciEstCeQueLImageEstAJour : date_a_tester    = $date_a_tester"
        ciPrintDebug "ciEstCeQueLImageEstAJour : DAILY_DATEUPDATE = $DAILY_DATEUPDATE"
        diff=$(( date_a_tester - DAILY_DATEUPDATE))
        ciPrintDebug "ciEstCeQueLImageEstAJour : diff             = $diff"
        diff_texte=$(ciAfficheDuree $diff)
        if [[ $diff -gt $limite ]];
        then
            ciPrintMsgMachine "ciEstCeQueLImageEstAJour : $diff_texte, Différence supérieure à $limite secondes, à mettre à jour"
            return 1
        else
            ciPrintMsgMachine "ciEstCeQueLImageEstAJour : $diff_texte, Différence inférieure à $limite secondes : pas besoin de mise à jour !!! "
            return 0
        fi
    else
        ciPrintMsgMachine "ciEstCeQueLImageEstAJour : context inconnu donc à mettre à jour"
        return 1
    fi
}
export -f ciEstCeQueLImageEstAJour

#########################################################################################################
#
# Patch /etc/init/failsafe.conf
#
#########################################################################################################
function ciPatchFailsafeConf()
{
    ciPrintMsgMachine "ciPatchFailsafeConf"
    [ -f /etc/init/failsafe.conf ] && sed -e 's/sleep 40/sleep 1/' -e 's/sleep 59/sleep 1/' -i /etc/init/failsafe.conf
}
export -f ciPatchFailsafeConf

#########################################################################################################
#
# Patch /etc/init/lxc.conf
#
#########################################################################################################
function ciPatchLxcConf()
{
    if ciVersionMajeurApres "2.5.1"
    then
        ciPrintMsgMachine "ciPatchLxcConf : pas de patch à partir de 2.5.2"
        return 0
    fi

    ciPrintMsgMachine "ciPatchLxcConf"
    if [ -f /etc/init/lxc.conf ]
    then
        grep "started cgmanager" /etc/init/lxc.conf
        if [ "$?" -eq 1 ]
        then
            ciPrintMsgMachine "Patch /etc/init/lxc.conf "
            sed -e 's/start on runlevel \[2345\]/start on runlevel [2345] and started cgmanager/' -e 's/sleep 59/sleep 1/' -i /etc/init/lxc.conf

            ciPrintMsgMachine "Check apres patch /etc/init/lxc.conf "
            grep "started cgmanager" /etc/init/lxc.conf
        else
            ciPrintMsgMachine "Déjà patché"
        fi
    fi
    return 0
}
export -f ciPatchLxcConf

#########################################################################################################
#
# ciStopMysql
#
#########################################################################################################
function ciStopMysql()
{
    #ciSignalAttention "plus d'arret de 'mysql.service'"
    ciPrintMsgMachine "*************************"
    ciPrintMsgMachine "mysqld --print-defaults"
    mysqld --print-defaults

    ciPrintMsgMachine "*************************"
    cat /etc/mysql/my.cnf
    ciPrintMsgMachine "*************************"
    cat /etc/mysql/mysql.conf.d/*
    ciPrintMsgMachine "*************************"
    cat /etc/mysql/conf.d/*
    ciPrintMsgMachine "*************************"
    cat /var/log/mysql/error.log

    ciPrintMsgMachine "*************************"
    ciPrintMsgMachine "STATUS ENGINE AVANT ARRET"
    mysql -N --raw <<EOF
show variables like '%log%';
SHOW ENGINE INNODB STATUS;
SHOW ENGINE INNODB MUTEX;
SHOW ENGINE PERFORMANCE_SCHEMA STATUS ;
SHOW FULL PROCESSLIST;
EOF


    ciPrintMsgMachine "*************************"
    ciPrintMsgMachine "SET innodb_fast_shutdown=2"
    mysql -N --raw <<EOF
SET GLOBAL innodb_fast_shutdown=2;
EOF

    ls -lR /var/lib/mysql/ >/tmp/avant

    ciSignalAttention "Arret 'mysql.service' manuel"
    systemctl stop mysql.service

    journalctl --no-pager -xe -u mysql.service >"$VM_DIR/journalctl-stop-mysql.log"

    ciPrintMsgMachine "*************************"
    ls -lR /var/lib/mysql/ >/tmp/apres
    diff --side-by-side --width=200 --ignore-case --ignore-tab-expansion --ignore-trailing-space --ignore-space-change --ignore-all-space --ignore-blank-lines -d /tmp/avant /tmp/apres
}
export -f ciStopMysql

#########################################################################################################
#
# get Envole Version
#
#########################################################################################################
function ciGetEnvoleVersion()
{
    ENVOLE=9
    if ciVersionMajeurAvant "2.5.2"
    then
        ENVOLE=4
    elif ciVersionMajeurAvant "2.6.1"
    then
        ENVOLE=5
    elif ciVersionMajeurAvant "2.7.1"
    then
        ENVOLE=6
    elif ciVersionMajeurAvant "2.8.0"
    then
        ENVOLE=7
    elif ciVersionMajeurAvant "2.9.0"
    then
        ENVOLE=8
    fi
    export ENVOLE
}
export -f ciGetEnvoleVersion

#########################################################################################################
#
# get Eole Version
#
#########################################################################################################
function ciGetEoleVersion()
{
    # shellcheck disable=SC2206
    VM_VERSIONMAJEUR_ARRAY=(${VM_VERSIONMAJEUR//\./ })
    VM_VERSION_EOLE="${VM_VERSIONMAJEUR_ARRAY[0]}.${VM_VERSIONMAJEUR_ARRAY[1]}"
    export VM_VERSION_EOLE
}
export -f ciGetEoleVersion

#########################################################################################################
#
# Update Daily
#
#########################################################################################################
function ciUpdateDaily()
{
    # rien, BUILD_DAILY, FOR_TEST
    if [ -n "$1" ]
    then
        ORIGINE_UPDATE=$1
    else
        ORIGINE_UPDATE=FOR_TEST
    fi
    ciPrintMsgMachine "ciUpdateDaily $ORIGINE_UPDATE"

    if [ ! -f "/root/.eole-ci-tests.freshinstall" ]
    then
        if [ -f "$VM_DIR/.eole-ci-tests.freshinstall" ]
        then
            ciSignalHack "Inject .eole-ci-tests.freshinstall"
            /bin/cp "$VM_DIR/.eole-ci-tests.freshinstall" "/root/.eole-ci-tests.freshinstall"
        fi
    fi

    # si la STABLE existe --> propose, sinon pas de proposed
    if ciVersionMajeurAvant "2.8.2"
    then
        if [ "$VM_IS_UBUNTU" == "1" ]
        then
            if [ ! -f /etc/apt/sources.list.d/ubuntu-proposed.list ]
            then
                ciPrintMsgMachine "Activation 'proposed-update' !"
                echo "deb http://test-eole.ac-dijon.fr/ubuntu $(lsb_release -s -c)-proposed main universe multiverse restricted"  > /etc/apt/sources.list.d/ubuntu-proposed.list
                cat /etc/apt/sources.list.d/ubuntu-proposed.list
                ORIGINE_UPDATE="FORCE_UPDATE"
            else
                ciPrintMsgMachine "'proposed-update' déjà actif!"
            fi

        fi
    else
        if [ -f /etc/apt/sources.list.d/ubuntu-proposed.list ]
        then
            ciPrintMsgMachine "DESACTIVATION 'proposed-update' !"
            /bin/rm -f /etc/apt/sources.list.d/ubuntu-proposed.list
            ORIGINE_UPDATE="FORCE_UPDATE"
        fi

#        if [[ "$VM_MODULE" == "scribe" ]] || [[ "$VM_MODULE" == "horus" ]]
#        then
#            bash "$VM_DIR_EOLE_CI_TEST/scripts/install-sympa.sh"
#        fi
    fi
    if [ -f "/etc/apt/sources.list.d/envole.list" ]
    then
        ciPrintMsgMachine "Suppression 'envole.list' s'il existe ! "
        # est ce que 'envole' apparait dans le sources.list ==> si oui ==> enlever le envole.list
        if grep -q envole /etc/apt/sources.list
        then
            ciPrintMsgMachine "rm /etc/apt/sources.list.d/envole.list"
            /bin/rm -f /etc/apt/sources.list.d/envole.list
            ORIGINE_UPDATE="FORCE_UPDATE"
        fi
    fi

    if [ "$ORIGINE_UPDATE" == "FOR_TEST" ]
    then
        if ciEstCeQueLImageEstAJour
        then
            ciPrintMsgMachine "Image à jour: je ne fais rien"
            return 0
        fi
    fi

    ciSetHttpProxy

    if ciVersionMajeurAvant "2.7.0"
    then
        if [ "$VM_IS_UBUNTU" == "1" ]
        then
            ciSignalHack "PB trousseau GPG cf. https://dev-eole.ac-dijon.fr/news/433 !"
            wget wget http://eole.ac-dijon.fr/eole/pool/main/e/eole-keyring/eole-archive-keyring_2022.34.19.1-1_all.deb -O /tmp/eole-archive-keyring_2022.34.19.1-1_all.deb
            dpkg -i /tmp/eole-archive-keyring_2022.34.19.1-1_all.deb
        fi
    fi

    ciPrintMsgMachine "liste des noyaux"
    if [ "$VM_IS_UBUNTU" == "1" ]
    then
        ls -l /boot/vmlinuz-*
    fi

    ciPrintMsgMachine "* espaces disponibles"
    if [ "$VM_IS_UBUNTU" == "1" ]
    then
        df -H -T --exclude-type=squashfs --exclude-type=tmpfs --exclude-type=devtmpfs --exclude-type=iso9660 --exclude-type=9p
    fi

    if [ "$FRESHINSTALL_MODULE" == "esbl" ]
    then
        if ciVersionMajeurEgal "2.5.1" || ciVersionMajeurEgal "2.5.2"
        then
            ciSignalHack "CreoleCat -t mysqld.apparmor.conf.esbl !!!! "
            CreoleCat -t mysqld.apparmor.conf.esbl
        else
            ciSignalHack "pas la version 2.5.1 ou 2.5.2 (CreoleCat -t mysqld.apparmor.conf.esbl ) "
        fi
    fi

    ciMajAutoSansTest
    RETOUR="$?"
    [[ "$RETOUR" -eq 0 ]] || return "$RETOUR"

    ciAfficheContenuFichier "/etc/apt/sources.list"
    for f in /etc/apt/sources.list.d/*
    do
        ciAfficheContenuFichier "$f"
    done

#    if ciVersionMajeurEgal "2.7.2"
#    then
#       if [ "$VM_MODULE" == "seth" ] || [ "$FRESHINSTALL_MODULE" == "seth" ]
#           then
#           if ! grep -q "4.11" /etc/apt/sources.list.d/seth-samba.list
#               then
#               ciSignalHack "Activation 'samba-4.11' sur Seth 2.7.2 !"
#                   echo "deb [ arch=amd64 ] http://test-eole.ac-dijon.fr/samba samba-4.11 main"  > /etc/apt/sources.list.d/seth-samba.list
#                   cat /etc/apt/sources.list.d/seth-samba.list
#                   apt-get update
#                   apt-get upgrade -y
#               else
#               ciSignalHack " 'samba-4.11' sur Seth 2.7.2 déjà actif !"
#               fi
#               ciSignalHack " force bascule en DEV !"
#           ciMonitor maj_auto_dev
#           fi
#    fi

    ciGenConteneur
    RETOUR="$?"
    [[ "$RETOUR" -eq 0 ]] || return "$RETOUR"

    if [ -n "$FRESHINSTALL_MODULE" ]
    then
        SCRIPT_ANNEXE="$VM_DIR_EOLE_CI_TEST/module/UpdateDaily-$FRESHINSTALL_MODULE.sh"
        if [ -f "$SCRIPT_ANNEXE" ]
        then
            ciPrintMsgMachine "Execution $SCRIPT_ANNEXE "
            bash "$SCRIPT_ANNEXE"
        else
            ciPrintMsgMachine "Pas de fichier startup '$SCRIPT_ANNEXE' "
        fi
    fi

    # HACK pour manu !
    if ciVersionMajeurEgal "2.5.1"
    then
        if [ -f "$VM_DIR_EOLE_CI_TEST/scripts/service/creoled" ]
        then
            ciSignalHack "Injection creoled 2.5.1"
            /bin/cp "$VM_DIR_EOLE_CI_TEST/scripts/service/creoled" /etc/init.d/creoled
        else
            ciSignalHack "Injection creoled impossible (manque fichier)"
        fi
    fi

    if command -v hwe-support-status >/dev/null 2>&1
    then
        ciPrintMsgMachine "Test CVE Noyau"
        hwe-support-status
        echo "$?"
    else
        ciPrintMsgMachine "Pas de Test CVE Noyau, car pas de commande 'hwe-support-status'"
    fi

    ciPrintMsgMachine "autoremove pour les anciens noyaux"
    apt-get -y --purge autoremove

    if command -v updatedb
    then
        # désactive le locate sur /mnt/eole-ci-test !
        sed -i 's#PRUNEFS="NFS#PRUNEFS="9p NFS#' /etc/updatedb.conf

        ciPrintMsgMachine "* Execute updatedb"
        updatedb
    fi

    if ! command -v /usr/bin/shellcheck
    then
        ciPrintMsgMachine "* install shellcheck"
        apt-get install shellcheck -y >/dev/null 2>&1
    fi

    ciPrintMsgMachine "Tag l'Image Daily"
    maintenant=$(date '+%s')
    jour="$(date +'%Y-%m-%d %R')"
    {
      echo DAILY_CONTAINER="$VM_CONTAINER";
      echo DAILY_DATEUPDATE="$maintenant";
      echo DAILY_DATE=\'"$jour"\';
      echo DAILY_MAJAUTO="$VM_MAJAUTO";
    } >/root/.eole-ci-tests.daily
    cat /root/.eole-ci-tests.daily
    # shellcheck disable=SC1091
    source /root/.eole-ci-tests.daily

    if ciVersionMajeurEgal "2.6.0" && [ "$ORIGINE_UPDATE" == "BUILD_DAILY" ] && [ -d /var/lib/mysql ]
    then
        ciSignalAttention "Arret 'mysql.service' manuel"
        ciStopMysql >"$VM_DIR/stop_mysql.log" 2>&1
    fi

    if [ "$ORIGINE_UPDATE" == "BUILD_DAILY" ]
    then
        ciPrintConsole "Check Update Service"
        bash "$VM_DIR_EOLE_CI_TEST/scripts/post-install/CheckUpdateService.sh"
    fi

    ciPrintConsole "Trim disk"
    fstrim /

    ciPrintConsole "ciUpdateDaily $VM_MAJAUTO : OK"
    return 0
}
export -f ciUpdateDaily

#########################################################################################################
#
# Execute Diff
#
#########################################################################################################
function ciDiff()
{
    if ciVersionMajeurEgal "2.3"
    then
        diff -y -i -E -b -w -B -d "$1" "$2"
    else
        # --width=200
        diff --side-by-side --ignore-case --ignore-tab-expansion --ignore-trailing-space --ignore-space-change --ignore-all-space --ignore-blank-lines -d "$1" "$2"
    fi
}
export -f ciDiff

#########################################################################################################
#
# ciCheckDiffFichierReference <pathFichierATester> <lieu> <nomFichier> <mskOk< <msgNok>
#
# lieu = PATH | CONFIGURATION
#########################################################################################################
function ciCheckDiffFichierReference()
{
    local REFERENCE_FILE
    local FICHIER_A_TESTER
    local LIEU
    local FILENAME
    local RESULT
    local MSG_OK
    local MSG_NOK
    local SIGNAL_ERROR
    local REFERENCE_FILE_DERNIER
    local REFERENCE_FILE_DATE
    local UPDATE_REFERENCE_FILE

    FICHIER_A_TESTER="${1}"
    if [ -z "$1" ]
    then
        ciPrintMsgMachine "ciCheckDiffFichierReference : manque le path du fichier à tester"
        return 1
    fi
    LIEU="${2}"
    if [ -z "$2" ]
    then
        ciPrintMsgMachine "ciCheckDiffFichierReference : manque l'endroit ou le fichier de référence est enregistré"
        return 1
    fi
    FILENAME="${3}"
    if [ -z "$3" ]
    then
        ciPrintMsgMachine "ciCheckDiffFichierReference : manque le nom du fichier de référence"
        return 1
    fi
    MSG_OK="${4}"
    if [ -z "$4" ]
    then
        MSG_OK="Fichiers '${FILENAME}' identiques"
    fi
    MSG_NOK="${5}"
    if [ -z "$5" ]
    then
        MSG_NOK="Fichiers '${FILENAME}' différents"
    fi
    SIGNAL_ERROR="${6}"
    if [ -z "$6" ]
    then
        SIGNAL_ERROR="OUI"
    fi
    UPDATE_REFERENCE_FILE="${7}"
    if [ -z "$7" ]
    then
        UPDATE_REFERENCE_FILE="OUI"
    fi

    case "$LIEU" in
        PATH)
            REFERENCE_FILE="${FILENAME}"
            FILENAME="$(basename "${FILENAME}")"
            ;;

        CONFIGURATION)
            ciGetDirConfiguration
            REFERENCE_FILE="$DIR_CONFIGURATION/${FILENAME}"
            ;;

        *)
            ciPrintMsgMachine "ciCheckDiffFichierReference : lieu $LIEU inconnu !"
            return 1
            ;;
    esac

    if [[ ! -f "$REFERENCE_FILE" ]]
    then
       ciPrintMsg "1ere fois que la commande est lancée. sauvegarde et pas d'erreur"
       ciPrintMsg "Le fichier de référence est $REFERENCE_FILE"
       /bin/cp "$FICHIER_A_TESTER" "$REFERENCE_FILE"
       return 0
    else
       ciPrintMsg "Le fichier de référence est $REFERENCE_FILE"
       ciDiff "$FICHIER_A_TESTER" "$REFERENCE_FILE" >"$FICHIER_A_TESTER.diff"
       RESULT="$?"
       if [[ "$RESULT" == "0" ]]
       then
           ciPrintMsg "${MSG_OK}"
           return 0
       else
           ciGrepDiff "$FICHIER_A_TESTER.diff"
           ciPrintMsg "< nouvelle par rapport au fichier de référence, > supprimée par rapport au fichier de référence, | changée par rapport au fichier de référence"
           REFERENCE_FILE_DERNIER="${REFERENCE_FILE}.dernier"

           if  [ "$SIGNAL_ERROR" == NON ]
           then
               ciSignalWarning "${MSG_NOK}"
           else
               if [[ "$VM_MAJAUTO" = "DEV" ]]
               then
                   ciSignalHack "${MSG_NOK}, mais en MODE DEV ignore !"
                   ciPrintMsg "Sauvegarde nouveau dans : $REFERENCE_FILE_DERNIER"
                   /bin/cp "$FICHIER_A_TESTER" "$REFERENCE_FILE_DERNIER"
               else
                   ciSignalAlerte "${MSG_NOK}"
               fi
           fi

           RESULT="0"
           if [[ ! -f "$REFERENCE_FILE_DERNIER" ]]
           then
               RESULT="1"
           else
               ciDiff "$FICHIER_A_TESTER" "$REFERENCE_FILE_DERNIER" >/dev/null
               RESULT="$?"
           fi

           if [ "$RESULT" == "1" ]
           then
               REFERENCE_FILE_DATE=${REFERENCE_FILE}.$(date "+%Y-%m-%d_%H:%M:%S")
               if [ "$UPDATE_REFERENCE_FILE" == NON ]
               then
                   ciPrintMsg "Sauvegarde désactivée !"
               else
                   ciPrintMsg "Sauvegarde nouveau dans : $REFERENCE_FILE_DERNIER"
                   /bin/cp "$FICHIER_A_TESTER" "$REFERENCE_FILE_DERNIER"
               fi
               ciPrintMsg "Sauvegarde nouveau dans historique : $REFERENCE_FILE_DATE"
               /bin/cp  "$FICHIER_A_TESTER" "$REFERENCE_FILE_DATE"
           else
               ciPrintMsg "La derniere sauvegarde est dans : $REFERENCE_FILE_DERNIER"
           fi
           return 1
       fi
    fi
}
export -f ciCheckDiffFichierReference

#########################################################################################################
#
# Execute GrepDiff
#
#########################################################################################################
function ciGrepDiff()
{
    # Normally the exit status is 0 if a line is selected, 1 if no lines were selected, and 2 if an error occurred.
    # However, if the -q or --quiet or --silent option is used and a line is selected, the exit status is 0 even if an error occurred.
    # Other grep implementations may exit with status greater than 2 on error.
    if grep --extended-regexp "[<|>]" "$1" ;
    then
        return 0
    else
        return 1
    fi
}
export -f ciGrepDiff

#########################################################################################################
#
# ciGenConfigSave
# load and save the configuration to fix freezable variables
#
#########################################################################################################
function ciGenConfigSave()
{
    if ciVersionMajeurApres "3."
    then
        ciPrintMsgMachine "pas de gen_config_save pour EOLE3"
        return 0
    fi
    ciPrintMsgMachine "Simulate a GenConfig load/save of the configuration"
    if ciVersionMajeurAPartirDe "2.8."
    then
        python3 -u "$VM_DIR_EOLE_CI_TEST/scripts/gen_config_save3" >/tmp/gen_config_save 2>/tmp/gen_config_save
        CDU="$?"
    else
        python -u "$VM_DIR_EOLE_CI_TEST/scripts/gen_config_save" >/tmp/gen_config_save 2>/tmp/gen_config_save
        CDU="$?"
    fi
    cat /tmp/gen_config_save
    if [ "$CDU" == "1" ]
    then
        if [ "$VM_IS_FREEBSD" == "1" ]
        then
            cat /tmp/gen_config_save >>/dev/console
        else
            cat /tmp/gen_config_save >>/dev/tty8
        fi
    fi
    return "$CDU"
}
export -f ciGenConfigSave

#########################################################################################################
#
# ciConfigurationEole($@)
# point entree pour la configuration du module en mode CI (sans interactivité)
#
#########################################################################################################
function ciConfigurationEole()
{
    if [ -n "$1" ]
    then
        CONF_METHODE="$1"
        if [ -n "$2" ]
        then
            CONFIGURATION=$2
        fi
    fi

    ciPrintDebug "ConfigurationEole $CONF_METHODE $CONFIGURATION"
    case $CONF_METHODE in
        minimale)
            # pas de maj-auto ici !
            ciConfigurationMinimale
            ;;

        zephir)
            ciMajAuto
            ciCheckExitCode $? "ciConfigurationEole: ciMajAuto"

            ciCheckCreoled

            ciGetConfigurationFromZephir
            ciCheckExitCode $? "ciConfigurationEole: ciGetConfigurationFromZephir"

            # obligatorie car enregistrement zephir repositionnne les sources list !
            ciMajAutoSansTest
            ciCheckExitCode $? "ciConfigurationEole: ciMajAutoSansTest"

            ciInstance
            ciCheckExitCode $? "ciConfigurationEole: ciInstance"

            ;;

        restauration)
            ciMajAuto
            ciCheckExitCode $? "ciConfigurationEole: ciMajAuto"

            ciRestaureDepuisConfiguration
            ciCheckExitCode $? "ciConfigurationEole: ciRestaureDepuisConfiguration"

            ciInstance
            ciCheckExitCode $? "ciConfigurationEole: ciInstance"

            ;;

        getbackup)
            ciGetBackup
            ciCheckExitCode $? "ciConfigurationEole: ciGetBackup"
            ;;

        bacula)
            ciCopieConfigEol
            ciCheckExitCode $? "ciConfigurationEole: ciCopieConfigEol"

            ciMajAuto
            ciCheckExitCode $? "ciConfigurationEole: ciMajAuto"

            ciInstance
            ciCheckExitCode $? "ciConfigurationEole: ciInstance"

            ciBacculaRestaure
            ciCheckExitCode $? "ciConfigurationEole: ciBacculaRestaure"
            ;;

        configeol)
            # pas de maj-auto ici !
            ciCopieConfigEol
            ciCheckExitCode $? "ciConfigurationEole: ciCopieConfigEol"

            ciGenConfigSave
            ciCheckExitCode $? "ciConfigurationEole: ciGenConfigSave"
            ;;

        instance)
            ciCopieConfigEol
            ciCheckExitCode $? "ciConfigurationEole: ciCopieConfigEol"

            ciGenConfigSave
            ciCheckExitCode $? "ciConfigurationEole: ciGenConfigSave"

            ciMajAuto
            ciCheckExitCode $? "ciConfigurationEole: ciMajAuto"

            ciInstance
            ciCheckExitCode $? "ciConfigurationEole: ciInstance"
            ;;

        freshinstall)
            ciConfigurationMinimale
            ciCheckExitCode $? "ciConfigurationEole: ciConfigurationMinimale"
            ;;

        daily)
            ciConfigurationMinimale
            ciCheckExitCode $? "ciConfigurationEole: ciConfigurationMinimale"

            ciUpdateDaily
            ciCheckExitCode $? "ciConfigurationEole: ciUpdateDaily"
            ;;

        majauto)
            ciMajAuto
            ciCheckExitCode $? "ciConfigurationEole: ciMajAuto"
            ;;

        updateDaily)
            ciUpdateDaily FOR_TEST
            ciCheckExitCode $? "ciConfigurationEole: ciUpdateDaily FOR_TEST"
            ;;

        *)
            ciPrintErreurAndExit "Méthode inconnue '$CONF_METHODE' !"
            ;;
    esac
    return $?
}
export -f ciConfigurationEole

#########################################################################################################
#
# ciInstanceDefault
#
#########################################################################################################
function ciInstanceDefault()
{
    ciPrintDebug "ciInstanceDefault"
    ciConfigurationEole instance default
    RETOUR="$?"
    ciPrintDebug "ciInstanceDefault ==> $RETOUR"
    return "$RETOUR"
}
export -f ciInstanceDefault

############################################################################################
#
# ciStopDaemon : arret du daemon et demontage
#
############################################################################################
function ciStopDaemon()
{
    [ -f "$VM_DIR/daemon.running"               ] && /bin/rm -f "$VM_DIR/daemon.running"
    [ -f "$VM_DIR/daemon.start"                 ] && /bin/rm -f "$VM_DIR/daemon.start"
    [ -f "$VM_DIR/daemon.pid"                   ] && /bin/rm -f "$VM_DIR/daemon.pid"

    ciPrintMsg "nettoyage 'motd' et '/etc/issue'"
    ciRemoveMotd

    ciPrintMsg "Sauvegarde log EoleCiTests"
    [ -f /var/log/eole-ci-tests.log ] && /bin/cp /var/log/eole-ci-tests.log "$VM_DIR/eole-ci-tests.log"
    [ -f /var/log/upstart/EoleCiTestsContext.log ] && /bin/cp /var/log/upstart/EoleCiTestsContext.log "$VM_DIR/EoleCiTestsContextUpstart.log"
    [ -f /var/log/upstart/EoleCiTestsDaemon.log ] && /bin/cp /var/log/upstart/EoleCiTestsDaemon.log "$VM_DIR/EoleCiTestsDaemonUpstart.log"
    [ -f /var/log/EoleCiTestsContext.log ] && /bin/cp /var/log/EoleCiTestsContext.log "$VM_DIR/EoleCiTestsContext.log"
    [ -f /var/log/EoleCiTestsDaemon.log ] && /bin/cp /var/log/EoleCiTestsDaemon.log "$VM_DIR/EoleCiTestsDaemon.log"
    [ -f /tmp/creoled.log ] && /bin/cp /tmp/creoled.log "$VM_DIR/creoled_avec_trace.log"

    sync
    ciPrintMsg "Démontage /mnt/cdrom et $VM_DIR_EOLE_CI_TEST"
    # shellcheck disable=2164
    cd /
    umount /mnt/cdrom
    if ! umount "$VM_DIR_EOLE_CI_TEST"
    then
        lsof "$VM_DIR_EOLE_CI_TEST"
    fi
}
export -f ciStopDaemon

############################################################################################
#
# intercepteur Trap
#
############################################################################################
function ciStopDaemonTrap()
{
   ciPrintMsg "TRAP dans daemon_runner!"
   ciStopDaemon
   exit 1
}
export -f ciStopDaemonTrap

############################################################################################
#
# ciNotifyUtilisateur <titre> <message>
#
############################################################################################
function ciNotifyUtilisateur()
{
    ciPrintConsole "$2"
    if [ -n "$IP_UTILISATEUR" ]
    then
        if [ -d "$DIR_OUTPUT_OWNER/gateway/todo" ]
        then
            MSG="$DIR_OUTPUT_OWNER/gateway/todo/${VM_MACHINE}-$(date +%s).msg"
            printf '%s\n%s' "$1" "$2" >"$MSG"
        else
            perl -w "$VM_DIR_EOLE_CI_TEST/scripts/send-notify-network.pl" "$IP_UTILISATEUR" "$1" "$2"
        fi
    fi
    return 0
}
export -f ciNotifyUtilisateur

############################################################################################
#
# ping ip sur eth
# $1 = ip
# $2 = eth
############################################################################################
function ciPingHost()
{
    local ADRESSE_TO_PING
    local NIC_TO_USE
    local CHAINE_ATTENDUE
    local CHAINE_ATTENDUE1

    ADRESSE_TO_PING="${1}"
    NIC_TO_USE="${2}"
    RESULT_PING="1"
    CHAINE_ATTENDUE="?"
    CHAINE_ATTENDUE1="?"

    if [ -z "${NIC_TO_USE}" ]
    then
        NIC_TO_USE="${VM_INTERFACE0_NAME}"
    fi

    if [ "$VM_IS_UBUNTU" == "1" ]
    then
        ping -W 1 -c 5 "${ADRESSE_TO_PING}" -I "${NIC_TO_USE}" >/tmp/ping
        RESULT_PING="$?"
        CHAINE_ATTENDUE=" 5 received"
        CHAINE_ATTENDUE1=" 5 reçu"
    fi
    if [ "$VM_IS_FREEBSD" == "1" ]
    then
        ping -W 1 -c 1 "${ADRESSE_TO_PING}" >/tmp/ping
        RESULT_PING="$?"
        CHAINE_ATTENDUE="1 packets received"
        CHAINE_ATTENDUE1=" 1 packet reçu"
    fi

    if grep -q "$CHAINE_ATTENDUE" /tmp/ping
    then
        ciPrintMsgMachine "ciPingHost ${NIC_TO_USE} => ${ADRESSE_TO_PING} ping=$RESULT_PING ==> OK (exit 0)"
        return 0
    fi
    if grep -q "$CHAINE_ATTENDUE1" /tmp/ping
    then
        ciPrintMsgMachine "ciPingHost ${NIC_TO_USE} => ${ADRESSE_TO_PING} ping=$RESULT_PING ==> OK (exit 0)"
        return 0
    fi
    [[ "$VM_DEBUG" -gt "1" ]] && cat /tmp/ping
    ciSignalAttention "ciPingHost ${NIC_TO_USE} => ${ADRESSE_TO_PING} ping=$RESULT_PING ==> K.O. (exit 1)"
    return 1
}
export -f ciPingHost

############################################################################################
#
# ciIsActiveService : check Status Service
#
############################################################################################
function ciIsActiveService()
{
    local SERVICE="$1"

    if command -v systemctl >/dev/null 2>/dev/null
    then
        if systemctl is-active "${SERVICE}" >/dev/null 2>&1
        then
            echo "active"
            return 0
        else
            echo "inactive"
            return 1
        fi
    else
        if service "${SERVICE}" status >/dev/null 2>&1
        then
            echo "active"
            return 0
        else
            echo "inactive"
            return 1
        fi
    fi
}
export -f ciIsActiveService

############################################################################################
#
# permets d'executer une commande dans le context session
# ne fonctionne qu'a la condition qu'une session ne soit ouverte !
#
############################################################################################
function ciRunInUserSession()
{
    ciPrintMsgMachine "ciRunInUserSession: $*"
    _display_id=":$(find /tmp/.X11-unix/* | sed 's#/tmp/.X11-unix/X##' | head -n 1)"
    _username=$(who | grep "\(${_display_id}\)" | awk '{print $1}')
    if [ -z "$_username" ]
    then
        ciPrintMsgMachine "pas de session utilisateur ouverte ... stop"
        return 1
    fi
    _user_id=$(id -u "$_username")
    _environment=("DISPLAY=$_display_id" "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$_user_id/bus")
    ciPrintMsgMachine "_environment=${_environment[*]}"
    sudo -Hu "$_username" env "${_environment[@]}" "$@"
}

export -f ciRunInUserSession

############################################################################################
#
# export complet gsettings + diff
# a executer dans la session user !!!
############################################################################################
function ciDiffGsettings()
{
    local GSETTINGS_CMD="sudo -Hu pcadmin env DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus gsettings "
    f=$(mktemp)
    for schema in $(${GSETTINGS_CMD} list-schemas | sort)
    do
        for key in $(${GSETTINGS_CMD} list-keys "$schema" | sort)
        do
            typ="$(${GSETTINGS_CMD} range "$schema" "$key" | tr "\n" " ")"
            value="$(${GSETTINGS_CMD} get "$schema" "$key" | tr "\n" " ")"
            echo "${schema[$key]}=${value} # ${typ}" >>"$f"
        done
    done
    diff "$f" "$HOME/export_gsettings"
    CDU="$?"
    if [ $CDU -ne 0 ]
    then
        echo "ciDiffGsettings: different"
        cp "$f" "$HOME/export_gsettings"
    else
        echo "ciDiffGsettings: égal"
    fi
}
export -f ciDiffGsettings

############################################################################################
#
# renome un PC Linux avec le pattern PC-<vmid>
#
############################################################################################
function ciRenamePcLinux()
{
    local NEW_NAME="pc-$VM_ID"

    if [ "$(hostname -s)" != "${NEW_NAME}" ]
    then
        if ciUtiliseSystemdNetplan
        then
            ciPrintMsgMachine "Inject ${NEW_NAME} -> hostnamectl "
            hostnamectl set-hostname "${NEW_NAME}"
        else
            ciPrintMsgMachine "Inject ${NEW_NAME} -> /etc/hostname"
            echo "${NEW_NAME}" >/etc/hostname
        fi
        if [ -f /var/lib/dhcp/dhclient.leases ]
        then
            # récupére domain-name sans quote ni ';' !
            DOMAIN_NAME="$(awk '/ domain-name / {gsub("\"",""); gsub(";","");print $3}' /var/lib/dhcp/dhclient.leases| tail -1)"
            FQDN="${NEW_NAME}.${DOMAIN_NAME}"
        else
            FQDN=""
        fi
        ciPrintMsgMachine "* Inject ${FQDN} ${NEW_NAME} -> /etc/hosts"
        sed -i "s/127.0.1.1\t.*/127.0.1.1\t${FQDN} ${NEW_NAME}/" /etc/hosts
        cat /etc/hosts

        ciPrintMsgMachine "* Restart avahi-daemon"
        systemctl restart avahi-daemon

    fi

    ciPrintMsgMachine "le PC a pour nom ${NEW_NAME} : $(hostname -f)"
    if ciUtiliseSystemdNetplan
    then
        hostnamectl
    fi

}
export -f ciRenamePcLinux

############################################################################################
#
# Gestion de la configuration 'PcLinux' si le module n'est pas instancié !
#
############################################################################################
function ciContextualizePcLinux()
{
    ciPrintMsgMachine "Debut ciContextualizePcLinux"

    ciGetNamesInterfaces

    #systemctl enable debug-shell.service
    ciPrintMsgMachine "OS $(lsb_release -ds)  Version=$(lsb_release -rs)"
    ciPrintMsgMachine "machine PcLinux ==> utilise le dhcp!"

    #ciAfficheContenuFichier /etc/machine-id

    if [ -d /etc/lightdm/lightdm.conf.d ]
    then
        if [  -f /etc/lightdm/lightdm.conf.d/12-autologin.conf ]
        then
            ciPrintMsgMachine "machine PcLinux ==> supprime 12-autologin.conf "
            /bin/rm -f /etc/lightdm/lightdm.conf.d/12-autologin.conf
        fi
    fi
#    if [ "$AGENT_JENKINS" == "oui" ]
#    then
#        # autlogin au boot !
#        cat >/etc/lightdm/lightdm.conf.d/12-autologin.conf <<EOF
#[SeatDefaults]
#autologin-user=pcadmin
#EOF
#    fi

    ciRenamePcLinux
    #snap list
    #snap remove ubuntu-mate-welcome
    #snap remove software-boutique
    #apt-get remove -y kerneloops
    #systemctl stop nslcd
    #systemctl disable nslcd

    #systemctl stop avahi-daemon
    #systemctl disable avahi-daemon

    #systemctl daemon-reload

    ciPrintMsgMachine "Fin ciContextualizePcLinux"
}
export -f ciContextualizePcLinux

############################################################################################
#
# Gestion de la configuration 'PcLinux' si le module n'est pas instancié !
#
############################################################################################
function ciConfigurationPcLinuxDconf()
{
    if command -v snap
    then
        snap list
        snap remove ubuntu-mate-welcome
        snap remove software-boutique
    fi
    apt-get remove -y kerneloops
    systemctl stop nslcd

    echo "user-db:user" >/home/pcadmin/db_profile
    if [ ! -f /home/pcadmin/old_settings ]
    then
        ciPrintMsg "ciConfigurationPcLinux : export dconf original"
        su pcadmin -c 'dconf dump / >/home/pcadmin/old_settings'
    else
        ciPrintMsg "ciConfigurationPcLinux : export dconf original existe déjà"
    fi

    ciPrintMsg "ciConfigurationPcLinux : application dconf"
    cat >/tmp/suppress-logout-restart-shutdown <<EOF
[apps/indicator-session]
suppress-logout-restart-shutdown=true
EOF
    su pcadmin -c 'DCONF_PROFILE=/run/user/1000/dconf dconf load / </tmp/suppress-logout-restart-shutdown'

    ciPrintMsg "ciConfigurationPcLinux : shutdown on poweroff event !"
    cat >/tmp/power-manager <<EOF
[org/mate/power-manager]
button-power='shutdown'
sleep-display-ac=0
EOF
    su pcadmin -c 'DCONF_PROFILE=/run/user/1000/dconf dconf load / </tmp/power-manager'

    ciPrintMsg "ciConfigurationPcLinux : session logout timeout 10s"
    cat >/tmp/mate-logout <<EOF
[org/mate/desktop/session]
logout-timeout=10
EOF
    su pcadmin -c 'DCONF_PROFILE=/run/user/1000/dconf dconf load / </tmp/mate-logout'

    ciPrintMsg "ciConfigurationPcLinux : linuxmint button power -> shutdown"
    cat >/tmp/mint-logout <<EOF
[org/cinnamon/settings-daemon/plugins/power]
button-power='shutdown'
EOF
    su pcadmin -c 'DCONF_PROFILE=/run/user/1000/dconf dconf load / </tmp/mint-logout'

    cat >/etc/acpi/events/power <<EOF
event=button/power
action=/etc/acpi/powerbtn.sh "%e"
EOF

    cp /usr/share/doc/acpid/examples/powerbtn.sh /etc/acpi/powerbtn.sh
    chmod a+x /etc/acpi/powerbtn.sh

    su pcadmin -c 'DCONF_PROFILE=/run/user/1000/dconf dconf update'

    # dans les tests, il ne faut pas poser de question, et aller vite
    #ciRunInUserSession gsettings set org.mate.power-manager button-power shutdown
    #ciRunInUserSession gsettings set org.mate.session logout-timeout 10
}
export -f ciConfigurationPcLinuxDconf

############################################################################################
#
# Gestion de sshd_config
#
############################################################################################
function ciCheckSSHDConfig()
{
    cat >/tmp/sshd_config <<EOF
PermitRootLogin yes
#ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
#AllowAgentForwarding yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem   sftp    /usr/lib/openssh/sftp-server
AddressFamily inet
EOF
    if diff /etc/ssh/sshd_config /tmp/sshd_config >/dev/null
    then
        ciPrintConsole "* /etc/ssh/sshd_config à corriger"

        cat /tmp/sshd_config >/etc/ssh/sshd_config

        SSH_ACTIVE=$(ciIsActiveService ssh)
        if [ "$SSH_ACTIVE" == "active" ]
        then
            ciPrintMsgMachine "Redémarrage SSH"
            systemctl restart ssh
        else
            ciPrintMsgMachine "pas de redémarrage SSH !"
        fi
    else
        ciPrintConsole "* /etc/ssh/sshd_config à jour"
    fi
}
export -f ciCheckSSHDConfig

############################################################################################
#
# Gestion des mots de passe root/pcadmin/eole
#
############################################################################################
function ciCheckMdpEole()
{
    if [ "$(lsb_release -rs)" == "22.04" ]
    then
        if grep 'minlen' /etc/pam.d/common-password
        then
            echo "minlen present dans /etc/pam.d/common-password"
        else
            echo "Inject minlen=4 dans /etc/pam.d/common-password"
            sed -i -e 's/pam_pwquality.so retry=3/pam_pwquality.so retry=3 minlen=4/' /etc/pam.d/common-password
        fi
        if grep 'minlen = 4' /etc/security/pwquality.conf 2>/dev/null
        then
            echo "minlen=4 present dans /etc/security/pwquality.conf"
        else
            echo "Inject minlen dans /etc/security/pwquality.conf"
            sed -i -e '/# minlen = 8/a minlen = 4' /etc/security/pwquality.conf 2>/dev/null
        fi
    fi

    if echo -e "eole\neole" | passwd pcadmin 2>/dev/null
    then
        echo "mdp pcadmin/eole OK"
    else
        echo -e "Eole12345!\nEole12345!" | passwd pcadmin
        echo "mdp pcadmin/Eole12345!"
    fi

    if echo -e "eole\neole" | passwd eole 2>/dev/null
    then
        echo "mdp eole/eole OK"
    else
        echo -e "Eole12345!\nEole12345!" | passwd eole
        echo "mdp eole/Eole12345!"
    fi

    if echo -e "eole\neole" | passwd root
    then
        echo "mdp root/eole OK"
    else
        echo -e "Eole12345!\nEole12345!" | passwd root
        echo "mdp root/Eole12345!"
    fi
}
export -f ciCheckMdpEole

############################################################################################
#
# Gestion de la configuration 'PcLinux' si le module n'est pas instancié !
#
############################################################################################
function ciConfigurationPcLinux()
{
    ciPrintMsgMachine "Debut ciConfigurationPcLinux"

    ciGetNamesInterfaces
	ciConfigurationMinimale

    if [ "$(lsb_release -rs)" == "22.04" ]
    then
        ciCheckMdpEole
        ciCheckSSHDConfig
    fi

    CURRENT_IP="$(ciGetCurrentIp)"
    if [[ "" == "$CURRENT_IP" ]]
    then
        if ! command -v dhclient
        then
           apt-get install -y isc-dhcp-client
        fi
    
        ciPrintMsgMachine "dhclient ${VM_INTERFACE0_NAME}"
        dhclient "${VM_INTERFACE0_NAME}"
    fi

    CURRENT_IP="$(ciGetCurrentIp)"
    if [[ "" == "$CURRENT_IP" ]]
    then
         ciDiagnoseNetwork
    fi

    GW_ACTUEL="$(ciGetGatewayIP)"
    if [ "$GW_ACTUEL" != "$VM_ETH0_GW" ] && [ "$GW_ACTUEL" != "192.168.0.1" ] && [ "$GW_ACTUEL" != "192.168.230.254" ] && [ "$GW_ACTUEL" != "" ]
    then
        ciPrintMsg "GW différente : $GW_ACTUEL, nettoye et force $VM_ETH0_GW"
        ciSetGatewayIP
    else
        ciPrintMsg "GW actuelle : $GW_ACTUEL OK, attendu: $VM_ETH0_GW"
    fi

    ciPrintMsg "** Test GW $GW_ACTUEL"
    ciPingHost "$GW_ACTUEL" "$VM_INTERFACE0_NAME"
    if [[ "$VM_NB_INTERFACE" = 2 ]]
    then
        ciPingHost "$GW_ACTUEL" "$VM_INTERFACE1_NAME"
    fi

    case "$VM_MACHINE" in
        etb1.pcprofs)
            #SERVER_LDAP=10.1.3.5
            SERVER_PROXY=10.1.2.1
            ;;

        etb1.pceleve)
            #SERVER_LDAP=10.1.3.5
            SERVER_PROXY=10.1.2.1
            ;;

        etb1.pcadmin)
            #SERVER_LDAP=10.1.1.5
            SERVER_PROXY=10.1.1.1
            ;;

        etb1.pcdmz)
            #SERVER_LDAP=10.1.3.5
            SERVER_PROXY=10.1.3.1
            ;;

        etb3.pcprofs)
            #SERVER_LDAP=10.3.2.1
            SERVER_PROXY=10.3.2.2
            ;;

        etb3.pceleve)
            #SERVER_LDAP=10.3.2.1
            SERVER_PROXY=10.3.2.2
            ;;

        aca.pc)
            ;;

        *)
            ciPrintMsg "ciConfigurationPcLinux : machine inconnue ! "
            return 1
            ;;
    esac

    if [ "$SERVER_PROXY" != "" ]
    then
        ciPrintMsg "ciConfigurationPcLinux : PROXY=$SERVER_PROXY"

        ciPrintMsg "ciConfigurationPcLinux : set proxy /etc/apt/apt.conf.d/proxy "
        echo "Acquire::http::Proxy \"http://admin:eole@$SERVER_PROXY:3128\";" >/etc/apt/apt.conf.d/proxy
        cat /etc/apt/apt.conf.d/proxy

        ciSignalAttention "ciSetHttpProxy, Injection 'http_proxy=http://admin:eole@$SERVER_PROXY:3128' "
        export http_proxy=http://admin:eole@$VM_ETH0_GW:3128
        export https_proxy=${http_proxy}
    else
        unset http_proxy
    fi
    ciTestHttp

    ciPrintMsgMachine "Liste des applications active"
    grep NoDisplay /etc/xdg/autostart/*.desktop

    mkdir -p /home/pcadmin/.config/autostart
    cat >/home/pcadmin/.config/autostart/org.gnome.DejaDup.Monitor.desktop <<EOF
[Desktop Entry]
Name=Backup Monitor
Hidden=true
EOF

    cat >/home/pcadmin/.config/autostart/mate-screensaver.desktop <<EOF
[Desktop Entry]
Name=Screensaver
Hidden=true
#X-MATE-Autostart-enabled=false
EOF

    ciPrintMsg "Fin ciConfigurationPcLinux"
}
export -f ciConfigurationPcLinux


############################################################################################
#
# Gestion de la configuration 'update' si le module n'est pas instancié !
#
############################################################################################
function ciContextualizeUpdate()
{
    ciPrintMsgMachine "Debut ciContextualizeUpdate"

    ciGetNamesInterfaces

    #systemctl enable debug-shell.service
    ciPrintMsgMachine "OS $(lsb_release -ds)  Version=$(lsb_release -rs)"
    ciPrintMsgMachine "machine Update ==> utilise le dhcp!"

    ciAfficheContenuFichier /etc/machine-id

    if [ "$(lsb_release -rs)" == "22.04" ]
    then
        ciCheckMdpEole
        ciCheckSSHDConfig
    else
        if ciUtiliseSystemdNetplan
        then
            ciPrintMsgMachine "Inject 01-netcfg avec 'dhcp-identifier: mac'"
            cat >/etc/netplan/01-netcfg.yaml <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    ${VM_INTERFACE0_NAME}:
      dhcp4: yes
      dhcp-identifier: mac
EOF

            chmod 600 /etc/netplan/01-netcfg.yaml
            
            ciPrintMsgMachine "netplan generate --debug"
            netplan generate --debug
        fi


    fi

    ciPrintMsgMachine "Fin ciContextualizeUpdate"
}
export -f ciContextualizeUpdate

############################################################################################
#
# Gestion de la configuration 'update' si le module n'est pas instancié !
#
############################################################################################
function ciConfigurationUpdate()
{
    ciPrintMsgMachine "Debut ciConfigurationUpdate"

    ciGetNamesInterfaces

    if command -v systemctl >/dev/null 2>/dev/null
    then
         ciPrintMsgMachine "systemctl is-active network.target : $(systemctl is-active network.target)"
         ciPrintMsgMachine "systemctl is-active network-online.target : $(systemctl is-active network-online.target)"
         ciPrintMsgMachine "systemctl is-system-running : $(systemctl is-system-running)"
    fi

    if ciUtiliseSystemdNetplan
    then
        ls -l /etc/netplan
        ciAfficheContenuFichier /etc/netplan/01-netcfg.yaml
        ciAfficheContenuFichier /etc/netplan/50-cloud-init.yaml
        ciAfficheContenuFichier /etc/systemd/resolved.conf
    else
        if command -v netplan >/dev/null 2>&1
        then
            ciAfficheContenuFichier /etc/netplan/01-netcfg.yaml
            ciAfficheContenuFichier /etc/netplan/50-cloud-init.yaml
            ciAfficheContenuFichier /etc/systemd/resolved.conf
            GW_ACTUEL="$(ciGetGatewayIP)"
            if [ "$GW_ACTUEL" == "" ]
            then
                ciPrintMsgMachine "netplan apply --debug"
                netplan apply --debug
            fi
        fi
    fi

    ciDisplayGatewayIp

    GW_ACTUEL="$(ciGetGatewayIP)"
    if [ "$GW_ACTUEL" != "192.168.0.1" ] && [ "$GW_ACTUEL" != "192.168.230.254" ] && [ "$GW_ACTUEL" != "" ]
    then
        ciPrintMsg "GW différente : $GW_ACTUEL, nettoye et force 192.168.0.1"
        ciSetGatewayIP "192.168.0.1"
    else
        ciPrintMsg "GW actuelle : $GW_ACTUEL OK"
    fi

    ciPrintMsg "** Test GW"
    ciPingHost 192.168.0.1 "$VM_INTERFACE0_NAME"
    if [[ "$VM_NB_INTERFACE" = 2 ]]
    then
        ciPingHost 192.168.0.1 "$VM_INTERFACE1_NAME"
    fi
    ciPrintMsgMachine "Fin ciConfigurationUpdate"
}
export -f ciConfigurationUpdate

############################################################################################
#
# Gestion de la contextualisation 'daily' si le module n'est pas instancié !
#
############################################################################################
function ciContextualizeDaily()
{
    ciPrintMsgMachine "Debut ciContextualizeDaily"

    #########################################################
    #
    # les Daily sont connectées sur Academie
    #
    # nous utilisons donc par défaut les information du DHCP
    #
    #########################################################

    ciGetNamesInterfaces

     if command -v systemctl >/dev/null 2>/dev/null
     then
         ciPrintDebug "systemctl is-active network.target : $(systemctl is-active network.target)"
         ciPrintDebug "systemctl is-active network-online.target : $(systemctl is-active network-online.target)"
         ciPrintDebug "systemctl is-system-running : $(systemctl is-system-running)"
    fi

    if ciVersionMajeurApres "2.6.2"
    then
        #ciAfficheContenuFichier /etc/machine-id

        if [ -f /etc/netplan/00-installer-config.yaml ]
        then
            ciPrintMsgMachine "ls -l /etc/netplan/"
            ls -l /etc/netplan/
            #ciAfficheContenuFichier /etc/netplan/01-netcfg.yaml

            ciPrintMsgMachine "netoyage /etc/netplan/00-installer-config.yaml"
            /bin/rm -f /etc/netplan/00-installer-config.yaml
        fi

        cat >/tmp/01-netcfg.yaml <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    ${VM_INTERFACE0_NAME}:
      dhcp4: yes
      dhcp-identifier: mac
EOF
        if diff /tmp/01-netcfg.yaml /etc/netplan/01-netcfg.yaml 2>/dev/null
        then
            ciPrintMsgMachine "01-netcfg ok, on ne fait rien !"
        else
            ciPrintMsgMachine "Inject 01-netcfg avec 'dhcp-identifier: mac'"
            cat </tmp/01-netcfg.yaml >/etc/netplan/01-netcfg.yaml
            chmod 600 /etc/netplan/01-netcfg.yaml
            
            ciPrintMsgMachine "netplan generate --debug"
            netplan generate --debug
        fi
    else
        ciPrintMsgMachine "avant 2.7, on ne fait rien !"
    fi

    ciPrintMsgMachine "Fin ciContextualizeDaily"
}
export -f ciContextualizeDaily

############################################################################################
#
# Gestion de la configuration 'daily' si le module n'est pas instancié !
#
############################################################################################
function ciConfigurationDaily()
{
    ciPrintMsgMachine "Debut ciConfigurationDaily"

    #########################################################
    #
    # les Daily sont connectées sur Academie
    #
    # nous utilisons donc par défaut les information du DHCP
    #
    #########################################################

    ciGetNamesInterfaces

    if command -v systemctl >/dev/null 2>/dev/null
    then
         ciPrintMsgMachine "systemctl is-active network.target : $(systemctl is-active network.target)"
         ciPrintMsgMachine "systemctl is-active network-online.target : $(systemctl is-active network-online.target)"
         ciPrintMsgMachine "systemctl is-system-running : $(systemctl is-system-running)"
    fi

    if ciVersionMajeurApres "2.6.2"
    then
        ciPrintMsgMachine "ls -l /etc/netplan/"
        ls -l /etc/netplan/
        ciAfficheContenuFichier /etc/netplan/00-installer-config.yaml
        ciAfficheContenuFichier /etc/netplan/01-netcfg.yaml
        ciAfficheContenuFichier /etc/netplan/50-cloud-init.yaml
    fi

    ciDisplayGatewayIp

    ciPingHost 192.168.0.1 "$VM_INTERFACE0_NAME"

    GW_ACTUEL="$(ciGetGatewayIP)"
    if [ "$GW_ACTUEL" != "192.168.0.1" ] && [ "$GW_ACTUEL" != "192.168.230.254" ] && [ "$GW_ACTUEL" != "" ]
    then
        ciPrintMsgMachine "GW différente : $GW_ACTUEL, nettoye et force 192.168.0.1"
        ciSetGatewayIP "192.168.0.1"
    else
        ciPrintMsgMachine "GW actuelle : $GW_ACTUEL OK"
    fi

    ciPrintMsg "Fin ciConfigurationDaily"
}
export -f ciConfigurationDaily

############################################################################################
#
# Gestion de la configuration 'daily' si le module n'est pas instancié !
#
############################################################################################
function ciConfigurationCloudInit()
{
    ciPrintMsgMachine "Debut ciConfigurationCloudInit"

    if ! grep OpenNebula /etc/cloud/cloud.cfg >/dev/null 2>&1
    then
        ciPrintMsgMachine "Injection opennebula dans /etc/cloud/cloud.cfg"
        cat >>/etc/cloud/cloud.cfg <<EOF

# work only with OpenNebula, use network based datasource,
# so that we can successfully resolve IPv4 based hostname
disable_ec2_metadata: True
datasource_list: ['OpenNebula']
datasource:
  OpenNebula:
    dsmode: net
EOF
    else
         ciPrintMsgMachine "Opennebula déjà dans /etc/cloud/cloud.cfg"
    fi

    ciPrintMsgMachine "Fin ciConfigurationCloudInit"
}
export -f ciConfigurationCloudInit


############################################################################################
#
# Gestion de la configuration automatique d'apres VM_METHODE
#
############################################################################################
function ciConfigureAutomatiqueAvecMethode()
{
    RETOUR="0"
    ciPrintMsg "Debut ciConfigureAutomatiqueAvecMethode"
    local DO_GEN_RPT
    DO_GEN_RPT=non
    case "$VM_METHODE" in
        testCharge)
            ciPrintMsg "ciConfigureAutomatiqueAvecMethode : TestCharge"
            ciConfigurationEole instance default
            RETOUR="$?"
            [[ "$RETOUR" -eq 0 ]] || return "$RETOUR"

            ciMonitor zephir_enregistrement_testcharge
            RETOUR="$?"
            [[ "$RETOUR" -eq 0 ]] || return "$RETOUR"

            ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "$VM_ONE-$VM_ID inscrit dans zephir"
            ;;

        instance)
            ciPrintConsole "ciConfigureAutomatiqueAvecMethode : Instance VM_CONFIGURATION=$VM_CONFIGURATION"
            if [ -z "$VM_CONFIGURATION" ]
            then
                ciConfigurationEole instance default
            else
                ciConfigurationEole instance "$VM_CONFIGURATION"
            fi
            RETOUR="$?"
            [[ "$RETOUR" -eq 0 ]] || return "$RETOUR"

            ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "$VM_ONE-$VM_ID instanciée"
            ;;

        fromubuntu)
            ciPrintConsole "ciConfigureAutomatiqueAvecMethode : Injection fromubuntu VM_MAJAUTO=$VM_MAJAUTO"
            ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "$VM_ONE-$VM_ID préparée pour EOLE"
            ;;

        sourceliste)
            ciPrintConsole "ciConfigureAutomatiqueAvecMethode : Injection sourceliste VM_MAJAUTO=$VM_MAJAUTO"
            ciInjectSourcesListSurUbuntu
            RETOUR="$?"
            [[ "$RETOUR" -eq 0 ]] || return "$RETOUR"

            ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "$VM_ONE-$VM_ID préparée pour EOLE"
            ;;

        cloudinit)
            ciPrintConsole "ciConfigureAutomatiqueAvecMethode : Activation cloudinit"
            ciConfigurationCloudInit
            RETOUR="$?"
            [[ "$RETOUR" -eq 0 ]] || return "$RETOUR"

            ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "$VM_ONE-$VM_ID préparée pour EOLE"
            ;;

        reconfigure)
            ;;

        up)
            ciPrintMsg "ciConfigureAutomatiqueAvecMethode : Methode $VM_METHODE"
            ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "Zephir2 rebuild + UP, wait ..."
            # zephir2
            cd /home/zephir || return 1
            docker-compose -f docker-compose.dev.yml down
            docker-compose -f docker-compose.dev.yml up -d
            docker ps
            ;;

        *)
            ciPrintMsg "ciConfigureAutomatiqueAvecMethode : Methode inconnue : $VM_METHODE"
            RETOUR="1"
            ;;
    esac
    ciPrintMsg "Fin ciConfigureAutomatiqueAvecMethode"
    return "$RETOUR"
}
export -f ciConfigureAutomatiqueAvecMethode

############################################################################################
# CYGWIN !
# Init ip
#
############################################################################################
function ciConfigureIp()
{
    REBOOT_NECESSAIRE=false

    ciPrintMsg "Autorise SSH sur le port 22 "
    netsh advfirewall firewall add rule name="SSH" action=allow protocol=TCP dir=in localport=22

    #net users root /add
    #net localgroup Administrateurs root /add
    #net users root /active:yes

    if [[ "$VM_ETH0_DHCP" = non ]]
    then
        netsh int ipv4 set address name="$VM_ETH0_NAME" source=static "$VM_ETH0_IP" mask=255.255.255.0 gateway="$VM_ETH0_GW" 1
        netsh int ipv4 set dns name="$VM_ETH0_NAME" source=static "$VM_ETH0_DNS" register=primary validate=no
    fi

    if [[ "$VM_ETH1_DHCP" = non ]]
    then
        netsh int ipv4 set address name="$VM_ETH1_NAME" source=static "$VM_ETH1_IP" mask=255.255.255.0 gateway="$VM_ETH1_GW" 1
        netsh int ipv4 set dns name="$VM_ETH1_NAME" source=static "$VM_ETH1_DNS" register=primary validate=no
    fi

    if [[ "$REBOOT_NECESSAIRE" = oui ]]
    then
         ciPrintMsg "Reboot nécessaire"
    fi

}
export -f ciConfigureIp

############################################################################################
#
# Init repertoire VirtFs
#
############################################################################################
function ciCreateDir()
{
    if [[ ! -d "$1" ]]
    then
        ciPrintMsg "ciCreateDir: $1"
        mkdir "$1"
        # dans le Virtfs, le owner est 'oneadmin' inconnu de la machine local
        # il faut donc autoriser les drotis 'others' !
        chmod 777 "$1"
    fi
}

export -f ciCreateDir
############################################################################################
#
# Init repertoire VirtFs
#
############################################################################################
function ciInitOutput()
{
    local BASE=$VM_DIR_EOLE_CI_TEST
    ciCreateDir "$BASE/"
    ciCreateDir "$BASE/status"
    ciCreateDir "$BASE/output"

    VM_DIR_OUTPUT="$BASE/output/$VM_OWNER"
    export VM_DIR_OUTPUT
    ciCreateDir "$VM_DIR_OUTPUT"

    VM_DIR="$VM_DIR_OUTPUT/$VM_ID"
    export VM_DIR
    ciCreateDir "$VM_DIR"

    VM_DIR_TODO="$VM_DIR/todo"
    export VM_DIR_TODO
    ciCreateDir "$VM_DIR_TODO"

    VM_DIR_RUNNING="$VM_DIR/running"
    export VM_DIR_RUNNING
    ciCreateDir "$VM_DIR_RUNNING"

    VM_DIR_DONE="$VM_DIR/done"

    export VM_DIR_DONE
    ciCreateDir "$VM_DIR_DONE"

    ciEnv >"$VM_DIR/env"
}
export -f ciInitOutput

#########################################################################################################
#
# ciTcpCheck($@): test tcpcheck
# arg1: host
# arg2: port
# arg3: maxtry
#########################################################################################################
function ciTcpCheck()
{
    local host="$1"
    local port="$2"
    if command -v tcpcheck >/dev/null 2>/dev/null
    then
        tcpcheck 1 "${host}:${port}" >/dev/null 2>/dev/null
        return $?
    fi
    if command -v nc >/dev/null 2>/dev/null
    then
        nc -v -w1 "${host}" "${port}" >/dev/null 2>/dev/null
        return $?
    fi
    # par default OK
    return 0
}
export -f ciTcpCheck

#########################################################################################################
#
# ciWaitTcpPort($@): Attente port tcp
# arg1: host
# arg2: port
# arg3: maxtry
#########################################################################################################
function ciWaitTcpPort()
{
    local host
    local port
    local maxtry
    local cdu
    local counter

    host="$1"
    port="$2"
    maxtry=$3

    counter=0
    while [[ ${counter} -lt ${maxtry} ]] ;
    do
        counter=$(( counter + 1 ))
        if ciTcpCheck "${host}" "${port}"
        then
            return 0
        fi
        sleep 1
        ciPrintMsg "ciWaitTcpPort ${host}:${port} (${counter}/${maxtry}): wait port ip $(date "+%Y-%m-%d %H:%M:%S")"
    done
    ciPrintMsg "ciWaitTcpPort ${host}:${port} : timeout, service non disponible !"
    return 1
}
export -f ciWaitTcpPort


###########################################################################################
#
# Wait Boot Complete
#
############################################################################################
function ciWaitBootComplete()
{
    ciPrintMsg "Debut ciWaitBootComplete"

    RUNLEVEL=$(/sbin/runlevel | cut -d " " -f 2)
    ciPrintMsg "ciWaitBootComplete : runlevel = $RUNLEVEL"
    until [[ $RUNLEVEL -ge 1 ]] && [[ $RUNLEVEL -le 6 ]]; do
        sleep 10
        RUNLEVEL=$(/sbin/runlevel | cut -d " " -f 2)
        ciPrintMsg "ciWaitBootComplete : runlevel = $RUNLEVEL"
        if [[ $RUNLEVEL == 2 ]]
        then
            ciPrintMsg "RUNLEVEL 2"
        fi

        if [ -f /etc/nologin ]
        then
            ciPrintMsg "/etc/nologin existe : boot en cours"
        else
            ciPrintMsg "/etc/nologin n'existe plus : boot fini"
        fi

    done
    ciPrintMsg "Fin ciWaitBootComplete"
}
export -f ciWaitBootComplete

############################################################################################
#
# ciGetProcess() : get liste des processus
#
############################################################################################
function ciGetProcess()
{
   ps ax >/tmp/ps.tmp
   if [ "$VM_IS_FREEBSD" == "1" ]
   then
       sed -i -e "# ps ax#d" /tmp/ps.tmp
       sed -i -e "#/etc/init.d/ondemand#d" /tmp/ps.tmp
       sed -i -e "#[kworker#d" /tmp/ps.tmp
       sed -i -e "#[upsmon#d" /tmp/ps.tmp
       sed -i -e "#sleep#d" /tmp/ps.tmp
       sed -i -e "s/^......................//" /tmp/ps.tmp
   fi
   if [ "$VM_IS_UBUNTU" == "1" ]
   then
       sed -i -e "# ps ax#d" /tmp/ps.tmp
       sed -i -e "#/etc/init.d/ondemand#d" /tmp/ps.tmp
       sed -i -e "#[kworker#d" /tmp/ps.tmp
       sed -i -e "#[upsmon#d" /tmp/ps.tmp
       sed -i -e "#sleep#d" /tmp/ps.tmp
       sed -i -e "s/^...........................//" /tmp/ps.tmp
   fi
   sort /tmp/ps.tmp
   /bin/rm -f /tmp/ps.tmp
}
export -f ciGetProcess

############################################################################################
#
# ciGetProcess() : Wait Boot Complete
#
############################################################################################
function ciAfficheProcess()
{
    local counter
    local counter_termine
    local LIMITE

    ciPrintMsg "Debut ciAfficheProcess $(date "+%Y-%m-%d %H:%M:%S")"

    #if [[ "$VM_EST_MACHINE_EOLE" != "oui" ]] && [[ "$VM_MACHINE" != "daily" ]]
    #then
    #    ciPrintMsg "pas d'attente pour les machines non eole !"
    #    ciPrintMsg "Fin ciAfficheProcess $(date "+%Y-%m-%d %H:%M:%S")"
    #    return 0
    #fi

    ciGetProcess >/tmp/ps.txt
    RESULT=0
    counter=0
    counter_termine=0
    LIMITE=80
    [[ "$VM_CONTAINER" = "oui" ]] && LIMITE=200
    /bin/rm -f /tmp/initctl.txt
    while [[ $counter -le $LIMITE ]];
    do
      if command -v systemctl >/dev/null 2>/dev/null
      then
          ciPrintMsg "****************************************************************************************************************"
          ciPrintMsgMachine "systemctl is-active multi-user.target : $(systemctl is-active multi-user.target)"
          ciPrintMsgMachine "systemctl is-active network.target : $(systemctl is-active network.target)"
          ciPrintMsgMachine "systemctl is-active network-online.target : $(systemctl is-active network-online.target)"
          IS_RUNNING=$(systemctl is-system-running)
          ciPrintMsgMachine "systemctl is-system-running : ${IS_RUNNING}"
          case "${IS_RUNNING}" in
             degraded)
                ciPrintMsg "**************************************"
                ciPrintMsg "systemctl --state=failed"
                systemctl --state=failed
                ciPrintMsg "**************************************"
                break
                ;;

             running)
                ciPrintMsg "system running OK ==> stop"
                RESULT=0
                break
                ;;
          esac
      else
          if command -v initctl >/dev/null 2>/dev/null
          then
              initctl --system list >/tmp/initctl1.txt
              if [ -f /tmp/initctl.txt ]
              then
                  ciPrintMsg "**************************************"
                  diff /tmp/initctl.txt /tmp/initctl1.txt
                  ciPrintMsg "**************************************"
              fi
              /bin/rm -f /tmp/initctl.txt
              /bin/mv -f /tmp/initctl1.txt /tmp/initctl.txt
          fi
      fi

      if ciTcpCheck 127.0.0.1 8000
      then
          ciPrintMsg "CreoleD attend en 8000 ==> test creoleget ..."
          if CreoleGet eole_version
          then
              ciPrintMsg "CreoleD m'a répondu : OK, j'arrête"
              RESULT=0
              break
          else
              ciPrintMsg "CreoleD ne m'a pas répondu : j'attends"
          fi
      fi

      sleep 2
      ciGetProcess >/tmp/ps1.txt
      counter=$(( counter + 1 ))
      counter_termine=$(( counter_termine + 1 ))
      diff /tmp/ps.txt /tmp/ps1.txt >/tmp/ps.diff
      cdu=$?
      /bin/rm -f /tmp/ps.txt
      mv /tmp/ps1.txt /tmp/ps.txt
      ciPrintMsg "$cdu : ${counter}/${LIMITE}, ${counter_termine}/30 Zzz.............. $(date "+%Y-%m-%d %H:%M:%S")"
      cat /tmp/ps.diff

      if [[ $counter -gt $LIMITE ]]
      then
          # plus d'activité ==> ok (?)
          ciPrintMsg "sortie counter >= $LIMITE"
          RESULT=0
          break
      fi

      if [[ $cdu -eq 0 ]]
      then
         if [[ $counter_termine -gt 30 ]]
         then
             ciPrintMsg "sortie counter_termine >= 30"
             RESULT=0
             break
         fi
      else
         ciPrintMsg "reset counter_termine = 0"
         counter_termine=0
      fi
    done

    /bin/rm -f /tmp/ps.txt

    /bin/rm -f /tmp/initctl.txt
    ciPrintMsg "Fin ciAfficheProcess : RESULT = $RESULT    $(date "+%Y-%m-%d %H:%M:%S")"
    return $RESULT
}
export -f ciAfficheProcess

############################################################################################
#
# ciWaitConteneur() : Wait Conteneur
#
############################################################################################
function ciWaitConteneur()
{
    #ciPrintMsg "Debut ciWaitConteneur $1"
    local conteneur=$1
    local A
    local B
    local CDU
    local conteneur
    local iter

    if [ -z "$conteneur" ]
    then
        return 1
    fi

    if ! command -v lxc-info
    then
        ciPrintMsg "$conteneur : pas de lxc-info, OK"
        return 0
    fi
    
    if command -v systemctl >/dev/null 2>/dev/null
    then
        A=$(lxc-info -n "$conteneur" -s | awk '{ print $2; }')
        if [ "$A" == "RUNNING" ]
        then
            # avec systemd ==> agetty
            B=$(lxc-attach -n "$conteneur" -- /bin/systemctl is-active multi-user.target)
            CDU=$?
            if [ $CDU -eq 0 ]
            then
                ciPrintMsg "$conteneur : OK, $B"
                return 0
            else
                echo "$conteneur : cdu=$CDU console? : $B"
            fi
        else
            echo "$conteneur : Statut = $A"
        fi
        return 1
    else
        A=$(lxc-info -n "$conteneur" -s | awk '{ print $2; }')
        if [ "$A" == "RUNNING" ]
        then
            lxc-attach -n "$conteneur" -- /bin/ps aux | grep -q "/sbin/getty"
            CDU=$?
            if [ $CDU -eq 0 ]
            then
                ciPrintMsg "$conteneur : OK"
                return 0
            else
                echo "$conteneur : cdu=$CDU console?"
            fi
        else
            echo "$conteneur : Statut = $A"
        fi
        return 1
    fi
}
#private : export -f ciWaitConteneur

############################################################################################
#
# ciWaitConteneurs() : Wait Conteneur
#
############################################################################################
function ciWaitConteneurs()
{
    ciPrintMsg "Debut ciWaitConteneurs $(date "+%Y-%m-%d %H:%M:%S")"

    if [[ "$VM_CONTAINER" != "oui" ]]
    then
        # cas ScribeAD HorusAD
        if [[ -d /var/lib/lxc/addc ]]
        then
            for iter in $(seq 1 10)
            do
                if ciWaitConteneur "addc"
                then
                    ciPrintMsg "Fin ciWaitConteneurs : ADDC OK $(date "+%Y-%m-%d %H:%M:%S")"
                    return 0
                fi
                sleep 2
           done
            ciPrintMsg "Fin ciWaitConteneurs : ADDC ERREUR $(date "+%Y-%m-%d %H:%M:%S")"
            return 1
        fi
        ciPrintMsg "Fin ciWaitConteneurs : OK, inutile $(date "+%Y-%m-%d %H:%M:%S")"
        return 0
    fi

    if [[ ! -d /opt/lxc ]]
    then
        ciPrintMsg "Fin ciWaitConteneurs : pas encore crée ==> pas d'attente!"
        return 0
    fi

    if ciVersionMajeurEgal "2.3"
    then
        ciPrintMsg "Fin ciWaitConteneurs : pas d'attente en 2.3 !"
        return 0
    fi

    echo "ls -l /opt/lxc /var/lib/lxc"
    ls -l /opt/lxc /var/lib/lxc

    local LIST_CONTENEUR
    local conteneur

    LIST_CONTENEUR="$(lxc-ls)"
    RESULT=0
    for iter in $(seq 1 20)
    do
        ciPrintMsg "ciWaitConteneurs test no $iter à $(date "+%Y-%m-%d %H:%M:%S")"
        RESULT=0
        for conteneur in $LIST_CONTENEUR
        do
            if ! ciWaitConteneur "$conteneur"
            then
                ciPrintMsg "Conteneurs $conteneur non pret: ERREUR"
                RESULT=1
            fi
        done
        if [ $RESULT == 0 ]
        then
            break
        fi
        sleep 10
    done
    if [ $RESULT == 1 ]
    then
        ciPrintMsg "grep /etc/init/lxc.conf"
        grep "started cgmanager" /etc/init/lxc.conf

        for conteneur in $LIST_CONTENEUR
        do
            ciPrintMsg "Cat /var/log/lxc/${conteneur}.log"
            cat "/var/log/lxc/${conteneur}.log"
        done
        ciExportCurrentStatus "erreur ciWaitConteneurs"

        ciPrintMsg "Fin ciWaitConteneurs : ERREUR $(date "+%Y-%m-%d %H:%M:%S")"
        #return 1
        return 0
    else
        ciPrintMsg "Fin ciWaitConteneurs : OK $(date "+%Y-%m-%d %H:%M:%S")"
        return 0
    fi
}
export -f ciWaitConteneurs

############################################################################################
#
# Configuration Poste Linux
#
############################################################################################
function ciInstallPaquet()
{
    if [[ -n "$2" ]]
    then
        if [ -f "$2" ] || [[ -d "$2" ]]
        then
            ciPrintMsg "* Paquet $1 semble installé car $2 existe"
            return 0
        else
            ciPrintMsg "* Paquet $1 à installer car $2 n'existe pas"
        fi
    else
        ciPrintMsg "* Paquet $1"
    fi
    if [[ -n "$1" ]]
    then
        #dpkg --configure -a
        if [ "$VM_IS_UBUNTU" == "1" ]
        then
            apt-get install -y "$1"
        fi
        if [ "$VM_IS_FREEBSD" == "1" ]
        then
            pkg install -y "$1"
        fi
    fi
}
export -f ciInstallPaquet


############################################################################################
#
# Contextualisation machine 'EOLECITEST'
#
############################################################################################
function ciContextualizeEoleCiTests()
{
    ciPrintConsole "Début ciContextualizeEoleCiTests"

    ciGetNamesInterfaces
    ciContextualisationMinimale

    echo "* timedatectl set-timezone"
    timedatectl set-timezone "Europe/Paris"

    samba-eolecitest.sh --contextualize

    ciPrintConsole "Fin ciContextualizeEoleCiTests : ok ($SECONDS)"
}
export -f ciContextualizeEoleCiTests

############################################################################################
#
# Configuration machine 'EOLECITEST'
#
############################################################################################
function ciConfigurationMachineEoleCiTests()
{
    ciPrintConsole "Début ciConfigurationMachineEoleCiTests"
    ciGetNamesInterfaces

    ls -l /etc/netplan
    if [ -f /etc/netplan/00-installer-config.yaml ]
    then
        /bin/rm -f /etc/netplan/00-installer-config.yaml
    fi

    echo "* netplan --debug apply"
    netplan --debug apply

    echo "* ciCheckSSHDConfig"
    ciCheckSSHDConfig

    echo "* timedatectl"
    timedatectl

    SSH_ACTIVE=$(ciIsActiveService ssh)
    if [ "$SSH_ACTIVE" == "active" ]
    then
        ciPrintMsgMachine "Redémarrage SSH !"
        service ssh start
    fi

    ciPrintConsole "Installation SAMBA"
    if ! command -v smbd
    then
        ciPrintConsole "Attention : nous ne devrions jamais arriver ici"
        apt-get update
        apt-get -y --force-yes install samba winbind
        # dans ce cas, il faut execute la contextualization
        samba-eolecitest.sh --contextualize
    fi

    samba-eolecitest.sh --configuration

    ciPrintConsole "Fin ciConfigurationMachineEoleCiTests : ok"
}
export -f ciConfigurationMachineEoleCiTests

############################################################################################
#
# Inject source liste EOLE sur une ubuntu server
#
############################################################################################
function ciInjectSourcesListSurUbuntu()
{
    ciPrintConsole "ciInjectSourcesListSurUbuntu : Utilise les sources ${VM_VERSIONMAJEUR} $VM_MAJAUTO"
    local VM_VERSION_EOLE

    if [ "$VM_IS_UBUNTU" == "0" ]
    then
        ciPrintMsgMachine "ciInjectSourcesListSurUbuntu: n'est pas Ubuntu !"
        return 0
    fi

    ciGetEoleVersion
    if ciVersionMajeurApres "2.6.1"
    then
        FORCE_ARCH="[ arch=amd64 ]"
    else
        FORCE_ARCH=""
    fi
    if [ "$VM_MAJAUTO" == "DEV" ]
    then
        DEPOT=${VM_VERSION_EOLE}-unstable
        echo "deb ${FORCE_ARCH} http://test-eole.ac-dijon.fr/eole eole-${DEPOT} main cloud" > /etc/apt/sources.list.d/eole.list
        wget -O- "http://test-eole.ac-dijon.fr/eole/project/eole-${VM_VERSION_EOLE}-repository.key" | apt-key add -
    else
        if [ "$VM_MAJAUTO" == "RC" ]
        then
            DEPOT=${VM_VERSIONMAJEUR}
            echo "deb ${FORCE_ARCH} http://test-eole.ac-dijon.fr/eole eole-${DEPOT} main cloud" > /etc/apt/sources.list.d/eole.list
            echo "deb ${FORCE_ARCH} http://test-eole.ac-dijon.fr/eole eole-${DEPOT}-security main cloud" >> /etc/apt/sources.list.d/eole.list
            echo "deb ${FORCE_ARCH} http://test-eole.ac-dijon.fr/eole eole-${DEPOT}-updates main cloud" >> /etc/apt/sources.list.d/eole.list
            wget -O- "http://test-eole.ac-dijon.fr/eole/project/eole-${VM_VERSION_EOLE}-repository.key" | apt-key add -
        else
            DEPOT=${VM_VERSIONMAJEUR}
            echo "deb ${FORCE_ARCH} http://eole.ac-dijon.fr/eole eole-${DEPOT} main cloud" > /etc/apt/sources.list.d/eole.list
            echo "deb ${FORCE_ARCH} http://eole.ac-dijon.fr/eole eole-${DEPOT}-security main cloud" >> /etc/apt/sources.list.d/eole.list
            echo "deb ${FORCE_ARCH} http://eole.ac-dijon.fr/eole eole-${DEPOT}-updates main cloud" >> /etc/apt/sources.list.d/eole.list
            wget -O- "http://eole.ac-dijon.fr/eole/project/eole-${VM_VERSION_EOLE}-repository.key" | apt-key add -
        fi
    fi
    ciPrintConsole "execute: apt-get update"
    apt-get update
    ciPrintConsole "ATTENTION FAIRE :"
    ciPrintConsole "  apt-get install eole-server eole-exim-pkg"
    ciPrintConsole "Pour un Conteneur:"
    ciPrintConsole "  apt-get install eole-lxc-controller eole-ssmtp-pkg"
    ciPrintConsole "Pour un Module:"
    ciPrintConsole "  apt-eole install eole-scribe-module"
    return 0
}
export -f ciInjectSourcesListSurUbuntu

#########################################################################################################
#
# Change le mdp du compte et supprime le  profil obligatorie
#
#########################################################################################################
function ciAccountProfile()
{
    ciPrintMsgMachine "ciAccountProfile : $*"
    ACCOUNT_NAME="$1"
    PWD="${2:-eole}"

    echo "$PWD" | smbldap-passwd -p "$ACCOUNT_NAME"
    ciCheckExitCode "$?" "Force changement mot de passe"

    pdbedit -p " " "$ACCOUNT_NAME"
    ciCheckExitCode "$?" "Suppression profile obligatoire"

    return 0
}
export -f ciAccountProfile

############################################################################################
#
# Configuration Module Eole
#
############################################################################################
function ciConfigurationModuleEole()
{
    ciPrintMsgMachine "Début ciConfigurationModuleEole"

    ############################################################################################
    # Si le fichier /etc/eole/config.eol existe, on ne touche à rien !
    ############################################################################################
    RETOUR=0
    if [[ -f /etc/eole/config.eol ]]
    then
        if [ "$VM_CONFIGURATION" == "" ]
        then
            ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "Le fichier config.eol existe : je ne fais rien !"
            ciCheckAccesInternet
            return 0
        fi
        if [ "$INSTANCE_CONFIGURATION" == "$VM_CONFIGURATION" ]
        then
            ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "Le fichier config.eol existe et l'image est instanciée : je ne fais rien !"
            ciCheckAccesInternet
            return 0
        else
            echo "INSTANCE_CONFIGURATION=$INSTANCE_CONFIGURATION et VM_CONFIGURATION=$VM_CONFIGURATION sont différent"
        fi
    else
        # si pas de fichier config.eol , faut il faire la configuration minimale ?
        if [[ -n "$VM_MACHINE" ]]
        then
            ciPrintMsgMachine "ciConfigureAutomatiqueMinimale car VM_MACHINE non vide"
            ciConfigureAutomatiqueMinimale
            RETOUR="$?"
        fi
    fi

    if [[ -n "$VM_METHODE" ]]
    then
        ciCreateMotd
        ciPrintMsgMachine "ciConfigureAutomatiqueAvecMethode car VM_METHODE non vide"
        ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "ciConfigurationModuleEole : instance/reconfigure"
        ciConfigureAutomatiqueAvecMethode
        RETOUR="$?"
        ciRemoveMotd
        if [[ "$RETOUR" -eq 0 ]]
        then
            ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "ciConfigurationModuleEole : OK"
        else
            ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "ciConfigurationModuleEole : en ERREUR, la machine n'est pas fonctionnelle"
        fi
    else
        ciPrintMsgMachine "Fin ciConfigurationModuleEole : sans méthode, ok"
    fi
    return $RETOUR
}
export -f ciConfigurationModuleEole

############################################################################################
#
# Contextualize Module Eole
#
############################################################################################
function ciContextualizeModuleEole()
{
    ciPrintMsgMachine "Début ciContextualizeModuleEole"

    ############################################################################################
    # Si le fichier /etc/eole/config.eol existe, on ne touche à rien !
    ############################################################################################
    if [[ -f /etc/eole/config.eol ]]
    then
        ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "Le fichier config.eol existe : plus de contextualization !"
        return 0
    fi
    ciContextualisationMinimale

    ciPrintMsgMachine "Fin ciContextualizeModuleEole"
    return 0
}
export -f ciContextualizeModuleEole

############################################################################################
#
# Contextualize Machine (avant reseaux)
#
############################################################################################
function ciContextualizeMachine()
{
    if [ -z "$VM_MACHINE" ]
    then
        ciPrintMsgMachine "ciContextualizeMachine : pas de MACHINE, stop !"
        return 0
    fi

    ciPrintMsgMachine "Début ciContextualizeMachine : $VM_MACHINE, $VM_HOSTNAME"

    case "$VM_MACHINE" in
        gateway-ecologie)
            ciGetNamesInterfaces
            bash "$VM_DIR_EOLE_CI_TEST/configuration/gateway/contextualize_routeur_ecologie.sh" 2>&1
            ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "Démarrée en $(ciGetCurrentIp)"
            ;;

        freebsd*)
            # comme une daily !
            ciContextualizeDaily
            set -x
            ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "Démarrée en $(ciGetCurrentIp)"
            ;;

        gateway*)
            ciGetNamesInterfaces
            bash "$VM_DIR_EOLE_CI_TEST/configuration/gateway/contextualize_routeur_ubuntu_dnsmasq.sh" 2>&1
            ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "Démarrée en $(ciGetCurrentIp)"
            ;;

        aca.gateway*)
            ciGetNamesInterfaces
            bash "$VM_DIR_EOLE_CI_TEST/configuration/gateway/contextualize_routeur_ubuntu_dnsmasq.sh" 2>&1
            ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "Démarrée en $(ciGetCurrentIp)"
            ;;

        daily)
            ciContextualizeDaily
            ;;

        aca.ubuntuserver)
            ciPrintConsole "$VM_OWNER $VM_ID $VM_MACHINE" "Pas de contextualization pour aca.ubuntuserver"
            ;;

        ubuntuserver)
            ciPrintConsole "$VM_OWNER $VM_ID $VM_MACHINE" "Pas de contextualization pour ubuntuserver"
            ;;

        update)
            ciContextualizeUpdate
            ;;

        *)
            case "$VM_HOSTNAME" in
                pc*)
                    ciContextualizePcLinux
                    ;;

                eolecitests*)
                    ciContextualizeEoleCiTests
                    ;;

                *)
                    ciContextualizeModuleEole
                    ;;
            esac
            ;;
    esac

    SCRIPT_CONTEXTUALIZE_SH="$VM_DIR_EOLE_CI_TEST/configuration/$VM_MACHINE/contextualize.sh"
    if [ -f "$SCRIPT_CONTEXTUALIZE_SH" ]
    then
        ciPrintMsgMachine "Execution $SCRIPT_CONTEXTUALIZE_SH "
        bash "$SCRIPT_CONTEXTUALIZE_SH"
        ciPrintMsgMachine "Fin Execution $SCRIPT_CONTEXTUALIZE_SH "
    fi

    ciPrintConsole "Contextualization Machine OK"
    VM_ID_CONTEXT_DATE=$(date "+%Y-%m-%d %H:%M:%S")
    cat >/root/.eole-ci-tests.context <<EOF
VM_ID_CONTEXT=$VM_ID
VM_ID_CONTEXT_DATE=$VM_ID_CONTEXT_DATE
EOF
    #cat /root/.eole-ci-tests.context

    ciPrintConsole "$VM_OWNER $VM_ID $VM_MACHINE" "Contextualization Machine : OK"
    ciPrintMsgMachine "Fin ciContextualizeMachine : ok à $VM_ID_CONTEXT_DATE"
}
export -f ciContextualizeMachine

############################################################################################
#
# Configuration Automatique : apres reseau
#
############################################################################################
function ciConfigurationAutomatique()
{
    ciPrintDebug "Début ciConfigurationAutomatique : $VM_MACHINE $VM_HOSTNAME $VM_METHODE"

    if [ -z "$VM_MACHINE" ]
    then
        ciPrintDebug "Fin ciConfigurationAutomatique : pas de MACHINE"
        return 0
    fi

    case "$VM_MACHINE" in
        gateway-ecologie)
            bash "$VM_DIR_EOLE_CI_TEST/configuration/gateway/configure_routeur_ecologie.sh" 2>&1 0</dev/null
            ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "Démarrée en $(ciGetCurrentIp)"
            ;;

        freebsd*)
            bash "$VM_DIR_EOLE_CI_TEST/configuration/gateway/configure_agent_freebsd.sh" 2>&1 0</dev/null
            ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "Démarrée en $(ciGetCurrentIp)"
            ;;

        gateway*)
            bash "$VM_DIR_EOLE_CI_TEST/configuration/gateway/configure_routeur_ubuntu_dnsmasq.sh" 2>&1 0</dev/null
            ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "Démarrée en $(ciGetCurrentIp)"
            ;;

        aca.gateway*)
            bash "$VM_DIR_EOLE_CI_TEST/configuration/gateway/configure_routeur_ubuntu_dnsmasq.sh" 2>&1 0</dev/null
            ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "Démarrée en $(ciGetCurrentIp)"
            ;;

        aca.kubernetes-master)
            bash "$VM_DIR_EOLE_CI_TEST/configuration/$VM_MACHINE/configure-kubernetes-master.sh" 2>&1 0</dev/null
            ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "Démarrée en $(ciGetCurrentIp)"
            ;;

        aca.kubernetes-node)
            bash "$VM_DIR_EOLE_CI_TEST/configuration/$VM_MACHINE/configure-kubernetes-node.sh" 2>&1 0</dev/null
            ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "Démarrée en $(ciGetCurrentIp)"
            ;;

        daily)
            ciConfigurationDaily
            ;;

        update)
            ciConfigurationUpdate
            ;;

        ubuntuserver)
            ciPrintConsole "$VM_OWNER $VM_ID $VM_MACHINE" "Pas de configuration pour ubuntuserver"
            ;;

        *)
            if [ -z "$VM_HOSTNAME" ]
            then
                ciPrintDebug "Fin ciConfigurationAutomatique : pas de hostname"
                return 0
            fi
            case "$VM_HOSTNAME" in
                pc*)
                    ciConfigurationPcLinux
                    ;;

                eolecitests*)
                    ciConfigurationMachineEoleCiTests
                    ;;

                *)
                    ciConfigurationModuleEole
                    ;;
            esac
            ;;
    esac

    SCRIPT_CONFIGURE_SH="$VM_DIR_EOLE_CI_TEST/configuration/$VM_MACHINE/configure.sh"
    if [ -f "$SCRIPT_CONFIGURE_SH" ]
    then
        ciPrintMsgMachine "Execution $SCRIPT_CONFIGURE_SH "
        bash "$SCRIPT_CONFIGURE_SH"
        ciPrintMsgMachine "Fin Execution $SCRIPT_CONFIGURE_SH "
    fi

    if command -v updatedb
    then
        # désactive le locate sur /mnt/eole-ci-test !
        if ! grep -q 9p /etc/updatedb.conf
        then
            ciPrintMsgMachine "* désactive le updatedb/locate sur /mnt/eole-ci-test !"
            sed -i 's#PRUNEFS="NFS#PRUNEFS="9p NFS#' /etc/updatedb.conf

            ciPrintMsgMachine "* updatedb"
            updatedb
        else
            ciPrintMsgMachine "* désactivation updatedb/locate sur /mnt/eole-ci-test présente !"
        fi
    fi

    ciPrintDebug "Fin ciConfigurationAutomatique"
    return 0
}
export -f ciConfigurationAutomatique

############################################################################################
#
# emettre un evenement vers une autre machine
#
############################################################################################
function ciSendEvent()
{
    local toMachine="${1}"
    local what="${2}"

    ciPrintMsg "ciSendEvent: $toMachine $what"
    if [ -d "$DIR_OUTPUT_OWNER/$toMachine" ]
    then
        EVENT="$DIR_OUTPUT_OWNER/$toMachine/todo/${VM_ID}-$(date +%s).event"
        printf '%s\n%s' "$VM_MACHINE" "$what" >"$EVENT"
    else
        ciPrintMsg "ciSendEvent: le repertoire de la machine n'existe pas ($toMachine) !"
    fi
}

############################################################################################
#
# actions a réaliser sur un event recu d'une autre machine
#
############################################################################################
function ciOnEvent()
{
    local f="$1"
    
    local fromMachine
    local what

    fromMachine=$(head -n 1 "$f")
    what=$(tail -n +2 "$f")
    /bin/rm -f "$f"
    ciPrintDebug "Début ciOnEvent to=$VM_MACHINE, from=$fromMachine, what=$what"
    case "$VM_MACHINE" in
        gateway*)
            case "$fromMachine" in
                aca.kubernetes-node)
                    # Ajout kubernetes-node + ip dans hosts
                    echo "192.168.0.$what kubernetes-node$what" >>/etc/hosts
                    # demande a dnsmasq de recharger la conf
                    pkill -HUP dnsmasq
                    ;;

                aca.proxy)
                    case "$what" in
                         APRES_INSTANCE)
                            # wpad ==> 192.168.0.10
                            ;;

                         *)
                            ;;
                    esac
                    ;;

                aca.dc1)
                    case "$what" in
                         APRES_INSTANCE)
                            # dns ==> 192.168.0.5
                            ;;

                         *)
                            ;;
                    esac
                    ;;

                *)
                    ;;
            esac
            ;;

        *)
            ;;
    esac

    ciPrintDebug "Fin ciOnEvent"
    return 0
}
#export -f ciOnEvent

############################################################################################
#
# boucle de traitement des commandes
#
############################################################################################
function ciOnShell()
{
    local f="$1"
    
    echo "shell : $f"
    base=$(basename "$f" .sh)
    output="$base.log"
    fichierExit="$base.exit"

    ciCreateDir "$VM_DIR_RUNNING"
    if [ -f "$VM_DIR_RUNNING/${base}.sh" ]
    then
        # protection 
        echo "ERREUR PROTECTION $VM_DIR_RUNNING/${base}.sh existe déjà !!" >>"$VM_DIR_DONE/$output" 2>&1
        echo "1" >"$VM_DIR_DONE/$fichierExit"
        chmod 777 "$VM_DIR_DONE/$fichierExit"
        /bin/rm -f "$f"
        return 
    fi
    
    mv "$f" "$VM_DIR_RUNNING/"
    chmod +x "$VM_DIR_RUNNING/${base}.sh"

    ciPrintMsg "Commande TODO : $VM_DIR_RUNNING/${base}.sh vers $output"
    ciPrintMsg "############################################################################################"
    cat "$VM_DIR_RUNNING/${base}.sh"
    ciPrintMsg "--------------------------------------------------------------------------------------------"

    ciCreateDir "$VM_DIR_DONE"
    ciPrintMsg "Run from daemon_runner" >"$VM_DIR_DONE/$output"
    # pour rendre visible depuis n'importe quelle machine ...
    chmod 777 "$VM_DIR_DONE/$output"

    /bin/bash "$VM_DIR_RUNNING/${base}.sh" >"$VM_DIR_DONE/$output" 2>&1
    RESULT="$?"
    ciPrintMsg "Exit ${base}.sh ==> $RESULT"
    sync
    sleep 4
    if [ ! -f "$VM_DIR_DONE/$fichierExit" ]
    then
        echo "$RESULT" >"$VM_DIR_DONE/$fichierExit"
        chmod 777 "$VM_DIR_DONE/$fichierExit"
    fi
    ciPrintMsg "cat $VM_DIR_DONE/$fichierExit"
    cat "$VM_DIR_DONE/$fichierExit"
    sync
    ciPrintMsg "############################################################################################"
    [ -f "$VM_DIR_RUNNING/${base}.sh" ] && /bin/rm -f "$VM_DIR_RUNNING/${base}.sh"
    if [ "$RESULT" != "0" ]
    then
        ciExportCurrentStatus "on exit ${base}.sh" 
    fi
    DUREE_PAUSE=10
}

############################################################################################
#
# boucle de traitement des commandes
#
############################################################################################
function ciOnMessage()
{
    local f="$1"
    echo "message : $f"
    title=$(head -n 1 "$f")
    corps=$(tail -n +2 "$f")
    /bin/rm -f "$f"

    ciPrintMsg "############################################################################################"
    ciPrintMsg "Message:"
    cat "$f"
    ciPrintMsg "--------------------------------------------------------------------------------------------"
    if [ -n "$IP_UTILISATEUR" ]
    then
        perl -w "$VM_DIR_EOLE_CI_TEST/scripts/send-notify-network.pl" "$IP_UTILISATEUR" "$title" "$corps"
    fi
}

############################################################################################
#
# boucle de traitement des commandes
#
############################################################################################
function ciBoucleDExecution()
{
    # je memorise dans une variable le no de processus ==> s'il change
    DAEMON_PID="$$"
    echo $DAEMON_PID >"$VM_DIR/daemon.pid"
    chmod 777 "$VM_DIR/daemon.pid"
    echo $DAEMON_PID >"/root/.daemon.pid"
    # laisse le temps a l'autre instance pour s'arreter (s'il elle ne fait rien, sinon ... dommage)
    sleep 30

    #trap ciStopDaemonTrap INT TERM

    touch "$VM_DIR/daemon.running"
    chmod 777 "$VM_DIR/daemon.running"

    # OOM_DISABLE on $DAEMON_PID
    if [ -f "/proc/${DAEMON_PID}/oom_adj" ]
    then
        ciPrintMsg "OOM_DISABLE on $DAEMON_PID"
        echo -17 >"/proc/${DAEMON_PID}/oom_adj"
    fi

    VM_PREVIOUS_IP=""
    while :
    do
        bash /root/mount.eole-ci-tests
        DUREE_PAUSE=30
        if [[ -d "$VM_DIR" ]]
        then
            # le fichier 'daemon.running' est modifier toutes les 10 secondes !
            date +%H:%M >"$VM_DIR/daemon.running"

            if [[ -f "/root/.daemon.pid" ]]
            then
                # si le service est redémarré, alors le fichier daemon.pid sera ecrasé. La valeur du PID aura changée ==> on stop
                DAEMON_PID1=$(cat "/root/.daemon.pid")
                if [[ "$DAEMON_PID1" != "$DAEMON_PID" ]]
                then
                    ciPrintMsg "############################################################################################"
                    ciPrintMsg "Detection redemmarrage du service"
                    ciPrintMsg "############################################################################################"
                    break
                fi
            fi

            # enregistre l'ip
            CURRENT_IP="$(ciGetCurrentIp)"
            if [[ "$CURRENT_IP" != "$VM_PREVIOUS_IP" ]]
            then
                ciNotifyUtilisateur "$VM_OWNER $VM_MACHINE $VM_ID" "Adresse(s) ip changée de $VM_PREVIOUS_IP vers $CURRENT_IP"
                VM_PREVIOUS_IP=$CURRENT_IP
                ciPrintMsg "$CURRENT_IP" >"$VM_DIR/ip"
                ciPrintMsg "Changement IP : $CURRENT_IP"
            fi

            if [[ "$VM_MACHINE" == "gateway"* ]]
            then
                if [[ -f /var/lib/misc/dnsmasq.leases ]]
                then
                    if [[ /var/lib/misc/dnsmasq.leases -nt "$VM_DIR/dnsmasq.leases" ]]
                    then
                        ciPrintMsg "Sauvegarde dnsmasq.leases"
                        /bin/cp /var/lib/misc/dnsmasq.leases "$VM_DIR/dnsmasq.leases"
                    fi
                fi
            fi

            # nettoyage tous les fichiers de plus de 24h sont supprimés
            find "${VM_DIR}/done" -mmin +$((60*24)) -delete

            # nettoyage tous les fichiers de plus de 10h sont supprimés
            find "${VM_DIR}/todo" -mmin +$((60*10)) -delete

            shopt -s nullglob
            for f in "${VM_DIR_TODO}"/*
            do
                if [ -d "$f" ]
                then
                    echo "repertoire : $f !"
                else
                    if [ "${f: -3}" == ".sh" ]
                    then
                        ciOnShell "$f"
                        DUREE_PAUSE=10
                    fi
                    if [ "${f: -4}" == ".msg" ]
                    then
                        ciOnMessage "$f"
                        DUREE_PAUSE=10
                    fi
                    if [ "${f: -6}" == ".event" ]
                    then
                        ciPrintMsg "############################################################################################"
                        ciPrintMsg "Event:"
                        cat "$f"
                        ciPrintMsg "--------------------------------------------------------------------------------------------"
                        ciOnEvent "$f"
                        DUREE_PAUSE=10
                    fi
                fi
            done
        fi
        #cp -u /var/log/EoleCiTests*.log "$VM_DIR"

        if [[ -f "/root/.export.pid" ]]
        then
            ciExportCurrentStatus  "export ciBoucleDExecution"
            touch /root/.export.pid
        fi
        sleep ${DUREE_PAUSE}
    done
}
export -f ciBoucleDExecution

############################################################################################
#
# ciCreateMotd
#
############################################################################################
function ciCreateMotd()
{
    # n'exsite pas toujours !
    if [ -d /etc/update-motd.d/ ]
    then
        cat >/etc/update-motd.d/99-eole-ci-tests <<EOF
#!/bin/sh
echo "ATTENTION AUTO CONFIGURATION EN COURS : $VM_METHODE"
EOF
        chmod +x /etc/update-motd.d/99-eole-ci-tests
        /bin/cp /etc/issue /etc/issue.eolecitests
        echo -e "ATTENTION AUTO CONFIGURATION EN COURS : $VM_METHODE" >>/etc/issue
    fi
}
# pas d'export

############################################################################################
#
# ciRemoveMotd
#
############################################################################################
function ciRemoveMotd()
{
    if [ -d /etc/update-motd.d/ ]
    then
        [ -f "/etc/update-motd.d/99-eole-ci-tests"  ] && /bin/rm -f "/etc/update-motd.d/99-eole-ci-tests"
        sed -i -e "/ATTENTION AUTO CONFIGURATION EN COURS/d" /etc/issue
    fi
}
# pas d'export

############################################################################################
#
# ciWaitDaemonStart() : Wait EoleCiDaemon start
#
############################################################################################
function ciWaitDaemonStart()
{
    local counter
    local LIMITE

    ciPrintMsg "Debut ciWaitDaemonStart"

    if [[ "$VM_EST_MACHINE_EOLE" != "oui" ]] && [[ "$VM_MACHINE" != "daily" ]]
    then
        if [ "$VM_NAME" != "aca.pc" ]
        then
            ciPrintMsg "pas d'attente pour les machines non eole !"
            ciPrintMsg "Fin ciWaitDaemonStart $(date "+%Y-%m-%d %H:%M:%S")"
            return 0
        else
            ciPrintMsg "aca.pc attente !"
        fi
    fi

    RESULT=0
    counter=0
    LIMITE=80
    [[ "$VM_CONTAINER" = "oui" ]] && LIMITE=200
    /bin/rm -f /tmp/initctl.txt
    while [[ $counter -le $LIMITE ]];
    do
        if [ -f "$VM_DIR/daemon.start" ]
        then
            ciPrintMsg "****************************************************************************************************************"
            ciPrintMsgMachine "systemctl is-active multi-user.target : $(systemctl is-active multi-user.target)"
            ciPrintMsgMachine "daemon.start présent, STOP OK"
            RESULT=0
            break
        fi
        if command -v systemctl >/dev/null 2>/dev/null
        then
            ciPrintMsg "****************************************************************************************************************"
            ciPrintMsgMachine "systemctl is-active multi-user.target : $(systemctl is-active multi-user.target)"
            ciPrintMsgMachine "systemctl is-active network.target : $(systemctl is-active network.target)"
            ciPrintMsgMachine "systemctl is-active network-online.target : $(systemctl is-active network-online.target)"
            IS_RUNNING=$(systemctl is-system-running)
            ciPrintMsgMachine "systemctl is-system-running : ${IS_RUNNING}"
            case "${IS_RUNNING}" in
               degraded)
                 ciPrintMsg "**************************************"
                 ciPrintMsg "systemctl --state=failed"
                 systemctl --state=failed
                 ciPrintMsg "**************************************"
                 RESULT=1
                 ;;

               running)
                 ciPrintMsg "system running OK ==> stop"
                 RESULT=0
                 ;;
            esac
        else
          if command -v initctl >/dev/null 2>/dev/null
          then
              initctl --system list >/tmp/initctl1.txt
              ciPrintMsg "**************************************"
              diff /tmp/initctl.txt /tmp/initctl1.txt
              ciPrintMsg "**************************************"
              /bin/rm -f /tmp/initctl.txt
              /bin/mv -f /tmp/initctl1.txt /tmp/initctl.txt
          fi
      fi
      sleep 5
      counter=$(( counter + 1 ))
      ciPrintMsg "ciWaitDaemonStart : ${counter}/${LIMITE}, Zzz.............. $(date "+%Y-%m-%d %H:%M:%S")"
    done
    ciExportCurrentStatus "ciWaitDaemonStart"

    /bin/rm -f /tmp/initctl.txt
    ciPrintMsg "Fin ciWaitDaemonStart : RESULT = $RESULT    $(date "+%Y-%m-%d %H:%M:%S")"
    return $RESULT
}
#private : export -f ciWaitDaemonStart

############################################################################################
#
# ciContextualizeMe
#
############################################################################################
function ciContextualizeMe()
{
    ciPrintMsg "Début ciContextualizeMe"
    if [[ ! -d "$VM_DIR_EOLE_CI_TEST/scripts" ]]
    then
        echo "Montage $VM_DIR_EOLE_CI_TEST non monté"
        exit 1
    fi

    export LANG=fr_FR.UTF-8

    if [[ -z "$VM_ID" ]]
    then
        ciPrintMsg "Pas de VM_ID : stop "
        exit 1
    fi

    #ciPrintMsg "init à $(date "+%Y-%m-%d %H:%M:%S")"
    ciInitOutput

    ############################################################################################
    # fichier semaphore pour signaler le 'start' context eole-ci-tests
    ############################################################################################
    echo "$$" >"$VM_DIR/contextualize.start"

    if [ -f /root/.eole-ci-tests.context ]
    then
        # shellcheck disable=SC1091
        source /root/.eole-ci-tests.context 2>/dev/null
        export VM_ID_CONTEXT
        export VM_ID_CONTEXT_DATE
        if [ "$VM_ID" == "$VM_ID_CONTEXT" ]
        then
            # déjà fait pour cette machine
            ciPrintMsgMachine "ciContextualizeMachine: déjà réalisée à $VM_ID_CONTEXT_DATE"
        else
            ciPrintMsgMachine "ciContextualizeMachine: réalisée pour $VM_ID_CONTEXT, à refaire"
            # a été fait pour une autre VM !
            ciContextualizeMachine >>"$VM_DIR/contextualisation.log" 2>&1
        fi
    else
        # premiere fois
        ciContextualizeMachine >"$VM_DIR/contextualisation.log" 2>&1
    fi
    echo "$?" >"$VM_DIR/contextualisation.exit"

    echo "$$" >"$VM_DIR/contexualize.ok"

    # pour debug start daemon !
    #if ciVersionMajeurEgal "2.7.0"
    #then
    #    ciWaitDaemonStart >>"$VM_DIR/waitDaemonStart.log" 2>&1
    #fi
    ciPrintMsg "Fin ciContextualizeMe"
}

############################################################################################
#
# ciConfigurationMe
#
############################################################################################
function ciConfigurationMe()
{
    ciPrintMsg "* ciConfigurationMe : avant $(date "+%Y-%m-%d %H:%M:%S")"
    # cela doit être executé dans un sous shell, car il peut y avoir des Exit !
    (
        ciConfigurationAutomatique >"$VM_DIR/instanceAutomatique.log" 2>&1
        echo "$?" >"$VM_DIR/instanceAutomatique.exit"
    )
    if [ ! -f "$VM_DIR/instanceAutomatique.exit" ]
    then
        echo "-2" >"$VM_DIR/instanceAutomatique.exit"
    fi
    ciRemoveMotd
    ciPrintMsg "* ciConfigurationMe : apres $(date "+%Y-%m-%d %H:%M:%S")"
}
export -f ciConfigurationMe

############################################################################################
#
# ciDeamonMain
#
############################################################################################
function ciDaemonMain()
{
    ciPrintMsg "Début ciDeamonMain $0"

    if [[ ! -d "$VM_DIR_EOLE_CI_TEST/scripts" ]]
    then
        echo "Montage $VM_DIR_EOLE_CI_TEST non monté"
        exit 1
    fi

    export LANG=fr_FR.UTF-8

    if [[ -z "$VM_ID" ]]
    then
        ciPrintMsg "Pas de VM_ID : stop "
        exit 1
    fi

    ciPrintMsg "init à $(date "+%Y-%m-%d %H:%M:%S")"
    ciInitOutput

    /bin/rm -f "$VM_DIR/boot_process.log"
    if [ ! -f "$VM_DIR/contexualize.ok" ]
    then
        # si le service de contextualisation a eu un probleme, fait le quand même
        ciPrintMsg "ATTENTION : appel ciContextualizeMe depuis le daemon !!!!!!" >>"$VM_DIR/boot_process.log"
        ciContextualizeMe
    fi

    ############################################################################################
    # fichier semaphore pour signaler le 'start' daemon eole-ci-tests
    ############################################################################################
    echo "$$" >"$VM_DIR/daemon.start"

    ciPrintMsg "* ciAfficheProcess : $(date "+%Y-%m-%d %H:%M:%S")"
    ciAfficheProcess >>"$VM_DIR/boot_process.log" 2>&1
    echo "$?" >"$VM_DIR/boot_process.exit"

    ciPrintMsg "* ciWaitConteneurs : $(date "+%Y-%m-%d %H:%M:%S")"
    ciWaitConteneurs >"$VM_DIR/waitConteneurs.log"  2>&1
    echo "$?" >"$VM_DIR/waitConteneurs.exit"

    ciGetDirConfigurationMachine
    ciGetNamesInterfaces

    ciConfigurationMe

    if [ -n "${VM_MACHINE}" ]
    then
        if [[ "${VM_MACHINE}" =~ "gateway-" ]]
        then
            ciPrintConsole "* pas de lien gateway ici. aller dans le code de la gateway!"
        else
            ciPrintConsole "* Creation lien $VM_MACHINE dans $VM_DIR"
            cd "$DIR_OUTPUT_OWNER/" || exit 1
            unlink "$DIR_OUTPUT_OWNER/${VM_MACHINE}"
            ln -s "$VM_ID" "${VM_MACHINE}"
        fi
    fi

    ciSauvegardeCaMachine

    ############################################################################################
    # est ce que l'on doit lancer la boucle inifinie ?
    ############################################################################################
    RUN_BOUCLE_EXECUTION=non
    if [[ "$VM_DAEMON" != "once" ]]
    then
        RUN_BOUCLE_EXECUTION=oui
    fi

    if [[ "$VM_OWNER" =~ jenkins* ]]
    then
        RUN_BOUCLE_EXECUTION=oui
    fi

    if [[ "$VM_OWNER" = "ggrandgerard" ]]
    then
        RUN_BOUCLE_EXECUTION=oui
    fi

    if [[ "$RUN_BOUCLE_EXECUTION" = "oui" ]]
    then
        ciPrintMsg "* ciBoucleDExecution : $(date "+%Y-%m-%d %H:%M:%S")"
        ciBoucleDExecution
    else
        ciPrintMsg "* ciBoucleDExecution : pas d'excution ==> sortie"
    fi

    ciPrintMsg "ciStopDaemon : $(date "+%Y-%m-%d %H:%M:%S")"
    ciStopDaemon
    ciPrintMsg "Fin ciDeamonMain : $(date "+%Y-%m-%d %H:%M:%S")"
    return 0
}
export -f ciDaemonMain

export EOLE_CI_FUNCTIONS_LOADED=oui
if [[ "$(uname -o)" == "FreeBSD" ]]
then
    VM_IS_FREEBSD=1
else
    VM_IS_FREEBSD=0
fi
export VM_IS_FREEBSD
if [[ "$(uname -o)" == "GNU/Linux" ]]
then
    VM_IS_UBUNTU=1
else
    VM_IS_UBUNTU=0
fi
export VM_IS_UBUNTU

export VM_LAST_VERSIONMAJEUR=2.8.1
if [[ -z "$VM_DIR_EOLE_CI_TEST" ]]
then
    export VM_DIR_EOLE_CI_TEST=/mnt/eole-ci-tests
fi
