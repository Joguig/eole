#!/bin/bash
 
if command -v CreoleGet
then
    if [ "$(CreoleGet eole_module)" == "scribe" ]
    then
        CMD=$(command -v "$0")
        cp -f "$CMD" /var/lib/lxc/addc/rootfs/tmp/export_gpos_samba.sh
        echo "Execute $0 dans le conteneur ADDC"
        lxc-attach -n addc -- /tmp/export_gpos_samba.sh "$@"
        ls -l /var/lib/lxc/addc/rootfs/tmp/gpo
        ls -l /var/lib/lxc/addc/rootfs/tmp/gpo/policy
        cp -rf /var/lib/lxc/addc/rootfs/tmp/gpo /tmp/ 
        exit $?
    fi
fi

rm -rvf /tmp/gpo/
mkdir /tmp/gpo/
cd /home/sysvol/*/Policies/ || exit 1
# shellcheck disable=SC2012
ls -d "{*" | while read -r GPOID
do
   if [ "$GPOID" == "{6AC1786C-016F-11D2-945F-00C04FB984F9}" ] | [ "$GPOID" == "{31B2F340-016D-11D2-945F-00C04FB984F9}" ]
   then
       # protection
       echo "$GPOID : PROTECTION IGNORE"
       continue
   fi 
   
   GPONAME=$(samba-tool gpo show "$GPOID" | grep "display name : "  | sed -e 's/display name : //') 
   if [ "$GPONAME" == "eole_script" ] | [ "$GPONAME" == "Default Domain Controllers Policy" ] | [ "$GPONAME" == "Default Domain Policy" ]
   then
       # protection
       echo "$GPONAME=$GPOID : PROTECTION IGNORE"
       continue
   fi
   echo "$GPONAME=$GPOID"
   echo "$GPONAME;$GPOID;" >>/tmp/gpo/Liste_GPO.csv
   samba-tool gpo backup "$GPOID" --generalize --tmpdir="/tmp/gpo/" --entities="/tmp/gpo/policy/$GPOID/entities.xml"
   find "/tmp/gpo/policy/$GPOID/" -name "*.SAMBABACKUP" | while read -r FICHIER_UTF16LE
   do
       xargs iconv -f UTF-16LE -t UTF-8 "$FICHIER_UTF16LE" -o "${FICHIER_UTF16LE}-utf8"
   done
   
done