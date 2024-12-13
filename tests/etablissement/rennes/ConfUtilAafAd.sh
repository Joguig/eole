#!/bin/bash
#################################################################
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
fqdndom=$(CreoleGet ad_domain)
BASEDN="DC=${fqdndom//./,DC=}"
#rne=$(CreoleGet numero_etab)
#ips1peda=$(CreoleGet adresse_ip_eth0)
#rnemin="${rne,,}"
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
CONTAINER_EXEC='lxc-attach -n addc --'

##############Liste des utilisateurs du domaine#################"
ldapsearch -xLLL cn=DomainUsers memberUid|cut -d ":" -f 2 |cut -d " " -f2 |sed "1,2d" |sed '/^admin$/d'| sed '$d' | sort > /root/dsii/Conf/Acad/AD/UtilisateursDuDomaine2

val3=$(wc -l /root/dsii/Conf/Acad/AD/UtilisateursDuDomaine2 |cut -d " " -f1)
val2=$(wc -l /root/dsii/Conf/Acad/AD/UtilisateursDuDomaine |cut -d " " -f1)

val4=$(( val3 - val2 ))

if [ "$val4" -eq "0" ]
then
    exit
elif [ "$val4" -lt "0" ]
then
    diff /root/dsii/Conf/Acad/AD/UtilisateursDuDomaine /root/dsii/Conf/Acad/AD/UtilisateursDuDomaine2 |grep '<' | cut -d " " -f 2 | sort > /tmp/UtilEnMoins
    while read -r line
        do
         $CONTAINER_EXEC samba-tool user delete "$line"
        done < /tmp/UtilEnMoins
    cp /root/dsii/Conf/Acad/AD/UtilisateursDuDomaine2 /root/dsii/Conf/Acad/AD/UtilisateursDuDomaine
elif [ "$val4" -gt "0" ]
then
    diff /root/dsii/Conf/Acad/AD/UtilisateursDuDomaine2 /root/dsii/Conf/Acad/AD/UtilisateursDuDomaine |grep '<' | cut -d " " -f 2 | sort > /tmp/UtilEnPlus
    while read -r line
        do
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
            if [ "$(ldapsearch -xLLL uid=\""$line"\" | grep ENTPersonProfils | cut -d ":" -f 2 | cut -d " " -f2)" = "enseignant" ]
            then
                $CONTAINER_EXEC samba-tool user move "$line" "OU=\"Professeurs\",OU=\"Utilisateurs du Domaine\",$BASEDN"

            elif [ "$(ldapsearch -xLLL uid=\""$line"\" | grep ENTPersonProfils | cut -d ":" -f 2 | cut -d " " -f2)" = "administratif" ]
            then
                $CONTAINER_EXEC samba-tool user move "$line" "OU=\"Professeurs\",OU=\"Utilisateurs du Domaine\",$BASEDN"

            elif [ "$(ldapsearch -xLLL uid=\""$line"\" | grep ENTPersonProfils | cut -d ":" -f 2 | cut -d " " -f2)" = "eleve" ]
            then
                divi=$(ldapsearch -xLLL uid="$line" | grep Divcod | cut -d ":" -f 2 |cut -d " " -f 2)
                $CONTAINER_EXEC samba-tool user move "$line" "OU=\"$divi\",OU=\"Eleves\",OU=\"Utilisateurs du Domaine\",$BASEDN"
            fi
       done < /tmp/UtilEnPlus
mv -f /root/dsii/Conf/Acad/AD/UtilisateursDuDomaine /root/dsii/Conf/Acad/AD/UtilisateursDuDomaine_bak
ldapsearch -xLLL cn=DomainUsers memberUid|cut -d ":" -f 2 |cut -d " " -f2 |sed "1,2d" |sed '/^admin$/d'| sed '$d' | sort > /root/dsii/Conf/Acad/AD/UtilisateursDuDomaine
fi
