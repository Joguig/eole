#!/bin/bash

if [ "$2" != "NO_UPDATE" ]
then
    A_METTRE_A_JOUR=nok
    # je test le timestamp des fichiers avant le contenu
    if [ /mnt/eole-ci-tests/scripts/EoleCiFunctions.sh -nt /root/EoleCiFunctions.sh ]
    then
        # je le copie avant de le tester plusieurs fois !
        /bin/cp /mnt/eole-ci-tests/scripts/EoleCiFunctions.sh /root/EoleCiFunctions1.sh
        if ! diff -q /root/EoleCiFunctions1.sh /root/EoleCiFunctions.sh >/dev/null
        then
            if [[ "$(uname -o)" == "GNU/Linux" ]]
            then
                SHELL_CHECK_VERSION="$(/usr/bin/shellcheck -V 2>/dev/null)"
                if [ -z "$SHELL_CHECK_VERSION" ]
                then
                    apt-get install shellcheck -y 2>/dev/null
                    SHELL_CHECK_VERSION="$(/usr/bin/shellcheck -V 2>/dev/null)"
                fi
                # ubuntu ==> test
                for SHELLCHECK_BIN in /mnt/eole-ci-tests/scripts/shellcheck \
                                      /mnt/eole-ci-tests/scripts/shellcheck-jammy \
                                      /mnt/eole-ci-tests/scripts/shellcheck-focal \
                                      /mnt/eole-ci-tests/scripts/shellcheck-bionic \
                                      /mnt/eole-ci-tests/scripts/shellcheck-xenial
                do
                    if [ -f "$SHELLCHECK_BIN" ]
                    then
                        SHELL_CHECK_VERSION_PARTAGE="$($SHELLCHECK_BIN -V 2>/dev/null)"
                        if [ -n "$SHELL_CHECK_VERSION_PARTAGE" ]
                        then
                            # ok
                            if [ "$SHELL_CHECK_VERSION_PARTAGE" \> "$SHELL_CHECK_VERSION" ]
                            then
                                echo "* Install shellcheck $SHELLCHECK_BIN '$SHELL_CHECK_VERSION'"
                                /bin/cp -f "$SHELLCHECK_BIN" /usr/bin/shellcheck
                                chmod 755 /usr/bin/shellcheck
                            fi
                            if /usr/bin/shellcheck -V 2>/dev/null 1>/dev/null
                            then
                                # si fonctionnel, stop
                                break
                            fi
#                        else
#                            echo "$SHELLCHECK_BIN : pas executable ou dependance incorrecte ?"
                        fi
#                    else
#                        echo "$SHELLCHECK_BIN : pas un fichier ?"
                    fi
                done
                if command -v /usr/bin/shellcheck >/dev/null 2>/dev/null
                then
                    if /usr/bin/shellcheck /root/EoleCiFunctions1.sh
                    then
#                        echo "* shellcheck EoleCiFunctions.sh OK ==> update"
                        A_METTRE_A_JOUR=ok
#                    else
#                        echo "* shellcheck EoleCiFunctions.sh NOK ==> pas d'update!" 
                    fi
                else
                    echo "* shellcheck imcompatible focal"
                    A_METTRE_A_JOUR=ok 
                fi
           else
               echo "* freebsd EoleCiFunctions.sh ==> update sans test !"
               A_METTRE_A_JOUR=ok
           fi
           if [ "$A_METTRE_A_JOUR" == "ok" ]
           then
               /bin/cp -f /root/EoleCiFunctions1.sh /root/EoleCiFunctions.sh
           fi
           
    #    else
    #        echo "* EoleCiFunctions.sh à jour (diff) !" 
        fi
        /bin/rm /root/EoleCiFunctions1.sh
    #else
    #    echo "* EoleCiFunctions.sh à jour (not newer) !" 
    fi
    
    # je test le timestamp des fichiers avant le contenu
    if [ /mnt/eole-ci-tests/scripts/getVMContext.sh -nt /root/getVMContext.sh ]
    then
        # je le copie avant de le tester plusieurs fois !
        /bin/cp /mnt/eole-ci-tests/scripts/getVMContext.sh /root/getVMContext1.sh
        if ! diff -q /root/getVMContext1.sh /root/getVMContext.sh >/dev/null
        then
            /bin/cp /root/getVMContext1.sh /root/getVMContext.sh
        fi
        /bin/rm /root/getVMContext1.sh
    fi
fi

# shellcheck disable=SC1091,SC1090
source /root/EoleCiFunctions.sh
ciGetContext
if [ "$1" != "NO_DISPLAY" ]
then
    ciDisplayContext
fi
