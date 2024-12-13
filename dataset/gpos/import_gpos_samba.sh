#!/bin/bash

function doSambaTool()
{
    if [ "$EST_SCRIBE_AD" == oui ]
    then
        # pb expansion variable contenant des espaces
        lxc-attach -n addc -- samba-tool "$@"
    else
        samba-tool "$@" 
    fi
}

function doLdbModify()
{
    if [ "$EST_SCRIBE_AD" == oui ]
    then
        # pb expansion variable contenant des espaces
        lxc-attach -n addc -- ldbmodify -H /var/lib/samba/private/sam.ldb "$@"
    else
        ldbmodify -H /var/lib/samba/private/sam.ldb "$@" 
    fi
}

function doMain()
{
    SOURCE="$1"
    echo "BASEDN: $BASEDN"
    echo "SOURCE: $SOURCE"
    GPO_ADMIN="gpo-${AD_HOST_NAME}"
    GPO_ADMIN_DN="${GPO_ADMIN}@${AD_REALM^^}"
    GPO_ADMIN_PWD_FILE=$(get_passwordfile_for_account "${GPO_ADMIN}")
    GPO_ADMIN_KEYTAB_FILE=$(get_keytabfile_for_account "${GPO_ADMIN}")
    if [ ! -f "${GPO_ADMIN_PWD_FILE}" ]
    then
        ciSignalWarning "Le fichier ${GPO_ADMIN_PWD_FILE} est manquant"
        exit 1
    fi
    ADMIN_PWD="$(cat "${GPO_ADMIN_PWD_FILE}")"
    CREDENTIAL="${GPO_ADMIN_DN}%${ADMIN_PWD}"
    
    if [ ! -f "$SOURCE/Liste_GPO.csv" ]
    then
        ciSignalWarning "source $SOURCE/Liste_GPO.csv est manquant"
        exit 1
    fi
    
    while IFS=';' read -r GPONAME GPOID
    do
       if [ "$GPOID" == "{6AC1786C-016F-11D2-945F-00C04FB984F9}" ] || [ "$GPOID" == "{31B2F340-016D-11D2-945F-00C04FB984F9}" ]
       then
           # protection
           echo "$GPOID : PROTECTION IGNORE"
       else
           GPONAME1=$(doSambaTool gpo show "$GPOID" | grep "display name : "  | sed -e 's/display name : //')
           if [ "$GPONAME1" == "eole_script" ] || [ "$GPONAME1" == "Default Domain Controllers Policy" ] || [ "$GPONAME1" == "Default Domain Policy" ]
           then
               # protection
               echo "$GPONAME1=$GPOID : PROTECTION IGNORE"
           else
               # si manque, restaure !
               if [ -z "$GPONAME1" ]
               then
                   echo "==========================================="
                   echo "GPO '$GPONAME' : à installer"
                   BASE=""
                   if [ -d "$SOURCE/policy/$GPOID" ]
                   then
                       BASE="$SOURCE/policy/$GPOID"
                   fi
                   if [ -d "$SOURCE/policy/$GPONAME" ]
                   then
                       BASE="$SOURCE/policy/$GPONAME"
                   fi
                   if [ -n "$BASE" ]
                   then
                       find "$BASE" -name '*.tmpl' | while IFS=';' read -r TEMPLATE
                       do
                           TARGET=$(basename "$TEMPLATE" .tmpl)
                           echo "TEMPLATE=$TEMPLATE : CreoleCat >$TARGET"
                           CreoleCat -s "$TEMPLATE" -o "$TARGET"
                       done
                       if [ -f "$BASE/entities.xml" ] 
                       then
                           echo "samba-tool gpo restore -H ldap://${AD_HOST_NAME}.${AD_REALM} -U${CREDENTIAL} --entities='$BASE/entities.xml' '$GPONAME' '$BASE'"
                           doSambaTool gpo restore -H "ldap://${AD_HOST_NAME}.${AD_REALM}" -U"${CREDENTIAL}" --entities="$BASE/entities.xml" "$GPONAME" "$BASE"
                           CDU="$?"
                       else
                           echo "samba-tool gpo restore -H ldap://${AD_HOST_NAME}.${AD_REALM} -U${CREDENTIAL} '$GPONAME' $BASE"
                           doSambaTool gpo restore -H "ldap://${AD_HOST_NAME}.${AD_REALM}" -U"${CREDENTIAL}" "$GPONAME" "$BASE"
                           CDU="$?"
                       fi
                       echo "samba-tool gpo restore : $CDU"
                       if [ "$CDU" -ne "0" ]
                       then
                           exit $?
                       fi
                   else
                       echo "Répertoire manquant $BASE, ignore !"  
                   fi
               else
                   echo  "$GPONAME=$GPOID : présente"
               fi
           fi 
       fi
    done < "$SOURCE/Liste_GPO.csv"
}

if [ -d /var/lib/lxc/addc/rootfs ]
then
    # cas ScribeAD
    CONTAINER_ROOTFS="/var/lib/lxc/addc/rootfs"
    EST_SCRIBE_AD=oui
else
    CONTAINER_ROOTFS=""
    EST_SCRIBE_AD=non
fi
#shellcheck disable=SC1091,SC1090
. "$CONTAINER_ROOTFS/etc/eole/samba4-vars.conf"
BASEDN="DC=${AD_REALM//./,DC=}"
echo "BASEDN: $BASEDN"

# execute main si non sourcé
if [[ "${BASH_SOURCE[0]}" == "$0" ]]
then
    doMain "$@"
    exit "$RESULTAT"
fi
