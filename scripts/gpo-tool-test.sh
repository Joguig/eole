#!/bin/bash

function checkExitCode()
{
    local EC
    local MSG
    EC="${1}"
    MSG_ERR="${2}"
    MSG_OK="${3}"
    if [[ "$EC" -eq 0 ]]
    then
        if [[ "$MSG_OK" != "" ]]
        then
            echo "$MSG_OK"
        fi
        return 0
    fi
    if [ "$EXIT_ON_ERROR" != "no" ]
    then
        echo "Error: '$MSG_ERR' exit=$EC, arret demandé"
        exit 1
    else
        echo "Warning: '$MSG_ERR' exit=$EC, mais je continue...."
    fi
}

function checkErrorAttendue()
{
    local EC
    local MSG
    EC="${1}"
    MSG="${2}"
    if [[ "$EC" -ne 0 ]]
    then
        return 0
    fi
    if [ "$EXIT_ON_ERROR" != "no" ]
    then
        echo "Error: '$MSG' exit=$EC, arret demandé"
        exit 1
    else
        echo "Warning: '$MSG' exit=$EC, mais je continue...."
    fi
}

function doGpoToolWithoutH()
{
    if [ "$WITH_KERBEROS" == yes ]
    then
        echo "# doGpoTool KERBEROS : '$*' -k 1 -d $DEBUG" >&2
        gpo-tool "$@" -k 1 -d "$DEBUG"
        return $?
    fi    
    if [ "$WITH_CREDENTIAL" == yes ]
    then
        echo "# doGpoTool CREDENTIAL : '$*' -U${CREDENTIAL} -d $DEBUG" >&2
        gpo-tool "$@" -U"${CREDENTIAL}" -d "$DEBUG"
        return $?
    fi    
    return 1
    #echo "# doGpoTool MACHINE '$*' -d $DEBUG" >&2
    #gpo-tool "$@" -d "$DEBUG"
}

function doGpoTool()
{
    if [ "$WITH_KERBEROS" == yes ]
    then
        doGpoToolWithoutH "$@" -H "ldap://${AD_HOST_NAME}.${AD_REALM}"
        return $?
    fi    
    if [ "$WITH_CREDENTIAL" == yes ]
    then
        doGpoToolWithoutH "$@" -H "ldap://${AD_HOST_NAME}.${AD_REALM}"
        return $?
    fi    
    doGpoToolWithoutH "$@" -H "ldap://${AD_HOST_NAME}.${AD_REALM}"
}

function doTestHelp()
{
    echo ""
    echo ""
    echo "********************************************************************************************************"
    echo " doTestHelp "
    echo "********************************************************************************************************"
   
    echo "==================================================================================="
    doGpoTool -h
    checkExitCode "$?" "help"
   
    echo "==================================================================================="
    doGpoTool gpo -h
    checkExitCode "$?" "help gpo"
   
    #echo "==================================================================================="
    #doGpoTool importation -h
    #checkExitCode "$?" "help importation"
   
    echo "==================================================================================="
    doGpoTool "$HELPER_COMMAND" -h
    checkExitCode "$?" "help $HELPER_COMMAND"
   
    echo "==================================================================================="
    doGpoTool "$HELPER_COMMAND" delete_by_name -h
    checkExitCode "$?" "help $HELPER_COMMAND delete_by_name"
   
    echo "==================================================================================="
    doGpoTool "$HELPER_COMMAND" show_by_name -h
    checkExitCode "$?" "help $HELPER_COMMAND show_by_name"
   
    #echo "==================================================================================="
    #doGpoTool importation importation_from_source -h
    #checkExitCode "$?" "help importation importation_from_source"
   
    echo "==================================================================================="
    doGpoTool policy -h
    checkExitCode "$?" "help policy"
   
    echo "==================================================================================="
    doGpoTool policy add -h
    checkExitCode "$?" "help policy add"
   
    echo "==================================================================================="
    doGpoTool policy resgister -h
    checkExitCode "$?" "help policy resgister "
   
    echo "==================================================================================="
    doGpoTool policy list -h
    checkExitCode "$?" "help policy list "
   
    echo "==================================================================================="
    doGpoTool policy inspect -h
    checkExitCode "$?" "help policy inspect "
}

function doTestGpoBase()
{
    echo ""
    echo ""
    echo "********************************************************************************************************"
    echo " doTestGpoBase "
    echo "********************************************************************************************************"
   
    echo "==================================================================================="
    samba-tool gpo listall -U"${CREDENTIAL}"
    checkExitCode "$?" "listall 1"
   
    echo "==================================================================================="
    doGpoTool "$HELPER_COMMAND" delete_by_name GpoQuiNExistePas
    checkErrorAttendue "$?" "delete_by_name"
   
    echo "==================================================================================="
    # seulement pour nettoyer !
    doGpoTool "$HELPER_COMMAND" delete_by_name TestGG || true 
    checkExitCode "$?" "delete_by_name"
   
    echo "==================================================================================="
    doGpoTool gpo listall
    checkExitCode "$?" "listall 2"
   
    echo "==================================================================================="
    doGpoTool gpo create TestGG 
    checkExitCode "$?" "gpo create"
   
    echo "==================================================================================="
    doGpoTool gpo listall
    checkExitCode "$?" "listall 3"
   
    echo "==================================================================================="
    NAME=$(doGpoTool "$HELPER_COMMAND" show_by_name TestGG --attribut name )
    checkExitCode "$?" "show_by_name TestGG"
    echo "NAME=$NAME"
   
    NAME=$(doGpoTool "$HELPER_COMMAND" show_by_name TestGG --attribut name )
    checkExitCode "$?" "show_by_name name TestGG"
    echo "NAME=$NAME"
   
    DISPLAY_NAME=$(doGpoTool "$HELPER_COMMAND" show_by_name TestGG --attribut displayName)
    checkExitCode "$?" "show_by_name displayName TestGG"
    echo "DISPLAY_NAME=$DISPLAY_NAME"
   
    GPCFILESYSPATH=$(doGpoTool "$HELPER_COMMAND" show_by_name TestGG --attribut gPCFileSysPath)
    checkExitCode "$?" "show_by_name gPCFileSysPath TestGG"
    echo "GPCFILESYSPATH=$GPCFILESYSPATH"
   
    VERSIONNUMBER=$(doGpoTool "$HELPER_COMMAND" show_by_name TestGG --attribut versionNumber)
    checkExitCode "$?" "show_by_name TestGG"
    echo "VERSIONNUMBER=$VERSIONNUMBER"
   
    FLAGS=$(doGpoTool "$HELPER_COMMAND" show_by_name TestGG --attribut flags)
    checkExitCode "$?" "show_by_name TestGG"
    echo "FLAGS=$FLAGS"

    doGpoTool "$HELPER_COMMAND" delete_by_name TestGG || true 
    checkExitCode "$?" "delete_by_name"
}

function doTestPolicy()
{
    echo ""
    echo ""
    echo "********************************************************************************************************"
    echo " doTestPolicy "
    echo "********************************************************************************************************"
   
    echo "==================================================================================="
    echo REMOVE /etc/samba/gpo_policies.pickle
    rm -f /etc/samba/gpo_policies.pickle
   
    echo "==================================================================================="
    gpo-tool policy register 'Ctrl+Alt+Suppr' '{35378EAC-683F-11D2-A89A-00C04FBBCFA2}{D02B1F73-3407-48AE-BA88-E8213C6761F1}' 'Registry.pol' 'User' 'Software\Microsoft\Windows\CurrentVersion\Policies\system;DisableChangePassword;REG_DWORD;4;{value}'
    checkExitCode "$?" "register Ctrl+Alt+Suppr"
   
    gpo-tool policy register 'WaitNetwork' '{35378EAC-683F-11D2-A89A-00C04FBBCFA2}{D02B1F73-3407-48AE-BA88-E8213C6761F1}' 'Registry.pol' 'Machine' 'Software\Policies\Microsoft\Windows NT\CurrentVersion\Winlogon;SyncForegroundPolicy;REG_DWORD;4;{value}'
    checkExitCode "$?" "register WaitNetwork"
    echo "==================================================================================="
}

function doTestMtes()
{
    echo ""
    echo ""
    echo "********************************************************************************************************"
    echo " doTestEoleScript "
    echo "********************************************************************************************************"
    doGpoTool policy register 'Ajouter des stations de travail au domaine' \
                             '{827D319E-6EAC-11D2-A4EA-00C04F79F83A}{803E14A0-B4FB-11D0-A0D0-00A0C90F574B}' \
                             'GptTmpl.inf' \
                             'Machine/Microsoft/Windows NT/SecEdit' \
                             '[Privilege Rights]\nSeMachineAccountPrivilege = {group}'
    checkExitCode "$?" "register 'Ajouter des stations de travail au domaine'"

    doGpoTool policy register 'Groupes restreints' \
                             '{827D319E-6EAC-11D2-A4EA-00C04F79F83A}{803E14A0-B4FB-11D0-A0D0-00A0C90F574B}' \
                             'GptTmpl.inf' \
                             'Machine/Microsoft/Windows NT/SecEdit' \
                             '[Group Membership]\n{group}__Memberof = {sup_group}\n{group}__Members = {sub_group}'
    checkExitCode "$?" "register 'Groupes restreints'"
   
    doGpoTool gpo create admin_local_mtes
    checkExitCode "$?" "gpo create admin_local_mtes"
   
    doGpoTool policy add "Default Domain Controllers Policy" \
                        'Ajouter des stations de travail au domaine' \
                        -v group:S-1-2-5-0
                       
    doGpoTool gpo create "GPO-Ctrl+Alt+Suppr"
    checkExitCode "$?" "gpo create admin_local_mtes"

    doGpoTool policy add "Ctrl+Alt+Suppr" \
                         "Utilisateur/Stratégie/Modèles d'administration/Système/Options Ctrl + Alt + Suppr/Désactiver la modification du mot de passe" \
                         -v value:1

                       
                       
}

function doCreateOUTest()
{
    etab="${1}"
    RESULT=$(ldbsearch -H /var/lib/samba/private/sam.ldb "(&(objectclass=organizationalunit)(name=$etab))" | grep dn:)
    if [ -n "$RESULT" ]
    then
        echo "OU $etab existe déjà"
        return
    fi
    
    cat >/tmp/creatOU.ldif <<EOF
dn: OU=$etab,$BASEDN
changetype: add
objectClass: top
objectClass: organizationalunit
EOF

    ldbmodify -v -H "/var/lib/samba/private/sam.ldb" /tmp/creatOU.ldif
    echo "OU $etab crée"
}

function doTestEoleScriptAcl()
{
    echo "==================================================================================="
    echo "Test présence Extension gPCMachineExtensionNames & gPCUserExtensionNames ($VM_VERSIONMAJEUR)"
    GPCMACHINEEXTENSIONNAMES=$(doGpoTool "$HELPER_COMMAND" show_by_name eole_script --attribut gPCMachineExtensionNames)
    checkExitCode "$?" "show_by_name gPCMachineExtensionNames eole_script"
    echo "gPCMachineExtensionNames=$GPCMACHINEEXTENSIONNAMES"
    if ciVersionMajeurApres "2.7.1"
    then
        #if ciVersionMajeurApres "2.8.0"
        #then
            GPCMACHINEEXTENSIONNAMES_ATTENDU="[{00000000-0000-0000-0000-000000000000}{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}][{35378EAC-683F-11D2-A89A-00C04FBBCFA2}{D02B1F72-3407-48AE-BA88-E8213C6761F1}][{42B5FAAE-6536-11D2-AE5A-0000F87571E3}{40B6664F-4972-11D1-A7CA-0000F87571E3}][{B087BE9D-ED37-454F-AF9C-04291E351182}{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}]"
        #else
        #    GPCMACHINEEXTENSIONNAMES_ATTENDU="[{00000000-0000-0000-0000-000000000000}{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}][{35378EAC-683F-11D2-A89A-00C04FBBCFA2}{D02B1F73-3407-48AE-BA88-E8213C6761F1}][{42B5FAAE-6536-11D2-AE5A-0000F87571E3}{40B6664F-4972-11D1-A7CA-0000F87571E3}][{B087BE9D-ED37-454F-AF9C-04291E351182}{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}]"
        #fi
    else
        GPCMACHINEEXTENSIONNAMES_ATTENDU="[{00000000-0000-0000-0000-000000000000}{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}][{42B5FAAE-6536-11D2-AE5A-0000F87571E3}{40B6664F-4972-11D1-A7CA-0000F87571E3}][{B087BE9D-ED37-454F-AF9C-04291E351182}{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}]"
    fi
    test "$GPCMACHINEEXTENSIONNAMES" == "$GPCMACHINEEXTENSIONNAMES_ATTENDU"
    # si le contenu de eole_script change, la liste changera. il faudra modifier la valeur attendue
    # dans le cas contraire, c'est que le code d'importation est incorrect !
    checkExitCode "$?" "ATTENDU=$GPCMACHINEEXTENSIONNAMES_ATTENDU" "OK"
       
    GPCUSEREXTENSIONNAMES=$(doGpoTool "$HELPER_COMMAND" show_by_name eole_script --attribut gPCUserExtensionNames)
    checkExitCode "$?" "show_by_name gPCUserExtensionNames eole_script"
    echo "gPCUserExtensionNames=$GPCUSEREXTENSIONNAMES"
    if ciVersionMajeurApres "2.7.1"
    then
        #if ciVersionMajeurApres "2.8.0"
        #then
            GPCUSEREXTENSIONNAMES_ATTENDU="[{42B5FAAE-6536-11D2-AE5A-0000F87571E3}{40B66650-4972-11D1-A7CA-0000F87571E3}]"
        #else
        #    GPCUSEREXTENSIONNAMES_ATTENDU="[{42B5FAAE-6536-11D2-AE5A-0000F87571E3}{40B66650-4972-11D1-A7CA-0000F87571E3}]"
        #fi
    else
        GPCUSEREXTENSIONNAMES_ATTENDU="[{35378EAC-683F-11D2-A89A-00C04FBBCFA2}{D02B1F73-3407-48AE-BA88-E8213C6761F1}][{42B5FAAE-6536-11D2-AE5A-0000F87571E3}{40B66650-4972-11D1-A7CA-0000F87571E3}]"
    fi
    test "$GPCUSEREXTENSIONNAMES" == "$GPCUSEREXTENSIONNAMES_ATTENDU"
    # si le contenu de eole_script change, la liste changera. il faudra modifier la valeur attendue
    # dans le cas contraire, c'est que le code d'importation est incorrect !
    checkExitCode "$?" "ATTENDU=$GPCUSEREXTENSIONNAMES_ATTENDU" "Ok"

}


function doImportEoleScript()
{
    local DN="$1"
    echo "==================================================================================="
    if ciVersionMajeurApres "2.7.1"
    then
        if [ -z "$DN" ]
        then
            bash /usr/share/eole/gpo/import-gpo.sh "eole_script" "/usr/share/eole/gpo/eole_script.tar.gz"
        else
            bash /usr/share/eole/gpo/import-gpo.sh "eole_script" "/usr/share/eole/gpo/eole_script.tar.gz" "$DN"
        fi
    else
        if [ -z "$DN" ]
        then
            doGpoTool importation import_eole_script
        else
            doGpoTool importation import_eole_script --container "$DN"
        fi
    fi
}

function doTestEoleScript()
{
    echo ""
    echo ""
    echo "********************************************************************************************************"
    echo " doTestEoleScript "
    echo "********************************************************************************************************"
    echo ""
    echo "==================================================================================="
    echo "préparation :"
    doCreateOUTest ETAB1

    echo "* find /home/sysvol/${AD_REALM}/"
    find "/home/sysvol/${AD_REALM}/"

    echo "* samba-tool ntacl get scripts --as-sddl"
    samba-tool ntacl get "/home/sysvol/${AD_REALM}/scripts/" --as-sddl
   
    echo "* getfacl scripts"
    getfacl "/home/sysvol/${AD_REALM}/scripts/"
   
    if [ "$WITH_CREDENTIAL" == yes ]
    then
        echo "smbclient:"
        smbclient //localhost/netlogon -U"${CREDENTIAL}" -c 'ls'
        checkExitCode "$?" "smbclient netlogon"
    fi

    if [ "$WITH_KERBEROS" == yes ]
    then
        echo "smbclient (kerberos):"
        smbclient "//${AD_HOST_NAME}/netlogon" -k 1 -c 'ls'
        checkExitCode "$?" "smbclient kerberos"
    fi

    echo "* REMOVE /home/sysvol/${AD_REALM}/scripts/ pour tester la création et les acls"
    rm -rf "/home/sysvol/${AD_REALM}/scripts/users"
    rm -rf "/home/sysvol/${AD_REALM}/scripts/os"
    rm -rf "/home/sysvol/${AD_REALM}/scripts/machines"
    rm -rf "/home/sysvol/${AD_REALM}/scripts/groups"

    echo "* sysvolcheck"
    if ! samba-tool ntacl sysvolcheck -U"${CREDENTIAL}" 2>/dev/null
    then
        echo "* sysvolreset"
        samba-tool ntacl sysvolreset -U"${CREDENTIAL}"
        echo "sysvolreset => $?"
    else
        echo "sysvol ok"
    fi

    echo "==================================================================================="
    doGpoTool "$HELPER_COMMAND" delete_by_name eole_script 
    echo "pas de check ici, ignore erreur si elle apparait !"

    samba-tool ntacl sysvolcheck -U"${CREDENTIAL}"
    #checkExitCode "$?" "sysvolcheck 1"
       
    echo "==================================================================================="
    doImportEoleScript
    checkExitCode "$?" "import_eole_script phase 1"

    samba-tool ntacl sysvolcheck -U"${CREDENTIAL}"
    #checkExitCode "$?" "sysvolcheck 2"
   
    echo "==================================================================================="
    doGpoTool gpo listall
    checkExitCode "$?" "listall 3"

    ls -ld "/home/sysvol/${AD_REALM}/scripts/users"
    ls -ld "/home/sysvol/${AD_REALM}/scripts/os"
    ls -ld "/home/sysvol/${AD_REALM}/scripts/machines"
    ls -ld "/home/sysvol/${AD_REALM}/scripts/groups"

    echo "==================================================================================="
    echo "Test avec sémaphore"
    touch /var/tmp/gpo-script/update_eole_script
    doImportEoleScript
    checkExitCode "$?" "import_eole_script phase 2"

    test ! -f /var/tmp/gpo-script/update_eole_script
    checkExitCode "$?" "semaphore non supprimé' !"
   
    echo "==================================================================================="
    GPOID=$(doGpoTool "$HELPER_COMMAND" show_by_name eole_script --attribut name)
    echo "Update 'eole_script' $GPOID : OK"

    echo "==================================================================================="
    echo "Second appel sans modification"
    doImportEoleScript
    checkExitCode "$?" "import_eole_script phase 3"

    GPOID1=$(doGpoTool "$HELPER_COMMAND" show_by_name eole_script --attribut name)
    test "$GPOID1" = "$GPOID"
    checkExitCode "$?" "Update 2nd fois 'eole_script' : NOK l'ID a été changé $GPOID -> $GPOID1"
    echo "Update 'eole_script' $GPOID1 : OK"
   
    echo "==================================================================================="
    echo "3eme appel sans modification"
    doImportEoleScript
    checkExitCode "$?" "import_eole_script phase 4"

    GPOID2=$(doGpoTool "$HELPER_COMMAND" show_by_name eole_script --attribut name)
    test "$GPOID2" = "$GPOID1"
    checkExitCode "$?" "Update 3eme fois 'eole_script' : NOK l'ID a été changé. $GPOID -> $GPOID1 -> $GPOID2"
    echo "Update 'eole_script' $GPOID2 : OK"
   
	echo "==================================================================================="
    echo "setlink $BASEDN avec eole_script"
    doGpoTool gpo setlink "$BASEDN" "$GPOID"
    checkExitCode "$?" "setlink $BASEDN eole_script"
    
    DN="OU=ETAB1,$BASEDN"
    echo "setlink $DN avec eole_script"
    doGpoTool gpo setlink "$DN" "$GPOID" 
    checkExitCode "$?" "setlink $DN eole_script"
       
    echo "==================================================================================="
    echo "Test avec Lien existant sans recréation"
    doImportEoleScript
    checkExitCode "$?" "import_eole_script Lien existant"
    
    echo "==================================================================================="
    echo "Vérification lien GPO / DN"
    doGpoTool gpo getlink "$DN"
    checkExitCode "$?" "getlink $DN"
   
    echo "==================================================================================="
    echo "Test gpo existante avec un lien +  sémaphore recréation"
    touch /var/tmp/gpo-script/update_eole_script
    doImportEoleScript
    checkExitCode "$?" "Test gpo existante avec un lien"
    
    echo "==================================================================================="
    doGpoTool "$HELPER_COMMAND" delete_by_name eole_script 
    checkExitCode "$?" "delete_by_name eole_script"

    echo "==================================================================================="
    echo "Test création avec lien"
    doImportEoleScript "$BASEDN"
    checkExitCode "$?" "Test création avec lien $DN"

    doTestEoleScriptAcl

    echo "==================================================================================="
    doGpoTool "$HELPER_COMMAND" delete_by_name eole_script 
    checkExitCode "$?" "delete_by_name eole_script"
}

function doTestEoleScriptBasic()
{
    echo ""
    echo ""
    echo "********************************************************************************************************"
    echo " doTestEoleScriptBasic"
    echo "********************************************************************************************************"
    echo ""
    echo "==================================================================================="

    echo "==================================================================================="
    doGpoTool "$HELPER_COMMAND" delete_by_name eole_script 
    # pas de check ici

    echo "==================================================================================="
    doImportEoleScript
    checkExitCode "$?" "import_eole_script phase 1"

    doTestEoleScriptAcl
}

function doOldScript()
{
    echo ""
    echo ""
    echo "********************************************************************************************************"
    echo " doOldScript "
    echo "********************************************************************************************************"
    echo ""

    echo "==================================================================================="
    doImportEoleScript

    echo "reg_to_xml =================================================================="
    /usr/share/eole/gpo/script/reg_to_xml.py
    
    echo "importation.py =================================================================="
    /usr/share/eole/gpo/script/importation.py
}

function doMain()
{
    DEBUG=1
    DO_GPO_TOOL=no
    DO_HELP=no
    DO_POLICY=no
    DO_MTES=no
    DO_EOLE_SCRIPT=no
    DO_EOLE_SCRIPT_BASIC=no
    DO_GPO_BASE=no
    WITH_CREDENTIAL=no
    WITH_KERBEROS=no
   
    if [ -n "$VM_VERSIONMAJEUR" ]
    then
        VERSIONMAJEUR=$VM_VERSIONMAJEUR
        echo "VERSIONMAJEUR default = $VERSIONMAJEUR"
    fi
   
    if [ $# -eq 0 ]
    then
        echo "$0: Tests par defaut"
        DO_GPO_TOOL=yes
        DO_HELP=no
        DO_POLICY=yes
        DO_EOLE_SCRIPT=yes
        DO_GPO_BASE=yes
        DO_MTES=yes
    else
        while [ -n "$1" ]
        do
            echo "$0: Options $1"
            case $1 in
                EXIT_ON_ERROR)
                        EXIT_ON_ERROR=yes
                        ;;
                all)    
                        DO_GPO_TOOL=yes
                        DO_HELP=yes
                        DO_POLICY=yes
                        DO_GPO_BASE=yes
                        DO_EOLE_SCRIPT=yes
                        DO_EOLE_SCRIPT_BASIC=no
                        ;;
                all-no-help)    
                        DO_GPO_TOOL=yes
                        DO_HELP=no
                        DO_POLICY=yes
                        DO_GPO_BASE=yes
                        DO_EOLE_SCRIPT=yes
                        ;;
                gpo_tool)
                         DO_GPO_TOOL=yes
                         ;;
                help)    
                        DO_HELP=yes
                        ;;
                policy)    
                        DO_POLICY=yes
                        ;;
                mtes)  
                        DO_MTES=yes
                        ;;
                gpo_base)
                        DO_GPO_BASE=no
                        ;;
                eole_script_basic)
                        DO_EOLE_SCRIPT_BASIC=yes
                        ;;
                eole_script)
                        DO_EOLE_SCRIPT=yes
                        ;;
                old_script_import_271)
                        DO_271=yes
                        ;;
                with_kerberos)
                        WITH_KERBEROS=yes
                        ;;
                with_credential)
                        WITH_CREDENTIAL=yes
                        ;;
                --version)
                        shift
                        VERSIONMAJEUR="$1"
                        echo "Active VERSIONMAJEUR = $VERSIONMAJEUR"
                        ;;
                --debug)
                        shift
                        DEBUG="$1"
                        echo "Active DEBUG = $DEBUG"
                        ;;
                *)      
                        echo "$0: Options $1 inconnue"
                        echo "Usage /mnt/eole-ci-tests/scripts/gpo-tool-test.sh with_credential|with_kerberos [all|all-no-help|help|gpo_tool|help|policy|mtes|gpo_base|eole_script_basic|eole_script|old_script_import_271] [--version <version>] [--debug]"
                        exit 1
            esac
            shift
        done
    fi
        
    if [ "${VERSIONMAJEUR}" \< "2.7.1" ]
    then
        echo "Pas de test 'gpo-tool' sur cette version $VERSIONMAJEUR"
        exit 0
    fi
               
    if [ "$DO_GPO_TOOL" == yes ]
    then
        if ! command -v gpo-tool
        then
            echo "La commande 'gpo-tool' n'est pas présente."
            exit 1
        fi
    fi

    # shellcheck disable=SC1091,SC1090
    . /etc/eole/samba4-vars.conf
    if [ "${AD_SERVER_ROLE}" != "controleur de domaine" ]
    then
        echo "Pas de GPO sur les serveurs membres"
        exit 0
    fi
    
    if [ "${AD_ADDITIONAL_DC}" != "non" ]
    then
        echo "Cette commande ne doit pas être éxecutée sur les Dc Secondaires."
        exit 0
    fi
    
    if [ "$VERSIONMAJEUR" \< "2.7.2" ]
    then
        # 2.7.1, pas de compte gpo-<host>, mais pas de pb samba-tool gpo avec kerberos !
        ADMIN_PWD=Eole12345!
        GPO_ADMIN_DN="$AD_ADMIN@${AD_REALM^^}"
        HELPER_COMMAND=importation
    
        if [ "$WITH_KERBEROS" == yes ]
        then
            KEYFILE="/tmp/gpoinit.keytab"
            [ -f "$KEYFILE" ] && rm -f "$KEYFILE"
            samba-tool domain exportkeytab "$KEYFILE" --principal="$GPO_ADMIN_DN" -P
            GPO_ADMIN_KEYTAB_FILE="$KEYFILE"
        fi    
    else
        HELPER_COMMAND=helper

        # shellcheck disable=SC1091,SC1090
        . /usr/lib/eole/samba4.sh
        
        # en 2.7.2 et +, les compte gpo-<host> existe et sont mis à jour
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
    fi

    if ciVersionMajeurAPartirDe "2.8."
    then
        OPT_KERBEROS=""
    else
        OPT_KERBEROS=("-k 1")
    fi
    echo "OPT_KERBEROS=${OPT_KERBEROS[*]}"
    
    CREDENTIAL="${GPO_ADMIN_DN}%${ADMIN_PWD}"
    if [ "$WITH_KERBEROS" == yes ]
    then
        kinit "$GPO_ADMIN_DN" -k -t "${GPO_ADMIN_KEYTAB_FILE}"
        checkExitCode "$?" "kinit"

        klist
        checkExitCode "$?"
    fi

    if [ "$DO_HELP" == yes ]
    then
        doTestHelp
        checkExitCode "$?"
    fi

    if [ "$DO_POLICY" == yes ]
    then
        doTestPolicy
        checkExitCode "$?"
    fi

    if [ "$DO_GPO_BASE" == yes ]
    then
        doTestGpoBase
        checkExitCode "$?"
    fi

    if [ "$DO_MTES" == yes ]
    then
        doTestMtes
        checkExitCode "$?"
    fi

    if [ "$DO_EOLE_SCRIPT" == yes ]
    then
        doTestEoleScript
        checkExitCode "$?"
    fi
    
    if [ "$DO_EOLE_SCRIPT_BASIC" == yes ]
    then
        doTestEoleScriptBasic
        checkExitCode "$?"
    fi

    if [ "$DO_271" == yes ]
    then
        doOldScript
        checkExitCode "$?"
    fi
    
    if [ "$WITH_KERBEROS" == yes ]
    then
        if [ -e "$KEYFILE" ]
        then
           # destroy kerberos ticket
           kdestroy
           rm -f "$KEYFILE"
        fi
    fi
    echo "==================================================================================="

}

if [[ "$VM_MODULE" == "scribe" ]] || [[ "$VM_MODULE" == "amonecole" ]]
then
    CMD=$(command -v "$0")
    cp -f "$CMD" /var/lib/lxc/addc/rootfs/usr/share/eole/sbin/gpo-tool-test
    echo "Execute $0 dans le conteneur ADDC"
    VM_MODULE='' lxc-attach -n addc -- /usr/share/eole/sbin/gpo-tool-test "$@"
    exit $?
fi

echo "=================================================================="
echo "GPO-TOOL-TEST : $*"
doMain "$@"
CDU="$?"
echo "GPO-TOOL-TEST : $* --> $CDU"
echo "======================================================================================"
exit "$CDU"
