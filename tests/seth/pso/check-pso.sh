#!/bin/bash

RESULTAT="0"

if [[ ! -f /tmp/semaphore ]]
then
    case "$VM_MACHINE" in
        aca.dc1)
            echo "* Préparation group/user"
            if ! samba-tool group show "professeurs" >/dev/null
            then
                samba-tool group add "professeurs"
                samba-tool group add "eleves"
                samba-tool group addmembers "eleves" "c31e1"
                samba-tool group addmembers "professeurs" "prof1"
            fi
            ;;
            
        aca.scribe)
            ;;
            
        *)
            echo "Machine non gérée : $VM_MACHINE"
            ;;
    esac
    
    echo "* Install eole-ad-dc-pso"
    ciAptEole eole-ad-dc-pso
    
    echo "* définit de les PSO professeurs et eleves"
    CreoleSet ad_group_name --default
    ciRunPython CreoleSet_Multi.py <<EOF
set ad_default_max_pwd_age 90
set ad_group_name 0 professeurs
set ad_group_max_pwd_age 0 180
set ad_group_min_pwd_age 0 1
set ad_group_min_pwd_length 0 4
set ad_group_name 1 eleves
set ad_group_history_length 1 1
set ad_group_max_pwd_age 1 120
set ad_group_min_pwd_length 1 5
EOF
    ciCheckExitCode $? "creolset"
    
    CreoleGet --list |grep "^ad_"
    
    echo "* reconfigure"
    ciMonitor reconfigure
    echo "==> $?"
    
    touch /tmp/semaphore
fi

#Precedence (lowest is best): 2
#Password complexity: on
#Store plaintext passwords: off
#Password history length: 24
#Minimum password length: 4
#Minimum password age (days): 1
#Maximum password age (days): 180
#Account lockout duration (mins): 30
#Account lockout threshold (attempts): 0
#Reset account lockout after (mins): 30

function checkPassorSettings()
{
    local USERNAME="$1"
    local CONTENEUR="$2"
    if [ "$1" == default ]
    then
        if [ -z "$CONTENEUR" ]
        then
            samba-tool domain passwordsettings show>/tmp/sortie_console
        else
            lxc-attach -n "$CONTENEUR" -- samba-tool domain passwordsettings show>/tmp/sortie_console
        fi
    else
        if [ -z "$CONTENEUR" ]
        then
            samba-tool domain passwordsettings pso show-user "$USERNAME">/tmp/sortie_console
        else
            lxc-attach -n "$CONTENEUR" -- samba-tool domain passwordsettings pso show-user "$USERNAME">/tmp/sortie_console
        fi
    fi
    #echo "===================================================="
    #echo "$USERNAME"
    #cat /tmp/sortie_console
    #echo "===================================================="
    shift
    shift
    while [ $# != 0 ]
    do
        case "$1" in
            --NoPSO)
                PATTERN='No PSO applies to user'
                ;;

            --MaxPwdAge)
                shift
                PATTERN="Maximum password age (days): $1"
                ;;
                
            --MinPwdLength)
                shift
                PATTERN="Minimum password length: $1"
                ;;
            *)
                echo "$USERNAME $1 : test inconnu"
                ;;
        esac
        if grep -q "$PATTERN" /tmp/sortie_console
        then
            echo "$USERNAME: $PATTERN ==> ok"
        else
            echo "===================================================="
            echo "$USERNAME: $PATTERN ==> ERREUR:"
            sed 's/^/  /' /tmp/sortie_console
            echo "===================================================="
            RESULTAT=1
        fi
        shift
    done
}

case "$VM_MACHINE" in
    aca.dc1)
        checkPassorSettings "default" "" --MaxPwdAge 90
        
        checkPassorSettings "Administrator" "" --NoPSO
        
        checkPassorSettings "c31e1" "" --MaxPwdAge 120 --MinPwdLength 5
        
        checkPassorSettings "prof1" "" --MaxPwdAge 180 --MinPwdLength 4
        ;;
        
    aca.scribe)
        checkPassorSettings "default" addc --MaxPwdAge 90
        
        checkPassorSettings "Administrator" addc --NoPSO
        checkPassorSettings "admin" addc --MaxPwdAge 180 --MinPwdLength 4
        
        checkPassorSettings "prof.6a" addc --MaxPwdAge 180 --MinPwdLength 4
        
        checkPassorSettings "prenom.eleve112" addc --MaxPwdAge 120 --MinPwdLength 5
        ;;

    *)
        echo "Machine non gérée : $VM_MACHINE"
        ;;
esac

echo "RESULTAT=$RESULTAT"
exit "$RESULTAT"
