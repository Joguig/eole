#!/bin/bash

BASE=/mnt/eole-ci-tests/output/ggrandgerard/gpo
if [ "$(CreoleGet eole_module)" == "scribe" ] || [ "$(CreoleGet eole_module)" == "amonecole" ]
then
    ROOT_PATH=/var/lib/lxc/addc/rootfs
    CMD="lxc-attach -n addc -- "
else
    ROOT_PATH=
    CMD=""
fi

VERSIONMAJEUR=$(CreoleGet eole_release)
echo "VERSIONMAJEUR=$VERSIONMAJEUR"
if [ "$VERSIONMAJEUR" == "2.7.1" ]
then
    BASE_SCRIPT=${BASE}/gpo_tool271
    echo "Inject code depuis $BASE_SCRIPT "
    if [ ! -d "${ROOT_PATH}/usr/lib/python2.7/dist-packages/gpo_utils" ]
    then
        echo "ERROR: ${ROOT_PATH}/usr/lib/python2.7/dist-packages/gpo_utils n'existe pas"
        exit 1 
    fi
    cp -rvf $BASE_SCRIPT/gpo_utils ${ROOT_PATH}/usr/lib/python2.7/dist-packages/
    rm -f ${ROOT_PATH}/usr/lib/python2.7/dist-packages/gpo_utils/*.pyc
fi
if [ "$VERSIONMAJEUR" == "2.7.2" ]
then
    BASE_SCRIPT=${BASE}/gpo_tool272
    echo "Inject code depuis $BASE_SCRIPT "
    if [ ! -d "${ROOT_PATH}/usr/lib/python3/dist-packages/gpo_utils" ]
    then
        echo "ERROR: ${ROOT_PATH}/usr/lib/python3/dist-packages/gpo_utils n'existe pas"
        exit 1 
    fi
    rm -f ${ROOT_PATH}/usr/lib/python3/dist-packages/gpo_utils/*.pyc
    rm -rf "${ROOT_PATH}/usr/share/eole/gpo/"*
    mkdir -p "${ROOT_PATH}/usr/share/eole/gpo/"
    cp -rvf $BASE_SCRIPT/gpo_utils ${ROOT_PATH}/usr/lib/python3/dist-packages/
    cp -rvf $BASE_SCRIPT/gpo ${ROOT_PATH}/usr/share/eole/
    #cp -rvf "$BASE_SCRIPT/gpo" "${ROOT_PATH}/usr/share/eole/"
fi
if [ "$VERSIONMAJEUR" == "2.8.0" ]
then
    BASE_SCRIPT=${BASE}/gpo_tool280
    echo "Inject code depuis $BASE_SCRIPT "
    if [ ! -d "${ROOT_PATH}/usr/lib/python3/dist-packages/gpo_utils" ]
    then
        echo "ERROR: ${ROOT_PATH}/usr/lib/python3/dist-packages/gpo_utils n'existe pas"
        exit 1 
    fi
    rm -f ${ROOT_PATH}/usr/lib/python3/dist-packages/gpo_utils/*.pyc
    cp -rvf $BASE_SCRIPT/gpo_utils ${ROOT_PATH}/usr/lib/python3/dist-packages/
fi
if [ "$VERSIONMAJEUR" == "2.8.1" ]
then
    BASE_SCRIPT=${BASE}/gpo_tool281
    echo "Inject code depuis $BASE_SCRIPT "
    if [ ! -d "${ROOT_PATH}/usr/lib/python3/dist-packages/gpo_utils" ]
    then
        echo "ERROR: ${ROOT_PATH}/usr/lib/python3/dist-packages/gpo_utils n'existe pas"
        exit 1 
    fi
    set -xe 
    rm -f "${ROOT_PATH}/usr/lib/python3/dist-packages/gpo_utils/*.pyc"
    #rm -rf "${ROOT_PATH}/usr/share/eole/gpo/"*
    #mkdir -p "${ROOT_PATH}/usr/share/eole/gpo/"
    cp -rvf "$BASE_SCRIPT/gpo_utils" ${ROOT_PATH}/usr/lib/python3/dist-packages/
    #cp -vf $BASE_SCRIPT/gpo/*.tar.gz ${ROOT_PATH}/usr/share/eole/gpo/
    #cp -rvf "$BASE_SCRIPT/gpo" "${ROOT_PATH}/usr/share/eole/"
fi
if [ "$VERSIONMAJEUR" == "2.9.0" ]
then
    BASE_SCRIPT=${BASE}/gpo_tool290
    echo "Inject code depuis $BASE_SCRIPT "
    if [ ! -d "${ROOT_PATH}/usr/lib/python3/dist-packages/gpo_utils" ]
    then
        echo "ERROR: ${ROOT_PATH}/usr/lib/python3/dist-packages/gpo_utils n'existe pas"
        exit 1 
    fi
    set -xe 
    rm -f "${ROOT_PATH}/usr/lib/python3/dist-packages/gpo_utils/*.pyc"
    #rm -rf "${ROOT_PATH}/usr/share/eole/gpo/"*
    #mkdir -p "${ROOT_PATH}/usr/share/eole/gpo/"
    cp -rvf "$BASE_SCRIPT/gpo_utils" ${ROOT_PATH}/usr/lib/python3/dist-packages/
    #cp -vf $BASE_SCRIPT/gpo/*.tar.gz ${ROOT_PATH}/usr/share/eole/gpo/
    #cp -rvf "$BASE_SCRIPT/gpo" "${ROOT_PATH}/usr/share/eole/"
fi
if [ "$VERSIONMAJEUR" == "2.10.0" ]
then
    BASE_SCRIPT=${BASE}/gpo_tool2100
    echo "Inject code depuis $BASE_SCRIPT "
    if [ ! -d "${ROOT_PATH}/usr/lib/python3/dist-packages/gpo_utils" ]
    then
        echo "ERROR: ${ROOT_PATH}/usr/lib/python3/dist-packages/gpo_utils n'existe pas"
        exit 1 
    fi
    set -xe 
    rm -f "${ROOT_PATH}/usr/lib/python3/dist-packages/gpo_utils/*.pyc"
    #rm -rf "${ROOT_PATH}/usr/share/eole/gpo/"*
    #mkdir -p "${ROOT_PATH}/usr/share/eole/gpo/"
    cp -rvf "$BASE_SCRIPT/gpo_utils" ${ROOT_PATH}/usr/lib/python3/dist-packages/
    #cp -vf $BASE_SCRIPT/gpo/*.tar.gz ${ROOT_PATH}/usr/share/eole/gpo/
    #cp -rvf "$BASE_SCRIPT/gpo" "${ROOT_PATH}/usr/share/eole/"
fi


if [ ! -d "${ROOT_PATH}/usr/share/eole/sbin/" ]
then
    ${CMD} mkdir -p /usr/share/eole/sbin
fi
cp -vf "$BASE_SCRIPT/samba4.sh" "${ROOT_PATH}/usr/lib/eole/samba4.sh"
cp -vf "$BASE_SCRIPT/gpo-tool" "${ROOT_PATH}/usr/share/eole/sbin/gpo-tool"
if [ ! -f "${ROOT_PATH}/usr/share/eole/sbin/gpo-tool" ]
then
    echo "ERROR: ${ROOT_PATH}/usr/share/eole/sbin/gpo-tool n'existe pas"
    exit 1 
fi
# il n'existe pas'
cp -vf "$BASE/gpo-tool-test.sh" "${ROOT_PATH}/usr/share/eole/sbin/gpo-tool-test"

if [ ! -d "${ROOT_PATH}/usr/share/eole/postservice/" ]
then
    echo "WARNING: ${ROOT_PATH}/usr/share/eole/postservice/ n'existe pas"
    ${CMD} mkdir -p /usr/share/eole/postservice
fi
cp -vf "$BASE_SCRIPT/30-gposcript" "${ROOT_PATH}/usr/share/eole/postservice/30-gposcript"
if [ ! -f "${ROOT_PATH}/usr/share/eole/postservice/30-gposcript" ]
then
    echo "ERROR: ${ROOT_PATH}/usr/share/eole/postservice/30-gposcript n'existe pas"
    exit 1 
fi

if [ ! -f "${ROOT_PATH}/usr/share/eole/gpo/import-gpo.sh" ]
then
    echo "ERROR: ${ROOT_PATH}/usr/share/eole/gpo/import-gpo.sh n'existe pas"
    exit 1 
fi

if [ ! -d "${ROOT_PATH}/usr/share/eole/samba" ]
then
    echo "WARNING: ${ROOT_PATH}/usr/share/eole/samba/ n'existe pas"
    ${CMD} mkdir -p /usr/share/eole/samba
fi
cp -vf "$BASE_SCRIPT/30-gposcript" "${ROOT_PATH}/usr/share/eole/samba/30-gposcript"
if [ ! -f "${ROOT_PATH}/usr/share/eole/samba/30-gposcript" ]
then
    echo "ERROR: ${ROOT_PATH}/usr/share/eole/samba/30-gposcript n'existe pas"
    exit 1 
fi

echo ""
#echo ""
echo "TEST: 30-gposcript 'désactive eole_script' $*"
echo "GPOSCRIPT=1" >${ROOT_PATH}/etc/eole/gposcript.conf
#VM_MODULE='' ${CMD} bash /usr/share/eole/postservice/30-gposcript "$@"
VM_MODULE='' ${CMD} bash /usr/share/eole/samba/30-gposcript "$@"

#echo "***************************************************************************************************"
#echo "GPOSCRIPT=0" >${ROOT_PATH}/etc/eole/gposcript.conf
#VM_MODULE='' ${CMD} bash /usr/share/eole/gpo/export-gpo.sh "eole_script_manuelle" "/usr/share/eole/gpo/eole_script_manuelle1.tar.gz"
#cp "${ROOT_PATH}/usr/share/eole/gpo/eole_script_manuelle1.tar.gz" $BASE_SCRIPT/gpo/

#touch ${ROOT_PATH}/var/tmp/gpo-script/update_eole_script
#VM_MODULE='' ${CMD} bash /usr/share/eole/gpo/import-gpo.sh "eole_script" "/usr/share/eole/gpo/eole_script.tar.gz" "$BASEDN"
#VM_MODULE='' ${CMD} bash /usr/share/eole/postservice/30-gposcript -d 3
#VM_MODULE='' ${CMD} bash -x /usr/share/eole/samba/30-gposcript "$@"
#echo "***************************************************************************************************"
#exit 0

echo ""
echo ""
echo "TEST: gpo-tool-test credential"
VM_MODULE='' ${CMD} /usr/share/eole/sbin/gpo-tool-test --version "$VERSIONMAJEUR" all-no-help with_credential "$@"

echo ""
echo ""
echo "TEST: gpo-tool-test kerberos"
if [ "$VERSIONMAJEUR" == "2.7.1" ]
then
    VM_MODULE='' ${CMD} /usr/share/eole/sbin/gpo-tool-test --version "$VERSIONMAJEUR" all-no-help with_kerberos "$@"
else
    echo "ATTENTION: gpo-tool-test kerberos DESACTIVEES car pb en 4.11 !"
fi

#${CMD} /usr/share/eole/sbin/gpo-tool-test --version "$VERSIONMAJEUR" with_credential eole_script_basic

echo ""
echo ""
echo "TEST: 30-gposcript $*"
echo "GPOSCRIPT=1" >/etc/eole/gposcript.conf
VM_MODULE='' ${CMD} bash /usr/share/eole/samba/30-gposcript "$@"

if [ "$VERSIONMAJEUR" == "2.7.1" ]
then
    echo ""
    echo ""
    echo "TEST: reg_to_xml & importation 271"
    VM_MODULE='' ${CMD} /usr/share/eole/sbin/gpo-tool-test --version "$VERSIONMAJEUR" old_script_import_271 with_kerberos
fi
