#!/bin/bash

CreoleSet system_mail_from "${MAIL_UTILISATEUR}"
CreoleSet system_mail_to "${MAIL_UTILISATEUR}"
CreoleGet --list |grep _mail_

ciMonitor reconfigure

echo "* envoi mail "

if ciVersionMajeurAvant "2.7.0"
then
    mail -s "Test Mail from $VM_OWNER pour $VM_VERSIONMAJEUR" "${MAIL_UTILISATEUR}" <<EOF
essai $(date)
.
EOF
else
    mail -s "Test Mail from $VM_OWNER pour $VM_VERSIONMAJEUR" -- "${MAIL_UTILISATEUR}" <<EOF
essai $(date)
.

EOF
fi
