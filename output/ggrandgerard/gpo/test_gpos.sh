#!/bin/bash

if [[ "$VM_MODULE" == "scribe" ]] || [[ "$VM_MODULE" == "amonecole" ]]
then
    cp -f "$0" /var/lib/lxc/addc/rootfs/tmp/test_gpos.sh
    echo "Execute $0 dans le conteneur ADDC"
    VM_MODULE='' lxc-attach -n addc -- /bin/bash /tmp/test_gpos.sh "$@"
    exit $?
fi

cat >/tmp/LdapUnWrap.py <<EOF
import sys

for line in sys.stdin:
    line = line.replace('\n', '')
    nbcar = len(line)
    if nbcar == 0:
        sys.stdout.write('\n')
        sys.stdout.write(line)
    else:
        if line[0] == ' ':
            sys.stdout.write(line[1:])
        else:
            sys.stdout.write('\n')
            sys.stdout.write(line)
sys.stdout.write('\n')
EOF

DESTINATION=/mnt/eole-ci-tests/output/ggrandgerard/extract_gpos
mkdir -p "$DESTINATION"
mkdir -p "$DESTINATION/gpos"

# shellcheck disable=SC1091
. /etc/eole/samba4-vars.conf

# shellcheck disable=SC1091
. /usr/lib/eole/samba4.sh

GPO_ADMIN="gpo-${AD_HOST_NAME}"
GPO_ADMIN_DN="${GPO_ADMIN}@${AD_REALM^^}"
#GPO_ADMIN_PWD_FILE=$(get_passwordfile_for_account "${GPO_ADMIN}")
GPO_ADMIN_KEYTAB_FILE=$(get_keytabfile_for_account "${GPO_ADMIN}")

if ! kinit "${GPO_ADMIN_DN}" -k -t "${GPO_ADMIN_KEYTAB_FILE}"
then
    echo "Impossible de créer une session kerberos."
    exit 1
fi

samba-tool gpo show "{31B2F340-016D-11D2-945F-00C04FB984F9}" -k 1
samba-tool ntacl get "/home/sysvol/${AD_REALM}/Policies/{31B2F340-016D-11D2-945F-00C04FB984F9}" -k 1 --as-sddl >"$DESTINATION/default.sddl"
cat "$DESTINATION/default.sddl"
samba-tool gpo listall | grep "GPO " | awk '{ print $3;}' >"$DESTINATION/liste_gpo"
GPOS=$(ls "/home/sysvol/${AD_REALM}/Policies")
for repertoire in ${GPOS}
do
    REP_GP="/home/sysvol/${AD_REALM}/Policies/$repertoire"
    ls -l "$REP_GP"
    if ! grep -q "$repertoire" "$DESTINATION/liste_gpo"
    then
        echo "$repertoire : Absent"
    fi
done

ACL_NORMAL="O:LAG:BAD:P(A;OICI;0x001f01ff;;;BA)(A;OICI;0x001200a9;;;SO)(A;OICI;0x001f01ff;;;SY)(A;OICI;0x001200a9;;;AU)(A;OICI;0x001301bf;;;PA)"
echo $ACL_NORMAL >"$DESTINATION/default"

BASEDN="DC=${AD_REALM//./,DC=}"
BASEDN3D="DC%3D${AD_REALM//./%2CDC%3D}"
BASEDN3D="${BASEDN3D^^}"
echo "BASEDN: $BASEDN"
echo "BASEDN3D: $BASEDN3D"

LISTE_GPO=$(cat $DESTINATION/liste_gpo)
for gp in ${LISTE_GPO}
do
    echo ""
    echo "=========================================================="
    REP_GP="/home/sysvol/${AD_REALM}/Policies/$gp"
    /bin/rm /tmp/show.txt
    samba-tool gpo show "$gp" -k 1 >"/tmp/show.txt" 2>&1
    if [ ! -f "/tmp/show.txt" ]
    then
        echo "$gp PB extract !"
        continue
    fi
    NAME=$(awk -F: '/display name/ { gsub(/^[ \t]+/, "", $2); print $2;}' </tmp/show.txt)
    if [ -z "$NAME" ]
    then
        echo "$gp INCONNUE !"
        continue
    fi
    mkdir -p "$DESTINATION/$NAME"
    cp /tmp/show.txt "$DESTINATION/$NAME/show.txt"
    grep ACL <"/tmp/show.txt" | sed -e 's/.*: //' >"$DESTINATION/$NAME/acl_show.sddl"
    ACL_SHOW=$(cat "$DESTINATION/$NAME/acl_show.sddl")
    mkdir -p "$DESTINATION/$NAME"
    echo "$gp" >"$DESTINATION/$NAME/id"
    ldbsearch -H /var/lib/samba/private/sam.ldb "cn=$gp" >"$DESTINATION/$NAME/sam.ldif"
    if [ -f "/var/lib/samba/private/sam.ldb.d/${BASEDN3D}.ldb" ]
    then
        ldbsearch -H "/var/lib/samba/private/sam.ldb.d/${BASEDN3D}.ldb" "cn=$gp" >"$DESTINATION/$NAME/sam_configuration.ldif"
    else
        ldbsearch -H "/var/lib/samba/private/sam.ldb.d/${BASEDN^^}.ldb" "cn=$gp" >"$DESTINATION/$NAME/sam_configuration.ldif"
    fi
    if [ ! -d "${REP_GP}" ]
    then
        echo "   Absent (les infos sont dans l'AD, mais les fichiers ne sont plus présents)"
        continue
    fi
    python3 /tmp/LdapUnWrap.py <"$DESTINATION/$NAME/sam_configuration.ldif" >"$DESTINATION/$NAME/sam_configuration.ldif_unwrap"

    ls -lR "$REP_GP" >"$DESTINATION/$NAME/ls_lR.txt"
    getfacl "$REP_GP" >"$DESTINATION/$NAME/fgetacl.txt" 2>/dev/null
    getfattr -R "$REP_GP" >"$DESTINATION/$NAME/getfattr.txt" 2>/dev/null
    samba-tool ntacl get "${REP_GP}" -k 1 --as-sddl >"$DESTINATION/$NAME/netacl_get.sddl"
    samba-tool ntacl getdosinfo "${REP_GP}" -k 1 >"$DESTINATION/$NAME/netacl_getidosinfo.txt"
    samba-tool gpo aclcheck "${REP_GP}" -k 1 >"$DESTINATION/$NAME/gpo_aclcheck.log" 2>&1

    #GPCFILESYSPATH=$(gpo-tool importation show_by_name "$NAME" -k 1 -d 2 --attribut gPCFileSysPath)
    #echo "GPCFILESYSPATH=$GPCFILESYSPATH"

    #VERSIONNUMBER=$(gpo-tool importation show_by_name "$NAME" -k 1 --attribut versionNumber)
    #echo "VERSIONNUMBER=$VERSIONNUMBER"

    #FLAGS=$(gpo-tool importation show_by_name "$NAME" -k 1 --attribut flags)
    #echo "FLAGS=$FLAGS"

    gpo-tool importation show_by_name "$NAME" -k 1 --attribut nTSecurityDescriptor >"$DESTINATION/$NAME/nTSecurityDescriptor.sddl"
    NT_SECURITY_DESCRIPTOR=$(cat "$DESTINATION/$NAME/nTSecurityDescriptor.sddl")

    ACL_GP=$(cat "$DESTINATION/$NAME/netacl_get.sddl")
    echo "Test GPO : $gp $NAME"
    if [ "$NT_SECURITY_DESCRIPTOR" != "$ACL_SHOW" ]
    then
        echo "nTSecurity DIFFERENT"
        echo "   SHOW                   : $ACL_SHOW"
        echo "   NT_SECURITY_DESCRIPTOR : $NT_SECURITY_DESCRIPTOR"
        diff "$DESTINATION/$NAME/nTSecurityDescriptor.sddl" "$DESTINATION/$NAME/acl_show.sddl"
    else
        echo "nTSecurity OK"
    fi
    if [ "$ACL_GP" != "$ACL_NORMAL" ]
    then
        echo "ACL DIFFERENT"
        echo "   ATTENDU                : $ACL_NORMAL"
        echo "   NTACL                  : $ACL_GP"
        diff "$DESTINATION/$NAME/netacl_get.sddl" "$DESTINATION/default"
    else
        echo "ACL OK"
    fi
    if [ "$NAME" == "Default Domain Policy" ]
    then
        echo "   ignore $NAME"
        continue
    fi
    if [ "$NAME" == "Default Domain Controllers Policy" ]
    then
        echo "   ignore $NAME"
        continue
    fi
    #samba-tool ntacl set "$ACL" "${REP_GP}" -k 1
    #if [ $? -eq 0 ]
    #then
    #    echo "$gp : reset ACL ok"
    #else
    #    echo "$gp : reset ACL ERREUR"
    #fi
done

# destroy kerberos ticket
kdestroy || true
