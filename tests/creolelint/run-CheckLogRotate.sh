#!/bin/bash

#########################################################################################################
#
# Check Dpkg Detail
#
#########################################################################################################
function ciCheckLogRotate()
{
    ciPrintConsole "CheckLogRotate: début"
    if ciVersionMajeurApres "2.5.1"
    then
        ciPrintMsgMachine "Test logrotate"
        /bin/rm -f /tmp/logrotate.log
        logrotate -fv /etc/logrotate.conf >/tmp/logrotate1.log 2>&1

        # suite https://github.com/logrotate/logrotate/blob/master/ChangeLog.md ignorer la cas 'prepend error...'
        grep -v "error: Compressing program wrote following message to stderr" </tmp/logrotate1.log >/tmp/logrotate.log
        # erreur "ubuntu-pro-client"
        grep -v "ubuntu-pro-client" </tmp/logrotate1.log >/tmp/logrotate.log

        if [ -s /tmp/logrotate.log ]
        then
            local TROUVE=0
            if grep "error:" /tmp/logrotate.log >/tmp/logrotate.grep
            then
                cat /tmp/logrotate.grep
                if grep -q 'already exists, skipping rotation' /tmp/logrotate.grep
                then
                    ciSignalWarning "'skipping' détecté dans test du logrotate"
                elif ciVersionMajeurEgal "2.5.2" && [[ "$VM_MODULE" == "amon" ]]
                then
                    ciSignalHack "${VM_MODULE}-${VM_VERSIONMAJEUR} ignore log.smbd logrotate error"
                elif ciVersionMajeurEgal "2.6.0" && [[ "$VM_MODULE" == "seth" ]]
                then
                    ciSignalHack "${VM_MODULE}-${VM_VERSIONMAJEUR} ignore log.winbindd logrotate error"
                else
                    ciSignalAlerte "'error:' détecté dans test du logrotate"
                    TROUVE=1
                fi
            else
                ciPrintMsgMachine "Test logrotate : logrotate.log existe, sans 'error'"
            fi

            if grep "Ignoring " /tmp/logrotate.log >/tmp/logrotate.grep
            then
                cat /tmp/logrotate.grep
                ciSignalAlerte "'Ignoring ' détecté dans test du logrotate"
                TROUVE=1
            else
                ciPrintMsgMachine "Test logrotate : logrotate.log existe, sans 'Ignoring'"
            fi

            if grep "warning:" /tmp/logrotate.log >/tmp/logrotate.grep
            then
                cat /tmp/logrotate.grep
                ciSignalWarning "'warning;' détecté dans test du logrotate"
                TROUVE=1
            fi
            if [ "$TROUVE" == "1" ]
            then
                # sauvegarde pour enregistrement dans jenkins
                /bin/cp /tmp/logrotate.log "$VM_DIR/logrotate.log"
                ciPrintErreurAndExit "Test du logrotate génère 'error', 'Ignoring' ou 'warning'"
            else
                ciPrintMsgMachine "Test logrotate : logrotate.log existe, sans 'error', Ignore ou warning !"
            fi
        else
            ciPrintMsgMachine "Test logrotate : logrotate.log vide ==> OK pas d'erreur"
        fi
        [ -f /tmp/logrotate.grep ] && /bin/rm -f /tmp/logrotate.grep
        [ -f /tmp/logrotate.log ] && /bin/rm -f /tmp/logrotate.log
    fi
    ciPrintConsole "CheckLogRotate: OK"
}

ciCheckLogRotate

