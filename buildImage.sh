#!/bin/bash -x
# ---------------------------------------------------------------------------------
# EoleCi
# Copyright © 2014-2023 Pôle de Compétence Logiciels Libres EOLE <eole@ac-dijon.fr>
# 
# LICENCE PUBLIQUE DE L'UNION EUROPÉENNE v. 1.2 :
# in french: https://joinup.ec.europa.eu/sites/default/files/inline-files/EUPL%20v1_2%20FR.txt
# in english https://joinup.ec.europa.eu/sites/default/files/custom-page/attachment/2020-03/EUPL-1.2%20EN.txt
# ---------------------------------------------------------------------------------


# arg1 : iso
# arg2 : repertoire contenant le fichier téléchargé
# arg3 : url
# arg4 : architecture cible
# ...
ISO=$1
REPERTOIRE=$2
URL=$3
ARCHITECTURE=$4
FICHIER=$2/$1

echo "$PWD"
#env |sort

case "$ISO" in
    CentOS-7-minimal-amd64.iso)
        wget -O "$FICHIER" "$URL"
        if [ ! -f "$FICHIER" ]
        then
            echo "$FICHIER : manquant, stop!"
            exit 1
        fi 
        echo "Prepare $ISO"
        [ ! -d "$REPERTOIRE/tmp/" ] && mkdir "$REPERTOIRE/tmp/"
        [ ! -d /media/cdrom/ ] && mkdir /media/cdrom/
        mount -o loop -t iso9660 "$FICHIER" /media/cdrom/
        cp -a /media/cdrom/. "$REPERTOIRE/tmp/"
        umount /media/cdrom/
        cp -a "$PWD/EoleNebula/windows/Autounattend-$ARCHITECTURE.xml" "$REPERTOIRE/tmp/Autounattend.xml"
        ls -lR "$REPERTOIRE/tmp"
        mkisofs -l -input-charset iso8859-1 -o "$REPERTOIRE/$ISO-updated" "$REPERTOIRE/tmp"
        rm "$REPERTOIRE/$ISO"
        mv "$REPERTOIRE/$ISO-updated" "$REPERTOIRE/$ISO"
        ;;
        
    virtio-win-x86.iso)
        wget -O "$FICHIER" "$URL"
        if [ ! -f "$FICHIER" ]
        then
            echo "$FICHIER : manquant, stop!"
            exit 1
        fi 
        echo "Prepare $ISO"
        [ ! -d "$REPERTOIRE/tmp/" ] && mkdir "$REPERTOIRE/tmp/"
        [ ! -d /media/cdrom/ ] && mkdir /media/cdrom/
        mount -o loop -t iso9660 "$FICHIER" /media/cdrom/ 
        cp -a /media/cdrom/. "$REPERTOIRE/tmp/"
        umount /media/cdrom/
        cp -a "$PWD/EoleNebula/windows/Autounattend-$ARCHITECTURE.xml" "$REPERTOIRE/tmp/Autounattend.xml"
        ls -lR "$REPERTOIRE/tmp"
        mkisofs -l -input-charset iso8859-1 -o "$REPERTOIRE/$ISO-updated" "$REPERTOIRE/tmp"
        rm "$REPERTOIRE/$ISO"
        mv "$REPERTOIRE/$ISO-updated" "$REPERTOIRE/$ISO"
        ;;

    Windows*)
        # le fichier doit avoir été copier ici
		SOURCE="/tmp/$URL"
        if [ ! -f "$SOURCE" ]
        then
			SOURCE="$REPERTOIRE/$URL"
        	if [ ! -f "$SOURCE" ]
        	then
               echo "$SOURCE : manquant, stop!"
            	exit 1
        	fi 
        fi 
        #rm -f "$FICHIER"
        ln "$SOURCE" "$FICHIER"
        ;;
  
    *)
        if [ ! -f "$FICHIER" ]
        then
            echo "image $1 : wget"
            # gia : 1 point / mega, 32 M par ligne
            wget --progress=dot:giga:noscroll -O "$FICHIER" "$URL"
            if [ ! -f "$FICHIER" ]
            then
                echo "$FICHIER : manquant, stop!"
                exit 1
            fi
            if [ ! -s "$FICHIER" ]
            then
                echo "$FICHIER : vide, stop!"
                exit 1
            fi
        else
            echo "image $1 : deja presente"
            exit 0
        fi 
        ;;
esac
exit 0 
