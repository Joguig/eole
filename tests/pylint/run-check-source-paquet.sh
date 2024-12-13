#!/bin/bash

#http://www.wallix.org/2011/06/29/how-to-use-jenkins-for-python-development/
#http://www.alexconrad.org/2011/10/jenkins-and-python.html
#http://chrigl.de/blogentries/integration-of-pylint-into-jenkins

function doPaquet()
{
    local FROM_UBUNTU
    local FROM_EOLE
    apt-cache policy "$PQ" >/tmp/dpkg
    #cat /tmp/dpkg
    if grep "/ubuntu " /tmp/dpkg >/dev/null 2>&1 ;
    then
        FROM_UBUNTU=UBUNTU
    else
        FROM_UBUNTU="" 
    fi

    if grep "cdrom://EOLE" /tmp/dpkg >/dev/null 2>&1 ;
    then
        FROM_EOLE=EOLE
    else
        FROM_EOLE=""
    fi
   
    if grep "/eole " /tmp/dpkg >/dev/null 2>&1 ;
    then
        FROM_EOLE=EOLE
    else
        FROM_EOLE=""
    fi

    printf "%-50s;%-10s;%-10s\n" "$PQ" "$FROM_UBUNTU" "$FROM_EOLE"
    echo "$PQ;$FROM_UBUNTU;$FROM_EOLE" >>"$DESTINATION"
    
    mkdir -p "/mnt/eole-ci-tests/version/$VM_VERSIONMAJEUR/"
    if [ "$FROM_EOLE" == EOLE ] && [ "$FROM_UBUNTU" == "" ] && [ ! -f "/mnt/eole-ci-tests/version/$VM_VERSIONMAJEUR/$PQ.depends" ]
    then
        apt-cache depends "$PQ" >"/mnt/eole-ci-tests/version/$VM_VERSIONMAJEUR/$PQ.depends"
        apt-cache rdepends "$PQ" >"/mnt/eole-ci-tests/version/$VM_VERSIONMAJEUR/$PQ.rdepends"
    fi    
}

if [ -z "$1" ]
then
    DESTINATION="$WORKSPACE/source_paquets.txt"
else
    DESTINATION="$1"
fi
/bin/rm -f "$DESTINATION"
dpkg -l | awk '/^ii/ {print $2;}' | while read -r PQ
do
   doPaquet "$PQ"
done
exit 0