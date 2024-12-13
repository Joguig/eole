#!/bin/bash
#####################################################################
# Script : CreationArborescenceAd.sh                                #
# Creation dossier pour redirection et affectation des utilisateurs #
# dans les bonnes OU et plannification dans la crontab              #
# Creation : 20/04/2020                                             # 
# Moncef ZIANI - Rectorat de Rennes - DSII-POPSIE                   #
#####################################################################
#################################################################
# Modifications                                                 #
#################################################################
#                                                               #
#                                                               #
#################################################################
#           Déclaration des répertoires et fichiers             #
#################################################################
#RepSources="/root/dsii/Conf/Acad/AD"                             
#################################################################
# Variables                                                     #
#################################################################
fqdndom=$(CreoleGet ad_domain)
BASEDN="DC=${fqdndom//./,DC=}"
#rne=$(CreoleGet numero_etab)
#ips1peda=$(CreoleGet adresse_ip_eth0)
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

##############Liste des utilisateurs du domaine#################"
ldapsearch -xLLL cn=DomainUsers memberUid|cut -d ":" -f 2 |cut -d " " -f2 |sed "1,2d" |sed '/^admin$/d'|sed '$d' | sort > /root/dsii/Conf/Acad/AD/UtilisateursDuDomaine

clear
EchoVert "#############################################################################################"
EchoVert "#   Création des dossiers nécessaires à la redirection dans le perso de chaque utilisateur  #"
EchoVert "#############################################################################################"
echo
while read -r line
        do
            if [ ! -d "/home/adhomes/$line/perso/Bureau" ]
            then
                mkdir  "/home/adhomes/$line/perso/Bureau"
                chown "$line":root "/home/adhomes/$line/perso/Bureau/"
            fi
            if [ ! -d "/home/adhomes/$line/perso/Musique" ]
            then
                mkdir  "/home/adhomes/$line/perso/Musique"
                chown "$line":root "/home/adhomes/$line/perso/Musique/"
            fi
            if [ ! -d "/home/adhomes/$line/perso/Images" ]
            then
                mkdir  "/home/adhomes/$line/perso/Images"
                chown "$line":root "/home/adhomes/$line/perso/Images/"
            fi
            if [ ! -d "/home/adhomes/$line/perso/Vidéos" ]
            then
                mkdir  "/home/adhomes/$line/perso/Vidéos"
                chown "$line":root "/home/adhomes/$line/perso/Vidéos/"
            fi
            if [ ! -d "/home/adhomes/$line/perso/Documents" ]
            then
                mkdir  "/home/adhomes/$line/perso/Documents"
                chown "$line":root "/home/adhomes/$line/perso/Documents/"
            fi
            if [ ! -d "/home/adhomes/$line/perso/Téléchargements" ]
            then
                mkdir "/home/adhomes/$line/perso/Téléchargements"
                chown "$line":root "/home/adhomes/$line/perso/Téléchargements/"
            fi
        done < /root/dsii/Conf/Acad/AD/UtilisateursDuDomaine

EchoVert "#########################################################"
EchoVert "#            Création des dossiers terminés             #"
EchoVert "#########################################################"
sleep 2
clear
EchoVert "#########################################################"
EchoVert "#          Création des OU Classes dans l'AD            #"
EchoVert "#########################################################"
echo
for clas in $(ldapsearch -xLLL | grep "displayName: profs-*" | cut -d "-" -f2 |sort) ;
do
	cat >> /tmp/Classes.ldif <<EOF
dn: OU=$clas,OU="Eleves",OU="Utilisateurs du Domaine",$BASEDN
changetype: add
objectClass: top
objectClass: organizationalunit

EOF
done
export LDB_URL=/var/lib/samba/private/sam.ldb
scp /tmp/Classes.ldif root@addc:/tmp/
$CONTAINER_EXEC ldbadd /tmp/Classes.ldif
echo
EchoVert "#########################################################"
EchoVert "#      Création des OU Classes dans l'AD terminées      #"
EchoVert "#########################################################"
sleep 2
clear
EchoVert "#########################################################"
EchoVert "# Déplacement des élèves dans les OU Classes dans l'AD  #"
EchoVert "#########################################################"
echo
ldapsearch -xLLL | grep "displayName: profs-*" | cut -d "-" -f2  | sort > /tmp/Classes.gr

while read -r line
        do
	     for util in $(ldapsearch -xLLL cn="$line" memberUid|cut -d ":" -f 2 |cut -d " " -f2 |sed "1,2d" |  sed '$d' | sort) ;do
         $CONTAINER_EXEC samba-tool user move "$util" "OU=\"$line\",OU=\"Eleves\",OU=\"Utilisateurs du Domaine\",$BASEDN"
         done
        done < /tmp/Classes.gr
echo
EchoVert "################################################"
EchoVert "#        Déplacement des élèves terminé        #"
EchoVert "################################################"
sleep 2
clear
EchoVert "#######################################################"
EchoVert "#  Déplacement des professeurs dans l'OU Professeurs  #"
EchoVert "#######################################################"
echo
ldapsearch -xLLL cn=professeurs memberUid|cut -d ":" -f 2 |cut -d " " -f2 |sed "1,2d" |sed '/^admin$/d'|sed '$d' | sort > /tmp/ComptesProfesseurs

while read -r line
        do
         $CONTAINER_EXEC samba-tool user move "$line" "OU=\"Professeurs\",OU=\"Utilisateurs du Domaine\",$BASEDN"
        done < /tmp/ComptesProfesseurs
echo
EchoVert "########################################"
EchoVert "#  Déplacement des professeurs terminé  #"
EchoVert "########################################"
sleep 2
clear
EchoVert "###########################################################"
EchoVert "# Déplacement des administratifs dans l'OU Administratifs #"
EchoVert "###########################################################"
echo
ldapsearch -xLLL cn=administratifs memberUid|cut -d ":" -f 2 |cut -d " " -f2 |sed "1,2d" |sed '/^admin$/d'|sed '$d' | sort > /tmp/ComptesAdministratifs

while read -r line
        do
         $CONTAINER_EXEC samba-tool user move "$line" "OU=\"Professeurs\",OU=\"Utilisateurs du Domaine\",$BASEDN"
        done < /tmp/ComptesAdministratifs
echo
EchoVert "############################################"
EchoVert "#  Déplacement des administratifs terminé  #"
EchoVert "############################################"
sleep 2
clear

EchoVert "###############################################################"
EchoVert "#  Planification de la mise à jour l'AD suite AAF Mise à jour #"
EchoVert "###############################################################"
echo
echo -e "30 6  *  *  *      /root/dsii/Conf/Acad/AD/ConfUtilAafAd.sh" >> /tmp/CronConf
crontab -u root /tmp/CronConf
service cron restart
echo
EchoVert "############################"
EchoVert "#  Planification terminée  #"
EchoVert "############################"
sleep 2
rm -rf /tmp/CronConf
rm -rf /tmp/Comptes*
rm -rf /tmp/Classes*
