#!/bin/bash

AD_DOMAIN=$(CreoleGet ad_domain)
BASEDN="DC=${AD_DOMAIN//./,DC=}"
BASEDN3D="DC=${AD_DOMAIN//./,DC%3D}"
echo "BASEDN: $BASEDN"

echo "* mkdir -p /root/dsii/Conf/Acad/AD/"
mkdir -p /root/dsii/Conf/Acad/AD/

echo "* cp ConfUtilAafAd.sh /root/dsii/Conf/Acad/AD/ConfUtilAafAd.sh"
cp ConfUtilAafAd.sh /root/dsii/Conf/Acad/AD/ConfUtilAafAd.sh
chmod +x /root/dsii/Conf/Acad/AD/ConfUtilAafAd.sh

echo "* Création groupes.ldif dans /root/dsii/Conf/Acad/AD/groupes.ldif"
sed "s/DC=SDOMAINE,DC=ac-rennes,DC=fr/$BASEDN/" groupes.ldif >/root/dsii/Conf/Acad/AD/groupes.ldif
cat /root/dsii/Conf/Acad/AD/groupes.ldif

echo "* CreationOuDefault.sh"
bash CreationOuDefault.sh

echo "* CreationArborescenceAd.sh"
bash CreationArborescenceAd.sh

echo "* fin"