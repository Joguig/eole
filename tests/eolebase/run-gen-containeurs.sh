#!/bin/bash

echo "* set Proxy *"
ciSetHttpProxy

echo "* run-gen-containeurs.sh : Début"

dpkg -l eole-exim-pkg
echo "* eole-exim-pkg : $?"

R=$(CreoleGet mode_conteneur_actif)
echo "* mode_conteneur_actif=$R (non attendu)"

echo "* apt-eole install eole-lxc-controller ssmtp"
apt-eole install eole-lxc-controller ssmtp
ciCheckExitCode $?

R=$(CreoleGet mode_conteneur_actif)
echo "* mode_conteneur_actif=$R (oui attendu)"

export VM_CONTAINER=oui
ciMonitor gen_conteneurs
ciCheckExitCode $?

wc -l /var/log/apt-cacher-ng/apt-cacher.log

dpkg -l eole-exim-pkg
echo "* eole-exim-pkg : $?"

CreoleGet --groups

ciCopieConfigEol
ciCheckExitCode $?

echo "* Instance default"
export CONFIGURATION=default
ciInstance
ciCheckExitCode $? "instance default"

echo "* run-gen-containeurs.sh : Fin"
exit 0