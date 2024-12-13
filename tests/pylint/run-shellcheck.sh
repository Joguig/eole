#!/bin/bash

function doFichierShell()
{
    echo "$1 $2 Shell"
    echo "$2" >>/tmp/liste_shell
}

function doFichier()
{
    [[ $2 == *".png" ]] && return 0
    [[ $2 == *".conf" ]] && return 0
    [[ $2 == *.js ]] && return 0
    [[ $2 == *.py ]] && return 0
    
    if [[ $2 == *.sh ]]
    then
        doFichierShell "$1" "$2"
        return $?
    fi

    FILETYPE=$(file "$2")
    if [[ $FILETYPE == *"Bourne"* ]]
    then
        doFichierShell "$1" "$2"
        return $?
    fi

    return 0
}

function doFichiers()
{
    dpkg -L "$PQ" | while read -r F
    do
        if [ -f "$F" ]
        then
            doFichier "$PQ" "$F"
        fi
    done
}

function doPaquets()
{
   while IFS=';' read -r PQ FROM_UBUNTU FROM_EOLE
   do
       if [ "$FROM_EOLE" == "EOLE" ]
       then 
           doFichiers "$PQ"
       fi
   done < "$WORKSPACE/source_paquets.txt"
}

/mnt/eole-ci-tests/scripts/shellcheck -v
rm -f /tmp/liste_shell
doPaquets

RETOUR_TEST=0
if [ "$VM_MODULE" == "base" ]
then
    echo "MODULE = $MODULE"
fi
   
if [ "$VM_MODULE" == "amon" ]
then   
    echo "MODULE = $MODULE"
fi

if [ "$VM_MODULE" == "horus" ]
then   
    echo "MODULE = $MODULE"
fi

if [ "$VM_MODULE" == "scribe" ]
then   
    echo "MODULE = $MODULE"
fi

if [ "$VM_MODULE" == "sphynx" ]
then   
    echo "MODULE = $MODULE"
fi

if [ "$VM_MODULE" == "thot" ]
then   
    echo "MODULE = $MODULE"
fi

echo "******************************************************************************************************************"
echo "******************************************************************************************************************"
echo "******                                      SHELLCHECK                                                          ******"
echo "******************************************************************************************************************"
echo "******************************************************************************************************************"
sort </tmp/liste_shell | uniq >/tmp/liste_shell1
cat /tmp/liste_shell1
# shellcheck disable=2046
/mnt/eole-ci-tests/scripts/shellcheck $(cat /tmp/liste_shell1) >"$WORKSPACE/shellcheck.txt" 2>&1
echo "******************************************************************************************************************"
echo "  "

echo "***********************************************************"
echo "Fin $0 ==> $RETOUR_TEST"
echo "***********************************************************"
exit $RETOUR_TEST
