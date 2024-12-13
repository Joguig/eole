#!/bin/bash
# shellcheck disable=SC2050

SCRIPT_PATH="${BASH_SOURCE[0]}"
if [ -h "${SCRIPT_PATH}" ]
then
  while [ -h "${SCRIPT_PATH}" ]
  do 
      SCRIPT_PATH=$(readlink "${SCRIPT_PATH}")
  done
fi
pushd . || exit 1 > /dev/null
DIR_SCRIPT=$(dirname "${SCRIPT_PATH}" )
cd "${DIR_SCRIPT}" > /dev/null || exit 1
SCRIPT_PATH=$(pwd);
popd || exit 1 > /dev/null

DIR_SCRIPT=$(dirname "${SCRIPT_PATH}" )
FORMATER=formatConfigEol1.py
GIT=${DIR_SCRIPT}
echo "Formatage '${DIR_SCRIPT}'"

machines=$(ls "$GIT/configuration/")
#machines="rie.esbl-ddt101 rie.ecdl-ddt101"
for machine in $machines
do
    echo "MACHINE = $machine GIT"
    configurations=$(ls "$GIT/configuration/$machine/")
    for configuration in $configurations  
    do
         repConfigurationGit="$GIT/configuration/$machine/$configuration"
         if [ -d "$repConfigurationGit" ]
         then
            configEolGit="$repConfigurationGit/etc/eole/config.eol"
            if [ -f "$configEolGit" ]
            then
                /bin/rm -f /tmp/configGit.eol
                python3 "$GIT/scripts/$FORMATER" <"$configEolGit" >/tmp/configGit.eol ;
                CDU="$?"
                if [ "$CDU" == "0" ]
                then
                    if ! diff --ignore-space-change /tmp/configGit.eol "$configEolGit" >/tmp/configGit.diff;
                    then
                        /bin/rm -f "$repConfigurationGit/etc/eole/config.bak"
                        /bin/cp "$configEolGit" "$repConfigurationGit/etc/eole/config.bak"
                        echo "    $configuration à reformater"
                        /bin/cp -f /tmp/configGit.eol "$configEolGit"
                    else 
                        echo "    $configuration déjà à jour"
                    fi
                else
                    echo "    ERREUR FORMATAGE dans $configEolGit"
                    cat /tmp/configGit.eol
                fi
                /bin/rm -f /tmp/configGit.eol
            fi
        fi
    done
done
