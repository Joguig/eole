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
pushd . > /dev/null
DIR_SCRIPT=$(dirname "${SCRIPT_PATH}" )
cd "${DIR_SCRIPT}" > /dev/null || exit 1
SCRIPT_PATH=$(pwd);
popd  > /dev/null || exit 1

DIR_SCRIPT=$(dirname "${SCRIPT_PATH}" )
FORMATER=formatConfigEol1.py
GIT=${DIR_SCRIPT}
MNT="$1"
if [ -z "$MNT" ]
then
   MNT="$GIT"
fi
echo "Compare '${SCRIPT_PATH}' avec ${MNT}"

if [ ! -d "$MNT" ]
then
    echo "usage: $0 <path-mnt-eole-ci-tests>"
    echo "   exemple $0 /mnt/eole-ci-tests"
    exit 1
fi

machines=$(ls "$MNT/configuration/")
for machine in $machines
do
    echo "MACHINE = $machine MNT"
    configurations=$(ls "$MNT/configuration/$machine/")
    for configuration in $configurations  
    do
        repConfigurationMnt="$MNT/configuration/$machine/$configuration"
        if [ -d "$repConfigurationMnt" ]
        then
            configEolMnt="$repConfigurationMnt/etc/eole/config.eol"
            if [ -f "$configEolMnt" ]
            then
                rm -f /tmp/configMnt.eol
                sed -i -e 's/val"null/val":null/' "$configEolMnt"
                if python "$GIT/scripts/$FORMATER" <"$configEolMnt" >/tmp/configMnt.eol
                then
                    if diff --ignore-space-change /tmp/configMnt.eol "$configEolMnt"
                    then
                        rm -f "$repConfigurationMnt/etc/eole/config.bak"
                        cp "$configEolMnt" "$repConfigurationMnt/etc/eole/config.bak"
                        echo "formatage MNT : $configEolMnt"
                        cp -f /tmp/configMnt.eol "$configEolMnt" 
                    fi
                else
                    echo "ERREUR FORMATAGE : $configEolMnt"
                fi
                rm -f /tmp/configMnt.eol
            fi
        fi
    done

    if [ "$MNT" != "$GIT" ]
    then
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
                    rm -f /tmp/configGit.eol
                    sed -i -e 's/val"null/val":null/' "$configEolGit"
                    if python "$GIT/scripts/$FORMATER" <"$configEolGit" >/tmp/configGit.eol
                    then
                        if diff --ignore-space-change /tmp/configGit.eol "$configEolGit"
                        then
                            rm -f "$repConfigurationGit/etc/eole/config.bak"
                            cp "$configEolGit" "$repConfigurationGit/etc/eole/config.bak"
                            echo "formatage GIT : $configEolGit"
                            cp -f /tmp/configGit.eol "$configEolGit" 
                        fi
                    else
                        echo "ERREUR FORMATAGE : $configEolGit"
                    fi
                    rm -f /tmp/configGit.eol
                    
                    repConfigurationMnt="$MNT/configuration/$machine/$configuration"
                    configEolMnt="$repConfigurationMnt/etc/eole/config.eol"
                    if [ "$configEolGit" != "configEolMnt" ]
                    then
                        if diff -q --ignore-space-change "$configEolGit" "$configEolMnt"
                        then
                            echo "   different : $configEolMnt / configEolGit"
                            diff "$configEolGit" "$configEolMnt"
                        #else
                            #echo "   identique : $configEolMnt / configEolGit"
                        fi
                    fi
                fi
            fi
        done
    fi
done
