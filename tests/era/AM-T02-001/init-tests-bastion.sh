#!/bin/bash

MODEL_BASE=4zones

[ -f /tmp/iptables-base ] && rm /tmp/iptables-base
[ -f /tmp/ipsets-base ] && rm ipsets-base
[ ! -f ./$MODEL_BASE.xml ] && cp /usr/share/era/modeles/$MODEL_BASE.xml .

diff /usr/share/era/modeles/$MODEL_BASE.xml ./$MODEL_BASE.xml >/tmp/modele-initial-diff
result=$?  
echo "modele-initial-diff = $result"
result=$?  
if [ "$result" != "0" ]
then
    cat /tmp/modele-initial-diff
    echo "Le modele $MODEL_BASE n'est pas le même que celui mémorisé dans le test"
    echo "TEST EN ERREUR"
    exit 1
fi 

CreoleSet type_amon $MODEL_BASE
result=$?  
echo "Creole Set $MODEL_BASE = $result"
if [ "$result" != "0" ]
then
    echo "ERREUR : erreur bastion ==> stop"
    exit 1
fi

service bastion restart
result=$?
echo "service bastion = $result"
if [ "$result" != "0" ]
then
    echo "ERREUR : erreur bastion ==> stop"
    exit 1
fi
    
iptables-save |grep -Ev '^# ' |sed -e 's/\[.*\]/[]/' >/tmp/iptables-base
if [ ! -f /tmp/iptables-base ]
then
    echo "ERREUR : impossible de créer /tmp/iptables-base"
    exit 1
fi

ipset save >/tmp/ipsets-base
if [ ! -f /tmp/ipsets-base ]
then
    echo "ERREUR : impossible de créer /tmp/ipsets-base"
    exit 1
fi
exit 0
exit 0