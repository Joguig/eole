#!/bin/bash

if [[ "$(uname -o)" == "GNU/Linux" ]]
then
    SHELL_CHECK_VERSION="$(/usr/bin/shellcheck -V 2>/dev/null)"
    if [ -z "$SHELL_CHECK_VERSION" ]
    then
        apt-get install shellcheck -y 2>/dev/null
    fi
    # ubuntu ==> test
    for SHELLCHECK_BIN in /mnt/eole-ci-tests/scripts/shellcheck \
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
                    echo "* Install shellcheck $SHELLCHECK_BIN $CDU"
                    /bin/cp -f "$SHELLCHECK_BIN" /usr/bin/shellcheck
                    chmod 755 /usr/bin/shellcheck
                fi
                if /usr/bin/shellcheck -V >/dev/null 2>&1
                then
                    # si fonctionnel, stop
                    break
                fi
            else
                echo "$SHELLCHECK_BIN : pas executable ou dependance incorrecte ?"
            fi
        else
            echo "$SHELLCHECK_BIN : pas un fichier ?"
        fi
    done
else
    echo "pas de shellcheck sur $(uname -o) ?"
fi