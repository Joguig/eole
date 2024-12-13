#!/bin/bash
USER_A_UTILISER="$1"

ciMajAuto

ciAptEole eole-workstation

ciMonitor reconfigure

echo "* Désactive home profile '$USER_A_UTILISER'"
efface-homeprofile.sh "$USER_A_UTILISER"

echo "* Inject BGInfo"
inject-bginfo.sh

echo "* samba-tool ntacl sysvolcheck"
samba-tool ntacl sysvolcheck

echo "* ls -lR /home/sysvol/domseth.ac-test.fr/Policies/"
ls -lR /home/sysvol/domseth.ac-test.fr/Policies/

echo "* ls -lR /usr/share/eole/workstation"
ls -lR /usr/share/eole/workstation

echo "* cat /usr/share/eole/workstation/installMinion.conf"
cat /usr/share/eole/workstation/installMinion.conf

echo "* check installMinion.ps1"
PATH_GPO_INSTALLMINION="$(find /home/sysvol/domseth.ac-test.fr/Policies/ -name installMinion.ps1)"
echo "< = $PATH_GPO_INSTALLMINION"
echo "> = /usr/share/eole/workstation/installMinion.ps1"
if ! diff "$PATH_GPO_INSTALLMINION" /usr/share/eole/workstation/installMinion.ps1
then
    echo "WARNING: Diff installMinion.ps1 / GPO installMinion.ps1"
fi
