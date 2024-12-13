#!/bin/bash
FICHIERTEMP=/tmp/$$

find /mnt/eole-ci-tests/configuration/gateway -name 'routeur_*' >"$FICHIERTEMP"
cat "$FICHIERTEMP"
while read -r ROUTEUR_SH
do
    unset IP_ONE
    unset AGENT_JENKINS
    # shellcheck disable=SC1091,SC1090
    . "$ROUTEUR_SH"
    export IP_ONE 
    export AGENT_JENKINS 
    if [[ "$AGENT_JENKINS" == "oui" ]]
    then
       IP_GW="192.168.230.$IP_ONE"
       if ping -c 1 "$IP_GW" >/dev/null 2>&1
       then
           echo "$ROUTEUR_SH"
           ssh-keygen -f ~/.ssh/known_hosts -R "$IP_GW"
           #ssh -o BatchMode=yes -o StrictHostKeyChecking=false "root@$IP_GW" "systemctl restart EoleCiTestsDaemon" 0</dev/null
           ssh -o BatchMode=yes -o StrictHostKeyChecking=false "root@$IP_GW" "systemctl status EoleCiTestsDaemon" 0</dev/null
           echo "GW $?"
       fi
    fi
done <"$FICHIERTEMP"
