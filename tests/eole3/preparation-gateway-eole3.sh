#!/bin/bash

MACHINE="$1"
if [ -z "$MACHINE" ]
then
    echo "MACHINE inconnu !"
    exit 1
fi

REALM="$2"
if [ -z "$REALM" ]
then
    echo "REALM inconnu !"
    exit 1
fi

ls -l "$VM_DIR_EOLE_CI_TEST/output/$VM_OWNER"

REPERTOIRE_MACHINE="$VM_DIR_EOLE_CI_TEST/output/$VM_OWNER/$MACHINE"
if [ ! -d "$REPERTOIRE_MACHINE" ]
then
    echo "Repertoire $REPERTOIRE_MACHINE manquant, stop !"
    # si on vient ici, c'est que le service executeur EoleCiTestService est en erreur sur le pc.... et qu'il n'a pas crée ce dossier !
    # il est fort probable que le fichier 'ip' n'est pas disponible nom plus.
    # donc on s'arrete !
    exit 1
fi 
IP_K8S=$(tr -d '\r\n' <"$REPERTOIRE_MACHINE/ip" )
if [ -z "${IP_K8S}" ]
then
    echo "fichier $REPERTOIRE_MACHINE/ip ne contient pas l'IP de la machine $1!"
    exit 1
fi

echo "* déclare forward ${REALM} vers ${IP_K8S}"
/bin/rm -rf "/etc/dnsmasq.d/k3d.conf"
cat > "/etc/dnsmasq.d/k3d.conf"  <<EOF  
address=/.${REALM}/${IP_K8S}
EOF

echo "* cat /etc/dnsmasq.d/k3d.conf"
cat "/etc/dnsmasq.d/k3d.conf"

echo "* Stop dnsmasq.service"
systemctl stop dnsmasq.service

echo "* Test dnsmasq.service"
if ! dnsmasq --test
then
    echo "ERREUR: erreur dnsmasq.conf"
    /bin/rm "/etc/dnsmasq.d/k3d.conf"
fi

echo "* Start dnsmasq.service"
systemctl start dnsmasq.service

echo "* Vérification du Forward de la GW vers le K8S "
dig @192.168.0.1 +short "auth.${REALM}"
