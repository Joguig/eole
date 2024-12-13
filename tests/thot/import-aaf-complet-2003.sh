#!/bin/bash

# shellcheck disable=SC1091,SC1090
source /root/getVMContext.sh

tmpaafdir="/var/tmp/aaf-complet"

echo "$0 : copie depuis aaf-VE2003/complet/*.xml "
rm -rf "$tmpaafdir"
mkdir -p "$tmpaafdir"
cp -v "$VM_DIR_EOLE_CI_TEST"/dataset/AAF-VE2003/complet/*.xml "$tmpaafdir"
sed -e 's/\/home\//\/var\/tmp\//' -i /etc/aaf.conf
#cat >> /etc/aaf.conf << EOF
#dbtype="sqlite"
#aaf_type="samba4"
#dbfilename="/home/eoleaaf.sql"
#EOF
echo "$0 : /usr/sbin/aaf-complet"
# bash car reconfigure fait un exit !
bash /usr/sbin/aaf-complet
result="$?"
echo "aaf-complet = $result"
ciCheckExitCode "$result"

echo "$0 : cat /var/log/eole/aafexceptions.log"
[ -f /var/log/eole/aafexceptions.log ] && cat /var/log/eole/aafexceptions.log

echo "$0 : mise à jour en utilisant les mêmes fichiers légèrement modifiés"
sed -e 's/\/home\//\/var\/tmp\//' -i /etc/aaf.conf

echo "$0 : Ajout de prénoms à un élève avec des doublons"
sed -e "s@<attr name=\"ENTPersonAutresPrenoms\"><value>Enzo</value></attr>@<attr name=\"ENTPersonAutresPrenoms\"><value>Enzo</value><value>Charles</value><value>Enzo</value></attr>@" -i "$tmpaafdir"/EnvOLE_ENT2DVA_0940072T_Complet_20180830_Eleve_0000.xml

echo "$0 : Suppression de classes à un établissement"
sed -e "s@<value>5C\$5EME\$10110001110</value>@@g" -i "$tmpaafdir"/EnvOLE_ENT2DVA_0940072T_Complet_20180830_EtabEducNat_0000.xml

echo "$0 : Ajout de caractères accentués sur des matières"
sed -e "s@ALLEMAND@\&#201;GYPTIEN@g" -i "$tmpaafdir"/EnvOLE_ENT2DVA_0940072T_Complet_20180830_Eleve_0000.xml
sed -e "s@ALLEMAND@\&#201;GYPTIEN@g" -i "$tmpaafdir"/EnvOLE_ENT2DVA_0940072T_Complet_20180830_PersEducNat_0000.xml

echo "$0 : Affichage de toutes les modifications appliquées"
diff -r "$VM_DIR_EOLE_CI_TEST"/dataset/AAF-VE2003/complet "$tmpaafdir"

bash /usr/sbin/aaf-complet-maj
result="$?"
echo "aaf-complet-maj = $result"
ciCheckExitCode "$result"
