#!/bin/bash

SAMBA4_VARS=/etc/eole/samba4-vars.conf
EXIT_ON_ERROR="${1:-no}"

if [ -f "${SAMBA4_VARS}" ]
then
    . "${SAMBA4_VARS}"
else
    # Template is disabled => samba is disabled
    echo "Samba is disabled"
    exit 0
fi

SECTIONS=$(grep "^\[" /etc/samba/smb.conf)

    
for section in ${SECTIONS}
do
    section_name="${section:1:-1}"
    cat >/tmp/smb.conf <<EOF
[global]
  realm = ${AD_REALM}
  workgroup = ${AD_DOMAIN}
  netbios name = ${AD_HOST_NAME}
[homes] 
    guest ok = no 
    browseable = no
EOF

    if [ $section_name != "global" ]
    then
        P=$(testparm --suppress-prompt -vp --section-name=${section_name} 2>/dev/null | grep "path =")
        echo >>/tmp/smb.conf
        echo "${section} " >>/tmp/smb.conf
        echo " $P" >>/tmp/smb.conf
    fi
    
    testparm --suppress-prompt -vp --section-name=${section_name} 2>/dev/null >/tmp/smb.actuel
    testparm --suppress-prompt -vp --section-name=${section_name} /tmp/smb.conf >/tmp/smb.minimale 2>/dev/null   

    echo "*** $section_name minimale=default    ***********   $section_name module = modifiée **********" 
    echo "$section" 
    diff --side-by-side --suppress-common-lines /tmp/smb.minimale /tmp/smb.actuel
    echo
done

echo $?
