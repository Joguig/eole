#!/bin/bash

function doAgent()
{
   CONTEXT="${1}"
   if [ ! -f "$CONTEXT" ]
   then
      return 1
   fi

   unset AGENT_JENKINS
   unset IP_GW
   # shellcheck disable=SC1090
   source "$CONTEXT"
            
   if [ "$AGENT_JENKINS" != "oui" ]
   then
      return 1
   fi

   echo "$CONTEXT"
   #cat "$CONTEXT"
   IP_GW="192.168.230.$IP_ONE"
   local OWNER
   OWNER="$(basename "$CONTEXT" .sh)"
   OWNER="${OWNER/routeur_/}"
   echo "  agent?: $AGENT_JENKINS"
   echo "  ip: $IP_GW"
   echo "  owner: $OWNER"
   #ssh-keygen -f "/home/gilles/.ssh/known_hosts" -R "$IP_GW"
   ssh -o BatchMode=yes -o StrictHostKeyChecking=false "root@$IP_GW" "/mnt/eole-ci-tests/configuration/gateway/configure_routeur_ubuntu_dnsmasq.sh"
}

#for agent in jenkins jenkins1 jenkins2 jenkins3 jenkins4 jenkins5 jenkins6 jenkins7 jenkins7 jenkins8 ggrangdreard
for agent in /mnt/eole-ci-tests/configuration/gateway/routeur_*.sh
do
   doAgent "$agent"
done
