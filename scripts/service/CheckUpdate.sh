#!/bin/bash

function checkUpdate()
{
    SOURCE=$1
    DEST=$2
    SET_PERMISSION=$3

    if [ ! -f "$SOURCE" ]
    then
        echo "CheckUpdate.sh: $SOURCE manquant !"
        return 0	
    fi
    UPDATE=0
    if [ ! -f "$DEST" ]
    then
        echo "CheckUpdate.sh: nouveau $DEST"
        UPDATE=1
    else
        if command -v md5sum >/dev/null 2>/dev/null
        then
        	HASH_SOURCE=$(md5sum "$SOURCE" | awk '{ print $1;}' )
        	HASH_DEST=$(md5sum "$DEST" | awk '{ print $1;}' )
        else
            if command -v sha256 >/dev/null 2>/dev/null
            then
                HASH_SOURCE=$(sha256 <"$SOURCE" )
                HASH_DEST=$(sha256 <"$DEST" )
            else
                HASH_SOURCE=$(wc -c <"$SOURCE" )
                HASH_DEST=$(wc -c <"$DEST" )
            fi
        fi
        #echo "$DEST : $HASH_SOURCE $HASH_DEST"
    	if [ "$HASH_SOURCE" != "$HASH_DEST" ]
    	then
    		echo "CheckUpdate.sh: update $DEST"
    		UPDATE=1
    	fi
    fi
    if [ "$UPDATE" == 1 ]
    then
        cp -v "$SOURCE" "$DEST"
    else
        echo "CheckUpdate.sh: $DEST A JOUR"
    fi
    
    if [ "${SET_PERMISSION}" == "yes" ]
    then
        if [ ! -x "$DEST" ]
    	then
	        echo "chmod +x $DEST"
    	    chmod +x "${DEST}"
    	fi
    fi
}

checkUpdate /mnt/eole-ci-tests/scripts/service/mount.eole-ci-tests /root/mount.eole-ci-tests yes
checkUpdate /mnt/eole-ci-tests/scripts/getVMContext.sh /root/getVMContext.sh yes
checkUpdate /mnt/eole-ci-tests/scripts/EoleCiFunctions.sh /root/EoleCiFunctions.sh yes
if command -v systemctl > /dev/null 2>/dev/null
then
	checkUpdate /mnt/eole-ci-tests/scripts/service/EoleCiTestsContextSystemD.sh /root/.EoleCiTestsContext.sh yes
	checkUpdate /mnt/eole-ci-tests/scripts/service/EoleCiTestsDaemonSystemD.sh /root/.EoleCiTestsDaemon.sh yes
	exit 0
fi

if command -v initctl > /dev/null 2>/dev/null
then
    checkUpdate /mnt/eole-ci-tests/scripts/service/EoleCiTestsContextUpstart.sh /root/.EoleCiTestsContextUpstart.sh yes
    checkUpdate /mnt/eole-ci-tests/scripts/service/EoleCiTestsDaemonUpstart.sh /root/.EoleCiTestsDaemonUpstart.sh yes
    checkUpdate /mnt/eole-ci-tests/scripts/service/daemon_runner.sh /root/eole-ci-tests-daemon-runner.sh yes
    exit 0
fi

DISTRIB=$(uname -o)
if [ "$DISTRIB" == FreeBSD ] 
then
    checkUpdate /mnt/eole-ci-tests/scripts/service/EoleCiTestsDaemonFreebsd.sh /root/EoleCiTestsDaemon.sh yes
    exit 0
fi

checkUpdate /mnt/eole-ci-tests/scripts/service/daemon_runner.sh /root/eole-ci-tests-daemon-runner.sh yes

exit 0
