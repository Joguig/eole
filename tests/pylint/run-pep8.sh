#!/bin/bash

#http://www.wallix.org/2011/06/29/how-to-use-jenkins-for-python-development/
#http://www.alexconrad.org/2011/10/jenkins-and-python.html
#http://chrigl.de/blogentries/integration-of-pylint-into-jenkins

function doFichierPython()
{
    echo "$1 $2 Python"
    echo "$2" >>/tmp/liste_python
}

function doFichier()
{
    [[ $2 == *".png" ]] && return 0
    [[ $2 == *".conf" ]] && return 0
    [[ $2 == *".sh" ]] && return 0
    [[ $2 == *".js" ]] && return 0

    if [[ $2 == *.py ]]
    then
        doFichierPython "$1" "$2"
        return $?
    fi

    FILETYPE=$(file "$2")
    if [[ $FILETYPE == *"Python"* ]]
    then
        doFichierPython "$1" "$2"
        return $?
    fi

    #echo " $1 $2 $FILETYPE"
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
  done <"$WORKSPACE/source_paquets.txt"
}

if ! command -v pep8 >/dev/null 2>&1
then
   apt install -y pep8
fi

rm -f /tmp/liste_python
doPaquets

echo "******************************************************************************************************************"
echo "******************************************************************************************************************"
echo "******                                      PEP8                                                          ******"
echo "******************************************************************************************************************"
echo "******************************************************************************************************************"

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

sort </tmp/liste_python | uniq >/tmp/liste_python1
# shellcheck disable=2046
pep8 $(cat /tmp/liste_python1) >"$WORKSPACE/pep8.txt" 2>&1

echo "***********************************************************"
echo "Fin $0 ==> $RETOUR_TEST"
echo "***********************************************************"
exit $RETOUR_TEST 
