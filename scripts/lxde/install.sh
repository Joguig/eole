#!/bin/bash

apt-get install -y cups
apt-get install -y libnss-ldapd libpam-ldapd

uri ldap://192.168.0.26/
base: o=gouv,c=fr
services: group + passwd + shadow

#ATTENTION: l'import sconet n'autorise pas l'acces linux (shell linux est à Faux)

#Ajouter dans /etc/pam.d/common-account
session    required   pam_mkhomedir.so skel=/etc/skel/ umask=0022