#!/bin/bash
echo "Début $0"

echo "* install eole-nfs et eole-gaspacho"
apt-eole install eole-nfs eole-gaspacho

echo "* activation tftp"
# Attention: le tftp est activé mais c'est celui de l'éclair qui répondra
CreoleSet adresses_ip_clients_nfs 10.1.3.20
CreoleSet activer_tftp oui
CreoleSet adresse_ip_tftp 10.1.3.20
if [ "$1" \< "2.6.1" ]
then
	CreoleSet chemin_fichier_pxe /pxelinux.0
else
	CreoleSet chemin_fichier_pxe /default/pxelinux.0
fi

echo "* configuration du compte admin"
smbldap-usermod -s/bin/bash admin

echo "* configuration du compte prof.6a"
smbldap-usermod -s/bin/bash prof.6a

echo "* definition mot de passe du compte prof.6a"
echo "prof.6a" | smbldap-passwd -p prof.6a

echo "* configuration du compte 6a.02"
smbldap-usermod -s/bin/bash 6a.02

echo "* definition mot de passe du compte 6a.02 = Eole12345!"
echo "Eole12345!" | smbldap-passwd -p 6a.02

echo "* reconfigure"
reconfigure

echo "* sauvegarde CA machine"
ciSauvegardeCaMachine

echo "Si gaspacho est activé sur le serveur Eclair"
echo "il faut copier le fichier /etc/ssl/certs/ca_local.crt du Scribe"
echo "vers le fichier /usr/local/share/ca-certificates/gaspacho-server.crt sur Eclair"
echo "il faudra reconstruire l'image sur Eclair avec /usr/share/eole/postservice/00-ltsp instance"
echo "Fin $0"
