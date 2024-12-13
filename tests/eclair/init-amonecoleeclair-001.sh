#!/bin/bash
echo "Début $0"

set -x

bash enregistrement-amon-si-besoin.sh "$1"

echo "* configuration du compte admin"
CreoleRun 'smbldap-usermod -s/bin/bash admin' partage

echo "* configuration du compte prof.6a"
CreoleRun 'smbldap-usermod -s/bin/bash prof.6a' partage

echo "* definition mot de passe du compte prof.6a"
CreoleRun 'echo "prof.6a" | smbldap-passwd -p prof.6a' partage

echo "* configuration du compte 6a.02"
CreoleRun 'smbldap-usermod -s/bin/bash 6a.02' partage

echo "* definition mot de passe du compte 6a.02 = Eole12345!"
CreoleRun 'echo "Eole12345!" | smbldap-passwd -p 6a.02' partage

echo "* scp lts.conf ltspserver:/var/lib/tftpboot/ltsp/default/lts.conf"
scp lts.conf ltspserver:/var/lib/tftpboot/ltsp/default/lts.conf

echo "* ssh ltspserver cat /var/lib/tftpboot/ltsp/default/lts.conf"
ssh ltspserver cat /var/lib/tftpboot/ltsp/default/lts.conf

echo "* ls -l /home apres instance"
ls -l /home

echo "Fin $0"
