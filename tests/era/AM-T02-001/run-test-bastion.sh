#!/bin/bash

#arg :
# 1: fichier modele xml (sans .xml)

HOME_TEST=$VM_DIR_EOLE_CI_TEST/tests/era/AM-T02-001
 
if [ ! -f /tmp/iptables-base ]
then
    echo "ERREUR: lancer init-test-bastion.sh !"
    exit 1
fi

if [ ! -f /tmp/ipsets-base ]
then
    echo "ERREUR: lancer init-test-bastion.sh avant !"
    exit 1
fi

if [ -f "$HOME_TEST/$1.xml" ] 
then
    cp "$HOME_TEST/$1.xml" "/usr/share/era/modeles/$1.xml" 
    result=$?  
    echo "cp $1 = $result"
else
    echo "fichier $1 manque"
    exit 0
fi

if [ ! -f "/usr/share/era/modeles/$1.xml" ] 
then
    echo "/usr/share/era/modeles/$1.xml : n'existe pas "
    exit 1
fi

CreoleSet type_amon "$1"
result=$?  
echo "Creole Set $1 = $result"

ERA_DEBUG=1 service bastion restart
result="$?"
echo "service bastion = $result"

iptables-save | grep -Ev '^# ' | sed -e 's/\[.*\]/[]/' >/tmp/iptables
diff /tmp/iptables /tmp/iptables-base >/tmp/iptables-diff
result=$?
echo "diff base = $result"

if [ ! -f "$HOME_TEST/$1.iptables" ]
then
    echo "enregistrement du diff dans $1.iptables"
    cp /tmp/iptables-diff "$HOME_TEST/$1.iptables"
else
    grep -E '^[<>] ' </tmp/iptables-diff >/tmp/iptables-diff.rules
    grep -E '^[<>] ' <"$HOME_TEST/$1.iptables" >/tmp/iptables-base.rules
    diff /tmp/iptables-diff.rules /tmp/iptables-base.rules
    result=$?  
    if [ "$result" == "0" ]
    then    
        echo "Pas de difference pour iptables"
    else
        cat /tmp/iptables-diff.rules
        echo "TEST EN ERREUR"
        exit 1
    fi 
fi

ipset save >/tmp/ipsets
diff /tmp/ipsets /tmp/ipsets-base >/tmp/ipsets-diff
result=$?  
echo "ipsets diff base = $result"

if [ ! -f "$HOME_TEST/$1.ipsets" ] 
then
    echo "enregistrement du diff dans $1.ipsets"
    cp /tmp/ipsets-diff "$HOME_TEST/$1.ipsets"
else
    diff /tmp/ipsets-diff "$HOME_TEST/$1.ipsets"
    result=$?  
    if [ "$result" == "0" ]
    then    
        echo "Pas de difference pour ipsets"
    else
        cat /tmp/ipsets-diff
        echo "TEST EN ERREUR"
        exit 1
    fi 
fi

echo "TEST OK"
exit 0