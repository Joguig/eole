#!/bin/bash

# shellcheck disable=SC1091,SC1090
source /root/getVMContext.sh

if ciVersionMajeurAvant "2.9.0"
then
    apt-get install -y mongo-tools
else
    apt-get install -y mongodb-org-tools
fi

[ -f /var/lib/eole/reports/importaaf.log ] && /bin/rm -f /var/lib/eole/reports/importaaf.log

if ciVersionMajeurAvant "2.7.1"
then
   ls -l /etc/salt/
else
   ls -l /etc/ead3/salt/
fi

#lancement de aaf-complet
echo "* zip depuis dataset/AAF-VE1901/complet/*.xml"
cd "$VM_DIR_EOLE_CI_TEST"/dataset/AAF-VE1901/ || exit 1
tmpaafdir="/tmp/complet"
rm -rf $tmpaafdir
cp -a complet $tmpaafdir

echo "$0 : Ajout de prénoms à un élève avec des doublons"
sed -e "s@<attr name=\"ENTPersonAutresPrenoms\"><value>Enzo</value></attr>@<attr name=\"ENTPersonAutresPrenoms\"><value>Enzo</value><value>Charles</value><value>Enzo</value></attr>@" -i "$tmpaafdir"/EnvOLE_ENT2DVA_0940072T_Complet_20180830_Eleve_0000.xml

echo "$0 : Suppression de classes à un établissement"
sed -e "s@<value>5C\$5EME\$10110001110</value>@@g" -i "$tmpaafdir"/EnvOLE_ENT2DVA_0940072T_Complet_20180830_EtabEducNat_0000.xml

echo "$0 : Ajout de caractères accentués sur des matières"
sed -e "s@ALLEMAND@\&#201;GYPTIEN@g" -i "$tmpaafdir"/EnvOLE_ENT2DVA_0940072T_Complet_20180830_Eleve_0000.xml
sed -e "s@ALLEMAND@\&#201;GYPTIEN@g" -i "$tmpaafdir"/EnvOLE_ENT2DVA_0940072T_Complet_20180830_PersEducNat_0000.xml

cd /tmp || exit

rm -f /tmp/complet.zip
zip -vr /tmp/complet.zip "complet/"*
result="$?"
cd || exit 1
echo "* result=$result"

if [ "$result" = 0 ]; then
    echo "* importation des comptes dans mongdob"
    if ciVersionMajeurAvant "2.7.1"
    then
        salt "*" ead.importaaf_processfile /tmp/complet.zip complète
    else
        salt -c /etc/ead3/salt/ "*" ead.importaaf_processfile /tmp/complet.zip complète
    fi
    result="$?"
    echo "* result importation=$result"
fi

if [ "$result" = 0 ]; then
    echo "* importation des comptes dans l'AD"
    if ciVersionMajeurAvant "2.7.1"
    then
        salt "*" ead.importad_launch
    else
        salt -c /etc/ead3/salt/ "*" ead.importad_launch
    fi
    result="$?"
    echo
fi

echo "* generation des exports de la base mongodb"
if [ "$VM_VERSIONMAJEUR" \< "2.9.0" ];
then
    mongoexport -d eoleaaf --jsonArray --pretty --collection user > user.json
    mongoexport -d eoleaaf --jsonArray --pretty --collection etablissement > etablissement.json
    mongoexport -d eoleaaf --jsonArray --pretty --collection subject > subject.json
else
    podman run -it eole-mongodb mongoexport -d eoleaaf --jsonArray --pretty --collection user > user.json
    podman run -it eole-mongodb mongoexport -d eoleaaf --jsonArray --pretty --collection etablissement > etablissement.json
    podman run -it eole-mongodb mongoexport -d eoleaaf --jsonArray --pretty --collection subject > subject.json
fi

echo "* cat /etc/aaf.conf"
cat /etc/aaf.conf

echo "* cat /var/lib/eole/reports/importaaf.log"
[ -f /var/lib/eole/reports/importaaf.log ] && cat /var/lib/eole/reports/importaaf.log

echo "* result=$result"
exit $result

