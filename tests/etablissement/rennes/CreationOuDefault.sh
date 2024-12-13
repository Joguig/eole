#!/bin/bash
#################################################################
# Script : CreationOuDefault.sh                                 #
# Creation des OU Professeurs, Eleves et Administratifs         #
# Creation : 20/04/2020                                         # 
# Moncef ZIANI - Rectorat de Rennes - DSII-POPSIE               #
#################################################################
# Modifications                                                 #
#################################################################
#                                                               #   
#                                                               # 
#################################################################
#           Déclaration des répertoires et fichiers             #
#################################################################
#                                                               #
#################################################################
# Variables                                                     #
#################################################################
#fqdndom=$(CreoleGet ad_domain)
#rne=$(CreoleGet numero_etab)
#rnemin=${rne,,}
#TYPEETAB="${rne:0:3}"
#DOM="${rnemin:1:8}"
#################################################################
#               Declaration des fonctions                       #
#################################################################        
#shellcheck disable=SC1091
. /usr/lib/eole/ihm.sh

#shellcheck disable=SC1091
. /usr/lib/eole/eolead.sh

#shellcheck disable=SC1091,SC1090
. "$CONTAINER_ROOTFS/etc/eole/samba4-vars.conf"
#AD_HOST_IP=$CONTAINER_IP
CONTAINER_EXEC='lxc-attach -n addc --'
##################################################################

EchoVert "#########################################################"
EchoVert "#              Ajout des \"OU\" par default               #"
EchoVert "#########################################################"

sed "s/SDOMAINE/$DOM/g" /root/dsii/Conf/Acad/AD/groupes.ldif > /tmp/groupes.ldif

export LDB_URL=/var/lib/samba/private/sam.ldb
scp /tmp/groupes.ldif root@addc:/tmp/
$CONTAINER_EXEC ldbadd /tmp/groupes.ldif

EchoVert "#########################################################"
EchoVert "#         	      \"OU\" rajoutées  		          #"
EchoVert "#########################################################"

